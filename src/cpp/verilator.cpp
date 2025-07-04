#include "verilator.hpp"

namespace verilator{

    Dut::Dut(const char* vcd_path, const int max_vcd_time) : max_vcd_time(max_vcd_time){
        dut = new Vtop;
        vcd = nullptr;
        if(vcd_path){
            Verilated::traceEverOn(true);
            vcd = new VerilatedVcdC;
            dut->trace(vcd, 99);
            vcd->open(vcd_path);
        }
    }

    Dut::~Dut(){
        delete dut;
        delete vcd;
    }

    void Dut::clk_cycle(){
        dut->clk = 0;
        dut->eval();
        if(vcd && sim_time < max_vcd_time)vcd->dump(sim_time++);

        dut->clk = 1;
        dut->eval();
        if(vcd && sim_time < max_vcd_time)vcd->dump(sim_time++);
    }

    void Dut::rst_device(){
        dut->rst = 0;
        clk_cycle();
        dut->rst = 1;
        clk_cycle();
        dut->rst = 0;
    }

}

