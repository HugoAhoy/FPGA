`timescale 1ns / 1ps

module read_to_sdram_tb;
    localparam PERIOD = 8;

	// Inputs
	reg CLKOUT;
	reg rst_n;
	reg FLAGA;

    // sdram wishbone inputs
    reg [31:0] data_o;
    reg [31:0] stall_o;
    reg [31:0] sdram_ack;

	// Outputs
	wire SLWR;
	wire SLRD;
	wire SLOE;
	wire IFCLK;
	wire [1:0] FIFOADR;
	wire [3:0] LED; 
	wire [2:0] cstate;
    wire read_ack;

    // sdram wishbone outputs
    wire stb_i;
    wire we_i;
    wire [3:0] sel_i;
    wire cyc_i;
    wire [31:0] addr_i;
    wire [31:0] data_i;

	// Bidirs
	wire [15:0] FDATA;

    reg [15:0] cnt = 0;
    assign FDATA = (FLAGA == 1'b1) ? cnt:16'hz;

	// Instantiate the Unit Under Test (UUT)
	read_to_sdram uut (
		.CLKOUT(CLKOUT), 
		.rst_n(rst_n), 
		.FLAGA(FLAGA), 
		.SLWR(SLWR), 
		.SLRD(SLRD), 
		.SLOE(SLOE), 
		.IFCLK(IFCLK), 
		.LED(LED), 
		.cstate(cstate), 
		.FIFOADR(FIFOADR), 
		.FDATA(FDATA),
        .read_ack(read_ack),
        .data_o(data_o),
        .stall_o(stall_o),
        .sdram_ack(sdram_ack),
        .stb_i(stb_i),
        .we_i(we_i),
        .sel_i(sel_i),
        .cyc_i(cyc_i),
        .addr_i(addr_i),
        .data_i(data_i)
	);

	initial begin
		// Initialize Inputs
		CLKOUT = 0;
		rst_n = 1'b1;
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

    always @(posedge CLKOUT) begin
        cnt <= cnt + 16'd1;
    end
    always @(*) begin
        if(FDATA < 3)begin
            FLAGA = 1'b0;
        end
        else begin
            FLAGA = 1'b1;
        end        
    end
      
endmodule

