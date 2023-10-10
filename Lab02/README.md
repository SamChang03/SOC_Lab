# Lab02 ZYSOC KV260 and FIR design
This lab is similar to Lab01. The board we use is KV260 and the cpp example is about FIR design.
### Resource: https://github.com/bol-edu/course-lab_2

# AXI-Master Interface
## Vitis HLS
- Download three files from the github link above  
1.  FIR.cpp : Baic FIR C＋＋ code
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

- Construct a block diagram. Adjust some parameters
- NOTE: there is something different from Lab01. We need to open HP port to select AXI HP0 FPD
![HP port](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/HP%20port.png)
- Run block automation and onnection automation *2
![block diagram](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/block%20diagram.png)

- We can double check by using address editor
![Address editor](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/Address%20editor.png)

- Wrap the block diagram
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
This topic is almost the same as above, so I just note something different in this part

## Vivado
- Because AXI-Master to stream is implemented through Xilinx DMA(Direct Memory Access) IP, we need to adjust something in DMA IP
- When we construct the block diagram, we should add both the IP we disign and two Xilinx DMA IP components

#### Adjust some parameters in Xilinx DMA IP component
1. Disalbe Scatter-Gather Mode
2. Adjust Width of Buffer Length Register to 32 bits
3. Allocate two DMA to read one or write one.
4. If the DMA is the read one, we enalbe Read Channel.(the same way for write one)
5. Rename the read one to axi_dma_in_0, while read one to axi_dma_out_0(we may use it in python)
![Xilinx DMA IP component](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/Xilinx%20DMA%20IP%20component.png)

#### Build the block diagram
1. Click run connection automation*2
2. Note that in this case we need to connect two wires by ourselves
3. Connect pstrminput in FIR_N11_STRM to axi_dma_in_0 in M_AXIS_MM2S
4. Connect pstrmoutput in FIR_N11_STRM to axi_dma_out_0 in S_AXIS_S2MM
5. Finish the block diagram design and check the address
![block diagram2](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/block%20diagram2.png)

-Check the address
![Address](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/Address.png)

## Jupyter Notebook
![result2](https://github.com/SamChang03/SOC_Lab/blob/main/Lab02/Screen%20shot/result2.png)
