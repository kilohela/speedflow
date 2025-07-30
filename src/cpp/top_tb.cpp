#include <cstdio>
#include <csignal>
#include <spdlog/common.h>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include "MemSys.hpp"
#include "verilator.hpp"
#include "device.hpp"

extern Memory memory;
extern DeviceManager device_manager;

bool simulation_on = true;

extern "C" void stop_simulation(){
    spdlog::info("stop simulation");
    simulation_on = false;
}

std::shared_ptr<spdlog::logger> global_logger;

void log_dump(int signum){
    spdlog::dump_backtrace();
    global_logger->flush();
}

int main(int argc, char **argv, char **env) {
    spdlog::set_level(spdlog::level::info);
    // please read decument or makefile for argument parse reference

    signal(SIGSEGV, log_dump);

    if(argc != 4){
        spdlog::error("Parameter list error.\n");
        return 1;
    }

    // instantiate vcd, log, dut, random seed, init memory and reset device
    char*& image_path = argv[1];
    char*& vcd_path   = argv[2];
    char*& log_path   = argv[3];

    spdlog::info("Switching logger...");
    global_logger = spdlog::rotating_logger_mt("global_logger", argv[3], 3*1024*1024, 3);
    spdlog::set_default_logger(global_logger);
    spdlog::set_level(spdlog::level::debug);

    // init seed, there is no randomness now, skip

    // init devices
    spdlog::info("Registering devices...");
    device_manager.DeviceRegister(new Serial);
    device_manager.DeviceRegister(new Timer);

    // instantiate and init memory system
    spdlog::info("Initializing memory with image: {}", image_path);
    memory.init(image_path, memory_map::kPhysical);

    // start simulation
    int max_cycle = 1000000000;
    int max_vcd_time = 500;

    spdlog::info("Creating device instantiation...");
    verilator::Dut dut(vcd_path, max_vcd_time);

    spdlog::info("Resetting device...");
    dut.rst_device();

    // run simulation for many clock cycles
    spdlog::info("Clock cycles start");
    for(int cycle = 1; cycle <= max_cycle && simulation_on; cycle++){
        dut.clk_cycle();
    }

    if(simulation_on) spdlog::warn("simulation timed out");
    return 0;
}