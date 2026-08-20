const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{.explicit = &std.Target.riscv.cpu.generic_rv32},
        .cpu_features_add = std.Target.riscv.featureSet(&.{.zicsr}),
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigrt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/start.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    exe.linker_script = b.path("linker.ld");

    b.installArtifact(exe);

    const img_step = b.step("img", "build the memory image file");

    const img_cmd = b.addObjCopy(exe.getEmittedBin(), .{
        .format = .bin,
    });

    const img_install = b.addInstallBinFile(img_cmd.getOutput(), "zigrt.bin");
    img_step.dependOn(&img_install.step);
}
