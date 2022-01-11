`timescale 1ns / 1ps

module convnet(
        input                   CLK,
        input                   rst_n,
        input                   FLAGA,
        input                   FLAGD,
        output wire [1:0]       FIFOADR,
        output wire [3:0]       LED,				    //	LED [3:0]
        output wire             pktend,
        output                  SLWR,
        output                  SLRD,
        output                  SLOE,
        output  wire            IFCLK,
        inout [15:0]            FDATA,
        // sdram Wishbone Interface
        input  [31:0]           data_o,
        input                   stall_o,
        input                   sdram_ack,
        output                  stb_i,
        output                  we_i,
        output [3:0]            sel_i,
        output                  cyc_i,
        output [31:0]           addr_i,
        output [31:0]           data_i
);
    localparam READ_TO_SDRAM = 4'b0000;
    localparam FIRST_CONV = 4'b0001;
    localparam FIRST_POOL = 4'b0010;
    localparam SECOND_CONV = 4'b0011;
    localparam SECOND_POOL = 4'b0100;

    localparam GATHER_PATCH = 4'b0101;
    localparam GATHER_KERNEL = 4'b0110;
    localparam GATHER_POOL = 4'b0111;

    localparam CONV = 4'b1000;
    localparam MAXPOOL = 4'b1001;
    localparam WRITE_TO_USB = 4'b1010;
    // localparam READ_IDLE = 4'b0110;
    // localparam READ_DATA = 4'b0111;
    // localparam WRITE_IDLE = 4'b1000;
    // localparam WRITE_DATA = 4'b1000;

    reg [3:0] current_state = READ_TO_SDRAM;
    reg [3:0] next_state;

    reg [15:0] KERNELS[8:0];
    reg [15:0] PATCHES[8:0];
    reg [15:0] CONV_RESULT;
    reg [15:0] POOL_RESULT;

    reg read_ack; // 标志read_to_sdram 是否完成

    // read_to_sdram 与 usb 相关的输出信号
    reg read_sdram_slrd;
    reg read_sdram_sloe;
    reg read_sdram_slwr;

    // read_to_sdram 与 sdram 相关的输出信号
    reg [31:0] read_sdram_data_i;
    reg read_sdram_stb_i;
    reg read_sdram_we_i;
    reg [3:0] read_sdram_sel_i;
    reg read_sdram_cyc_i;
    reg [31:0] read_sdram_addr_i;

    // convnet 与 usb 相关的输出信号
    reg convnet_slrd;
    reg convnet_sloe;
    reg convnet_slwr;

    // convnet 与 sdram 相关的输出信号
    reg [31:0] convnet_data_i;
    reg convnet_stb_i;
    reg convnet_we_i;
    reg [3:0] convnet_sel_i;
    reg convnet_cyc_i;
    reg [31:0] convnet_addr_i;

    // 最终输出的与 usb 相关的输出信号
    reg out_slrd;
    reg out_sloe;
    reg out_slwr;

    // 最终输出的与 sdram 相关的输出信号
    reg [31:0] out_data_i;
    reg out_stb_i;
    reg out_we_i;
    reg [3:0] out_sel_i;
    reg out_cyc_i;
    reg [31:0] out_addr_i;
    

    // 例化 conv
    conv_3_3 convmodule(
        .CLK(CLK),
        .rst_n(rst_n),
        .PATCH({PATCHES[0],PATCHES[1],PATCHES[2],PATCHES[3],PATCHES[4],PATCHES[5],PATCHES[6],PATCHES[7],PATCHES[8]}),
        .KERNEL({KERNELS[0],KERNELS[1],KERNELS[2],KERNELS[3],KERNELS[4],KERNELS[5],KERNELS[6],KERNELS[7],KERNELS[8]}),
        .RESULT(CONV_RESULT)
    );

    // 例化 maxpool
    maxpool poolmodule(
        .CLK(CLK),
        .rst_n(rst_n),
        .PATCH({PATCHES[0],PATCHES[1],PATCHES[2],PATCHES[3]}),
        .RESULT(POOL_RESULT)
    );

    read_to_sdram readsdrammodule(
        .CLKOUT(CLK),
        .rst_n(rst_n),
        .FLAGA(FLAGA),
        .SLWR(read_sdram_slwr),
        .SLRD(read_sdram_slrd),
        .SLOE(read_sdram_sloe),

    );

    // 组合逻辑计算下一个状态
    always @(*) begin
        case (current_state)
            // READ_TO_SDRAM
            READ_TO_SDRAM:begin
                if(read_ack == 1'b1)begin
                    next_state = GATHER_KERNEL;
                end
                else begin
                    next_state = READ_TO_SDRAM;
                end
            end
            // FIRST_CONV
            FIRST_CONV:begin
                
            end 
            // FIRST_POOL
            FIRST_POOL:begin
                
            end 
            // SECOND_CONV
            SECOND_CONV:begin
                
            end 
            // SECOND_POOL
            SECOND_POOL:begin
                
            end 
            // GATHER_PATCH
            GATHER_PATCH:begin
                
            end 
            // GATHER_KERNEL
            GATHER_KERNEL:begin
                
            end 
            // GATHER_POOL
            GATHER_POOL:begin
                
            end 
            // CONV
            CONV:begin
                
            end 
            // MAXPOOL
            MAXPOOL:begin
                
            end 
            // WRITE_TO_USB
            WRITE_TO_USB:begin
                
            end 
            default: begin
                
            end
        endcase
    end

endmodule
