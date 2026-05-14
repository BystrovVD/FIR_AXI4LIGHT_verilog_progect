`timescale 1ns / 1ps

import coeff_map_pkg::*;

module coeff_wrapper (
    input  logic        clk,
    input  logic        rst,

    axi4lite_intf.slave s_axil,

    output logic [15:0] o_data,        
    output logic [2:0]  o_data_addr,   
    output logic        o_write_enable  
);

    coeff_map_pkg::coeff_map__out_t hwif_out;

    coeff_map u_coeff_logic (
        .clk      (clk),
        .rst      (rst),
        .s_axil   (s_axil),
        .hwif_out (hwif_out)
    );

    
    logic [2:0] current_reg_idx;
    logic       reg_written;

    always_ff @(posedge clk) begin
        if (rst) begin
            o_data         <= 16'h0;
            o_data_addr    <= 3'h0;
            o_write_enable <= 1'b0;
        end else begin
            o_write_enable <= 1'b0;


            if (s_axil.AWVALID && s_axil.AWREADY && s_axil.WVALID && s_axil.WREADY) begin

                current_reg_idx <= s_axil.AWADDR[4:2];
                
                o_data_addr    <= s_axil.AWADDR[4:2];
                o_data         <= s_axil.WDATA[15:0];
                o_write_enable <= s_axil.WDATA[16]; 
            end
        end
    end

endmodule
