# Lab02 ZYSOC KV260 and FIR design
This lab is similar to Lab01. The board we use is KV260 and the cpp example is about FIR design.
### Resource: https://github.com/bol-edu/course-lab_2

# AXI-Master Interface
## Vitis HLS
- Download three files from the github link above  
1.  FIR.cpp : Baic FIR C code
2.  FIR.h : Head file
3.  FIRTester.cpp : Testbench for the code

- First open Vitis_HLS and create a projrct
- Upload the HLS code/testbench in Vitis_HLS  
![HLS_code](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/vitis_hls.png)
      
- Note that although there is KV260's Board file in VITIS HLS but we still get error when we run C simulation and C synthesis
![synthesis_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/hls_sythsis.png)  
- Exporting RTL IP 
- Then open the Vivado
## Vivado
- Open Vivado; create a project
![vivado](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/vivado.png)

- Construct a block diagram. Adjust some parameters, run block automation and onnection automation *2
![block diagram](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/block%20diagram.png)

- Then we generate Bitstream, which will include the Synthesis and Implemetation processes
- Find out **[project_name].bit** and **[project_name].hwh** and save the files in other directory to prepare for uploading the Bistreem on the FPGA board  

## MobaXterm and Online FPGA
- Open MobaXterm and set some SSH parameters to connect(rent) the Online FPGA
![MobaXterm](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/rent%20FPGA%20board.png)  

- Then copy the jupyter web ip port from MobaXterm and enter the password on the Internet
- So, we can open a Jupyter Notebook website

## Jupyter Notebook
Following the steps above, we can approach Jupyter Notebook
- Upload this two files and a Python code(from resource) to the context
![Jupyter Notebook](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/jupyter%20notebook.png)

- Run the Python code to get the final result
![result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/result.png)

# Stream Interface
