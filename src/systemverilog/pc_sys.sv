`timescale 1ns / 1ps

`include "defs.sv"

// calculate the correct dnpc of given inst
module pc_sys(
        input [31:0] pc, 
        input [2:0] pc_ctrl,
        input alu_o, // |alu_out
        input [31:0] reg1,
        input [31:0] offset, // imm
        input [31:0] epc,
        input [31:0] mtvec,

        output reg [31:0] dnpc,
        output wire       is_br,
        output wire       is_br_taken
    );
    wire [31:0] snpc;
    assign snpc = pc + `INST_LENTH;
    assign is_br = ((pc_ctrl == `PC_B) || (pc_ctrl == `PC_B_inv));
    assign is_br_taken = (((pc_ctrl == `PC_B) && alu_o) || ((pc_ctrl == `PC_B_inv) && !alu_o));

    always_comb begin
        case (pc_ctrl)
        `PC_SNPC:
            dnpc = snpc;
        `PC_J_pc:
            dnpc = pc + offset;
        `PC_J_reg:
            dnpc = reg1 + offset;
        `PC_B:
            if (alu_o) begin 
                dnpc = pc + offset;
            end
            else begin 
                dnpc = snpc;
            end
        `PC_B_inv:
            if (!alu_o) begin 
                dnpc = pc + offset;
            end
            else begin 
                dnpc = snpc;
            end
        `PC_EPC:
            dnpc = epc;
        `PC_TRAP:
            dnpc = mtvec;
        default: // error, should not reach here!
            dnpc = pc;
            // $error("module pc_sys error: invalid pc_ctrl value.");
        endcase
    end
endmodule
