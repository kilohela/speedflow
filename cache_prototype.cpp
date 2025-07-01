#include <cstdbool>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <stdexcept>

#include "MemSys.hpp"

// return the range descriptor 
// if the address is in physical address mapping range, it will align the address and split
Range AddressParse(const uint32_t address, uint32_t& tag, uint32_t& index, uint32_t block_offset){
    switch(address){
        case memory_map::kSerial:return Range::Serial;
    }
    
    uint32_t aligned_address = address>>2<<2;
    uint32_t a = kCacheBlockSize;
    uint32_t b = a * kCacheSetCount;
    tag = aligned_address / b;
    index = aligned_address % b / a;
    block_offset = aligned_address % a;
    return Range::Physical;
}


Memory::Memory(const std::string& image_path, std::uint32_t start_address) : start_address_(start_address){
    std::ifstream file(image_path, std::ios::binary);
    if (!file) {
        throw std::system_error(errno, std::generic_category(), "Failed to open file: " + image_path);
    }
    
    // get image file size
    file.seekg(0, std::ios::end);
    const auto file_size = file.tellg();
    file.seekg(0, std::ios::beg);
    
    if (file_size > kMemorySize) {
        throw std::runtime_error("File is too large for the target buffer");
    }

    if (!file.read((char*)(data_.data()), file_size)) {
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
    throw std::runtime_error("Attempt to read missed address!");
}

// only accept hit addr
void Cache::Write(uint32_t index, uint32_t tag, CacheBlockData data){
    for (auto& block: sets_.at(index)){
        if (block.tag == tag && block.valid){
            block.data = data;
        }
    }
    throw std::runtime_error("Attempt to write missed address!");
}

void Cache::GetBlock(uint32_t address){
    uint32_t aligned_address = address>>2<<2;
    auto block_data = memory_.FetchBlock(aligned_address);
    uint32_t tag, index, block_offset;
    AddressParse(address, tag, index, block_offset);
    for (auto& block: sets_.at(index)){
        if (block.valid == false){
            memory_.StoreBlock(block.data, block.tag + index);
            block.valid = true;
            block.tag = tag;
            block.data = block_data;
            return;
        }
    }

    // all block(line) in cache is valid, replace the first
    auto& block = sets_.at(index).at(0);
    block.valid = true;
    block.tag = tag;
    block.data = block_data;
}

CacheBlockData Memory::FetchBlock(uint32_t aligned_address) const {
    uint32_t data_offset = aligned_address - start_address_;
    return *(CacheBlockData*)(data_.data()+data_offset);
}

void Memory::StoreBlock(const CacheBlockData &block_data, uint32_t aligned_address){
    uint32_t data_offset = aligned_address - start_address_;
    *(CacheBlockData*)(data_.data()+data_offset) = block_data;
}

Memory memory(kMemoryImagePath, memory_map::kPhysical);
DCache dcache(memory);
ICache icache(memory);

// only accept aligned memory access, access through 2 blocks is prohibited
extern "C" void dpi_dcache(
    const bool ren, 
    const uint32_t addr, 
    const uint32_t rwidth, 
    const bool rsign, 
    uint32_t* rdata, 
    const bool wen, 
    const uint32_t wwidth, 
    const uint32_t wdata, 
    volatile bool* valid
){
    if(ren){
        *valid = 0;
        uint32_t tag, index, block_offset;
        Range range = AddressParse(addr, tag, index, block_offset);
        switch (range) {
            case Range::Serial:{
                *rdata = getchar();
                break;
            }

            case Range::Physical:{
                if(!(dcache.IsCacheHit(index, tag))){ // cache miss
                    dcache.GetBlock(addr);
                }

                CacheBlockData block_data = dcache.Read(index, tag);

                uint32_t rdata_word = *(uint32_t*)(&block_data[block_offset]);   
                uint32_t rdata_unext = rdata_word<<(32-rwidth*8); // LSB-aligned --> MSB-aligned, cut the MSBs

                if(rsign){
                    *rdata = rdata_unext>>(32-rwidth*8); // note endianness!
                }
                else{
                    *rdata = ((int32_t)rdata_unext)>>(32-rwidth*8);
                }
                break;
            }
        }
        *valid = 1;
    }
    else if(wen){
        *valid = 0;
        uint32_t tag, index, block_offset;
        Range range = AddressParse(addr, tag, index, block_offset);
        switch (range) {
            case Range::Serial:{
                putchar(wdata);
                break;
            }
            case Range::Physical:{
                if(!(dcache.IsCacheHit(index, tag))){ // cache miss
                    dcache.GetBlock(addr);
                }
                CacheBlockData block_data = dcache.Read(index, tag);
                std::memcpy(block_data.data()+block_offset, &wdata, wwidth);
                dcache.Write(index, tag, block_data);
                break;
            }
        }
        *valid = 1;
    }
    else return;
}

extern "C" void dpi_icache(uint32_t addr, uint32_t* rdata, volatile bool* valid){ // don't support unaligned memory access!
    *valid = 0;
    uint32_t tag, index, block_offset;
    Range range = AddressParse(addr, tag, index, block_offset);
    if(range != Range::Physical){
        throw std::runtime_error("Instruction address not in range");
    }
    // called combinational
    if(!(icache.IsCacheHit(index, tag))){ // cache miss
        icache.GetBlock(addr);
    }
    CacheBlockData block_data = dcache.Read(index, tag);
    *rdata = *(uint32_t*)(block_data.data()+block_offset);
    *valid = 1;
}