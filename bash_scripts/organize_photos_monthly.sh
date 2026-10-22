#!/bin/bash

#directory=$PWD
#conda activate file_handler
mod="$(cd "$(dirname "$0")" && pwd)/organize_photos_monthly.py"
python3 "$mod"
