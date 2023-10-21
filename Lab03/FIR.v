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

/**** Change Bram(Data) Address With Clock ****/

reg data_A_temp = 0;
always@ (posedge axis_clk) begin 
    if (axis_rst_n) // Reset Data Ram Address repeating
     data_A_temp <= 0;
    else if( data_A == 4'd11)
    data_A_temp <= 0;
    else    
     data_A_temp <= data_A_temp + 1'd1;
     
always@ (posedge axis_clk) begin //hold the data for a cycle
    if (axis_rst_n) 
     data <= 0;
    else 
     data <=data_A_temp;    
end

/**** Change Bram(Tap) Address With Clock ****/

reg tap_A_temp = 0;
always@ (posedge axis_clk) begin 
    if (axis_rst_n) // Reset Data Ram Address repeating
     tap_A_temp <= 0;
    else if( tap_A == 4'd11)
    tap_A_temp <= 0;
    else    
     tap_A_temp <= tap_A_temp + 1'd1;
     
always@ (posedge axis_clk) begin //hold the data for a cycle
    if (axis_rst_n) 
     tap <= 0;
    else 
     tap <= tap_A_temp;    
end

/**** Multify h and x and sum that****/
reg [(pDATA_WIDTH-1):0] yi;
reg [(pDATA_WIDTH-1):0] y;

always@ (posedge axis_clk) begin //hold the data for a cycle
    if (axis_rst_n) begin
     yi <= 0;
     y <=0;
    end
    else begin
     yi <= data_Do*tap_Do; 
     y <= y+yi ; 
    end 
endmodule
