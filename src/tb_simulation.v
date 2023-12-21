`timescale 1ns/1ps 
/**************************************************************************/
/******************** Testbench for simulation ****************************/
/**************************************************************************/

/*************************** **********************************************/
/*************************** Definition file ******************************/
/*************************** **********************************************/
`define INPUTFILENAME		 "./images/input.hex" // Input file name
`define OUTPUTFILENAME		 "./images/output.bmp"		// Output file name

// Choose the operation of code by delete // in the beginning of the selected line

//`define BRIGHTNESS_OPERATION
`define GRAYSCALE_OPERATION

module tb_simulation;

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------

reg HCLK, HRESETn;
wire          vsync;
wire          hsync;
wire [ 7 : 0] data_R;
wire [ 7 : 0] data_G;
wire [ 7 : 0] data_B;
wire enc_done;

//-------------------------------------------------
// Components
//-------------------------------------------------

image_read 
#(.INFILE(`INPUTFILENAME))
	u_image_read
( 
    .HCLK	                (HCLK    ),
    .HRESETn	            (HRESETn ),
    .HSYNC	                (hsync   ),
    .DATA_R	            (data_R ),
    .DATA_G	            (data_G ),
    .DATA_B	            (data_B ),
	.ctrl_done				(enc_done)
); 

image_write 
#(.INFILE(`OUTPUTFILENAME))
	u_image_write
(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.hsync(hsync),
   .DATA_WRITE_R(data_R),
   .DATA_WRITE_G(data_G),
   .DATA_WRITE_B(data_B),
	.Write_Done()
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
    #25 HRESETn = 1;
end

always @ (*) 
	if(enc_done)
		#1000 $finish;

endmodule