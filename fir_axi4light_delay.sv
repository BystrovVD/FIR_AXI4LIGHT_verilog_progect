`timescale 1ns / 1ps

module fir_axi4light_delay#( 
    parameter int DATA_WIDTH = 16,
    parameter int COEF_NUM   = 127
)(
    input logic                         clk,
    input logic                         rst,
    input logic [$clog2(COEF_NUM) - 1 : 0] cnt,
    input logic                         in_vld,
    input logic [DATA_WIDTH -1 :0]    in_data,
    
    output logic [DATA_WIDTH -1 :0]   out_data 
);

logic vld_d;
logic [0:COEF_NUM-1][DATA_WIDTH -1 :0] del;

always @(posedge clk, posedge rst) begin
    if(rst) begin
        vld_d   <= 1'b0;
        del <= '0;
    end else begin
        vld_d <= in_vld;
        if(in_vld && ~vld_d) begin
            del[0] <= in_data;
            for(int i = 1; i < COEF_NUM; i++) begin
                del[i] <= del[i-1];
            end 
        end
    end
end

assign out_data = del[cnt];
endmodule