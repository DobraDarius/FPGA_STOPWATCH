// Wishbone Slave Wrapper
// Converts Wishbone protocol to native memory interface
module wb_slave_wrapper(
    input wire clk,
    input wire rst_n,
    
    // Wishbone slave interface (slave side)
    input wire wb_cyc_i,             // Cycle signal
    input wire wb_stb_i,             // Strobe signal
    input wire wb_we_i,              // Write enable
    input wire [7:0] wb_adr_i,       // Address
    input wire [15:0] wb_dat_i,      // Data in
    output reg [15:0] wb_dat_o,      // Data out
    output reg wb_ack_o,             // Acknowledge
    
    // Native memory interface (master side)
    output reg [15:0] rd_data_out,   // Data to return (for reads)
    output reg [7:0] rd_addr,        // Read address
    output reg rd_en,                // Read enable
    input wire [15:0] rd_data_in,    // Data from memory
    output reg [15:0] wr_data,       // Write data
    output reg [7:0] wr_addr,        // Write address
    output reg wr_en                 // Write enable
);

    // State machine
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;
    localparam ACK = 2'b11;
    
    reg [1:0] state, state_next;
    reg [15:0] captured_data, captured_data_next;
    
    // Next-state signals for outputs
    reg wb_ack_next;
    reg [15:0] wb_dat_next;
    reg [7:0] rd_addr_next, wr_addr_next;
    reg rd_en_next, wr_en_next;
    reg [15:0] wr_data_next;
    
    // SEQUENTIAL LOGIC
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            wb_ack_o <= 0;
            wb_dat_o <= 0;
            rd_addr <= 0;
            rd_en <= 0;
            wr_addr <= 0;
            wr_data <= 0;
            wr_en <= 0;
            captured_data <= 0;
        end else begin
            state <= state_next;
            wb_ack_o <= wb_ack_next;
            wb_dat_o <= wb_dat_next;
            rd_addr <= rd_addr_next;
            rd_en <= rd_en_next;
            wr_addr <= wr_addr_next;
            wr_data <= wr_data_next;
            wr_en <= wr_en_next;
            captured_data <= captured_data_next;
        end
    end
    
    // COMBINATIONAL LOGIC
    always @(*) begin
        // Default values
        state_next = state;
        wb_ack_next = 0;
        wb_dat_next = wb_dat_o;
        rd_addr_next = rd_addr;
        rd_en_next = 0;  // Pulse signals default to 0
        wr_addr_next = wr_addr;
        wr_data_next = wr_data;
        wr_en_next = 0;  // Pulse signals default to 0
        captured_data_next = captured_data;
        
        case (state)
            IDLE: begin
                // Detect valid Wishbone transaction
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin
                        // Write operation
                        wr_addr_next = wb_adr_i;
                        wr_data_next = wb_dat_i;
                        wr_en_next = 1;
                        state_next = WRITE;
                    end else begin
                        // Read operation
                        rd_addr_next = wb_adr_i;
                        rd_en_next = 1;
                        state_next = READ;
                    end
                end
            end
            
            READ: begin
                // Memory needs one cycle to read
                captured_data_next = rd_data_in;  // Capture data from memory
                state_next = ACK;
            end
            
            WRITE: begin
                // Memory write complete
                state_next = ACK;
            end
            
            ACK: begin
                // Send acknowledgment
                wb_ack_next = 1;
                wb_dat_next = captured_data;  // Send read data (ignored for writes)
                
                // Return to idle when transaction ends
                if (!wb_cyc_i || !wb_stb_i) begin
                    state_next = IDLE;
                end
            end
            
            default: state_next = IDLE;
        endcase
    end

endmodule