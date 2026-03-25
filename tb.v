`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2026 02:44:12
// Design Name: 
// Module Name: tb
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
`define headerSize 1080
`define imageSize 512*512

module tb(

    );

reg clk;
reg reset;
reg [7:0] imgData;
integer file,file1,i;
reg imgDataValid;
integer sentSize;// As I don't know it's size i'll make it integer(32bit)
wire intr;
wire [7:0] outData;
wire outDataValid;
integer receivedData=0;


initial
    begin
    clk = 1'b0;
    forever
    begin
    #5 clk = ~clk;
    end
end
    
  initial 
  begin
      reset =0;
      sentSize = 0;
      imgDataValid =0;//At the beggining imagedatavalid is zero so that the header data doesn;t go to our IP
      #100;
      reset =1;// Xilinx IP Core expect a reset with atleast 100 ns duration, also it's followed by real world FPGA
      #100;
      file = $fopen("lena_gray.bmp","rb"); // rb means to read in binary form
      file1 = $fopen("blurred_lena.bmp","wb");// The processesd image o/p file
      // The initial header part of the file we need not to send to our image processing IP
      // The header part remains same in the input image as well as the output image
      // As it contains the information like what is the file size , what is the resolution etc.
      for(i=0;i<`headerSize;i=i+1)
      begin
            $fscanf(file,"%c",imgData);
           //Read one byte data at a time.
           $fwrite(file1,"%c",imgData);
      end
      
      // Now we are going to read four lines as we have 4 line buffers only.
      // Now we'll send the fifth line when the IP is reasy to accept the next line
      for(i=0;i<4*512;i=i+1)// 4 lines , so 4*512 pixels
      begin
          @(posedge clk);
          $fscanf(file,"%c",imgData);
          imgDataValid <= 1'b1;
      end
      sentSize = 4*512;
      @(posedge clk);
      imgDataValid <= 1'b0; //Now we'll wait till the interrupt(until there is a free line available)
      while(sentSize < `imageSize) // sentSize -> I have some variable which tells me how much data I have send till now
      begin
         @(posedge intr);//Afeterr I recieve interrupt i will read next line of data
         for(i=0;i<512;i=i+1)
         begin
             @(posedge clk);
             $fscanf(file,"%c",imgData);
             imgDataValid <= 1'b1;
         end 
         @(posedge clk);
         imgDataValid <= 1'b0; 
         sentSize = sentSize+512;
      end  
      //By the time we come out of this loop we have sent alll the image data to our ip
      
      //As we are doing convolution , there will be an issue of dimensionality reduction ,
      //In our case we'll face this issue rowwise. 2 rows , one upmost and one downmost will be lost]
      //To balance this we send 2 dummy lines in the end, there would be some slight shifting 
      // in the image due to this but without those dummy lines , the output image size will be less than the input image size
          
        
      @(posedge clk);
      imgDataValid <= 1'b0; 
      @(posedge intr); // we'll wait for intr
       for(i=0;i<512;i=i+1)
       begin
            @(posedge clk);
            imgData <=0 ; // As it's a dummy line
            imgDataValid <= 1'b1;
       end 
       @(posedge clk);
       imgDataValid <= 1'b0;
      @(posedge intr); // we'll wait for intr
       for(i=0;i<512;i=i+1)
       begin
            @(posedge clk);
            imgData <=0 ; // As it's a dummy line
            imgDataValid <= 1'b1;
       end 
       @(posedge clk);
       imgDataValid <= 1'b0;
       $fclose(file);
  end 
  
  //Now we need to write the logic which accepts data from the IP and write it to the output file 
 // header we have already returned , now we need to write the pixel part of it
 
 always @(posedge clk)
 begin
     if(outDataValid)
     begin
     $fwrite(file1,"%c",outData);  //whenever we are getting a valid data we are writing it to our output 
     receivedData = receivedData +1;
     end
     if(receivedData == `imageSize)
     begin
     $fclose(file1);
     $stop;
     end
 end 
  
imageProcessTop dut(
    .axi_clk(clk),
    .axi_reset_n(reset),
    //slave interface :  THe interface through which data will be coming from the DMA Controller
    .i_data_valid(imgDataValid),
    .i_data(imgData),
    .o_data_ready(),//This rdy signal we are giving to the DMA controller when we're accepting data from the dma controller
    //master inteface
    .o_data_valid(outDataValid), // Whether data coming as output is valid or not.
    .o_data(outData),
    .i_data_ready(1'b1), //This rdy signal is coming from the DMA controller when we're sending data
                        // Here we want our IP to be always ready to accept data, so its 1
    //interrupt
    .o_intr(intr)
        );    
    
    
    
    
endmodule
