`timescale 1ns / 1ps

module fir_axi4light_top#(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_NUM   = 127,
    parameter int FIFO_DEPTH = 7
)(
    input  logic                   clk,
    input  logic                   rst,
    
    axi4lite_intf.slave s_axil,
    /*
    input logic                          write_mem_en,
    input logic [$clog2(COEF_NUM)-1:0]   addr_write,
    input logic [$clog2(COEF_NUM)-1:0]   max_coef_num,
    input logic [DATA_WIDTH-1:0]         data_write,
    */
    
    input  logic [2*DATA_WIDTH-1:0]       i_AXIS_s_t_data,
    input  logic                          i_AXIS_s_t_valid,
    output logic                          o_AXIS_s_t_ready,
    
    output logic [2*DATA_WIDTH-1:0]       o_AXIS_m_t_data,
    output logic                          o_AXIS_m_t_valid,
    input  logic                          i_AXIS_m_t_ready
);

    
    logic                          write_mem_en;
    logic [$clog2(COEF_NUM)-1:0]   addr_write;
    logic [DATA_WIDTH-1:0]         data_write;
    logic [$clog2(COEF_NUM)-1:0]   max_coef_num;
    
    
    
    logic [2*DATA_WIDTH-1:0]  fifo_in_to_delay;
    logic                     fifo_in_valid;
    logic                     fifo_out_ready;
    logic                     delay_ready;
    
    logic [2*DATA_WIDTH-1:0]  delayed_data;
    logic [DATA_WIDTH-1:0]    coef_from_ram;
    logic [$clog2(COEF_NUM)-1:0] coef_cnt;
    logic                     enable_calc;
    logic                     last_coef;
    
    logic [DATA_WIDTH-1:0]    calc_out1, calc_out2;
    logic                     calc_done;

    fir_axi4light_fifo #(
        .DATA_WIDTH(2 * DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) input_fifo (
        .clk(clk), .rst(rst),
        .input_data(i_AXIS_s_t_data),
        .input_valid(i_AXIS_s_t_valid),
        .output_ready(o_AXIS_s_t_ready),
        .output_data(fifo_in_to_delay),
        .output_valid(fifo_in_valid),
        .input_ready(delay_ready) 
    );
    

   fir_axi4light_wrapper wrapp(
        .clk(clk), .rst(rst),
        .s_axil(s_axil),
        .out_coeff_val(data_write),
        .out_wr_addr(addr_write),
        .out_wr_en(write_mem_en),
        .out_max_coef_num(max_coef_num)
    );


    fir_axi4light_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_NUM(COEF_NUM)
    ) control_unit (
        .clk(clk), .rst(rst),
        .write_mem_en(write_mem_en),
        .max_coef_num(max_coef_num),
        .in_data_valid(fifo_in_valid),
        .out_ready(delay_ready),      
        .in_ready(fifo_out_ready),  
        .out_data_valid(calc_done),   
        .enable_calc(enable_calc),
        .last_coef(last_coef),
        .coef_cnt(coef_cnt) 
    );

    fir_axi4light_delay #(
        .DATA_WIDTH(2 * DATA_WIDTH),
        .COEF_NUM(COEF_NUM)
    ) delay_line (
        .clk(clk), .rst(rst),
        .cnt(coef_cnt),
        .in_vld(fifo_in_valid && delay_ready), 
        .in_data(fifo_in_to_delay),
        .out_data(delayed_data)
    );

    fir_axi4light_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_NUM(COEF_NUM)
    ) coef_memory (
        .clk(clk),
        .write_e(write_mem_en),
        .addr_write(addr_write),
        .addr_read(coef_cnt),
        .data_write(data_write),
        .data_read(coef_from_ram)
    );

    fir_axi4light_calc #(.DATA_WIDTH(DATA_WIDTH)) calc_inst1 (
        .clk(clk), .rst(rst),
        .enable(enable_calc),
        .coef(coef_from_ram),
        .data(delayed_data[DATA_WIDTH-1 : 0]),
        .last_coef(last_coef),
        .data_out(calc_out1)
    );

    fir_axi4light_calc #(.DATA_WIDTH(DATA_WIDTH)) calc_inst2 (
        .clk(clk), .rst(rst),
        .enable(enable_calc),
        .coef(coef_from_ram),
        .data(delayed_data[2*DATA_WIDTH-1 : DATA_WIDTH]),
        .last_coef(last_coef),
        .data_out(calc_out2)
    );

    fir_axi4light_fifo #(
        .DATA_WIDTH(2 * DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) output_fifo (
        .clk(clk), .rst(rst),
        .input_data({calc_out2, calc_out1}),
        .input_valid(calc_done),
        .output_ready(fifo_out_ready),
        .output_data(o_AXIS_m_t_data),
        .output_valid(o_AXIS_m_t_valid),
        .input_ready(i_AXIS_m_t_ready)
    );


endmodule