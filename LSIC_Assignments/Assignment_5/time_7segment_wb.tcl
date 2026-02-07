# TCL for 7 segment time display (MM - SS)
# Implementing Wishbone Bus 

# Create project
project_new time_7segment -overwrite

# Device
set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G

# Source file
set_global_assignment -name VERILOG_FILE time_7segment_wb.v
set_global_assignment -name VERILOG_FILE decoder.v
set_global_assignment -name VERILOG_FILE sram_2port.v
set_global_assignment -name VERILOG_FILE debouncer.v
set_global_assignment -name VERILOG_FILE wb_master_wrapper.v
set_global_assignment -name VERILOG_FILE wb_bus_interconnect.v
set_global_assignment -name VERILOG_FILE wb_slave_wrapper.v
set_global_assignment -name VERILOG_FILE wishbone_stopwatch_top.v
# Top entity
set_global_assignment -name TOP_LEVEL_ENTITY wishbone_stopwatch_top

# Pin assignments for DE10-Lite
set_location_assignment PIN_P11 -to clk
set_location_assignment PIN_B8 -to rst_n
set_location_assignment PIN_B12 -to next_saved
set_location_assignment PIN_A12 -to start_stop
set_location_assignment PIN_F15 -to pause

#SEGMENTs specific pins
set_location_assignment PIN_C14 -to segment_1[0]
set_location_assignment PIN_E15 -to segment_1[1]
set_location_assignment PIN_C15 -to segment_1[2]
set_location_assignment PIN_C16 -to segment_1[3]
set_location_assignment PIN_E16 -to segment_1[4]
set_location_assignment PIN_D17 -to segment_1[5]
set_location_assignment PIN_C17 -to segment_1[6]

set_location_assignment PIN_C18 -to segment_2[0]
set_location_assignment PIN_D18 -to segment_2[1]
set_location_assignment PIN_E18 -to segment_2[2]
set_location_assignment PIN_B16 -to segment_2[3]
set_location_assignment PIN_A17 -to segment_2[4]
set_location_assignment PIN_A18 -to segment_2[5]
set_location_assignment PIN_B17 -to segment_2[6]

set_location_assignment PIN_B20 -to segment_3[0]
set_location_assignment PIN_A20 -to segment_3[1]
set_location_assignment PIN_B19 -to segment_3[2]
set_location_assignment PIN_A21 -to segment_3[3]
set_location_assignment PIN_B21 -to segment_3[4]
set_location_assignment PIN_C22 -to segment_3[5]
set_location_assignment PIN_B22 -to segment_3[6]
set_location_assignment PIN_A19 -to dot

set_location_assignment PIN_F21 -to segment_4[0]
set_location_assignment PIN_E22 -to segment_4[1]
set_location_assignment PIN_E21 -to segment_4[2]
set_location_assignment PIN_C19 -to segment_4[3]
set_location_assignment PIN_C20 -to segment_4[4]
set_location_assignment PIN_D19 -to segment_4[5]
set_location_assignment PIN_E17 -to segment_4[6]

#DEBUG LEDS
set_location_assignment PIN_A8 -to debug_leds[0]
set_location_assignment PIN_A9 -to debug_leds[1]
set_location_assignment PIN_A10 -to debug_leds[2]

#SWITCH LEDS
set_location_assignment PIN_D13 -to switch[1]
set_location_assignment PIN_B11 -to switch[0]
set_location_assignment PIN_C13 -to switch[2]

# Compile
load_package flow
execute_flow -compile

project_close
