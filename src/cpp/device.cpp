#include <cstdint>
#include <cstdio>
#include <spdlog/spdlog.h>
#include <string>
#include "device.hpp"

Serial::Serial(){name = "Serial"; base_address_ = 0xa00003f8; size_ = 4;}
Timer::Timer()  {name = "Timer";  base_address_ = 0xa0000048; size_ = 8;}

uint32_t Serial::read(uint32_t addr){
    return getchar();
}
void Serial::write(uint32_t addr, uint32_t data){
    putchar(data);
}

uint64_t Timer::get_time() {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
    uint64_t us = now.tv_sec * 1000000 + now.tv_nsec / 1000;
    return us;
}

uint32_t Timer::read(uint32_t addr){
    if (boot_time == 0) boot_time = get_time();
    uint64_t time = get_time() - boot_time;
    if(addr == base_address_)
        return time;
    else return time>>32;
}

void Timer::write(uint32_t addr, uint32_t data){
    spdlog::warn("attempt to write Timer!");
}

void DeviceManager::DeviceRegister(Device* device) {
    if (device) {
        if(device->name == ""){
            spdlog::error("Attempt to add device with no name, probably caused by class inheritation!");
            return;
        }
        devices_.push_back(device);
        spdlog::info("Device {} registeration success.", device->name);
    }
    else {
        spdlog::error("{}: nullptr.", __func__);
    }
}

uint32_t DeviceManager::DeviceRead(uint32_t addr){
    for(auto device : devices_){
        if(addr >= device->base_address_ && addr < device->base_address_ + device->size_)
            return device->read(addr);
    }
    spdlog::error("{}: cannot find a device to handle request! addr: 0x{:08x}", __func__, addr);
    return 0xDEADBEEF;
}
void DeviceManager::DeviceWrite(uint32_t addr, uint32_t data){
    for(auto device : devices_){
        if(addr >= device->base_address_ && addr < device->base_address_ + device->size_){
            device->write(addr, data);
            return;
        }
    }
    spdlog::error("{}: cannot find a device to handle request! addr: 0x{:08x}", __func__, addr);
    return;
}