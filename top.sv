`timescale 1ns / 1ps

`include "defs.sv"

module top(
        input clk,
        input rst_n,
    );

    logic [31:0]         inst;
    logic [31:0]         pc;
    logic [2:0]          pc_ctrl;
    logic [31:0]         snpc;

    logic                reg_w_en;
    logic [4:0]          rd_addr; assign rd_addr = inst[11:7];
    logic [1:0]          reg_rd_sel;
    logic [31:0]         rd;
    logic [4:0]          rs1_addr; assign rs1_addr = inst[19:15];
    logic [31:0]         rs1;
    logic [4:0]          rs2_addr; assign rs2_addr = inst[24:20];
    logic [31:0]         rs2;

    logic [3:0]          mem_ctrl;
    logic [31:0]         mem_o;

    logic [2:0]          imm_type;
    logic [31:0]         imm;

    logic [3:0]          alu_ctrl;
    logic [31:0]         alu_a;
    logic [1:0]          alu_a_sel;
    logic [31:0]         alu_b;
    logic                alu_b_sel;
    logic [31:0]         alu_o;
    
    logic                csr_we;
    logic [31:0]         csr;
    logic [11:0]         csr_addr; assign csr_addr = inst[31:20];
    logic [31:0]         mtvec;
    logic [31:0]         mepc;

    always @ (*) begin
        case(alu_a_sel)
            `ALU_a_rs1: alu_a = rs1;
            `ALU_a_0: alu_a = 0;
            `ALU_a_pc: alu_a = pc;
            default: alu_a = 0;
        endcase
    end

    always @ (*) begin
        case(alu_b_sel)
            `ALU_b_rs2: alu_b = rs2;
            `ALU_b_imm: alu_b = imm;
            default: alu_b = 0;
        endcase
    end

    always @ (*) begin
        case(reg_rd_sel)
            `RD_ALU: rd = alu_o;
            `RD_MEM: rd = mem_o;
            `RD_SNPC: rd = snpc;
            `RD_CSR: rd = csr;
            default: rd = 0;
        endcase
    end

    pc_sys u_pc(
        .clk(clk),
        .rst_n(rst_n),
        .pc_ctrl(pc_ctrl),
        .alu_o(|alu_o),
        .rs1(rs1),
        .offset(imm),

        .snpc(snpc),
        .dnpc(pc), // pc to be excecuted

        .mtvec(mtvec),
        .epc(mepc)
    );

    alu u_alu(
        .op(alu_ctrl),
        .a_i(alu_a),
        .b_i(alu_b),

        .out(alu_o)
    );

    immext u_imm(
        .inst(inst[31:7]),
        .imm_type(imm_type),
        .ext(imm)
    );

    mem4test u_data(
        .clk(clk),
        .mem_ctrl(mem_ctrl),
        
        .addr(alu_o),
        .data_in(rs2),
        .data_out(mem_o)
    );

    mem4test u_inst(
        .clk(clk),
        .mem_ctrl(`MEM_LOAD4),

        .addr(pc),
        .data_in(32'hDEADBEEF),
        .data_out(inst)
    );

    reg_file u_reg_file(
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .write_data(rd),
        .write_en(reg_w_en),
        
        .rs1(rs1),
        .rs2(rs2)
    );

    decoder u_decoder(
        .inst_i(inst),

        .pc_ctrl(pc_ctrl),
        .imm_type(imm_type),
        .mem_ctrl(mem_ctrl),
        
        .alu_ctrl(alu_ctrl),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        
        .reg_w_en(reg_w_en),
        .reg_rd_sel(reg_rd_sel),
        .csr_we(csr_we)
    );

    csr_file u_csr_file(
        .clk(clk),
        .rst_n(rst_n),
        .csr_we(csr_we),
        .sys_func(inst[14:12]),
        .rs1_imm(rs1_addr),
        .src1(rs1),
        .pc(pc),
        .csr_addr(csr_addr),
        .csr(csr),
        .mepc_out(mepc),
        .mtvec_out(mtvec)
    );

endmodule
