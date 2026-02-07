// Debouncer with edge detection
module debouncer #(
    parameter DEBOUNCE_TIME = 1_000_000  // 20ms at 50MHz
)(
    input wire clk,
    input wire rst_n,
    input wire button_in,
    output reg button_stable,      // Debounced level output
    output reg button_rising_edge  // Single-cycle pulse on rising edge
);
    reg [19:0] counter;
    reg button_sync1, button_sync2;  // Two-stage synchronizer
    reg button_prev;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            button_sync1 <= 0;
            button_sync2 <= 0;
            button_stable <= 0;
            button_prev <= 0;
            button_rising_edge <= 0;
        end else begin
            // Two-stage synchronizer (prevents metastability)
            button_sync1 <= button_in;
            button_sync2 <= button_sync1;
            
            // Debouncing logic
            if (button_sync2 == button_stable) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
                if (counter >= DEBOUNCE_TIME) begin
                    button_stable <= button_sync2;
                    counter <= 0;
                end
            end
            
            // Edge detection
            button_prev <= button_stable;
            button_rising_edge <= button_stable & ~button_prev;
        end
    end
endmodule