const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");
const types = @import("./build/types.zig");
const command_line = @import("./build/command_line3.zig");
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
        sleep_nanoseconds: u64 = 50000,
        build_timeout_milliseconds: u64 = 1000 * 60 * 60 * 24,
        max_thread_count: u64 = 16,
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        stack_lb_addr: u64 = 0x700000000000,
        show_state: bool = false,
        env_name: [:0]const u8 = "env.zig",
        build_name: [:0]const u8 = "build.zig",
        zig_out_dir: [:0]const u8 = "zig-out/",
        zig_cache_dir: [:0]const u8 = "zig-cache/",
        exe_out_name: [:0]const u8 = "bin",
        aux_out_name: [:0]const u8 = "aux",
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
    pub const Logging = packed struct(u34) {
        close: builtin.Logging.Field(file.CloseSpec),
        create: builtin.Logging.Field(file.CreateSpec),
        dup3: builtin.Logging.Field(file.DuplicateSpec),
        execve: builtin.Logging.Field(file.ExecuteSpec),
        fork: builtin.Logging.Field(proc.ForkSpec),
        map: builtin.Logging.Field(mem.MapSpec),
        mkdir: builtin.Logging.Field(file.MakeDirSpec),
        mknod: builtin.Logging.Field(file.MakeNodeSpec),
        path: builtin.Logging.Field(file.PathSpec),
        pipe: builtin.Logging.Field(file.MakePipeSpec),
        waitpid: builtin.Logging.Field(proc.WaitSpec),
        read: builtin.Logging.Field(file.ReadSpec),
        unmap: builtin.Logging.Field(mem.UnmapSpec),
        write: builtin.Logging.Field(file.WriteSpec),
        stat: builtin.Logging.Field(file.StatusSpec),
        poll: builtin.Logging.Field(file.PollSpec),
    };
    pub const Errors = struct {
        close: sys.ErrorPolicy,
        create: sys.ErrorPolicy,
        dup3: sys.ErrorPolicy,
        execve: sys.ErrorPolicy,
        fork: sys.ErrorPolicy,
        map: sys.ErrorPolicy,
        mkdir: sys.ErrorPolicy,
        mknod: sys.ErrorPolicy,
        path: sys.ErrorPolicy,
        pipe: sys.ErrorPolicy,
        waitpid: sys.ErrorPolicy,
        read: sys.ErrorPolicy,
        unmap: sys.ErrorPolicy,
        write: sys.ErrorPolicy,
        stat: sys.ErrorPolicy,
        poll: sys.ErrorPolicy,
        sleep: sys.ErrorPolicy,
        clock: sys.ErrorPolicy,
    };
    const thread_map_options: mem.MapSpec.Options = .{
        .grows_down = true,
    };
    const pipe_options: file.MakePipeSpec.Options = .{
        .close_on_exec = false,
    };
    const create_options: file.CreateSpec.Options = .{
        .exclusive = false,
        .write = .truncate,
    };
    fn clock(comptime builder_spec: BuilderSpec) time.ClockSpec {
        return .{ .errors = builder_spec.errors.clock };
    }
    fn sleep(comptime builder_spec: BuilderSpec) time.SleepSpec {
        return .{ .errors = builder_spec.errors.sleep };
    }
    fn path(comptime builder_spec: BuilderSpec) file.PathSpec {
        return .{
            .errors = builder_spec.errors.path,
            .logging = builder_spec.logging.path,
        };
    }
    fn mkdir(comptime builder_spec: BuilderSpec) file.MakeDirSpec {
        return .{
            .errors = builder_spec.errors.mkdir,
            .logging = builder_spec.logging.mkdir,
        };
    }
    fn write(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{
            .errors = builder_spec.errors.write,
            .logging = builder_spec.logging.write,
        };
    }
    fn write2(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{
            .errors = builder_spec.errors.write,
            .logging = builder_spec.logging.write,
            .child = types.Message.ClientHeader,
        };
    }
    fn read(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{
            .errors = builder_spec.errors.read,
            .logging = builder_spec.logging.read,
            .return_type = u64,
        };
    }
    fn read2(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{
            .errors = builder_spec.errors.read,
            .logging = builder_spec.logging.read,
            .return_type = u64,
        };
    }
    fn read3(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{
            .child = types.Message.ServerHeader,
            .errors = builder_spec.errors.read,
            .logging = builder_spec.logging.read,
            .return_type = void,
        };
    }
    fn close(comptime builder_spec: BuilderSpec) file.CloseSpec {
        return .{
            .errors = builder_spec.errors.close,
            .logging = builder_spec.logging.close,
        };
    }
    fn unmap(comptime builder_spec: BuilderSpec) mem.UnmapSpec {
        return .{
            .errors = builder_spec.errors.unmap,
            .logging = builder_spec.logging.unmap,
        };
    }
    fn stat(comptime builder_spec: BuilderSpec) file.StatusSpec {
        return .{
            .errors = builder_spec.errors.stat,
            .logging = builder_spec.logging.stat,
        };
    }
    fn fork(comptime builder_spec: BuilderSpec) proc.ForkSpec {
        return .{
            .errors = builder_spec.errors.fork,
            .logging = builder_spec.logging.fork,
        };
    }
    fn waitpid(comptime builder_spec: BuilderSpec) proc.WaitSpec {
        return .{
            .errors = builder_spec.errors.waitpid,
            .logging = builder_spec.logging.waitpid,
            .return_type = proc.Return,
        };
    }
    fn mknod(comptime builder_spec: BuilderSpec) file.MakeNodeSpec {
        return .{
            .errors = builder_spec.errors.mknod,
            .logging = builder_spec.logging.mknod,
        };
    }
    fn dup3(comptime builder_spec: BuilderSpec) file.DuplicateSpec {
        return .{
            .errors = builder_spec.errors.dup3,
            .logging = builder_spec.logging.dup3,
            .return_type = void,
        };
    }
    fn poll(comptime builder_spec: BuilderSpec) file.PollSpec {
        return .{
            .errors = builder_spec.errors.poll,
            .logging = builder_spec.logging.poll,
            .return_type = bool,
        };
    }
    fn pipe(comptime builder_spec: BuilderSpec) file.MakePipeSpec {
        return .{
            .errors = builder_spec.errors.pipe,
            .logging = builder_spec.logging.pipe,
            .options = pipe_options,
        };
    }
    fn map(comptime builder_spec: BuilderSpec) mem.MapSpec {
        return .{
            .errors = builder_spec.errors.map,
            .logging = builder_spec.logging.map,
            .options = thread_map_options,
        };
    }
    fn create(comptime builder_spec: BuilderSpec) file.CreateSpec {
        return .{
            .errors = builder_spec.errors.create,
            .logging = builder_spec.logging.create,
            .options = create_options,
        };
    }
    fn execve(comptime builder_spec: BuilderSpec) file.ExecuteSpec {
        return .{
            .errors = builder_spec.errors.execve,
            .logging = builder_spec.logging.execve,
            .args_type = [][*:0]u8,
            .vars_type = [][*:0]u8,
        };
    }
    fn fstat() file.StatusSpec {
        return .{
            .logging = .{ .Error = false, .Fault = true },
            .errors = .{ .throw = sys.stat_errors },
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
            .options = addrspace_options,
        });
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "stack",
            .idx_type = AddressSpace.Index,
            .divisions = max_thread_count,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .errors = spec.address_space.errors.noexcept,
            .logging = spec.address_space.logging.silent,
            .options = threadspace_options,
        });
        pub const Allocator = mem.GenericRtArenaAllocator(.{
            .AddressSpace = AddressSpace,
            .logging = spec.allocator.logging.silent,
            .errors = spec.allocator.errors.noexcept,
            .options = spec.allocator.options.small_composed,
        });
        pub const Args = Allocator.StructuredVectorLowAlignedWithSentinel(u8, 0, 8);
        pub const CompilerFn = fn (*Builder, *Target, *Allocator, types.Path) [:0]u8;
        pub const max_thread_count: u64 = builder_spec.options.max_thread_count;
        pub const max_arena_count: u64 = if (max_thread_count == 0) 4 else max_thread_count + 1;
        pub const stack_aligned_bytes: u64 = builder_spec.options.stack_aligned_bytes;
        pub const arena_aligned_bytes: u64 = builder_spec.options.arena_aligned_bytes;
        pub const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        pub const arena_lb_addr: u64 = stack_up_addr;
        pub const stack_up_addr: u64 = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        pub const arena_up_addr: u64 = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
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
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.abort ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                if (max_thread_count == 0) {
                    try meta.wrap(impl.executeCommand(builder, allocator, target, task, depth));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (thread_space.atomicSet(arena_index)) {
                            return @call(.never_inline, impl.forwardToExecuteCloneThreaded, .{
                                builder, address_space, thread_space, target, task, arena_index, depth, ThreadSpace.high(arena_index) -% 4096,
                            });
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
                .throw = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
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
                    while (targetWait(target, task, arena_index)) {
                        try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                    }
                    try meta.wrap(target.acquireThread(address_space, thread_space, allocator, builder, task, depth));
                }
                if (depth == 0) {
                    while (target.lock.get(task) == .blocking) {
                        try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
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
                .throw = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, task, max_thread_count, 0));
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
            fn binaryRelative(target: *Target, allocator: *Allocator) [:0]const u8 {
                switch (target.build_cmd.kind) {
                    .exe => return concatenate(allocator, &[_][]const u8{
                        zig_out_exe_dir ++ "/",
                        target.name,
                    }),
                    .lib => return concatenate(allocator, &[_][]const u8{
                        zig_out_exe_dir ++ "/",
                        target.name,
                        builder_spec.options.lib_ext,
                    }),
                    .obj => return concatenate(allocator, &[_][]const u8{
                        zig_out_exe_dir ++ "/",
                        target.name,
                        builder_spec.options.obj_ext,
                    }),
                }
            }
            fn auxiliaryRelative(target: *Target, allocator: *Allocator, kind: types.AuxOutputMode) [:0]u8 {
                switch (kind) {
                    .@"asm" => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.asm_ext,
                    }),
                    .llvm_ir => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.llvm_ir_ext,
                    }),
                    .llvm_bc => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.llvm_bc_ext,
                    }),
                    .h => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.h_ext,
                    }),
                    .docs => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.docs_ext,
                    }),
                    .analysis => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
                        target.name,
                        builder_spec.options.analysis_ext,
                    }),
                    .implib => return concatenate(allocator, &[_][]const u8{
                        zig_out_aux_dir ++ "/",
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
            inline fn createBinaryPath(target: *Target, allocator: *Allocator, builder: *const Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = binaryRelative(target, allocator) };
            }
            fn createAuxiliaryPath(target: *Target, allocator: *Allocator, builder: *const Builder, kind: types.AuxOutputMode) types.Path {
                return .{ .absolute = builder.build_root, .relative = auxiliaryRelative(target, allocator, kind) };
            }
            pub fn emitBinary(target: *Target, allocator: *Allocator, builder: *const Builder) void {
                target.build_cmd.emit_bin = .{ .yes = createBinaryPath(target, allocator, builder) };
            }
            pub fn emitAuxiliary(target: *Target, allocator: *Allocator, builder: *const Builder, kind: types.AuxOutputMode) void {
                target.build_cmd.emit_bin = .{ .yes = createAuxiliaryPath(target, allocator, builder, kind) };
            }
            fn rootSourcePath(target: *Target, builder: *const Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = target.root };
            }
            fn dependOnBuild(target: *Target, allocator: *Allocator, dependency: *Target) void {
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
                    builtin.proc.exitGroup(2);
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
            fn addDependency(target: *Target, allocator: *Allocator, dependency: *Target, task: types.Task, state: types.State) void {
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
            fn buildDependencies(target: *const Target) []Dependency {
                @setRuntimeSafety(false);
                return target.deps[0..target.deps_len];
            }
            fn runArguments(target: *const Target) [][*:0]u8 {
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
                    try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
            pub fn addTarget(
                group: *Group,
                allocator: *Allocator,
                extra: anytype,
                name: [:0]const u8,
                root: [:0]const u8,
            ) !*Target {
                @setRuntimeSafety(false);
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = reallocate(allocator, *Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = create(allocator, Target);
                group.trgs[group.trgs_len] = ret;
                group.trgs_len +%= 1;
                const builder: *const Builder = group.builder;
                ret.build_cmd = create(allocator, types.BuildCommand);
                buildExtra(ret.build_cmd, extra);
                ret.name = name;
                ret.root = root;
                ret.assertExchange(.build, .unavailable, .ready);
                ret.emitBinary(allocator, builder);
                if (ret.build_cmd.kind == .exe) {
                    const bin_path: types.Path = ret.binaryPath();
                    ret.addRunArgument(
                        allocator,
                        concatenate(allocator, &[_][]const u8{ bin_path.absolute, "/", bin_path.relative.? }),
                    );
                }
                if (ret.build_cmd.name == null) {
                    ret.build_cmd.name = ret.name;
                }
                if (ret.build_cmd.main_pkg_path == null) {
                    ret.build_cmd.main_pkg_path = builder.build_root;
                }
                if (ret.build_cmd.cache_root == null) {
                    ret.build_cmd.cache_root = builder.cache_root;
                }
                if (ret.build_cmd.global_cache_root == null) {
                    ret.build_cmd.global_cache_root = builder.global_cache_root;
                }
                return ret;
            }
            pub fn targets(group: *const Group) []*Target {
                @setRuntimeSafety(false);
                return group.trgs[0..group.trgs_len];
            }
        };
        pub fn groups(builder: *const Builder) []*Group {
            @setRuntimeSafety(false);
            return builder.grps[0..builder.grps_len];
        }
        fn clientLoop(allocator: *Allocator, out: file.Pipe) u8 {
            var fds: [1]file.PollFd = .{
                .{ .fd = out.read, .expect = .{ .input = true } },
            };
            while (try meta.wrap(
                file.poll(builder_spec.poll(), &fds, builder_spec.options.build_timeout_milliseconds),
            )) : (fds[0].actual = .{}) {
                const save: Allocator.Save = allocator.save();
                defer allocator.restore(save);
                const hdr: *types.Message.ServerHeader = create(allocator, types.Message.ServerHeader);
                try meta.wrap(
                    file.readOne(builder_spec.read3(), out.read, hdr),
                );
                const msg: []u8 = allocate(allocator, u8, hdr.bytes_len);
                mach.memset(msg.ptr, 0, msg.len);
                var len: u64 = 0;
                while (len != hdr.bytes_len) {
                    len +%= try meta.wrap(
                        file.readMany(builder_spec.read2(), out.read, msg.ptr + len, hdr.bytes_len),
                    );
                }
                if (hdr.tag == .error_bundle) {
                    return debug.writeErrors(allocator, types.Message.ErrorHeader.create(msg));
                }
            }
            return builder_spec.options.expected_status;
        }
        fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            const start: time.TimeSpec = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) try meta.wrap(
                file.execPath(builder_spec.execve(), meta.manyToSlice(args[0]), args, builder.vars),
            );
            const ret: proc.Return = try meta.wrap(
                proc.waitPid(builder_spec.waitpid(), .{ .pid = pid }),
            );
            ts.* = time.diff(try meta.wrap(time.get(builder_spec.clock(), .realtime)), start);
            return proc.Status.exit(ret.status);
        }
        fn compile(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            const start: time.TimeSpec = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) {
                try meta.wrap(
                    file.execPath(builder_spec.execve(), builder.zig_exe, args, builder.vars),
                );
            }
            const wait: proc.Return = try meta.wrap(
                proc.waitPid(builder_spec.waitpid(), .{ .pid = pid }),
            );
            ts.* = time.diff(try meta.wrap(time.get(builder_spec.clock(), .realtime)), start);
            return proc.Status.exit(wait.status);
        }
        fn compileServer(builder: *const Builder, allocator: *Builder.Allocator, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            const in: file.Pipe = try meta.wrap(file.makePipe(builder_spec.pipe()));
            const out: file.Pipe = try meta.wrap(file.makePipe(builder_spec.pipe()));
            const start: time.TimeSpec = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) {
                try meta.wrap(openChild(in, out));
                try meta.wrap(
                    file.execPath(builder_spec.execve(), builder.zig_exe, args, builder.vars),
                );
            }
            try meta.wrap(openParent(in, out));
            try meta.wrap(
                file.write(builder_spec.write2(), in.write, &update_exit_message, 2),
            );
            const ret: u8 = try meta.wrap(clientLoop(allocator, out));
            try meta.wrap(closeParent(in, out));
            ts.* = time.diff(try meta.wrap(time.get(builder_spec.clock(), .realtime)), start);
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
                if (switch (task) {
                    .build => meta.wrap(
                        executeCompilerCommand(builder, &allocator, target, depth, buildWrite),
                    ) catch false,
                    .run => meta.wrap(
                        executeRunCommand(builder, &allocator, target, depth),
                    ) catch false,
                }) {
                    target.assertExchange(task, .blocking, .finished);
                } else {
                    target.assertExchange(task, .blocking, .failed);
                }
                allocator.deinit(address_space, arena_index);
                builtin.assert(thread_space.atomicUnset(arena_index));
            }
            fn executeCommand(
                builder: *Builder,
                allocator: *Allocator,
                target: *Target,
                task: types.Task,
                depth: u64,
            ) sys.Call(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                if (switch (task) {
                    .build => try meta.wrap(
                        executeCompilerCommand(builder, allocator, target, depth, buildWrite),
                    ),
                    .run => try meta.wrap(
                        executeRunCommand(builder, allocator, target, depth),
                    ),
                }) {
                    target.assertExchange(task, .blocking, .finished);
                } else {
                    target.assertExchange(task, .blocking, .failed);
                }
            }
        };
        fn buildWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            const max_len: u64 = builder_spec.options.max_command_line orelse command_line.buildLength(builder, target, root_path);
            if (@hasDecl(command_line, "buildWrite")) {
                var array: Args = Args.init(allocator, max_len);
                command_line.buildWrite(target.build_cmd, builder.zig_exe, root_path, &array);
                return array.referAllDefinedWithSentinel(0);
            } else {
                const buf: []u8 = allocate(allocator, u8, max_len);
                return buf[0..command_line.buildWriteBuf(target.build_cmd, builder.zig_exe, root_path, buf.ptr) :0];
            }
        }
        fn formatWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            const max_len: u64 = builder_spec.options.max_command_line orelse command_line.formatLength(builder, target, root_path);
            if (@hasDecl(command_line, "formatWrite")) {
                var array: Args = Args.init(allocator, max_len);
                command_line.formatWrite(target.format_cmd, builder.zig_exe, root_path, &array);
                return array.referAllDefinedWithSentinel(0);
            } else {
                const buf: []u8 = allocate(allocator, u8, max_len);
                return buf[0..command_line.formatWriteBuf(target.format_cmd, builder.zig_exe, root_path, buf.ptr) :0];
            }
        }
        fn executeCompilerCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64, cmd: *const CompilerFn) sys.Call(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, bool) {
            var build_time: time.TimeSpec = undefined;
            const bin_path: [:0]const u8 = try meta.wrap(
                target.binaryRelative(allocator),
            );
            const root_path: types.Path = target.rootSourcePath(builder);
            if (max_thread_count != 0) {
                target.build_cmd.listen = .@"-";
            }
            const args: [:0]u8 = try meta.wrap(
                cmd(builder, target, allocator, root_path),
            );
            const ptrs: [][*:0]u8 = try meta.wrap(
                makeArgPtrs(allocator, args),
            );
            const old_size: u64 = builder.getFileSize(bin_path);
            const rc: u8 = try meta.wrap(
                if (max_thread_count == 0)
                    builder.compile(ptrs, &build_time)
                else
                    builder.compileServer(allocator, ptrs, &build_time),
            );
            const new_size: u64 = builder.getFileSize(bin_path);
            if (depth < builder_spec.options.max_relevant_depth) {
                debug.buildNotice(target, build_time, old_size, new_size);
            }
            if (target.build_cmd.kind == .exe) {
                target.assertExchange(.run, .unavailable, .ready);
            }
            return rc == builder_spec.options.expected_status;
        }
        fn executeRunCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64) sys.Call(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, bool) {
            target.addRunArguments(allocator, builder);
            const args: [][*:0]u8 = target.runArguments();
            var run_time: time.TimeSpec = undefined;
            const rc: u8 = try meta.wrap(
                builder.system(args, &run_time),
            );
            if (rc != 0 or depth <= builder_spec.options.max_relevant_depth) {
                debug.simpleTimedNotice(debug.about_run_s, target.name, run_time, rc);
            }
            return rc == builder_spec.options.expected_status;
        }

        pub fn init(args: [][*:0]u8, vars: [][*:0]u8) sys.Call(.{
            .throw = builder_spec.errors.mkdir.throw ++
                builder_spec.errors.path.throw ++ builder_spec.errors.close.throw ++ builder_spec.errors.create.throw,
            .abort = builder_spec.errors.mkdir.abort ++
                builder_spec.errors.path.abort ++ builder_spec.errors.close.abort ++ builder_spec.errors.create.abort,
        }, Builder) {
            const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
            const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
            const cache_root: [:0]const u8 = meta.manyToSlice(args[3]);
            const global_cache_root: [:0]const u8 = meta.manyToSlice(args[4]);
            if (max_thread_count != 0) {
                try meta.wrap(mem.map(builder_spec.map(), stack_lb_addr, stack_up_addr -% stack_lb_addr));
            }
            const build_root_fd: u64 = try meta.wrap(file.path(builder_spec.path(), build_root));
            const cache_root_fd: u64 = try meta.wrap(file.path(builder_spec.path(), cache_root));
            const env_fd: u64 = try meta.wrap(file.createAt(builder_spec.create(), cache_root_fd, builder_spec.options.env_name, file.file_mode));
            for ([_][]const u8{
                "pub const zig_exe: [:0]const u8 = \"",                zig_exe,
                "\";\npub const build_root: [:0]const u8 = \"",        build_root,
                "\";\npub const cache_root: [:0]const u8 = \"",        cache_root,
                "\";\npub const global_cache_root: [:0]const u8 = \"", global_cache_root,
                "\";\n",
            }) |s| try meta.wrap(file.write(builder_spec.write(), env_fd, s.ptr, s.len));
            try meta.wrap(file.close(builder_spec.close(), env_fd));
            try meta.wrap(file.close(builder_spec.close(), cache_root_fd));
            try meta.wrap(file.makeDirAt(builder_spec.mkdir(), build_root_fd, builder_spec.options.zig_out_dir, file.dir_mode));
            try meta.wrap(file.makeDirAt(builder_spec.mkdir(), build_root_fd, zig_out_exe_dir, file.dir_mode));
            try meta.wrap(file.makeDirAt(builder_spec.mkdir(), build_root_fd, zig_out_aux_dir, file.dir_mode));
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
        fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.Status {
            return file.statusAt(BuilderSpec.fstat(), builder.dir_fd, name) catch null;
        }
        fn getFileSize(builder: *Builder, name: [:0]const u8) u64 {
            return if (getFileStatus(builder, name)) |st| st.size else 0;
        }
        pub fn processCommands(
            builder: *Builder,
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
        ) void {
            var target_task: types.Task = .build;
            var idx: u64 = 5;
            lo: while (idx < builder.args_len) : (idx +%= 1) {
                const command: []const u8 = meta.manyToSlice(builder.args[idx]);
                if (builder.args_len == builder.args.len) {
                    if (mach.testEqualMany8(command, "build")) {
                        target_task = .build;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "--")) {
                        builder.args_len = idx;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "run")) {
                        target_task = .run;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "list")) {
                        debug.builderCommandNotice(builder, true, true, true);
                        continue :lo;
                    }
                }
                for (builder.groups()) |group| {
                    if (mach.testEqualMany8(command, group.name)) {
                        builder.args_len = idx +% 1;
                        try meta.wrap(group.executeToplevel(address_space, thread_space, allocator, target_task));
                        continue :lo;
                    }
                    for (group.targets()) |target| {
                        if (mach.testEqualMany8(command, target.name)) {
                            builder.args_len = idx +% 1;
                            try meta.wrap(target.executeToplevel(address_space, thread_space, allocator, builder, target_task));
                            continue :lo;
                        }
                    }
                }
                builtin.proc.exitWithError(error.TargetDoesNotExist, 2);
            }
        }
        fn targetWait(target: *Target, task: types.Task, arena_index: AddressSpace.Index) bool {
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
                    for (types.Task.list) |task| {
                        if (target.lock.get(task) == .blocking) {
                            return true;
                        }
                    }
                }
            }
            if (address_space.count() != 1) {
                return true;
            }
            if (max_thread_count == 0) {
                return false;
            }
            if (thread_space.count() != 0) {
                return true;
            }
            return false;
        }
        const dup3_spec: file.DuplicateSpec = builder_spec.dup3();
        fn openChild(in: file.Pipe, out: file.Pipe) sys.Call(.{
            .throw = builder_spec.errors.close.throw ++ builder_spec.errors.dup3.throw,
            .abort = builder_spec.errors.close.abort ++ builder_spec.errors.dup3.abort,
        }, void) {
            try meta.wrap(
                file.close(builder_spec.close(), in.write),
            );
            try meta.wrap(
                file.close(builder_spec.close(), out.read),
            );
            try meta.wrap(
                file.duplicateTo(builder_spec.dup3(), in.read, 0),
            );
            try meta.wrap(
                file.duplicateTo(builder_spec.dup3(), out.write, 1),
            );
        }
        fn openParent(in: file.Pipe, out: file.Pipe) sys.Call(builder_spec.errors.close, void) {
            try meta.wrap(
                file.close(builder_spec.close(), in.read),
            );
            try meta.wrap(
                file.close(builder_spec.close(), out.write),
            );
        }
        fn closeParent(in: file.Pipe, out: file.Pipe) sys.Call(builder_spec.errors.close, void) {
            try meta.wrap(
                file.close(builder_spec.close(), in.write),
            );
            try meta.wrap(
                file.close(builder_spec.close(), out.read),
            );
        }
        const update_exit_message: [2]types.Message.ClientHeader = .{
            .{ .tag = .update, .bytes_len = 0 },
            .{ .tag = .exit, .bytes_len = 0 },
        };
        const addrspace_options: mem.ArenaOptions = .{
            .thread_safe = true,
            .require_map = true,
            .require_unmap = true,
        };
        const threadspace_options: mem.ArenaOptions = .{
            .thread_safe = true,
        };
        const zig_out_exe_dir: [:0]const u8 = builder_spec.options.zig_out_dir ++ builder_spec.options.exe_out_name;
        const zig_out_aux_dir: [:0]const u8 = builder_spec.options.zig_out_dir ++ builder_spec.options.aux_out_name;
        pub const debug = struct {
            const about_run_s: [:0]const u8 = builtin.debug.about("run");
            const about_build_s: [:0]const u8 = builtin.debug.about("build");
            const about_format_s: [:0]const u8 = builtin.debug.about("format");
            const about_state_0_s: [:0]const u8 = builtin.debug.about("state");
            const about_state_1_s: [:0]const u8 = builtin.debug.about("state-fault");
            const error_s: *const [5:0]u8 = "error";
            const note_s: *const [4:0]u8 = "note";
            const fancy_hl_line: bool = false;
            inline fn resetStyle() [12]u8 {
                comptime return "\x1b[0m".*;
            }
            inline fn tildeStyle() [10]u8 {
                comptime return "\x1b[38;5;46m".*;
            }
            inline fn boldStyle() [6]u8 {
                comptime return "\x1b[0;1m".*;
            }
            inline fn noteStyle() [15]u8 {
                comptime return "\x1b[0;38;5;250;1m".*;
            }
            inline fn traceStyle() [11]u8 {
                comptime return "\x1b[38;5;247m".*;
            }
            inline fn hiRedStyle() [12]u8 {
                comptime return "\x1b[38;5;196m".*;
            }
            fn exchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
                    about_state_0_s, target.name,
                    ".",             @tagName(task),
                    ", ",            @tagName(old_state),
                    " -> ",          @tagName(new_state),
                    "\n",
                });
            }
            fn noExchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
                    about_state_0_s, target.name,
                    ".",             @tagName(task),
                    ", (",           @tagName(target.lock.get(task)),
                    ") ",            @tagName(old_state),
                    " -!!-> ",       @tagName(new_state),
                    "\n",
                });
            }
            fn noExchangeFault(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
                    about_state_1_s, target.name,
                    ".",             @tagName(task),
                    ", (",           @tagName(target.lock.get(task)),
                    ") ",            @tagName(old_state),
                    " -!!-> ",       @tagName(new_state),
                    "\n",
                });
            }
            fn buildNotice(target: *Target, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
                @setRuntimeSafety(false);
                const diff_size: u64 = @max(new_size, old_size) -% @min(new_size, old_size);
                const new_size_s: []const u8 = builtin.fmt.ud64(new_size).readAll();
                const old_size_s: []const u8 = builtin.fmt.ud64(old_size).readAll();
                const diff_size_s: []const u8 = builtin.fmt.ud64(diff_size).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(durat.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(durat.nsec).readAll();
                var buf: [32768]u8 = undefined;
                @memcpy(&buf, about_build_s.ptr, about_build_s.len);
                var len: u64 = about_build_s.len;
                @memcpy(buf[len..].ptr, target.name.ptr, target.name.len);
                len = len +% target.name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len = len +% 2;
                const mode: builtin.Mode = target.build_cmd.mode orelse .Debug;
                @memcpy(buf[len..].ptr, @tagName(mode).ptr, @tagName(mode).len);
                len = len +% @tagName(mode).len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len = len +% 2;
                if (old_size == 0) {
                    @ptrCast(*[5]u8, buf[len..].ptr).* = "\x1b[93m".*;
                    len = len +% 5;
                    @memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len = len +% new_size_s.len;
                    @ptrCast(*[13]u8, buf[len..].ptr).* = "*\x1b[0m bytes, ".*;
                    len = len +% 13;
                } else if (new_size == old_size) {
                    @memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len = len +% new_size_s.len;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = " bytes, ".*;
                    len = len +% 8;
                } else {
                    @memcpy(buf[len..].ptr, old_size_s.ptr, old_size_s.len);
                    len = len +% old_size_s.len;
                    if (new_size > old_size) {
                        @ptrCast(*[7]u8, buf[len..].ptr).* = "(\x1b[91m+".*;
                    } else {
                        @ptrCast(*[7]u8, buf[len..].ptr).* = "(\x1b[93m-".*;
                    }
                    len = len +% 7;
                    @memcpy(buf[len..].ptr, diff_size_s.ptr, diff_size_s.len);
                    len = len +% diff_size_s.len;
                    @ptrCast(*[9]u8, buf[len..].ptr).* = "\x1b[0m) => ".*;
                    len = len +% 9;
                    @memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len = len +% new_size_s.len;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = " bytes, ".*;
                    len = len +% 8;
                }
                @memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len = len +% sec_s.len;
                buf[len] = '.';
                len = len +% 1;
                @memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len = len +% 3;
                @ptrCast(*[2]u8, buf[len..].ptr).* = "s\n".*;
                builtin.debug.logAlways(buf[0 .. len +% 2]);
            }
            fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
                @setRuntimeSafety(false);
                const rc_s: []const u8 = builtin.fmt.ud64(rc).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(durat.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(durat.nsec).readAll();
                var buf: [32768]u8 = undefined;
                @memcpy(&buf, about.ptr, about.len);
                var len: u64 = about.len;
                @memcpy(buf[len..].ptr, name.ptr, name.len);
                len = len +% name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len = len +% 2;
                @ptrCast(*[3]u8, buf[len..].ptr).* = "rc=".*;
                len = len +% 3;
                @memcpy(buf[len..].ptr, rc_s.ptr, rc_s.len);
                len = len +% rc_s.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len = len +% 2;
                @memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len = len +% sec_s.len;
                buf[len] = '.';
                len = len +% 1;
                @memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len = len +% 3;
                @ptrCast(*[2]u8, buf[len..].ptr).* = "s\n".*;
                builtin.debug.logAlways(buf[0 .. len +% 2]);
            }
            fn writeAndWalk(target: *Target) void {
                var buf0: [1048576]u8 = undefined;
                var buf1: [32768]u8 = undefined;
                @memcpy(&buf0, target.name.ptr, target.name.len);
                var len: u64 = target.name.len;
                len = writeAndWalkInternal(&buf0, len, &buf1, 0, target);
                builtin.debug.logAlways(buf0[0..len]);
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, target: *Target) u64 {
                @setRuntimeSafety(false);
                const deps: []Target.Dependency = target.buildDependencies();
                var len: u64 = len0;
                buf0[len] = '\n';
                len = len +% 1;
                for (deps, 0..) |dep, idx| {
                    @memcpy(buf1 + len1, if (idx == deps.len -% 1) "  " else "| ", 2);
                    @memcpy(buf0 + len, buf1, len1 +% 2);
                    len = len +% len1 +% 2;
                    @ptrCast(*[4]u8, buf0 + len).* = if (idx == deps.len -% 1) "\x08\x08`-".* else "\x08\x08|-".*;
                    len = len +% 4;
                    @ptrCast(*[2]u8, buf0 + len).* = if (dep.target.deps_len == 0) "> ".* else "+ ".*;
                    len = len +% 2;
                    @memcpy(buf0 + len, dep.target.name.ptr, dep.target.name.len);
                    len = len +% target.name.len;
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep.target);
                }
                return len;
            }
            pub fn builderCommandNotice(builder: *Builder, show_root: bool, show_descr: bool, show_deps: bool) void {
                @setRuntimeSafety(false);
                const alignment: u64 = 8;
                var buf0: [1024 * 1024]u8 = undefined;
                var buf1: [32768]u8 = undefined;
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
                    @memcpy(buf0[len..].ptr, group.name.ptr, group.name.len);
                    len = len +% group.name.len;
                    @ptrCast(*[2]u8, buf0[len..].ptr).* = ":\n".*;
                    len = len +% 2;
                    for (group.targets()) |target| {
                        @memset(buf0[len..].ptr, ' ', 4);
                        len = len +% 4;
                        @memcpy(buf0[len..].ptr, target.name.ptr, target.name.len);
                        len = len +% target.name.len;
                        var count: u64 = name_max_width -% target.name.len;
                        if (show_root) {
                            @memset(buf0[len..].ptr, ' ', count);
                            len = len +% count;
                            @memcpy(buf0[len..].ptr, target.root.ptr, target.root.len);
                            len = len +% target.root.len;
                        }
                        if (show_descr) {
                            count = root_max_width -% target.root.len;
                            @memset(buf0[len..].ptr, ' ', count);
                            len = len +% count;
                            if (target.descr) |descr| {
                                @memcpy(buf0[len..].ptr, descr.ptr, descr.len);
                                len = len +% descr.len;
                            }
                        }
                        if (show_deps) {
                            @ptrCast(*[4]u8, buf0[len..].ptr).* = "\x1b[2m".*;
                            len = len +% 4;
                            len = writeAndWalkInternal(&buf0, len, &buf1, 8, target);
                            @ptrCast(*[4]u8, buf0[len..].ptr).* = "\x1b[0m".*;
                            len = len +% 4;
                        } else {
                            buf0[len] = '\n';
                            len = len +% 1;
                        }
                    }
                }
                builtin.debug.write(buf0[0..len]);
            }
            fn writeAbout(buf: [*]u8, about: [:0]const u8) u64 {
                @setRuntimeSafety(false);
                var len: u64 = 0;
                if (about.ptr == error_s) {
                    @ptrCast(*@TypeOf(boldStyle()), buf + len).* = boldStyle();
                    len = len +% boldStyle().len;
                } else if (about.ptr == note_s) {
                    @ptrCast(*@TypeOf(noteStyle()), buf + len).* = noteStyle();
                    len = len +% noteStyle().len;
                }
                @memcpy(buf + len, about.ptr, about.len);
                len = len +% about.len;
                @ptrCast(*[2]u8, buf + len).* = ": ".*;
                len = len +% 2;
                @ptrCast(*@TypeOf(boldStyle()), buf + len).* = boldStyle();
                return len +% boldStyle().len;
            }
            inline fn arrcpy(buf: [*]u8, any: anytype) u64 {
                @ptrCast(*@TypeOf(any), buf).* = any;
                comptime return any.len;
            }
            fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(false);
                const err: *types.ErrorMessage = builtin.ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = builtin.ptrCast(*types.SourceLocation, extra + err.src_loc);
                var len: u64 = 4;
                @ptrCast(*[4]u8, buf + len).* = "\x1b[1m".*;
                if (err.src_loc != 0) {
                    len = len +% writeSourceLocation(
                        buf + len,
                        meta.manyToSlice(bytes + src.src_path),
                        src.line +% 1,
                        src.column +% 1,
                    );
                    @ptrCast(*[2]u8, buf + len).* = ": ".*;
                    len = len +% 2;
                }
                return len;
            }
            fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, about: [:0]const u8) u64 {
                @setRuntimeSafety(false);
                const err: *types.ErrorMessage = builtin.ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = builtin.ptrCast(*types.SourceLocation, extra + err.src_loc);
                const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
                var len: u64 = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
                const pos: u64 = len +% about.len -% traceStyle().len -% 2;
                len = len +% writeAbout(buf + len, about);
                len = len +% writeMessage(buf + len, bytes, err.start, pos);
                if (err.src_loc == 0) {
                    if (err.count != 1)
                        len = len +% writeTimes(buf + len, err.count);
                    for (0..err.notes_len) |idx|
                        len = len +% writeError(buf + len, extra, bytes, notes[idx], note_s);
                } else {
                    if (err.count != 1)
                        len = len +% writeTimes(buf + len, err.count);
                    if (src.src_line != 0)
                        len = len +% writeCaret(buf + len, bytes, src);
                    for (0..err.notes_len) |idx|
                        len = len +% writeError(buf + len, extra, bytes, notes[idx], note_s);
                    if (src.ref_len != 0)
                        len = len +% writeTrace(buf + len, extra, bytes, err.src_loc, src.ref_len);
                }
                return len;
            }
            fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: u64, column: u64) u64 {
                @setRuntimeSafety(false);
                const line_s: []const u8 = builtin.fmt.ud64(line).readAll();
                const column_s: []const u8 = builtin.fmt.ud64(column).readAll();
                var len: u64 = 0;
                @ptrCast(*@TypeOf(traceStyle()), buf + len).* = comptime traceStyle();
                len +%= comptime traceStyle().len;
                @memcpy(buf + len, pathname.ptr, pathname.len);
                len = len +% pathname.len;
                buf[len] = ':';
                len = len +% 1;
                @memcpy(buf + len, line_s.ptr, line_s.len);
                len = len +% line_s.len;
                buf[len] = ':';
                len = len +% 1;
                @memcpy(buf + len, column_s.ptr, column_s.len);
                return len +% column_s.len;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(false);
                const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
                @ptrCast(*[6]u8, buf).* = "\x1b[2m (".*;
                var len: u64 = 6;
                @memcpy(buf + len, count_s.ptr, count_s.len);
                len = len +% count_s.len;
                @ptrCast(*[12]u8, buf).* = " times)\x1b[0m\n".*;
                len = len +% 12;
                return len;
            }
            fn writeCaret(buf: [*]u8, bytes: [*:0]u8, src: *types.SourceLocation) u64 {
                @setRuntimeSafety(false);
                const line: [:0]u8 = meta.manyToSlice(bytes + src.src_line);
                const before_caret: u64 = src.span_main -% src.span_start;
                const indent: u64 = src.column -% before_caret;
                const after_caret: u64 = src.span_end -% src.span_main -| 1;
                var len: u64 = 0;
                if (fancy_hl_line) {
                    var pos: u64 = indent +% before_caret;
                    @memcpy(buf, line.ptr, indent);
                    len = len +% indent;
                    @ptrCast(*@TypeOf(boldStyle()), buf + len).* = comptime boldStyle();
                    len = len +% comptime boldStyle().len;
                    @memcpy(buf + len, line[indent..pos].ptr, before_caret);
                    len = len +% before_caret;
                    @ptrCast(*@TypeOf(hiRedStyle()), buf + len).* = comptime hiRedStyle();
                    len = len +% comptime hiRedStyle().len;
                    buf[len] = line[pos];
                    pos = pos +% 1;
                    len = len +% 1;
                    @ptrCast(*@TypeOf(boldStyle()), buf + len).* = comptime boldStyle();
                    len = len +% comptime boldStyle().len;
                    @memcpy(buf + len, line[pos .. pos + after_caret].ptr, after_caret);
                    len = len +% after_caret;
                    buf[len] = '\n';
                    len = len +% 1;
                } else {
                    @memcpy(buf, line.ptr, line.len);
                    len = line.len;
                    buf[len] = '\n';
                    len = len +% 1;
                }
                @memset(buf + len, ' ', indent);
                len = len +% indent;
                @ptrCast(*@TypeOf(tildeStyle()), buf + len).* = comptime tildeStyle();
                len = len +% comptime tildeStyle().len;
                @memset(buf + len, '~', before_caret);
                len = len +% before_caret;
                buf[len] = '^';
                len = len +% 1;
                @memset(buf + len, '~', after_caret);
                len = len +% after_caret;
                @ptrCast(*[5]u8, buf + len).* = "\x1b[0m\n".*;
                return len +% 5;
            }
            fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: u64, indent: u64) u64 {
                @setRuntimeSafety(false);
                var len: u64 = 0;
                var next: u64 = start;
                var idx: u64 = start;
                while (bytes[idx] != 0) : (idx +%= 1) {
                    if (bytes[idx] == '\n') {
                        const line: []u8 = bytes[next..idx];
                        @memcpy(buf + len, line.ptr, line.len);
                        len = len +% line.len;
                        buf[len] = '\n';
                        len = len +% 1;
                        @memset(buf + len, ' ', indent);
                        len = len +% indent;
                        next = idx +% 1;
                    }
                }
                const line: []u8 = bytes[next..idx];
                @memcpy(buf + len, line.ptr, line.len);
                len = len +% line.len;
                @ptrCast(*[5]u8, buf + len).* = "\x1b[0m\n".*;
                return len +% 5;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: u64, ref_len: u64) u64 {
                @setRuntimeSafety(false);
                var ref_idx: u64 = start +% types.SourceLocation.len;
                var idx: u64 = 0;
                var len: u64 = 0;
                @ptrCast(*@TypeOf(traceStyle()), buf + len).* = comptime traceStyle();
                len +%= comptime traceStyle().len;
                @ptrCast(*[15]u8, buf + len).* = "referenced by:\n".*;
                len = len +% 15;
                while (idx != ref_len) : (idx +%= 1) {
                    const ref_trc: *types.ReferenceTrace = builtin.ptrCast(*types.ReferenceTrace, extra + ref_idx);
                    if (ref_trc.src_loc != 0) {
                        const ref_src: *types.SourceLocation = builtin.ptrCast(*types.SourceLocation, extra + ref_trc.src_loc);
                        const src_file: [:0]u8 = meta.manyToSlice(bytes + ref_src.src_path);
                        const decl_name: [:0]u8 = meta.manyToSlice(bytes + ref_trc.decl_name);
                        @memset(buf + len, ' ', 4);
                        len = len +% 4;
                        @memcpy(buf + len, decl_name.ptr, decl_name.len);
                        len = len +% decl_name.len;
                        @ptrCast(*[2]u8, buf + len).* = ": ".*;
                        len = len +% 2;
                        len = len +% writeSourceLocation(buf + len, src_file, ref_src.line +% 1, ref_src.column +% 1);
                        buf[len] = '\n';
                        len = len +% 1;
                    }
                    ref_idx +%= types.ReferenceTrace.len;
                }
                @ptrCast(*[5]u8, buf + len).* = "\x1b[0m\n".*;
                return len +% 5;
            }
            fn writeErrors(allocator: *Allocator, hdr: *types.Message.ErrorHeader) u8 {
                @setRuntimeSafety(false);
                const extra: [*]u32 = hdr.extra();
                const bytes: [*:0]u8 = hdr.bytes();
                var buf: [*]u8 = allocate(allocator, u8, 1024 * 1024).ptr;
                const list: types.ErrorMessageList = builtin.ptrCast(*types.ErrorMessageList, extra).*;
                for ((extra + list.start)[0..list.len]) |err_msg_idx| {
                    var len: u64 = writeError(buf, extra, bytes, err_msg_idx, error_s);
                    builtin.debug.write(buf[0..len]);
                }
                builtin.debug.write(meta.manyToSlice(bytes + list.compile_log_text));
                return @intCast(u8, list.len);
            }
        };
        fn strdup(allocator: *Allocator, values: []const u8) [:0]u8 {
            @setRuntimeSafety(false);
            const addr: u64 = builtin.addr(values);
            if (addr < stack_lb_addr or addr >= allocator.lb_addr and addr < allocator.ub_addr) {
                return @constCast(values.ptr[0..values.len :0]);
            } else {
                var buf: [:0]u8 = @ptrCast([:0]u8, allocate(allocator, u8, values.len));
                @memcpy(buf.ptr, values.ptr, values.len);
                return buf;
            }
        }
        fn strdup2(allocator: *Allocator, values: []const []const u8) [][:0]const u8 {
            @setRuntimeSafety(false);
            var buf: [][:0]u8 = @ptrCast([][:0]u8, allocate(allocator, [:0]u8, values.len));
            var idx: u64 = 0;
            for (values) |value| {
                buf[idx] = strdup(allocator, value);
                idx +%= 1;
            }
        }
        fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
            @setRuntimeSafety(false);
            var len: u64 = 0;
            for (values) |value| len = len +% value.len;
            const buf: [:0]u8 = @ptrCast([:0]u8, allocate(allocator, u8, len));
            var idx: u64 = 0;
            for (values) |value| {
                @memcpy(buf[idx..].ptr, value.ptr, value.len);
                idx +%= value.len;
            }
            return buf;
        }
        fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
            @setRuntimeSafety(false);
            var count: u64 = 0;
            for (args) |value| count +%= @boolToInt(value == 0);
            const ptrs: [][*:0]u8 = allocate(allocator, [*:0]u8, count +% 1);
            var len: u64 = 0;
            var idx: u64 = 0;
            var pos: u64 = 0;
            while (idx != args.len) : (idx +%= 1) {
                if (args[idx] == 0) {
                    ptrs[len] = args[pos..idx :0];
                    len = len +% 1;
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
        fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: u64) []align(@max(@alignOf(T), 8)) T {
            @setRuntimeSafety(false);
            const ret: []align(@max(@alignOf(T), 8)) T = allocate(allocator, T, count);
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
        fn allocate(allocator: *Allocator, comptime T: type, count: u64) []align(@max(@alignOf(T), 8)) T {
            @setRuntimeSafety(false);
            const s_ab_addr: u64 = allocateInternal(allocator, count, @sizeOf(T), @max(@alignOf(T), 8));
            return mem.pointerSliceAligned(T, s_ab_addr, count, @max(@alignOf(T), 8));
        }
        fn create(allocator: *Allocator, comptime T: type) *align(@max(@alignOf(T), 8)) T {
            @setRuntimeSafety(false);
            const s_ab_addr: u64 = allocator.alignAbove(@alignOf(T));
            allocator.allocate(s_ab_addr +% @sizeOf(T));
            return mem.pointerOneAligned(T, s_ab_addr, @max(@alignOf(T), 8));
        }
    };
    return Type;
}
fn copy(comptime T: type, dest: *T, src: *const T) void {
    @memcpy(@ptrCast([*]u8, dest), @ptrCast([*]const u8, src), @sizeOf(T));
}
