const sys = @import("./sys.zig");
const lit = @import("./lit.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const spec = @import("./spec.zig");
const types = @import("./build/types.zig");
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");
const command_line = @import("./build/command_line.zig");
pub usingnamespace types;
pub const State = enum(u8) {
    unavailable = 0,
    failed = 1,
    ready = 2,
    blocking = 3,
    invalid = 4,
    finished = 255,
};
pub const Task = enum(u8) { build, run };
pub const BuilderSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    pub const Options = struct {
        max_command_line: ?u64 = 65536,
        max_command_args: ?u64 = 1024,
        max_relevant_depth: u64 = 255,
        dep_sleep_nsec: u64 = 50000,
        max_thread_count: u64 = 16,
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        stack_lb_addr: u64 = 0x700000000000,
    };
    pub const Logging = packed struct {
        command: proc.CommandSpec.Logging = .{},
        path: builtin.Logging.AcquireErrorFault = .{},
        create: builtin.Logging.AcquireErrorFault = .{},
        close: builtin.Logging.ReleaseErrorFault = .{},
        mkdir: builtin.Logging.SuccessErrorFault = .{},
        write: builtin.Logging.SuccessErrorFault = .{},
        map: builtin.Logging.AcquireErrorFault = .{},
        unmap: builtin.Logging.AcquireErrorFault = .{},
        stat: builtin.Logging.SuccessErrorFault = .{},
    };
    pub const Errors = struct {
        map: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
        unmap: sys.ErrorPolicy = .{ .abort = sys.munmap_errors },
        command: proc.CommandSpec.Errors = .{},
        path: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        clock: sys.ErrorPolicy = .{ .throw = sys.clock_get_errors },
        sleep: sys.ErrorPolicy = .{ .throw = sys.nanosleep_errors },
        stat: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
        create: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        mkdir: sys.ErrorPolicy = .{ .throw = sys.mkdir_noexcl_errors },
        close: sys.ErrorPolicy = .{ .abort = sys.close_errors },
        write: sys.ErrorPolicy = .{ .abort = sys.write_errors },
    };
    const map_options: mem.MapSpec.Options = .{
        .grows_down = true,
    };
    const create_options: file.CreateSpec.Options = .{
        .exclusive = false,
        .write = .truncate,
    };
    fn path(comptime builder_spec: BuilderSpec) file.PathSpec {
        return .{ .errors = builder_spec.errors.path, .logging = builder_spec.logging.path };
    }
    fn clock(comptime builder_spec: BuilderSpec) time.ClockSpec {
        return .{ .errors = builder_spec.errors.clock };
    }
    fn sleep(comptime builder_spec: BuilderSpec) time.SleepSpec {
        return .{ .errors = builder_spec.errors.sleep };
    }
    fn mkdir(comptime builder_spec: BuilderSpec) file.MakeDirSpec {
        return .{ .errors = builder_spec.errors.mkdir, .logging = builder_spec.logging.mkdir };
    }
    fn write(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{ .errors = builder_spec.errors.write, .logging = builder_spec.logging.write };
    }
    fn close(comptime builder_spec: BuilderSpec) file.CloseSpec {
        return .{ .errors = builder_spec.errors.close, .logging = builder_spec.logging.close };
    }
    fn unmap(comptime builder_spec: BuilderSpec) mem.UnmapSpec {
        return .{ .errors = builder_spec.errors.unmap, .logging = builder_spec.logging.unmap };
    }
    fn stat(comptime builder_spec: BuilderSpec) file.StatSpec {
        return .{ .errors = builder_spec.errors.stat, .logging = builder_spec.logging.stat };
    }
    fn map(comptime builder_spec: BuilderSpec) mem.MapSpec {
        return .{
            .errors = builder_spec.errors.map,
            .logging = builder_spec.logging.map,
            .options = map_options,
        };
    }
    fn create(comptime builder_spec: BuilderSpec) file.CreateSpec {
        return .{
            .errors = builder_spec.errors.create,
            .logging = builder_spec.logging.create,
            .options = create_options,
        };
    }
    fn command(comptime builder_spec: BuilderSpec) proc.CommandSpec {
        return .{
            .args_type = [][*:0]u8,
            .vars_type = [][*:0]u8,
            .errors = builder_spec.errors.command,
            .logging = builder_spec.logging.command,
        };
    }
};
pub fn GenericBuilder(comptime builder_spec: BuilderSpec) type {
    const Type = struct {
        zig_exe: [:0]const u8,
        build_root: [:0]const u8,
        cache_root: [:0]const u8,
        global_cache_root: [:0]const u8,
        dir_fd: u64,
        args: [][*:0]u8,
        args_len: u64,
        vars: [][*:0]u8,
        grps: []*Group = &.{},
        grps_len: u64 = 0,
        const Builder = @This();
        pub const AddressSpace = mem.GenericRegularAddressSpace(.{
            .label = "arena",
            .idx_type = u8,
            .divisions = max_arena_count,
            .lb_addr = arena_lb_addr,
            .up_addr = arena_up_addr,
            .errors = spec.address_space.errors.noexcept,
            .logging = spec.address_space.logging.silent,
            .options = .{ .thread_safe = true, .require_map = true, .require_unmap = true },
        });
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "stack",
            .idx_type = AddressSpace.Index,
            .divisions = max_thread_count,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .errors = spec.address_space.errors.noexcept,
            .logging = spec.address_space.logging.silent,
            .options = .{ .thread_safe = true },
        });
        pub const Allocator = mem.GenericRtArenaAllocator(.{
            .AddressSpace = AddressSpace,
            .logging = spec.allocator.logging.silent,
            .errors = spec.allocator.errors.noexcept,
            .options = spec.allocator.options.small_composed,
        });
        pub const Args = mem.StructuredVector(u8, &@as(u8, 0), 8, Allocator, .{});
        pub const Ptrs = mem.StructuredVector([*:0]u8, builtin.anyOpaque(builtin.zero([*:0]u8)), 8, Allocator, .{});
        pub const Dependency = struct {
            target: *Target,
            task: Task,
            state: State,
        };
        pub const Target = struct {
            name: [:0]const u8,
            descr: ?[:0]const u8 = null,
            root: [:0]const u8,
            lock: Lock,
            build_cmd: *types.BuildCommand,

            deps: []Dependency = &.{},
            deps_len: u64 = 0,

            args: [][*:0]u8 = &.{},
            args_len: u64 = 0,

            pub const Lock = virtual.ThreadSafeSet(6, State, Task);
            const CompiledExecutable = struct {
                lock: Lock = .{},
                root: [:0]const u8,
                build_cmd: *types.BuildCommand,
                run_cmd: *types.RunCommand,
            };
            const Compiled = struct {
                lock: Lock,
                root: [:0]const u8,
                build_cmd: *types.BuildCommand,
            };
            fn acquireThread(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: Task,
                depth: u64,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.abort ++ decls.command_spec.errors.abort(),
            }, void) {
                if (max_thread_count == 0) {
                    try meta.wrap(executeCommand(builder, allocator, target, task, depth));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (thread_space.atomicSet(arena_index)) {
                            const stack_ab_addr: u64 = ThreadSpace.high(arena_index) -% 4096;
                            return forwardToExecuteCloneThreaded(builder, address_space, thread_space, target, task, arena_index, depth, stack_ab_addr);
                        }
                    }
                    try meta.wrap(executeCommand(builder, allocator, target, task, depth));
                }
            }
            fn acquireLock(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: Task,
                arena_index: AddressSpace.Index,
                depth: u64,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.abort ++ decls.command_spec.errors.throw(),
            }, void) {
                if (task == .run and target.build_cmd.kind == .exe) {
                    try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, .build, arena_index, 0));
                }
                if (target.transform(task, .ready, .blocking)) {
                    for (target.deps[0..target.deps_len]) |dep| {
                        try meta.wrap(dep.target.acquireLock(address_space, thread_space, allocator, builder, dep.task, arena_index, depth +% 1));
                    }
                    while (dependencyWait(target, task, arena_index)) {
                        try meta.wrap(time.sleep(decls.sleep_spec, decls.time_spec));
                    }
                    try meta.wrap(target.acquireThread(address_space, thread_space, allocator, builder, task, depth));
                }
                if (depth == 0) {
                    while (target.lock.get(task) == .blocking) {
                        try meta.wrap(time.sleep(decls.sleep_spec, decls.time_spec));
                    }
                }
            }
            pub fn executeToplevel(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: Task,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.abort ++ decls.command_spec.errors.throw(),
            }, void) {
                try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, task, Builder.max_thread_count, 0));
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(decls.sleep_spec, decls.time_spec));
                }
            }
            pub fn addDependency(target: *Target, allocator: *Allocator, dependency: *Target, task: Task, state: State) void {
                if (target.deps_len == target.deps.len) {
                    target.deps = allocator.reallocateIrreversible(Dependency, target.deps, (target.deps_len +% 1) *% 2);
                }
                target.deps[target.deps_len] = .{ .target = dependency, .task = task, .state = state };
                target.deps_len +%= 1;
            }
            pub fn addRunArgument(target: *Target, allocator: *Allocator, arg: []const u8) void {
                if (target.args_len == target.args.len) {
                    target.args = allocator.reallocateIrreversible([*:0]u8, target.args, (target.args_len +% 1) *% 2);
                }
                target.args[target.args_len] = strdup(allocator, arg).ptr;
                target.args_len +%= 1;
            }
            fn addRunArguments(target: *Target, allocator: *Allocator, builder: *Builder) void {
                const run_args_len: u64 = builder.args.len -% builder.args_len;
                if (target.args.len <= target.args_len +% run_args_len) {
                    target.args = allocator.reallocateIrreversible([*:0]u8, target.args, target.args_len +% run_args_len +% 1);
                }
                for (builder.args[builder.args_len..]) |run_arg| {
                    target.args[target.args_len] = run_arg;
                    target.args_len +%= 1;
                }
            }
            pub fn buildDependencies(target: *const Target) []Dependency {
                return target.deps[0..target.deps_len];
            }
            pub fn runArguments(target: *const Target) [][*:0]u8 {
                return target.args[0..target.args_len];
            }
            fn binaryRelative(target: *Target, allocator: *Allocator) [:0]const u8 {
                switch (target.build_cmd.kind) {
                    .exe => return concatenate(allocator, u8, &.{ tok.exe_out_dir, target.name }),
                    .lib => return concatenate(allocator, u8, &.{ tok.exe_out_dir, target.name, tok.lib_ext }),
                    .obj => return concatenate(allocator, u8, &.{ tok.exe_out_dir, target.name, tok.obj_ext }),
                }
            }
            fn auxiliaryRelative(target: *Target, allocator: *Allocator, kind: types.AuxOutputMode) [:0]const u8 {
                switch (kind) {
                    .@"asm" => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.asm_ext }),
                    .llvm_ir => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.llvm_ir_ext }),
                    .llvm_bc => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.llvm_bc_ext }),
                    .h => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.h_ext }),
                    .docs => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.docs_ext }),
                    .analysis => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.analysis_ext }),
                    .implib => return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.implib_ext }),
                }
            }
            fn binaryPath(target: *Target) types.Path {
                return target.build_cmd.emit_bin.?.yes.?;
            }
            fn auxiliaryPath(target: *Target, kind: types.AuxOutputMode) types.Path {
                switch (kind) {
                    .@"asm" => return target.build_cmd.emit_asm.?.yes.?,
                    .llvm_ir => return target.build_cmd.emit_llvm_ir.?.yes.?,
                    .llvm_bc => return target.build_cmd.emit_llvm_bc.?.yes.?,
                    .h => return target.build_cmd.emit_h.?.yes.?,
                    .docs => return target.build_cmd.emit_docs.?.yes.?,
                    .analysis => return target.build_cmd.emit_analysis.?.yes.?,
                    .implib => return target.build_cmd.emit_implib.?.yes.?,
                }
            }
            inline fn createBinaryPath(target: *Target, allocator: *Allocator, builder: *Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = binaryRelative(target, allocator) };
            }
            inline fn createAuxiliaryPath(target: *Target, allocator: *Allocator, builder: *Builder, kind: types.AuxOutputMode) types.Path {
                return .{ .absolute = builder.build_root, .relative = auxiliaryRelative(target, allocator, kind) };
            }
            fn emitBinary(target: *Target, allocator: *Allocator, builder: *Builder) void {
                target.build_cmd.emit_bin = .{ .yes = createBinaryPath(target, allocator, builder) };
            }
            fn emitAuxiliary(target: *Target, allocator: *Allocator, builder: *Builder) void {
                target.build_cmd.emit_bin = .{ .yes = createAuxiliaryPath(target, allocator, builder) };
            }
            fn emitAssembly(target: *Target, allocator: *Allocator, builder: *Builder) void {
                emitAuxiliary(target, allocator, builder, .@"asm");
            }
            fn rootSourcePath(target: *Target, builder: *Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = target.root };
            }
            pub fn dependOnBuild(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, dependency, .build, .finished);
            }
            pub fn dependOnRun(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, dependency, .run, .finished);
            }
            pub fn dependOnObject(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.dependOnBuild(allocator, dependency);
                target.addFile(allocator, dependency.binaryPath());
            }
            fn addFile(target: *Target, allocator: *Allocator, path: types.Path) void {
                if (target.build_cmd.files) |*files| {
                    const buf: []types.Path = allocator.reallocateIrreversible(types.Path, @constCast(files.*), files.len +% 1);
                    buf[files.len] = path;
                    target.build_cmd.files = buf;
                } else {
                    const buf: []types.Path = allocator.allocateIrreversible(types.Path, 1);
                    buf[0] = path;
                    target.build_cmd.files = buf;
                }
            }
            fn transform(target: *Target, task: Task, old_state: State, new_state: State) bool {
                const ret: bool = target.lock.atomicTransform(task, old_state, new_state);
                if (builtin.logging_general.Success) {
                    if (ret) {
                        debug.transformNotice(target, task, old_state, new_state);
                    } else {
                        debug.noTransformNotice(target, task, old_state, new_state);
                    }
                }
                return ret;
            }
            fn assertTransform(target: *Target, task: Task, old_state: State, new_state: State) void {
                const res: bool = target.lock.atomicTransform(task, old_state, new_state);
                if (res) {
                    if (builtin.logging_general.Success) {
                        debug.transformNotice(target, task, old_state, new_state);
                    }
                } else {
                    if (builtin.logging_general.Fault) {
                        debug.noTransformFault(target, task, old_state, new_state);
                    }
                    builtin.proc.exit(2);
                }
            }
        };
        pub const Group = struct {
            name: [:0]const u8,
            builder: *Builder,
            trgs: []*Target = &.{},
            trgs_len: u64 = 0,
            pub fn acquireLock(
                group: *Group,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                task: Task,
            ) !void {
                for (group.targets()) |target| {
                    try meta.wrap(target.acquireLock(address_space, thread_space, allocator, group.builder, task, max_thread_count, 1));
                }
                groupScan(group, task);
            }
            pub fn addTarget(
                group: *Group,
                allocator: *Allocator,
                comptime extra: anytype,
                name: [:0]const u8,
                root: [:0]const u8,
            ) !*Target {
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = allocator.reallocateIrreversible(*Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = try group.builder.createTarget(allocator, name, root, extra);
                group.trgs[group.trgs_len] = ret;
                group.trgs_len +%= 1;
                return ret;
            }
            pub fn targets(group: *const Group) []*Target {
                return group.trgs[0..group.trgs_len];
            }
        };
        pub const max_thread_count: u64 = builder_spec.options.max_thread_count;
        pub const max_arena_count: u64 = if (max_thread_count == 0) 4 else max_thread_count + 1;
        pub const stack_aligned_bytes: u64 = builder_spec.options.stack_aligned_bytes;
        pub const arena_aligned_bytes: u64 = builder_spec.options.arena_aligned_bytes;
        pub const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        pub const arena_lb_addr: u64 = stack_up_addr;
        pub const stack_up_addr: u64 = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        pub const arena_up_addr: u64 = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        pub fn groups(builder: *const Builder) []*Group {
            return builder.grps[0..builder.grps_len];
        }
        fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
            .abort = decls.clock_spec.errors.throw ++ decls.command_spec.errors.abort(),
        }, u8) {
            const start: time.TimeSpec = try meta.wrap(time.get(decls.clock_spec, .realtime));
            const ret: u8 = try meta.wrap(proc.command(decls.command_spec, meta.manyToSlice(args[0]), args, builder.vars));
            const finish: time.TimeSpec = try meta.wrap(time.get(decls.clock_spec, .realtime));
            ts.* = time.diff(finish, start);
            return ret;
        }
        extern fn forwardToExecuteCloneThreaded(
            builder: *Builder,
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            target: *Target,
            task: Task,
            arena_index: AddressSpace.Index,
            depth: u64,
            stack_address: u64,
        ) void;
        comptime {
            asm (@embedFile("./build/forwardToExecuteCloneThreaded.s"));
        }
        pub export fn executeCommandThreaded(
            builder: *Builder,
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            target: *Target,
            task: Task,
            arena_index: AddressSpace.Index,
            depth: u64,
        ) callconv(.C) void {
            if (max_thread_count == 0) {
                unreachable;
            }
            var allocator: Allocator = Allocator.init(address_space, arena_index);
            defer allocator.deinit(address_space, arena_index);
            if (switch (task) {
                .build => meta.wrap(executeBuildCommand(builder, &allocator, target, depth)) catch false,
                .run => meta.wrap(executeRunCommand(builder, &allocator, target, depth)) catch false,
            }) {
                target.assertTransform(task, .blocking, .finished);
            } else {
                target.assertTransform(task, .blocking, .failed);
            }
            builtin.assert(thread_space.atomicUnset(arena_index));
        }
        pub fn executeCommand(
            builder: *Builder,
            allocator: *Allocator,
            target: *Target,
            task: Task,
            depth: u64,
        ) sys.Call(.{
            .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
            .abort = decls.clock_spec.errors.throw ++ decls.command_spec.errors.abort(),
        }, void) {
            if (switch (task) {
                .build => try meta.wrap(executeBuildCommand(builder, allocator, target, depth)),
                .run => try meta.wrap(executeRunCommand(builder, allocator, target, depth)),
            }) {
                target.assertTransform(task, .blocking, .finished);
            } else {
                target.assertTransform(task, .blocking, .failed);
            }
        }
        fn buildWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            @setRuntimeSafety(false);
            var ret: Args = Args.init(allocator, buildLength(builder, target, root_path));
            ret.writeMany(builder.zig_exe);
            ret.writeOne(0);
            ret.writeMany(tok.build_prefix);
            ret.writeMany(@tagName(target.build_cmd.kind));
            ret.writeOne(0);
            command_line.buildWrite(target.build_cmd, &ret);
            ret.writeFormat(root_path);
            ret.writeOne(0);
            ret.writeOne(0);
            ret.undefine(1);
            return ret.referAllDefinedWithSentinel(0);
        }
        fn buildLength(builder: *Builder, target: *Target, root_path: types.Path) u64 {
            if (builder_spec.options.max_command_line) |len| return len;
            var len: u64 = builder.zig_exe.len +% 1;
            len +%= 6 +% @tagName(target.build_cmd.kind).len +% 1;
            len +%= command_line.buildLength(target.build_cmd);
            len +%= root_path.formatLength();
            len +%= 1;
            return len;
        }
        fn executeBuildCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64) sys.Call(.{
            .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
            .abort = decls.clock_spec.errors.abort ++ decls.command_spec.errors.abort(),
        }, bool) {
            var build_time: time.TimeSpec = undefined;
            const bin_path: [:0]const u8 = try meta.wrap(
                target.binaryRelative(allocator),
            );
            const root_path: types.Path = target.rootSourcePath(builder);
            const args: [:0]u8 = try meta.wrap(
                builder.buildWrite(target, allocator, root_path),
            );
            const ptrs: [][*:0]u8 = try meta.wrap(
                makeArgPtrs(allocator, args),
            );
            const old_size: u64 = builder.getFileSize(bin_path);
            const rc: u8 = try meta.wrap(
                builder.system(ptrs, &build_time),
            );
            const new_size: u64 = builder.getFileSize(bin_path);
            if (depth < builder_spec.options.max_relevant_depth) {
                debug.buildNotice(target.name, build_time, old_size, new_size);
            }
            if (target.build_cmd.kind == .exe) {
                target.assertTransform(.run, .unavailable, .ready);
            }
            return rc == 0;
        }
        fn executeRunCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64) sys.Call(.{
            .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
            .abort = decls.clock_spec.errors.abort ++ decls.command_spec.errors.abort(),
        }, bool) {
            var run_time: time.TimeSpec = undefined;
            const args: [:0]u8 = target.run_args.referAllDefinedWithSentinel(0);
            const ptrs: [][*:0]u8 = try meta.wrap(
                makeArgPtrs(allocator, args),
            );
            const rc: u8 = try meta.wrap(
                builder.system(ptrs, &run_time),
            );
            if (rc != 0 or depth <= builder_spec.options.max_relevant_depth) {
                debug.runNotice(target.name, run_time, rc);
            }
            return rc == 0;
        }
        pub fn init(args: [][*:0]u8, vars: [][*:0]u8) sys.Call(.{
            .throw = builder_spec.errors.mkdir.throw ++ builder_spec.errors.path.throw ++
                builder_spec.errors.close.throw ++ builder_spec.errors.create.throw,
            .abort = builder_spec.errors.mkdir.abort ++ builder_spec.errors.path.abort ++
                builder_spec.errors.close.abort ++ builder_spec.errors.create.abort,
        }, Builder) {
            const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
            const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
            const cache_root: [:0]const u8 = meta.manyToSlice(args[3]);
            const global_cache_root: [:0]const u8 = meta.manyToSlice(args[4]);
            if (max_thread_count != 0) {
                try meta.wrap(mem.map(decls.map_spec, stack_lb_addr, stack_up_addr -% stack_lb_addr));
            }
            const build_root_fd: u64 = try meta.wrap(file.path(decls.path_spec, build_root));
            try meta.wrap(writeEnvDecls(zig_exe, build_root, cache_root, global_cache_root, build_root_fd)); 
            return .{
                .zig_exe = zig_exe,
                .build_root = build_root,
                .cache_root = cache_root,
                .global_cache_root = global_cache_root,
                .args = args,
                .vars = vars,
                .dir_fd = build_root_fd,
            };
        }
        pub fn addGroup(builder: *Builder, allocator: *Allocator, name: [:0]const u8) !*Group {
            if (builder.grps.len == builder.grps_len) {
                builder.grps = try meta.wrap(allocator.reallocateIrreversible(*Group, builder.grps, (builder.grps_len +% 1) *% 2));
            }
            const ret: *Group = create(allocator, Group);
            builder.grps[builder.grps_len] = ret;
            builder.grps_len +%= 1;
            ret.* = .{ .name = name, .builder = builder, .trgs = &.{}, .trgs_len = 0 };
            return ret;
        }
        pub fn createTarget(
            builder: *Builder,
            allocator: *Allocator,
            name: [:0]const u8,
            root: [:0]const u8,
            comptime extra: anytype,
        ) !*Target {
            const ret: *Target = create(allocator, Target);
            ret.root = root;
            ret.name = name;
            ret.build_cmd = buildExtra(create(allocator, types.BuildCommand), extra);
            ret.assertTransform(.build, .unavailable, .ready);
            ret.emitBinary(allocator, builder);
            ret.build_cmd.name = ret.name;
            ret.build_cmd.main_pkg_path = builder.build_root;
            ret.build_cmd.cache_root = builder.cache_root;
            ret.build_cmd.global_cache_root = builder.global_cache_root;
            if (ret.build_cmd.kind == .exe) {
                ret.run_args = Args.init(allocator, 4096);
                ret.run_args.writeFormat(ret.binaryPath());
                ret.run_args.writeOne(0);
            }
            return ret;
        }
        fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.FileStatus {
            return meta.wrap(file.fstatAt(.{ .errors = .{ .throw = sys.stat_errors } }, builder.dir_fd, name)) catch null;
        }
        fn getFileSize(builder: *Builder, name: [:0]const u8) u64 {
            return if (getFileStatus(builder, name)) |st| st.size else 0;
        }
        fn makeZigCacheDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_cache_dir, file.dir_mode));
        }
        fn makeZigOutDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_out_dir, file.dir_mode));
        }
        fn makeBinDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_exe_out_dir, file.dir_mode));
        }
        fn makeAuxDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_aux_out_dir, file.dir_mode));
        }
        fn writeEnvDecls(
            zig_exe: [:0]const u8,
            build_root: [:0]const u8,
            cache_root: [:0]const u8,
            global_cache_root: [:0]const u8,
            build_root_fd: u64,
        ) sys.Call(.{
            .throw = decls.mkdir_spec.errors.throw ++ decls.create_spec.errors.throw ++
                decls.write_spec.errors.throw ++ decls.close_spec.errors.throw,
            .abort = decls.mkdir_spec.errors.abort ++ decls.create_spec.errors.abort ++
                decls.write_spec.errors.abort ++ decls.close_spec.errors.abort,
        }, void) {
            const cache_root_fd: u64 = try meta.wrap(file.path(decls.path_spec, cache_root));
            const env_fd: u64 = try meta.wrap(file.createAt(decls.create_spec, cache_root_fd, tok.env_name, file.file_mode));
            for ([_][]const u8{
                tok.zig_exe_decl,                           zig_exe,
                tok.end_expr ++ tok.build_root_decl,        build_root,
                tok.end_expr ++ tok.cache_root_decl,        cache_root,
                tok.end_expr ++ tok.global_cache_root_decl, global_cache_root,
                tok.end_expr,
            }) |s| {
                try meta.wrap(file.write(decls.write_spec, env_fd, s));
            }
            try meta.wrap(file.close(decls.close_spec, env_fd));
            try meta.wrap(file.close(decls.close_spec, cache_root_fd));
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, build_root_fd, tok.zig_out_dir, file.dir_mode));
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, build_root_fd, tok.exe_out_dir, file.dir_mode));
        }
        fn targetScanInternal(
            target: *Target,
            arena_index: AddressSpace.Index,
            task: Task,
        ) void {
            if (target.lock.get(task) == .failed) {
                target.assertTransform(task, .blocking, .failed);
                if (max_thread_count != 0) {
                    if (arena_index != max_thread_count) {
                        builtin.proc.exitWithError(error.DependencyFailed, 2);
                    }
                }
            }
        }
        fn dependencyScan(
            target: *Target,
            task: Task,
            arena_index: AddressSpace.Index,
        ) bool {
            @setRuntimeSafety(false);
            for (target.dependencies()) |*dep| {
                targetScanInternal(dep.target, arena_index, dep.task);
            }
            for (target.dependencies()) |*dep| {
                if (dep.target.lock.get(dep.task) == .failed) {
                    return target.transform(task, .blocking, .failed);
                }
                if (dep.target.lock.get(dep.task) != dep.state) {
                    return true;
                }
            }
            return false;
        }
        fn groupScan(group: *Group, task: Task) void {
            lo: while (true) {
                for (group.targets()) |target| {
                    if (target.lock.get(task) == .blocking) continue :lo;
                } else {
                    break;
                }
            }
        }
        const decls = struct {
            const path_spec: file.PathSpec = builder_spec.path();
            const close_spec: file.CloseSpec = builder_spec.close();
            const map_spec: mem.MapSpec = builder_spec.map();
            const stat_spec: file.StatSpec = builder_spec.stat();
            const unmap_spec: mem.UnmapSpec = builder_spec.unmap();
            const clock_spec: time.ClockSpec = builder_spec.clock();
            const sleep_spec: time.SleepSpec = builder_spec.sleep();
            const clone_spec: proc.CloneSpec = builder_spec.clone();
            const write_spec: file.WriteSpec = builder_spec.write();
            const create_spec: file.CreateSpec = builder_spec.create();
            const mkdir_spec: file.MakeDirSpec = builder_spec.mkdir();
            const command_spec: proc.CommandSpec = builder_spec.command();
        };
        const tok = struct {
            const env_name: [:0]const u8 = "env.zig";
            const build_name: [:0]const u8 = "build.zig";
            const build_prefix: [:0]const u8 = "build-";
            const zig_out_dir: [:0]const u8 = "zig-out/";
            const zig_cache_dir: [:0]const u8 = "zig-cache/";
            const exe_out_dir: [:0]const u8 = "zig-out/bin/";
            const aux_out_dir: [:0]const u8 = "zig-out/aux/";
            const lib_ext: [:0]const u8 = ".so";
            const obj_ext: [:0]const u8 = ".o";
            const asm_ext: [:0]const u8 = ".s";
            const llvm_bc_ext: [:0]const u8 = ".bc";
            const llvm_ir_ext: [:0]const u8 = ".ll";
            const header_ext: [:0]const u8 = ".h";
            const analysis_ext: [:0]const u8 = ".json";
            const zig_exe_decl: [:0]const u8 = "pub const zig_exe: [:0]const u8 = \"";
            const build_root_decl: [:0]const u8 = "pub const build_root: [:0]const u8 = \"";
            const cache_root_decl: [:0]const u8 = "pub const cache_dir: [:0]const u8 = \"";
            const global_cache_root_decl: [:0]const u8 = "pub const global_cache_dir: [:0]const u8 = \"";
            const end_expr: [:0]const u8 = "\";\n";
        };
        pub const debug = struct {
            const ChangedSize = fmt.ChangedBytesFormat(.{
                .dec_style = "\x1b[92m-",
                .inc_style = "\x1b[91m+",
            });
            const about_run_s: [:0]const u8 = builtin.debug.about("run");
            const about_build_s: [:0]const u8 = builtin.debug.about("build");
            const about_format_s: [:0]const u8 = builtin.debug.about("format");
            const about_state_0_s: [:0]const u8 = builtin.debug.about("state");
            const about_state_1_s: [:0]const u8 = builtin.debug.about("state-fault");
            pub fn transformNotice(target: *Target, task: Task, old_state: State, new_state: State) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &.{
                    about_state_0_s, target.name,
                    ".",             @tagName(task),
                    ", ",            @tagName(old_state),
                    " -> ",          @tagName(new_state),
                    "\n",
                });
            }
            pub fn noTransformNotice(target: *Target, task: Task, old_state: State, new_state: State) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &.{
                    about_state_0_s, target.name,
                    ".",             @tagName(task),
                    ", (",           @tagName(target.lock.get(task)),
                    ") ",            @tagName(old_state),
                    " -!!-> ",       @tagName(new_state),
                    "\n",
                });
            }
            pub fn noTransformFault(target: *Target, task: Task, old_state: State, new_state: State) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &.{
                    about_state_1_s, target.name,
                    ".",             @tagName(task),
                    ", (",           @tagName(target.lock.get(task)),
                    ") ",            @tagName(old_state),
                    " -!!-> ",       @tagName(new_state),
                    "\n",
                });
            }
            fn buildNotice(name: [:0]const u8, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                var len: u64 = mach.memcpyMulti(&buf, &.{ about_build_s, name, ", " });
                if (old_size == 0) {
                    len +%= mach.memcpyMulti(buf[len..].ptr, &.{ "\x1b[93m", builtin.fmt.ud64(new_size).readAll(), "*\x1b[0m bytes " });
                } else if (new_size == old_size) {
                    len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(new_size).readAll(), " bytes, ",
                    });
                } else if (new_size > old_size) {
                    len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(old_size).readAll(),             "(\x1b[91m+",
                        builtin.fmt.ud64(new_size -% old_size).readAll(), "\x1b[0m) => ",
                        builtin.fmt.ud64(new_size).readAll(),             " bytes, ",
                    });
                } else {
                    len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(old_size).readAll(),             "(\x1b[92m-",
                        builtin.fmt.ud64(old_size -% new_size).readAll(), "\x1b[0m) => ",
                        builtin.fmt.ud64(new_size).readAll(),             " bytes, ",
                    });
                }
                len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                    builtin.fmt.ud64(durat.sec).readAll(),        ".",
                    builtin.fmt.nsec(durat.nsec).readAll()[0..3], "s\n",
                });
                builtin.debug.logAlways(buf[0..len]);
            }
            fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: ?u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                var len: u64 = mach.memcpyMulti(&buf, &.{ about, name, ", " });
                if (rc) |return_code| {
                    len +%= mach.memcpyMulti(buf[len..].ptr, &.{ "rc=", builtin.fmt.ud64(return_code).readAll(), ", " });
                }
                len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                    builtin.fmt.ud64(durat.sec).readAll(),        ".",
                    builtin.fmt.nsec(durat.nsec).readAll()[0..3], "s\n",
                });
                builtin.debug.logAlways(buf[0..len]);
            }
            inline fn runNotice(name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
                simpleTimedNotice(about_run_s, name, durat, rc);
            }
            inline fn formatNotice(name: [:0]const u8, durat: time.TimeSpec) void {
                simpleTimedNotice(about_format_s, name, durat, null);
            }
            pub fn writeAndWalk(target: *Target) void {
                var buf0: [1024 * 1024]u8 = undefined;
                var buf1: [4096]u8 = undefined;
                mach.memcpy(&buf0, target.name.ptr, target.name.len);
                var len: u64 = target.name.len;
                len = writeAndWalkInternal(&buf0, len, &buf1, 0, target);
                builtin.debug.logAlways(buf0[0..len]);
            }
            fn writeAndWalkInternal(buf0: *[1024 * 1024]u8, len0: u64, buf1: *[4096]u8, len1: u64, target: *Builder.Target) u64 {
                @setRuntimeSafety(false);
                const deps: []Builder.Dependency = target.dependencies();
                var len: u64 = len0;
                buf0[len] = '\n';
                len = len +% 1;
                for (deps, 0..) |dep, idx| {
                    mach.memcpy(buf1[len1..].ptr, if (idx == deps.len -% 1) "  " else "| ", 2);
                    mach.memcpy(buf0[len..].ptr, buf1, len1 +% 2);
                    len = len +% len1 +% 2;
                    mach.memcpy(buf0[len..].ptr, if (idx == deps.len -% 1) "\x08\x08`-" else "\x08\x08|-", 4);
                    len = len +% 4;
                    mach.memcpy(buf0[len..].ptr, if (dep.target.deps_len == 0) "> " else "+ ", 2);
                    len = len +% 2;
                    mach.memcpy(buf0[len..].ptr, dep.target.name.ptr, dep.target.name.len);
                    len = len +% target.name.len;
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep.target);
                }
                return len;
            }
            pub fn builderCommandNotice(builder: *Builder, show_root: bool, show_descr: bool, show_deps: bool) void {
                @setRuntimeSafety(false);
                const alignment: u64 = 8;
                var buf0: [1024 * 1024]u8 = undefined;
                var buf1: [4096]u8 = undefined;
                var len: u64 = 0;
                var name_max_width: u64 = 0;
                var root_max_width: u64 = 0;
                for (builder.groups()) |group| {
                    for (group.targets()) |target| {
                        name_max_width = @max(name_max_width, target.name.len);
                        if (show_root) {
                            root_max_width = @max(root_max_width, target.root.len);
                        }
                    }
                }
                name_max_width += alignment;
                root_max_width += alignment;
                name_max_width &= ~(alignment - 1);
                root_max_width &= ~(alignment - 1);
                mach.memset(&buf1, ' ', 4);
                for (builder.groups()) |group| {
                    len +%= builtin.debug.writeMulti(buf0[len..], &.{ group.name, ":\n" });
                    for (group.targets()) |target| {
                        mach.memset(buf0[len..].ptr, ' ', 4);
                        len +%= 4;
                        mach.memcpy(buf0[len..].ptr, target.name.ptr, target.name.len);
                        len +%= target.name.len;
                        var count: u64 = name_max_width - target.name.len;
                        if (show_root) {
                            mach.memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0[len..].ptr, target.root.ptr, target.root.len);
                            len +%= target.root.len;
                        }
                        if (show_descr) {
                            count = root_max_width - target.root.len;
                            mach.memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            if (target.descr) |descr| {
                                mach.memcpy(buf0[len..].ptr, descr.ptr, descr.len);
                                len +%= descr.len;
                            }
                        }
                        if (show_deps) {
                            mach.memcpy(buf0[len..].ptr, "\x1b[2m", 4);
                            len +%= 4;
                            len = writeAndWalkInternal(&buf0, len, &buf1, 8, target);
                            mach.memcpy(buf0[len..].ptr, "\x1b[0m", 4);
                            len +%= 4;
                        } else {
                            buf0[len] = '\n';
                            len +%= 1;
                        }
                    }
                }
                builtin.debug.logAlways(buf0[0..len]);
            }
        };
    };
    return Type;
}
fn duplicate(allocator: anytype, comptime T: type, values: []const T) [:builtin.zero(T)]T {
    var buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(T, values.len, builtin.zero(T));
    mach.memcpy(buf.ptr, values.ptr, values.len);
    return buf;
}
fn duplicate2(allocator: anytype, comptime T: type, values: []const []const T) [][:builtin.zero(T)]T {
    var buf: [][:0]u8 = allocator.allocateIrreversible([:builtin.zero(T)]T, values.len);
    var idx: u64 = 0;
    for (values) |value| {
        buf[idx] = duplicate(allocator, value);
        idx +%= 1;
    }
}
fn concatenate(allocator: anytype, comptime T: type, values: []const []const T) [:builtin.zero(T)]T {
    var len: u64 = 0;
    for (values) |value| len +%= value.len;
    const buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, len, builtin.zero(T));
    var idx: u64 = 0;
    for (values) |value| {
        mach.memcpy(buf[idx..].ptr, value.ptr, value.len);
        idx +%= value.len;
    }
    return buf;
}
fn makeArgPtrs(allocator: anytype, args: [:0]u8) [][*:0]u8 {
    const ptrs: [][*:0]u8 = argsPointers(allocator, args);
    var len: u64 = 0;
    var idx: u64 = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0) {
            ptrs[len] = args[pos..idx :0];
            len +%= 1;
            pos = idx +% 1;
        }
    }
    ptrs[len] = builtin.zero([*:0]u8);
    return ptrs[0..len];
}
fn argsPointers(allocator: anytype, args: [:0]u8) [][*:0]u8 {
    var count: u64 = 0;
    for (args) |value| {
        count +%= @boolToInt(value == 0);
    }
    return allocator.allocateIrreversible([*:0]u8, count +% 1);
}
fn buildExtra(build_cmd: *types.BuildCommand, comptime extra: anytype) *types.BuildCommand {
    inline for (@typeInfo(@TypeOf(extra)).Struct.fields) |field| {
        @field(build_cmd, field.name) = @field(extra, field.name);
    }
    return build_cmd;
}
fn reallocate(allocator: anytype, comptime T: type, buf: []T, count: u64) []T {
    @setRuntimeSafety(false);
    const ret: [:builtin.zero(T)]T = allocate(allocator, T, count);
    mach.memcpy(@ptrCast([*]u8, ret.ptr), @ptrCast([*]const u8, buf.ptr), buf.len *% @sizeOf(T));
    return ret;
}
fn allocateInternal(allocator: anytype, count: u64, size_of: u64, align_of: u64) u64 {
    @setRuntimeSafety(false);
    const s_ab_addr: u64 = allocator.alignAbove(align_of);
    const s_up_addr: u64 = count *% size_of;
    mach.memset(@intToPtr([*]u8, s_up_addr), 0, size_of);
    allocator.allocate(mach.cmov64(count != 1, s_up_addr, s_up_addr +% size_of));
    return s_ab_addr;
}
fn allocate(allocator: anytype, comptime T: type, count: u64) []T {
    @setRuntimeSafety(false);
    const s_ab_addr: u64 = allocateInternal(allocator, count, @sizeOf(T), @alignOf(T));
    return mem.pointerSliceWithSentinel(T, s_ab_addr, count, builtin.zero(T));
}
fn create(allocator: anytype, comptime T: type) *T {
    const s_ab_addr: u64 = allocator.alignAbove(@alignOf(T));
    allocator.allocate(s_ab_addr +% @sizeOf(T));
    return mem.pointerOne(T, s_ab_addr);
}
fn copy(comptime T: type, dest: *T, src: *const T) void {
    mach.memcpy(@ptrCast([*]u8, dest), @ptrCast([*]const u8, src), @sizeOf(T));
}
