#include <cstdint>
#include <cstdio>
#include <csignal>
#include <fmt/core.h>
#include <spdlog/common.h>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include "MemSys.hpp"
#include "verilator.hpp"
#include "device.hpp"

extern Memory memory;
extern DCache dcache;
extern ICache icache;
extern DeviceManager device_manager;

bool simulation_on = true;

enum class StopCause {
    NONE,
    EBREAK,
    TIME_OUT,
    KEYBOARD_INTERRUPT,
} stop_cause;

extern "C" void stop_simulation(){
    simulation_on = false;
    stop_cause = StopCause::EBREAK;
}

std::shared_ptr<spdlog::logger> global_logger;

void print_report(){
    FILE* f = fopen("out/cache_report.txt", "w");
    fmt::print(f, "========================================\n");
    fmt::print(f, "        DCache Report\n");
    fmt::print(f, "========================================\n");
    fmt::print(f, "Cache Way Count:        {:10}\n", kCacheWayCount);
    fmt::print(f, "Cache Set Count:        {:10}\n", kCacheSetCount);
    fmt::print(f, "Cache Block Size:       {:10}\n", kCacheBlockSize);
    fmt::print(f, "Cache Total Size:       {:9}K\n", kCacheBlockSize * kCacheSetCount * kCacheWayCount /1024);
    fmt::print(f, "Read total:             {:10}\n", dcache.read_total);
    fmt::print(f, "Read hit:               {:10}\n", dcache.read_hit);
    fmt::print(f, "Read miss:              {:10}\n", dcache.read_miss);
    fmt::print(f, "Read miss rate:         {:9.6f}%\n", (double)(dcache.read_miss)/dcache.read_total*100);
    fmt::print(f, "Write total:            {:10}\n", dcache.write_total);
    fmt::print(f, "Write hit:              {:10}\n", dcache.write_hit);
    fmt::print(f, "Write miss:             {:10}\n", dcache.write_miss);
    fmt::print(f, "Write miss rate:        {:9.6f}%\n", (double)(dcache.write_miss)/dcache.write_total*100);
    fmt::print(f, "Total miss rate:        {:9.6f}%\n", (double)(dcache.write_miss + dcache.read_miss)/(dcache.write_total+dcache.read_total)*100);
    fmt::print(f, "Note, a read/write across two blocks will count as one read/write total, but might add 2 r/w hit or miss. Total miss rate is calculated by real miss handle count / total access count.");
    fmt::print(f, "\n\n\n");
    fmt::print(f, "========================================\n");
    fmt::print(f, "        ICache Report\n");
    fmt::print(f, "========================================\n");
    fmt::print(f, "Cache Way Count:        {:10}\n", kCacheWayCount);
    fmt::print(f, "Cache Set Count:        {:10}\n", kCacheSetCount);
    fmt::print(f, "Cache Block Size:       {:10}\n", kCacheBlockSize);
    fmt::print(f, "Cache Total Size:       {:9}K\n", kCacheBlockSize * kCacheSetCount * kCacheWayCount /1024);
    fmt::print(f, "Read total:             {:10}\n", icache.read_total);
    fmt::print(f, "Read hit:               {:10}\n", icache.read_hit);
    fmt::print(f, "Read miss:              {:10}\n", icache.read_miss);
    fmt::print(f, "Read miss rate:         {:9.6f}%\n", (double)(icache.read_miss)/icache.read_total*100);
    fclose(f);
}

void sigint_handler(int signum){
    simulation_on = false;
    stop_cause = StopCause::KEYBOARD_INTERRUPT;
}

int main(int argc, char **argv, char **env) {
    spdlog::set_level(spdlog::level::info);
    // please read decument or makefile for argument parse reference

    signal(SIGINT, sigint_handler);

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
    uint32_t max_cycle = -1; // -1 means infinite
    int max_vcd_time = 500;

    spdlog::info("Creating device instantiation...");
    verilator::Dut dut(vcd_path, max_vcd_time);

    spdlog::info("Resetting device...");
    dut.rst_device();

    // run simulation for many clock cycles
    spdlog::info("Clock cycles start");
    for(uint32_t cycle = 1; cycle <= max_cycle && simulation_on; cycle++){
        dut.clk_cycle();
    }

    if(simulation_on) stop_cause = StopCause::TIME_OUT;
    switch (stop_cause) {
    case StopCause::EBREAK: 
        spdlog::info("Simulation stopped by software");
        break;
    case StopCause::TIME_OUT:
        spdlog::warn("Simulation timed out");
        break;
    case StopCause::KEYBOARD_INTERRUPT:
        spdlog::warn("Simulation stopped by keyboard interrupt");
        break;
    default:
        spdlog::error("Simulation stopped by unknown event");
        break;
    }
    
    print_report();
    return 0;
}