# Workload Optimized SoC Design

# Contributers
### Project Advisor:  
- 賴瑾（Jiin Lai）
### Students:
- [張育碩](https://github.com/SamChang03)

# Toolchain and Prerequisites
- Environment: Ubuntu 20.04
- Applications: Xilinx Vitis 2022.1 (Vitis_HLS / Vivado), GTKWave v3.3.103
- FPGA boards: Xilinx PYNQ-Z2 / ZYSOC KV260 / BASYS3
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
    └── vip                     # Caravel Verification IP


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

## System Overview

