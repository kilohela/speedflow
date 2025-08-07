#![no_std]

use core::arch::global_asm;
use core::panic::PanicInfo;
use core::assert;
use core::ptr;
use riscv::asm;


global_asm!("
    .section .text.start
    .global _start

    _start:
        la sp, _stack_start
");

#[no_mangle]
#[link_section = ".text.reset"]
pub unsafe fn reset() -> ! {

    // Initialize RAM
    extern "C" {
        static mut __bss_start: u8;
        static mut __bss_end: u8;
    }

    let mut bss_start = ptr::addr_of_mut!(__bss_start);
    let     bss_end = ptr::addr_of!(__bss_end);
    // Copy static variables
    let count = bss_end.offset_from(bss_start);

    assert!(count >= 0);

    // The call to ptr::write_bytes is safe and does not depend on the initialization of the .bss segment.
    ptr::write_bytes(&mut bss_start, 0, count as usize);

    extern "Rust" {
        fn main() -> i32;
    }

    main();
    halt();
}

#[panic_handler]
unsafe fn panic(_info: &PanicInfo) -> ! {
    halt();
}

unsafe fn halt() -> ! {
    asm::nop();
    asm::nop();
    asm::nop();
    asm::ebreak();
    loop {};
}

const UART_BASE: *mut u8 = 0xa00003f8 as *mut u8;
pub mod uart {
    use core::ptr::read_volatile;
    use core::ptr::write_volatile;
    use crate::UART_BASE;

    #[allow(dead_code)]
    pub fn send(data: char) {
        unsafe { write_volatile(UART_BASE, data as u8) };
    }

    #[allow(dead_code)]
    pub fn receive() -> char {
        unsafe { read_volatile(UART_BASE) as char }
    }
}

