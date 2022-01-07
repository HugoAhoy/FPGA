`timescale 1ns / 1ps
`define  DELAY            25'd24

module maxpool_tb;
    localparam PERIOD = 8;
    reg [24 :0] counter = 0;

	// Inputs
	reg CLK;
	reg rst_n;
	reg [64*4-1:0] PATCH;

	// Outputs
	wire [63:0] RESULT;

	// Instantiate the Unit Under Test (UUT)
	maxpool uut (
		.CLK(CLK), 
		.rst_n(rst_n), 
		.PATCH(PATCH), 
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
        PATCH = {64'd0,64'd1,64'd2,64'd3};
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
                PATCH[63:0] <= PATCH[255:192]+64'd10;
                PATCH[127:64] <= PATCH[63:0]+64'd10;
                PATCH[191:128] <= PATCH[127:64]+64'd10;
                PATCH[255:192] <= PATCH[191:128]+64'd10;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
      
endmodule

