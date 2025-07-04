#include <cstdio>
#include "MemSys.hpp"

extern Memory memory;
extern DCache dcache;
extern ICache icache;

bool simulation_on = true;

extern "C" void stop_simulation(){
    simulation_on = false;
}

void speedflow_mainloop(){
    while(1){
        
    }
}





int main(int argc, char **argv, char **env) {

    // please read decument or makefile for argument parse reference

    if(argc != 3){
        printf("Please input image file name\n");
        return 1;
    }

    // instantiate vcd, log, dut, random seed, init memory and reset device
    char*& image_path = argv[1];
    char*& vcd_path   = argv[2];
    char*& log_path   = argv[3];

    // init seed, there is no randomness now, skip

    // memory is already in global variable instantiation, skip memory initialization

    // start simulation
    int sim_time = 0;
    int sim_cycle = 0;
    rst_device();
    // run simulation for many clock cycles
    speedflow_mainloop();

    return 0;
}