const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("playdate", .{ .source_file = .{ .path = "src/playdate.zig" } });
}

pub const StandardExecutableTargetOptionsDefaults = struct {
    device: bool = true,
    simulator: bool = true,
};

pub fn standardExecutableTargetOptions(
    b: *std.Build,
    defaults: StandardExecutableTargetOptionsDefaults,
) []const CompileExecutablePseudoStep.Target {
    const device = b.option(bool, "device", "Build for the Playdate device");
    const simulator = b.option(bool, "simulator", "Build for the Playdate Simulator");

    var buf: [2]CompileExecutablePseudoStep.Target = undefined;
    var targets: []CompileExecutablePseudoStep.Target = buf[0..0];
    if (device orelse defaults.device) {
        targets.len += 1;
        targets[targets.len - 1] = .device;
    }
    if (simulator orelse defaults.simulator) {
        targets.len += 1;
        targets[targets.len - 1] = .simulator;
    }

    return b.allocator.dupe(CompileExecutablePseudoStep.Target, targets) catch @panic("OOM");
}

pub fn addCompileBundle(
    b: *std.Build,
    options: CompileBundlePseudoStep.Options,
) *CompileBundlePseudoStep {
    const pdc_command = b.addSystemCommand(&.{sdkToolName(b, "pdc")});
    for (options.lib_paths) |lib_path| {
        pdc_command.addArg("-I");
        pdc_command.addDirectoryArg(lib_path);
    }
    if (options.strip) {
        pdc_command.addArg("-s");
    }
    if (!options.compress) {
        pdc_command.addArg("-u");
    }
    pdc_command.addArg("-q");
    const sources = b.addWriteFiles();
    pdc_command.addDirectoryArg(sources.getDirectory());
    const generated_dir = pdc_command.addOutputFileArg("Bundle.pdx");

    const pdx = b.allocator.create(CompileBundlePseudoStep) catch @panic("OOM");
    pdx.* = .{
        .step = generated_dir.generated.step,
        .pdc_command = pdc_command,
        .sources = sources,
        .generated_dir = generated_dir,
    };
    return pdx;
}

pub const CompileBundlePseudoStep = struct {
    step: *std.Build.Step,
    pdc_command: *std.Build.Step.Run,
    sources: *std.Build.Step.WriteFile,
    generated_dir: std.Build.LazyPath,

    pub const Options = struct {
        /// `-I, -libpath <path>`
        lib_paths: []const std.Build.LazyPath = &.{},
        /// `-s, --strip`
        strip: bool = false,
        /// `-u, --no-compress`
        compress: bool = true,
    };

    pub fn addExecutable(
        pdx: *CompileBundlePseudoStep,
        pdex: *CompileExecutablePseudoStep,
    ) void {
        _ = pdx.sources.addCopyFile(pdex.artifact.getEmittedBin(), pdex.artifact.out_filename);
    }

    pub fn addAsset(
        pdx: *CompileBundlePseudoStep,
        source: std.Build.LazyPath,
        dest_rel_path: []const u8,
    ) void {
        _ = pdx.sources.addCopyFile(source, dest_rel_path);

        // <https://github.com/ziglang/zig/issues/18281>
        //if (std.ascii.endsWithIgnoreCase(dest_rel_path, ".lua")) {
        //    pdx.pdc_command.has_side_effects = true;
        //}
    }
};

pub fn addCompileExecutable(
    b: *std.Build,
    options: CompileExecutablePseudoStep.Options,
) *CompileExecutablePseudoStep {
    const dep = thisDep(b);
    const artifact = switch (options.target) {
        .device => device: {
            const elf = b.addExecutable(.{
                .name = "pdex.elf",
                .root_source_file = options.root_source_file,
                .target = device_cross_target,
                .optimize = options.optimize,
            });
            elf.setLinkerScript(.{ .dependency = .{ .dependency = dep, .sub_path = "device.ld" } });
            elf.entry = .{ .symbol_name = "eventHandler" };
            elf.force_pic = true;
            elf.formatted_panics = false;
            elf.link_function_sections = true;
            elf.link_data_sections = true;
            elf.link_emit_relocs = true;
            elf.link_gc_sections = true;
            elf.strip = false;
            break :device elf;
        },
        .simulator => simulator: {
            const so = b.addSharedLibrary(.{
                .name = "pdex",
                .root_source_file = options.root_source_file,
                .target = simulator_cross_target,
                .optimize = options.optimize,
            });
            break :simulator so;
        },
    };
    artifact.addModule("playdate", dep.module("playdate"));

    const pdex = b.allocator.create(CompileExecutablePseudoStep) catch @panic("OOM");
    pdex.* = .{
        .step = &artifact.step,
        .artifact = artifact,
    };
    return pdex;
}

