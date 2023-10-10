# Lab02 KV260 and FIR design
This lab is similat to Lab01 but the board we use is KV260. And, we construct the FIR disigh 
### Resourse: https://github.com/bol-edu/course-lab_2

# AXI-Master Interface
## Vitis HLS
- Download three files from the github link above  
1.  Multiplication.cpp : Baic mutiplication C code
2.  Multiplication.h : Head file
3.  MultipTester.cpp : Testbench for the code

- First open Vitis_HLS and create a projrct
- Upload the HLS code/testbench in Vitis_HLS  
![HLS_code]()

- Run the simulation to get the simulation result and check the HLS code meet our expectatoin
![vitis_simulation]()  
      
- Run synthesis and cosimulation to ensure that we can get the correct result in the hardware
- Note that before we run the cosimulation, we need to comment out the pragma inculde ap_strl_none. Then, run synthesis and cosimulaion again to pass the cosimulation
![synthesis_result]()  
![cosimulation_result]()  

- After we pass the cosimulation, exporting RTL IP with Vitis_HLS.
- Then open the Vivado
## Vivado
- Open Vivado; create a project
![vivado]()

- Construct a block diagram. Then, ajust some parameters
- PS: The folling sreenshot is from the handout in above URL
![block diagram]()

- Then we generate Bitstream, which will include the Synthesis and Implemetation processes
- Find out **[project_name].bit** and **[project_name].hwh** and save the files in other directory to prepare for uploading the Bistreem on the FPGA board  

## MobaXterm and Online FPGA
- Open MobaXterm and set some SSH parameters to connect(rent) the Online FPGA
![MobaXterm]()  

- Then copy the jupyter web ip port from MobaXterm and enter the password on the Internet
- So, we can open a Jupyter Notebook website

## Jupyter Notebook

# Stream Interface
