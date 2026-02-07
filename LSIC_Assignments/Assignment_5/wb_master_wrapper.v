// Wishbone Master Wrapper
// Converts timer's native memory interface to Wishbone protocol
module wb_master_wrapper(
    input wire clk,
    input wire rst_n,
    
    // Native interface from timer (slave side)
    input wire mem_req,              // Timer requests transaction
    input wire mem_we,               // Write enable (1=write, 0=read)
    input wire [7:0] mem_addr,       // Address
    input wire [15:0] mem_wr_data,   // Data to write
    output reg [15:0] mem_rd_data,   // Data read
    output reg mem_ack,              // Transaction complete
    
    // Wishbone master interface (master side)
    output reg wb_cyc_o,             // Cycle signal
    output reg wb_stb_o,             // Strobe signal
    output reg wb_we_o,              // Write enable
    output reg [7:0] wb_adr_o,       // Address
    output reg [15:0] wb_dat_o,      // Data out
    input wire [15:0] wb_dat_i,      // Data in
    input wire wb_ack_i              // Acknowledge
);

    // State machine for Wishbone protocol
    localparam IDLE = 2'b00;
    localparam REQUEST = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    reg [1:0] state, state_next;
    
    // Next-state signals for outputs
    reg wb_cyc_next, wb_stb_next, wb_we_next;
    reg [7:0] wb_adr_next;
    reg [15:0] wb_dat_next;
    reg [15:0] mem_rd_data_next;
    reg mem_ack_next;
    
    // SEQUENTIAL LOGIC:
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            wb_we_o <= 0;
            wb_adr_o <= 0;
            wb_dat_o <= 0;
            mem_rd_data <= 0;
            mem_ack <= 0;
        end else begin
            state <= state_next;
            wb_cyc_o <= wb_cyc_next;
            wb_stb_o <= wb_stb_next;
            wb_we_o <= wb_we_next;
            wb_adr_o <= wb_adr_next;
            wb_dat_o <= wb_dat_next;
            mem_rd_data <= mem_rd_data_next;
            mem_ack <= mem_ack_next;
        end
    end
    
    // COMBINATIONAL LOGIC:
    always @(*) begin
        // Default values - hold current state
        state_next = state;
        wb_cyc_next = wb_cyc_o;
        wb_stb_next = wb_stb_o;
        wb_we_next = wb_we_o;
        wb_adr_next = wb_adr_o;
        wb_dat_next = wb_dat_o;
        mem_rd_data_next = mem_rd_data;
        mem_ack_next = 0;  // Pulse signal, default to 0
        
        case (state)
            IDLE: begin
                wb_cyc_next = 0;
                wb_stb_next = 0;
                
                if (mem_req) begin
                    // Start new transaction
                    wb_cyc_next = 1;
                    wb_stb_next = 1;
                    wb_we_next = mem_we;
                    wb_adr_next = mem_addr;
                    wb_dat_next = mem_wr_data;
                    state_next = REQUEST;
                end
            end
            
            REQUEST: begin
                // Keep signals stable, move to wait
                state_next = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (wb_ack_i) begin
                    // Transaction complete
                    mem_rd_data_next = wb_dat_i;  // Capture read data
                    mem_ack_next = 1;             // Signal completion to timer
                    wb_cyc_next = 0;              // Release bus
                    wb_stb_next = 0;
                    state_next = IDLE;
                end
            end
            
            default: state_next = IDLE;
        endcase
    end

endmodule