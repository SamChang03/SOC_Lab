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
    reg  [2:0] state_r, state_w;
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
    assign load_done = (state_r == S_LOAD && ss_tvalid);
    assign calc_done = (i_r == Tape_Num);
    assign send_done = (state_r == S_SEND && sm_tready);
    assign ap_ready  = (state_r == S_IDLE && ap_start);
    assign ap_done   = (state_r == S_DONE);
    assign ap_idle   = (state_r == S_IDLE || state_r == S_DONE);
    assign raddr     = waddr_r + ((i_r + 1) << 2);
    assign raddr_sft = (raddr > MAX_ADDR) ? raddr - (MAX_ADDR + 12'h04) : raddr;
    assign mul_a     = (first_ten_data_r && i_r <= ((MAX_ADDR - waddr_r) >> 2) && i_r >= 1) ? 0 : data_Do;
    assign mul_b     = tap_Do;
    assign add_a     = acc_r;
    assign add_b     = mul_o;
    // output assignment
    assign ss_tready = (state_r == S_LOAD);
    assign sm_tvalid = (state_r == S_SEND);
    assign sm_tdata  = (state_r == S_SEND) ? acc_r : 0;
    assign sm_tlast  = (state_r == S_SEND & last_r);
    assign data_WE   = (load_done) ? 4'b1111 : 4'b0000;
    assign data_EN   = 1'b1;
    assign data_Di   = (load_done) ? ss_tdata : 0;
    assign data_A    = (load_done) ? waddr_r : raddr_sft;
    assign tap_WE    = (state_r == S_CALC) ? 4'b0000 : axi_tap_we;
    assign tap_EN    = 1'b1;
    assign tap_A     = (state_r == S_CALC) ? MAX_ADDR - (i_r << 2) : axi_tap_a;

    // fir state machine
    always @(*) begin
        state_w = state_r;
        case (state_r)
            S_IDLE: if (ap_start)    state_w = S_LOAD;
            S_LOAD: if (ss_tvalid)   state_w = S_CALC;
            S_CALC: if (calc_done)   state_w = S_SEND;
            S_SEND: begin
                if (sm_tready) begin
                    if (last_r)      state_w = S_DONE;
                    else             state_w = S_LOAD;
                end
            end
            S_DONE: if (ap_done_ack) state_w = S_IDLE;
            default:                 state_w = state_r;
        endcase
    end
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) state_r <= S_IDLE;
        else             state_r <= state_w;
    end
    // fir counter
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n)   i_r <= 0;
        else if (state_r == S_CALC) begin
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
        else if (state_r == S_CALC && i_r == 0) acc_r <= 0; // reset or new data
    end

    mul #(.pDATA_WIDTH (pDATA_WIDTH)) mul_0
    (
        .a (mul_a),
        .b (mul_b),
        .p (mul_o)
    );

    add #(.pDATA_WIDTH (pDATA_WIDTH)) add_0
    (
        .a (add_a),
        .b (add_b),
        .s (add_o)
    );

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

endmodule

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

module mul
#(
    parameter pDATA_WIDTH = 32
)
(
    input  wire [(pDATA_WIDTH-1):0] a,
    input  wire [(pDATA_WIDTH-1):0] b,
    output wire [(pDATA_WIDTH-1):0] p
);
    assign p = $signed(a) * $signed(b);

endmodule

module add
#(
    parameter pDATA_WIDTH = 32
)
(
    input  wire [(pDATA_WIDTH-1):0] a,
    input  wire [(pDATA_WIDTH-1):0] b,
    output wire [(pDATA_WIDTH-1):0] s
);

    assign s = $signed(a) + $signed(b);

endmodule
