module image_read
#(
  parameter MAX_WIDTH 	= 1080, 						// Image WIDTH
			MAX_HEIGHT 	= 1080, 						// Image HEIGHT
			INFILE  = "input.hex" 						// image file
)
(
	input CLK,									// clock					
	input RESET,								// Reset (active low)
	input [11:0] ROW, 								// ROW index of the image
    input [11:0] COL, 								// column index of the image
	output reg [7:0]  RED,					        // 8 bit Red data
    output reg [7:0]  GREEN,					    // 8 bit Green data
    output reg [7:0]  BLUE,					    // 8 bit Blue data
    output [11:0] WIDTH,
    output [11:0] HEIGHT
);			

// Internal Signals
localparam BMP_HEADER_NUM = 54;
localparam sizeOfLengthReal = MAX_WIDTH*MAX_HEIGHT*3; 	// image data : 1179648 bytes: 512 * 768 *3 
reg [7:0] total_memory [0:BMP_HEADER_NUM + sizeOfLengthReal-1];	// memory to store  8-bit data image

// Reading data from input file
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1);
	$display("load file successfully");
end

assign WIDTH = {total_memory[21], total_memory[20], total_memory[19], total_memory[18]};
assign HEIGHT = {total_memory[25], total_memory[24], total_memory[23], total_memory[22]};

always@(*) begin
	RED 	<= total_memory[BMP_HEADER_NUM+WIDTH*3*(HEIGHT-ROW-1)+3*COL+0];
	GREEN 	<= total_memory[BMP_HEADER_NUM+WIDTH*3*(HEIGHT-ROW-1)+3*COL+1];
	BLUE 	<= total_memory[BMP_HEADER_NUM+WIDTH*3*(HEIGHT-ROW-1)+3*COL+2];
end

endmodule