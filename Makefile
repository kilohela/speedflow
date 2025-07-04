WORK_DIR = $(shell pwd -P)
TOP_NAME = top
SRCS = $(shell find $(WORK_DIR)/src -name "*.c" -or -name "*.cc" -or -name "*.cpp" -or -name "*.v" -or -name "*.sv") # DPI-C or simulation file
BUILD_DIR = build
OUT_DIR = out
OUT_VCD = $(OUT_DIR)/top.vcd
OUT_LOG = $(OUT_DIR)/top.log
CFLAGS = -ggdb3 -I. -I$(WORK_DIR)
LDFLAGS = -ggdb3



all: $(VSRCS) $(CSRCS)
	mkdir -p $(BUILD_DIR)
	mkdir -p $(OUT_DIR)
	
	verilator -Wall --trace --exe --build -I./src/systemverilog -cc -I. -O3 $(SRCS) -Wno-UNUSEDSIGNAL -Wno-BLKSEQ\
				--top $(TOP_NAME) -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" -Mdir $(BUILD_DIR)/obj_dir

sim: all
	./$(BUILD_DIR)/obj_dir/V$(TOP_NAME) $(IMG) $(OUT_VCD) $(OUT_LOG) $(SKIP_RVDB)

gtk: sim
	gtkwave top.vcd &

.PHONY: sim clean clean-out

clean:
	rm -rf $(BUILD_DIR)

clean-out:
	rm -rf $(OUT_DIR)