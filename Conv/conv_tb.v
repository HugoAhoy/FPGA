`timescale 1ns/1ps
`define  DELAY            25'd24000000

module conv_tb;    
    localparam PERIOD = 8;
    reg [24 :0] counter = 0;

	// Inputs
	reg CLKOUT;
    
	reg rst_n;
    reg [3*3*16-1:0] PATCH;
    reg [3*3*16-1:0] KERNEL_WEIGHT;

    wire [63:0] RESULT;

    conv uut (
        .CLK(CLKOUT),
        .rst_n(rst_n),
        .PATCH(PATCH),
        .KERNEL(KERNEL_WEIGHT),
        .RESULT()
    );
    
    initial begin
		CLKOUT = 0;
		rst_n = 1'b1;
        PATCH = {16'd0,16'd1,16'd2,16'd3,16'd4,16'd5,16'd6,16'd7,16'd8};
        KERNEL_WEIGHT = {16'd9,16'd10,16'd11,16'd12,16'd13,16'd14,16'd15,16'd16,16'd17};

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
    end

    always begin
        CLKOUT = 1'b0;
        #(PERIOD / 2);
        CLKOUT = 1'b1;
        #(PERIOD / 2);
    end
    integer i;
    always @(posedge CLKOUT) begin
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