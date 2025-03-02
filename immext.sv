`timescale 1ns / 1ps
`include "defs.sv"

module immext(
    input [31:7] inst,
    input [2:0] imm_type,
    output logic [31:0] ext
);

always_comb begin
    case(imm_type)

    `IMM_I: ext = {{21{inst[31]}}, inst[30:20]};
    `IMM_S: ext = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    `IMM_B: ext = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    `IMM_U: ext = {inst[31:12], 12'b0};
    `IMM_J: ext = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
    
    default: ext = 32'b0;
    endcase
end

endmodule
