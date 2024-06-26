module qsort 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)
(
    input   wire                     axis_clk,
    input   wire                     axis_rst_n,
    
    // ap_start from DMA
    input   wire                     qsort_start_whole,
    output   wire                    qsort_done_whole,

    // Data in (AXI-Stream)
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    output  wire                     ss_tready,

    // Data out (AXI-Stream)
    input   wire                     sm_tready, 
    output  reg                     sm_tvalid, 
    output  reg [(pDATA_WIDTH-1):0] sm_tdata
);

// regs and wires declaration
reg [31:0] data_w [0:9], data_r[0:9];
reg [31:0] sort_in1 [0:4], sort_in2 [0:4];
wire [31:0] sort_out1 [0:4], sort_out2 [0:4];    
reg [3:0] sort_state_w, sort_state_r;
reg [5:0] stream_cnt_w, stream_cnt_r;
reg [3:0] state_w, state_r;



integer i, j, k;
assign ss_tready = 1;
assign qsort_done_whole = (state_r==S_DONE);

// states
localparam S_IDLE = 0;
localparam S_LOAD = 1;
localparam S_SORT = 2;
localparam S_DONE = 3;

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

// combinational logic

// state machine
always @(*) begin
    state_w = state_r;

    case (state_r)
        S_IDLE: begin
            if (qsort_start_whole) begin
                state_w = S_LOAD;
            end
        end
        S_LOAD: begin
            if (stream_cnt_r == 10)begin
                state_w = S_SORT;
            end
        end
        S_SORT: begin
            if (sort_state_r == 6) begin
                state_w = S_DONE;
            end
        end
        S_DONE: begin

        end
    endcase
end



