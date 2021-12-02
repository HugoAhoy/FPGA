`timescale 1ns / 1ps

module fpga_tb;
localparam PERIOD = 8;


// Inputs
reg CLOCK_48;
reg flagd;
reg flaga;

// Outputs
wire [3:0] LED;
wire slwr;
wire slrd;
wire sloe;
wire ifclk;
wire [1:0] fifoadr;
wire [15:0] fd;

// Instantiate the Unit Under Test (UUT)
usb_wrtie uut (
	.CLKOUT(CLOCK_48), 
	.rst_n(1'b1),
    .FLAGD(flagd),
    .FLAGA(flaga),
    .SLWR(slwr),
    .SLRD(slrd),
    .SLOE(sloe),
    .IFCLK(ifclk),
    .FIFOADR(fifoadr),
    .FD(fd)
);

initial begin
	// Initialize Inputs
	CLOCK_48 = 0;
	// Wait 100 ns for global reset to finish
	#100;
        
	// Add stimulus here
end

always begin
   CLOCK_48 = 1'b0;
   #(PERIOD / 2);
   CLOCK_48 = 1'b1;
   #(PERIOD / 2);
end

always begin
    flagd <= 1'b1;
    flaga <= 1'b0;
    #(PERIOD * 2);

    flagd <= 1'b0;
    flaga <= 1'b1;
    #(PERIOD * 10);
end
      
endmodule

