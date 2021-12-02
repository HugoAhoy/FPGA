`timescale 1ns / 1ps

module usb_write_tb;
    localparam PERIOD = 8;

	// Inputs
	reg CLKOUT;
	reg rst_n;
	reg FLAGD;
	reg FLAGA;

	// Outputs
	wire SLWR;
	wire SLRD;
	wire SLOE;
	wire IFCLK;
	wire [1:0] FIFOADR;

	// Bidirs
	wire [15:0] FDATA;

	// Instantiate the Unit Under Test (UUT)
	usb_write uut (
		.CLKOUT(CLKOUT), 
		.rst_n(rst_n), 
		.FLAGD(FLAGD), 
		.FLAGA(FLAGA), 
		.SLWR(SLWR), 
		.SLRD(SLRD), 
		.SLOE(SLOE), 
		.IFCLK(IFCLK), 
		.FIFOADR(FIFOADR), 
		.FDATA(FDATA)
	);

	initial begin
		// Initialize Inputs
		CLKOUT = 0;
		rst_n = 1'b1;
		FLAGD = 0;
		FLAGA = 0;

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

    always begin
        FLAGD <= 1'b1;
        FLAGA <= 1'b0;
        #(PERIOD * 2);

        FLAGD <= 1'b0;
        FLAGA <= 1'b1;
        #(PERIOD * 10);
    end
      
endmodule

