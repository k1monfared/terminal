#!/bin/bash
# quickly add the content of the clipboard to a file organized with date
# the structure of the file will be like:
# 2023-01-01
#     first save clipboard content on this date
#
#     the second clipboard content on this date
#
#     ...
#
#
# 2023-01-04
#     first save clipboard content on this date
#
#     the second clipboard content on this date
#
#     ...

indent_clipboard() {
    # add indents to the content of the clipboard
    # call this like:
    #     indent_clipboard 4
    # Read the first argument passed to the function (the number of spaces)
    num_spaces=$1
    # Read the clipboard and store its contents in a variable
    clipboard=$(xclip -o)
    # Add the specified number of spaces to the beginning of each line of the clipboard
    indented_clipboard=$(echo "$clipboard" | sed "s/^/$(printf ' %.0s' $(seq 1 $num_spaces))/")
    # Overwrite the clipboard with the indented text
    echo "$indented_clipboard"
}

create_file_with_path() {
    # check if the file exists, if not create all the required directories and file
    # call this like:
    #     create_file_with_path path/to/file
    # Read the first argument passed to the function (the file path)
    file_path=$1
    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        # If not, create the necessary folders and subfolders
        mkdir -p "$(dirname "$file_path")"
        # Create the file
        touch "$file_path"
    fi
}

read_last_non_indented_line() {
    # get a file path and output the last unindented line
    # Read the first argument passed to the function (the file path)
    file_path=$1
    # Read the non-indented lines of the file and store them in a variable
    non_indented_lines=$(grep -v "^[ ]" "$file_path")
    # Read the last line of the non-indented lines
    last_line=$(echo "$non_indented_lines" | tail -1)
    # Output the last line
    echo "$last_line"
}

remember_clipboard() {
    # Check if there is a file named "memory" in the drafts folder
    # this will save all the clipboard cuts that I want to remember listed by date
    create_file_with_path $memory_address
    # read the last date something was added to the memory
    last_date=$(read_last_non_indented_line $memory_address)
    if [ "$(date +%Y_%m_%d)" != "$last_date" ]; then
      # Add a line with the current date in YYYY_MM_DD format at the end of it
      echo " " >> $memory_address
      echo $(date +%Y_%m_%d) >> $memory_address
    fi
    # Append the content of the clipboard to the memory with an indent of 4 spaces
    echo " " >> $memory_address
    indent_clipboard 4 >> $memory_address
}

remember_clipboard
