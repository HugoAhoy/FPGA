`timescale 1ns / 1ps

module read_to_sdram(
        input                   CLKOUT,
        input                   rst_n,
        //usb interface  
        input                   FLAGA, // EP2 OUT FIFO 的空标志
        output                  SLWR,
        output                  SLRD,
        output                  SLOE,
        output  wire            IFCLK,
        output  wire [ 1: 0]    FIFOADR,
		output  wire [ 3: 0]    LED,
		output  wire [ 2: 0]    cstate, 
        inout   wire [15: 0]    FDATA,
        output wire             read_ack,
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

    localparam IDLE = 3'b000;
    localparam SELECT_READ_FIFO = 3'b001;
    localparam READ_DATA = 3'b010;
    localparam WRITE_TO_SDRAM = 3'b011;
    localparam NUM_TO_READ = 118;

    reg [2: 0] current_state;
    reg [2: 0] next_state;

    // 保存读入的数据
    reg [15:0] DATA;

    // 根据文档，IFCLK需要180反向，让FX2LP建立数据同步时间
    assign IFCLK = ~CLKOUT;

    // 用寄存器保存下一时刻的读写信号
    reg next_SLWR;
    reg next_SLRD;
    reg next_SLOE;

    // 寄存器保存下一时刻的FIFOADR地址选择
    reg [1:0] next_FIFOADR;

    // 寄存器保存读取完成信号
    reg next_read_ack = 1'b0;

    // 寄存器保存sdram wishbone 输出信号
    reg stb_n = 1'b0;
    reg we_n = 1'b1;
    reg [3:0] sel_n;
    reg cyc_n = 1'b0;
    reg [31:0] addr_n = 0;
    reg [31:0] data_n;

    // 寄存器记录当前输入
    reg [15:0] cnt = 16'd0;

    // 将读写信号连接到输出引脚
    assign SLWR = next_SLWR;
    assign SLRD = next_SLRD;
    assign SLOE = next_SLOE;
	 
    // 将状态连接到LED灯
    assign LED[2:0] = next_state;
    assign LED[3] = FLAGA;
    assign cstate = current_state;

    // 将endpoint选择信号连接到输出引脚
    assign FIFOADR = next_FIFOADR;

    // 将sdram wishbone 输出连接到引脚
    assign stb_i = stb_n;
    assign we_i = we_n;
    assign sel_i = sel_n;
    assign cyc_i =  cyc_n;
    assign addr_i = addr_n;
    assign data_i = data_n;

    // 将read_ack连接到输出引脚
    assign read_ack = next_read_ack;

    // 将数据连接到输出引脚
    // assign FDATA = (next_state == WRITE_DATA)? data:16'hzzzz;

    // 组合逻辑实现状态机
    always @(*) begin
        case(current_state)
            IDLE:begin
                if(FLAGA == 1'b1)begin
                    next_state = SELECT_READ_FIFO;
                end
                else begin
                    next_state = IDLE;
                end
            end
            SELECT_READ_FIFO:begin
                if(cnt == NUM_TO_READ)begin
                    next_read_ack = 1'b1;
                    next_state = SELECT_READ_FIFO;
                end
                else if(FLAGA == 1'b0)begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ_DATA;
                end
            end
            READ_DATA:begin
                next_state = WRITE_TO_SDRAM;
            end
            WRITE_TO_SDRAM:begin
                if(sdram_ack == 1'b1)begin
                    next_state = SELECT_READ_FIFO;
                end
                else begin
                    next_state = WRITE_TO_SDRAM;
                end
            end
            default:begin
                next_state = IDLE;
            end
        endcase
    end

    // TODO: 组合逻辑实现读写信号控制
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
                next_SLOE = ~FLAGA;
            end
            READ_DATA:begin
                next_SLWR = 1'b1;
                next_SLRD = ~FLAGA;
                next_SLOE = ~FLAGA;                
            end
            WRITE_TO_SDRAM:begin
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
    always @(*) begin
        if(current_state == IDLE)begin
            next_FIFOADR[1:0] = 2'b00; // 因为这个代码只实现FPGA读USB操作，所以让FIFOADR一直选择 EP2
        end
        else begin
            next_FIFOADR[1:0] = 2'b00;
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
        if((next_state == SELECT_READ_FIFO) &&(current_state == WRITE_TO_SDRAM))begin
            cnt <= cnt + 16'b1;
        end
		  else if(next_state == READ_DATA) begin
		      if (FLAGA == 1'b1) begin
		          DATA <= FDATA;
				end
		  end
    end

    // TODO:sdram相关信号的输出
    always @(*) begin
        case (current_state)
            WRITE_TO_SDRAM:begin
                stb_n = 1'b1; // 选通
                cyc_n = 1'b1; // 总线周期有效
                addr_n = {16'd0,cnt}; // 地址
                data_n = {16'd0,DATA};
                sel_n = 4'b0011;
                we_n = 1'b1;
            end
            default:begin
                stb_n = 1'b0; // 不选通
                cyc_n = 1'b0; // 总线周期无效
                addr_n = 32'hz; // 地址
                data_n = 32'hz;
                sel_n = 4'b0000;
                we_n = 1'b1;
            end 
        endcase
    end
endmodule
