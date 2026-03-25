`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.02.2026 23:59:01
// Design Name: 
// Module Name: imageControl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module imageControl(
input i_clk,
input i_rst,
input [7:0] i_pixel_data,
input i_pixel_data_valid,
output reg [71:0] o_pixel_data,
output o_pixel_data_valid,
output reg o_intr
);

// Steps followedWhile designing :
//1. The writing logic blocks(counter -> currentbuffer ->buffdatavalid).
//2. The reading logic blocks (counter -> Currentbuffer -> o_pixel_data -> linebuffrddata) 
//3. TotalpixelCounter and final FSM with IDLE and RD_BUFFER state.

reg [8:0] pixelCounter;// Counts For writing only
reg [1:0] currentWrLineBuffer;// As 3 line buffers are used max 2'b11
reg [3:0] lineBuffDataValid;

reg [1:0] currentRdLineBuffer;
reg [8:0] rd_Counter;
reg [3:0] lineBuffRdData;
reg rd_line_buffer;

wire [23:0] lb0data,lb1data,lb2data,lb3data;

reg [11:0] totalPixelCounter;// For worst case we'll have 512*4 = 2048(2KB) pixels to count , that'll need 12 bits
reg rdState;

localparam IDLE = 'b0,
           RD_BUFFER = 'b1;

assign o_pixel_data_valid = rd_line_buffer;

// Case1: If a new pixel comes from external world(ie. we're writing) we'll have to increment the totalpixelcounter
// Case2: if we are reading from the linebuffer we'll have to decrement the totalpixelcounter
/*Case3: (Not needed to code)when reading and writing are happening parallely , we'll not change
value of totalpixelcounter because increment and decrement cancel out each other.*/

always @(posedge i_clk)
begin
    if(i_rst)
        totalPixelCounter <=0;
    else
    begin
        if(i_pixel_data_valid & !rd_line_buffer)
            totalPixelCounter <= totalPixelCounter + 1; //Case1 (Details above)
        else if(!i_pixel_data_valid & rd_line_buffer)
            totalPixelCounter <= totalPixelCounter - 1;  //Case2 (Details above)
    end
end

// we must first write data in the first 3 line buffers then we can read and write parallely
// Thus we must have atleast 512*3 = 1536 pixels stored in order to start reading 
// For this we'll model one small state machine

always @(posedge i_clk)
begin
    if(i_rst)
    begin
        rdState <= IDLE;
         rd_line_buffer <= 1'b0;
         o_intr <= 1'b0;
    end
    else
    begin
        case(rdState)
        IDLE:begin
            o_intr <= 1'b0;
            if(totalPixelCounter >= 1536) // we have atleast 3 line buffers written
            begin
                 rd_line_buffer <= 1'b1;  // three lineBuffrdData will get high,ie o/p will start reading from them
                 rdState <= RD_BUFFER;
            end
            end
       RD_BUFFER:begin
            if(rd_Counter == 511) // When we are ending reading one line buffer(at 512th pixel), we'll go back to IDLE state,
            begin                 //if there's enough data (1536 pixels) ready , it'll get back to RD_BUFFER as coded above 
                rdState <= IDLE;
                rd_line_buffer <= 1'b0;
                o_intr <= 1'b1;
            end
            end
        endcase
    end
end

// That is (refrence: imageControl.v) in RD_BUFFER state when the rdCounter becomes 511 and in the next clock
// it's indicating we have finished reading from a line buffer
// Once we have finished reading a line buffer means we have a free line buffer available

/* As we're dealing with 512 bits of data we're having 
(log512 base2) 9 bit counter (pixelCounter). The aim is that whenever the counter overflows 
ie. from 511 to 512 , we need to switch to next line buffer
to which data should go.
*/
always @(posedge i_clk)
begin
     if(i_rst)
        pixelCounter <=0;
      else
      begin
      if(i_pixel_data_valid)
      pixelCounter <= pixelCounter + 1;
      end

end

/*We'll choose a register which decides to which
line buffer incoming data should go.
*/
 
always @(posedge i_clk)
begin
     if(i_rst)
          currentWrLineBuffer <=0;
     else
     begin
         if(pixelCounter == 511 & i_pixel_data_valid) // If we are at the 511th pixel of one line buffer and next coming data is valid , we move to the next line buffer
            currentWrLineBuffer <= currentWrLineBuffer + 1;
     end
//As currentWrLineBuffer is 2bit , after 3 line buffers(2'b11) it'll become 0 automatically
end 
 
/*whichever is the current line buffer it's data valid 
should be same as the main i_pixel_data_valid and all other line buffer data valid
should remain 0 so that if any new data comes it goes to the current line buffer
*/

 always @(*)
 begin
     lineBuffDataValid = 4'h0; // Initailly all (lineBuffDataValid[0] to lineBuffDataValid[3] will be zero
     lineBuffDataValid[currentWrLineBuffer] = i_pixel_data_valid; // Then only the lineBuffer which is currently being written on will take the i_pixel_data_valid
end // MUX

// Similiarly we'll have a rdCounter with (log512 base2) 9 bit value to count where we are reading

always @(posedge i_clk)
begin
    if(i_rst)
    rd_Counter <=0;
    else
    begin
    if(rd_line_buffer)          
    rd_Counter <= rd_Counter + 1;
    end
end


// Similarly for deciding from which line buffer we are reading we have the currentRdLineBuffer

always @(posedge i_clk)
begin
    if(i_rst)
    currentRdLineBuffer <=0;
    
    else
    begin
    if(rd_Counter == 511 & rd_line_buffer)
    currentRdLineBuffer <= currentRdLineBuffer +1;
    end
end

/* Similarily we can have the read logic
what will be prefetched for reading acxording to value of currentRdLineBuffer  
*/

always @(*)
begin
case(currentRdLineBuffer)
0: o_pixel_data = {lb2data,lb1data,lb0data} ;//o_pixel_data of control block will be going to i_pixel_data of conv
1: o_pixel_data = {lb3data,lb2data,lb1data} ;// 210 -> 321 -> 032 -> 103, so that we cover all the lines -
2: o_pixel_data = {lb0data,lb3data,lb2data} ;// - for convolution.
3: o_pixel_data = {lb1data,lb0data,lb3data} ;  
endcase
end

 // Note to Remember:
 // 1. While reading we'll be reading data from 3 line buffers at a time.
 // 2. While writing we'll be writting data to one line buffer at a time.
 
 // As soon as we finish reading from 3 we must switch to the next three
 // that's why we model using combinational always block
 
 always @(*)
 begin
      lineBuffRdData = 4'b0000; 
      case(currentRdLineBuffer)// Same as above 210 -> 321 -> 032 -> 103
      0:begin
            lineBuffRdData[0] = rd_line_buffer;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = 1'b0;
        end
      1:begin
            lineBuffRdData[0] = 1'b0;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = rd_line_buffer;
        end
      2:begin
            lineBuffRdData[0] = rd_line_buffer;
            lineBuffRdData[1] = 1'b0;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = rd_line_buffer;
        end  
      3:begin
            lineBuffRdData[0] = rd_line_buffer;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = 1'b0;
            lineBuffRdData[3] = rd_line_buffer;
        end 
      endcase
end

 
 /*For performance improvement we'll be using 4 line buffers 
here, one time we'll be doing convolutionon 3 of them
 and parallely we'll be filling data in 4th one
 */
lineBuffer lB0 (
 .i_clk(i_clk),
 .i_rst(i_rst),
 .i_data(i_pixel_data),
 .i_data_valid(lineBuffDataValid[0]),
 .o_data(lb0data),
 .i_rd_data(lineBuffRdData[0])
); 

lineBuffer lB1 (
 .i_clk(i_clk),
 .i_rst(i_rst),
 .i_data(i_pixel_data),
 .i_data_valid(lineBuffDataValid[1]),
 .o_data(lb1data),
 .i_rd_data(lineBuffRdData[1])
); 

lineBuffer lB2 (
 .i_clk(i_clk),
 .i_rst(i_rst),
 .i_data(i_pixel_data),
 .i_data_valid(lineBuffDataValid[2]),
 .o_data(lb2data),
 .i_rd_data(lineBuffRdData[2])
);  
 
lineBuffer lB3 (
 .i_clk(i_clk),
 .i_rst(i_rst),
 .i_data(i_pixel_data),
 .i_data_valid(lineBuffDataValid[3]),
 .o_data(lb3data),
 .i_rd_data(lineBuffRdData[3])
); 
 
endmodule
