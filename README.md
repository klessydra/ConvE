# Hardware Convolution_2D Engine

This project was an initial effort to transform the behaivioral model in the original repository here

https://github.com/BarisATAK/2D-Convolution-Using-VHDL

into a synthesiable, and highly parametrizable hardware model capable of doing two different types convolutions

1) Full Single cycle hardware convolutions.

2) Single pixel per cycle convolutions.

The matrix and filter sizes can be parametrized (however only odd filter sizes are allowed)

To run the project do the following:

- tclsh run.tcl

If you wanted to simulate a synthesis or post-synthesis netlist then do the folowing:

- Synthesize the RTL on Vivado
- Extract the netlist with the command "write_verilog /<path_to_netlist>"
- copy the wrapper "Convolution_netlist_wrap.vhd" from the Netlists folder to the main folder
- Then run the bash script " ./run_netlist.sh "
- A further " power.tcl " script is available in order to generate the .saif file used by Vivado to calculte th dynamic power consumption for the FPGAs.
