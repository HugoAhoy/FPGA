`timescale 1ns / 1ps

module read_to_sdram_tb;
    localparam PERIOD = 8;

	// Inputs
	reg CLKOUT;
	reg rst_n;
	reg FLAGA;

    // sdram wishbone inputs
    reg [31:0] data_o;
    reg stall_o;
    reg sdram_ack;

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
    reg [15:0] data_cnt = 0;

    assign FDATA = (FLAGA == 1'b1) ? data_cnt:16'hz;

    // pseudo sdram start
    reg [1:0] sdram_cnt = 2'd0;
    reg [31:0] sdram [119:0]; // pseudo sdram的存储空间
    localparam S_WAIT = 4'b0000;
    localparam S_CYC = 4'b0001;
    localparam S_STB = 4'b0010;
    localparam S_ACK = 4'b0011;

    reg [3:0] s_current = S_WAIT;

    // 状态转移
    always @(posedge CLK) begin
        case (s_current)
            S_WAIT:begin
                if(cyc_i == 1'b1)begin
                    s_current <= S_CYC;
                end
                else begin
                    s_current <= S_WAIT;
                end
            end
            S_CYC:begin
                if(cyc_i == 1'b1)begin
                    if (stb_i == 1'b1)begin
                        s_current <= S_STB;
                    end
                    else begin
                        s_current <= S_CYC;
                    end
                end
                else begin // 如果cyc没有持续有效，则总线无效
                    s_current <= S_WAIT;
                end
            end
            S_STB:begin
                if(cyc_i == 1'b1)begin
                    if(sdram_cnt == 2'd3)begin
                        s_current <= S_ACK;
                        sdram_cnt <= 2'd0;
                    end
                    else begin
                        sdram_cnt <= sdram_cnt + 2'd1;
                    end
                end
                else begin // 如果cyc没有持续有效，则总线无效
                    s_current <= S_WAIT;
                end
            end
            S_ACK:begin
                if(cyc_i == 1'b1)begin
                    s_current <= S_ACK;
                end
                else begin // 如果cyc没有持续有效，则总线无效
                    s_current <= S_WAIT;
                end
            end
            default: 
                s_current <= S_WAIT;
        endcase
    end

    always @(posedge CLK) begin
        if((we_i == 1'b1)&&(sdram_cnt == 2'd3)) begin
            sdram[addr_i[6:0]] <= data_i;
        end
    end

    // sdram 输出信号
    always @(*) begin
        case (s_current)
            S_STB:begin
                data_o = 32'hz;
                sdram_ack = 1'b0;
                stall_o = 1'b0;
            end 
            S_ACK:begin
                if(we_i == 1'b0)begin
                    data_o = sdram[addr_i[6:0]];
                end
                sdram_ack = 1'b1;
                stall_o = 1'b0;
            end
            default: begin
                data_o = 32'hz;
                sdram_ack = 1'b0;
                stall_o = 1'b0;
            end
        endcase
    end

    // pseudo sdram end

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

    always @(posedge IFCLK) begin
        if (SLRD == 1'b0)begin
		      data_cnt <= data_cnt + 16'd1;
		  end
    end
	 
    always @(posedge IFCLK) begin
        cnt <= cnt + 16'd1;
    end
	 
    always @(*) begin
        if(cnt < 3)begin
            FLAGA = 1'b0;
        end
        else begin
            FLAGA = 1'b1;
        end        
    end
      
endmodule

