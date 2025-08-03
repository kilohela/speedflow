OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
  .text : {
    KEEP(*(.text.init)) /* 将 .text.init 段放在最前面 */
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

  /* 定义堆的起始位置 */
  _end = .;
  _heap_start = _end;

  _stack_start = ORIGIN(ram) + LENGTH(ram);
}