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
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");

const types = @import("./build/types.zig");
const command_line = @import("./build/command_line.zig");

pub usingnamespace types;

pub const BuilderSpec = struct {
    options: Options = .{},
    logging: Logging,
    errors: Errors,
    pub const Options = struct {
        expected_status: u8 = 0,
        max_command_line: ?u64 = 65536,
        max_command_args: ?u64 = 1024,
        max_relevant_depth: u64 = 255,
        dep_sleep_nsec: u64 = 50000,
        max_thread_count: u64 = 16,
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        stack_lb_addr: u64 = 0x700000000000,
        show_state: bool = false,
        env_name: [:0]const u8 = "env.zig",
        build_name: [:0]const u8 = "build.zig",
        zig_out_dir: [:0]const u8 = "zig-out/",
        zig_cache_dir: [:0]const u8 = "zig-cache/",
        exe_out_dir: [:0]const u8 = "zig-out/bin/",
        aux_out_dir: [:0]const u8 = "zig-out/aux/",
        h_ext: [:0]const u8 = ".h",
        lib_ext: [:0]const u8 = ".so",
        obj_ext: [:0]const u8 = ".o",
        asm_ext: [:0]const u8 = ".s",
        llvm_bc_ext: [:0]const u8 = ".bc",
        llvm_ir_ext: [:0]const u8 = ".ll",
        analysis_ext: [:0]const u8 = ".json",
        docs_ext: [:0]const u8 = ".html",
        implib_ext: [:0]const u8 = ".lib",
    };
    pub const Logging = packed struct {
        path: builtin.Logging.AcquireError,
        create: builtin.Logging.AcquireError,
        close: builtin.Logging.ReleaseError,
        mkdir: builtin.Logging.SuccessError,
        write: builtin.Logging.SuccessError,
        map: builtin.Logging.AcquireError,
        unmap: builtin.Logging.AcquireError,
        fork: builtin.Logging.SuccessError,
        waitpid: builtin.Logging.SuccessError,
        execve: builtin.Logging.AttemptError,
        mknod: builtin.Logging.SuccessError,
        dup3: builtin.Logging.SuccessError,
        stat: builtin.Logging.SuccessErrorFault,
    };
    pub const Errors = struct {
        map: sys.ErrorPolicy,
        unmap: sys.ErrorPolicy,
        path: sys.ErrorPolicy,
        clock: sys.ErrorPolicy,
        sleep: sys.ErrorPolicy,
        stat: sys.ErrorPolicy,
        create: sys.ErrorPolicy,
        mkdir: sys.ErrorPolicy,
        close: sys.ErrorPolicy,
        write: sys.ErrorPolicy,
        fork: sys.ErrorPolicy,
        execve: sys.ErrorPolicy,
        waitpid: sys.ErrorPolicy,
        mknod: sys.ErrorPolicy,
        dup3: sys.ErrorPolicy,
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
    fn stat(comptime builder_spec: BuilderSpec) file.StatusSpec {
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
            .idx_type = u64,
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
        pub const Args = Allocator.StructuredVectorLowAlignedWithSentinel(u8, 0, 8);

        pub const Target = struct {
            name: [:0]const u8,
            descr: ?[:0]const u8 = null,
            root: [:0]const u8,
            lock: types.Lock,
            build_cmd: *types.BuildCommand,
            deps: []Dependency = &.{},
            deps_len: u64 = 0,
            args: [][*:0]u8 = &.{},
            args_len: u64 = 0,
            pub const Dependency = struct {
                target: *Target,
                task: types.Task,
                state: types.State,
            };
            fn acquireThread(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: types.Task,
                depth: u64,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.abort ++ decls.command_spec.errors.abort(),
            }, void) {
                if (max_thread_count == 0) {
                    try meta.wrap(impl.executeCommand(builder, allocator, target, task, depth));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (thread_space.atomicSet(arena_index)) {
                            const stack_ab_addr: u64 = ThreadSpace.high(arena_index) -% 4096;
                            return impl.forwardToExecuteCloneThreaded(builder, address_space, thread_space, target, task, arena_index, depth, stack_ab_addr);
                        }
                    }
                    try meta.wrap(impl.executeCommand(builder, allocator, target, task, depth));
                }
            }
            fn acquireLock(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: types.Task,
                arena_index: AddressSpace.Index,
                depth: u64,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.abort ++ decls.command_spec.errors.throw(),
            }, void) {
                if (task == .run and target.build_cmd.kind == .exe) {
                    try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, .build, arena_index, 0));
                    if (target.lock.get(.build) == .failed) {
                        target.assertExchange(.run, .unavailable, .failed);
                    }
                }
                if (target.exchange(task, .ready, .blocking)) {
                    for (target.buildDependencies()) |dep| {
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
                task: types.Task,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.throw ++ decls.sleep_spec.errors.abort ++ decls.command_spec.errors.throw(),
            }, void) {
                try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, task, max_thread_count, 0));
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(decls.sleep_spec, decls.time_spec));
                }
            }
            fn binaryRelative(target: *Target, allocator: *Allocator) [:0]const u8 {
                switch (target.build_cmd.kind) {
                    .exe => return concatenate(allocator, &.{
                        builder_spec.options.exe_out_dir,
                        target.name,
                    }),
                    .lib => return concatenate(allocator, &.{
                        builder_spec.options.exe_out_dir,
                        target.name,
                        builder_spec.options.lib_ext,
                    }),
                    .obj => return concatenate(allocator, &.{
                        builder_spec.options.exe_out_dir,
                        target.name,
                        builder_spec.options.obj_ext,
                    }),
                }
            }
            fn auxiliaryRelative(target: *Target, allocator: *Allocator, kind: types.AuxOutputMode) [:0]const u8 {
                switch (kind) {
                    .@"asm" => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.asm_ext,
                    }),
                    .llvm_ir => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.llvm_ir_ext,
                    }),
                    .llvm_bc => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.llvm_bc_ext,
                    }),
                    .h => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.h_ext,
                    }),
                    .docs => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.docs_ext,
                    }),
                    .analysis => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.analysis_ext,
                    }),
                    .implib => return concatenate(allocator, &.{
                        builder_spec.options.aux_out_dir,
                        target.name,
                        builder_spec.options.implib_ext,
                    }),
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
            fn createAuxiliaryPath(target: *Target, allocator: *Allocator, builder: *Builder, kind: types.AuxOutputMode) types.Path {
                return .{ .absolute = builder.build_root, .relative = auxiliaryRelative(target, allocator, kind) };
            }
            pub fn emitBinary(target: *Target, allocator: *Allocator, builder: *Builder) void {
                target.build_cmd.emit_bin = .{ .yes = createBinaryPath(target, allocator, builder) };
            }
            pub fn emitAuxiliary(target: *Target, allocator: *Allocator, builder: *Builder, kind: types.AuxOutputMode) void {
                target.build_cmd.emit_bin = .{ .yes = createAuxiliaryPath(target, allocator, builder, kind) };
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
            fn exchange(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) bool {
                const ret: bool = target.lock.atomicExchange(task, old_state, new_state);
                if (builtin.logging_general.Success or builder_spec.options.show_state) {
                    if (ret) {
                        debug.exchangeNotice(target, task, old_state, new_state);
                    } else {
                        debug.noExchangeNotice(target, task, old_state, new_state);
                    }
                }
                return ret;
            }
            fn assertExchange(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                const res: bool = target.lock.atomicExchange(task, old_state, new_state);
                if (res) {
                    if (builtin.logging_general.Success or builder_spec.options.show_state) {
                        debug.exchangeNotice(target, task, old_state, new_state);
                    }
                } else {
                    if (builtin.logging_general.Fault or builder_spec.options.show_state) {
                        debug.noExchangeFault(target, task, old_state, new_state);
                    }
                    builtin.proc.exit(2);
                }
            }
            pub fn addFile(target: *Target, allocator: *Allocator, path: types.Path) void {
                @setRuntimeSafety(false);
                if (target.build_cmd.files) |*files| {
                    const buf: []types.Path = reallocate(allocator, types.Path, @constCast(files.*), files.len +% 1);
                    buf[files.len] = path;
                    target.build_cmd.files = buf;
                } else {
                    const buf: []types.Path = allocate(allocator, types.Path, 1);
                    buf[0] = path;
                    target.build_cmd.files = buf;
                }
            }
            pub fn addDependency(target: *Target, allocator: *Allocator, dependency: *Target, task: types.Task, state: types.State) void {
                @setRuntimeSafety(false);
                if (target.deps_len == target.deps.len) {
                    target.deps = reallocate(allocator, Dependency, target.deps, (target.deps_len +% 1) *% 2);
                }
                target.deps[target.deps_len] = .{ .target = dependency, .task = task, .state = state };
                target.deps_len +%= 1;
            }
            pub fn addRunArgument(target: *Target, allocator: *Allocator, arg: []const u8) void {
                @setRuntimeSafety(false);
                if (target.args_len == target.args.len) {
                    target.args = reallocate(allocator, [*:0]u8, target.args, (target.args_len +% 1) *% 2);
                }
                target.args[target.args_len] = strdup(allocator, arg).ptr;
                target.args_len +%= 1;
            }
            fn addRunArguments(target: *Target, allocator: *Allocator, builder: *Builder) void {
                @setRuntimeSafety(false);
                const run_args_len: u64 = builder.args.len -% builder.args_len;
                if (target.args.len <= target.args_len +% run_args_len) {
                    target.args = reallocate(allocator, [*:0]u8, target.args, target.args_len +% run_args_len +% 1);
                }
                for (builder.args[builder.args_len..]) |run_arg| {
                    target.args[target.args_len] = run_arg;
                    target.args_len +%= 1;
                }
                target.args[target.args_len] = builtin.zero([*:0]u8);
            }
            pub fn buildDependencies(target: *const Target) []Dependency {
                @setRuntimeSafety(false);
                return target.deps[0..target.deps_len];
            }
            pub fn runArguments(target: *const Target) [][*:0]u8 {
                @setRuntimeSafety(false);
                return target.args[0..target.args_len];
            }
        };
        pub const Group = struct {
            name: [:0]const u8,
            builder: *Builder,
            trgs: []*Target = &.{},
            trgs_len: u64 = 0,
            pub fn executeToplevel(
                group: *Group,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                task: types.Task,
            ) !void {
                for (group.targets()) |target| {
                    try meta.wrap(target.acquireLock(address_space, thread_space, allocator, group.builder, task, max_thread_count, 1));
                }
                while (groupWait(group, task)) {
                    try meta.wrap(time.sleep(decls.sleep_spec, decls.time_spec));
                }
            }
            pub fn addTarget(
                group: *Group,
                allocator: *Allocator,
                extra: anytype,
                name: [:0]const u8,
                root: [:0]const u8,
            ) !*Target {
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = reallocate(allocator, *Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = create(allocator, Target);
                ret.build_cmd = create(allocator, types.BuildCommand);
                buildExtra(ret.build_cmd, extra);
                group.builder.createTarget(allocator, name, root, ret);
                group.trgs[group.trgs_len] = ret;
                group.trgs_len +%= 1;
                return ret;
            }
            pub fn targets(group: *const Group) []*Target {
                @setRuntimeSafety(false);
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
            @setRuntimeSafety(false);
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
        // This namespace exists so that programs referencing builder types do
        // not necessitate compiling `executeCommandThreaded`. These will only
        // be compiled if their callers are compiled.
        const impl = struct {
            extern fn forwardToExecuteCloneThreaded(
                builder: *Builder,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                target: *Target,
                task: types.Task,
                arena_index: AddressSpace.Index,
                depth: u64,
                stack_address: u64,
            ) void;
            comptime {
                asm (@embedFile("./build/forwardToExecuteCloneThreaded.s"));
            }
            export fn executeCommandThreaded(
                builder: *Builder,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                target: *Target,
                task: types.Task,
                arena_index: AddressSpace.Index,
                depth: u64,
            ) void {
                if (max_thread_count == 0) {
                    unreachable;
                }
                var allocator: Allocator = Allocator.init(address_space, arena_index);
                defer allocator.deinit(address_space, arena_index);
                if (switch (task) {
                    .build => meta.wrap(executeBuildCommand(builder, &allocator, target, depth)) catch false,
                    .run => meta.wrap(executeRunCommand(builder, &allocator, target, depth)) catch false,
                }) {
                    target.assertExchange(task, .blocking, .finished);
                } else {
                    target.assertExchange(task, .blocking, .failed);
                }
                builtin.assert(thread_space.atomicUnset(arena_index));
            }
            fn executeCommand(
                builder: *Builder,
                allocator: *Allocator,
                target: *Target,
                task: types.Task,
                depth: u64,
            ) sys.Call(.{
                .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
                .abort = decls.clock_spec.errors.throw ++ decls.command_spec.errors.abort(),
            }, void) {
                if (switch (task) {
                    .build => try meta.wrap(executeBuildCommand(builder, allocator, target, depth)),
                    .run => try meta.wrap(executeRunCommand(builder, allocator, target, depth)),
                }) {
                    target.assertExchange(task, .blocking, .finished);
                } else {
                    target.assertExchange(task, .blocking, .failed);
                }
            }
        };
        fn buildWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            @setRuntimeSafety(false);
            var ret: Args = Args.init(allocator, buildLength(builder, target, root_path));
            ret.writeMany(builder.zig_exe);
            ret.writeOne(0);
            ret.writeMany("build-");
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
                target.assertExchange(.run, .unavailable, .ready);
            }
            return rc == builder_spec.options.expected_status;
        }
        fn executeRunCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64) sys.Call(.{
            .throw = decls.clock_spec.errors.throw ++ decls.command_spec.errors.throw(),
            .abort = decls.clock_spec.errors.abort ++ decls.command_spec.errors.abort(),
        }, bool) {
            var run_time: time.TimeSpec = undefined;
            target.addRunArguments(allocator, builder);
            const args: [][*:0]u8 = target.runArguments();
            const rc: u8 = try meta.wrap(
                builder.system(args, &run_time),
            );
            if (rc != 0 or depth <= builder_spec.options.max_relevant_depth) {
                debug.simpleTimedNotice(debug.about_run_s, target.name, run_time, rc);
            }
            return rc == builder_spec.options.expected_status;
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
                .args_len = args.len,
                .vars = vars,
                .dir_fd = build_root_fd,
            };
        }
        pub fn addGroup(builder: *Builder, allocator: *Allocator, name: [:0]const u8) !*Group {
            @setRuntimeSafety(false);
            if (builder.grps.len == builder.grps_len) {
                builder.grps = try meta.wrap(reallocate(allocator, *Group, builder.grps, (builder.grps_len +% 1) *% 2));
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
            in: *Target,
        ) void {
            in.name = name;
            in.root = root;
            in.assertExchange(.build, .unavailable, .ready);
            in.emitBinary(allocator, builder);
            in.build_cmd.name = in.name;
            in.build_cmd.main_pkg_path = builder.build_root;
            in.build_cmd.cache_root = builder.cache_root;
            in.build_cmd.global_cache_root = builder.global_cache_root;
            if (in.build_cmd.kind == .exe) {
                const bin_path: types.Path = in.binaryPath();
                assertKindOrNothing(builder.dir_fd, bin_path.relative.?, .regular);
                in.addRunArgument(allocator, concatenate(allocator, &.{ bin_path.absolute, "/", bin_path.relative.? }));
            }
        }
        fn assertKindOrNothing(dir_fd: u64, name: [:0]const u8, kind: file.Kind) void {
            file.assertAt(decls.fstat_spec, dir_fd, name, kind) catch |stat_error| {
                builtin.assert(stat_error == error.NoSuchFileOrDirectory);
            };
        }
        fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.Status {
            return file.statusAt(decls.fstat_spec, builder.dir_fd, name) catch null;
        }
        fn getFileSize(builder: *Builder, name: [:0]const u8) u64 {
            return if (getFileStatus(builder, name)) |st| st.size else 0;
        }
        fn makeZigCacheDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, builder_spec.options.zig_cache_dir, file.dir_mode));
        }
        fn makeZigOutDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, builder_spec.options.zig_out_dir, file.dir_mode));
        }
        fn makeBinDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, builder_spec.options.zig_exe_out_dir, file.dir_mode));
        }
        fn makeAuxDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, builder_spec.options.zig_aux_out_dir, file.dir_mode));
        }
        fn dependencyWait(target: *Target, task: types.Task, arena_index: AddressSpace.Index) bool {
            for (target.buildDependencies()) |*dep| {
                if (dep.target.lock.get(dep.task) != dep.state) {
                    if (dep.target.lock.get(dep.task) == .failed) {
                        target.assertExchange(task, .blocking, .failed);
                        if (max_thread_count != 0) {
                            if (arena_index != max_thread_count) {
                                builtin.proc.exitWithError(error.DependencyFailed, 2);
                            }
                        }
                        return false;
                    } else {
                        return true;
                    }
                }
            }
            return false;
        }
        fn groupWait(group: *Group, task: types.Task) bool {
            for (group.targets()) |target| {
                if (target.lock.get(task) == .blocking) {
                    return true;
                }
            }
            return false;
        }
        fn builderWait(address_space: *Builder.AddressSpace, thread_space: *Builder.ThreadSpace, builder: *Builder) bool {
            for (builder.groups()) |group| {
                for (group.targets()) |target| {
                    for (types.task_list) |task| {
                        if (target.lock.get(task) == .blocking) {
                            return true;
                        }
                    }
                }
            } else {
                if (address_space.count() != 1) {
                    return true;
                }
                if (thread_space.count() != 0) {
                    return true;
                }
            }
            return false;
        }
        const decls = struct {
            const path_spec: file.PathSpec = builder_spec.path();
            const close_spec: file.CloseSpec = builder_spec.close();
            const map_spec: mem.MapSpec = builder_spec.map();
            const stat_spec: file.StatusSpec = builder_spec.stat();
            const unmap_spec: mem.UnmapSpec = builder_spec.unmap();
            const clock_spec: time.ClockSpec = builder_spec.clock();
            const sleep_spec: time.SleepSpec = builder_spec.sleep();
            const clone_spec: proc.CloneSpec = builder_spec.clone();
            const write_spec: file.WriteSpec = builder_spec.write();
            const create_spec: file.CreateSpec = builder_spec.create();
            const mkdir_spec: file.MakeDirSpec = builder_spec.mkdir();
            const command_spec: proc.CommandSpec = builder_spec.command();
            const time_spec: time.TimeSpec = .{ .nsec = builder_spec.options.dep_sleep_nsec };
            const fstat_spec: file.StatusSpec = .{
                .logging = .{ .Error = false, .Fault = true },
                .errors = .{ .throw = sys.stat_errors },
            };
        };
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
            const env_fd: u64 = try meta.wrap(
                file.createAt(decls.create_spec, cache_root_fd, builder_spec.options.env_name, file.file_mode),
            );
            for ([_][]const u8{
                "pub const zig_exe: [:0]const u8 = \"",               zig_exe,
                "\";\npub const build_root: [:0]const u8 = \"",       build_root,
                "\";\npub const cache_dir: [:0]const u8 = \"",        cache_root,
                "\";\npub const global_cache_dir: [:0]const u8 = \"", global_cache_root,
                "\";\n",
            }) |s| {
                try meta.wrap(file.write(decls.write_spec, env_fd, s));
            }
            try meta.wrap(file.close(decls.close_spec, env_fd));
            try meta.wrap(file.close(decls.close_spec, cache_root_fd));
            try meta.wrap(
                file.makeDirAt(decls.mkdir_spec, build_root_fd, builder_spec.options.zig_out_dir, file.dir_mode),
            );
            try meta.wrap(
                file.makeDirAt(decls.mkdir_spec, build_root_fd, builder_spec.options.exe_out_dir, file.dir_mode),
            );
        }

        pub const debug = struct {
            const about_run_s: [:0]const u8 = builtin.debug.about("run");
            const about_build_s: [:0]const u8 = builtin.debug.about("build");
            const about_format_s: [:0]const u8 = builtin.debug.about("format");
            const about_state_0_s: [:0]const u8 = builtin.debug.about("state");
            const about_state_1_s: [:0]const u8 = builtin.debug.about("state-fault");
            pub fn exchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
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
            pub fn noExchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
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
            pub fn noExchangeFault(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
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
            fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                var len: u64 = mach.memcpyMulti(&buf, &.{ about, name, ", " });
                len +%= mach.memcpyMulti(buf[len..].ptr, &.{
                    "rc=", builtin.fmt.ud64(rc).readAll(),
                    ", ",  builtin.fmt.ud64(durat.sec).readAll(),
                    ".",   builtin.fmt.nsec(durat.nsec).readAll()[0..3],
                    "s\n",
                });
                builtin.debug.logAlways(buf[0..len]);
            }
            pub fn writeAndWalk(target: *Target) void {
                var buf0: [1024 * 1024]u8 = undefined;
                var buf1: [4096]u8 = undefined;
                @memcpy(&buf0, target.name.ptr, target.name.len);
                var len: u64 = target.name.len;
                len = writeAndWalkInternal(&buf0, len, &buf1, 0, target);
                builtin.debug.logAlways(buf0[0..len]);
            }
            fn writeAndWalkInternal(buf0: *[1024 * 1024]u8, len0: u64, buf1: *[4096]u8, len1: u64, target: *Builder.Target) u64 {
                @setRuntimeSafety(false);
                const deps: []Target.Dependency = target.buildDependencies();
                var len: u64 = len0;
                buf0[len] = '\n';
                len = len +% 1;
                for (deps, 0..) |dep, idx| {
                    @memcpy(buf1[len1..].ptr, if (idx == deps.len -% 1) "  " else "| ", 2);
                    @memcpy(buf0[len..].ptr, buf1, len1 +% 2);
                    len = len +% len1 +% 2;
                    @memcpy(buf0[len..].ptr, if (idx == deps.len -% 1) "\x08\x08`-" else "\x08\x08|-", 4);
                    len = len +% 4;
                    @memcpy(buf0[len..].ptr, if (dep.target.deps_len == 0) "> " else "+ ", 2);
                    len = len +% 2;
                    @memcpy(buf0[len..].ptr, dep.target.name.ptr, dep.target.name.len);
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
                name_max_width +%= alignment;
                root_max_width +%= alignment;
                name_max_width &= ~(alignment -% 1);
                root_max_width &= ~(alignment -% 1);
                @memset(&buf1, ' ', 4);
                for (builder.groups()) |group| {
                    len +%= builtin.debug.writeMulti(buf0[len..], &.{ group.name, ":\n" });
                    for (group.targets()) |target| {
                        @memset(buf0[len..].ptr, ' ', 4);
                        len +%= 4;
                        @memcpy(buf0[len..].ptr, target.name.ptr, target.name.len);
                        len +%= target.name.len;
                        var count: u64 = name_max_width -% target.name.len;
                        if (show_root) {
                            @memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            @memcpy(buf0[len..].ptr, target.root.ptr, target.root.len);
                            len +%= target.root.len;
                        }
                        if (show_descr) {
                            count = root_max_width -% target.root.len;
                            @memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            if (target.descr) |descr| {
                                @memcpy(buf0[len..].ptr, descr.ptr, descr.len);
                                len +%= descr.len;
                            }
                        }
                        if (show_deps) {
                            @memcpy(buf0[len..].ptr, "\x1b[2m", 4);
                            len +%= 4;
                            len = writeAndWalkInternal(&buf0, len, &buf1, 8, target);
                            @memcpy(buf0[len..].ptr, "\x1b[0m", 4);
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
        fn strdup(allocator: *Allocator, values: []const u8) [:0]u8 {
            const addr: u64 = builtin.addr(values);
            if (addr < stack_lb_addr or
                addr >= allocator.lb_addr and addr < allocator.ub_addr)
            {
                return @constCast(values.ptr[0..values.len :0]);
            } else {
                var buf: [:0]u8 = @ptrCast([:0]u8, allocate(allocator, u8, values.len));
                @memcpy(buf.ptr, values.ptr, values.len);
                return buf;
            }
        }
        fn strdup2(allocator: *Allocator, values: []const []const u8) [][:0]const u8 {
            var buf: [][:0]u8 = @ptrCast([][:0]u8, allocate(allocator, [:0]u8, values.len));
            var idx: u64 = 0;
            for (values) |value| {
                buf[idx] = strdup(allocator, value);
                idx +%= 1;
            }
        }
        fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
            var len: u64 = 0;
            for (values) |value| len +%= value.len;
            const buf: [:0]u8 = @ptrCast([:0]u8, allocate(allocator, u8, len));
            var idx: u64 = 0;
            for (values) |value| {
                @memcpy(buf[idx..].ptr, value.ptr, value.len);
                idx +%= value.len;
            }
            return buf;
        }
        fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
            var count: u64 = 0;
            for (args) |value| count +%= @boolToInt(value == 0);
            const ptrs: [][*:0]u8 = allocate(allocator, [*:0]u8, count +% 1);
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
        fn buildExtra(build_cmd: *types.BuildCommand, extra: anytype) void {
            inline for (@typeInfo(@TypeOf(extra)).Struct.fields) |field| {
                @field(build_cmd, field.name) = @field(extra, field.name);
            }
        }
        fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: u64) []T {
            @setRuntimeSafety(false);
            const ret: []T = allocate(allocator, T, count);
            @memcpy(@ptrCast([*]u8, ret.ptr), @ptrCast([*]const u8, buf.ptr), buf.len *% @sizeOf(T));
            return ret;
        }
        fn allocateInternal(allocator: *Allocator, count: u64, size_of: u64, align_of: u64) u64 {
            @setRuntimeSafety(false);
            const s_ab_addr: u64 = allocator.alignAbove(align_of);
            const s_up_addr: u64 = s_ab_addr +% count *% size_of;
            @memset(@intToPtr([*]u8, s_up_addr), 0, size_of);
            allocator.allocate(s_up_addr +% size_of);
            return s_ab_addr;
        }
        fn allocate(allocator: *Allocator, comptime T: type, count: u64) []T {
            @setRuntimeSafety(false);
            const s_ab_addr: u64 = allocateInternal(allocator, count, @sizeOf(T), @alignOf(T));
            return mem.pointerSlice(T, s_ab_addr, count);
        }
        fn create(allocator: *Allocator, comptime T: type) *T {
            @setRuntimeSafety(false);
            const s_ab_addr: u64 = allocator.alignAbove(@alignOf(T));
            allocator.allocate(s_ab_addr +% @sizeOf(T));
            return mem.pointerOne(T, s_ab_addr);
        }
    };
    return Type;
}
fn copy(comptime T: type, dest: *T, src: *const T) void {
    @memcpy(@ptrCast([*]u8, dest), @ptrCast([*]const u8, src), @sizeOf(T));
}
