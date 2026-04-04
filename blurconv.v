`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2026 23:44:00
// Design Name: 
// Module Name: conv
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

// Blur convolution operation for learning purpose
module conv(
input i_clk,
input [71:0] i_pixel_data,//72 pixel,3 line buffer of 24 bits each as inputs
input i_pixel_data_valid,
output reg [7:0] o_convolved_data,
output reg o_convolved_data_valid
    );

integer i;   
reg [7:0] kernel[8:0]; //8 kernels of 9 each
reg [15:0] multData [8:0]; /* We're multiplying an 8 bit thing with another
                             8 bit so theoretically it'll be 16 bit*/
reg [15:0] sumDataInt;
reg [15:0] sumData;
reg multDataValid;
reg sumDataValid;
reg convolved_data_valid;

initial 
begin
    for(i=0;i<9;i=i+1)
    begin
       kernel[i] = 1;
       end 
end

always @(posedge i_clk)
begin
   for(i=0;i<9;i=i+1)
   begin
   multData[i] = kernel[i]*i_pixel_data[i*8+:8]; // We're doing multiplication here
   end 
   multDataValid <= i_pixel_data_valid;
end

always @(*)
begin
   sumDataInt = 0;
   for(i=0;i<9;i=i+1)
   begin
     sumDataInt = sumDataInt + multData[i]; 
     end
end

always @(posedge i_clk)
begin
   sumData <= sumDataInt;
   sumDataValid <= multDataValid;
end

always @(posedge i_clk)
begin
    o_convolved_data <= sumData/9;
    o_convolved_data_valid <= sumDataValid;
end

endmodule
