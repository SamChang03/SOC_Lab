`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/19/2023 12:04:58 AM
// Design Name: 
// Module Name: FSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm(

output reg [2:0]state,
input  ss_tvalid,   
input  ap_done_ack,
input  last_r,
input  sm_tready,
input  calc_done,    
input  ap_start,
input  axis_clk,
input  axis_rst_n
);    

reg [2:0] next_state;

localparam S_IDLE = 3'd0; // idle state, wait for ap_start
localparam S_LOAD = 3'd1; // stream in, data load to bram, wait for ss_tvalid
localparam S_CALC = 3'd2; // read data from bram and calculate (11 cycles)
localparam S_SEND = 3'd3; // finish calculation, wait for stream out finish (sm_tready)
localparam S_DONE = 3'd4; // last data send to stream out and was acked, wait for ap_done acked
 
// fir state machine
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: if (ap_start)    next_state = S_LOAD;
            S_LOAD: if (ss_tvalid)   next_state = S_CALC;
            S_CALC: if (calc_done)   next_state = S_SEND;
            S_SEND: begin
                if (sm_tready) begin
                    if (last_r)      next_state = S_DONE;
                    else             next_state = S_LOAD;
                end
            end
            S_DONE: if (ap_done_ack) next_state = S_IDLE;
            default:                 next_state = state;
        endcase
    end
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) state <= S_IDLE;
        else             state <= next_state;
    end
 
endmodule
