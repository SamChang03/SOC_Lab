module qsort
#(  parameter pADDR_WIDTH = 12,
    parameter pnext_ARRAYIDTH = 32
)
(
    input   wire                     axis_clk,
    input   wire                     axis_rst_n,
    
    // ap_start from DMA
    input   wire                     qsort_start_whole,
    output   wire                     qsort_done_whole,
    /////output   wire                     QS_idle,

    // Data in (AXI-Stream)
    input   wire                     ss_tvalid, 
    input   wire [(pnext_ARRAYIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast,
    output  reg                     ss_tready,

    // Data out (AXI-Stream)
    input   wire                     sm_tready, 
    output  reg                     sm_tvalid, 
    output  reg [(pnext_ARRAYIDTH-1):0] sm_tdata
    //output  wire                     sm_tlast, //not used
);

// Design By SamChang
localparam IDLE = 3'd0;
localparam WAIT_HANDSHAKE = 3'd1;
localparam LOAD_ARRAY= 3'd2;
localparam SORT_ARRAY= 3'd3;
localparam OUTPUT_ARRAY = 3'd4;
localparam DONE = 3'd5;


wire QS_start; // modified
wire QS_done; // modified
wire QS_idle; // modified
assign qsort_done_whole=QS_idle; // modified

reg ss_tready_before_FF;
reg sm_tvalid_before_FF;
reg [(pnext_ARRAYIDTH-1):0] sm_tdata_before_FF;

reg         [3:0]           n_state;
reg         [3:0]           c_state;
//ARRAY A * ARRAY B == ARRAY C
reg         [4:0]           cnt_IO, next_cnt_IO; //for 10 cycles
reg         [3:0]           cnt_sort, next_cnt_sort; //for 7 cycles

reg   [(pnext_ARRAYIDTH-1):0]  ARRAY[0:9],next_ARRAY[0:9];
reg   [(pnext_ARRAYIDTH-1):0] sort_in1 [0:4], sort_in2 [0:4];
wire  [(pnext_ARRAYIDTH-1):0] sort_out1 [0:4], sort_out2 [0:4]; 



///////////////////////////////////////// (For test) /////////////////////////////////////////
    //wire test1;
    wire [31:0] ARRAY0;
    wire [31:0] ARRAY1;
    wire [31:0] ARRAY2;
    wire [31:0] ARRAY3;
    wire [31:0] ARRAY4;
    wire [31:0] ARRAY5;
    wire [31:0] ARRAY6;
    wire [31:0] ARRAY7;
    wire [31:0] ARRAY8;
    wire [31:0] ARRAY9;


    assign ARRAY0=ARRAY[0];
    assign ARRAY1=ARRAY[1];
    assign ARRAY2=ARRAY[2];
    assign ARRAY3=ARRAY[3];
    assign ARRAY4=ARRAY[4];
    assign ARRAY5=ARRAY[5];
    assign ARRAY6=ARRAY[6];
    assign ARRAY7=ARRAY[7];
    assign ARRAY8=ARRAY[8];
    assign ARRAY9=ARRAY[9];


    //assign test1=(wbs_adr_i[7:0]==8'h88);
    //////////////////////////////////////////////////////////////////////////////////////////////


assign QS_start = (ss_tvalid && ss_tready) ? 1:0;
assign QS_done = (sm_tvalid && sm_tready) ? 1:0;
assign QS_idle = (c_state == DONE) ? 1:0;

integer i;
genvar g;
generate
    for (g=0; g<5; g=g+1) begin
        sort2 sort(
            .in1(sort_in1[g]),
            .in2(sort_in2[g]),
            .out1(sort_out1[g]),
            .out2(sort_out2[g])
        );
    end
endgenerate




always @(*)begin
   if (c_state == SORT_ARRAY) begin // ref : https://bertdobbelaere.github.io/sorting_networks.html#N11L35D8
        case (cnt_sort)
            0: begin
                //[(0,1),(2,5),(3,6),(4,7),(8,9)]
                sort_in1[0] = ARRAY[0];
                sort_in2[0] = ARRAY[1];
                next_ARRAY[0] = sort_out1[0];
                next_ARRAY[1] = sort_out2[0];

                sort_in1[1] = ARRAY[2];
                sort_in2[1] = ARRAY[5];
                next_ARRAY[2] = sort_out1[1];
                next_ARRAY[5] = sort_out2[1];

                sort_in1[2] = ARRAY[3];
                sort_in2[2] = ARRAY[6];
                next_ARRAY[3] = sort_out1[2];
                next_ARRAY[6] = sort_out2[2];

                sort_in1[3] = ARRAY[4];
                sort_in2[3] = ARRAY[7];
                next_ARRAY[4] = sort_out1[3];
                next_ARRAY[7] = sort_out2[3];

                sort_in1[4] = ARRAY[8];
                sort_in2[4] = ARRAY[9];
                next_ARRAY[8] = sort_out1[4];
                next_ARRAY[9] = sort_out2[4];
            end
            1:begin
                //[(0,6),(1,8),(2,4),(3,9),(5,7)]
                sort_in1[0] = ARRAY[0];
                sort_in2[0] = ARRAY[6];
                next_ARRAY[0] = sort_out1[0];
                next_ARRAY[6] = sort_out2[0];

                sort_in1[1] = ARRAY[1];
                sort_in2[1] = ARRAY[8];
                next_ARRAY[1] = sort_out1[1];
                next_ARRAY[8] = sort_out2[1];

                sort_in1[2] = ARRAY[2];
                sort_in2[2] = ARRAY[4];
                next_ARRAY[2] = sort_out1[2];
                next_ARRAY[4] = sort_out2[2];

                sort_in1[3] = ARRAY[3];
                sort_in2[3] = ARRAY[9];
                next_ARRAY[3] = sort_out1[3];
                next_ARRAY[9] = sort_out2[3];

                sort_in1[4] = ARRAY[5];
                sort_in2[4] = ARRAY[7];
                next_ARRAY[5] = sort_out1[4];
                next_ARRAY[7] = sort_out2[4];
            end 
            2:begin
                //[(0,2),(1,3),(4,5),(6,8),(7,9)]
                sort_in1[0] = ARRAY[0];
                sort_in2[0] = ARRAY[2];
                next_ARRAY[0] = sort_out1[0];
                next_ARRAY[2] = sort_out2[0];

                sort_in1[1] = ARRAY[1];
                sort_in2[1] = ARRAY[3];
                next_ARRAY[1] = sort_out1[1];
                next_ARRAY[3] = sort_out2[1];

                sort_in1[2] = ARRAY[4];
                sort_in2[2] = ARRAY[5];
                next_ARRAY[4] = sort_out1[2];
                next_ARRAY[5] = sort_out2[2];

                sort_in1[3] = ARRAY[6];
                sort_in2[3] = ARRAY[8];
                next_ARRAY[6] = sort_out1[3];
                next_ARRAY[8] = sort_out2[3];

                sort_in1[4] = ARRAY[7];
                sort_in2[4] = ARRAY[9];
                next_ARRAY[7] = sort_out1[4];
                next_ARRAY[9] = sort_out2[4];
            end
            3:begin
                //[(0,1),(2,7),(3,5),(4,6),(8,9)]
                sort_in1[0] = ARRAY[0];
                sort_in2[0] = ARRAY[1];
                next_ARRAY[0] = sort_out1[0];
                next_ARRAY[1] = sort_out2[0];

                sort_in1[1] = ARRAY[2];
                sort_in2[1] = ARRAY[7];
                next_ARRAY[2] = sort_out1[1];
                next_ARRAY[7] = sort_out2[1];

                sort_in1[2] = ARRAY[3];
                sort_in2[2] = ARRAY[5];
                next_ARRAY[3] = sort_out1[2];
                next_ARRAY[5] = sort_out2[2];

                sort_in1[3] = ARRAY[4];
                sort_in2[3] = ARRAY[6];
                next_ARRAY[4] = sort_out1[3];
                next_ARRAY[6] = sort_out2[3];

                sort_in1[4] = ARRAY[8];
                sort_in2[4] = ARRAY[9];
                next_ARRAY[8] = sort_out1[4];
                next_ARRAY[9] = sort_out2[4];
            end
            4:begin
                //[(1,2),(3,4),(5,6),(7,8)]
                sort_in1[0] = ARRAY[1];
                sort_in2[0] = ARRAY[2];
                next_ARRAY[1] = sort_out1[0];
                next_ARRAY[2] = sort_out2[0];

                sort_in1[1] = ARRAY[3];
                sort_in2[1] = ARRAY[4];
                next_ARRAY[3] = sort_out1[1];
                next_ARRAY[4] = sort_out2[1];

                sort_in1[2] = ARRAY[5];
                sort_in2[2] = ARRAY[6];
                next_ARRAY[5] = sort_out1[2];
                next_ARRAY[6] = sort_out2[2];

                sort_in1[3] = ARRAY[7];
                sort_in2[3] = ARRAY[8];
                next_ARRAY[7] = sort_out1[3];
                next_ARRAY[8] = sort_out2[3];
            end
            5:begin
                //[(1,3),(2,4),(5,7),(6,8)]
                sort_in1[0] = ARRAY[1];
                sort_in2[0] = ARRAY[3];
                next_ARRAY[1] = sort_out1[0];
                next_ARRAY[3] = sort_out2[0];

                sort_in1[1] = ARRAY[2];
                sort_in2[1] = ARRAY[4];
                next_ARRAY[2] = sort_out1[1];
                next_ARRAY[4] = sort_out2[1];

                sort_in1[2] = ARRAY[5];
                sort_in2[2] = ARRAY[7];
                next_ARRAY[5] = sort_out1[2];
                next_ARRAY[7] = sort_out2[2];

                sort_in1[3] = ARRAY[6];
                sort_in2[3] = ARRAY[8];
                next_ARRAY[6] = sort_out1[3];
                next_ARRAY[8] = sort_out2[3];
            end
            6:begin
                //[(2,3),(4,5),(6,7)]
                sort_in1[0] = ARRAY[2];
                sort_in2[0] = ARRAY[3];
                next_ARRAY[2] = sort_out1[0];
                next_ARRAY[3] = sort_out2[0];

                sort_in1[1] = ARRAY[4];
                sort_in2[1] = ARRAY[5];
                next_ARRAY[4] = sort_out1[1];
                next_ARRAY[5] = sort_out2[1];

                sort_in1[2] = ARRAY[6];
                sort_in2[2] = ARRAY[7];
                next_ARRAY[6] = sort_out1[2];
                next_ARRAY[7] = sort_out2[2];
            end

        endcase
   end

end


/////////////////////////////////////////////
///FSM
/////////////////////////////////////////////
always @(*) begin
    for(i=0;i<10;i=i+1)
            next_ARRAY[i] = ARRAY[i];
    case(c_state)
        //0
        IDLE: begin // modified
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_IO=0;
            next_cnt_sort=0;
            
            if(qsort_start_whole) begin // ap_start
                n_state = LOAD_ARRAY;
                ss_tready_before_FF=1;
            end
            else begin
                n_state = IDLE;
                ss_tready_before_FF=0;
            end
        end
        WAIT_HANDSHAKE:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_IO=0;
            next_cnt_sort=0;

            if(QS_start) begin // ss handshake
                n_state = LOAD_ARRAY;
            end
            else begin
                n_state = WAIT_HANDSHAKE;
            end
        end
        
       LOAD_ARRAY:begin
            ss_tready_before_FF=1;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_sort=0;
            next_ARRAY[cnt_IO]=ss_tdata;
            
            if(cnt_IO==4'd10) begin
                n_state = SORT_ARRAY; 
                next_cnt_IO=0;
            end
            else if(ss_tvalid) begin
                n_state = LOAD_ARRAY;
                next_cnt_IO = cnt_IO+1;
            end
            else begin
                n_state = LOAD_ARRAY;
                next_cnt_IO = cnt_IO;
            end
        end
        
        SORT_ARRAY:begin
            ss_tready_before_FF=0;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_IO=0;
            
            if(cnt_sort==6) begin
                n_state = OUTPUT_ARRAY; 
                next_cnt_sort=0;
            end
            else begin
                n_state = SORT_ARRAY;
                next_cnt_sort = cnt_sort+1;
            end
        end
        
        OUTPUT_ARRAY:begin
            ss_tready_before_FF=0;
            next_cnt_IO=0;
            if (QS_done) begin // sm handshake
                sm_tvalid_before_FF=0;
                sm_tdata_before_FF=0;
                ss_tready_before_FF=0;
                next_cnt_IO=cnt_IO+1;
                
                if(cnt_IO==4'd9) 
                    n_state = DONE;
                else 
                    n_state = OUTPUT_ARRAY;
            end
            else begin
                n_state = OUTPUT_ARRAY;
                ss_tready_before_FF=0;
                sm_tvalid_before_FF=1;
                next_cnt_IO=cnt_IO;
                next_cnt_sort=cnt_sort;
                sm_tdata_before_FF = ARRAY[cnt_IO];               
                
            end
        end
        DONE:begin
            n_state = DONE;
            ss_tready_before_FF=0;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_IO=0;
            next_cnt_sort=0;
        end
        default : begin
            n_state = IDLE;
            ss_tready_before_FF=0;
            sm_tvalid_before_FF=0;
            sm_tdata_before_FF=0;
            next_cnt_IO=0;
            next_cnt_sort=0;
            
        end
    endcase
end

  //Sequential Circuit (FF)
  always @(posedge axis_clk or negedge axis_rst_n) begin
	if(!axis_rst_n) begin
	c_state <= IDLE;
        ss_tready <= 0;
        sm_tvalid <= 0;
        sm_tdata <= 0;
        
        for(i=0;i<10;i=i+1)
          ARRAY[i] <= 0;

        cnt_IO <= 0;
        cnt_sort <= 0;
	end
	else begin
	c_state <= n_state;
        ss_tready <= ss_tready_before_FF;
        sm_tvalid <= sm_tvalid_before_FF;
        sm_tdata <= sm_tdata_before_FF;
        
        for(i=0;i<10;i=i+1)
            ARRAY[i] <=next_ARRAY[i] ;
            
        cnt_IO <= next_cnt_IO;
        cnt_sort <= next_cnt_sort;
	end
  end
endmodule


module sort2(
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out1,
    output wire [31:0] out2
);

assign out1 = (in1 > in2) ? in2 : in1;
assign out2 = (in1 > in2) ? in1 : in2;

endmodule
