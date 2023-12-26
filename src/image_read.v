/******************************************************************************/
/******************  Module for reading and processing image     **************/
/******************************************************************************/
//`define BRIGHTNESS_OPERATION
`define GRAYSCALE_OPERATION
//`define ROTATE

module image_read
#(
  parameter MAX_WIDTH 	= 768, 						// Image width
			MAX_HEIGHT 	= 512, 						// Image height
			INFILE  = "input.hex", 			// image file
			VALUE= 100,							// value for Brightness operation
			THRESHOLD= 90,						// Threshold value for Threshold operation
			SIGN=1								// Sign value using for brightness operation
													// SIGN = 0: Brightness subtraction
													// SIGN = 1: Brightness addition
)
(
	input HCLK,									// clock					
	input HRESETn,								// Reset (active low)
	output reg [31:0] out_width,
	output reg [31:0] out_height,
	output reg [10:0] write_row,
	output reg [10:0] write_col,
    output reg [7:0]  DATA_R,					// 8 bit Red data (even)
    output reg [7:0]  DATA_G,					// 8 bit Green data (even)
    output reg [7:0]  DATA_B,					// 8 bit Blue data (even)
	// Process and transmit 2 pixels in parallel to make the process faster, you can modify to transmit 1 pixels or more if needed
	output			  ctrl_done					// Done flag
);			
//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
localparam BMP_HEADER_NUM = 54;
localparam sizeOfLengthReal = MAX_WIDTH*MAX_HEIGHT*3; 	// image data : 1179648 bytes: 512 * 768 *3 
// local parameters for FSM
localparam		ST_IDLE 	= 2'b00,			// idle state
				ST_DATA		= 2'b11;			// state for data processing 
reg [1:0] cstate, 								// current state
		  nstate;								// next state			
reg start;										// start signal: trigger Finite state machine beginning to operate
reg HRESETn_d;									// delayed reset signal: use to create start signal
reg 		ctrl_data_run;						// control signal for data processing
reg [7:0]   total_memory [0 :BMP_HEADER_NUM + sizeOfLengthReal-1];	// memory to store  8-bit data image
// temporary memory to save image data : size will be MAX_WIDTH*MAX_HEIGHT*3		
reg [7:0] org_R  [0 : MAX_WIDTH*MAX_HEIGHT - 1]; 			// temporary storage for R component
reg [7:0] org_G  [0 : MAX_WIDTH*MAX_HEIGHT - 1];			// temporary storage for G component
reg [7:0] org_B  [0 : MAX_WIDTH*MAX_HEIGHT - 1];			// temporary storage for B component
// counting variables
integer i, j;
// temporary signals for calculation: details in the paper.
integer tempR,tempG,tempB; 					// temporary variables in contrast and brightness operation

integer value,value2;							// temporary variables in invert and threshold operation
reg [10:0] row; 								// row index of the image
reg [10:0] col; 								// column index of the image
reg [18:0] data_count; 							// data counting for entire pixels of the image
wire [31:0] width;
wire [31:0] height;
//-------------------------------------------------//
// -------- Reading data from input file ----------//
//-------------------------------------------------//
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); // read file from INFILE
	$display("load file successfully");
end
// use 3 intermediate signals RGB to save image data
always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<height; i=i+1) begin
            for(j=0; j<width; j=j+1) begin
                org_R[width*i+j] = total_memory[BMP_HEADER_NUM+width*3*(height-i-1)+3*j+0]; // save Red component
                org_G[width*i+j] = total_memory[BMP_HEADER_NUM+width*3*(height-i-1)+3*j+1];// save Green component
                org_B[width*i+j] = total_memory[BMP_HEADER_NUM+width*3*(height-i-1)+3*j+2];// save Blue component
            end
        end
    end
end

assign width = {total_memory[21], total_memory[20], total_memory[19], total_memory[18]};
assign height = {total_memory[25], total_memory[24], total_memory[23], total_memory[22]};

