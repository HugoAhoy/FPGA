`timescale 1ns/1ps
`timescale 1ns / 1ps

module usb_tb;
    localparam PERIOD = 8;
    reg [24:0] counter;

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
    wire [2:0] cState;
    wire [15:0] WCount;
    wire [15:0] RCount;

	// Bidirs
	wire [15:0] FDATA;

    reg [15:0] pseudoData;
	// Instantiate the Unit Under Test (UUT)
	usb uut (
		.CLKOUT(CLKOUT), 
		.rst_n(rst_n), 
		.FLAGD(FLAGD), 
		.FLAGA(FLAGA), 
		.SLWR(SLWR), 
		.SLRD(SLRD), 
		.SLOE(SLOE), 
		.IFCLK(IFCLK), 
		.FIFOADR(FIFOADR), 
		.FDATA(FDATA),
        .cState(cState),
        .WCount(WCount),
        .RCount(RCount)
	);

	initial begin
		// Initialize Inputs
		CLKOUT = 0;
		rst_n = 1'b1;
		FLAGD = 1;
		FLAGA = 1;
        counter = 0;
        pseudoData = 0;

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
        counter <= counter + 1;
    end

    // always begin
    //     FLAGD <= 1'b1;
    //     FLAGA <= 1'b0;
    //     #(PERIOD * 2);

    //     FLAGD <= 1'b0;
    //     FLAGA <= 1'b1;
    //     #(PERIOD * 10);
    // end

    // 模拟FLAGA
    always @(posedge IFCLK) begin
        case(counter)
            25'd3:begin
                FLAGA <= 1'b0;
            end
            25'd10:begin
                FLAGA <= 1'b1;
            end
            25'd15:begin
                FLAGA <= 1'b0;
            end
            25'd30:begin
                FLAGA <= 1'b1;
            end
            default:begin
                FLAGA <= FLAGA;
            end
        endcase
    end

    // 模拟FLAGD
    always @(posedge IFCLK) begin
        case(counter)
            25'd25:begin
                FLAGD <= 1'b0;
            end
            25'd29:begin
                FLAGD <= 1'b1;
            end
            25'd34:begin
                FLAGD <= 1'b0;
            end
            25'd40:begin
                FLAGD <= 1'b1;
            end
            default:begin
                FLAGD <= FLAGD;
            end
        endcase
    end

    // 模拟数据被读了一次，然后送出下一个数据
    always @(posedge IFCLK) begin
        if(FLAGA == 1'b1 & SLRD == 1'b0)begin
            pseudoData = pseudoData + 1;
        end
        else begin
            pseudoData = pseudoData;
        end
    end

    assign FDATA =(FIFOADR == 2'b00)? pseudoData:16'hzzzz;

endmodule

