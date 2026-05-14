`timescale 1ns / 1ps

module mult_round_dsp #(
    parameter int DATA_WIDTH = 16
)(
    input  logic clk,
    input  logic signed [DATA_WIDTH-1:0] a,
    input  logic signed [DATA_WIDTH-1:0] b,
    
    output logic signed [DATA_WIDTH - 1 : 0] zlast
);

    localparam int P_WIDTH   = 2 * DATA_WIDTH;         
    localparam int F_WIDTH   = DATA_WIDTH - 1;         
    localparam int INT_WIDTH = DATA_WIDTH;

    logic signed [DATA_WIDTH-1:0] areg;
    logic signed [DATA_WIDTH-1:0] breg;
    logic signed [P_WIDTH-1:0]   z1;
    
    logic pattern_detect;
    
    logic signed [P_WIDTH-1:0] multadd;
    logic signed [P_WIDTH-1:0] multadd_reg;

    logic [P_WIDTH-1:0] c;
    assign c = (P_WIDTH'(1) << (F_WIDTH - 1)) - 1; 

    assign multadd = z1 + c + 1'b1;

    always_ff @(posedge clk) begin
        areg <= a;
        breg <= b;
        
        z1   <= areg * breg;
        
        pattern_detect <= (multadd[F_WIDTH-1:0] == {F_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
        
        multadd_reg <= multadd;
    end

    always_ff @(posedge clk) begin
        if (pattern_detect) begin
            zlast <= {multadd_reg[P_WIDTH-2 : F_WIDTH+1], 1'b0};
        end else begin
            zlast <= multadd_reg[P_WIDTH-2 : F_WIDTH];
        end
    end
endmodule
