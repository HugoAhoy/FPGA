`timescale 1ns/1ps
module maxpool
(
    CLK,
    rst_n,
    PATCH,
    RESULT
);
    localparam DATAWIDTH = 64;
    input CLK;
    input rst_n;
    input  wire [4*DATAWIDTH-1:0] PATCH;
    output wire [DATAWIDTH-1:0] RESULT;
    
    reg [DATAWIDTH-1:0] PIXELS[3:0];
    reg [DATAWIDTH-1:0] RES;

    assign RESULT=RES;

    always @(*) begin
        {PIXELS[0],PIXELS[1],PIXELS[2],PIXELS[3]} = PATCH;
    end

    always @(*) begin
        if(PIXELS[0] < PIXELS[1])begin
            PIXELS[0] = PIXELS[1];
        end
    end
    always @(*) begin
        if(PIXELS[2] < PIXELS[3])begin
            PIXELS[2] = PIXELS[3];
        end        
    end

    always @(*) begin
        if(PIXELS[0] < PIXELS[2])begin
            RES = PIXELS[2];
        end
        else begin
            RES = PIXELS[2];
        end
    end

endmodule