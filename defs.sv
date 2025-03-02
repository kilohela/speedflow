`define INST_LENTH                              4


//--------------------------------------------------------------------
// ALU Operations
//--------------------------------------------------------------------
`define ALU_NONE                                4'b0000
`define ALU_SLL                                 4'b0001
`define ALU_SRL                                 4'b0010
`define ALU_SRA                                 4'b0011
`define ALU_ADD                                 4'b0100
`define ALU_SUB                                 4'b0110
`define ALU_AND                                 4'b0111
`define ALU_OR                                  4'b1000
`define ALU_XOR                                 4'b1001
`define ALU_SLTU                                4'b1010
`define ALU_SLT                                 4'b1011


//--------------------------------------------------------------------
// ALU Sources
//--------------------------------------------------------------------
`define ALU_a_pc                                 2'b01
`define ALU_a_0                                  2'b10
`define ALU_a_rs1                                2'b00

`define ALU_b_rs2                                1'b1
`define ALU_b_imm                                1'b0


//--------------------------------------------------------------------
// PC Control (pc_ctrl) and reset
//--------------------------------------------------------------------
`define PC_SNPC                                 3'b000           // PC += 4
`define PC_J_pc                                 3'b100           // PC += offset
`define PC_J_rs1                                3'b101           // PC  = rs1+offset
`define PC_B                                    3'b010           // PC += offset or PC += 4 depends on alu result[0]
`define PC_B_inv                                3'b011           // PC += offset or PC += 4 depends on alu result[0] inverted
`define PC_EPC                                  3'b110           // PC  = epc (now mepc)
`define PC_TRAP                                 3'b111           // PC  = mtvec

`define PC_INITIAL_ADDRESS                      32'h80000000


//--------------------------------------------------------------------
// rd source
//--------------------------------------------------------------------
`define RD_ALU                                 2'b00          // from ALU Result
`define RD_MEM                                 2'b01          // from Memory
`define RD_SNPC                                2'b10          // PC + 4
`define RD_CSR                                 2'b11          // from CSR


//--------------------------------------------------------------------
// ImmType
//--------------------------------------------------------------------
`define IMM_I                                   3'b001
`define IMM_S                                   3'b010
`define IMM_B                                   3'b011
`define IMM_U                                   3'b100
`define IMM_J                                   3'b101


//--------------------------------------------------------------------
// Memory
//--------------------------------------------------------------------
`define MEM_NONE                                4'b1100
`define MEM_INIT                                4'b1111
`define MEM_LOAD1                               4'b0000
`define MEM_LOAD2                               4'b0001
`define MEM_LOAD4                               4'b0010
`define MEM_LOAD1U                              4'b0100
`define MEM_LOAD2U                              4'b0101
`define MEM_STORE1                               4'b1000
`define MEM_STORE2                               4'b1001
`define MEM_STORE4                               4'b1010
    
//--------------------------------------------------------------------
// CSR Operations (func3)
//--------------------------------------------------------------------
`define CSRRW                                  3'b001
`define CSRRWI                                 3'b101
`define CSRRS                                  3'b010
`define CSRRSI                                 3'b110
`define CSRRC                                  3'b011
`define CSRRCI                                 3'b111
`define CSR_ECALL                              3'b000
