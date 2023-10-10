# Lab02 ZYSOC KV260 and FIR design
This lab is similar to Lab01. The board we use is KV260 and the cpp example is about FIR design.
### Resourse: https://github.com/bol-edu/course-lab_2

# AXI-Master Interface
## Vitis HLS
- Download three files from the github link above  
1.  FIR.cpp : Baic FIR C code
2.  FIR.h : Head file
3.  FIR.cpp : Testbench for the code

- First open Vitis_HLS and create a projrct
- Upload the HLS code/testbench in Vitis_HLS  
![HLS_code](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/vitis_hls.png)
      
- Run synthesis and cosimulation to ensure that we can get the correct result in the hardware
- Note that before we run the cosimulation, we need to comment out the pragma inculde ap_strl_none. Then, run synthesis and cosimulaion again to pass the cosimulation
![synthesis_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/hls_sythsis.png)  


- After we pass the cosimulation, exporting RTL IP with Vitis_HLS.
- Then open the Vivado
## Vivado
- Open Vivado; create a project
![vivado](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/vivado.png)

- Construct a block diagram. Then, ajust some parameters
![block diagram](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/block%20diagram.png)

- Then we generate Bitstream, which will include the Synthesis and Implemetation processes
- Find out **[project_name].bit** and **[project_name].hwh** and save the files in other directory to prepare for uploading the Bistreem on the FPGA board  

## MobaXterm and Online FPGA
- Open MobaXterm and set some SSH parameters to connect(rent) the Online FPGA
![MobaXterm](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/rent%20FPGA%20board.png)  

- Then copy the jupyter web ip port from MobaXterm and enter the password on the Internet
- So, we can open a Jupyter Notebook website

## Jupyter Notebook

# Stream Interface
