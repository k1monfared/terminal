#!/bin/bash
. "$(cd "$(dirname "$0")" && pwd)/lib/platform.sh"

cat -- "$@" | clip_copy
