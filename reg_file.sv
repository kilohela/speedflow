`timescale 1ns / 1ps

module reg_file(
        input clk,
        input rst_n,
        input [4:0] rs1_addr,
        input [4:0] rs2_addr,
        input [4:0] rd_addr,
        input [31:0] write_data,
        input write_en,
        output reg [31:0] rs1,
        output reg [31:0] rs2
    );
    reg  [31:0] gpr [15:0] /*verilator public_flat*/ ;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gpr[0] <= 32'h0;
            gpr[1] <= 32'h0;
            gpr[2] <= 32'h0;
            gpr[3] <= 32'h0;
            gpr[4] <= 32'h0;
            gpr[5] <= 32'h0;
            gpr[6] <= 32'h0;
            gpr[7] <= 32'h0;
            gpr[8] <= 32'h0;
            gpr[9] <= 32'h0;
            gpr[10] <= 32'h0;
            gpr[11] <= 32'h0;
            gpr[12] <= 32'h0;
            gpr[13] <= 32'h0;
            gpr[14] <= 32'h0;
            gpr[15] <= 32'h0;
        end
        else if (write_en && rd_addr != 0) begin
            gpr[rd_addr[3:0]] <= write_data;
        end
    end

    assign rs1 = gpr[rs1_addr[3:0]];
    assign rs2 = gpr[rs2_addr[3:0]];
    
endmodule
