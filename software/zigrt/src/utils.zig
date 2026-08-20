const mmio = @import("device.zig");

pub fn uartWriteStreamingAll(str: []const u8) void {
    for(str) |c| {
        mmio.deviceWrite(.uart, c);
    }
}

pub fn uartBufReadStreamingUntil(buf: []u8, end: u8) usize {
    var num_read: usize = 0;
    for(buf) |*c| {
        c.* = mmio.deviceRead(.uart);
        num_read += 1;
        if(c.* == end) {
            break;
        }
    }
    return num_read;
}

pub fn gettime() u64 {
    return mmio.deviceRead(.timer);
}

