`timescale 1ns / 1ps

`include "defs.sv"

module decoder(
        input [31:0] inst_i,

        output logic [2:0] pc_ctrl, 
        output logic [2:0] imm_type, 
        output logic [3:0] mem_ctrl,

        output logic [3:0] alu_ctrl, 
        output logic [1:0] alu_a_sel, 
        output logic       alu_b_sel, 

        output logic       reg_w_en,
        output logic [1:0] reg_rd_sel,
        output logic [4:0] rs1,
        output logic [4:0] rs2,
        output logic [4:0] rd,

        output logic        csr_we,
        output logic [2:0]  func3,
        output logic [11:0] csr_addr,
        output logic        target_en,
        output logic        target_jump
    );

    import "DPI-C" function void stop_simulation();

assign rs1 = inst_i[19:15];
assign rs2 = inst_i[24:20];
assign rd  = inst_i[11:7];
assign func3 = inst_i[14:12];
assign csr_addr = inst_i[31:20];
    
wire [6:0] opcode = inst_i[6:0];
wire [6:0] func7 = inst_i[31:25];

assign target_en = (opcode == 7'b1100011 || opcode == 7'b1101111); // note: JALR: target_en = 0
assign target_jump = (opcode == 7'b1101111);

logic [20:0] ctrl_signals;

assign                              {pc_ctrl,    imm_type,   mem_ctrl,   alu_ctrl,   alu_a_sel,  alu_b_sel,  reg_w_en,   reg_rd_sel, csr_we} = ctrl_signals;
always @(*) begin
    case(opcode)
        7'b0110111: begin //LUI
                    ctrl_signals = {`PC_SNPC,   `IMM_U,     `MEM_NONE,  `ALU_ADD,   `ALU_a_0,   `ALU_b_imm, 1'b1,       `RD_ALU,     1'b0};    
        end

        7'b0010111: begin //AUIPC
                    ctrl_signals = {`PC_SNPC,   `IMM_U,     `MEM_NONE,  `ALU_ADD,   `ALU_a_pc,  `ALU_b_imm, 1'b1,       `RD_ALU,     1'b0};    
        end

        7'b1101111: begin //JAL
                    ctrl_signals = {`PC_J_pc,   `IMM_J,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_imm, 1'b1,       `RD_SNPC,    1'b0};    
        end

        7'b1100111: begin //JALR
                    ctrl_signals = {`PC_J_reg,  `IMM_I,     `MEM_NONE,  `ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,       `RD_SNPC,    1'b0};    
        end

        7'b1100011: begin //B-type instructions
            case(func3)
                3'b000: begin //BEQ
                    ctrl_signals = {`PC_B_inv,  `IMM_B,     `MEM_NONE,  `ALU_XOR,   `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};    
                end

                3'b001: begin //BNE
                    ctrl_signals = {`PC_B,      `IMM_B,     `MEM_NONE,  `ALU_XOR,   `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};    
                end

                3'b100: begin //BLT
                    ctrl_signals = {`PC_B,      `IMM_B,     `MEM_NONE,  `ALU_SLT,   `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};    
                end

                3'b101: begin //BGE
                    ctrl_signals = {`PC_B_inv,  `IMM_B,     `MEM_NONE,  `ALU_SLT,   `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};    
                end

                3'b110: begin //BLTU
                    ctrl_signals = {`PC_B,      `IMM_B,     `MEM_NONE,  `ALU_SLTU,  `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};    
                end

                3'b111: begin //BGEU
                    ctrl_signals = {`PC_B_inv,  `IMM_B,     `MEM_NONE,  `ALU_SLTU,  `ALU_a_reg1,`ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};
                end

                default: begin //error

                end

            endcase
        end

        7'b0000011: begin //I-type load instructions
            case(func3)
                3'b000: begin //LB
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_LOAD1, `ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_MEM,      1'b0};
                end

                3'b001: begin //LH
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_LOAD2, `ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_MEM,      1'b0};
                end

                3'b010: begin //LW
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_LOAD4, `ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_MEM,      1'b0};
                end

                3'b100: begin //LBU 
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_LOAD1U,`ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_MEM,      1'b0};
                end

                3'b101: begin //LHU 
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_LOAD2U,`ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_MEM,      1'b0};
                end

                default: begin //error

                end

            endcase
        end

        7'b0100011: begin //S-type instructions
            case(func3)
                3'b000: begin //SB
                    ctrl_signals = {`PC_SNPC,   `IMM_S,     `MEM_STORE1,`ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b0,      `RD_ALU,      1'b0};
                end

                3'b001: begin //SH 
                    ctrl_signals = {`PC_SNPC,   `IMM_S,     `MEM_STORE2,`ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b0,      `RD_ALU,      1'b0};
                end

                3'b010: begin //SW 
                    ctrl_signals = {`PC_SNPC,   `IMM_S,     `MEM_STORE4,`ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b0,      `RD_ALU,      1'b0};
                end

                default: begin //error

                end

            endcase
        end

        7'b0010011: begin //I-type calculative instructions
            case(func3)
                3'b000: begin //ADDI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_ADD,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b010: begin //SLTI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLT,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b011: begin //SLTIU
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLTU,  `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b100: begin //XORI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_XOR,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b110: begin //ORI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_OR,    `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b111: begin //ANDI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_AND,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                end

                3'b001: begin //SLLI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLL,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                
                end

                3'b101: begin //SRLI, SRAI
                    if (func7 == 7'b0000000) // SRLI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SRL,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};
                    else if (func7 == 7'b0100000) // SRAI
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SRA,   `ALU_a_reg1,`ALU_b_imm, 1'b1,      `RD_ALU,      1'b0};

                end


                default: begin //error

                end

            endcase
        end

        7'b0110011: begin //R-type instructions
            case(func3)
                3'b000: begin //ADD, SUB
                    if (func7 == 7'b0000000) // ADD
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_ADD,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                    else if (func7 == 7'b0100000) // SUB
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SUB,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b001: begin //SLL
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLL,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b010: begin //SLT
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLT,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b011: begin //SLTU   
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SLTU,  `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b100: begin //XOR
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_XOR,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b101: begin //SRL, SRA
                    if (func7 == 7'b0000000) // SRL
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SRL,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                    else if (func7 == 7'b0100000) // SRA
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_SRA,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                    else // NOP
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};
                end
                3'b110: begin //OR
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_OR,    `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                3'b111: begin //AND
                    ctrl_signals = {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_AND,   `ALU_a_reg1,`ALU_b_reg2,1'b1,      `RD_ALU,      1'b0};
                end

                default: begin //error

                end
            endcase
        end

        7'b0001111: begin //FENCE (not implemented)

        end

        7'b1110011: begin //system: ECALL, EBREAK, CSR
            if(inst_i == 32'h00100073) begin// EBREAK
                ctrl_signals =     {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};
                stop_simulation();
            end else if(inst_i == 32'h00000073) // ECALL
                ctrl_signals =     {`PC_TRAP,   `IMM_I,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_reg2,1'b0,      `RD_ALU,      1'b1};
            else if(|func3)// CSR
                ctrl_signals =     {`PC_SNPC,   `IMM_I,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_reg2,1'b1,      `RD_CSR,      1'b1};
            else if(inst_i == 32'h30200073) // mret
                ctrl_signals =     {`PC_EPC,    `IMM_I,     `MEM_NONE,  `ALU_NONE,  `ALU_a_0,   `ALU_b_reg2,1'b0,      `RD_ALU,      1'b0};
        end

        default: ;
    endcase

end

endmodule
