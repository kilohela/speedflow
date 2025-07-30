#pragma once
#include <cstdint>
#include <string>
#include <vector>


class Device {
public:
    virtual ~Device() = default;
    std::string name;
    uint32_t base_address_;
    uint32_t size_;
    virtual uint32_t read(uint32_t addr) = 0;
    virtual void write(uint32_t addr, uint32_t data) = 0;
};

class DeviceManager{
public:
    void DeviceRegister(Device* device);
    uint32_t DeviceRead(uint32_t addr);
    void DeviceWrite(uint32_t addr, uint32_t data);
private:
    std::vector<Device*> devices_;
};


class Serial : public Device {
public: 
    Serial();
    uint32_t read(uint32_t addr) override;
    void write(uint32_t addr, uint32_t data) override;
};

class Timer : public Device {
public: 
    Timer();
    uint64_t boot_time = 0;
    uint32_t read(uint32_t addr) override;
    void write(uint32_t addr, uint32_t data) override;
private:
    uint64_t get_time();
};