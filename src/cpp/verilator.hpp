#include "../obj_dir/Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h" 

class VerilatedObject{
public:
    VerilatedObject();
    rst_device();

private:
    Vtop *dut;
    VerilatedVcdC *vcd;

    void clk_cycle();
}


vcd = new VerilatedVcdC;
    dut = new Vtop;


    Verilated::traceEverOn(true);
    dut->trace(vcd, 99);
    vcd->open(vcd_file.c_str());