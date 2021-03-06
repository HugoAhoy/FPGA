`timescale 1ns / 1ps

module usb_write(
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
		output  wire [ 3: 0]    LED,
		output  wire [ 2: 0]    cstate, 
		output  wire            pktend, 
        inout   wire [15: 0]    FDATA
    );
    parameter SEND_PKTEND = 3'b010;
    parameter IDLE = 3'b100;
    parameter WRITE_DATA = 3'b011;

    reg [2: 0] current_state = IDLE;
    reg [2: 0] next_state;

    // 根据文档，IFCLK需要180反向，让FX2LP建立数据同步时间
    assign IFCLK = ~CLKOUT;

    // 用寄存器保存下一时刻的读写信号
    reg next_SLWR = 1'b1;
    reg next_SLRD = 1'b1;
    reg next_SLOE = 1'b1;

    // pktend 信号
    reg next_pktend = 1'b1;

    // 寄存器保存下一时刻的FIFOADR地址选择
    reg [1:0] next_FIFOADR = 2'b10;

    // 寄存器保存下一时刻的数据信号
    // reg [15:0] data;

    // 寄存器记录当前输入
    reg [15:0] cnt = 0;

    // 将读写信号连接到输出引脚
    assign SLWR = next_SLWR;
    assign SLRD = next_SLRD;
    assign SLOE = next_SLOE;

    // 将pkt信号连接到输出引脚
    assign pktend = next_pktend;

    // 将状态连接到LED灯
    assign LED[2:0] = next_state;
    assign LED[3] = FLAGD;
    assign cstate = current_state;

    // 将endpoint选择信号连接到输出引脚
    assign FIFOADR = next_FIFOADR;

    // 将数据连接到输出引脚
    assign FDATA = (next_state == WRITE_DATA)? {8'd0,cnt[7:0]}:16'hzzzz;
    // assign FDATA = (next_state == WRITE_DATA)? data:16'hzzzz;

    // 组合逻辑实现状态机
    always @(*) begin
        case(current_state)
            IDLE:begin
                if(FLAGD == 1'b1)begin
                    next_state = WRITE_DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WRITE_DATA:begin
                if (cnt[3:0] == 4'd15)begin
                    next_state = SEND_PKTEND;
                end
                else if(FLAGD == 1'b0)begin
                    next_state = IDLE;
                end
                else begin
                    next_state = WRITE_DATA;
                end
            end
            SEND_PKTEND:begin
                if(FLAGD == 1'b0)begin
                    next_state = IDLE;
                end
                else begin
                    next_state = WRITE_DATA;
                end
            end
            default:begin
                next_state = IDLE;
            end
        endcase
    end

    // TODO: 组合逻辑实现读写信号控制
    always @(*) begin
        case(current_state)
            WRITE_DATA:begin
                next_SLWR = 1'b0;
                next_SLRD = 1'b1;
                next_SLOE = 1'b1;
                next_pktend = 1'b1;
            end
            SEND_PKTEND:begin
                next_SLWR = 1'b0;
                next_SLRD = 1'b1;
                next_SLOE = 1'b1;
                next_pktend = 1'b0;                
            end
            default:begin
                next_SLWR = 1'b1;
                next_SLRD = 1'b1;
                next_SLOE = 1'b1;
                next_pktend = 1'b1;
            end
        endcase
    end

    // 组合逻辑实现 EP2, EP6 的 FIFOADR 选择
    always @(*) begin
        // if((current_state == IDLE) | (current_state == SELECT_READ_FIFO) | (current_state == READ_DATA))begin
        if(current_state == IDLE)begin
            next_FIFOADR[1:0] = 2'b10; // 因为这个代码只实现FPGA写操作，所以让FIFOADR一直选择 EP6
        end
        else begin
            next_FIFOADR[1:0] = 2'b10;
        end
    end

    // 时序逻辑实现数据的输出
    // always @(posedge CLKOUT) begin
    //     if(current_state == WRITE_DATA)begin
    //         data <= {8'h00,cnt[7:0]};
    //     end
    // end

    // 在每次时候上升沿控制自动机状态转换
    always@(posedge CLKOUT, negedge rst_n) begin
        if(rst_n == 1'b0)begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // 统计读取/写入数据字节数
    always@(posedge CLKOUT)begin
        // if(reset_n == 1'b0)
        // 	data_out1 <= 16'd0;
        // else if(slwr_n == 1'b0)
        // 	data_out1 <= data_out1 + 16'd1;
        if(next_state == WRITE_DATA)begin
            cnt <= cnt + 16'b1;
        end
        else begin
            cnt <= cnt + 16'b0;
        end
    end

endmodule
