/******************************************************************************/
/******************     Module for writing .bmp image    		 *************/
/******************************************************************************/
module image_write
#(parameter MAX_WIDTH 	= 1080,						// Image WIDTH
			MAX_HEIGHT 	= 1080,						// Image HEIGHT
			INFILE  = "output.bmp",				// Output image
			BMP_HEADER_NUM = 54					// Header for bmp image
)
(
	input CLK,									// Clock	
	input RESET,	
    input [11:0] WIDTH,
	input [11:0] HEIGHT,
    input [11:0] ROW,
    input [11:0] COL,
    input [7:0]  RED,					// Red 8-bit data (odd)
    input [7:0]  GREEN,					// Green 8-bit data (odd)
    input [7:0]  BLUE,					// Blue 8-bit data (odd)
    output reg FILE_CLOSED
);	
reg [7:0] BMP_header [0:BMP_HEADER_NUM - 1];	// BMP header
reg [7:0] out_BMP    [0:MAX_WIDTH*MAX_HEIGHT*3 - 1];	// Temporary memory for image
integer data_count;								// Counting data
wire done;										// done flag
// counting variables
integer i, k, fd;

//----------------------------------------------------------//
//-------Header data for bmp image--------------------------//
//----------------------------------------------------------//
// Windows BMP files begin with a 54-byte header: 
// Check the website to see the value of this header: http://www.fastgraph.com/help/bmp_header_format.html
initial begin
	BMP_header[ 0] = 66;
	BMP_header[ 1] = 77;
	BMP_header[ 2] = 54;
	BMP_header[ 3] =  0;
	BMP_header[ 4] = 18;
	BMP_header[ 5] =  0;
	BMP_header[ 6] =  0;
	BMP_header[ 7] =  0;
	BMP_header[ 8] =  0;
	BMP_header[ 9] =  0;
	BMP_header[10] = 54;
	BMP_header[11] =  0;
	BMP_header[12] =  0;
	BMP_header[13] =  0;
	BMP_header[14] = 40;
	BMP_header[15] =  0;
	BMP_header[16] =  0;
	BMP_header[17] =  0;
    // 18-25 set later
	BMP_header[26] = 1;
	BMP_header[27] = 0;
    BMP_header[28] = 24;
    BMP_header[29] = 0;
    BMP_header[30] = 0;
    BMP_header[31] = 0;
    BMP_header[32] = 0;
    BMP_header[33] = 0;
    BMP_header[34] = 0;
    BMP_header[35] = 0;
    BMP_header[36] = 0;
    BMP_header[37] = 0;
    BMP_header[38] = 0;
    BMP_header[39] = 0;
    BMP_header[40] = 0;
    BMP_header[41] = 0;
    BMP_header[42] = 0;
    BMP_header[43] = 0;
    BMP_header[44] = 0;
    BMP_header[45] = 0;
    BMP_header[46] = 0;
    BMP_header[47] = 0;
    BMP_header[48] = 0;
    BMP_header[49] = 0;
    BMP_header[50] = 0;
    BMP_header[51] = 0;
    BMP_header[52] = 0;
    BMP_header[53] = 0;
end

always @(*) begin
    {BMP_header[21], BMP_header[20], BMP_header[19], BMP_header[18]} <= WIDTH;
    {BMP_header[25], BMP_header[24], BMP_header[23], BMP_header[22]} <= HEIGHT;
end

// Writing RGB888 even and odd data to the temp memory
always@(posedge CLK, negedge RESET) begin
    if(!RESET)
        for(k=0;k<WIDTH*HEIGHT*3;k=k+1)
            out_BMP[k] <= 0;
    else begin
        out_BMP[WIDTH*3*ROW + 3*COL + 2] <= RED;
        out_BMP[WIDTH*3*ROW + 3*COL + 1] <= GREEN;
        out_BMP[WIDTH*3*ROW + 3*COL    ] <= BLUE;
    end
end
// data counting
always@(posedge CLK, negedge RESET)
begin
    if(~RESET)
        data_count <= 0;
    else
		data_count <= data_count + 1; // pixels counting for create done flag
end

assign done = (data_count == WIDTH*HEIGHT-1)? 1'b1: 1'b0; // done flag once all pixels were processed

//---------------------------------------------------------//
//--------------Write .bmp file		----------------------//
//----------------------------------------------------------//
initial begin
    fd = $fopen(INFILE, "wb+");
end
always@(done) begin // once the processing was done, bmp image will be created
    if(done == 1'b1) begin
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]); // write the header
        end
        
        for(i=0; i<WIDTH*HEIGHT*3; i=i+3) begin
		// write RBG
            $fwrite(fd, "%c", out_BMP[i  ][7:0]);
            $fwrite(fd, "%c", out_BMP[i+1][7:0]);
            $fwrite(fd, "%c", out_BMP[i+2][7:0]);
        end
        $fclose(fd);
        $display("Write file successfully!");
        FILE_CLOSED = 1;
    end
    else
       FILE_CLOSED = 0;
end
endmodule