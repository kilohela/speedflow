`timescale 1ns/1ps

`include "defs.sv"

// used for branch prediction and give pc
module pred(
    input               clk,
    input               rst,
    input               pipeline_en,
    input       [7:0]   ex_pc7_0,
    input       [31:0]  ex_dnpc, // calculated in excute stage (comb out)
    input               is_ex_br, // if this is a branch(ex stage)
    input               is_br_taken, // if the branch is taken (enabled when pc_sys calculated the result)
    input       [31:0]  id_target,
    input               id_target_en, // enable id_target, which means a branch or jump instruction
    input               id_target_jump, // unconditional jump
    input       [31:0]  id_pc,

    output reg  [31:0]  pc_out, // pc to the icache
    output wire         id_invalid // when id_invalid == 1 , means prediction error, control logic should disable instruction in 1(decode) stage
);

    reg         [7:0]   BHT_addr; // Branch History Table
    reg                 BHT_tag;  // taken or not

    reg         [1:0]   work_state;
    wire                id_correct;
    wire                predict_taken;

    localparam S_VII = 2'd0;
    localparam S_PVI = 2'd2;
    localparam S_XPV = 2'd3;

    always @(posedge clk) begin
        if(rst) begin
            work_state <= S_VII;
        end
        else if(pipeline_en) begin 
            case(work_state)
            S_VII: work_state <= S_PVI;
            S_PVI: work_state <= S_XPV;
            S_XPV: begin
                if(!id_correct) begin // VIV
                    work_state <= S_PVI;
                end // else PVV, keep the state
                if(is_ex_br) begin
                    BHT_addr <= ex_pc7_0;
                    BHT_tag  <= is_br_taken;
                end
            end
            default work_state <= S_VII; 
            endcase
        end 
    end

    always @(*) begin
        case(work_state)
        S_VII: pc_out = `PC_INITIAL_ADDRESS;
        S_PVI: pc_out = id_target_jump?id_target:
                    (predict_taken?id_target:(id_pc+4));
        S_XPV: if(!id_correct) pc_out = ex_dnpc; // VIV
            else pc_out =   id_target_jump?id_target: // PVV
                            (predict_taken?id_target:(id_pc+4));
        default: pc_out = `PC_INITIAL_ADDRESS;
        endcase
    end

    assign id_correct = (id_pc==ex_dnpc); // the predicted inst in id stage is correct
    assign predict_taken = id_target_en & (id_pc[7:0] == BHT_addr) & BHT_tag;
    assign id_invalid = (work_state == S_XPV && !id_correct);
endmodule
