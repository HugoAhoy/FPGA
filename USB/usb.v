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
        inout   wire [15: 0]    FD
);

parameter IDLE = 3'b000; // 空闲状态
parameter SELECT_WRITE_FIFO = 3'b001; // 等待写入信号状态
parameter SELECT_READ_FIFO = 3'b010; // 等待读取信号状态
parameter WRITE_DATA = 3'b011; // 写入数据状态
parameter READ_DATA = 3'b100; // 读取数据状态
parameter CONV = 3'b101; // 卷积操作状态

reg [2: 0] current_state;
reg [2: 0] next_state;

// 根据文档，IFCLK需要180反向，让FX2LP建立数据同步时间
assign IFCLK = ~CLKOUT;

// 用寄存器保存下一时刻的读写信号
reg next_SLWR;
reg next_SLRD;
reg next_SLOE;

// 寄存器保存下一时刻的FIFOADR地址选择
reg [1:0] next_FIFOADR;

// 记录数据读取/写入次数
reg counter = 0;

// 将读写信号连接到输出引脚
assign SLWR = next_SLWR;
assign SLRD = next_SLRD;
assign SLOE = next_SLOE;

// 将endpoint选择信号连接到输出引脚
assign FIFOADR = next_FIFOADR;


// 组合逻辑实现状态机
// TODO: 未完成
always @(*) begin
    case(current_state)
        IDLE:begin
            if(FLAGA == 1'b1 )begin
                next_state = READ_DATA;
            end
            else begin
                next_state = IDLE;
            end
        end
        WRITE_DATA:begin
            if(FLAGD == 1'b1 )begin
                next_state = READ_DATA;
            end
            else begin
                next_state = IDLE;
            end
        end
        READ_DATA:begin
            if(FLAGA == 1'b1 )begin
                next_state = READ_DATA;
            end
            else begin
                next_state = SELECT_READ_FIFO;
            end
        end
        SELECT_READ_FIFO:begin
            
        end
        default:begin
            next_state = IDLE;
        end
    endcase
end

// 组合逻辑实现读写信号控制
always @(negedge IFCLK) begin
    case (current_state)
        IDLE:begin
            // next_SLWR <= 1'b1;
            // next_SLRD <= 1'b1;
            // next_SLOE <= 1'b1;
        end
        SELECT_READ_FIFO:begin
            
        end
        SELECT_WRITE_FIFO:begin
            
        end
        WRITE_DATA:begin
            
        end
        READ_DATA:begin
            
        end
        CONV:begin
            
        end
        default: begin
            
        end
    endcase
end

// 组合逻辑实现 EP2, EP6 的 FIFOADR 选择
always @(*) begin
    if((current_state == IDLE) | (current_state == SELECT_READ_FIFO) | (current_state == READ_DATA))begin
        next_FIFOADR[1:0] = 2'b00;
    end
    else begin
        next_FIFOADR[1:0] = 2'b10;
    end
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

// 统计读取/写入的字节数
always@(posedge CLKOUT)begin
    if(next_SLWR == 1'b0)begin
        counter <= counter + 1;
    end
end
endmodule