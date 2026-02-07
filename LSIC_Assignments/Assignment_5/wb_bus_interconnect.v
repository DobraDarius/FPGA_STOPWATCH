// Wishbone Bus Interconnect
// For single master, single slave - simple passthrough
// Can be extended for multiple slaves with address decoding
module wb_bus_interconnect(
    // Master interface
    input wire wb_cyc_m,
    input wire wb_stb_m,
    input wire wb_we_m,
    input wire [7:0] wb_adr_m,
    input wire [15:0] wb_dat_m,
    output wire [15:0] wb_dat_m_i,
    output wire wb_ack_m,
    
    // Slave interface
    output wire wb_cyc_s,
    output wire wb_stb_s,
    output wire wb_we_s,
    output wire [7:0] wb_adr_s,
    output wire [15:0] wb_dat_s,
    input wire [15:0] wb_dat_s_o,
    input wire wb_ack_s
);

    // For single master, single slave - just wire through
    assign wb_cyc_s = wb_cyc_m;
    assign wb_stb_s = wb_stb_m;
    assign wb_we_s = wb_we_m;
    assign wb_adr_s = wb_adr_m;
    assign wb_dat_s = wb_dat_m;
    
    assign wb_dat_m_i = wb_dat_s_o;
    assign wb_ack_m = wb_ack_s;

endmodule