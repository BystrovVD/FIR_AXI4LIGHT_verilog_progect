`timescale 1ns / 1ps

module fir_axi4light_calc#(
    parameter int DATA_WIDTH = 16
)(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic last_coef,
    input logic [DATA_WIDTH - 1 : 0] coef,
    input logic [DATA_WIDTH - 1 : 0] data,
    
    output logic [DATA_WIDTH - 1 : 0] data_out
);


localparam int en_num_del = 7;
logic [en_num_del-1:0] enable_delay;
logic [en_num_del-1:0] last_coef_delay;

logic signed [2*DATA_WIDTH - 1 : 0] mult_res;
logic [DATA_WIDTH - 1 : 0] data_delay;
logic [DATA_WIDTH - 1 : 0] coef_delay;
logic [DATA_WIDTH - 1 : 0] data_delay_2;
logic [DATA_WIDTH - 1 : 0] coef_delay_2;
logic [DATA_WIDTH - 1 : 0] round_val_delay;
logic [DATA_WIDTH - 1 : 0] round_val_delay2;

logic [DATA_WIDTH - 1 : 0] acc;


localparam int clipp_value = {(DATA_WIDTH-1){1'b1}};

always @(posedge clk) begin
    data_delay <= data;
    coef_delay <= coef;
    data_delay_2 <= data_delay;
    coef_delay_2 <= coef_delay;
end


mult_round_dsp #(
        .DATA_WIDTH(DATA_WIDTH)
    ) mult_round (
        .clk(clk),
        .a(data_delay_2),
        .b(coef_delay_2),
        .zlast(round_val_delay)
    );


always @(posedge clk) begin
    round_val_delay2 <= round_val_delay;
end

logic signed [DATA_WIDTH : 0] sum_res;
assign sum_res = $signed(round_val_delay2) + $signed(acc);



always @(posedge clk, posedge rst) begin : accumulate_sum_block
    if(rst) begin
        for(int i = 0; i < en_num_del; i++) begin
                enable_delay[i] <= 1'b0;
        end
        for(int i = 0; i < en_num_del; i++) begin
                last_coef_delay[i] <= 1'b0;
        end 
        acc <= {DATA_WIDTH{1'b0}}; 
    end
    else begin
        for(int i = 1; i < en_num_del; i++) begin
                enable_delay[i] <= enable_delay[i-1];
        end 
        for(int i = 1; i < en_num_del; i++) begin
                last_coef_delay[i] <= last_coef_delay[i-1];
        end 
        enable_delay[0] <= enable;
        last_coef_delay[0] <= last_coef;
        
        if (last_coef_delay[en_num_del-1]) begin
            acc <= {DATA_WIDTH{1'b0}};  
            if(sum_res >= clipp_value)
                data_out <= clipp_value;
            else if (sum_res <= -(clipp_value+1))
                data_out <= -(clipp_value+1);
            else
                data_out <= sum_res[DATA_WIDTH - 1 : 0];
        end 
        else begin
            if(enable_delay[en_num_del-1]) 
                if(sum_res >= clipp_value)
                    acc <= clipp_value;
                else if (sum_res <= -(clipp_value+1))
                    acc <= -(clipp_value+1);
                else
                    acc <= sum_res[DATA_WIDTH - 1 : 0];
            else 
                acc <= {DATA_WIDTH{1'b0}};
        end
    end
end

endmodule
