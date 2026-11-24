# Lab03: FIR Filter in Verilog (AXI-Lite + AXI-Stream)

A hand-written RTL version of the 11-tap FIR filter that Lab02 built with HLS.

| File | Role |
|---|---|
| `FIR.v` | Top module. 11-tap, 32-bit FIR with **one multiplier and one adder** that are reused over 11 cycles per output sample |
| `axilite.v` | AXI-Lite slave: writes the tap coefficients and data length, and handles `ap_start` / `ap_done` / `ap_idle` |
| `FSM.v` | Control FSM: `IDLE → LOAD` (stream in a sample) `→ CALC` (11-cycle MAC) `→ SEND` (stream out) `→ DONE` |
| `bram11.v` | 11-word BRAM model, used twice: once for the taps and once as a shift buffer for the input samples |
| `fir_tb.v` | Testbench: programs the taps over AXI-Lite, streams samples in and out over AXI-Stream, and compares against golden outputs |

**Interfaces**
- **AXI-Lite:** configuration and status.
- **AXI-Stream:** input data `ss_*` and output data `sm_*`.
