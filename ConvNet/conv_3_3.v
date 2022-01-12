`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:24:15 12/06/2021 
// Design Name: 
// Module Name:    conv 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module conv_3_3
(
    CLK,
	 rst_n,
	 PATCH,
	 KERNEL,
	 RESULT
    );
    input CLK;
    input rst_n;
    input  wire [9*16-1:0] PATCH;
    input  wire [9*16-1:0] KERNEL;
    output wire [15:0] RESULT;

    reg [15:0] reg_output;
    assign RESULT = reg_output;

    reg [15:0] PIXELS [8:0];
    reg [15:0] KERNEL_WEIGHT [8:0];
    reg [15:0] TEMP_RES [8:0];
	 always @(*) begin 
	     {PIXELS[0],PIXELS[1],PIXELS[2],PIXELS[3],PIXELS[4],PIXELS[5],PIXELS[6],PIXELS[7],PIXELS[8]}<=PATCH;
	     {KERNEL_WEIGHT[0],KERNEL_WEIGHT[1],KERNEL_WEIGHT[2],KERNEL_WEIGHT[3],KERNEL_WEIGHT[4],KERNEL_WEIGHT[5],KERNEL_WEIGHT[6],KERNEL_WEIGHT[7],KERNEL_WEIGHT[8]}<=KERNEL;
	 end
	 
	 always @(*) begin 
	     TEMP_RES[0] = PIXELS[0]*KERNEL_WEIGHT[0];
	     TEMP_RES[1] = PIXELS[1]*KERNEL_WEIGHT[1];
	     TEMP_RES[2] = PIXELS[2]*KERNEL_WEIGHT[2];
	     TEMP_RES[3] = PIXELS[3]*KERNEL_WEIGHT[3];
	     TEMP_RES[4] = PIXELS[4]*KERNEL_WEIGHT[4];
	     TEMP_RES[5] = PIXELS[5]*KERNEL_WEIGHT[5];
	     TEMP_RES[6] = PIXELS[6]*KERNEL_WEIGHT[6];
	     TEMP_RES[7] = PIXELS[7]*KERNEL_WEIGHT[7];
	     TEMP_RES[8] = PIXELS[8]*KERNEL_WEIGHT[8];
	 end
	 integer i;
	 always @(*) begin 
        reg_output = 0;
        for(i=0; i < 9; i=i+1)
            reg_output = reg_output + TEMP_RES[i];
	 end

endmodule
