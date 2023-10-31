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

assign awready=(awvalid)?1'b1:1'b0; //when we get the wvalid, we send awready
assign wready=(wvalid)?1'b1:1'b0;

assign arready = (~wready)?1'b1:1'b0;
assign rvalid = (!wready)?1'b1:1'b0;
assign rdata = rdata_reg;

assign ss_tready = (ap_start&ap_idle)|sm_tvalid;

assign sm_tvalid = (~ap_start)&(sm_cnt>12'd10);
assign sm_tdata = (sm_tvalid&sm_tready)?temp:sm_tdata;
assign sm_tlast = (data_cnt==data_length)& ap_start ;

assign tap_WE = {4{(write_en&awrite_en)&(awaddr>=12'h20)}};
assign tap_EN = (((write_en&awrite_en)|(read_en&aread_en))&((awaddr>=12'h20)||(araddr>=12'h20))|(ap_start))?1'b1:1'b0;
assign tap_Di = wdata;
assign tap_A = awaddr-12'h20;

assign data_WE = {4{(ss_tready & ss_tvalid)}};
assign data_EN=(ss_tvalid&ss_tready|(!ss_tlast)|ap_start)?1'b1:1'b0;
assign data_Di=(data_EN)?ss_tdata:data_Di;
assign data_A=(data_EN)?(!ap_start)?12'h00:data_write_pnt:12'd40;

//assign read / write enable
assign write_en=(wvalid&wready)?1'b1:1'b0;
assign awrite_en=(awvalid&awready)?1'b1:1'b0;
assign read_en=(rvalid&rready)?1'b1:1'b0;
assign aread_en=(arvalid&arready)?1'b1:1'b0;

reg [(pDATA_WIDTH-1):0]data_cnt;
reg [(pDATA_WIDTH-1):0]temp;
reg [(pADDR_WIDTH-1):0]data_write_pnt,sm_cnt,offset,j_cnt;


//*** Configuration Register Address map ***//
reg ap_start;
reg ap_done;
reg ap_idle;
reg [(pDATA_WIDTH-1):0] data_lengh;
reg [(pDATA_WIDTH-1):0] rdata_reg;

//Decide the rdata 
always@(*)begin
	if(read_en & aread_en)begin
		if(araddr==12'h00)begin
			rdata_reg[0]<=ap_start;
			rdata_reg[1]<=ap_done;
			rdata_reg[2]<=ap_idle;
		end
		else if(araddr>=12'h20)
			rdata_reg<=tap_Do;
		else 
			rdata_reg<=rdata_reg;
	end
	else
	 rdata_reg<=rdata_reg;
end


//Write data length
always@(posedge axis_clk)begin
    if(~axis_rst_n) 
        data_length<=data_length;
	else if(write_en & awrite_en & (awaddr==12'h10))  
	   data_length<=wdata;
	else 
	   data_length<=data_length;
end

//ap_idle control
always@(posedge axis_clk)begin
	if(!axis_rst_n)begin
		ap_idle<=1'b1;
	end
	else if(ap_done)begin
		ap_idle<=1'b1;
	end
	else if(ap_start)begin
		ap_idle<=1'b0;
	end
	else begin
		ap_idle<=1'b1;
	end
end

//ap_down control
always@(posedge axis_clk)begin
	if(!axis_rst_n)
		ap_done<=1'b0;
	else if(sm_tlast)
		ap_done<=1'b1;
	else 
		ap_done<=1'b0;
end

//last of data
always@(posedge axis_clk)begin
	if(!axis_rst_n)begin
		data_cnt<=32'd0;
		sm_tlast<=1'b0;
	end
	else if(data_cnt == data_length)begin
		data_cnt<=data_cnt;
		sm_tlast<=1'b1;
	end
	else if(ap_start) begin
		data_cnt<=data_cnt+32'b1;
		sm_tlast<=1'b0;
	end
end


//*** FIR Calculation ***//

always@(posedge axis_clk)begin
	if(ap_idle|ss_tready)begin
		temp<=32'd0;
	end
	else if(ap_start)begin
		temp<=temp+mul*tap_Do;
	end
	else begin
		temp<=temp;
	end
end

always@(posedge axis_clk)begin
	if(~axis_clk)begin
		mul<=32'd0;
	end
	else if((sm_cnt>1)&(sm_cnt<=j_cnt+12'd1))begin
		mul<=data_Do;
	end
	else begin
		mul<=32'd0;
	end
end


always@(posedge axis_clk)begin
    if(~ap_start)
        sm_cnt<=12'd0;
    else if(sm_cnt>12'd10)
        sm_cnt<=12'd0;
    else 
        sm_cnt<=sm_cnt+12'd1;

end

always@(posedge axis_clk)begin
    if((~axis_rst_n)|(offset>12'd10))begin
        offset<=12'd0;
    end
    else if(ss_tready)begin
        offset<=offset+12'd1;
    end
    else begin
        offset<=offset;
    end
end

always@(posedge axis_clk)begin
    if(~ap_start)begin
        data_read_pnt<=12'd28;
    end
    else if(ss_tready)begin
        data_read_pnt<=12'h28-offset*4;
    end
    else if(data_read_pnt<12'h28)begin
        data_read_pnt<=data_read_pnt+12'd4;
    end
    else begin
        data_read_pnt<=12'h0;
    end
end

always@(posedge axis_clk)begin
    if(~axis_rst_n)begin
        j_cnt<=12'd0;
    end
    else if(ss_tready)begin
        j_cnt<=j_cnt+12'd1;
    end
    else if(j_cnt>12'd11)begin
        j_cnt<=j_cnt;
    end
    else begin
        j_cnt<=j_cnt;
    end
end

endmodule
