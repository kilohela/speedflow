`timescale 1ns / 1ps

`include "defs.sv"

module alu(
        input logic [3:0] op,
        input logic [31:0] a_i,
        input logic [31:0] b_i,
        output logic [31:0] out
    );
    logic [31:16]     shift_right_fill_r;
    logic [31:0]      shift_right_1_r;
    logic [31:0]      shift_right_2_r;
    logic [31:0]      shift_right_4_r;
    logic [31:0]      shift_right_8_r;

    logic [31:0]      shift_left_1_r;
    logic [31:0]      shift_left_2_r;
    logic [31:0]      shift_left_4_r;
    logic [31:0]      shift_left_8_r;

always_latch @(*) begin
    case(op)
        `ALU_SLL: begin
            if (b_i[0]) 
                shift_left_1_r = {a_i[30:0], 1'b0};
            else shift_left_1_r = a_i;

            if (b_i[1]) 
                shift_left_2_r = {shift_left_1_r[29:0], 2'b00};
            else shift_left_2_r = shift_left_1_r;

            if (b_i[2]) 
                shift_left_4_r = {shift_left_2_r[27:0], 4'h0};
            else shift_left_4_r = shift_left_2_r;

            if (b_i[3]) 
                shift_left_8_r = {shift_left_4_r[23:0], 8'h00};
            else shift_left_8_r = shift_left_4_r;

            if (b_i[4]) 
                out = {shift_left_8_r[15:0], 16'h0000};
            else out = shift_left_8_r;
        end

        `ALU_SRL, `ALU_SRA: begin
            if (a_i[31] == 1'b1 && op == `ALU_SRA)
                shift_right_fill_r = 16'b1111111111111111;
            else
                shift_right_fill_r = 16'b0000000000000000;

            if (b_i[0] == 1'b1)
                shift_right_1_r = {shift_right_fill_r[31], a_i[31:1]};
            else
                shift_right_1_r = a_i;

            if (b_i[1] == 1'b1)
                shift_right_2_r = {shift_right_fill_r[31:30], shift_right_1_r[31:2]};
            else
                shift_right_2_r = shift_right_1_r;

            if (b_i[2] == 1'b1)
                shift_right_4_r = {shift_right_fill_r[31:28], shift_right_2_r[31:4]};
            else
                shift_right_4_r = shift_right_2_r;

            if (b_i[3] == 1'b1)
                shift_right_8_r = {shift_right_fill_r[31:24], shift_right_4_r[31:8]};
            else
                shift_right_8_r = shift_right_4_r;

            if (b_i[4] == 1'b1)
                out = {shift_right_fill_r[31:16], shift_right_8_r[31:16]};
            else
                out = shift_right_8_r;
        end

        `ALU_ADD: begin
            out = a_i + b_i;
        end
        
        `ALU_SUB: begin
            out = a_i - b_i;
        end

        `ALU_AND: begin
            out = a_i & b_i;
        end

        `ALU_OR: begin
            out = a_i | b_i;
        end

        `ALU_XOR: begin
            out = a_i ^ b_i;
        end

        `ALU_SLTU: begin
            out = (a_i < b_i) ? 32'h1 : 32'h0;
        end

        `ALU_SLT: begin
            if (a_i[31]==b_i[31]) out = (a_i < b_i) ? 32'h1 : 32'h0;
            else out = a_i[31] ? 32'h1 : 32'h0;
        end

        `ALU_NONE: begin
            out = a_i;
        end

        default: begin
            out = a_i;
        end

    endcase

    if(op != `ALU_SLL) begin
        shift_left_1_r = a_i;
        shift_left_2_r = a_i;
        shift_left_4_r = a_i;
        shift_left_8_r = a_i;
    end

    if(op != `ALU_SRL && op != `ALU_SRA) begin
        shift_right_fill_r = 16'b0;
        shift_right_1_r = a_i;
        shift_right_2_r = a_i;
        shift_right_4_r = a_i;
        shift_right_8_r = a_i;
    end
end


endmodule