pub const CompileExecutablePseudoStep = struct {
    step: *std.Build.Step,
    artifact: *std.Build.Step.Compile,

    pub const Target = enum { device, simulator };

    pub const Options = struct {
        root_source_file: std.Build.LazyPath,
        target: Target,
        optimize: std.builtin.OptimizeMode,
    };
};

pub fn addInstallBundle(
    b: *std.Build,
    pdx: *CompileBundlePseudoStep,
    install_dir: std.Build.InstallDir,
    dest_rel_path: []const u8,
) *InstallBundlePseudoStep {
    const dir = b.addInstallDirectory(.{
        .source_dir = pdx.generated_dir,
        .install_dir = install_dir,
        .install_subdir = dest_rel_path,
    });

    const installed_pdx = b.allocator.create(InstallBundlePseudoStep) catch @panic("OOM");
    installed_pdx.* = .{
        .step = &dir.step,
        .dir = dir,
    };
    return installed_pdx;
}

pub const InstallBundlePseudoStep = struct {
    step: *std.Build.Step,
    dir: *std.Build.Step.InstallDir,
};

pub fn addRunSimulator(
    b: *std.Build,
    installed_pdx: *InstallBundlePseudoStep,
) *RunSimulatorPseudoStep {
    const simulator_command = b.addSystemCommand(&.{sdkToolName(b, "PlaydateSimulator")});
    simulator_command.addArg(b.getInstallPath(
        installed_pdx.dir.options.install_dir,
        installed_pdx.dir.options.install_subdir,
    ));
    simulator_command.step.dependOn(installed_pdx.step);

    const run_simulator = b.allocator.create(RunSimulatorPseudoStep) catch @panic("OOM");
    run_simulator.* = .{
        .step = &simulator_command.step,
        .simulator_command = simulator_command,
    };
    return run_simulator;
}

pub const RunSimulatorPseudoStep = struct {
    step: *std.Build.Step,
    simulator_command: *std.Build.Step.Run,
};

const simulator_cross_target = parse: {
    @setEvalBranchQuota(10_000);
    break :parse std.zig.CrossTarget.parse(.{
        .arch_os_abi = "native",
    }) catch unreachable;
};

const device_cross_target = parse: {
    @setEvalBranchQuota(10_000);
    break :parse std.zig.CrossTarget.parse(.{
        .arch_os_abi = "thumb-freestanding-eabihf",
        .cpu_features = "cortex_m7+fp_armv8d16sp" ++ "-fp_armv8d16-vfp4d16-vfp3d16-vfp2-fp64-fpregs64",
    }) catch unreachable;
};

fn thisDep(b: *std.Build) *std.Build.Dependency {
    const pkg = comptime find: {
        const all_pkgs = @import("root").dependencies.packages;
        for (@typeInfo(all_pkgs).Struct.decls) |decl| {
            const pkg = @field(all_pkgs, decl.name);
            if (@hasDecl(pkg, "build_zig") and pkg.build_zig == @This()) break :find pkg;
        } else unreachable;
    };

    return b.dependencyInner("playdate", pkg.build_root, pkg.build_zig, pkg.deps, .{});
}

fn sdkToolName(b: *std.Build, tool: []const u8) []const u8 {
    return if (b.env_map.get("PLAYDATE_SDK_PATH")) |sdk_path|
        b.pathJoin(&.{ sdk_path, "bin", tool })
    else
        tool;
}
