# Makefile
TARGET      = riscv32-unknown-elf
CC          = $(TARGET)-gcc
LD          = $(TARGET)-ld
OBJCOPY     = $(TARGET)-objcopy
OBJDUMP     = $(TARGET)-objdump
READELF     = $(TARGET)-readelf

BUILD_DIR   = build

# compile flags
CFLAGS      = -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -I. -mstrict-align
LDFLAGS     = -T runtime/linker.ld -nostartfiles -nostdlib -lgcc
 
# source files
TEST_SRCS   = $(wildcard tests/*.c)


PROG_BINS      = $(patsubst tests/%.c,$(BUILD_DIR)/%.bin,$(TEST_SRCS))
RUNTIME_OBJ = runtime/build/runtime.o


.PHONY: all clean

all: $(PROG_BINS)


vpath %.c tests

$(MAIN_SRC): generate_main.py
	./generate_main.py tests

# ---------------------------------
#           COMPILE
# ---------------------------------
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(RUNTIME_OBJ):
	cd runtime
	make
	cd ..

# ---------------------------------
#           LINKING
# ---------------------------------
$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o $(RUNTIME_OBJ)
	$(CC) $(CFLAGS) -o $@ $< $(RUNTIME_OBJ) $(LDFLAGS)



# ---------------------------------
#           IMAGE
# ---------------------------------
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary $< $@


# ---------------------------------
#           RUN
# ---------------------------------

run: $(PROG_BINS)
	./test.py



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