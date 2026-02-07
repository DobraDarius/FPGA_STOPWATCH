// Top module - connects timer, Wishbone bus, and memory
module wishbone_stopwatch_top(
    input wire clk,
    input wire rst_n,
    input wire start_stop,
    input wire pause,
    input wire next_saved,
    output wire [2:0] debug_leds,
    output wire [6:0] segment_1, segment_2, segment_3, segment_4,
    output wire dot,
    output wire [2:0] switch
);

    // Native memory interface (Timer <-> Master Wrapper)
    wire mem_req, mem_we, mem_ack;
    wire [7:0] mem_addr;
    wire [15:0] mem_wr_data, mem_rd_data;
    
    // Wishbone bus signals (Master <-> Bus <-> Slave)
    wire wb_cyc, wb_stb, wb_we, wb_ack;
    wire [7:0] wb_adr;
    wire [15:0] wb_dat_m2s, wb_dat_s2m;
    
    // Native memory interface (Slave Wrapper <-> SRAM)
    wire [15:0] sram_rd_data_in, sram_rd_data_out;
    wire [7:0] sram_rd_addr, sram_wr_addr;
    wire sram_rd_en, sram_wr_en;
    wire [15:0] sram_wr_data;

    // ========================================================================
    // TIMER MODULE (with Wishbone-ready interface)
    // ========================================================================
    time_7segment_wb timer_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start_stop(start_stop),
        .pause(pause),
        .next_saved(next_saved),
        .debug_leds(debug_leds),
        .segment_1(segment_1),
        .segment_2(segment_2),
        .segment_3(segment_3),
        .segment_4(segment_4),
        .dot(dot),
        .switch(switch),
        
        // Native memory interface
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wr_data(mem_wr_data),
        .mem_rd_data(mem_rd_data),
        .mem_ack(mem_ack)
    );

    // ========================================================================
    // WISHBONE MASTER WRAPPER
    // ========================================================================
    wb_master_wrapper master_wrapper(
        .clk(clk),
        .rst_n(rst_n),
        
        // Native interface (from timer)
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wr_data(mem_wr_data),
        .mem_rd_data(mem_rd_data),
        .mem_ack(mem_ack),
        
        // Wishbone master interface
        .wb_cyc_o(wb_cyc),
        .wb_stb_o(wb_stb),
        .wb_we_o(wb_we),
        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_m2s),
        .wb_dat_i(wb_dat_s2m),
        .wb_ack_i(wb_ack)
    );

    // ========================================================================
    // WISHBONE BUS INTERCONNECT
    // ========================================================================
    wb_bus_interconnect bus(
        // Master side
        .wb_cyc_m(wb_cyc),
        .wb_stb_m(wb_stb),
        .wb_we_m(wb_we),
        .wb_adr_m(wb_adr),
        .wb_dat_m(wb_dat_m2s),
        .wb_dat_m_i(wb_dat_s2m),
        .wb_ack_m(wb_ack),
        
        // Slave side
        .wb_cyc_s(wb_cyc),
        .wb_stb_s(wb_stb),
        .wb_we_s(wb_we),
        .wb_adr_s(wb_adr),
        .wb_dat_s(wb_dat_m2s),
        .wb_dat_s_o(wb_dat_s2m),
        .wb_ack_s(wb_ack)
    );

    // ========================================================================
    // WISHBONE SLAVE WRAPPER
    // ========================================================================
    wb_slave_wrapper slave_wrapper(
        .clk(clk),
        .rst_n(rst_n),
        
        // Wishbone slave interface
        .wb_cyc_i(wb_cyc),
        .wb_stb_i(wb_stb),
        .wb_we_i(wb_we),
        .wb_adr_i(wb_adr),
        .wb_dat_i(wb_dat_m2s),
        .wb_dat_o(wb_dat_s2m),
        .wb_ack_o(wb_ack),
        
        // Native memory interface
        .rd_data_out(sram_rd_data_out),
        .rd_addr(sram_rd_addr),
        .rd_en(sram_rd_en),
        .rd_data_in(sram_rd_data_in),
        .wr_data(sram_wr_data),
        .wr_addr(sram_wr_addr),
        .wr_en(sram_wr_en)
    );

    // ========================================================================
    // SRAM MEMORY (Unchanged)
    // ========================================================================
    sram_2port memory(
        .clk(clk),
        .rd_data(sram_rd_data_in),
        .rd_addr(sram_rd_addr),
        .rd_en(sram_rd_en),
        .wr_data(sram_wr_data),
        .wr_addr(sram_wr_addr),
        .wr_en(sram_wr_en)
    );

endmodule