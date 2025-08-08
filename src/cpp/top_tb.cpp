#include <cstdint>
#include <cstdio>
#include <csignal>
#include <spdlog/common.h>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <CLI/CLI.hpp>
#include "MemSys.hpp"
#include "verilator.hpp"
#include "device.hpp"

extern Memory memory;
extern DCache dcache;
extern ICache icache;
extern DeviceManager device_manager;
void print_report();

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

void sigint_handler(int signum){
    simulation_on = false;
    stop_cause = StopCause::KEYBOARD_INTERRUPT;
}

bool keep_running, log_stdout;
long long max_cycle;
std::string waveform_path, log_path, image_path, report_path;
int random_seed, wave_time;

int main(int argc, char **argv, char **env) {
    spdlog::set_level(spdlog::level::info);

    CLI::App app ("speedflow riscv simulator");
    app.add_flag("-k,--keep", keep_running, "run infinite cycles") -> default_val(false);
    app.add_flag("--log-stdout", log_stdout, "output log to stdout") -> default_val(false);

    app.add_option("-c,--cycles", max_cycle, "set the max cycle") -> default_val(1000000000);
    app.add_option("-w,--wave", waveform_path, "set the waveform path") -> default_val("");
    app.add_option("--wave-time", wave_time, "set the max time of waveform tracer") -> default_val(500);
    app.add_option("-l,--log", log_path, "set the log path") -> default_val("");
    app.add_option("-r,--report", report_path, "set cache report path") ->default_val("");
    app.add_option("-i,--image", image_path, "set the image path") -> required();
    app.add_option("-s,--seed", random_seed, "set the random seed for emulation") -> default_val(0);

    CLI11_PARSE(app, argc, argv);

    signal(SIGINT, sigint_handler);

    // instantiate vcd, log, dut, random seed, init memory and reset device

    if(!log_path.empty()){
        spdlog::info("log will be written to: {}", log_path);
        global_logger = spdlog::rotating_logger_mt("global", log_path, 3*1024*1024, 3);
        spdlog::set_default_logger(global_logger);
        spdlog::set_level(spdlog::level::debug);
    }
    else if(!log_stdout){
        spdlog::set_level(spdlog::level::off);
    }

    // init devices
    spdlog::info("Registering devices...");
    device_manager.DeviceRegister(new Serial);
    device_manager.DeviceRegister(new Timer);

    // instantiate and init memory system
    spdlog::info("Initializing memory with image: {}", image_path);
    memory.init(image_path, memory_map::kPhysical);

    // start simulation

    spdlog::info("Creating device instantiation...");
    verilator::Dut dut(waveform_path, wave_time);

    spdlog::info("Resetting device...");
    dut.rst_device();

    // run simulation for many clock cycles
    spdlog::info("Clock cycles start");
    for(long long cycle = 1; cycle <= max_cycle && simulation_on; cycle++){
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