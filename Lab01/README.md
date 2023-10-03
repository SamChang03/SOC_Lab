# Lab 01 PYNQ-Z2
We will get more familiar to the tool that we will use to develop our SOC in this Lab.  
### Resourse: https://github.com/bol-edu/course-lab_1
## Vitis HLS
- Download the three files from the github link above  
1.  Multiplication.cpp : Baic mutiplication C code
2.  Multiplication.h : Head file
3.  MultipTester.cpp : Testbench for the code

- First open the Vitis and upload the HLS code/testbench in the Vitis HLS
![HLS_code](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/HLS%20code.png)

- Run the simulation to get the simulation result and check the HLS code meet our expectatoin
![vitis_simulation](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/vitis_simulation.png)  
      
- Run synthesis and cosimulation to ensure that we can get the correct result in the hardware
- Note that before we run the cosimulation, we need to comment out the pragma inculd ap_strl_none. Then, run the synthesis and the cosimulaion again and passing the cosimulation
![synthesis_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/synthesis_result.png)  
![cosimulation_result](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/cosimulation_result.png)  

- After we pass the cosimulation, exporting RTL IP with Vitis_HLS.
- Then open the Vivado
## Vivado
- Open the Vivado, create a project and construct a block diagram. Then, ajust some parameters
- PS: The folling sreenshot is from the handout in above URL
![block diagram](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/block%20diagram.png)

- Then we generate Bitstream, which will include the Synthesis and Implemetation processes
- Find out project_name.bit and == project_name.hwh == and save the files in other directory to prepare for the Demo on the FPGA
