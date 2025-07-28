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
    output wire         valid
);

    import "DPI-C" function void dpi_dcache(
        input bit ren, 
        input int addr, 
        input int rwidth, 
        input bit rsign, 
        output int rdata, 
        input bit wen, 
        input int wwidth, 
        input int wdata
    );

    import "DPI-C" function bit dpi_dcache_valid(
        input int addr,
        input bit en
    );

    assign valid = dpi_dcache_valid(addr, ren || wen);

    reg        _ren;    
    reg [31:0] _addr;
    reg [2:0]  _rwidth;
    reg        _rsign;
    reg        _wen; 
    reg [2:0]  _wwidth;
    reg [31:0] _wdata;

    always @(posedge clk) begin
        if(rst) begin
            _ren <= 0;
            _wen <= 0;
        end
        else if(pipeline_en || valid == 1'b0) begin
            _ren    <= ren;   
            _addr   <= addr;  
            _rwidth <= rwidth;
            _rsign  <= rsign; 
            _wen    <= wen;   
            _wwidth <= wwidth;
            _wdata  <= wdata;
        end
    end

    always_comb begin
        dpi_dcache(
                _ren,
                _addr,
                {29'b0, _rwidth},
                _rsign,
                rdata,
                _wen,
                {29'b0, _wwidth},
                _wdata
        );
    end


endmodule
