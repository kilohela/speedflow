`timescale 1ns / 1ps

module reg_file(
        input clk,
        input rst,
        input pipeline_en,
        input [4:0] rs1,
        input [4:0] rs2,
        input [4:0] rd,
        input [31:0] wdata,
        input wen,
        output wire [31:0] reg1,
        output wire [31:0] reg2
    );
    reg  [31:0] gpr [31:0];

    always_ff @(posedge clk) begin
        if (rst) begin
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
            gpr[16] <= 32'h0;
            gpr[17] <= 32'h0;
            gpr[18] <= 32'h0;
            gpr[19] <= 32'h0;
            gpr[20] <= 32'h0;
            gpr[21] <= 32'h0;
            gpr[22] <= 32'h0;
            gpr[23] <= 32'h0;
            gpr[24] <= 32'h0;
            gpr[25] <= 32'h0;
            gpr[26] <= 32'h0;
            gpr[27] <= 32'h0;
            gpr[28] <= 32'h0;
            gpr[29] <= 32'h0;
            gpr[30] <= 32'h0;
            gpr[31] <= 32'h0;
        end
        else if (pipeline_en && wen && rd != 0) begin
            gpr[rd] <= wdata;
        end
    end

    // internal write bypass
    assign reg1 = (wen && rs1 == rd && |rd)?wdata:gpr[rs1];
    assign reg2 = (wen && rs2 == rd && |rd)?wdata:gpr[rs2];
    
endmodule
