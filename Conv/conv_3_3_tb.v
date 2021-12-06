`timescale 1ns / 1ps
`define  DELAY            25'd24000000

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:41:58 12/06/2021
// Design Name:   conv
// Module Name:   D:/GitRepository/FPGA/Conv/conv_tb.v
// Project Name:  Conv
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: conv
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module conv_3_3_tb;
    localparam PERIOD = 8;
    reg [24 :0] counter = 0;

	// Inputs
	reg CLK;
	reg rst_n;
	reg [143:0] PATCH;
	reg [143:0] KERNEL;

	// Outputs
	wire [63:0] RESULT;

	// Instantiate the Unit Under Test (UUT)
	conv_3_3 uut (
		.CLK(CLK), 
		.rst_n(rst_n), 
		.PATCH(PATCH), 
		.KERNEL(KERNEL), 
		.RESULT(RESULT)
	);
    /*iverilog */
    initial
    begin            
        $dumpfile("wave.vcd");        //生成的vcd文件名称
        $dumpvars(0, conv_3_3_tb);     //tb模块名称
    end
    /*iverilog */

	initial begin
		// Initialize Inputs
		CLK = 0;
		rst_n = 1'b1;
      PATCH = {16'd0,16'd1,16'd2,16'd3,16'd4,16'd5,16'd6,16'd7,16'd8};
      KERNEL = {16'd9,16'd10,16'd11,16'd12,16'd13,16'd14,16'd15,16'd16,16'd17};

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end

    always begin
        CLK = 1'b0;
        #(PERIOD / 2);
        CLK = 1'b1;
        #(PERIOD / 2);
    end

    always @(posedge CLK) begin
        if (counter == `DELAY) begin
                counter <= 0;
                PATCH[15:0] <= PATCH[15:0]+16'd1;
                PATCH[31:16] <= PATCH[31:16]+16'd1;
                PATCH[47:32] <= PATCH[47:32]+16'd1;
                PATCH[63:48] <= PATCH[63:48]+16'd1;
                PATCH[79:64] <= PATCH[79:64]+16'd1;
                PATCH[95:80] <= PATCH[95:80]+16'd1;
                PATCH[111:96] <= PATCH[111:96]+16'd1;
                PATCH[127:112] <= PATCH[127:112]+16'd1;
                PATCH[143:128] <= PATCH[143:128]+16'd1;
        end
        else begin
            counter <= counter + 1'b1;
        end        
    end
      
endmodule

