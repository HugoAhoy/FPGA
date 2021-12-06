`timescale 1ns/1ps
`define MAXDATA 16'd18
`define RESBITS 16'd4

module  usb(  
        input                   CLKOUT,
        input                   rst_n,
        //usb interface  
        input                   FLAGD, // EP6 IN FIFO 的满标志
        input                   FLAGA, // EP2 OUT FIFO 的空标志
        output                  SLWR,
        output                  SLRD,
        output                  SLOE,
        output  wire            IFCLK,
        output  wire [ 1: 0]    FIFOADR,
        inout   wire [15: 0]    FDATA
);

localparam IDLE = 3'b000; // 空闲状态
localparam SELECT_WRITE_FIFO = 3'b001; // 等待写入信号状态
localparam SELECT_READ_FIFO = 3'b010; // 等待读取信号状态
localparam WRITE_DATA = 3'b011; // 写入数据状态
localparam READ_DATA = 3'b100; // 读取数据状态
localparam CONV = 3'b101; // 卷积操作状态

reg [2: 0] current_state;
reg [2: 0] next_state;

// 根据文档，IFCLK需要180反向，让FX2LP建立数据同步时间
assign IFCLK = ~CLKOUT;

// 用寄存器保存下一时刻的读写信号
reg next_SLWR;
reg next_SLRD;
reg next_SLOE;

// 寄存器保存下一状态的FIFOADR地址选择
reg [1:0] next_FIFOADR;

// 记录数据读取/写入次数
reg [15:0] rcounter = 0;
reg [15:0] wcounter = 0;

// 等待卷积核操作4个周期
reg [3:0] CONV_WAIT = 4'd4;

// 将读写信号连接到输出引脚
assign SLWR = next_SLWR;
assign SLRD = next_SLRD;
assign SLOE = next_SLOE;

// 将endpoint选择信号连接到输出引脚
assign FIFOADR = next_FIFOADR;


// 组合逻辑实现状态机
always @(*) begin
    case(current_state)
        IDLE:begin
            next_state = SELECT_READ_FIFO;
        end
        SELECT_READ_FIFO:begin
            if(rcounter < `MAXDATA)begin
                if (FLAGA == 1'b0)begin
                    next_state = READ_DATA;
                end
                else begin
                    next_state = SELECT_READ_FIFO;
                end
            end
            else begin
                next_state = CONV;
            end
        end
        READ_DATA:begin
            next_state = SELECT_READ_FIFO;
        end
        CONV:begin
            if(CONV_WAIT == 4'b0)begin
                next_state = SELECT_WRITE_FIFO;
            end
            else begin
                next_state = CONV;
            end
        end
        SELECT_WRITE_FIFO:begin
            if(wcounter < `RESBITS)begin
                if (FLAGA == 1'b0)begin
                    next_state = READ_DATA;
                end
                else begin
                    next_state = SELECT_READ_FIFO;
                end
            end
            else begin
                next_state = IDLE;
            end
        end
        WRITE_DATA:begin
            next_state = SELECT_WRITE_FIFO;
        end
        default:begin
            next_state = IDLE;
        end
    endcase
end

// 组合逻辑实现读写信号控制
always @(*) begin
    case (current_state)
        IDLE:begin
            next_SLWR = 1'b1;
            next_SLRD = 1'b1;
            next_SLOE = 1'b1;
        end
        SELECT_READ_FIFO:begin
            next_SLWR = 1'b1;
            next_SLRD = 1'b1;
            next_SLOE = 1'b0;            
        end
        SELECT_WRITE_FIFO:begin
            next_SLWR = 1'b1;
            next_SLRD = 1'b1;
            next_SLOE = 1'b1;
        end
        WRITE_DATA:begin
            next_SLWR = ~FLAGD;
            next_SLRD = 1'b1;
            next_SLOE = 1'b1;
        end
        READ_DATA:begin
            next_SLWR = 1'b1;
            next_SLRD = ~FLAGA;
            next_SLOE = 1'b0;
        end
        CONV:begin
            next_SLWR = 1'b1;
            next_SLRD = 1'b1;
            next_SLOE = 1'b1;
        end
        default: begin
            next_SLWR = 1'b1;
            next_SLRD = 1'b1;
            next_SLOE = 1'b1;
        end
    endcase
end

// 组合逻辑实现 EP2, EP6 的 FIFOADR 选择
// IDLE, SELECT_READ_FIFO, READ_DATA 选择EP2, 其他选EP6
always @(*) begin
    case (current_state)
        IDLE:begin
            next_FIFOADR[1:0] = 2'b00;
        end
        SELECT_READ_FIFO:begin
            next_FIFOADR[1:0] = 2'b00;
        end
        READ_DATA:begin
            next_FIFOADR[1:0] = 2'b00;
        end
        SELECT_WRITE_FIFO:begin
            next_FIFOADR[1:0] = 2'b10;
        end
        WRITE_DATA:begin
            next_FIFOADR[1:0] = 2'b10;
        end
        CONV:begin
            next_FIFOADR[1:0] = 2'b10;
        end
        default: begin
            next_FIFOADR[1:0] = 2'b00;
        end
    endcase
end

// 在每次时候上升沿控制自动机状态转换
always@(posedge CLKOUT, negedge rst_n) begin
	if(rst_n == 1'b0)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

// 统计写入的字节数
always@(posedge CLKOUT)begin
    if(current_state == IDLE)begin
        wcounter <= 0;
    end
    else if(next_SLWR == 1'b0)begin
        wcounter <= wcounter + 1;
    end
    else begin
        wcounter <= wcounter;
    end
end

// 统计读取的字节数
always@(posedge CLKOUT)begin
    if(current_state == IDLE)begin
        rcounter <= 0;
    end
    else if(next_SLWR == 1'b0)begin
        rcounter <= rcounter + 1;
    end
    else begin
        rcounter <= rcounter;
    end
end

// 记录CONV的运算时钟周期
always@(posedge CLKOUT)begin
    case(current_state)
        IDLE:begin
            CONV_WAIT <= 4'd4;
        end
        CONV:begin
            CONV_WAIT <= CONV_WAIT - 1;
        end
        default:begin
            CONV_WAIT <= CONV_WAIT;
        end
    endcase
end

endmodule