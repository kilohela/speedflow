`timescale 1ns/1ps

module icache( 
    input               clk,
    input               rst,
    input               pipeline_en,
    input       [31:0]  pc,
    output reg  [31:0]  inst,
    output reg          valid
);

    import "DPI-C" function void dpi_icache(
        input  int pc, 
        output int inst, 
        output bit valid
    );
    
    always @(posedge clk) begin
        if(rst) begin
            valid = 1;
        end
        if(pipeline_en || valid==1'b0) begin
            dpi_icache(pc, inst, valid);
        end
    end
endmodule
