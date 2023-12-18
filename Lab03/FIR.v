`timescale 1ns / 1ps

module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
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
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

    // write your code here!
    // addr decode
    localparam MAX_ADDR = (Tape_Num - 1) << 2; // 12'h28
    // fir state
    localparam S_IDLE = 3'd0; // idle state, wait for ap_start
    localparam S_LOAD = 3'd1; // stream in, data load to bram, wait for ss_tvalid
    localparam S_CALC = 3'd2; // read data from bram and calculate (11 cycles)
    localparam S_SEND = 3'd3; // finish calculation, wait for stream out finish (sm_tready)
    localparam S_DONE = 3'd4; // last data send to stream out and was acked, wait for ap_done acked

    // fir ctrl signal
    wire       ap_start;
    wire       ap_ready;
    wire       ap_done;
    wire       ap_idle;
    wire       ap_done_ack;
    wire  [2:0] state;
    reg  [3:0] i_r;              // counter for inner loop
    reg        first_ten_data_r; // first ten data flag, pad 0 to multiplier
    reg        last_r;           // last data flag
    wire       load_done;
    wire       calc_done;
    wire       send_done;
    // fir data signal
    wire [(pDATA_WIDTH-1):0] data_len;
    reg  [(pADDR_WIDTH-1):0] waddr_r;
    wire [(pADDR_WIDTH-1):0] raddr;
    wire [(pADDR_WIDTH-1):0] raddr_sft;  // circular shift for read addr
    wire [3:0]               axi_tap_we; // for axilite module output
    wire [(pADDR_WIDTH-1):0] axi_tap_a;  // for axilite module output
    reg  [(pDATA_WIDTH-1):0] acc_r; // shift add tmp data
    wire [(pDATA_WIDTH-1):0] mul_a, mul_b, mul_o;
    wire [(pDATA_WIDTH-1):0] add_a, add_b, add_o;
    // fir wire assignment
    assign load_done = (state == S_LOAD && ss_tvalid);
    assign calc_done = (i_r == Tape_Num);
    assign send_done = (state == S_SEND && sm_tready);
    assign ap_ready  = (state == S_IDLE && ap_start);
    assign ap_done   = (state == S_DONE);
    assign ap_idle   = (state == S_IDLE || state == S_DONE);
    assign raddr     = waddr_r + ((i_r + 1) << 2);
    assign raddr_sft = (raddr > MAX_ADDR) ? raddr - (MAX_ADDR + 12'h04) : raddr;
    assign mul_a     = (first_ten_data_r && i_r <= ((MAX_ADDR - waddr_r) >> 2) && i_r >= 1) ? 0 : data_Do;
    assign mul_b     = tap_Do;
    assign add_a     = acc_r;
    assign add_b     = mul_o;
    // output assignment
    assign ss_tready = (state == S_LOAD);
    assign sm_tvalid = (state == S_SEND);
    assign sm_tdata  = (state == S_SEND) ? acc_r : 0;
    assign sm_tlast  = (state == S_SEND & last_r);
    assign data_WE   = (load_done) ? 4'b1111 : 4'b0000;
    assign data_EN   = 1'b1;
    assign data_Di   = (load_done) ? ss_tdata : 0;
    assign data_A    = (load_done) ? waddr_r : raddr_sft;
    assign tap_WE    = (state == S_CALC) ? 4'b0000 : axi_tap_we;
    assign tap_EN    = 1'b1;
    assign tap_A     = (state == S_CALC) ? MAX_ADDR - (i_r << 2) : axi_tap_a;

    assign mul_o = $signed(mul_a) * $signed(mul_b);
    assign add_o = $signed(add_a) + $signed(add_b);
   
    
    
    // fir counter
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)   i_r <= 0;
        else if (state == S_CALC) begin
            if (calc_done) i_r <= 0;
            else           i_r <= i_r + 1;
        end
    end
    // fir write addr
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)             waddr_r <= 0;
        else if (send_done) begin
            if (waddr_r == MAX_ADDR) waddr_r <= 0;
            else                     waddr_r <= waddr_r + 12'h04;
        end
    end
    // fir first ten data
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)              first_ten_data_r <= 1;
        else if (waddr_r == MAX_ADDR) first_ten_data_r <= 0;
    end
    // fir last data
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)    last_r <= 0;
        else if (load_done) last_r <= ss_tlast;
    end
    // fir shift add reg
    always @(posedge axis_clk or negedge axis_rst_n) begin
        acc_r <= add_o;
        if (!axis_rst_n)                        acc_r <= 0;
        else if (state == S_CALC && i_r == 0) acc_r <= 0; // reset or new data
    end




    axilite #(
        .pADDR_WIDTH (pADDR_WIDTH),
        .pDATA_WIDTH (pDATA_WIDTH),
        .Tape_Num    (Tape_Num   )
    ) axilite_0
    (
        // from / to fir_tb
        .awready     (awready    ),
        .wready      (wready     ),
        .awvalid     (awvalid    ),
        .awaddr      (awaddr     ),
        .wvalid      (wvalid     ),
        .wdata       (wdata      ),
        .arready     (arready    ),
        .rready      (rready     ),
        .arvalid     (arvalid    ),
        .araddr      (araddr     ),
        .rvalid      (rvalid     ),
        .rdata       (rdata      ),
        .tap_WE      (axi_tap_we ),
        .tap_Di      (tap_Di     ),
        .tap_A       (axi_tap_a  ),
        .tap_Do      (tap_Do     ),
        // from / to fir
        .ap_start    (ap_start   ),
        .ap_ready    (ap_ready   ),
        .ap_done     (ap_done    ),
        .ap_idle     (ap_idle    ),
        .data_len    (data_len   ),
        .ap_done_ack (ap_done_ack),
        // clock and reset
        .axis_clk    (axis_clk   ),
        .axis_rst_n  (axis_rst_n )
    );
    
    fsm FSM(
        .state(state),
        .ss_tvalid(ss_tvalid),   
        .ap_done_ack(ap_done_ack),
        .last_r(last_r),
        .sm_tready(sm_tready),
        .calc_done(calc_done),    
        .ap_start(ap_start),
        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
    );
    

endmodule
