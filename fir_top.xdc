set TARGET_FREQ_MHZ 500

set TARGET_PERIOD_NS [expr {1000.0 / $TARGET_FREQ_MHZ}]

create_clock -name clk -period $TARGET_PERIOD_NS [get_ports clk]
set_clock_uncertainty [expr {$TARGET_PERIOD_NS * 0.01}] [get_clocks clk]

set_input_delay -clock clk -max [expr {$TARGET_PERIOD_NS * 0.6}] [all_inputs]
set_input_delay -clock clk -min [expr {$TARGET_PERIOD_NS * 0.2}] [all_inputs]

set_output_delay -clock clk -max [expr {$TARGET_PERIOD_NS * 0.6}] [all_outputs]
set_output_delay -clock clk -min [expr {$TARGET_PERIOD_NS * 0.2}] [all_outputs]

set_false_path -from [get_ports rst] -to [all_registers]