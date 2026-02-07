module decoder(
    input wire [3:0] inp,
    output reg [6:0] out
);

    always @(*) begin
        case (inp)
            // 0 means ON, 1 means OFF for DE10-Lite
            // positions: gfedcba
            4'd0: out = 7'b1000000; // 0
            4'd1: out = 7'b1111001; // 1
            4'd2: out = 7'b0100100; // 2
            4'd3: out = 7'b0110000; // 3
            4'd4: out = 7'b0011001; // 4
            4'd5: out = 7'b0010010; // 5
            4'd6: out = 7'b0000010; // 6
            4'd7: out = 7'b1111000; // 7
            4'd8: out = 7'b0000000; // 8
            4'd9: out = 7'b0010000; // 9
            default: out = 7'b1111111; // OFF
        endcase
    end
endmodule