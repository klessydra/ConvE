# The time needed to load the 4x4 input matrix
#run 385 ns
# The time needed to load the 8x8 input matrix
#run 1025 ns
# The time needed to load the 16x16 input matrix
#run 3265 ns
# The time needed to load the 32x32 input matrix
run 11585 ns

power add -in -inout -internal -out -ports -r /conv_eng_tb/CONV_ENG_NETLIST/CE/CE/*

# time needed to perfrom the convolution 4x4
#run 165 ns
# time needed to perfrom the convolution 8x8
#run 645 ns
# time needed to perfrom the convolution 16x16
#run 2565 ns
# time needed to perfrom the convolution 32x32
run 10245 ns

set saif_file $::env(file)

power report -all -bsaif ${saif_file}.saif
