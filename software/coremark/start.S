.section .text.init
.global _start
.global halt

_start:
    la sp, _stack_start
    la   a0, __bss_start
    la   a1, __bss_end
    bgeu a0, a1, bss_clear_done

bss_clear_loop:
    sw   zero, 0(a0)
    addi a0, a0, 4
    bltu a0, a1, bss_clear_loop
    
bss_clear_done:
    call trap_init
    call main
    call exit

halt:
    nop
    nop
    nop
    ebreak

