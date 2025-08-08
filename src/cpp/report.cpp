#include <fmt/core.h>
#include "MemSys.hpp"
extern DCache dcache;
extern ICache icache;
extern std::string report_path;

void print_report(){
    if(report_path.empty()) return;
    FILE* f = fopen(report_path.c_str(), "w");
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

