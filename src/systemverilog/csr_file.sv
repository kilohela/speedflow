`timescale 1ns / 1ps
`include "defs.sv"
module csr_file(
    input wire clk,
    input wire rst,
    input wire pipeline_en,
    input wire csr_we,
    input wire [2:0] func3,
    input wire [4:0] rs1,
    input wire [31:0] reg1,
    input wire [31:0] pc,
    input wire [11:0] csr_addr,
    // output reg [31:0] mstatus,
    output reg [31:0] csr,
    output wire [31:0] mepc_out,
    output wire [31:0] mtvec_out
);
    reg [31:0] mepc;
    reg [31:0] mtvec;
    reg [31:0] mcause;
    reg [31:0] mstatus;

    assign mepc_out = mepc;
    assign mtvec_out = mtvec;


    always_comb begin
        case (csr_addr)
            12'h300: csr = mstatus;
            12'h341: csr = mepc;
            12'h305: csr = mtvec;
            12'h342: csr = mcause;
            default: csr = 32'h0000_0000;
        endcase
    end

    reg [31:0] csr_wdata;
    always_comb begin
        case (func3)
            `CSRRW:  csr_wdata = reg1;
            `CSRRWI: csr_wdata = {27'b0, rs1};
            `CSRRS:  csr_wdata = reg1 | csr;
            `CSRRSI: csr_wdata = {27'b0, rs1} | csr;
            `CSRRC:  csr_wdata = ~reg1 & csr;
            `CSRRCI: csr_wdata = ~{27'b0, rs1} & csr;
            default: csr_wdata = 32'h0000_0000;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mepc    <= 32'h0000_0000;
            mtvec   <= 32'h0000_0000;
            mcause  <= 32'h0000_0000;
            mstatus <= 32'h0000_0000;
        end else if (pipeline_en && csr_we) begin
            if(func3 != `CSR_ECALL) begin 
                case (csr_addr)
                    12'h300: mstatus <= csr_wdata;
                    12'h341: mepc    <= csr_wdata;
                    12'h305: mtvec   <= csr_wdata;
                    12'h342: mcause  <= csr_wdata;
                    default: ;
                endcase
            end else begin
                mepc <= pc;
                mcause <= 32'd11;
            end
        end
    end

endmodule
