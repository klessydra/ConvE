#!/bin/bash

filename=./*v
#[ -e "$filename" ] || continue
file="$(basename -- $filename)"
file="${file%.*}"
#echo $file
export file
tclsh run_netlist.tcl
