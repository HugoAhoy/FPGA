`timescale 1ns / 1ps

module conv (
    CLK,
    rst_n,
    //usb interface
    PATCH,
    KERNEL,
    RESULT
);
parameter KERNEL_SIZE = 3;
    input CLK;
    input rst_n;
    input  wire [KERNEL_SIZE*KERNEL_SIZE*16-1:0] PATCH;
    input  wire [KERNEL_SIZE*KERNEL_SIZE*16-1:0] KERNEL;
    output wire [63:0] RESULT;

    reg [63:0] reg_output;
    assign RESULT = reg_output;

    reg [15:0] PIXELS [KERNEL_SIZE*KERNEL_SIZE];
    reg [15:0] KERNEL_WEIGHT [KERNEL_SIZE*KERNEL_SIZE];
    reg [31:0] TEMP_RES [KERNEL_SIZE*KERNEL_SIZE];
    integer i;
    integer j;
    always @(*) begin
        for(i=0; i < KERNEL_SIZE*KERNEL_SIZE; i=i+1)
            // TEMP_RES[i] = PATCH[(i+1)*16-1:i*16]*KERNEL[(i+1)*16-1:i*16];
            for(j=0; j < 16; j=j+1)
                PIXELS[i][j] = PATCH[i*16+j];
                KERNEL_WEIGHT[i][j] = KERNEL[i*16+j];
    end

    always @(*) begin
        for(i=0; i < KERNEL_SIZE*KERNEL_SIZE; i=i+1)
            TEMP_RES[i] = PIXELS[i]*KERNEL_WEIGHT[i];
    end

    always @(*) begin
        reg_output = 0;
        for(i=0; i < KERNEL_SIZE*KERNEL_SIZE; i=i+1)
            reg_output = reg_output + {32'd0, TEMP_RES[i]};
    end
endmodule