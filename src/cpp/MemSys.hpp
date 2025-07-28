#include <cstddef>
#include <cstdint>
#include <array>
#include <string>

constexpr int kCacheSetCount   = 1024;
constexpr int kCacheWayCount   = 4;
constexpr size_t kCacheBlockSize  = 128;
constexpr size_t kMemorySize      = 0x10000000; // should not be more than 0x10000000, the region above 0x8FFFFFFF should be map on other function
constexpr auto kMemoryImagePath = "test/testc.bin";

namespace memory_map {
    static constexpr uint32_t kPhysical = 0x80000000;
    static constexpr uint32_t kSerial   = 0xa00003f8;
}

enum Range {
    Physical, Serial, Invalid, 
};

Range AddressParse(const uint32_t address, uint32_t& tag, uint32_t& index, uint32_t& block_offset);

using CacheBlockData = std::array<uint8_t, kCacheBlockSize>;

struct CacheBlock {
    bool valid = false;
    uint32_t tag = 0;
    CacheBlockData data;
};

using CacheSet = std::array<CacheBlock, kCacheWayCount>;

class Memory {
public:
    Memory(const std::string& image_path, uint32_t start_address);

    // invalid fetch address will cause error
    CacheBlockData FetchBlock(uint32_t aligned_address) const;
    void StoreBlock(const CacheBlockData& block_data, uint32_t aligned_address);

private:
    std::array<uint8_t, kMemorySize> data_;
    uint32_t start_address_;
};

class Cache {
public:
    explicit Cache(Memory& memory);

    CacheBlockData Read(uint32_t index, uint32_t tag);
    void Write(uint32_t index, uint32_t tag, CacheBlockData data);
    bool IsCacheHit(uint32_t index, uint32_t tag) const;

    // get block from memory and automatically store into cache, and store the original dirty block into memory
    void GetBlock(uint32_t address);
    

private:
    

    // only replace the block data, do not change the tag and other region
    // this function does not contain a replacement strategy
    void ReplaceBlock(CacheBlock& block, uint32_t old_address, uint32_t new_address);

    std::array<CacheSet, kCacheSetCount> sets_;
    Memory& memory_;
};

class DCache : public Cache {
public:
    using Cache::Cache;
};

class ICache : public Cache {
public:
    using Cache::Cache;
    void Write(uint32_t address, uint32_t data) = delete;
};

