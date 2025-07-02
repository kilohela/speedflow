`timescale 1ns/1ps

module forwarding(
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] wb_rd,
    input       wb_reg_wen,
    output bypass_reg1,
    output bypass_reg2
);

assign bypass_reg1 = wb_reg_wen && ex_rs1 == wb_rd && wb_rd != 5'b0;
assign bypass_reg2 = wb_reg_wen && ex_rs2 == wb_rd && wb_rd != 5'b0;


endmodule