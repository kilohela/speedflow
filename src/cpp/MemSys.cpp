#include <cstdbool>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <spdlog/common.h>
#include <stdexcept>
#include <spdlog/spdlog.h>

#include "device.hpp"
#include "MemSys.hpp"
#include "svdpi.h"

// return the range descriptor 
// if the address is in physical address mapping range, it will align the address and split
Range AddressParse(const uint32_t address, uint32_t& tag, uint32_t& index, uint32_t& block_offset){
    switch(address){
        case memory_map::kDevice:return Range::Device;
    }
    
    uint32_t aligned_address = address>>2<<2;
    uint32_t a = kCacheBlockSize;
    uint32_t b = a * kCacheSetCount;
    tag = aligned_address / b;
    index = aligned_address % b / a;
    block_offset = aligned_address % a;
    if(address >= memory_map::kPhysical && address < memory_map::kPhysical + kMemorySize)
        return Range::Physical;
    else if(address >= memory_map::kDevice && address < memory_map::kDevice + kDeviceSize)
        return Range::Device;
    else return Range::Invalid;
}



Memory::Memory(){
    memset(data_.data(), '#', kMemorySize);
}


void Memory::init(const std::string& image_path, uint32_t start_address){
    start_address_ = start_address;
    std::ifstream file(image_path, std::ios::binary);
    if (!file) {
        spdlog::critical("{}: Failed to open image file: {}", __func__, image_path);
        throw std::system_error(errno, std::generic_category(), "Failed to open file: " + image_path);
    }
    
    // get image file size
    file.seekg(0, std::ios::end);
    const auto file_size = file.tellg();
    file.seekg(0, std::ios::beg);
    
    if (file_size > kMemorySize) {
        spdlog::critical("{}: File is too large for the target buffer: {}", __func__, image_path);
        throw std::runtime_error("File is too large for the target buffer");
    }

    if (!file.read((char*)(data_.data()), file_size)) {
        spdlog::critical("{}: Failed to read file: {}", __func__, image_path);
        throw std::system_error(errno, std::generic_category(), "Failed to read file: " + image_path);
    }
}

Cache::Cache(Memory& memory) : memory_(memory){}

bool Cache::IsCacheHit(uint32_t index, uint32_t tag) const {
    for (auto& block: sets_.at(index)){
        if (block.tag == tag && block.valid){
            return true;
        }
    }
    return false;
}

// only accept hit addr
CacheBlockData Cache::Read(uint32_t index, uint32_t tag){
    for (auto& block: sets_.at(index)){
        if (block.tag == tag && block.valid){
            return block.data;
        }
    }
    spdlog::error("Attempt to read missed address at index: 0x{0:x}, tag: 0x{1:x}", index, tag);
    throw std::runtime_error("please read log");
}

// only accept hit addr
void Cache::Write(uint32_t index, uint32_t tag, CacheBlockData data){
    for (auto& block: sets_.at(index)){
        if (block.tag == tag && block.valid){
            block.data = data;
            return;
        }
    }
    spdlog::error("Attempt to write missed address. Write nothing!");
}

void Cache::GetBlock(uint32_t address){
    spdlog::debug("{0}: address: 0x{1:08x}", __func__, address);
    uint32_t block_aligned_address = address / kCacheBlockSize * kCacheBlockSize;
    uint32_t tag, index, block_offset;
    Range range = AddressParse(address, tag, index, block_offset);
    if(range != Range::Physical){
        spdlog::error("Address not in the cache range, do nothing!");
        return;
    }
    auto block_data = memory_.FetchBlock(block_aligned_address);
    for (auto& block: sets_.at(index)){
        if (block.valid == false){
            block.valid = true;
            block.tag = tag;
            block.data = block_data;
            return;
        }
    }

    // all block(line) in cache is valid, replace the first
    auto& block = sets_.at(index).at(0);
    memory_.StoreBlock(block.data, block.tag * kCacheBlockSize * kCacheSetCount + index * kCacheBlockSize);
    block.valid = true;
    block.tag = tag;
    block.data = block_data;
}

CacheBlockData Memory::FetchBlock(uint32_t aligned_address) const {
    spdlog::debug("Memory: fetch data block at aligned address: 0x{0:08x}", aligned_address);
    uint32_t data_offset = aligned_address - start_address_;
    return *(CacheBlockData*)(data_.data()+data_offset);
}

void Memory::StoreBlock(const CacheBlockData &block_data, uint32_t aligned_address){
    spdlog::debug("Memory: Store data block at aligned address: 0x{0:08x}", aligned_address);
    uint32_t data_offset = aligned_address - start_address_;
    *(CacheBlockData*)(data_.data()+data_offset) = block_data;
}

Memory memory;
DCache dcache(memory);
ICache icache(memory);
DeviceManager device_manager;

