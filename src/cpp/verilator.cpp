#include "verilator.hpp"

class VerilatedObject{
    
}

void clk_cycle(){
    dut->clk = 0;
    dut->eval();
    if(sim_time < max_vcd_time)vcd->dump(sim_time++);

    dut->clk = 1;
    dut->eval();
    if(sim_time < max_vcd_time)vcd->dump(sim_time++);
}

void rst_device(){
    dut->rst_n = 1;
    clk_cycle();
    dut->rst_n = 0;
    clk_cycle();
    dut->rst_n = 1;
}