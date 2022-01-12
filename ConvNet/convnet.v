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
        // for debug
        output [3:0]            cstate,
        output [16*9-1:0]       KERNELS_d,
        output [16*9-1:0]       PATCHES_d,
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
    localparam END = 4'b1011;
    // localparam READ_IDLE = 4'b0110;
    // localparam READ_DATA = 4'b0111;
    // localparam WRITE_IDLE = 4'b1000;
    // localparam WRITE_DATA = 4'b1000;

    // 定义idx边界
    localparam FIRST_CONV_BORDER = 5'd7;
    localparam SECOND_CONV_BORDER = 5'd1;
    localparam FIRST_POOL_BORDER = 5'd6;
    localparam SECOND_POOL_BORDER = 5'd0;

    // 卷积bias
    reg [1:0] conv_bias_i[8:0];
    reg [1:0] conv_bias_j[8:0];

    // 池化bias
    reg [1:0] pool_bias_i[3:0];
    reg [1:0] pool_bias_j[3:0];

    initial begin
        conv_bias_i[0] = 2'd0;
        conv_bias_i[1] = 2'd0;
        conv_bias_i[2] = 2'd0;
        conv_bias_i[3] = 2'd1;
        conv_bias_i[4] = 2'd1;
        conv_bias_i[5] = 2'd1;
        conv_bias_i[6] = 2'd2;
        conv_bias_i[7] = 2'd2;
        conv_bias_i[8] = 2'd2;

        conv_bias_j[0] = 2'd0;
        conv_bias_j[1] = 2'd1;
        conv_bias_j[2] = 2'd2;
        conv_bias_j[3] = 2'd0;
        conv_bias_j[4] = 2'd1;
        conv_bias_j[5] = 2'd2;
        conv_bias_j[6] = 2'd0;
        conv_bias_j[7] = 2'd1;
        conv_bias_j[8] = 2'd2;

        pool_bias_i[0] = 2'd0;
        pool_bias_i[1] = 2'd0;
        pool_bias_i[2] = 2'd1;
        pool_bias_i[3] = 2'd1;

        pool_bias_j[0] = 2'd0;
        pool_bias_j[1] = 2'd1;
        pool_bias_j[2] = 2'd0;
        pool_bias_j[3] = 2'd1;
    end

    // 初始patch 左上角的idx
    reg [4:0] idx_i = 5'd0;
    reg [4:0] idx_j = 5'd0;

    reg [3:0] current_state = READ_TO_SDRAM;
    reg [3:0] next_state;

    // for debug
    assign cstate = current_state;
    assign KERNELS_d = {KERNELS[0],KERNELS[1],KERNELS[2],KERNELS[3],KERNELS[4],KERNELS[5],KERNELS[6],KERNELS[7],KERNELS[8]};
    assign PATCHES_d = {PATCHES[0],PATCHES[1],PATCHES[2],PATCHES[3],PATCHES[4],PATCHES[5],PATCHES[6],PATCHES[7],PATCHES[8]};

    reg [15:0] KERNELS[8:0];
    reg [15:0] PATCHES[8:0];
    wire [15:0] CONV_RESULT;
    wire [15:0] POOL_RESULT;

    wire read_ack; // 标志read_to_sdram 是否完成

    // read_to_sdram 与 usb 相关的输出信号
    wire read_sdram_slrd;
    wire read_sdram_sloe;
    wire read_sdram_slwr;
    wire [1:0] read_sdram_fifoadr;
    wire [15:0] read_sdram_fdata;

    // read_to_sdram 与 sdram 相关的输出信号
    wire [31:0] read_sdram_data_i;
    wire read_sdram_stb_i;
    wire read_sdram_we_i;
    wire [3:0] read_sdram_sel_i;
    wire read_sdram_cyc_i;
    wire [31:0] read_sdram_addr_i;

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
    reg [2:0] kernel_cyc_cnt = 3'd0; // GATHER_KERNEL 时候控制sdram信号的counter
    reg [3:0] patch_idx = 4'd0;
    reg [2:0] patch_cyc_cnt = 3'd0;
    reg [2:0] gather_pool_cyc_cnt = 3'd0;

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
        .IFCLK(IFCLK),
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
                if (idx_i > FIRST_CONV_BORDER) begin
                    next_state = FIRST_POOL;
                end
                else begin
                    next_state = GATHER_PATCH;
                end
            end 
            // FIRST_POOL
            FIRST_POOL:begin
                if (idx_i > FIRST_POOL_BORDER) begin
                    next_state = GATHER_KERNEL; // 从SDRAM读入第二层卷积的KERNEL
                end
                else begin
                    next_state = GATHER_POOL;
                end
            end 
            // SECOND_CONV
            SECOND_CONV:begin
                if (idx_i > SECOND_CONV_BORDER) begin
                    next_state = SECOND_POOL;
                end
                else begin
                    next_state = GATHER_PATCH;
                end
            end 
            // SECOND_POOL
            SECOND_POOL:begin
                if (idx_i > SECOND_POOL_BORDER) begin
                    next_state = WRITE_TO_USB; // 将结果写回USB
                end
                else begin
                    next_state = GATHER_POOL;
                end                
            end 
            // GATHER_PATCH
            GATHER_PATCH:begin
                if ((patch_idx == 4'd8)&&(patch_cyc_cnt == 3'd3))begin
                    next_state = CONV;
                end
                else begin
                    next_state = GATHER_PATCH;
                end
            end 
            // GATHER_KERNEL
            GATHER_KERNEL:begin
                if ((kernel_idx == 4'd8)&&(kernel_cyc_cnt == 3'd3))begin
                    if(LAYER == 1'b0)begin
                        next_state = FIRST_CONV;
                    end
                    else begin
                        next_state = SECOND_CONV;
                    end
                end
                else begin
                    next_state = GATHER_KERNEL;
                end
            end 
            // GATHER_POOL
            GATHER_POOL:begin
                if ((patch_idx == 4'd3)&&(gather_pool_cyc_cnt == 3'd3))begin
                    next_state = MAXPOOL;
                end
                else begin
                    next_state = GATHER_POOL;
                end
            end 
            // CONV
            CONV:begin
                if(sdram_ack == 1'b1) begin
                    if(LAYER == 1'b0)begin
                        next_state = FIRST_CONV;
                    end
                    else begin
                        next_state = SECOND_CONV;
                    end
                end
                else begin
                    next_state = CONV;
                end
            end 
            // MAXPOOL
            MAXPOOL:begin
                if(sdram_ack == 1'b1) begin
                    if(LAYER == 1'b0)begin
                        next_state = FIRST_POOL;
                    end
                    else begin
                        next_state = SECOND_POOL;
                    end
                end
                else begin
                    next_state = MAXPOOL;
                end                
            end 
            // WRITE_TO_USB
            WRITE_TO_USB:begin
                next_state = WRITE_TO_USB;
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

    // 组合逻辑根据状态给usb输出赋值
    always @(*) begin
        if(current_state == READ_TO_SDRAM)begin
            out_slwr = read_sdram_slwr;
            out_sloe = read_sdram_sloe;
            out_slrd = read_sdram_slrd;
            out_fifoadr = read_sdram_fifoadr;
        end
        else begin
            out_slwr = convnet_slwr;
            out_sloe = convnet_sloe;
            out_slrd = convnet_slrd;
            out_fifoadr = convnet_fifoadr;
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
                    convnet_stb_i=1'b1;
                    convnet_cyc_i=1'b1;
                end
                convnet_data_i= 32'hz;
                convnet_we_i=1'b0;
                convnet_sel_i=4'b0011;
                convnet_addr_i= {27'd0,kernel_bias}+{27'd0,kernel_idx};
            end
            GATHER_PATCH:begin
                if(patch_cyc_cnt == 3'd3)begin
                    convnet_stb_i=1'b0;
                    convnet_cyc_i=1'b0;
                end
                else begin
                    convnet_stb_i=1'b1;
                    convnet_cyc_i=1'b1;
                end
                convnet_data_i= 32'hz;
                convnet_we_i=1'b0;
                convnet_sel_i=4'b0011;
                convnet_addr_i= 32'd18+({27'd0,idx_i} + {30'd0,conv_bias_i[patch_idx]})*32'd10+({27'd0,idx_j} + {30'd0,conv_bias_j[patch_idx]});
            end
            CONV:begin
                convnet_stb_i=1'b1;
                convnet_cyc_i=1'b1;
                convnet_data_i= {16'd0, CONV_RESULT};
                convnet_we_i=1'b1;
                convnet_sel_i=4'b0011;
                convnet_addr_i= 32'd18+{27'd0,idx_i}*32'd10+{27'd0,idx_j};
            end
            GATHER_POOL:begin
                if(gather_pool_cyc_cnt == 3'd3)begin
                    convnet_stb_i=1'b0;
                    convnet_cyc_i=1'b0;
                end
                else begin
                    convnet_stb_i=1'b1;
                    convnet_cyc_i=1'b1;
                end
                convnet_data_i= 32'hz;
                convnet_we_i=1'b0;
                convnet_sel_i=4'b0011;
                convnet_addr_i= 32'd18+({27'd0,idx_i} + {30'd0,pool_bias_i[patch_idx]})*32'd10+({27'd0,idx_j} + {30'd0,pool_bias_j[patch_idx]});
            end
            MAXPOOL:begin
                convnet_stb_i=1'b1;
                convnet_cyc_i=1'b1;
                convnet_data_i= {16'd0, POOL_RESULT};
                convnet_we_i=1'b1;
                convnet_sel_i=4'b0011;
                convnet_addr_i= 32'd18+{28'd0,idx_i[4:1]}*32'd10+{28'd0,idx_j[4:1]};// 相当于右移一位 
            end
            default: begin
                convnet_stb_i=1'b0;
                convnet_cyc_i=1'b0;
                convnet_data_i= 32'hz;
                convnet_we_i=1'b0;
                convnet_sel_i=4'b0000;
                convnet_addr_i= 32'd0;
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
            GATHER_PATCH:begin
                if(patch_cyc_cnt == 3'd3)begin
                    patch_cyc_cnt <= 0;
                    if (patch_idx == 4'd8)begin
                        patch_idx <= 4'd0;
                    end
                    else begin
                        patch_idx <= patch_idx + 4'd1;
                    end
                end
                else begin
                    patch_cyc_cnt <= patch_cyc_cnt+sdram_ack;
                end
            end 
            GATHER_POOL:begin
                if(gather_pool_cyc_cnt == 3'd3)begin
                    gather_pool_cyc_cnt <= 0;
                    if (patch_idx == 4'd3)begin
                        patch_idx <= 4'd0;
                    end
                    else begin
                        patch_idx <= patch_idx + 4'd1;
                    end
                end
                else begin
                    gather_pool_cyc_cnt <= gather_pool_cyc_cnt+sdram_ack;
                end
            end 
            FIRST_POOL: begin
                if(next_state == GATHER_KERNEL) begin
                    kernel_idx <= 5'd0;
                    kernel_bias <= 5'd9;
                    LAYER <= 1'd1;
                end
            end
            default: begin
                
            end
        endcase
    end

    // 数据IO
    always @(posedge CLK) begin
        case (current_state)
            GATHER_KERNEL: begin
                if(kernel_cyc_cnt == 3'd1) begin
                    KERNELS[kernel_idx[3:0]] <= data_o[15:0];
                end
            end
            GATHER_PATCH:begin
                if(patch_cyc_cnt == 3'd1) begin
                    PATCHES[patch_idx[3:0]] <= data_o[15:0];
                end
            end
            GATHER_POOL:begin
                if(gather_pool_cyc_cnt == 3'd1) begin
                    PATCHES[patch_idx[3:0]] <= data_o[15:0];
                end
            end
            default: begin
                
            end
        endcase
    end

    // 控制图片左上角位置
    always @(posedge CLK) begin
        case (current_state)
            CONV: begin
                if (next_state == FIRST_CONV) begin
                    if(idx_j == FIRST_CONV_BORDER) begin
                        idx_i <= idx_i + 5'd1;
                        idx_j <= 5'd0;
                    end
                    else begin
                        idx_j <= idx_j + 5'd1;
                    end
                end
                else if (next_state == SECOND_CONV) begin
                    if(idx_j == SECOND_CONV_BORDER) begin
                        idx_i <= idx_i + 5'd1;
                        idx_j <= 5'd0;
                    end
                    else begin
                        idx_j <= idx_j + 5'd1;
                    end
                end
            end 
            FIRST_CONV: begin
                if(next_state == FIRST_POOL) begin
                    // 重置 idx_i, idx_j 和 patch_idx
                    idx_i <= 5'd0;
                    idx_j <= 5'd0;
                end
            end
            FIRST_POOL: begin
                if(next_state == GATHER_KERNEL) begin
                    // 重置 idx_i, idx_j 和 patch_idx
                    idx_i <= 5'd0;
                    idx_j <= 5'd0;
                end
            end
            SECOND_CONV: begin
                if(next_state == SECOND_POOL) begin
                    // 重置 idx_i, idx_j 和 patch_idx
                    idx_i <= 5'd0;
                    idx_j <= 5'd0;
                end
            end
            MAXPOOL: begin
                if (next_state == FIRST_POOL) begin
                    if(idx_j == FIRST_POOL_BORDER) begin
                        idx_i <= idx_i + 5'd2;
                        idx_j <= 5'd0;
                    end
                    else begin
                        idx_j <= idx_j + 5'd2;
                    end
                end
                else if (next_state == SECOND_POOL) begin
                    if(idx_j == SECOND_POOL_BORDER) begin
                        idx_i <= idx_i + 5'd2;
                        idx_j <= 5'd0;
                    end
                    else begin
                        idx_j <= idx_j + 5'd2;
                    end                    
                end
            end
            default: begin
                
            end
        endcase
    end

endmodule
