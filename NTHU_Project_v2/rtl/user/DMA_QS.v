module DMA_QS 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)
(

    // WB interface
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // SDRAM request QS (controller interface)
    output reg  [23:0] QS_address,
    output reg  QS_rw, // 1 = write, 0 = read
    output reg  [31:0] data_from_QS,
    input   [31:0] data_to_QS,
    input   QS_busy,
    output reg  QS_in_valid,
    input   QS_out_valid,
    output reg  QS_prefetch_step
);

    
    localparam DMA_QS_IDLE = 3'd0, DMA_QS_BASE_ADDRESS = 3'd1, DMA_QS_DETECT_Yn_Xn = 3'd2, DMA_QS_STREAM_IN = 3'd3, DMA_QS_STREAM_OUT = 3'd4, DMA_QS_DONE = 3'd5;
    localparam DMA_QS_REQUEST_IDLE = 3'd0, DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER = 3'd1, DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER = 3'd2, DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER_WAIT = 3'd3, DMA_QS_NO_REQUEST = 3'd4, DMA_QS_REQUEST_DONE = 3'd5;

    reg wbs_ack_o_before_FF;
    reg [31:0] wbs_dat_o_before_FF;

    reg [23:0] QS_address_before_FF;
    reg QS_rw_before_FF;
    reg [31:0] data_from_QS_before_FF;
    reg QS_in_valid_before_FF;
    reg QS_prefetch_step_before_FF;

    reg [2:0] state_DMA_QS;
    reg [2:0] next_state_DMA_QS;
    reg [2:0] state_DMA_QS_request_SDRAM;
    reg [2:0] next_state_DMA_QS_request_SDRAM;

    reg [31:0] input_buffer; // To buffer 1 data
    reg [31:0] next_input_buffer;
    reg input_buffer_valid; // "All" of the input buffer have been used
    reg next_input_buffer_valid;
    
    reg [31:0] output_buffer;
    reg [31:0] next_output_buffer;
    reg output_buffer_valid;
    reg next_output_buffer_valid;
    reg [23:0] output_SDRAM_address_pointer_counter;
    reg [23:0] next_output_SDRAM_address_pointer_counter;
    

    reg [23:0] QS_base_address_buffer; // Be caution of its bit number !! (Because it is with controller protocol)
    reg [23:0] next_QS_base_address_buffer;

    reg [3:0] input_number_counter;
    reg [3:0] next_input_number_counter;


    reg QS_done_shown_in_DMA;
    reg next_QS_done_shown_in_DMA;
    


    integer i;

    always @* begin
        if((state_DMA_QS==DMA_QS_DONE) && (output_buffer_valid==0)) begin
            next_QS_done_shown_in_DMA=1;
        end
        else if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin
            next_QS_done_shown_in_DMA=0;
        end
        else begin
            next_QS_done_shown_in_DMA=QS_done_shown_in_DMA;
        end
    end

    always @* begin
        if((sm_tready==1) && (sm_tvalid==1)) begin
            next_output_buffer_valid=1;
        end
        else if((state_DMA_QS_request_SDRAM==DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER) && (QS_busy==1) && (QS_in_valid==0)) begin
            next_output_buffer_valid=0;
        end
        else begin
            next_output_buffer_valid=output_buffer_valid;
        end
    end

    always @* begin
        if((state_DMA_QS_request_SDRAM==DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER) && (QS_out_valid==1)) begin
            next_input_buffer_valid=1;
        end
        else if((state_DMA_QS==DMA_QS_STREAM_IN)&& ((ss_tready==1) && (ss_tvalid==1))) begin
            next_input_buffer_valid=0;
        end
        else begin
            next_input_buffer_valid=input_buffer_valid;
        end
    end

    // When input buffer is all empty or used, make a request to SDRAM
    always @* begin
        case(state_DMA_QS_request_SDRAM)
            DMA_QS_REQUEST_IDLE: begin
                QS_rw_before_FF=0;
                data_from_QS_before_FF=0;
                QS_prefetch_step_before_FF=0;
                next_input_buffer=input_buffer;
                next_output_SDRAM_address_pointer_counter=0;
                next_input_number_counter=0;

                if(QS_base_address_buffer==3721) begin // Maybe using the concept of buffer_valid signal would be better
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_IDLE;
                    QS_in_valid_before_FF=0;
                    QS_address_before_FF=0;
                end
                else begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER;
                    QS_in_valid_before_FF=1;
                    QS_address_before_FF=QS_base_address_buffer;
                end
            end
            DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER: begin
                QS_rw_before_FF=0;
                data_from_QS_before_FF=0;
                QS_prefetch_step_before_FF=QS_prefetch_step;
                next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;

                if(QS_out_valid) begin
                    if(input_number_counter==4'd9) begin
                        QS_in_valid_before_FF=0;
                        QS_address_before_FF=QS_address;
                        next_input_number_counter=input_number_counter;
                        next_input_buffer=data_to_QS;
                        next_state_DMA_QS_request_SDRAM=DMA_QS_NO_REQUEST;
                    end
                    else begin
                        next_state_DMA_QS_request_SDRAM=DMA_QS_NO_REQUEST;
                        QS_in_valid_before_FF=0;
                        QS_address_before_FF=QS_address+4;
                        next_input_buffer=data_to_QS;
                        next_input_number_counter=input_number_counter+1;
                    end
                end
                else if(QS_busy) begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER;
                    QS_in_valid_before_FF=0;
                    QS_address_before_FF=QS_address;
                    next_input_buffer=input_buffer;
                    next_input_number_counter=input_number_counter;
                end
                else begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER;
                    QS_in_valid_before_FF=QS_in_valid;
                    QS_address_before_FF=QS_address;
                    next_input_buffer=input_buffer;
                    next_input_number_counter=input_number_counter;
                end
            end
            DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER: begin
                QS_address_before_FF=QS_base_address_buffer+output_SDRAM_address_pointer_counter;
                data_from_QS_before_FF=output_buffer;
                QS_prefetch_step_before_FF=0;
                next_input_buffer=input_buffer;
                next_input_number_counter=input_number_counter;
                if(QS_busy) begin
                    if(QS_in_valid) begin
                        next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER;
                        QS_in_valid_before_FF=QS_in_valid;
                        QS_rw_before_FF=1;
                        next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                    end
                    else begin
                        QS_in_valid_before_FF=0;
                        QS_rw_before_FF=0;

                        if(output_SDRAM_address_pointer_counter==23'd36) begin
                            next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_DONE;
                            next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                        end
                        else begin
                            next_state_DMA_QS_request_SDRAM=DMA_QS_NO_REQUEST;
                            next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter+4;
                        end
                    end
                end
                else begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER;
                    QS_in_valid_before_FF=0;
                    QS_rw_before_FF=1;
                    next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                end
            end
            DMA_QS_NO_REQUEST: begin


                if(output_buffer_valid==1) begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_READ_OUTPUT_BUFFER;
                    QS_in_valid_before_FF=1;
                    QS_rw_before_FF=1;
                    QS_address_before_FF=QS_base_address_buffer+output_SDRAM_address_pointer_counter;
                    data_from_QS_before_FF=output_buffer;
                    QS_prefetch_step_before_FF=0;
                    next_input_number_counter=input_number_counter;
                    next_input_buffer=input_buffer;
                    next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                end
                else if(input_buffer_valid==0) begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_SDRAM_WRITE_INPUT_BUFFER;
                    QS_in_valid_before_FF=1;
                    QS_rw_before_FF=0;
                    data_from_QS_before_FF=0;
                    next_input_number_counter=input_number_counter;
                    next_input_buffer=input_buffer;
                    next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                    QS_address_before_FF=QS_base_address_buffer;
                    QS_prefetch_step_before_FF=1;

                end
                else begin
                    next_state_DMA_QS_request_SDRAM=DMA_QS_NO_REQUEST;
                    QS_in_valid_before_FF=0;
                    QS_rw_before_FF=0;
                    QS_address_before_FF=QS_address;
                    data_from_QS_before_FF=0;
                    QS_prefetch_step_before_FF=QS_prefetch_step;
                    next_input_buffer=input_buffer;
                    next_output_SDRAM_address_pointer_counter=output_SDRAM_address_pointer_counter;
                    next_input_number_counter=input_number_counter;
                end
            end
            DMA_QS_REQUEST_DONE: begin
                next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_DONE;
                QS_in_valid_before_FF=0;
                QS_rw_before_FF=0;
                QS_address_before_FF=QS_address;
                data_from_QS_before_FF=0;
                QS_prefetch_step_before_FF=0;
                next_input_buffer=input_buffer;
                next_output_SDRAM_address_pointer_counter=0;
                next_input_number_counter=input_number_counter;
            end
            default: begin
                next_state_DMA_QS_request_SDRAM=DMA_QS_REQUEST_IDLE;
                QS_in_valid_before_FF=0;
                QS_rw_before_FF=0;
                QS_address_before_FF=0;
                data_from_QS_before_FF=0;
                QS_prefetch_step_before_FF=0;
                next_input_number_counter=0;
                next_input_buffer=input_buffer;
                next_output_SDRAM_address_pointer_counter=0;

            end
        endcase
    end

    // DMA interacts with WB (in the upper level) and QS (in the downer level)
    always @* begin
        case(state_DMA_QS)
            DMA_QS_IDLE: begin
                QS_start=0;
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=0;
                next_output_buffer=output_buffer;

                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==1) && (wbs_adr_i[7:0]==8'h04)) begin // that is, program base_address_A_buffer(0x30020004)
                    next_state_DMA_QS=DMA_QS_IDLE;
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=0;
                    next_QS_base_address_buffer=wbs_dat_i[23:0];

                end
                else if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==1) && (wbs_adr_i[7:0]==8'h00)) begin // that is, read ap_register(0x30020000)
                    next_state_DMA_QS=DMA_QS_IDLE;
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=32'b100; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time
                    next_QS_base_address_buffer=QS_base_address_buffer;
                    
                end
                else begin
                    next_state_DMA_QS=DMA_QS_IDLE;
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                    next_QS_base_address_buffer=QS_base_address_buffer;
                end
            end
            DMA_QS_BASE_ADDRESS: begin
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=0;
                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer=output_buffer;

                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==1) && (wbs_adr_i[7:0]==8'h00) && (wbs_dat_i==1)) begin // that is, program ap_start
                    next_state_DMA_QS=DMA_QS_DETECT_Yn_Xn;
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=0;
                    QS_start=1;
                end
                else if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin // that is, read ap_register(0x30020000)
                    next_state_DMA_QS=DMA_QS_BASE_ADDRESS;
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=32'b100; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time
                    QS_start=0;
                end
                else begin
                    next_state_DMA_QS=DMA_QS_BASE_ADDRESS;
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                    QS_start=0;
                end
            end
            DMA_QS_DETECT_Yn_Xn: begin
                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin // that is, read ap_register(0x30020000)
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=32'd0; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time
                end
                else begin
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                end
                QS_start=0;
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=0;
                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer=output_buffer;
                
                if((sm_tvalid==1) && (output_buffer_valid==0)) begin // Detect Y[n], making sure output_buffer data is empty / has been sent to SDRAM
                    next_state_DMA_QS=DMA_QS_STREAM_OUT;
                end
                else if(QS_done) begin // Detect done signal
                    next_state_DMA_QS=DMA_QS_DONE;
                end
                else if((ss_tready==1) && (input_buffer_valid==1)) begin // Detect X[n]
                    next_state_DMA_QS=DMA_QS_STREAM_IN;
                end
                else begin
                    next_state_DMA_QS=DMA_QS_DETECT_Yn_Xn;
                end
            end
            DMA_QS_STREAM_IN: begin
                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin // that is, read ap_register(0x30020000)
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=32'd0; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time
                end
                else begin
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                end
                QS_start=0;
                ss_tvalid=1;
                ss_tdata=input_buffer;
                sm_tready=0;
                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer=output_buffer;

                if((ss_tready==1) && (ss_tvalid==1)) begin
                    if(input_number_counter==2'd3) begin
                        next_state_DMA_QS=DMA_QS_DETECT_Yn_Xn;
                    end
                    else begin
                        next_state_DMA_QS=DMA_QS_STREAM_IN;
                    end
                end
                else begin
                    next_state_DMA_QS=DMA_QS_STREAM_IN;
                end
            end
            DMA_QS_STREAM_OUT: begin
                next_state_DMA_QS=DMA_QS_DETECT_Yn_Xn;
                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin // that is, read ap_register(0x30020000)
                    wbs_ack_o_before_FF=1;
                    wbs_dat_o_before_FF=32'd0; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time
                end
                else begin
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                end
                QS_start=0;
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=1;
                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer = sm_tdata;
            end
            DMA_QS_DONE: begin // which means QS engine is done, but we still have to wait for all the output data to move to SDRAM, at that time, we can raise "QS_done_shown_in_DMA" signal to indicate finish 
                next_state_DMA_QS=DMA_QS_DONE;
                QS_start=0;
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=0;
                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer=output_buffer;

                if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0) && (wbs_adr_i[7:0]==8'h00)) begin
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF={25'd0,QS_done_shown_in_DMA,6'b10}; // {QS_done_shown_in_DMA,0,0,0,ap_idle, ap_done, ap_start} with QS_done_shown_in_DMA=0 at this time; here it's better to reset ap_done to 0 after read.
                end
                else if((wbs_stb_i==1) && (wbs_cyc_i==1) && (wbs_we_i==0)) begin
                    wbs_ack_o_before_FF=1;
                    case(wbs_adr_i[7:0])
                        8'h0C: wbs_dat_o_before_FF=output_buffer[0];
                        8'h10: wbs_dat_o_before_FF=output_buffer[1];
                        8'h14: wbs_dat_o_before_FF=output_buffer[2];
                        8'h18: wbs_dat_o_before_FF=output_buffer[3];
                        8'h1C: wbs_dat_o_before_FF=output_buffer[4];
                        8'h20: wbs_dat_o_before_FF=output_buffer[5];
                        8'h24: wbs_dat_o_before_FF=output_buffer[6];
                        8'h28: wbs_dat_o_before_FF=output_buffer[7];
                        8'h2C: wbs_dat_o_before_FF=output_buffer[8];
                        8'h30: wbs_dat_o_before_FF=output_buffer[9];
                        default: wbs_dat_o_before_FF=0;
                    endcase
                end
                else begin
                    wbs_ack_o_before_FF=0;
                    wbs_dat_o_before_FF=0;
                end

            end
            default: begin
                next_state_DMA_QS=DMA_QS_IDLE;
                wbs_ack_o_before_FF=0;
                wbs_dat_o_before_FF=0;
                
                QS_start=0;
                ss_tvalid=0;
                ss_tdata=0;
                sm_tready=0;

                next_QS_base_address_buffer=QS_base_address_buffer;
                next_output_buffer=output_buffer;
            end
        endcase
    end



    always@(posedge wb_clk_i) begin
        if(wb_rst_i) begin // positive reset
            state_DMA_QS <= DMA_QS_IDLE;
            state_DMA_QS_request_SDRAM <= DMA_QS_REQUEST_IDLE;
            wbs_ack_o <= 0;
            wbs_dat_o <= 0;
            QS_address <= 0;
            QS_rw <= 0;
            data_from_QS <= 0;
            QS_in_valid <= 0;
            QS_prefetch_step <= 0;
            input_buffer <= 0;
            input_buffer_valid <= 0;
            QS_base_address_buffer <= 3721;
            output_buffer <= 0;
            QS_done_shown_in_DMA <= 0;
            output_buffer_valid <= 0;
            output_SDRAM_address_pointer_counter <= 0;
            input_number_counter<=0;
        end
        else begin
            state_DMA_QS <= next_state_DMA_QS;
            state_DMA_QS_request_SDRAM <= next_state_DMA_QS_request_SDRAM;
            wbs_ack_o <= wbs_ack_o_before_FF;
            wbs_dat_o <= wbs_dat_o_before_FF;
            QS_address <= QS_address_before_FF;
            QS_rw <= QS_rw_before_FF;
            data_from_QS <= data_from_QS_before_FF;
            QS_in_valid <= QS_in_valid_before_FF;
            QS_prefetch_step <= QS_prefetch_step_before_FF;
            input_buffer <= next_input_buffer;
            input_buffer_valid <= next_input_buffer_valid;
            QS_base_address_buffer <= next_QS_base_address_buffer;
            output_buffer <= next_output_buffer;
            QS_done_shown_in_DMA <= next_QS_done_shown_in_DMA;
            output_buffer_valid <= next_output_buffer_valid;
            output_SDRAM_address_pointer_counter <= next_output_SDRAM_address_pointer_counter;
            input_number_counter<=next_input_number_counter;
        end
    end
    
    reg QS_start;
    wire QS_done;
    reg ss_tvalid;
    reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    wire ss_tready;
    reg sm_tready;
    wire sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    
    qsort QS_U0 (

        .axis_clk(wb_clk_i),
        .axis_rst_n(~wb_rst_i),

        .qsort_start_whole(QS_start),
        .qsort_done_whole(QS_done),

        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tready(ss_tready),

        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata)

    );

endmodule

