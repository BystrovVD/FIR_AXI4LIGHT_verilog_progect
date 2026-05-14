`timescale 1ns / 1ps

module fir_axi4light_ram #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_NUM   = 127    
) (
    input  wire                          clk,
    input  wire                          write_e,
    input  wire [$clog2(COEF_NUM)-1:0]   addr_write,
    input  wire [$clog2(COEF_NUM)-1:0]   addr_read,
    input wire [DATA_WIDTH-1:0]         data_write,
    output wire [DATA_WIDTH-1:0]         data_read
);

    reg [DATA_WIDTH-1:0] mem [0:COEF_NUM-1];
    
    logic [DATA_WIDTH-1:0] data_write_delay_1, data_write_delay_2;
    logic [$clog2(COEF_NUM)-1:0]   addr_write_delay_1, addr_write_delay_2;
    logic write_e_delay_1, write_e_delay_2;
    
    ///*
    always_ff @(posedge clk) begin
        if (write_e)
            mem[addr_write] <= data_write; 
    end
    //*/
    /*
    always_ff @(posedge clk) begin
            write_e_delay_1 <= write_e;
            data_write_delay_1 <= data_write;
            addr_write_delay_1 <= addr_write;
            write_e_delay_2 <= write_e_delay_1;
            data_write_delay_2 <= data_write_delay_1;
            addr_write_delay_2 <= addr_write_delay_1;  
    end
    
    
    
    always_ff @(posedge clk) begin
        if (write_e_delay_2)
            mem[addr_write_delay_2] <= data_write_delay_2; 
    end
    */

    assign data_read = mem[addr_read];
    

endmodule