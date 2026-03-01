`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 09:25:11
// Design Name: 
// Module Name: lineBuffer
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

/*
It first takes input of all the 8bit data from us and stores it in the line
corresponding to wrpointer location and reads and outputs as bunch 
of 3 of 8bit as per the rdpointer
Whenever reset is applied both the write and readpointer are made 0
else they're continously incremented by one.
*/

module lineBuffer(
//Similiar to AXI
input i_clk,
input i_rst,
input [7:0] i_data,// Input data is of 8 bits array at a time.
input i_data_valid,//When i_data_valid is high data from input is stored in line
output [23:0] o_data,
//In verilog we can't have 2d arrays in input output port
input i_rd_data //When i_rd_data is high, data from line is stored in output
);

reg [7:0] line [511:0];//line buffer , 512 locations ,Each stores 8-bit pixel data
reg [8:0] wrPntr;//Tells in which memory location the new data needs to be stored, log512base2 = 9 
reg [8:0] rdPntr;

always @(posedge i_clk)
begin
if(i_data_valid)
   line[wrPntr] <= i_data;/* The 8bit input data is written to one of the memory
                             locations of line (this location is told by wrPntr).*/
end

//Better to divide in multiple always blocks so that code is more maintainable
always @(posedge i_clk)
begin
    if(i_rst)
        wrPntr <='d0; //(decimal zero)
    else if(i_data_valid)
        wrPntr <= wrPntr + 'd1; // decimal 1 , next data will be stored in next position
        // Thus all the locations of line will be filled with input data.
end

assign o_data = {line[rdPntr],line[rdPntr+1],line[rdPntr+2]}; //Prefetching to avoid latency 

// We are taking 3 lines (each of 8bit) as the output.

always @(posedge i_clk)
begin
if(i_rst)
   rdPntr <= 'd0;
else if(i_rd_data)
   rdPntr <= rdPntr + 'd1;

end

endmodule
