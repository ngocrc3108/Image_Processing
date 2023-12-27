`timescale 1ns/1ps 

`define INPUTFILENAME		 "./images/hex/768-512.hex" // Input file name
`define OUTPUTFILENAME		 "./images/output.bmp"		// Output file name

module tb_simulation;

localparam BRIGHTNESS = 0;
localparam GRAYSCALE = 1;
localparam ROTATE = 2;

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
reg CLK, RESET;
reg [1:0] opcode;
wire [7:0] read_red;
wire [7:0] read_green;
wire [7:0] read_blue;
wire [7:0] write_red;
wire [7:0] write_green;
wire [7:0] write_blue;
wire [11:0] read_width;
wire [11:0] read_height;
wire [11:0] read_row;
wire [11:0] read_col;
wire [11:0] write_row;
wire [11:0] write_col;
wire [11:0] write_width;
wire [11:0] write_height;
wire file_closed;

image_read 
#(.INFILE(`INPUTFILENAME))
	u_image_read
(
    .CLK(CLK),
    .RESET(RESET),
    .ROW(read_row),
    .COL(read_col),
    .RED(read_red),
    .GREEN(read_green),
    .BLUE(read_blue),
    .WIDTH(read_width),
    .HEIGHT(read_height)
);

processing p
(
    .CLK(CLK),
    .RESET(RESET),
    .OPCODE(opcode),
    .READ_WIDTH(read_width),
    .READ_HEIGHT(read_height),
    .READ_RED(read_red),
    .READ_GREEN(read_green),
    .READ_BLUE(read_blue),
    .READ_ROW(read_row),
    .READ_COL(read_col),
    .WRITE_WIDTH(write_width),
    .WRITE_HEIGHT(write_height),
    .WRITE_ROW(write_row),
    .WRITE_COL(write_col),
    .WRITE_RED(write_red),
    .WRITE_GREEN(write_green),
    .WRITE_BLUE(write_blue)
);

image_write 
#(.INFILE(`OUTPUTFILENAME))
	u_image_write
(
    .CLK(CLK),
    .RESET(RESET),
    .WIDTH(write_width),
    .HEIGHT(write_height),
    .ROW(write_row),
    .COL(write_col),
    .RED(write_red),
    .GREEN(write_green),
    .BLUE(write_blue),
    .FILE_CLOSED(file_closed)
);	

initial begin 
    CLK = 0;
    forever #10 CLK = ~CLK;
end

initial begin
    RESET = 0;
    opcode = GRAYSCALE;
    #25 RESET = 1;
end

always @ (*) 
	if(file_closed)
		#10 $finish;

endmodule