// only accept aligned memory access, access through 2 blocks is prohibited
extern "C" void dpi_dcache(
    const svBit ren, 
    const uint32_t addr, 
    const uint32_t rwidth, 
    const svBit rsign, 
    uint32_t* rdata, 
    const svBit wen, 
    const uint32_t wwidth, 
    const uint32_t wdata
){
    if(ren){
        // spdlog::debug("dcache valid = 0");
        // *valid = 0;
        // spdlog::debug("{}: addr: 0x{:08x}", __func__, addr);
        uint32_t tag, index, block_offset, byte_offset;
        Range range = AddressParse(addr, tag, index, block_offset);
        byte_offset = addr % 4;
        switch (range) {
            case Range::Device:{
                *rdata = device_manager.DeviceRead(addr);
                break;
            }

            case Range::Physical:{
                if(!(dcache.IsCacheHit(index, tag))){ // cache miss
                    dcache.GetBlock(addr);
                }

                CacheBlockData block_data = dcache.Read(index, tag);
                if(block_offset == kCacheBlockSize - 4 && byte_offset!= 0 && byte_offset + rwidth > 4){
                    spdlog::error("Attempt to read across two blocks! Change byte_offset to 0 to prevent host SEGV! Simulator will load wrong value!");
                    spdlog::error("addr: 0x{:08x}, width: {}", addr, rwidth);
                    byte_offset = 0;
                }
                uint32_t rdata_word = *(uint32_t*)(&block_data[block_offset + byte_offset]);
                uint32_t rdata_unext = rdata_word<<(32-rwidth*8); // LSB-aligned --> MSB-aligned, cut the MSBs
                if(rsign){
                    *rdata = rdata_unext>>(32-rwidth*8); // note endianness!
                }
                else{
                    *rdata = ((int32_t)rdata_unext)>>(32-rwidth*8);
                }
                spdlog::debug("dcache read: load 0x{:08x} from address 0x{:08x}, width = {}", *rdata, addr, rwidth);
                break;
            }

            case Range::Invalid:{
                spdlog::error("{}: Invalid address: 0x{:08x}, do nothing!", __func__, addr);
                spdlog::error("Note, read data will be arbitrary!");
                break;
            }
        }
        // *valid = 1;
        // spdlog::debug("dcache valid = {}", *valid);
    }
    else if(wen){
        // spdlog::debug("dcache valid = 0");
        // *valid = 0;
        uint32_t tag, index, block_offset, byte_offset;
        Range range = AddressParse(addr, tag, index, block_offset);
        byte_offset = addr % 4;
        switch (range) {
            case Range::Device:{
                device_manager.DeviceWrite(addr, wdata);
                break;
            }
            case Range::Physical:{
                if(!(dcache.IsCacheHit(index, tag))){ // cache miss
                    dcache.GetBlock(addr);
                }
                CacheBlockData block_data = dcache.Read(index, tag);
                if(block_offset == kCacheBlockSize - 4 && byte_offset!= 0 && byte_offset + wwidth > 4){
                    spdlog::error("Attempt to write across two blocks! Do nothing!");
                    spdlog::error("addr: 0x{:08x}, width: {}", addr, wwidth);
                }
                else {
                    std::memcpy(block_data.data()+block_offset+byte_offset, &wdata, wwidth);
                    dcache.Write(index, tag, block_data);
                }
                spdlog::debug("dcache write: store 0x{:08x} to address 0x{:08x}, width = {}", wdata, addr, wwidth);
                break;
            }
            case Range::Invalid:{
                spdlog::error("{}: Invalid address: 0x{:08x}, do nothing!", __func__, addr);
                spdlog::error("Note, read data will be arbitrary!");
                break;
            }
        }
        // spdlog::debug("dcache valid = 1");
        // *valid = 1;
    }
    else return;
}

extern "C" void dpi_icache(uint32_t addr, uint32_t* rdata){ // don't support unaligned memory access!
    // spdlog::debug("icache valid = 0");
    // *valid = 0;
    uint32_t tag, index, block_offset;
    Range range = AddressParse(addr, tag, index, block_offset);
    if(range != Range::Physical){
        spdlog::error("{}: Invalid address: 0x{:08x}, do nothing!", __func__, addr);
        spdlog::error("Note, read data will be arbitrary!");
        return;
    }
    // called combinational
    if(!(icache.IsCacheHit(index, tag))){ // cache miss
        icache.GetBlock(addr);
    }
    CacheBlockData block_data = icache.Read(index, tag);
    *rdata = *(uint32_t*)(block_data.data()+block_offset);
    // spdlog::debug("icache valid = 1");
    // *valid = 1;
}

extern "C" svBit dpi_icache_valid(uint32_t addr){
    return 1;
    // uint32_t tag, index, block_offset;
    // Range range = AddressParse(addr, tag, index, block_offset);
    // return icache.IsCacheHit(index, tag);
}

extern "C" svBit dpi_dcache_valid(uint32_t addr, svBit en){
    return 1;
    // uint32_t tag, index, block_offset;
    // Range range = AddressParse(addr, tag, index, block_offset);
    // return !en || icache.IsCacheHit(index, tag);
}
