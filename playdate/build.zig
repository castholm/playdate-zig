const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("playdate", .{ .root_source_file = .{ .path = "src/playdate.zig" } });
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
    return CompileBundlePseudoStep.create(b, options);
}

pub const CompileBundlePseudoStep = struct {
    pdex_steps: Steps,
    asset_steps: Steps,

    pub const Options = struct {
        /// `-I, -libpath <path>`
        lib_paths: []const std.Build.LazyPath = &.{},
        /// `-s, --strip`
        strip: bool = false,
        /// `-u, --no-compress`
        compress: bool = true,
    };

    pub const Steps = struct {
        command: *std.Build.Step.Run,
        sources: *std.Build.Step.WriteFile,
        generated_dir: std.Build.LazyPath,

        pub fn create(b: *std.Build, options: Options, temp_name: []const u8) Steps {
            const command = b.addSystemCommand(&.{sdkToolName(b, "pdc")});
            for (options.lib_paths) |lib_path| {
                command.addArg("-I");
                command.addDirectoryArg(lib_path);
            }
            if (options.strip) command.addArg("-s");
            if (!options.compress) command.addArg("-u");
            command.addArg("-q");
            const sources = b.addWriteFiles();
            command.addDirectoryArg(sources.getDirectory());
            const generated_dir = command.addOutputFileArg(temp_name);
            return .{ .command = command, .sources = sources, .generated_dir = generated_dir };
        }
    };

    pub fn create(b: *std.Build, options: Options) *CompileBundlePseudoStep {
        // Executables and assets are split up into two different compilations for cache reasons.
        // The rationale is that code is recompiled much more frequently than assets, so by doing
        // this we prevent a lot of unnecessary caching of assets.
        const pdex_steps = Steps.create(b, options, "Executables.pdx");
        const asset_steps = Steps.create(b, options, "Assets.pdx");

        // pdc requires an entry point, but we only want to compile assets; add a dummy pdex.bin
        // file to shut it up, then exclude it when installing.
        _ = asset_steps.sources.add("pdex.bin", "");

        const pdx = b.allocator.create(CompileBundlePseudoStep) catch @panic("OOM");
        pdx.* = .{ .pdex_steps = pdex_steps, .asset_steps = asset_steps };
        return pdx;
    }

    pub fn addExecutable(
        pdx: *CompileBundlePseudoStep,
        pdex: *CompileExecutablePseudoStep,
    ) void {
        _ = pdx.pdex_steps.sources.addCopyFile(
            pdex.artifact.getEmittedBin(),
            pdex.artifact.out_filename,
        );
    }

    pub fn addAsset(
        pdx: *CompileBundlePseudoStep,
        source: std.Build.LazyPath,
        dest_rel_path: []const u8,
    ) void {
        // pdc appends a build timestamp to the pdxinfo file, so we compile it together with the
        // executable instead of other assets to make it less likely to get stale.
        const sources = if (std.mem.eql(u8, dest_rel_path, "pdxinfo"))
            pdx.pdex_steps.sources
        else
            pdx.asset_steps.sources;

        _ = sources.addCopyFile(
            source,
            dest_rel_path,
        );
    }
};

pub fn addCompileExecutable(
    b: *std.Build,
    options: CompileExecutablePseudoStep.Options,
) *CompileExecutablePseudoStep {
    return CompileExecutablePseudoStep.create(b, options);
}

