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
    reg [1:0] read_sdram_fifoadr;
    reg [15:0] read_sdram_fdata;

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
    reg [1:0] convnet_fifoadr;
    reg [15:0] convnet_fdata;

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
    reg [1:0] out_fifoadr;
    reg [15:0] out_fdata;

    // 最终输出的与 sdram 相关的输出信号
    reg [31:0] out_data_i;
    reg out_stb_i;
    reg out_we_i;
    reg [3:0] out_sel_i;
    reg out_cyc_i;
    reg [31:0] out_addr_i;

    // 将out_usb输出连接到输出引脚
    assign SLRD = out_slrd;
    assign SLOE = out_sloe;
    assign SLWR = out_slwr;
    assign FIFOADR = out_fifoadr;
    assign FDATA = (current_state == READ_TO_SDRAM)? 16'hz:out_fdata;

    // 将out_sdram输出连接到输出引脚
    assign data_i = out_data_i;
    assign stb_i = out_stb_i;
    assign we_i = out_we_i;
    assign sel_i = out_sel_i;
    assign cyc_i = out_cyc_i;
    assign addr_i = out_addr_i;

    // 状态转移相关寄存器
    reg LAYER=0;
    reg [4:0] kernel_idx=5'd0;
    reg [4:0] kernel_bias = 5'd0;
    reg [2:0] kernel_cyc_cnt = 3'd0;

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
        .FIFOADR(read_sdram_fifoadr),
        .FDATA(FDATA),
        .data_o(data_o),
        .sdram_ack(sdram_ack),
        .stall_o(stall_o),
        .read_ack(read_ack),
        .data_i(read_sdram_data_i),
        .stb_i(read_sdram_stb_i),
        .we_i(read_sdram_we_i),
        .sel_i(read_sdram_sel_i),
        .cyc_i(read_sdram_cyc_i),
        .addr_i(read_sdram_addr_i)
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
                next_state = FIRST_CONV;
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
                if ((kernel_idx == 5'd8)&&(kernel_cyc_cnt == 3'd3))begin
                    next_state = FIRST_CONV;
                end
                else begin
                    next_state = GATHER_KERNEL;
                end
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

    // 时序逻辑控制状态转移
    always @(posedge CLK) begin
        current_state <= next_state;
    end

    // 组合逻辑根据状态给sdram输出赋值
    always @(*) begin
        if(current_state == READ_TO_SDRAM)begin
            out_data_i = read_sdram_data_i;
            out_stb_i = read_sdram_stb_i;
            out_we_i = read_sdram_we_i;
            out_sel_i = read_sdram_sel_i;
            out_cyc_i = read_sdram_cyc_i;
            out_addr_i = read_sdram_addr_i;
        end
        else begin
            out_data_i = convnet_data_i;
            out_stb_i = convnet_stb_i;
            out_we_i = convnet_we_i;
            out_sel_i = convnet_sel_i;
            out_cyc_i = convnet_cyc_i;
            out_addr_i = convnet_addr_i;            
        end
    end

    // sdram 信号
    always @(*) begin
        case(current_state)
            GATHER_KERNEL:begin
                if(kernel_cyc_cnt == 3'd3)begin
                    convnet_stb_i=1'b0;
                    convnet_cyc_i=1'b0;
                end
                else begin
                    convnet_stb_i=1'b0;
                    convnet_cyc_i=1'b0;
                end
                convnet_data_i= 32'hz;
                convnet_we_i=1'b0;
                convnet_sel_i=4'b0011;
                convnet_addr_i= {27'd0,kernel_bias}+{27'd0,kernel_idx};
            end
        endcase
    end

    // 时序逻辑控制一些状态内变量的值
    always @(posedge CLK) begin
        case (current_state)
            GATHER_KERNEL:begin
                if(kernel_cyc_cnt == 3'd3)begin
                    kernel_cyc_cnt <= 0;
                    kernel_idx <= kernel_idx + 5'd1;
                end
                else begin
                    kernel_cyc_cnt <= kernel_cyc_cnt+sdram_ack;
                end
            end 
            default: begin
                
            end
        endcase
    end

    always @(posedge CLK) begin
        case (current_state)
            GATHER_KERNEL: begin
                if(kernel_cyc_cnt == 3'd1) begin
                    KERNELS[kernel_idx[3:0]] <= data_o[15:0];
                end
            end
            default: begin
                
            end
        endcase
    end

    // 
endmodule
