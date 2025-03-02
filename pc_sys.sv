`timescale 1ns / 1ps

`include "defs.sv"

module pc_sys(
        input clk,
        input [2:0] pc_ctrl,
        input rst_n,
        input alu_o, // |alu_out
        input [31:0] rs1,
        input [31:0] offset, // imm
        input [31:0] epc,
        input [31:0] mtvec,

        output wire [31:0] snpc,
        output reg [31:0] dnpc
    );
    wire [31:0] pc = dnpc;
    assign snpc = pc + `INST_LENTH;

    always @(posedge clk) begin
        if (!rst_n) begin
            dnpc <=  `PC_INITIAL_ADDRESS;
        end
        else begin
            case (pc_ctrl)
            `PC_SNPC:
                dnpc <= snpc;
            `PC_J_pc:
                dnpc <= pc + offset;
            `PC_J_rs1:
                dnpc <= rs1 + offset;
            `PC_B:
                if (alu_o) dnpc <= pc + offset;
                else dnpc <= snpc;
            `PC_B_inv:
                if (!alu_o) dnpc <= pc + offset;
                else dnpc <= snpc;
            `PC_EPC:
                dnpc <= epc;
            `PC_TRAP:
                dnpc <= mtvec;
            default:
                dnpc <= pc;
            endcase
        end
    end
endmodule
