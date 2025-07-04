#include <cstdio>
#include "MemSys.hpp"
#include "verilator.hpp"

extern Memory memory;
extern DCache dcache;
extern ICache icache;

bool simulation_on = true;

extern "C" void stop_simulation(){
    simulation_on = false;
}

int main(int argc, char **argv, char **env) {

    // please read decument or makefile for argument parse reference

    if(argc != 3){
        printf("Parameter list error.\n");
        return 1;
    }

    // instantiate vcd, log, dut, random seed, init memory and reset device
    char*& image_path = argv[1];
    char*& vcd_path   = argv[2];
    char*& log_path   = argv[3];

    // init seed, there is no randomness now, skip

    // memory is already in global variable instantiation, skip memory initialization

    // start simulation
    int max_cycle = 50000;
    int max_vcd_time = 100000;

    verilator::Dut dut(vcd_path, max_vcd_time);
    dut.rst_device();
    // run simulation for many clock cycles
    for(int cycle = 1; cycle <= max_cycle; cycle++){
        dut.clk_cycle();
    }

    return 0;
}