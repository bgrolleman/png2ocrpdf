#!/bin/bash
#
# Quick Version

LANG="dut"
FILE="$1"

cuneiform -l $LANG -f hocr -o "$FILE.hocr" "$FILE"
hocr2pdf -i "$FILE" -s -o "$FILE.pdf" < "$FILE.hocr"

