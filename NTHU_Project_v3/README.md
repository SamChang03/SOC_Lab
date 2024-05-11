# Workload Optimized SoC Design

## Contributers
### Project Advisor:  
- 賴瑾（Jiin Lai）
### Students:
- [張育碩](https://github.com/SamChang03)

## Abstract
SoC (System on Chip) is a complete computer system on a chip, which includes a 
microprocessor, memory, peripherals, and other necessary components for a specific 
application. This integration presents numerous advantages, such as compact size, 
heightened power efficiency, and enhanced versatility. Furthermore, SoC can fully utilize
existing design accumulations enhancing the design capability of ASICs. Therefore, SoC 
is an inevitable trend in the development of integrated circuits and also represents the 
future direction of the IC industry.
  
In this project, we develop our work on Efabless Caravel “Harness” SoC platform. 
We synthesize and implement the hardware with Xilinx Vivado environment. 
Subsequently, we verify the circuit's functionality on an online FPGA. By the project's 
conclusion, we gain valuable insights into software-hardware codesign, employing it to 
accelerate three workloads (FIR, MM, and QS) by implementing them into hardware, 
comparing the results with the baseline firmware execution.

# Caravel SoC
Caravel SoC is a platform for developing RISC-V CPU based hardware and software referred from [Efabless Caravel “harness” SoC](https://caravel-harness.readthedocs.io/en/latest/#efabless-caravel-harness-soc). You can develop and integrate custom design into this platform, then vefify their functionality with open source toolchain.  
![Caravel SoC](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/Caravel%20SoC.png)

## Caravel SoC FPGA Development Environment
![Caravel SoC FPGA Development Environment](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/Caravel%20SoC%20FPGA%20Development%20Environment.png)

# Toolchain and Prerequisites
- Environment: Ubuntu 20.04
- Applications: Xilinx Vitis 2022.1 (Vitis_HLS / Vivado), GTKWave v3.3.103
- FPGA boards: Xilinx PYNQ-Z2 / ZYSOC KV260
- Remote network tool: MobaXterm V23.2

# Directory Structure
    ├── cvc-pdk                 # SKY130 OpenRAM SRAM Model
    ├── firmware                # Caravel System Firmware Libraries
    ├── rtl                     # Caravel RTL Designs
    │   ├── header              # Headers
    │   ├── soc                 # Boledu Revised SoC
    │   ├── user                # User Project Designs
    ├── testbench               # Caravel Testbenches
    │   ├── counter_la          # Counter with Logic Analyzer Interface
    │   ├── counter_wb          # Counter with Wishbone Interface
    │   └── gcd_la              # GCD with Logic Analyzer Interface
    ├── vip                     # Caravel Verification IP
    └── vivido                  # Generate Hardware throuth Xilinx Vivado


## System Overview
![System Overview](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/%E6%BC%94%E7%AE%97%E6%B3%95%E6%9E%B6%E6%A7%8B.png)

## FIR
![FIR](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/FIR_structure.drawio.png)

## MM
![MM](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/MM_structure.drawio.png)

## QS
![QS](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/QS_structure%20.drawio.png)

## Quality of Service (QOS)
![QOS](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/QoS.png)

## Utilization Table
![Utilization Table](https://github.com/SamChang03/SOC_Lab/blob/main/NTHU_Project_v2/Utilization%20Table.png)
