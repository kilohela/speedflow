const print = @import("utils.zig").uartWriteStreamingAll;

pub fn main() void {
    print("Hello, Zig!\n");
}
