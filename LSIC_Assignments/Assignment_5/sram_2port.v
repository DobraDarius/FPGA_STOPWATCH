module sram_2port(
	input wire clk,
	output reg [15:0] rd_data, // the data that is read from the mem
	input wire [7:0] rd_addr, // the address of the wanted data to be read
	input wire rd_en, // YOU HAVE PERMISSION TO READ IF ACTIVE
	input wire [15:0] wr_data, // the data that is writed inside the memory
	input wire [7:0] wr_addr, // at a specific address
	input wire wr_en // YOU HAVE PERMISION TO WRITE IF ACTIVE
);
	reg [15:0] ram_mem [256:0]; // let us have 256 mem spaces
	
	always @(posedge clk) begin
		if(wr_en) begin
			ram_mem[wr_addr] <= wr_data;
		end
		if(rd_en) begin
			rd_data <= ram_mem[rd_addr];
		end
	end
endmodule
