`timescale 1ns / 1ps
`define  DELAY            25'd24

module maxpool_tb;
    localparam PERIOD = 8;
    reg [24 :0] counter = 0;

	// Inputs
	reg CLK;
	reg rst_n;
	reg [16*4-1:0] PATCH;

	// Outputs
	wire [15:0] RESULT;

	// Instantiate the Unit Under Test (UUT)
	maxpool uut (
		.CLK(CLK), 
		.rst_n(rst_n), 
		.PATCH(PATCH), 
		.RESULT(RESULT)
	);

	initial begin
		// Initialize Inputs
		CLK = 0;
		rst_n = 1'b1;
        PATCH = {16'd0,16'd1,16'd2,16'd3};
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
                PATCH[15:0] <= PATCH[63:48]+16'd10;
                PATCH[31:16] <= PATCH[15:0]+16'd10;
                PATCH[47:32] <= PATCH[31:16]+16'd10;
                PATCH[63:48] <= PATCH[47:32]+16'd10;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
      
endmodule

