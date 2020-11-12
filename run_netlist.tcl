set work_dir [pwd]

puts $work_dir

if {[file exist $work_dir]} {
} else {
    exec vlib work
    exec vmap work $work_dir/work
}

exec vcom -2008 Convolution.vhd
exec vcom -2008 $work_dir/Netlists/Convolution_netlist_wrap.vhd
exec vlib general_libs
exec vmap general_libs $work_dir/general_libs
exec vlog -work $work_dir/general_libs/ $work_dir/Netlists/include/glbl.v
#exec vmap work
exec pwd
#puts $::env(file)
exec vlog $::env(file).v

exec vsim conv_eng_tb -t ps -vopt -L simprims_ver -L general_libs general_libs.glbl

# exec add wave /conv_eng_tb/CE