//----------------------------------------------------//
// ---Begin to read image file once reset was high ---//
// ---by creating a starting pulse (start)------------//
//----------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(!HRESETn) begin
        start <= 0;
		HRESETn_d <= 0;
    end
    else begin											//        ______		 				
        HRESETn_d <= HRESETn;							//       |		|
		if(HRESETn == 1'b1 && HRESETn_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
			start <= 1'b1;
		else
			start <= 1'b0;
    end
end

//------------------------------------------------------------------------------------------------//
// Finite state machine for reading RGB888 data from memory and creating hsync and vsync pulses --//
//------------------------------------------------------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        cstate <= ST_IDLE;
    end
    else begin
        cstate <= nstate; // update next state 
    end
end
//-----------------------------------------//
//--------- State Transition --------------//
//-----------------------------------------//
// IDLE . DATA
always @(*) begin
	case(cstate)
		ST_IDLE: begin
			if(start)
				nstate = ST_DATA;
			else
				nstate = ST_IDLE;
		end				
		ST_DATA: begin
			if(ctrl_done)
				nstate = ST_IDLE;
			else 
				nstate = ST_DATA;	
		end
	endcase
end
// ------------------------------------------------------------------- //
// ----------------------- control signal ---------------------------- //
// ------------------------------------------------------------------- //
always @(*) begin
	ctrl_data_run  = 0;
	case(cstate)
		ST_DATA: ctrl_data_run  = 1; // trigger counting for data processing
	endcase
end

// counting data, column and row index for reading memory 
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
		data_count <= 0;
        row <= 0;
		col <= 0;
    end
	else begin
		if(ctrl_data_run) begin
			data_count <= data_count + 1;
			if(col == width - 1) begin
				row <= row + 1;
				col <= 0;
			end
			else
				col <= col + 1;
		end
	end
end

assign ctrl_done = (data_count >= width*height-1)? 1'b1: 1'b0; // done flag
//-------------------------------------------------//
//-------------  Image processing   ---------------//
//-------------------------------------------------//
always @(*) begin
	DATA_R = 0;
	DATA_G = 0;
	DATA_B = 0;                                                                              
	if(ctrl_data_run) begin	
		`ifdef BRIGHTNESS_OPERATION	
		/**************************************/		
		/*		BRIGHTNESS ADDITION OPERATION */
		/**************************************/
		out_width = width;
		out_height = height;
		write_row = row;
		write_col = col;
		if(SIGN == 1) begin
		// R0
		tempR = org_R[width * row + col   ] + VALUE;
		if (tempR > 255)
			DATA_R = 255;
		else
			DATA_R = org_R[width * row + col   ] + VALUE;
		// G0	
		tempG = org_G[width * row + col   ] + VALUE;
		if (tempG > 255)
			DATA_G = 255;
		else
			DATA_G = org_G[width * row + col   ] + VALUE;	
		// B
		tempB = org_B[width * row + col   ] + VALUE;
		if (tempB > 255)
			DATA_B = 255;
		else
			DATA_B = org_B[width * row + col   ] + VALUE;
	end
	else begin
	/**************************************/		
	/*	BRIGHTNESS SUBTRACTION OPERATION */
	/**************************************/
		// R0
		tempR = org_R[width * row + col   ] - VALUE;
		if (tempR < 0)
			DATA_R = 0;
		else
			DATA_R = org_R[width * row + col   ] - VALUE;	
		// G0	
		tempG = org_G[width * row + col   ] - VALUE;
		if (tempG < 0)
			DATA_G = 0;
		else
			DATA_G = org_G[width * row + col   ] - VALUE;		
		// B0
		tempB = org_B[width * row + col   ] - VALUE;
		if (tempB < 0)
			DATA_B = 0;
		else
			DATA_B = org_B[width * row + col   ] - VALUE;
	 end
		`endif
	
		/**************************************/		
		/*		GRAYSCALE_OPERATION 		  */
		/**************************************/
		`ifdef GRAYSCALE_OPERATION	
			out_width = width;
			out_height = height;
			write_row = row;
			write_col = col;
			value2 = (org_B[width * row + col] + org_R[width * row + col] + org_G[width * row + col]) / 3;
			DATA_R = value2;
			DATA_G = value2;
			DATA_B = value2;	
		`endif

		`ifdef ROTATE	
			out_width = height;
			out_height = width;
			write_row = col;
			write_col = height - row;
			DATA_R = org_R[width * row + col];
			DATA_G = org_G[width * row + col];
			DATA_B = org_B[width * row + col];	
		`endif
	end
end
endmodule


