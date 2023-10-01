# Lab 01 PYNQ-Z2
We will get familiar to the tool that we will use to develop our SOC in this Lab.  
### resourse: https://github.com/bol-edu/course-lab_1
## Vitis HLS
we downloaded the three files from the github link above  
1.  Multiplication.cpp : Baic mutiplication C code
2.  Multiplication.h : Head file
3.  MultipTester.cpp : Testbench for the code

Then we run the simulation to get the simulation result to check the HLS code meet our expectatoin  
![vitis_simulation](https://github.com/SamChang03/SOC_Lab/blob/main/Lab01/vitis_simulation.png)  
  
We move on to run synthesis and cosimulation to ensure that we can get the correct result in the hardware  
![synthesis_result](Lab01/synthesis_result.png)  
![cosimulation_result](Lab01/cosimulation_result.png)  
