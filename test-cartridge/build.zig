const std = @import("std");
const playdate = @import("playdate");

pub fn build(b: *std.Build) void {
    const pdex_targets = playdate.standardExecutableTargetOptions(b, .{});
    const optimize = b.standardOptimizeOption(.{});

    const pdx = playdate.addCompileBundle(b, .{});

    for (pdex_targets) |target| {
        const pdex = playdate.addCompileExecutable(b, .{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        pdx.addExecutable(pdex);

        if (target == .device) {
            const installed_elf = b.addInstallArtifact(pdex.artifact, .{
                .dest_dir = .{ .override = .prefix },
                .dest_sub_path = "TestCartridge.elf",
            });
            b.getInstallStep().dependOn(&installed_elf.step);
        }
    }

    pdx.addAsset(.{ .path = "assets/pdxinfo" }, "pdxinfo");
    pdx.addAsset(.{ .path = "assets/menuImage.png" }, "menuImage.png");
    pdx.addAsset(.{ .path = "assets/Roobert-11-Mono-Condensed.fnt" }, "Roobert-11-Mono-Condensed.fnt");
    pdx.addAsset(.{ .path = "assets/Roobert-11-Mono-Condensed-table-8-16.png" }, "Roobert-11-Mono-Condensed-table-8-16.png");

    const installed_pdx = playdate.addInstallBundle(b, pdx, .prefix, "TestCartridge.pdx");
    b.getInstallStep().dependOn(installed_pdx.step);

    const run_simulator = playdate.addRunSimulator(b, installed_pdx);

    const run_step = b.step("run", "Run the game in the Playdate Simulator");
    run_step.dependOn(run_simulator.step);
}
