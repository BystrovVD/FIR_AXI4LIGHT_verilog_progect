`timescale 1ns / 1ps

module fir_axi4light_top_TB();

    parameter int DATA_WIDTH = 16;
    parameter int COEF_NUM   = 127;
    parameter int MAX_COEF_NUM   = 127;    
    parameter int FIFO_DEPTH = 7;
    parameter int CLK_PERIOD = 10;
    parameter int AXI_DATA_WIDTH = 32;
    parameter int AXI_ADDR_WIDTH = 32;

    logic                   clk;
    logic                   rst;
    
    axi4lite_intf #(
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(AXI_ADDR_WIDTH)
    ) axi_bus ();

    logic [2*DATA_WIDTH-1:0] i_AXIS_s_t_data;
    logic                   i_AXIS_s_t_valid;
    wire                    o_AXIS_s_t_ready;
    wire [2*DATA_WIDTH-1:0] o_AXIS_m_t_data;
    wire                    o_AXIS_m_t_valid;
    logic                   i_AXIS_m_t_ready;
    
    parameter int num_test_sample = 100;
    logic [DATA_WIDTH-1:0] coef_buffer [0:MAX_COEF_NUM-1];
    logic [DATA_WIDTH-1:0] in_buffer   [0:num_test_sample-1]; 
    logic [DATA_WIDTH-1:0] out_buffer  [0:num_test_sample-1];
    int mcount = 0;
    int com_cnt = 0;
    int err_num = 0;

    fir_axi4light_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_NUM(COEF_NUM),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .s_axil(axi_bus.slave), 
        .i_AXIS_s_t_data(i_AXIS_s_t_data),
        .i_AXIS_s_t_valid(i_AXIS_s_t_valid),
        .o_AXIS_s_t_ready(o_AXIS_s_t_ready),
        .o_AXIS_m_t_data(o_AXIS_m_t_data),
        .o_AXIS_m_t_valid(o_AXIS_m_t_valid),
        .i_AXIS_m_t_ready(i_AXIS_m_t_ready)
    );

    task axi_write(input [AXI_ADDR_WIDTH-1:0] addr, input [AXI_DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            axi_bus.AWADDR  = addr;
            axi_bus.AWVALID = 1;
            axi_bus.WDATA   = data;
            axi_bus.WVALID  = 1;
            axi_bus.WSTRB   = 4'hF;
            axi_bus.BREADY  = 1;

            wait (axi_bus.AWREADY && axi_bus.WREADY);
            @(posedge clk);
            axi_bus.AWVALID = 0;
            axi_bus.WVALID  = 0;

            wait (axi_bus.BVALID);
            @(posedge clk);
            axi_bus.BREADY  = 0;
        end
    endtask

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst = 1;
        i_AXIS_s_t_data = 0;
        i_AXIS_s_t_valid = 0;
        i_AXIS_m_t_ready = 1;
        
        axi_bus.AWVALID = 0;
        axi_bus.WVALID  = 0;
        axi_bus.BREADY  = 0;
        axi_bus.ARVALID = 0;
        axi_bus.RREADY  = 0;

        $readmemh("D:/Polytech/HW/3mag_School_of_synth/FIR_project/taps.txt", coef_buffer);
        $readmemh("D:/Polytech/HW/3mag_School_of_synth/FIR_project/sig_in_c.txt", in_buffer);
        $readmemh("D:/Polytech/HW/3mag_School_of_synth/FIR_project/sig_out_c.txt", out_buffer);

        repeat(5) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);

        for (int i = 0; i < MAX_COEF_NUM; i++) begin
            logic [31:0] packed_reg;
            packed_reg = {
                1'b0,                       
                7'(MAX_COEF_NUM),             
                7'(i),                      
                1'b1,                       
                16'(coef_buffer[i])         
            };

            axi_write(32'h0, packed_reg);
        end

        repeat(10) @(posedge clk);

        for (int i = 0; i < num_test_sample; i++) begin
            i_AXIS_s_t_valid = 1;
            i_AXIS_s_t_data = {in_buffer[i], in_buffer[i]}; 
            
            @(posedge clk);
            while(!o_AXIS_s_t_ready) @(posedge clk); 
            i_AXIS_s_t_valid = 0;
            
            repeat(130) @(posedge clk); 
        end

        wait((mcount == num_test_sample) | (com_cnt == 16'd15000));
        if (err_num > 0 )
            $display("FAIL: num of mistmatches = %0d ", err_num);
        else 
            $display("ALL VALUES MATCHED");
            
        repeat(20) @(posedge clk);
        $finish;
    end
    
    always @(negedge clk) begin
        if (o_AXIS_m_t_valid && mcount < num_test_sample) begin
            $display("--- Sample %0d ---", mcount);
            $display("Actual Data 1: %h", o_AXIS_m_t_data[31:16]);
            $display("Expected Data: %h", out_buffer[mcount]);
            if (signed'(o_AXIS_m_t_data[15:0]) != signed'(out_buffer[mcount])) begin
                $display("Mismatch at sample %0d", mcount);
                err_num <= err_num +1;
            end
            mcount <= mcount + 1;
        end
    end
    
     always @(posedge clk) begin
        com_cnt <= com_cnt + 1'b1;
     end

endmodule
