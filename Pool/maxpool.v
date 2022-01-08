`timescale 1ns/1ps
module maxpool
(
    CLK,
    rst_n,
    PATCH,
    RESULT
);
    localparam DATAWIDTH = 16;
    input CLK;
    input rst_n;
    input  wire [4*DATAWIDTH-1:0] PATCH;
    output wire [DATAWIDTH-1:0] RESULT;
    
    reg [DATAWIDTH-1:0] PIXELS[3:0];
    reg [DATAWIDTH-1:0] RES;
    reg [DATAWIDTH-1:0] TEMP_RES1;
    reg [DATAWIDTH-1:0] TEMP_RES2;

    assign RESULT=RES;

    always @(*) begin
        {PIXELS[0],PIXELS[1],PIXELS[2],PIXELS[3]} = PATCH;
    end

    always @(*) begin
        if(PIXELS[0] < PIXELS[1])begin
            TEMP_RES1 = PIXELS[1];
        end
        else begin
            TEMP_RES1 = PIXELS[0];
        end
    end
    always @(*) begin
        if(PIXELS[2] < PIXELS[3])begin
            TEMP_RES2 = PIXELS[3];
        end
        else begin
            TEMP_RES2 = PIXELS[2];
        end
    end

    always @(*) begin
        if(TEMP_RES1 < TEMP_RES2)begin
            RES = TEMP_RES2;
        end
        else begin
            RES = TEMP_RES1;
        end
    end

endmodule