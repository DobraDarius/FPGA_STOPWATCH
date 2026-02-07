// Timer module modified to work with Wishbone master wrapper
module time_7segment_wb(
	input wire clk,
	input wire rst_n,
	input wire start_stop,
	input wire pause,
    input wire next_saved,
	output reg [2:0] debug_leds,
	output wire [6:0] segment_1, segment_2, segment_3, segment_4,
    output reg dot,
    output [2:0] switch,
    
    // Memory interface (connects to master wrapper)
    output reg mem_req,              // Request memory transaction
    output reg mem_we,               // Write enable (1=write, 0=read)
    output reg [7:0] mem_addr,       // Memory address
    output reg [15:0] mem_wr_data,   // Data to write
    input wire [15:0] mem_rd_data,   // Data read from memory
    input wire mem_ack,              // Transaction complete
    
    // Debug outputs
    output wire [3:0] current_state  // For debugging state machine
);

	assign switch = {start_stop, pause, next_saved};

	//PARAMS
    parameter CLK_FREQ = 50_000_000;
    parameter SECOND_COUNT = CLK_FREQ;
    
    // Debounced signals
    wire start_stop_stable, start_stop_edge;
    wire pause_stable, pause_edge;
    wire next_saved_stable, next_saved_edge;
    
    // Instantiate debouncers
    debouncer #(.DEBOUNCE_TIME(1_000_000)) db_start (
        .clk(clk),
        .rst_n(rst_n),
        .button_in(start_stop),
        .button_stable(start_stop_stable),
        .button_rising_edge(start_stop_edge)
    );
    
    debouncer #(.DEBOUNCE_TIME(1_000_000)) db_pause (
        .clk(clk),
        .rst_n(rst_n),
        .button_in(pause),
        .button_stable(pause_stable),
        .button_rising_edge(pause_edge)
    );
    
    debouncer #(.DEBOUNCE_TIME(1_000_000)) db_next (
        .clk(clk),
        .rst_n(rst_n),
        .button_in(next_saved),
        .button_stable(next_saved_stable),
        .button_rising_edge(next_saved_edge)
    );
    
    //INTERNAL_SIGNALS
    reg [25:0] counter;
    reg [25:0] counter_next;
    reg [3:0] second_counter_1;
    reg [3:0] second_counter_next_1;
    reg [3:0] second_counter_2;
    reg [3:0] second_counter_next_2;
    reg [3:0] minute_counter_1;
    reg [3:0] minute_counter_next_1;
    reg [3:0] minute_counter_2;
    reg [3:0] minute_counter_next_2;

    //STATE DEFINITION
    localparam [3:0] S_IDLE = 4'd0;
    localparam [3:0] S_RUN = 4'd1;
    localparam [3:0] S_PAUSE = 4'd2;
    localparam [3:0] S_WRITE_REQ = 4'd3;    // Request write to memory
    localparam [3:0] S_WRITE_WAIT = 4'd4;   // Wait for write ack
    localparam [3:0] S_READ = 4'd5;
    localparam [3:0] S_READ_REQ = 4'd6;     // Request read from memory
    localparam [3:0] S_READ_WAIT = 4'd7;    // Wait for read ack
    localparam [3:0] S_READ_NXT = 4'd8;

    // Track write and read pointers
    reg [7:0] wr_pnt, rd_pnt, wr_pnt_next, rd_pnt_next;
    
    // States
    reg [3:0] state, state_next;
    
    // Captured read data
    reg [15:0] captured_data, captured_data_next;
    
    // Memory interface next-state signals
    reg mem_req_next, mem_we_next;
    reg [7:0] mem_addr_next;
    reg [15:0] mem_wr_data_next;
    
    // Debug output
    assign current_state = state;

    // SEQUENTIAL LOGIC
    always @(posedge clk) begin
        if(!rst_n) begin
            state <= S_IDLE;
            wr_pnt <= 0;
            rd_pnt <= 0;
            counter <= 0;
            second_counter_1 <= 0;
            second_counter_2 <= 0;
            minute_counter_1 <= 0;
            minute_counter_2 <= 0;
            dot <= 1;
            debug_leds <= 0;
            captured_data <= 0;
            
            // Memory interface signals
            mem_req <= 0;
            mem_we <= 0;
            mem_addr <= 0;
            mem_wr_data <= 0;
        end else begin
            state <= state_next;
            wr_pnt <= wr_pnt_next;
            rd_pnt <= rd_pnt_next;
            counter <= counter_next;
            second_counter_1 <= second_counter_next_1;
            second_counter_2 <= second_counter_next_2;
            minute_counter_1 <= minute_counter_next_1;
            minute_counter_2 <= minute_counter_next_2;
            captured_data <= captured_data_next;
            dot <= 0;
            debug_leds <= state[2:0];
            
            // Update memory interface from combinational logic
            mem_req <= mem_req_next;
            mem_we <= mem_we_next;
            mem_addr <= mem_addr_next;
            mem_wr_data <= mem_wr_data_next;
        end
    end

    //COMBINATIONAL BLOCK
    always @(*) begin
        state_next = state;
        counter_next = counter;
        second_counter_next_1 = second_counter_1;
        second_counter_next_2 = second_counter_2;
        minute_counter_next_1 = minute_counter_1;
        minute_counter_next_2 = minute_counter_2;
        wr_pnt_next = wr_pnt;
        rd_pnt_next = rd_pnt;
        captured_data_next = captured_data;

        case (state)
            S_IDLE: begin
                counter_next = 0;
                second_counter_next_1 = 0;
                second_counter_next_2 = 0;
                minute_counter_next_1 = 0;
                minute_counter_next_2 = 0;
				
                if(start_stop_edge && !pause_stable) begin
                    state_next = S_RUN;
                end
            end

            S_RUN: begin
                if(pause_edge) begin
                	// Need to write to memory
                    state_next = S_WRITE_REQ;
                end
                else if (start_stop_edge) begin
                	if(wr_pnt > 0) begin
                		state_next = S_READ;
                	end
                	else begin
                    	state_next = S_IDLE;
                    end
                end
                else begin
                    // Counter logic
                    if(counter == SECOND_COUNT - 1) begin
                        counter_next = 0;

                        if(second_counter_1 == 9) begin
                            second_counter_next_1 = 0;

                            if(second_counter_2 == 5) begin
                                second_counter_next_2 = 0;

                                if(minute_counter_1 == 9) begin
                                    minute_counter_next_1 = 0;

                                    if(minute_counter_2 == 5) begin
                                        minute_counter_next_2 = 0;
                                    end
                                    else begin
                                        minute_counter_next_2 = minute_counter_2 + 1;
                                    end
                                end
                                else begin
                                    minute_counter_next_1 = minute_counter_1 + 1;
                                end
                            end
                            else begin
                                second_counter_next_2 = second_counter_2 + 1;
                            end
                        end
                        else begin
                            second_counter_next_1 = second_counter_1 + 1;
                        end
                    end
                    else begin
                        counter_next = counter + 1;
                    end
                end
            end
            
            S_WRITE_REQ: begin
                // Memory write request
                mem_req_next = 1;
                mem_we_next = 1;
                mem_addr_next = wr_pnt;
                mem_wr_data_next = {minute_counter_2, minute_counter_1, 
                                    second_counter_2, second_counter_1};
                // Wait one cycle for request to register
                state_next = S_WRITE_WAIT;
            end
            
            S_WRITE_WAIT: begin
                if (mem_ack) begin
                    // Write complete
                    wr_pnt_next = wr_pnt + 1;
                    state_next = S_PAUSE;
                end
            end

            S_PAUSE: begin
                if(start_stop_edge) begin
                    state_next = S_READ;
                end
                else if(pause_edge) begin
                    state_next = S_RUN;
                end
            end
            
            S_READ: begin
            	if(rd_pnt == wr_pnt) begin
            		state_next = S_IDLE;
            	end
            	else begin
            	    // Need to read from memory
            	    state_next = S_READ_REQ;
            	end
            end
            
            S_READ_REQ: begin
                // Memory read request
                mem_req_next = 1;
                mem_we_next = 0;
                mem_addr_next = rd_pnt;
                // Wait one cycle for request to register
                state_next = S_READ_WAIT;
            end
            
            S_READ_WAIT: begin
                if (mem_ack) begin
                    // Read complete, capture data
                    captured_data_next = mem_rd_data;
                    state_next = S_READ_NXT;
                end
            end
           
           	S_READ_NXT: begin
           		if(next_saved_edge) begin
           			    rd_pnt_next = rd_pnt + 1;
           			    state_next = S_READ;
           			end
           		end
           			
            default: state_next = S_IDLE;
        endcase      
    end

    // Display value selection
    reg [3:0] display_val_sec1, display_val_sec2, display_val_min1, display_val_min2;

    always @(*) begin
        if(state == S_READ_NXT || state == S_READ_WAIT) begin
            display_val_sec1 = captured_data[3:0];
            display_val_sec2 = captured_data[7:4];
            display_val_min1 = captured_data[11:8];
            display_val_min2 = captured_data[15:12];
        end
        else begin
            display_val_sec1 = second_counter_1;
            display_val_sec2 = second_counter_2;
            display_val_min1 = minute_counter_1;
            display_val_min2 = minute_counter_2;
        end
    end    

    decoder sec_block_1(.inp(display_val_sec1), .out(segment_1));
    decoder sec_block_2(.inp(display_val_sec2), .out(segment_2));
    decoder min_block_1(.inp(display_val_min1), .out(segment_3));
    decoder min_block_2(.inp(display_val_min2), .out(segment_4));

endmodule