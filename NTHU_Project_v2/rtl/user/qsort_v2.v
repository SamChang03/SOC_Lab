module mm 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)
(
    input   wire                     axis_clk,
    input   wire                     axis_rst_n,
    
    // ap_start from DMA
    input   wire                     mm_start_whole,
    output   wire                     mm_done_whole,
    /////output   wire                     mm_idle,

    // Data in (AXI-Stream)
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    //input   wire                     ss_tlast, //not used
    output  reg                     ss_tready,

    // Data out (AXI-Stream)
    input   wire                     sm_tready, 
    output  reg                     sm_tvalid, 
    output  reg [(pDATA_WIDTH-1):0] sm_tdata
    //output  wire                     sm_tlast, //not used
);

// Design by yuhungwei, testbench by zeus950068, modified by whywhytellmewhy
localparam IDLE = 4'd0;
localparam WAIT_MATRIX_A1_HANDSHAKE = 4'd1;
localparam INPUT_MATRIX_A_row1= 4'd2;

localparam WAIT_MATRIX_B_HANDSHAKE= 4'd3;
localparam INPUT_MATRIX_B_column = 4'd4;

localparam OUTPUT_row1 = 4'd5;
localparam WAIT_MATRIX_A_rest_row_HANDSHAKE = 4'd6;
localparam INPUT_MATRIX_A_rest_row = 4'd7;
localparam OUTPUT_rest_row = 4'd8;
localparam DONE = 4'd9;


wire mm_start; // modified
wire mm_done; // modified
wire mm_idle; // modified
assign mm_done_whole=mm_idle; // modified

reg ss_tready_before_FF;
reg sm_tvalid_before_FF;
reg [(pDATA_WIDTH-1):0] sm_tdata_before_FF;

reg         [3:0]           n_state;
reg         [3:0]           c_state;
//matrix A * matrix B == matrix C
reg         [4:0]           cnt_output, next_cnt_output;
reg         [1:0]           cnt_input, next_cnt_input;

reg    [(pDATA_WIDTH-1):0]  A1,A2,A3,A4;
reg    [(pDATA_WIDTH-1):0]  B11,B12,B13,B14;
reg    [(pDATA_WIDTH-1):0]  B21,B22,B23,B24;
reg    [(pDATA_WIDTH-1):0]  B31,B32,B33,B34;
reg    [(pDATA_WIDTH-1):0]  B41,B42,B43,B44;
reg    [(pDATA_WIDTH-1):0]  next_A1,next_A2,next_A3,next_A4;
reg    [(pDATA_WIDTH-1):0]  next_B11,next_B12,next_B13,next_B14;
reg    [(pDATA_WIDTH-1):0]  next_B21,next_B22,next_B23,next_B24;
reg    [(pDATA_WIDTH-1):0]  next_B31,next_B32,next_B33,next_B34;
reg    [(pDATA_WIDTH-1):0]  next_B41,next_B42,next_B43,next_B44;
wire   [(pDATA_WIDTH-1):0]  mac1,mac2,mac3,mac4; // MUL & ADD


assign mm_start = (ss_tvalid && ss_tready) ? 1:0;
assign mm_done = (sm_tvalid && sm_tready) ? 1:0;
assign mm_idle = (c_state == DONE) ? 1:0;


//MAC
assign mac1 = A1 * B11 + A2 * B21 + A3 * B31 + A4 * B41;
assign mac2 = A1 * B12 + A2 * B22 + A3 * B32 + A4 * B42;
assign mac3 = A1 * B13 + A2 * B23 + A3 * B33 + A4 * B43;
assign mac4 = A1 * B14 + A2 * B24 + A3 * B34 + A4 * B44;

/////////////////////////////////////////////
///FSM
/////////////////////////////////////////////
always @(posedge axis_clk or negedge axis_rst_n) begin
	if(!axis_rst_n) begin
		c_state <= IDLE;
        ss_tready <= 0;
        sm_tvalid <= 0;
        sm_tdata <= 0;
        A1  <= 0;
        A2  <= 0;
        A3  <= 0;
        A4  <= 0;
        B11 <= 0;
        B12 <= 0;
        B13 <= 0;
        B14 <= 0;
        B21 <= 0;
        B22 <= 0;
        B23 <= 0;
        B24 <= 0;
        B31 <= 0;
        B32 <= 0;
        B33 <= 0;
        B34 <= 0;
        B41 <= 0;
        B42 <= 0;
        B43 <= 0;
        B44 <= 0;
        cnt_output <= 0;
        cnt_input <= 0;
	end
	else begin
		c_state <= n_state;
        ss_tready <= ss_tready_before_FF;
        sm_tvalid <= sm_tvalid_before_FF;
        sm_tdata <= sm_tdata_before_FF;
        A1  <= next_A1 ;
        A2  <= next_A2 ;
        A3  <= next_A3 ;
        A4  <= next_A4 ;
        B11 <= next_B11;
        B12 <= next_B12;
        B13 <= next_B13;
        B14 <= next_B14;
        B21 <= next_B21;
        B22 <= next_B22;
        B23 <= next_B23;
        B24 <= next_B24;
        B31 <= next_B31;
        B32 <= next_B32;
        B33 <= next_B33;
        B34 <= next_B34;
        B41 <= next_B41;
        B42 <= next_B42;
        B43 <= next_B43;
        B44 <= next_B44;
        cnt_output <= next_cnt_output;
        cnt_input <= next_cnt_input;
	end
