#!/bin/bash
# vim: foldmethod=marker ts=4
#
# png2ocrpdf.sh - Convert group of .png files to Searchable PDF using OCR
# 
# Author: Bas Grolleman <bgrolleman@emendo-it.nl>
# Usage: png2ocdpdf.sh <title> <file1> <file2> ...
#
# Defaults
lang="dut"
title="no_title_$$"
author="Bas Grolleman"
# show_help() {{{
show_help() {
	echo "
Usage: $0 -v -t <title> -a <author> <files...>

Options: 
	-t Title
	-a Author 
	-v Verbose
	-c Clean 
		Move processed png to clean subdir
	-r Add Random
	  Add a random string to title to avoid duplicates
"
	exit 1;
}
# }}}
# verbose() {{{
verbose() {
	if [ $VERBOSE -gt 0 ]; then
		echo "$1"
	fi
}
# }}}
# Setup (Show Help, Set Options) {{{
# No Arguments, show help
if [ $# -lt 1 ]; then
	show_help
fi
# Get Options
VERBOSE=0
DEBUG=0
CLEAN=0
ADDRANDOM=0
RANDOMSTR=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 8`


while getopts \?a:t:vdcr opt ;do
case "$opt" in
	v) VERBOSE=1;;
	t) title="$OPTARG";;
  a) author="$OPTARG";;
	l) lang="$OPTARG";;
	d) DEBUG=1;;
	c) CLEAN=1;;
	r) ADDRANDOM=1;; 
	\?) show_help;;
esac
done
verbose "Starting $0"
verbose "Verbose on"
# }}}

verbose "Language: $lang"
verbose "Author: $author"
verbose "Title: $title"

# Setup "Clean" dir to move processed files to
if [ $CLEAN -gt 0 ]; then
	mkdir -p clean
fi
if [ $ADDRANDOM -gt 0 ]; then
	title="$title $RANDOMSTR"
fi
# Make sure we only get filenames
shift $((OPTIND-1))
# Need a place to work
WORKDIR=`mktemp -d`
PDFFILES=""
verbose "Workdir: $WORKDIR"
for I in $@; do
	verbose "Processing $I"
	BASE=$(basename $I)
	cuneiform -l $lang -f hocr -o "$WORKDIR/$BASE.hocr" "$I"
	hocr2pdf -i "$I" -s -o "$WORKDIR/$BASE.pdf" < "$WORKDIR/$BASE.hocr"
	PDFFILES="${PDFFILES} $WORKDIR/$BASE.pdf"
	if [ $CLEAN -gt 0 ]; then
		mv $I clean
	fi
done

WORKFILE="${WORKDIR}/WorkFile"
pdfjoin --outfile "${WORKFILE}.pdf" $PDFFILES

cat > "${WORKDIR}/in.info" <<EOF
InfoKey: Author
InfoValue: ${author}
InfoKey: Title
InfoValue: ${title} 
InfoKey: Creator
InfoValue: png2ocrpdf
EOF

pdftk "${WORKFILE}.pdf" update_info "${WORKDIR}/in.info" output "${title}.pdf"


if [ $DEBUG -gt 0 ]; then
	verbose "Debug on, no cleanup of tmp dir $WORKDIR"
else
	verbose "Cleanup of $WORKDIR"
	rm -rf "$WORKDIR"
fi
