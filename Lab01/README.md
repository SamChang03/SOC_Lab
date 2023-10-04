# Lab 01 PYNQ-Z2
We will get more familiar with tools that we will use to develop our SOC in this Lab.  
### Resourse: https://github.com/bol-edu/course-lab_1
## Vitis HLS
- Download three files from the github link above  
1.  Multiplication.cpp : Baic mutiplication C code
2.  Multiplication.h : Head file
3.  MultipTester.cpp : Testbench for the code

- First open Vitis_HLS and create a projrct
- Upload the HLS code/testbench in Vitis_HLS  
![HLS_code](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/HLS%20code.png)

- Run the simulation to get the simulation result and check the HLS code meet our expectatoin
![vitis_simulation](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/vitis_simulation.png)  
      
- Run synthesis and cosimulation to ensure that we can get the correct result in the hardware
- Note that before we run the cosimulation, we need to comment out the pragma inculde ap_strl_none. Then, run synthesis and cosimulaion again to pass the cosimulation
![synthesis_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/synthesis_result.png)  
![cosimulation_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/cosimulation_result.png)  

- After we pass the cosimulation, exporting RTL IP with Vitis_HLS.
- Then open the Vivado
## Vivado
- Open Vivado; create a project
![vivado](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/rent%20FPGA%20board.png)

- Construct a block diagram. Then, ajust some parameters
- PS: The folling sreenshot is from the handout in above URL
![block diagram](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/block%20diagram.png)

- Then we generate Bitstream, which will include the Synthesis and Implemetation processes
- Find out **[project_name].bit** and **[project_name].hwh** and save the files in other directory to prepare for uploading the Bistreem on the FPGA board  

## MobaXterm and Online FPGA
- Open MobaXterm and set some SSH parameters to connect(rent) the Online FPGA
![MobaXterm](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/rent%20FPGA%20board.png)  

- Then copy the jupyter web ip port from MobaXterm and enter the password on the Internet
- So, we can open a Jupyter Notebook website

## Jupyter Notebook  
- Following the steps above, we can approach Jupyter Notebook
- Upload this two files and a Python code(from resource) to the context
![Jupyter Notebook](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/jupyter.png)

- Run the Python code to get the final result
![result_1](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/python%20code%201.png)
![result_2](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/python%20code%202.png)

