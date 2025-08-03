# Makefile
TARGET      = riscv32-unknown-elf
CC          = $(TARGET)-gcc
OBJCOPY     = $(TARGET)-objcopy
OBJDUMP     = $(TARGET)-objdump
READELF     = $(TARGET)-readelf

BUILD_DIR   = build

# compile flags
CFLAGS      = -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -I. -mstrict-align
 
# source files
C_SRCS      = $(wildcard *.c)
ASM_SRCS    = $(wildcard *.S)
OBJS        = $(addprefix $(BUILD_DIR)/, $(C_SRCS:.c=.o) $(ASM_SRCS:.S=.o))

# final targets
PROG_OBJ    = $(BUILD_DIR)/runtime.o

ASM_TXT   = $(BUILD_DIR)/testc.txt
ELF_TXT   = $(BUILD_DIR)/testc.elf.txt

.PHONY: all clean

all: $(PROG_OBJ)


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
$(PROG_OBJ): $(OBJS)
	$(CC) -r -o $@ $(OBJS) 

# ---------------------------------
#           CLEAN
# ---------------------------------
clean:
	rm -rf $(BUILD_DIR)