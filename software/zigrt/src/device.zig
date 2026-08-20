const Device = enum {
    uart,
    timer,
};

const Meta = struct {
    ApiT: type,                     // datatype in API
    MmioT: type,                    // datatype in MMIO
    base: *align(4) volatile anyopaque       // MMIO base addr
};

fn DeviceMeta(comptime name: Device) Meta {
    return switch(name) {
        .uart => .{
            .ApiT = u8,
            .MmioT = u32,
            .base = @ptrFromInt(0xa00003f8)},
        .timer => .{
            .ApiT = u64,
            .MmioT = u64,
            .base = @ptrFromInt(0xa0000048)},
    };
}

pub fn deviceRead(comptime name: Device) DeviceMeta(name).ApiT {
    const device = DeviceMeta(name);
    const MmioT = device.MmioT;
    const mmio_data: MmioT = device.base.*;
    return @truncate(mmio_data);
}

pub fn deviceWrite(comptime name: Device, data: DeviceMeta(name).ApiT) void {
    const device = DeviceMeta(name);
    const MmioT = device.MmioT;
    const mmio_data: MmioT = @intCast(data);
    const mmio_ptr: *volatile MmioT = @ptrCast(device.base);
    mmio_ptr.* = mmio_data;
}

