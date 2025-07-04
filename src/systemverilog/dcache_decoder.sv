`timescale 1ns/1ps

`include "defs.sv"

module dcache_decoder(
    input       [3:0]   decode_Mctl,
    output reg          ren,
    output reg  [2:0]   rwidth,
    output reg          rsign,
    output reg          wen,
    output reg  [2:0]   wwidth
);

    always @(*) begin
        case(decode_Mctl)
        `MEM_NONE: begin
            ren = 0;
            rwidth = 0;
            rsign = 0;
            wen = 0;
            wwidth = 0;
        end

        `MEM_INIT: begin
            ren = 0;
            rwidth = 0;
            rsign = 0;
            wen = 0;
            wwidth = 0;
        end

        `MEM_LOAD1: begin
            ren = 1;
            rwidth = 1;
            rsign = 1;
            wen = 0;
            wwidth = 0;
        end

        `MEM_LOAD2: begin
            ren = 1;
            rwidth = 2;
            rsign = 1;
            wen = 0;
            wwidth = 0;
        end

        `MEM_LOAD4: begin
            ren = 1;
            rwidth = 4;
            rsign = 1;
            wen = 0;
            wwidth = 0;
        end

        `MEM_LOAD1U: begin
            ren = 1;
            rwidth = 1;
            rsign = 0;
            wen = 0;
            wwidth = 0;
        end

        `MEM_LOAD2U: begin
            ren = 1;
            rwidth = 2;
            rsign = 0;
            wen = 0;
            wwidth = 0;
        end

        `MEM_STORE1: begin
            ren = 0;
            rwidth = 0;
            rsign = 0;
            wen = 1;
            wwidth = 1;
        end
        
        `MEM_STORE2: begin
            ren = 0;
            rwidth = 0;
            rsign = 0;
            wen = 1;
            wwidth = 2;
        end

        `MEM_STORE4: begin
            ren = 0;
            rwidth = 0;
            rsign = 0;
            wen = 1;
            wwidth = 4;
        end

        endcase
    end



endmodule
