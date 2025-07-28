#include <cstdio>
#include <spdlog/common.h>
#include <spdlog/spdlog.h>
#include "MemSys.hpp"
#include "verilator.hpp"

extern Memory memory;
extern DCache dcache;
extern ICache icache;

bool simulation_on = true;

extern "C" void stop_simulation(){
    spdlog::info("stop simulation");
    simulation_on = false;
}

int main(int argc, char **argv, char **env) {
    spdlog::set_pattern("[%^%l%$] %v");
    spdlog::set_level(spdlog::level::info);
    // please read decument or makefile for argument parse reference

    if(argc != 4){
        spdlog::error("Parameter list error.\n");
        return 1;
    }

    // instantiate vcd, log, dut, random seed, init memory and reset device
    char*& image_path = argv[1];
    char*& vcd_path   = argv[2];
    char*& log_path   = argv[3];

    // init seed, there is no randomness now, skip

    // instantiate and init memory system
    spdlog::info("Initializing memory...");
    spdlog::debug("No need to initailize memory");
    spdlog::info("Success!");

    // start simulation
    int max_cycle = 2000;
    int max_vcd_time = 100000;

    spdlog::info("Creating device instantiation...");
    verilator::Dut dut(vcd_path, max_vcd_time);
    spdlog::info("Success!");

    spdlog::info("Resetting device...");
    dut.rst_device();
    spdlog::info("Success!");

    // run simulation for many clock cycles
    spdlog::info("Clock cycles start");
    for(int cycle = 1; cycle <= max_cycle && simulation_on; cycle++){
        dut.clk_cycle();
    }

    if(simulation_on) spdlog::warn("simulation timed out");
    return 0;
}