const main = @import("main.zig").main;

fn clearBss() void {
    const bss_start: usize = @intFromPtr(@extern(*u8, .{ .name = "__bss_start" }));
    const bss_end: usize = @intFromPtr(@extern(*u8, .{ .name = "__bss_end" }));
    const bss_size = bss_end - bss_start;
    const bss_ptr: [*]u8 = @ptrFromInt(bss_start);
    const bss: []u8 = bss_ptr[0..bss_size];
    @memset(bss, 0);
}

fn halt() noreturn {
    asm volatile(
        \\ nop
        \\ nop
        \\ nop
        \\ ebreak
    );
    while(true) {}
    unreachable;
}

export fn _start() linksection(".text.start") callconv(.naked) noreturn {
    asm volatile(
        \\ la sp, _stack_start
        \\ call zig_start
    );
}

export fn zig_start() noreturn {
    clearBss();
    main();
    halt();
    unreachable;
}