pub const CompileExecutablePseudoStep = struct {
    artifact: *std.Build.Step.Compile,

    pub const Target = enum { device, simulator };

    pub const Options = struct {
        root_source_file: std.Build.LazyPath,
        target: Target,
        optimize: std.builtin.OptimizeMode,
        import_name: []const u8 = "playdate",
    };

    pub fn create(b: *std.Build, options: Options) *CompileExecutablePseudoStep {
        const dep = thisDep(b);
        const artifact = switch (options.target) {
            .device => device: {
                const elf = b.addExecutable(.{
                    .name = "pdex.elf",
                    .root_source_file = options.root_source_file,
                    .target = b.resolveTargetQuery(.{
                        .cpu_arch = .thumb,
                        .os_tag = .freestanding,
                        .abi = .eabihf,
                        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
                        .cpu_features_add = std.Target.arm.featureSet(&.{.fp_armv8d16sp}),
                    }),
                    .optimize = options.optimize,
                });
                elf.setLinkerScript(dep.path("device.ld"));
                elf.entry = .{ .symbol_name = "eventHandler" };
                elf.image_base = 0;
                elf.root_module.strip = false;
                elf.root_module.pic = true;
                elf.link_function_sections = true;
                elf.link_data_sections = true;
                elf.link_emit_relocs = true;
                elf.link_gc_sections = true;
                elf.formatted_panics = false;
                break :device elf;
            },
            .simulator => simulator: {
                const so = b.addSharedLibrary(.{
                    .name = "pdex",
                    .root_source_file = options.root_source_file,
                    .target = b.resolveTargetQuery(.{}),
                    .optimize = options.optimize,
                });
                break :simulator so;
            },
        };
        artifact.root_module.addImport(options.import_name, dep.module("playdate"));

        const pdex = b.allocator.create(CompileExecutablePseudoStep) catch @panic("OOM");
        pdex.* = .{ .artifact = artifact };
        return pdex;
    }
};

pub fn addInstallBundle(
    b: *std.Build,
    pdx: *CompileBundlePseudoStep,
    install_dir: std.Build.InstallDir,
    dest_rel_path: []const u8,
) *InstallBundlePseudoStep {
    return InstallBundlePseudoStep.create(b, pdx, install_dir, dest_rel_path);
}

pub const InstallBundlePseudoStep = struct {
    installation: *std.Build.Step.InstallDir,

    pub fn create(
        b: *std.Build,
        pdx: *CompileBundlePseudoStep,
        install_dir: std.Build.InstallDir,
        dest_rel_path: []const u8,
    ) *InstallBundlePseudoStep {
        const asset_installation = b.addInstallDirectory(.{
            .source_dir = pdx.asset_steps.generated_dir,
            .install_dir = install_dir,
            .install_subdir = dest_rel_path,
            // pdc always creates a pdxinfo file if none is explicitly provided.
            .exclude_extensions = &.{ "pdxinfo", "pdex.bin" },
        });
        const pdex_installation = b.addInstallDirectory(.{
            .source_dir = pdx.pdex_steps.generated_dir,
            .install_dir = install_dir,
            .install_subdir = dest_rel_path,
        });
        pdex_installation.step.dependOn(&asset_installation.step);

        const installed_pdx = b.allocator.create(InstallBundlePseudoStep) catch @panic("OOM");
        installed_pdx.* = .{ .installation = pdex_installation };
        return installed_pdx;
    }
};

pub fn addRunSimulator(
    b: *std.Build,
    installed_pdx: *InstallBundlePseudoStep,
) *RunSimulatorPseudoStep {
    return RunSimulatorPseudoStep.create(b, installed_pdx);
}

pub const RunSimulatorPseudoStep = struct {
    command: *std.Build.Step.Run,

    pub fn create(b: *std.Build, installed_pdx: *InstallBundlePseudoStep) *RunSimulatorPseudoStep {
        const command = b.addSystemCommand(&.{sdkToolName(b, "PlaydateSimulator")});
        command.addArg(b.getInstallPath(
            installed_pdx.installation.options.install_dir,
            installed_pdx.installation.options.install_subdir,
        ));
        command.step.dependOn(&installed_pdx.installation.step);

        const run_simulator = b.allocator.create(RunSimulatorPseudoStep) catch @panic("OOM");
        run_simulator.* = .{ .command = command };
        return run_simulator;
    }
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
