#!/usr/bin/env bash
# procmon.sh — sample CPU/memory over a window and print a summary.

set -euo pipefail

usage() {
    cat <<'EOF'
procmon.sh — sample running processes for a window, then print a summary.

USAGE
    procmon [DURATION] [INDIV_LIMIT] [GROUP_LIMIT]
    procmon -h | --help

ARGUMENTS  (all positional, all optional)
    DURATION       sampling window in whole seconds.
                   The script collects per-process averages over this many
                   seconds before printing. Longer = more accurate, but you
                   wait longer.
                   default: 30

    INDIV_LIMIT    how many rows to show in the INDIVIDUAL table
                   (top-N processes ranked by avg %CPU over the window).
                   default: 20

    GROUP_LIMIT    how many rows to show in the GROUPED table
                   (top-N command names with stats summed across all
                   instances, e.g. all firefox processes combined).
                   default: 5

OUTPUT
    Three sections, in order:
      1. SYSTEM SUMMARY  — overall %CPU over the window, %MEM, %SWAP,
                           load average, and a GPU line if nvidia-smi
                           is available.
      2. GROUPED         — top GROUP_LIMIT process groups by total avg %CPU.
                           Columns: COMMAND, COUNT, %CPU, %MEM (+ %GPU
                           if NVIDIA pmon worked).
      3. INDIVIDUAL      — top INDIV_LIMIT processes by avg %CPU.
                           Columns: PID, USER, TIME (cumulative CPU time,
                           like top's TIME+), %CPU, %MEM (+ %GPU), COMMAND.

EXAMPLES
    procmon                # 30s window, default limits
    procmon 60             # longer 60s window
    procmon 10 30 5        # short 10s window, 30 individual rows, 5 groups
    procmon 120 50 10      # 2-minute window for catching intermittent spikes

REQUIREMENTS
    sysstat (for pidstat).  Install:  sudo apt install sysstat
    nvidia-smi is optional; per-process GPU columns appear only if present.
EOF
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

DURATION=${1:-30}
INDIV_LIMIT=${2:-20}
GROUP_LIMIT=${3:-5}

# Validate numeric args so we fail fast instead of deep inside pidstat / awk.
for v in "$DURATION" "$INDIV_LIMIT" "$GROUP_LIMIT"; do
    if ! [[ "$v" =~ ^[0-9]+$ ]] || [ "$v" -lt 1 ]; then
        echo "Error: arguments must be positive integers (got '$v')" >&2
        echo "Run 'procmon -h' for usage." >&2
        exit 2
    fi
done

if ! command -v pidstat >/dev/null 2>&1; then
    echo "Error: pidstat not found. Install with: sudo apt install sysstat" >&2
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

NCPU=$(nproc)

read_proc_stat() {
    awk '/^cpu / {
        total=0; for (i=2;i<=NF;i++) total += $i
        idle = $5 + $6
        printf "%d %d\n", total, idle
    }' /proc/stat
}

read CPU_TOTAL_BEFORE CPU_IDLE_BEFORE < <(read_proc_stat)

echo "Sampling for ${DURATION}s..."

# pidstat: -h horizontal, -u CPU, -r memory, 1s × DURATION samples.
# ISO time format makes the time column a single token (no AM/PM split).
S_TIME_FORMAT=ISO LC_ALL=C pidstat -h -u -r 1 "$DURATION" \
    > "$TMP/pidstat.out" &
PIDSTAT_PID=$!

# Optional NVIDIA per-process GPU sampling (best effort)
NVIDIA_PID=""
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi pmon -c "$DURATION" -d 1 \
        > "$TMP/nvpmon.out" 2>/dev/null &
    NVIDIA_PID=$!
fi

wait "$PIDSTAT_PID" 2>/dev/null || true
[ -n "$NVIDIA_PID" ] && { wait "$NVIDIA_PID" 2>/dev/null || true; }

read CPU_TOTAL_AFTER CPU_IDLE_AFTER < <(read_proc_stat)

# Snapshot ps for cumulative CPU TIME and elapsed ETIME per process
ps -eo pid=,user=,etime=,time=,comm= > "$TMP/ps.out"

# System CPU % over the window
TDIFF=$((CPU_TOTAL_AFTER - CPU_TOTAL_BEFORE))
IDIFF=$((CPU_IDLE_AFTER - CPU_IDLE_BEFORE))
if [ "$TDIFF" -gt 0 ]; then
    SYS_CPU=$(awk -v t="$TDIFF" -v i="$IDIFF" 'BEGIN { printf "%.1f", (t-i)*100/t }')
else
    SYS_CPU="0.0"
fi

# Memory + swap snapshot at end of window
read MEM_TOTAL MEM_USED MEM_PCT SWAP_TOTAL SWAP_USED SWAP_PCT < <(awk '
    /^MemTotal:/    {tot=$2}
    /^MemAvailable:/ {avail=$2}
    /^SwapTotal:/   {st=$2}
    /^SwapFree:/    {sf=$2}
    END {
        used = tot - avail
        upct = tot ? used*100/tot : 0
        sused = st - sf
        spct = st ? sused*100/st : 0
        printf "%d %d %.1f %d %d %.1f\n", tot, used, upct, st, sused, spct
    }
' /proc/meminfo)

read LOAD1 LOAD5 LOAD15 _ < /proc/loadavg

# GPU summary line (NVIDIA only)
GPU_SUMMARY=""
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_SUMMARY=$(nvidia-smi --query-gpu=name,utilization.gpu,utilization.memory,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null | awk -F',' 'NR==1 {
            for (i=1;i<=NF;i++) gsub(/^ +| +$/, "", $i)
            printf "%s, util %s%%, vram %s/%s MiB", $1, $2, $4, $5
        }')
fi

# Per-process GPU averages from nvidia-smi pmon (PID -> avg sm%, avg fb mem MiB)
# pmon output:
# # gpu        pid  type    sm   mem   enc   dec   command
GPU_PROC_FILE=""
if [ -s "$TMP/nvpmon.out" ]; then
    awk '
        /^#/ { next }
        $2 ~ /^[0-9]+$/ {
            sm = ($4 == "-" ? 0 : $4) + 0
            mem = ($6 == "-" ? 0 : $6) + 0
            sum_sm[$2] += sm
            sum_mem[$2] += mem
            count[$2]++
        }
        END {
            for (pid in count) {
                printf "%s %.2f %.2f\n", pid, sum_sm[pid]/count[pid], sum_mem[pid]/count[pid]
            }
        }
    ' "$TMP/nvpmon.out" > "$TMP/gpu_proc.out"
    [ -s "$TMP/gpu_proc.out" ] && GPU_PROC_FILE="$TMP/gpu_proc.out"
fi

human_kib() {
    awk -v k="$1" 'BEGIN {
        suf[0]="KiB"; suf[1]="MiB"; suf[2]="GiB"; suf[3]="TiB"
        i=0
        while (k >= 1024 && i < 3) { k /= 1024; i++ }
        printf "%.1f %s", k, suf[i]
    }'
}

rule() { printf '%*s\n' 88 '' | tr ' ' '-'; }

echo
echo "SYSTEM SUMMARY  (window ${DURATION}s, $NCPU cores)"
rule
printf '  CPU   : %6s%%   load avg %s, %s, %s\n' "$SYS_CPU" "$LOAD1" "$LOAD5" "$LOAD15"
printf '  MEM   : %6.1f%%   %s used of %s\n' "$MEM_PCT" "$(human_kib "$MEM_USED")" "$(human_kib "$MEM_TOTAL")"
if [ "$SWAP_TOTAL" -gt 0 ]; then
    printf '  SWAP  : %6.1f%%   %s used of %s\n' "$SWAP_PCT" "$(human_kib "$SWAP_USED")" "$(human_kib "$SWAP_TOTAL")"
else
    printf '  SWAP  :  (none)\n'
fi
[ -n "$GPU_SUMMARY" ] && printf '  GPU   :  %s\n' "$GPU_SUMMARY"

# Parse pidstat Averages and emit grouped + individual tables
awk -v indiv_lim="$INDIV_LIMIT" \
    -v group_lim="$GROUP_LIMIT" \
    -v ps_file="$TMP/ps.out" \
    -v gpu_file="${GPU_PROC_FILE:-}" '
BEGIN {
    # Load ps snapshot: pid -> "user etime cputime comm"
    while ((getline line < ps_file) > 0) {
        # Fields are space-separated but comm may have spaces in rare cases.
        # Split into max 5 parts.
        n = split(line, raw, /[ \t]+/)
        # Drop empty leading
        j = 0; delete f
        for (i=1; i<=n; i++) if (raw[i] != "") { j++; f[j] = raw[i] }
        if (j < 5) continue
        pid = f[1]; user = f[2]; etime = f[3]; cputime = f[4]
        comm = f[5]
        for (i=6; i<=j; i++) comm = comm " " f[i]
        ps_user[pid] = user
        ps_etime[pid] = etime
        ps_cputime[pid] = cputime
        ps_comm[pid] = comm
    }
    close(ps_file)

    # Optional GPU per-pid data
    if (gpu_file != "") {
        while ((getline line < gpu_file) > 0) {
            split(line, p, " ")
            gpu_sm[p[1]] = p[2]
            gpu_mem[p[1]] = p[3]
        }
        close(gpu_file)
    }
}
# Sample data row from `pidstat -h -u -r 1 N`:
#   $1=time  $2=UID  $3=PID  $4=%usr  $5=%system  $6=%guest  $7=%wait
#   $8=%CPU  $9=cpu  $10..11=minflt/majflt  $12=VSZ  $13=RSS  $14=%MEM  $15..=Command
$1 !~ /^#/ && $3 ~ /^[0-9]+$/ && NF >= 14 {
    pid = $3
    cmd = ""
    for (i=15; i<=NF; i++) cmd = cmd (cmd ? " " : "") $i

    sum_cpu[pid] += $8 + 0
    sum_mem[pid] += $14 + 0
    sum_rss[pid] += $13 + 0
    n_samples[pid]++
    last_uid[pid] = $2
    last_cmd[pid] = cmd
}
END {
    # Build per-pid averages, then individual + grouped views
    for (pid in n_samples) {
        c = n_samples[pid]
        cpu_avg = sum_cpu[pid] / c
        mem_avg = sum_mem[pid] / c
        rss_avg = sum_rss[pid] / c
        cmd = last_cmd[pid]
        if (cmd == "" && pid in ps_comm) cmd = ps_comm[pid]
        if (cmd == "") continue

        n_indiv++
        ind_pid[n_indiv]  = pid
        ind_cpu[n_indiv]  = cpu_avg
        ind_mem[n_indiv]  = mem_avg
        ind_rss[n_indiv]  = rss_avg
        ind_cmd[n_indiv]  = cmd
        ind_user[n_indiv] = (pid in ps_user) ? ps_user[pid] : last_uid[pid]
        ind_time[n_indiv] = (pid in ps_cputime) ? ps_cputime[pid] : "?"

        # Group key: pidstat already truncates Command to ~15 chars, which
        # collapses Firefox content tabs ("Isolated Web Co"), Claude sessions,
        # etc. into a single bucket. Strip kthread parens for tidiness.
        base = cmd
        sub(/^\(/, "", base); sub(/\)$/, "", base)

        g_cpu[base]    += cpu_avg
        g_mem[base]    += mem_avg
        g_count[base]  += 1
        if (pid in gpu_sm) {
            g_gpu_sm[base]    += gpu_sm[pid]
            g_gpu_count[base] += 1
        }
    }

    # Sort group names by total CPU desc
    n = 0
    for (k in g_count) { n++; gnames[n] = k }
    for (i=1; i<=n; i++) for (j=i+1; j<=n; j++) {
        if (g_cpu[gnames[j]] > g_cpu[gnames[i]]) {
            t = gnames[i]; gnames[i] = gnames[j]; gnames[j] = t
        }
    }

    print ""
    printf "GROUPED  (top %d by total avg CPU; values are sums across instances)\n", group_lim
    s = ""; for (i=0; i<88; i++) s = s "-"; print s
    if (gpu_file != "")
        printf "  %-30s %5s %8s %8s %8s\n", "COMMAND", "COUNT", "%CPU", "%MEM", "%GPU"
    else
        printf "  %-30s %5s %8s %8s\n", "COMMAND", "COUNT", "%CPU", "%MEM"
    for (i=1; i<=n && i<=group_lim; i++) {
        k = gnames[i]
        if (gpu_file != "")
            printf "  %-30s %5d %8.2f %8.2f %8.2f\n", \
                substr(k, 1, 30), g_count[k], g_cpu[k], g_mem[k], (g_gpu_count[k] ? g_gpu_sm[k] : 0)
        else
            printf "  %-30s %5d %8.2f %8.2f\n", \
                substr(k, 1, 30), g_count[k], g_cpu[k], g_mem[k]
    }

    # Sort individual entries by CPU desc
    for (i=1; i<=n_indiv; i++) idx[i] = i
    for (i=1; i<=n_indiv; i++) for (j=i+1; j<=n_indiv; j++) {
        if (ind_cpu[idx[j]] > ind_cpu[idx[i]]) {
            t = idx[i]; idx[i] = idx[j]; idx[j] = t
        }
    }

    print ""
    printf "INDIVIDUAL  (top %d by avg CPU)\n", indiv_lim
    print s
    if (gpu_file != "")
        printf "  %7s %-12s %10s %7s %7s %7s %s\n", \
            "PID", "USER", "TIME", "%CPU", "%MEM", "%GPU", "COMMAND"
    else
        printf "  %7s %-12s %10s %7s %7s %s\n", \
            "PID", "USER", "TIME", "%CPU", "%MEM", "COMMAND"
    for (i=1; i<=n_indiv && i<=indiv_lim; i++) {
        k = idx[i]
        pid = ind_pid[k]
        gpu_v = (pid in gpu_sm) ? gpu_sm[pid] : 0
        if (gpu_file != "")
            printf "  %7s %-12s %10s %7.2f %7.2f %7.2f %s\n", \
                pid, substr(ind_user[k], 1, 12), ind_time[k], \
                ind_cpu[k], ind_mem[k], gpu_v, substr(ind_cmd[k], 1, 36)
        else
            printf "  %7s %-12s %10s %7.2f %7.2f %s\n", \
                pid, substr(ind_user[k], 1, 12), ind_time[k], \
                ind_cpu[k], ind_mem[k], substr(ind_cmd[k], 1, 40)
    }
}
' "$TMP/pidstat.out"

echo
