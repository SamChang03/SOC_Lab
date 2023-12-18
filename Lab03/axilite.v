`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/15/2023 12:52:34 AM
// Design Name: 
// Module Name: axilite
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


module axilite
#(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    // from / to fir_tb
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,
    output  wire [3:0]               tap_WE,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,
    // from / to fir
    output  wire                     ap_start,
    input   wire                     ap_ready,
    input   wire                     ap_done,
    input   wire                     ap_idle,
    output  wire [(pDATA_WIDTH-1):0] data_len,
    output  wire                     ap_done_ack,
    // clock and reset
    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

    // addr decode
    localparam ADDR_AP_CTRL   = 12'h00;
    localparam ADDR_DATA_LEN  = 12'h10;
    // localparam ADDR_TAP_BEGIN = 12'h20;
    localparam ADDR_TAP_BEGIN = 12'h80; // optimize
    localparam ADDR_TAP_END   = 12'hFF;

    // write state
    localparam WRIDLE  = 1'd0;
    localparam WRDATA  = 1'd1;
    // read state
    localparam RDIDLE  = 1'd0;
    localparam RDDATA  = 1'd1;

    // write ctrl signal
    reg  wstate_r, wstate_w;
    wire aw_hs, w_hs; // handshake signal
    wire ctrl_w_hs, len_w_hs, tap_w_hs;
    // write data signal
    reg [(pADDR_WIDTH-1):0] waddr_r;    // store addr to wait for w_hs
    reg                     ap_start_r; // tb config write
    reg [(pDATA_WIDTH-1):0] data_len_r; // tb config write
    // write wire assignment
    assign aw_hs     = (awvalid & awready);
    assign w_hs      = (wvalid & wready);
    assign ctrl_w_hs = (w_hs && waddr_r == ADDR_AP_CTRL);
    assign len_w_hs  = (w_hs && waddr_r == ADDR_DATA_LEN);
    assign tap_w_hs  = (w_hs && waddr_r <= ADDR_TAP_END && waddr_r >= ADDR_TAP_BEGIN);

    // read ctrl signal
    reg  rstate_r, rstate_w;
    wire ar_hs; // handshake signal
    wire ctrl_ar_hs, len_ar_hs, tap_ar_hs;
    reg  ctrl_ar_hs_r, tap_ar_hs_r;
    // read data signal
    wire [(pADDR_WIDTH-1):0] tap_addr;
    reg  [(pDATA_WIDTH-1):0] rdata_r; // store data to wait for rready
    // read wire assignment
    assign ar_hs      = (arvalid & arready);
    assign ctrl_ar_hs = (ar_hs && araddr == ADDR_AP_CTRL);
    assign len_ar_hs  = (ar_hs && araddr == ADDR_DATA_LEN);
    assign tap_ar_hs  = (ar_hs && araddr <= ADDR_TAP_END && araddr >= ADDR_TAP_BEGIN);
    assign tap_addr   = (tap_w_hs) ? waddr_r : araddr;

    // output assignment
    assign awready     = (wstate_r == WRIDLE);
    assign wready      = (wstate_r == WRDATA);
    assign arready     = (rstate_r == RDIDLE);
    assign rvalid      = (rstate_r == RDDATA);
    assign rdata       = (tap_ar_hs_r) ? tap_Do : rdata_r;
    assign tap_WE      = (tap_w_hs) ? 4'b1111 : 4'b0000;
    assign tap_Di      = wdata;
    // assign tap_A       = tap_addr - ADDR_TAP_BEGIN;
    assign tap_A       = {tap_addr[(pADDR_WIDTH-1):(pADDR_WIDTH-4)], 1'b0, tap_addr[(pADDR_WIDTH-6):0]}; // optimize
    assign data_len    = data_len_r;
    assign ap_start    = ap_start_r;
    assign ap_done_ack = ctrl_ar_hs_r;


    // write state machine
    always @(*) begin
        wstate_w = wstate_r;
        case (wstate_r)
            WRIDLE: if (awvalid) wstate_w = WRDATA;
            WRDATA: if (wvalid)  wstate_w = WRIDLE;
            default:             wstate_w = wstate_r;
        endcase
    end
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) wstate_r <= WRIDLE;
        else             wstate_r <= wstate_w;
    end
    // write addr
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) waddr_r <= 0;
        else if (aw_hs)  waddr_r <= awaddr;
    end
    // write data - ap_start
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)              ap_start_r <= 1'b0;
        else if (ctrl_w_hs & ap_idle) ap_start_r <= wdata[0];
        else if (ap_ready)            ap_start_r <= 1'b0;
    end
    // write data - data length
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)   data_len_r <= 0;
        else if (len_w_hs) data_len_r <= wdata;
    end

    // read state machine
    always @(*) begin
        rstate_w = rstate_r;
        case (rstate_r)
            RDIDLE: if (arvalid) rstate_w = RDDATA;
            RDDATA: if (rready)  rstate_w = RDIDLE; // rvalid is also high
            default:             rstate_w = rstate_r;
        endcase
    end
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) rstate_r <= RDIDLE;
        else             rstate_r <= rstate_w;
    end
    // read data - tap ctrl, ap_done ack
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            ctrl_ar_hs_r <= 0;
            tap_ar_hs_r  <= 0;
        end
        else if (ctrl_ar_hs)             ctrl_ar_hs_r <= 1;
        else if (ctrl_ar_hs_r && rready) ctrl_ar_hs_r <= 0;
        else                             tap_ar_hs_r  <= tap_ar_hs; // assert for 1 cycle only
    end
    // read data - ap_start, ap_done, ap_idle, data_length
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)      rdata_r      <= 0;
        else if (ctrl_ar_hs)  rdata_r[2:0] <= {ap_idle, ap_done, ap_start_r};
        else if (len_ar_hs)   rdata_r      <= data_len_r;
        else if (tap_ar_hs_r) rdata_r      <= tap_Do;
    end

endmodule