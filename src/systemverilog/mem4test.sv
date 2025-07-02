`timescale 1ns / 1ps

`include "defs.sv"
module mem4test(
    input clk,
    input [3:0] mem_ctrl,
    input [31:0] addr,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] pmem [0:255];
    always @(*) begin
        data_out = pmem[addr[7:2]];
    end

    always @(posedge clk) begin
        if(mem_ctrl == `MEM_STORE1 || mem_ctrl == `MEM_STORE2 || mem_ctrl == `MEM_STORE4) begin
            pmem[addr[7:2]] <= data_in;
        end
    end
endmodule
