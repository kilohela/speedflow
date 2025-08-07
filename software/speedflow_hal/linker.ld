OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
  .text : {
    KEEP(*(.text.start))
    KEEP(*(.text.reset))
    *(.text .text.*)
  } > ram

  .rodata : {
    *(.rodata .rodata.*)
  } > ram

  . = ALIGN(16);
  PROVIDE(__global_pointer$ = . + 0x800);
  .sdata : {
    *(.sdata .sdata.*)
  }

  .data : {
    *(.data .data.*)
  } > ram

  .bss : {
    . = ALIGN(8);
    __bss_start = .;
    *(.bss .bss.* .sbss .sbss.*)
    *(COMMON)
    . = ALIGN(8);
    __bss_end = .;
  } > ram

  _end = .;
  _heap_start = _end;

  _stack_start = ORIGIN(ram) + LENGTH(ram);
}