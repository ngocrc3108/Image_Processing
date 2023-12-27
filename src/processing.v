`timescale 1ns / 1ps
module processing
#(
  parameter MAX_WIDTH 	= 1080, 						// Image width
			MAX_HEIGHT 	= 1080, 						// Image height
			INFILE  = "input.hex", 			// image file
			VALUE = 100,							// value for Brightness operation
			SIGN=0								// Sign value using for brightness operation
													// SIGN = 0: Brightness subtraction
													// SIGN = 1: Brightness addition
)
(
	input CLK,									// clock					
	input RESET,								// Reset (active low)
	input [1:0] OPCODE,
    input [11:0] READ_WIDTH,
    input [11:0] READ_HEIGHT,
    input [7:0]  READ_RED,					        // 8 bit Red data
    input [7:0]  READ_GREEN,					    // 8 bit Green data
    input [7:0]  READ_BLUE,					        // 8 bit Blue data
    output reg [11:0] READ_ROW, 								// READ_ROW index of the image
    output reg [11:0] READ_COL, 								// column index of the image
	output reg [11:0] WRITE_WIDTH,
	output reg [11:0] WRITE_HEIGHT,
	output reg [11:0] WRITE_ROW,
	output reg [11:0] WRITE_COL,
    output reg [7:0]  WRITE_RED,					// 8 bit Red data
    output reg [7:0]  WRITE_GREEN,					// 8 bit Green data
    output reg [7:0]  WRITE_BLUE					// 8 bit Blue data
);			
//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
localparam BRIGHTNESS = 0;
localparam GRAYSCALE = 1;
localparam ROTATE = 2;

localparam		IDLE 	    = 2'b00,			// idle state
				PROCESSING	= 2'b01;			// state for data processing 
reg [1:0] cstate, 								// current state
		  nstate;								// next state			
reg start;										// start signal: trigger Finite state machine beginning to operate
reg RESET_d;									// delayed reset signal: use to create start signal
wire ctrl_done;					// Done flag

integer value, value2;							// temporary variables in invert and threshold operation
integer tempR, tempG, tempB;
reg [18:0] data_count; 							// data counting for entire pixels of the image

//----------------------------------------------------//
// ---Begin to read image file once reset was high ---//
// ---by creating a starting pulse (start)------------//
//----------------------------------------------------//
always@(posedge CLK, negedge RESET)
begin
    if(!RESET) begin
        start <= 0;
		RESET_d <= 0;
    end
    else begin											//        ______		 				
        RESET_d <= RESET;							//       |		|
		if(RESET == 1'b1 && RESET_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
			start <= 1'b1;
		else
			start <= 1'b0;
    end
end

//------------------------------------------------------------------------------------------------//
// Finite state machine for reading RGB888 data from memory                                       //
//------------------------------------------------------------------------------------------------//
always@(posedge CLK, negedge RESET)
begin
    if(~RESET) begin
        cstate <= IDLE;
    end
    else begin
        cstate <= nstate; // update next state 
    end
end

//-----------------------------------------//
//--------- State Transition --------------//
//-----------------------------------------//
always @(*) begin
	case(cstate)
		IDLE: begin
			if(start)
				nstate = PROCESSING;
			else
				nstate = IDLE;
		end				
		PROCESSING: begin
			if(ctrl_done)
				nstate = IDLE;
			else 
				nstate = PROCESSING;	
		end
	endcase
end

// counting data, column and READ_ROW index for reading memory 
always@(posedge CLK, negedge RESET)
begin
    if(~RESET) begin
		data_count <= 0;
        READ_ROW <= 0;
		READ_COL <= 0;
    end
	else begin
        data_count <= data_count + 1;
        if(READ_COL == READ_WIDTH - 1) begin
            READ_ROW <= READ_ROW + 1;
            READ_COL <= 0;
        end
        else
            READ_COL <= READ_COL + 1;
	end
end

assign ctrl_done = (data_count >= READ_WIDTH*READ_HEIGHT-1)? 1'b1: 1'b0; // done flag
//-------------------------------------------------//
//-------------  Image processing   ---------------//
//-------------------------------------------------//
always @(*)
	if(OPCODE == BRIGHTNESS) begin
		WRITE_WIDTH = READ_WIDTH;
		WRITE_HEIGHT = READ_HEIGHT;
		WRITE_ROW = READ_ROW;
		WRITE_COL = READ_COL;
		if(SIGN == 1) begin
			tempR = READ_RED + VALUE;
			WRITE_RED = tempR > 255 ? 255 : tempR;

			tempG = READ_GREEN + VALUE;
			WRITE_GREEN = tempG > 255 ? 255 : tempG;

			tempB = READ_BLUE + VALUE;
			WRITE_BLUE = tempB > 255 ? 255 : tempB;
		end
		else begin
			tempR = READ_RED - VALUE;
			WRITE_RED = tempR < 0 ? 0 : tempR;

			tempG = READ_GREEN - VALUE;
			WRITE_GREEN = tempG < 0 ? 0 : tempG;

			tempB = READ_BLUE - VALUE;
			WRITE_BLUE = tempB < 0 ? 0 : tempB;
		end
	end
	else if(OPCODE == GRAYSCALE) begin
		WRITE_WIDTH <= READ_WIDTH;
		WRITE_HEIGHT <= READ_HEIGHT;
		WRITE_ROW <= READ_ROW;
		WRITE_COL <= READ_COL;
		value2 <= (READ_RED + READ_GREEN + READ_BLUE) / 3;
		WRITE_RED <= value2;
		WRITE_GREEN <= value2;
		WRITE_BLUE <= value2;
	end
	else if(OPCODE == ROTATE) begin
		WRITE_WIDTH <= READ_HEIGHT;
		WRITE_HEIGHT <= READ_WIDTH;
		WRITE_ROW <= READ_COL;
		WRITE_COL <= READ_HEIGHT - READ_ROW;
		WRITE_RED <= READ_RED;
		WRITE_GREEN <= READ_GREEN;
		WRITE_BLUE <= READ_BLUE;	
	end
endmodule
