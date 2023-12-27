`timescale 1ns/1ps 
/**************************************************************************/
/******************** Testbench for simulation ****************************/
/**************************************************************************/

/*************************** **********************************************/
/*************************** Definition file ******************************/
/*************************** **********************************************/
`define INPUTFILENAME		 "./images/hex/480-360.hex" // Input file name
`define OUTPUTFILENAME		 "./images/output.bmp"		// Output file name

module tb_simulation;

localparam BRIGHTNESS = 0;
localparam GRAYSCALE = 1;
localparam ROTATE = 2;

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------

reg HCLK, HRESETn;
reg [1:0] opcode;
wire [7:0] data_R;
wire [7:0] data_G;
wire [7:0] data_B;
wire [31:0] width;
wire [31:0] height;
wire [10:0] write_row;
wire [10:0] write_col;
wire File_Closed;

//-------------------------------------------------
// Components
//-------------------------------------------------

image_read 
#(.INFILE(`INPUTFILENAME))
	u_image_read
(
    .opcode(opcode), 
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .DATA_R(data_R),
    .DATA_G(data_G),
    .DATA_B(data_B),
    .out_width(width),
    .out_height(height),
    .write_row(write_row),
    .write_col(write_col)
); 

image_write 
#(.INFILE(`OUTPUTFILENAME))
	u_image_write
(
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .DATA_WRITE_R(data_R),
    .DATA_WRITE_G(data_G),
    .DATA_WRITE_B(data_B),
    .File_Closed(File_Closed),
    .width(width),
    .height(height),
    .row(write_row),
    .col(write_col)
);	

//-------------------------------------------------
// Test Vectors
//-------------------------------------------------
initial begin 
    HCLK = 0;
    forever #10 HCLK = ~HCLK;
end

initial begin
    HRESETn     = 0;
    opcode = GRAYSCALE;
    #25 HRESETn = 1;
end

always @ (*) 
	if(File_Closed)
		#10 $finish;

endmodule