`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2023 05:41:06 PM
// Design Name: 
// Module Name: FIR
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


module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(   //wirte data with AXI-Light
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    // read data with AXI-Light
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

/**** Assign Output ****/

assign awready = awvalid;
assign wready = ;

assign arready = arvalid;
assign rvalid = ;

assign ss_tready = ;

assign sm_tvalid = ;
assign sm_tdata = ;
assign sm_tlast = ;

assign tap_WE = ;
assign tap_EN = ;
assign tap_Di = wdata;
assign tap_A = ;

assign data_WE = ;
assign data_EN = ;
assign data_Di = (ss_tvalid == 1) ? ss_tdata : 32'h00;
assign data_A = ;


//*** Configuration Register Address map ***//
reg ap_start;
reg ap_done;
reg ap_idle;
reg [(pDATA_WIDTH-1):0] data_lengh;
integer i;

//Read data
always@(*)begin
    if(rready) begin
     case(araddr)
      32'h00 : begin
            rdata[0] = ap_start;          // ap_start is read by TB
            rdata[1] = ap_down;            // ap_down is read by TB
            rdata[2] = ap_idle;          // ap_idle is read by TB
           end  
      32'h10 : rdata = data_lengh;           //check 
      32'h11 : rdata = data_lengh;
      32'h12 : rdata = data_lengh;
      32'h13 : rdata = data_lengh;
      32'h13 : rdata = data_lengh;
      32'h8x,32'h9x, 32'hAx,32'hBx,32'hCx,32'hDx, 32'hEx,32'hFx: rdata = tap_Do;     
      default: rdata = 0;
     endcase
   end
   else rdata = 0;
end

//Write data
always@(*)begin
    if(wready) begin
     case(awaddr)
      32'h00 : ap_start= wdata[0] ;          // ap_start is written by TB
      32'h10 : data_lengh = wdata;           //check 
      32'h11 : data_lengh = wdata;
      32'h12 : data_lengh = wdata;
      32'h13 : data_lengh = wdata;
      32'h13 : data_lengh = wdata;
      32'h8x,32'h9x, 32'hAx,32'hBx,32'hCx,32'hDx, 32'hEx,32'hFx: tap_Di = wdata;     
      default: tap_Di = 0;
      32'hFF : tap_Di = 0;
     endcase
   end
   else rdata = 0;
end


always@(posedge axis_clk)begin
  if(~axis_rst_n) 
    ap_done <= 0;
  else if(transfer_done)              //check 
    ap_done <= 1;
  else 
    ap_done <= ap_done;
end


always@(posedge axis_clk)begin
  if(~axis_rst_n) 
    ap_idle <= 1;
  else if(ap_state) 
    ap_idle <= 0;
  else if (proccess_done)              //check
    ap_idle <= 1;
  else 
    ap_idle <= ap_idle;
end

/**** Change Bram(Data) Address With Clock ****/

reg data_A_temp = 0;
always@ (posedge axis_clk) begin 
    if (axis_rst_n) // Reset Data Ram Address repeating
     data_A_temp <= 0;
    else if( data_A == 4'd11)
    data_A_temp <= 0;
    else    
     data_A_temp <= data_A_temp + 1'd1;
end    
 
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
end    
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

end
endmodule
