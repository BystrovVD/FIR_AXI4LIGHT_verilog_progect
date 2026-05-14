`timescale 1ns / 1ps

module fir_axi4light_fifo #(
    parameter int DATA_WIDTH = 16,
    parameter int FIFO_DEPTH = 7 
)(
    input  logic                   clk,
    input  logic                   rst,
    
    
    input  logic [DATA_WIDTH-1:0]  input_data,
    input  logic                   input_valid,
    output logic                   output_ready,
    

    output logic [DATA_WIDTH-1:0]  output_data,
    output logic                   output_valid,
    input  logic                   input_ready
);


    localparam pointer_width = $clog2 (FIFO_DEPTH),
               counter_width = $clog2 (FIFO_DEPTH + 1);


    logic [pointer_width - 1:0] wr_ptr, rd_ptr;
    logic [counter_width - 1:0] fifo_count;

    logic [DATA_WIDTH - 1:0] data [0: FIFO_DEPTH - 1];

    assign output_data = data [rd_ptr];
    
    
    always_ff @(posedge clk) begin
        if (input_valid && output_ready) begin
            data[wr_ptr] <= input_data;
        end
    end


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr     <= 0;
            rd_ptr     <= 0;
            fifo_count <= 0;
        end else begin
            case ({input_valid && output_ready, input_ready && output_valid})
                2'b00: begin 
                    wr_ptr     <=  wr_ptr;
                    rd_ptr     <=  rd_ptr;
                    fifo_count <= fifo_count;
                end
                2'b10: begin 
                    wr_ptr     <= (wr_ptr == FIFO_DEPTH - 1) ? 0 : wr_ptr + 1;
                    rd_ptr     <= rd_ptr;
                    fifo_count <= fifo_count + 1;
                end
                2'b01: begin
                    wr_ptr     <= wr_ptr ;
                    rd_ptr     <= (rd_ptr == FIFO_DEPTH - 1) ? 0 : rd_ptr + 1;
                    fifo_count <= fifo_count - 1;
                end
                2'b11: begin 
                    wr_ptr     <= (wr_ptr == FIFO_DEPTH - 1) ? 0 : wr_ptr + 1;
                    rd_ptr     <= (rd_ptr == FIFO_DEPTH - 1) ? 0 : rd_ptr + 1;
                    fifo_count <= fifo_count;
                end
                default: ;
            endcase
        end
    end


    assign output_ready = (fifo_count < FIFO_DEPTH);
    assign output_valid = (fifo_count > 0);


endmodule
