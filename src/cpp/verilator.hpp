#include <string>
#include "../obj_dir/Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h" 

namespace verilator{

    // design under test
    class Dut{
    public:
        Dut(const std::string &vcd_path, const int max_vcd_time);
        ~Dut();
        void clk_cycle();
        void rst_device();

    private:
        Vtop *dut;
        VerilatedVcdC *vcd;
        const int max_vcd_time;
        int sim_time = 0;
    };

}