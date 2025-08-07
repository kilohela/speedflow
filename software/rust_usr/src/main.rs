#![no_std]
#![no_main]

use speedflow_hal;

fn printstr(s: &str){
    for c in s.chars() {
        speedflow_hal::uart::send(c);
    }
}
#[unsafe(export_name = "main")]
fn main() -> i32 {
    let welcome = "Hello, world!\n";
    printstr(welcome);
    0
}
