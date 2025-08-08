WORK_DIR = $(shell pwd -P)
TOP_NAME = top
SRCS = $(shell find $(WORK_DIR)/src -name "*.c" -or -name "*.cc" -or -name "*.cpp" -or -name "*.v" -or -name "*.sv") # DPI-C or simulation file
BUILD_DIR = build
OUT_DIR = out
OUT_VCD = $(OUT_DIR)/top.vcd
OUT_LOG = $(OUT_DIR)/top.log
CFLAGS = -ggdb3 -I. -I$(WORK_DIR) -std=c++14 -lspdlog -lfmt
LDFLAGS = -ggdb3 -lspdlog -lfmt
#IMG := test/testc.bin
IMG := test/badapple.bin

all: $(VSRCS) $(CSRCS)
	mkdir -p $(BUILD_DIR)
	mkdir -p $(OUT_DIR)
	
	verilator -Wall --trace --exe --build -I./src/systemverilog -cc -I. -O3 $(SRCS) \
				--top $(TOP_NAME) -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" -Mdir $(BUILD_DIR)/obj_dir

sim: all
	./$(BUILD_DIR)/obj_dir/V$(TOP_NAME) --image $(IMG) --wave $(OUT_VCD) --log $(OUT_LOG) --keep

gtk: sim
	gtkwave top.vcd &

.PHONY: sim clean clean-all

clean:
	rm -rf $(BUILD_DIR)

clean-all: clean
	rm -rf $(OUT_DIR) .cache
