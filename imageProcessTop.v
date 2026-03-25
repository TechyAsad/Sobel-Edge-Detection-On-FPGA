`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.03.2026 23:29:13
// Design Name: 
// Module Name: imageProcessTop
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


module imageProcessTop(
input axi_clk,
input axi_reset_n,
//slave interface :  THe interface through which data will be coming from the DMA Controller
input i_data_valid,
input [7:0] i_data,
output o_data_ready,//This rdy signal we are giving to the DMA controller when we're accepting data from the dma controller
//master inteface
output o_data_valid,
output [7:0] o_data,
input  i_data_ready, //This rdy signal is coming from the DMA controller when we're sending data
//interrupt
output o_intr
    );
    
//We only have 4 line buffer inside our IP and once we finish processing one of tbe
//line buffers we will send an interrupt to the processor saying okay
//I have a free line buffer you can send the next line of data 
// So the interrupt signal should become high only when we have a free line buffer inside our IP   
    
// That is (refrence: imageControl.v) in RD_BUFFER state when the rdCounter becomes 511 and in the next clock
// it's indicating we have finished reading from a line buffer
// Once we have finished reading a line buffer means we have a free line buffer available

wire [71:0] pixel_data;    
wire pixel_data_valid;
wire [7:0] convolved_data;
wire convolved_data_valid;
wire axis_prog_full;// This will become high when it's full

assign o_data_ready = !axis_prog_full;
    
imageControl IC(
     .i_clk(axi_clk),
     .i_rst(!axi_reset_n),// AXI uses active low reset while we have designed the circuit on active high reset
     .i_pixel_data(i_data),
     .i_pixel_data_valid(i_data_valid),
     .o_pixel_data(pixel_data),
     .o_pixel_data_valid(pixel_data_valid),
     .o_intr(o_intr)
    );    

//Outputs from image control will be going into convolution module

conv  conv(
.i_clk(axi_clk),
.i_pixel_data(pixel_data),//72 pixel,3 line buffer of 24 bits each as inputs
.i_pixel_data_valid(pixel_data_valid),
.o_convolved_data(convolved_data),
.o_convolved_data_valid(convolved_data_valid)
    );   
 
// We'll add a FIFO to  the output to manage the mismatch between these input and output i_data_ready & o_data_ready rgrding AXI DMA controller
  
 outputBuffer OB(
  .wr_rst_busy(),        // output wire wr_rst_busy
  .rd_rst_busy(),        // output wire rd_rst_busy
  .s_aclk(axi_clk),                  // input wire s_aclk
  .s_aresetn(axi_reset_n),            // input wire s_aresetn
  .s_axis_tvalid(convolved_data_valid),    // input wire s_axis_tvalid
  .s_axis_tready(),    // output wire s_axis_tready , in our logic , there won't be any case in case for which the FIFO won't be ready
  .s_axis_tdata(convolved_data),      // input wire [7 : 0] s_axis_tdata
  .m_axis_tvalid(o_data_valid),    // output wire m_axis_tvalid
  .m_axis_tready(i_data_ready),    // input wire m_axis_tready
  .m_axis_tdata(o_data),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
); 
// s- slave 
// m - master  



endmodule
