# Makefile
TARGET      = riscv32-unknown-elf
CC          = $(TARGET)-gcc
LD          = $(TARGET)-ld
OBJCOPY     = $(TARGET)-objcopy
OBJDUMP     = $(TARGET)-objdump
READELF     = $(TARGET)-readelf

# 编译选项
CFLAGS      = -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -I. 
LDFLAGS     = -T linker.ld -nostartfiles -lgcc -lm 
 
# 源文件
C_SRCS      = testc.c syscall.c
ASM_SRCS    = start.S trap.S # maybe crt0.S
OBJS        = $(C_SRCS:.c=.o) $(ASM_SRCS:.S=.o)

# 最终目标
PROG_ELF    = testc.elf
PROG_BIN    = testc.bin

ASM_TXT   = testc.txt
ELF_TXT   = testc.elf.txt

.PHONY: all clean

all: $(PROG_BIN)




# ---------------------------------
#           COMPILE
# ---------------------------------
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
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
	rm -f $(OBJS) $(PROG_ELF) $(PROG_BIN) $(ASM_TXT) $(ELF_TXT)