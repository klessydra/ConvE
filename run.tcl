set work_dir [pwd]

puts $work_dir

if {[file exist $work_dir]} {
} else {
    exec vlib work
}
exec vcom -2008 Convolution.vhd

exec vsim conv_eng_tb

# exec add wave /conv_eng_tb/CE
