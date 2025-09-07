# FPGA-Synth
This repo contains the last lab exercise for the course *"Digital Systems Design Using E-cad Tools/CAD*" of the **Department of Computer Engineering & Informatics** in **University of Patras**.

## Objective

The objective is to implement a synthesizer for playing basic notes and displaying them on a VGA monitor. The example system architecture is:

<p align="center">
  <img src="/example_architecture.png" />
</p>

*	Keyboard controller captures the input from a PS/2 keyboard.
*	Display controller is responsible for the monitor timing and actual display.
*	Sound Controller is responsible for generating of the right note for the piezoelectric speaker.
  
After writing the code and simulating it with ModelSim, the circuit was mapped to the FPGA with Xilinx ISE.

## Solution

The implemented system is:

<p align="center">
  <img src="/system.png" />
</p>

*	*"cnt2b"* is a 2 bit counter for generating the 25MHz pixel clock.
*	*"display_cntrl"* consists of *"disp_timing*", responsible for the monitor timing(HSYNC & VSYNC hence the 2 counters) and *"disp_out*", responsible for generating the pentagram and note masks for display. *"circle_mask*" is implemented as a separate module becaused it`s used for displaying chords.
*	*"kbd_protocol*" implements the PS/2 keyboard protocol.
*	*"sound_cntrl*" contains the module *"frequency_generator*" which consists of the modulo counters needed for generating the needed notes.


## File explanation

1.	The folder *"mapping_results"* contains the outputs of the FPGA mapping process by Xilinx ISE. The configuration file is *"mysynth.bit"*.
2.	The folder *"src"* contains all the Verilog code files of the implementation, the FPGA pin configuration file(ucf) and a testbench for the display controller. As I didn`t always have access to the lab for testing on the actual FPGA, I used this testbench which depicted a monitor frame on a txt file. Where there was black it printed 0 and where there was white 1, so by zooming out in Notepad the rough frame could be seen and needed changes could be made.
3.	The folder *"work"* contains the files used by ModelSim for simulations.
4.	The file *"example_architecture.png"* is the system architecture proposed by the project description.
5.	The file *"system.png"* is the final implemented system hierarchy.
