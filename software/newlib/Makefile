# Makefile
TARGET      = riscv32-unknown-elf
CC          = $(TARGET)-gcc
LD          = $(TARGET)-ld
OBJCOPY     = $(TARGET)-objcopy
OBJDUMP     = $(TARGET)-objdump
READELF     = $(TARGET)-readelf

BUILD_DIR   = build

# compile flags
CFLAGS      = -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -I. 
LDFLAGS     = -T linker.ld -nostartfiles -lgcc -lm 
 
# source files
C_SRCS      = $(wildcard *.c)
ASM_SRCS    = $(wildcard *.S)
OBJS        = $(addprefix $(BUILD_DIR)/, $(C_SRCS:.c=.o) $(ASM_SRCS:.S=.o))

# final targets
PROG_ELF    = $(BUILD_DIR)/testc.elf
PROG_BIN    = $(BUILD_DIR)/testc.bin

ASM_TXT   = $(BUILD_DIR)/testc.txt
ELF_TXT   = $(BUILD_DIR)/testc.elf.txt

.PHONY: all clean

all: $(PROG_BIN)




# ---------------------------------
#           COMPILE
# ---------------------------------
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@



# ---------------------------------
#           LINKING
# ---------------------------------
$(PROG_ELF): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)



# ---------------------------------
#           IMAGE
# ---------------------------------
$(PROG_BIN): $(PROG_ELF)
	$(OBJCOPY) -O binary $< $@



# ---------------------------------
#           RUN
# ---------------------------------
OUT_DIR = out
OUT_VCD = $(OUT_DIR)/top.vcd
OUT_LOG = $(OUT_DIR)/top.log

run: $(PROG_BIN)
	../../build/obj_dir/Vtop $(PROG_BIN) $(OUT_VCD) $(OUT_LOG)



# ---------------------------------
#           DEBUG
# ---------------------------------
$(ASM_TXT): $(PROG_ELF)
	$(OBJDUMP) -d -s -M no-aliases $< > $@

$(ELF_TXT): $(PROG_ELF)
	$(READELF) -a $< > $@

debug: $(ASM_TXT) $(ELF_TXT)



# ---------------------------------
#           CLEAN
# ---------------------------------
clean:
	rm -rf $(BUILD_DIR)