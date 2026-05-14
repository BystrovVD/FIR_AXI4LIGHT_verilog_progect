`timescale 1ns / 1ps

import coeff_map_pkg::*;

module fir_axi4light_wrapper#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,

    axi4lite_intf.slave s_axil,

    output logic [15:0] out_coeff_val,
    output logic        out_wr_en,
    output logic [6:0]  out_wr_addr,
    output logic [6:0]  out_max_coef_num
);

    coeff_map_pkg::coeff_map__out_t hwif_out;

    coeff_map u_coeff_map (
        .clk      (clk),
        .rst      (rst),
        .s_axil   (s_axil), 
        .hwif_out (hwif_out)
    );

    assign out_coeff_val    = hwif_out.COEFF_BLOCK.COEFF.val.value;
    assign out_wr_en        = hwif_out.COEFF_BLOCK.COEFF.wr_en.value;
    assign out_wr_addr      = hwif_out.COEFF_BLOCK.COEFF.wr_addr.value;
    assign out_max_coef_num = hwif_out.COEFF_BLOCK.COEFF.max_coef_num.value;

endmodule
