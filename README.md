# SoC Design Lab

My labs and final project for **EE5251 Topics on SoC Design** (11210EE525100) at National Tsing Hua University (Fall 2023). The course covers hardware/software co-design on FPGA SoCs: Vitis HLS kernels driven from Python on PYNQ, hand-written AXI RTL, and finally accelerators integrated into a RISC-V **Caravel SoC** running on an FPGA.

- **Instructor:** Jiin Lai (賴瑾)
- **Author:** Yu-Shuo Chang (張育碩)

## Labs at a glance

| Folder | Topic | What I built |
|---|---|---|
| [Lab01](Lab01) | Vitis HLS flow on **PYNQ-Z2** | HLS multiplier IP → Vivado block design → bitstream, driven from a Jupyter notebook on a remote FPGA |
| [Lab02](Lab02) | HLS FIR filter on **KV260** | 11-tap FIR in two versions, with an **AXI-Master** interface (`hls_FIRN11MAXI`) and with an **AXI-Stream** interface plus an AXI DMA (`hls_FIRN11Stream`). Each has a Python host notebook |
| [Lab03](Lab03) | FIR in Verilog | Hand-written AXI-Lite and AXI-Stream FIR with a single shared MAC, an FSM, tap and data BRAMs, and a self-checking testbench |
| [Final Project](Final-Project-WLOS) | **Workload-Optimized SoC (WLOS)** | Three workloads (FIR, 4×4 matrix multiply, quicksort) accelerated in the user area of the Caravel RISC-V SoC |

Lab01 and Lab02 have step-by-step READMEs with screenshots of the full flow, from HLS through Vivado to Jupyter.

## Final project: Workload-Optimized SoC

The three workloads run on the Caravel "harness" SoC (a VexRiscv CPU with a Wishbone bus). Each one has a hardware accelerator in the user project area, and the design was implemented in Vivado and run on an online FPGA.

| Part | Modules (in `Final-Project-WLOS/rtl/user`) |
|---|---|
| Accelerators | `fir.v`, `mm.v`, `qsort.v` |
| Data movement | `DMA_FIR.v`, `DMA_MM.v`, `DMA_QS.v`. These DMA engines feed each accelerator from SDRAM |
| Memory system | `sdram_controller.v`, `sdram_arbiter.v` (with prefetch), `sdr.v` |
| Bus glue | `WB_decoder.v`, `WB_to_AXI.v`, `WB_to_controller.v`, `user_project_wrapper.v` |
| UART | `uart*.v` |

**Result:** compared with running the same workloads in RISC-V firmware, the accelerated SoC needs **500–1000× fewer cycles**, while FPGA utilization grows by less than 2×. See the [project README](Final-Project-WLOS/README.md) for block diagrams, QoS, and utilization.

## Tools

- Xilinx Vitis HLS 2022.1
- Xilinx Vivado
- Jupyter / PYNQ (Python)
- Verilog
- GTKWave
- MobaXterm

**Boards:** Xilinx PYNQ-Z2, AMD Kria KV260

The course materials come from [bol-edu](https://github.com/bol-edu): [course-lab_1](https://github.com/bol-edu/course-lab_1), [course-lab_2](https://github.com/bol-edu/course-lab_2), and [caravel-soc_fpga-lab](https://github.com/bol-edu/caravel-soc_fpga-lab).
