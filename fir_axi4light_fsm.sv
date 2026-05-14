`timescale 1ns / 1ps

module fir_axi4light_fsm#(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_NUM   = 127
)(
    input logic clk,
    input logic rst,
    
    input logic write_mem_en,
    input logic [$clog2(COEF_NUM) - 1:0] max_coef_num,
    
    input  logic                     in_data_valid,
    output logic                     out_ready,
    
    input  logic                     in_ready,
    output logic                     out_data_valid,
    
    output logic                    enable_calc,
    output logic                    last_coef,
    output logic [$clog2(COEF_NUM) - 1:0] coef_cnt       
);

localparam int out_data_valid_delay_num = 7;
logic [out_data_valid_delay_num-1:0] out_data_valid_delay;

logic [$clog2(COEF_NUM) - 1:0] max_coef_num_mem;

enum logic [1:0]{
    IDLE_ST = 2'b00,
    CALC_ST = 2'b01,
    MEWR_ST = 2'b10
} next_state, state;

always @(posedge clk, posedge rst)
    if(rst) begin 
        max_coef_num_mem <= '0;
    end
    else if (write_mem_en) begin
        max_coef_num_mem <= max_coef_num;
    end 
    else begin
        max_coef_num_mem <= max_coef_num_mem;
    end

always @(posedge clk, posedge rst)
    if(rst) begin 
        state <= IDLE_ST;
    end
    else state <= next_state;
    
always_comb begin
    if (rst) next_state = IDLE_ST;
    else if (write_mem_en) next_state = MEWR_ST;
    else 
        case(state)
        IDLE_ST: if(in_data_valid & in_ready) next_state = CALC_ST;
        CALC_ST: if((coef_cnt == max_coef_num_mem - 1) & (~in_data_valid)) next_state = IDLE_ST;
        MEWR_ST: if (~write_mem_en) next_state = IDLE_ST;
        endcase
end

always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        last_coef <= 1'b0;
        enable_calc <= 1'b0;
        coef_cnt <= '0;
        out_ready <= 1'b0;
        out_data_valid_delay[0] <= 1'b0;
    end else begin
    
        case(state) 
        IDLE_ST: begin
            coef_cnt <= '0; 
            out_data_valid_delay[0] <= 1'b0;
            enable_calc <= 1'b0;
            out_ready <= 1'b1;
            if(in_data_valid) begin
                enable_calc <= 1'b1;
                out_ready <= 1'b0;
            end
        end
        CALC_ST: begin
            coef_cnt <= coef_cnt + 1'b1; 
            if(coef_cnt == max_coef_num_mem - 1) begin
                if (in_data_valid) begin
                    enable_calc <= 1'b1;  
                end
                else enable_calc <= 1'b0;
                coef_cnt <= '0;
                out_data_valid_delay[0] <= 1'b1;
            end
            else begin
                out_data_valid_delay[0] <= 1'b0;
            end
            if(coef_cnt == max_coef_num_mem - 2) last_coef <= 1'b1;
            else last_coef <= 1'b0;
            if(coef_cnt >= max_coef_num_mem - 3) out_ready <= 1'b1;
            else out_ready <= 1'b0;
        end
        endcase
        
    end
end


always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        out_data_valid <= 1'b0;
        for(int i = 1; i < out_data_valid_delay_num; i++) begin
                out_data_valid_delay[i] <= 1'b0;;
        end 
    end 
    else begin
        for(int i = 1; i < out_data_valid_delay_num; i++) begin
                out_data_valid_delay[i] <= out_data_valid_delay[i-1];
        end 
        out_data_valid <= out_data_valid_delay[out_data_valid_delay_num-1];
    end
end

endmodule