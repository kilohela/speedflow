`timescale 1ns/1ps

module icache( 
    input               clk,
    input               rst,
    input               pipeline_en,
    input       [31:0]  pc,
    output reg  [31:0]  inst,
    output wire         valid
);

    import "DPI-C" function void dpi_icache(
        input  int pc, 
        output int inst
    );

    import "DPI-C" function bit dpi_icache_valid(
        input  int pc
    );

    reg [31:0] id_pc;

    assign valid = dpi_icache_valid(pc);
    
    always @(posedge clk) begin
        if(rst) begin
            id_pc <= `PC_INITIAL_ADDRESS;
        end
        if(pipeline_en || valid==1'b0) begin
            id_pc <= pc;
        end
    end

    always_comb begin
        dpi_icache(id_pc, inst);
    end
endmodule
