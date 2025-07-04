`timescale 1ns / 1ps
// simulate sram, data out will renew after clk positive edge
// a simple implemtation
module dcache( 
    input               clk,
    input               rst,
    input               pipeline_en,
    input               ren,
    input       [31:0]  addr,
    input       [2:0]   rwidth,
    input               rsign, // 0 means 0-ext, 1 means sign-ext
    output reg  [31:0]  rdata,
    input               wen,
    input       [2:0]   wwidth,
    input       [31:0]  wdata,
    output reg          valid // (waddr/raddr --> wvalid/rvalid) signal chain should be combinational and change within one cycle(before clk), this signal is used to stall pipeline
);

    import "DPI-C" function void dpi_dcache(
        input bit ren, 
        input int addr, 
        input int rwidth, 
        input bit rsign, 
        output int rdata, 
        input int wen, 
        input int wwidth, 
        input int wdata, 
        output bit valid
    );

    always @(wen, ren, addr) begin
        if(wen || ren) valid = dpi_dcache_is_hit(addr);
        else valid = 1;
    end
    always @(posedge clk) begin
        if(rst) begin
            
        end
        else if(pipeline_en || valid == 1'b0) begin
            dpi_dcache(
                ren,
                raddr,
                rwidth,
                rsign,
                rdata,
                wen,
                waddr,
                wwidth,
                wdata,
                valid
            );
        end
    end


endmodule