end

always @(*) begin
    next_A1=A1;
    next_A2=A2;
    next_A3=A3;
    next_A4=A4;
    next_B11=B11;
    next_B12=B12;
    next_B13=B13;
    next_B14=B14;
    next_B21=B21;
    next_B22=B22;
    next_B23=B23;
    next_B24=B24;
    next_B31=B31;
    next_B32=B32;
    next_B33=B33;
    next_B34=B34;
    next_B41=B41;
    next_B42=B42;
    next_B43=B43;
    next_B44=B44;


    case(c_state)
        //0
        IDLE: begin // modified
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_input=0;
            next_cnt_output=0;
            
            if(mm_start_whole) begin // ap_start
                n_state = WAIT_MATRIX_A1_HANDSHAKE;
                ss_tready_before_FF=1;
            end
            else begin
                n_state = IDLE;
                ss_tready_before_FF=0;
            end
        end
        WAIT_MATRIX_A1_HANDSHAKE:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_input=0;
            next_cnt_output=0;

            if(mm_start) begin // ss handshake
                n_state = INPUT_MATRIX_A_row1;
            end
            else begin
                n_state = WAIT_MATRIX_A1_HANDSHAKE;
            end
        end
        INPUT_MATRIX_A_row1:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_output=0;

            if(cnt_input==3) begin
                n_state = WAIT_MATRIX_B_HANDSHAKE;
                next_A4=ss_tdata;
                next_cnt_input=0;
            end
            else if(cnt_input==2) begin
                n_state = INPUT_MATRIX_A_row1;
                next_A3=ss_tdata;
                next_cnt_input=cnt_input+1;
            end
            else if(cnt_input==1) begin
                n_state = INPUT_MATRIX_A_row1;
                next_A2=ss_tdata;
                next_cnt_input=cnt_input+1;
            end
            else begin
                n_state = INPUT_MATRIX_A_row1;
                next_A1=ss_tdata;
                next_cnt_input=cnt_input+1;
            end
        end
        WAIT_MATRIX_B_HANDSHAKE:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_input=0;
            next_cnt_output=cnt_output;

            if(mm_start) begin // ss handshake
                n_state = INPUT_MATRIX_B_column;
            end
            else begin
                n_state = WAIT_MATRIX_B_HANDSHAKE;
            end
        end
        INPUT_MATRIX_B_column:begin
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_output=cnt_output;

            if(cnt_input==3) begin
                n_state = OUTPUT_row1;
                ss_tready_before_FF=0;
                if(cnt_output==0) begin
                    next_B41=ss_tdata;
                end
                else if(cnt_output==1) begin
                    next_B42=ss_tdata;
                end
                else if(cnt_output==2) begin
                    next_B43=ss_tdata;
                end
                else begin
                    next_B44=ss_tdata;
                end
                next_cnt_input=0;
            end
            else if(cnt_input==2) begin
                n_state = INPUT_MATRIX_B_column;
                ss_tready_before_FF=1;
                if(cnt_output==0) begin
                    next_B31=ss_tdata;
                end
                else if(cnt_output==1) begin
                    next_B32=ss_tdata;
                end
                else if(cnt_output==2) begin
                    next_B33=ss_tdata;
                end
                else begin
                    next_B34=ss_tdata;
                end
                next_cnt_input=cnt_input+1;
            end
            else if(cnt_input==1) begin
                n_state = INPUT_MATRIX_B_column;
                ss_tready_before_FF=1;
                if(cnt_output==0) begin
                    next_B21=ss_tdata;
                end
                else if(cnt_output==1) begin
                    next_B22=ss_tdata;
                end
                else if(cnt_output==2) begin
                    next_B23=ss_tdata;
                end
                else begin
                    next_B24=ss_tdata;
                end
                next_cnt_input=cnt_input+1;
            end
            else begin
                n_state = INPUT_MATRIX_B_column;
                ss_tready_before_FF=1;
                if(cnt_output==0) begin
                    next_B11=ss_tdata;
                end
                else if(cnt_output==1) begin
                    next_B12=ss_tdata;
                end
                else if(cnt_output==2) begin
                    next_B13=ss_tdata;
                end
                else begin
                    next_B14=ss_tdata;
                end

                next_cnt_input=cnt_input+1;
            end
        end
        OUTPUT_row1:begin
            next_cnt_input=0;

            if (mm_done) begin // sm handshake
                sm_tvalid_before_FF=0;
                sm_tdata_before_FF=0;
                next_cnt_output=cnt_output+1;
                if(cnt_output==3) begin
                    n_state = WAIT_MATRIX_A_rest_row_HANDSHAKE;
                    ss_tready_before_FF=1;
                end
                else begin
                    n_state = WAIT_MATRIX_B_HANDSHAKE;
                    ss_tready_before_FF=0;
                end
            end
            else begin
                n_state = OUTPUT_row1;
                ss_tready_before_FF=0;
                sm_tvalid_before_FF=1;
                next_cnt_output=cnt_output;
                if(cnt_output==0) begin
                    sm_tdata_before_FF=mac1;
                end
                else if(cnt_output==1) begin
                    sm_tdata_before_FF=mac2;
                end
                else if(cnt_output==2) begin
                    sm_tdata_before_FF=mac3;
                end
                else begin
                    sm_tdata_before_FF=mac4;
                end
                
            end
        end
        WAIT_MATRIX_A_rest_row_HANDSHAKE:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_input=0;
            next_cnt_output=cnt_output;

            if(mm_start) begin // ss handshake
                n_state = INPUT_MATRIX_A_rest_row;
            end
            else begin
                n_state = WAIT_MATRIX_A_rest_row_HANDSHAKE;
            end
        end
        INPUT_MATRIX_A_rest_row:begin
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_output=cnt_output;

            if(cnt_input==3) begin
                n_state = OUTPUT_rest_row;
                ss_tready_before_FF=0;
                next_A4=ss_tdata;
                next_cnt_input=0;
            end
            else if(cnt_input==2) begin
                n_state = INPUT_MATRIX_A_rest_row;
                ss_tready_before_FF=1;
                next_A3=ss_tdata;
                next_cnt_input=cnt_input+1;
            end
            else if(cnt_input==1) begin
                n_state = INPUT_MATRIX_A_rest_row;
                ss_tready_before_FF=1;
                next_A2=ss_tdata;
                next_cnt_input=cnt_input+1;
            end
            else begin
                n_state = INPUT_MATRIX_A_rest_row;
                ss_tready_before_FF=1;
                next_A1=ss_tdata;

                next_cnt_input=cnt_input+1;
            end
        end
        OUTPUT_rest_row:begin
            ss_tready_before_FF=0;
            

            if (mm_done) begin // sm handshake
                next_cnt_output=cnt_output+1;
                if(cnt_input==3) begin
                    sm_tvalid_before_FF=0;
                    sm_tdata_before_FF=0;
                    next_cnt_input=0;
                    if(cnt_output==15) begin
                        n_state = DONE;
                    end
                    else begin
                        n_state = WAIT_MATRIX_A_rest_row_HANDSHAKE;
                    end
                end
                else begin
                    n_state = OUTPUT_rest_row;
                    sm_tvalid_before_FF=1;
                    if(cnt_input==0) begin
                        sm_tdata_before_FF=mac2;
                    end
                    else if(cnt_input==1) begin
                        sm_tdata_before_FF=mac3;
                    end
                    else if(cnt_input==2) begin
                        sm_tdata_before_FF=mac4;
                    end
                    else begin
                        sm_tdata_before_FF=0;
                    end
                    next_cnt_input=cnt_input+1;
                end
            end
            else begin
                n_state = OUTPUT_rest_row;
                ss_tready_before_FF=0;
                sm_tvalid_before_FF=1;
                next_cnt_input=cnt_input;
                next_cnt_output=cnt_output;

                if(cnt_input==0) begin
                    sm_tdata_before_FF=mac1;
                end
                else if(cnt_input==1) begin
                    sm_tdata_before_FF=mac2;
                end
                else if(cnt_input==2) begin
                    sm_tdata_before_FF=mac3;
                end
                else begin
                    sm_tdata_before_FF=mac4;
                end
                
            end
        end
        DONE:begin
            n_state = DONE;
            ss_tready_before_FF=0;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_input=0;
            next_cnt_output=cnt_output;
        end
        default : begin
            n_state = IDLE;
            ss_tready_before_FF=0;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;

            next_cnt_input=0;
            next_cnt_output=cnt_output;
            
        end
    endcase
end
    

endmodule