// data stream in and out, sorting network
always @(*) begin
    stream_cnt_w = stream_cnt_r;
    sort_state_w = sort_state_r;
    sm_tvalid = 0;
    sm_tdata = data_r[0];
    for (i=0; i<10; i=i+1) begin
        data_w[i] = data_r[i];
    end

    if (ss_tvalid && stream_cnt_r < 11) begin
        stream_cnt_w = stream_cnt_r + 1;
        for (i=0; i<10; i=i+1) begin
            data_w[i] = data_r[i+1];
        end
        data_w[9] = ss_tdata;
    end

    if (state_r == S_DONE)begin
        sm_tvalid = 1;
        if (sm_tready) begin
            for (i=0; i<10; i=i+1) begin
                data_w[i] = data_r[i+1];
            end
        end
    end

    if (state_r == S_SORT) begin // ref : https://bertdobbelaere.github.io/sorting_networks.html#N11L35D8
        sort_state_w = sort_state_r + 1;
        case (sort_state_r)
            0: begin
                //[(0,1),(2,5),(3,6),(4,7),(8,9)]
                sort_in1[0] = data_r[0];
                sort_in2[0] = data_r[1];
                data_w[0] = sort_out1[0];
                data_w[1] = sort_out2[0];

                sort_in1[1] = data_r[2];
                sort_in2[1] = data_r[5];
                data_w[2] = sort_out1[1];
                data_w[5] = sort_out2[1];

                sort_in1[2] = data_r[3];
                sort_in2[2] = data_r[6];
                data_w[3] = sort_out1[2];
                data_w[6] = sort_out2[2];

                sort_in1[3] = data_r[4];
                sort_in2[3] = data_r[7];
                data_w[4] = sort_out1[3];
                data_w[7] = sort_out2[3];

                sort_in1[4] = data_r[8];
                sort_in2[4] = data_r[9];
                data_w[8] = sort_out1[4];
                data_w[9] = sort_out2[4];
            end
            1:begin
                //[(0,6),(1,8),(2,4),(3,9),(5,7)]
                sort_in1[0] = data_r[0];
                sort_in2[0] = data_r[6];
                data_w[0] = sort_out1[0];
                data_w[6] = sort_out2[0];

                sort_in1[1] = data_r[1];
                sort_in2[1] = data_r[8];
                data_w[1] = sort_out1[1];
                data_w[8] = sort_out2[1];

                sort_in1[2] = data_r[2];
                sort_in2[2] = data_r[4];
                data_w[2] = sort_out1[2];
                data_w[4] = sort_out2[2];

                sort_in1[3] = data_r[3];
                sort_in2[3] = data_r[9];
                data_w[3] = sort_out1[3];
                data_w[9] = sort_out2[3];

                sort_in1[4] = data_r[5];
                sort_in2[4] = data_r[7];
                data_w[5] = sort_out1[4];
                data_w[7] = sort_out2[4];
            end 
            2:begin
                //[(0,2),(1,3),(4,5),(6,8),(7,9)]
                sort_in1[0] = data_r[0];
                sort_in2[0] = data_r[2];
                data_w[0] = sort_out1[0];
                data_w[2] = sort_out2[0];

                sort_in1[1] = data_r[1];
                sort_in2[1] = data_r[3];
                data_w[1] = sort_out1[1];
                data_w[3] = sort_out2[1];

                sort_in1[2] = data_r[4];
                sort_in2[2] = data_r[5];
                data_w[4] = sort_out1[2];
                data_w[5] = sort_out2[2];

                sort_in1[3] = data_r[6];
                sort_in2[3] = data_r[8];
                data_w[6] = sort_out1[3];
                data_w[8] = sort_out2[3];

                sort_in1[4] = data_r[7];
                sort_in2[4] = data_r[9];
                data_w[7] = sort_out1[4];
                data_w[9] = sort_out2[4];
            end
            3:begin
                //[(0,1),(2,7),(3,5),(4,6),(8,9)]
                sort_in1[0] = data_r[0];
                sort_in2[0] = data_r[1];
                data_w[0] = sort_out1[0];
                data_w[1] = sort_out2[0];

                sort_in1[1] = data_r[2];
                sort_in2[1] = data_r[7];
                data_w[2] = sort_out1[1];
                data_w[7] = sort_out2[1];

                sort_in1[2] = data_r[3];
                sort_in2[2] = data_r[5];
                data_w[3] = sort_out1[2];
                data_w[5] = sort_out2[2];

                sort_in1[3] = data_r[4];
                sort_in2[3] = data_r[6];
                data_w[4] = sort_out1[3];
                data_w[6] = sort_out2[3];

                sort_in1[4] = data_r[8];
                sort_in2[4] = data_r[9];
                data_w[8] = sort_out1[4];
                data_w[9] = sort_out2[4];
            end
            4:begin
                //[(1,2),(3,4),(5,6),(7,8)]
                sort_in1[0] = data_r[1];
                sort_in2[0] = data_r[2];
                data_w[1] = sort_out1[0];
                data_w[2] = sort_out2[0];

                sort_in1[1] = data_r[3];
                sort_in2[1] = data_r[4];
                data_w[3] = sort_out1[1];
                data_w[4] = sort_out2[1];

                sort_in1[2] = data_r[5];
                sort_in2[2] = data_r[6];
                data_w[5] = sort_out1[2];
                data_w[6] = sort_out2[2];

                sort_in1[3] = data_r[7];
                sort_in2[3] = data_r[8];
                data_w[7] = sort_out1[3];
                data_w[8] = sort_out2[3];
            end
            5:begin
                //[(1,3),(2,4),(5,7),(6,8)]
                sort_in1[0] = data_r[1];
                sort_in2[0] = data_r[3];
                data_w[1] = sort_out1[0];
                data_w[3] = sort_out2[0];

                sort_in1[1] = data_r[2];
                sort_in2[1] = data_r[4];
                data_w[2] = sort_out1[1];
                data_w[4] = sort_out2[1];

                sort_in1[2] = data_r[5];
                sort_in2[2] = data_r[7];
                data_w[5] = sort_out1[2];
                data_w[7] = sort_out2[2];

                sort_in1[3] = data_r[6];
                sort_in2[3] = data_r[8];
                data_w[6] = sort_out1[3];
                data_w[8] = sort_out2[3];
            end
            6:begin
                //[(2,3),(4,5),(6,7)]
                sort_in1[0] = data_r[2];
                sort_in2[0] = data_r[3];
                data_w[2] = sort_out1[0];
                data_w[3] = sort_out2[0];

                sort_in1[1] = data_r[4];
                sort_in2[1] = data_r[5];
                data_w[4] = sort_out1[1];
                data_w[5] = sort_out2[1];

                sort_in1[2] = data_r[6];
                sort_in2[2] = data_r[7];
                data_w[6] = sort_out1[2];
                data_w[7] = sort_out2[2];
            end

        endcase
    end

end

// sequential logic
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        state_r <= S_IDLE;
        stream_cnt_r <= 0;
        for (i = 0; i < 11; i = i + 1) begin
            data_r[i] <= 0;
        end
        sort_state_r <= 0;
    end else begin
        state_r <= state_w;
        stream_cnt_r <= stream_cnt_w;
        for (i = 0; i < 11; i = i + 1) begin
            data_r[i] <= data_w[i];
        end
        sort_state_r <= sort_state_w;
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
