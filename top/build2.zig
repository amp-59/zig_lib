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
        sleep_nanoseconds: u64 = 50000,
        build_timeout_milliseconds: u64 = 1000 * 84600,
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
            .return_type = void,
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
        pub const max_thread_count: u64 = builder_spec.options.max_thread_count;
        pub const max_arena_count: u64 = if (max_thread_count == 0) 4 else max_thread_count + 1;
        pub const stack_aligned_bytes: u64 = builder_spec.options.stack_aligned_bytes;
        pub const arena_aligned_bytes: u64 = builder_spec.options.arena_aligned_bytes;
        pub const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        pub const arena_lb_addr: u64 = stack_up_addr;
        pub const stack_up_addr: u64 = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        pub const arena_up_addr: u64 = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        const path_spec: file.PathSpec = builder_spec.path();
        const close_spec: file.CloseSpec = builder_spec.close();
        const map_spec: mem.MapSpec = builder_spec.map();
        const stat_spec: file.StatusSpec = builder_spec.stat();
        const unmap_spec: mem.UnmapSpec = builder_spec.unmap();
        const clock_spec: time.ClockSpec = builder_spec.clock();
        const sleep_spec: time.SleepSpec = builder_spec.sleep();
        const clone_spec: proc.CloneSpec = builder_spec.clone();
        const write_spec: file.WriteSpec = builder_spec.write();
        const write_spec2: file.WriteSpec = builder_spec.write2();
        const create_spec: file.CreateSpec = builder_spec.create();
        const mkdir_spec: file.MakeDirSpec = builder_spec.mkdir();
        const fork_spec: proc.ForkSpec = builder_spec.fork();
        const execve_spec: file.ExecuteSpec = builder_spec.execve();
        const waitpid_spec: proc.WaitSpec = builder_spec.waitpid();
        const mknod_spec: file.MakeNodeSpec = builder_spec.mknod();
        const dup3_spec: file.DuplicateSpec = builder_spec.dup3();
        const poll_spec: file.PollSpec = builder_spec.poll();
        const pipe_spec: file.MakePipeSpec = builder_spec.pipe();
        const read_spec: file.ReadSpec = builder_spec.read();
        const read_spec2: file.ReadSpec = builder_spec.read2();
        const read_spec3: file.ReadSpec = builder_spec.read3();
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
        const fstat_spec: file.StatusSpec = .{
            .logging = .{ .Error = false, .Fault = true },
            .errors = .{ .throw = sys.stat_errors },
        };
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
                .throw = clock_spec.errors.throw ++
                    fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
                .abort = clock_spec.errors.abort ++
                    fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
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
                .throw = clock_spec.errors.throw ++ sleep_spec.errors.throw ++
                    fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
                .abort = clock_spec.errors.abort ++ sleep_spec.errors.abort ++
                    fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
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
                        try meta.wrap(time.sleep(sleep_spec, .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                    }
                    try meta.wrap(target.acquireThread(address_space, thread_space, allocator, builder, task, depth));
                }
                if (depth == 0) {
                    while (target.lock.get(task) == .blocking) {
                        try meta.wrap(time.sleep(sleep_spec, .{ .nsec = builder_spec.options.sleep_nanoseconds }));
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
                .throw = clock_spec.errors.throw ++ sleep_spec.errors.throw ++
                    fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
                .abort = clock_spec.errors.abort ++ sleep_spec.errors.abort ++
                    fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
            }, void) {
                try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, task, max_thread_count, 0));
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(sleep_spec, .{ .nsec = builder_spec.options.sleep_nanoseconds }));
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
                    try meta.wrap(time.sleep(sleep_spec, .{ .nsec = builder_spec.options.sleep_nanoseconds }));
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
        pub fn groups(builder: *const Builder) []*Group {
            @setRuntimeSafety(false);
            return builder.grps[0..builder.grps_len];
        }
        fn openChild(in: file.Pipe, out: file.Pipe, err: file.Pipe) sys.Call(.{
            .throw = close_spec.errors.throw ++ dup3_spec.errors.throw,
            .abort = close_spec.errors.abort ++ dup3_spec.errors.abort,
        }, void) {
            try meta.wrap(
                file.close(close_spec, in.write),
            );
            try meta.wrap(
                file.close(close_spec, out.read),
            );
            try meta.wrap(
                file.close(close_spec, err.read),
            );
            try meta.wrap(
                file.duplicateTo(dup3_spec, in.read, 0),
            );
            try meta.wrap(
                file.duplicateTo(dup3_spec, out.write, 1),
            );
            try meta.wrap(
                file.duplicateTo(dup3_spec, err.write, 2),
            );
        }
        fn openParent(in: file.Pipe, out: file.Pipe, err: file.Pipe) sys.Call(close_spec.errors, void) {
            try meta.wrap(
                file.close(close_spec, in.read),
            );
            try meta.wrap(
                file.close(close_spec, out.write),
            );
            try meta.wrap(
                file.close(close_spec, err.write),
            );
        }
        fn closeParent(in: file.Pipe, out: file.Pipe, err: file.Pipe) sys.Call(close_spec.errors, void) {
            try meta.wrap(
                file.close(close_spec, in.write),
            );
            try meta.wrap(
                file.close(close_spec, out.read),
            );
            try meta.wrap(
                file.close(close_spec, err.read),
            );
        }
        fn clientLoop(allocator: *Allocator, out: file.Pipe) void {
            var fds: [1]file.PollFd = .{
                .{ .fd = out.read, .expect = .{ .input = true } },
            };
            while (!fds[0].actual.hangup) : (fds[0].actual.input = false) {
                const hdr: *types.Message.ServerHeader = create(allocator, types.Message.ServerHeader);
                try meta.wrap(
                    file.poll(poll_spec, &fds, builder_spec.options.build_timeout_milliseconds),
                );
                try meta.wrap(
                    file.readOne(read_spec3, out.read, hdr),
                );
                const msg: []u8 = allocate(allocator, u8, hdr.bytes_len);
                mach.memset(msg.ptr, 0, msg.len);
                var len: u64 = 0;
                while (len != hdr.bytes_len) {
                    len +%= try meta.wrap(
                        file.readMany(read_spec2, out.read, msg.ptr + len, hdr.bytes_len),
                    );
                }
                switch (hdr.tag) {
                    .zig_version => continue,
                    .progress => continue,
                    .emit_bin_path => break,
                    .test_metadata => break,
                    .test_results => break,
                    .error_bundle => break {
                        debug.writeErrors(allocator, types.Message.ErrorHeader.create(msg));
                    },
                }
            }
        }
        fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = clock_spec.errors.throw ++
                fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
            .abort = clock_spec.errors.abort ++
                fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
        }, u8) {
            const start: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
            const pid: u64 = try meta.wrap(proc.fork(fork_spec));
            if (pid == 0) try meta.wrap(
                file.execPath(execve_spec, meta.manyToSlice(args[0]), args, builder.vars),
            );
            var status: u32 = 0;
            try meta.wrap(
                proc.waitPid(waitpid_spec, .{ .pid = pid }, &status),
            );
            ts.* = time.diff(try meta.wrap(time.get(clock_spec, .realtime)), start);
            return proc.Status.exit(status);
        }
        fn compile(builder: *const Builder, allocator: *Builder.Allocator, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = clock_spec.errors.throw ++
                fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
            .abort = clock_spec.errors.abort ++
                fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
        }, u8) {
            const in: file.Pipe = try meta.wrap(file.makePipe(pipe_spec));
            const out: file.Pipe = try meta.wrap(file.makePipe(pipe_spec));
            const err: file.Pipe = try meta.wrap(file.makePipe(pipe_spec));
            const start: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
            const pid: u64 = try meta.wrap(proc.fork(fork_spec));
            if (pid == 0) {
                try meta.wrap(openChild(in, out, err));
                try meta.wrap(
                    file.execPath(execve_spec, builder.zig_exe, args, builder.vars),
                );
            }
            try meta.wrap(openParent(in, out, err));
            try meta.wrap(
                file.write(write_spec2, in.write, &update_exit_message, 2),
            );
            try meta.wrap(
                clientLoop(allocator, out),
            );
            var status: u32 = 0;
            try meta.wrap(
                proc.waitPid(waitpid_spec, .{ .pid = pid }, &status),
            );
            ts.* = time.diff(try meta.wrap(time.get(clock_spec, .realtime)), start);
            return proc.Status.exit(status);
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
                        executeBuildCommand(builder, &allocator, target, depth),
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
                .throw = clock_spec.errors.throw ++
                    fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
                .abort = clock_spec.errors.abort ++
                    fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
            }, void) {
                if (switch (task) {
                    .build => try meta.wrap(
                        executeBuildCommand(builder, allocator, target, depth),
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
            len = len +% 6 +% @tagName(target.build_cmd.kind).len +% 1;
            len = len +% command_line.buildLength(target.build_cmd);
            len = len +% root_path.formatLength();
            len = len +% 1;
            return len;
        }
        fn executeBuildCommand(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64) sys.Call(.{
            .throw = clock_spec.errors.throw ++
                fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
            .abort = clock_spec.errors.abort ++
                fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
        }, bool) {
            var build_time: time.TimeSpec = undefined;
            const bin_path: [:0]const u8 = try meta.wrap(
                target.binaryRelative(allocator),
            );
            const root_path: types.Path = target.rootSourcePath(builder);
            target.build_cmd.listen = .@"-";
            const args: [:0]u8 = try meta.wrap(
                builder.buildWrite(target, allocator, root_path),
            );
            const ptrs: [][*:0]u8 = try meta.wrap(
                makeArgPtrs(allocator, args),
            );
            const old_size: u64 = builder.getFileSize(bin_path);
            const rc: u8 = try meta.wrap(
                builder.compile(allocator, ptrs, &build_time),
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
            .throw = clock_spec.errors.throw ++
                fork_spec.errors.throw ++ execve_spec.errors.throw ++ waitpid_spec.errors.throw,
            .abort = clock_spec.errors.abort ++
                fork_spec.errors.abort ++ execve_spec.errors.abort ++ waitpid_spec.errors.abort,
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
                try meta.wrap(mem.map(map_spec, stack_lb_addr, stack_up_addr -% stack_lb_addr));
            }
            const build_root_fd: u64 = try meta.wrap(file.path(path_spec, build_root));
            const cache_root_fd: u64 = try meta.wrap(file.path(path_spec, cache_root));
            const env_fd: u64 = try meta.wrap(file.createAt(create_spec, cache_root_fd, builder_spec.options.env_name, file.file_mode));
            for ([_][]const u8{
                "pub const zig_exe: [:0]const u8 = \"",               zig_exe,
                "\";\npub const build_root: [:0]const u8 = \"",       build_root,
                "\";\npub const cache_dir: [:0]const u8 = \"",        cache_root,
                "\";\npub const global_cache_dir: [:0]const u8 = \"", global_cache_root,
                "\";\n",
            }) |s| try meta.wrap(file.write(write_spec, env_fd, s.ptr, s.len));
            try meta.wrap(file.close(close_spec, env_fd));
            try meta.wrap(file.close(close_spec, cache_root_fd));
            try meta.wrap(file.makeDirAt(mkdir_spec, build_root_fd, builder_spec.options.zig_out_dir, file.dir_mode));
            try meta.wrap(file.makeDirAt(mkdir_spec, build_root_fd, builder_spec.options.exe_out_dir, file.dir_mode));
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
            file.assertAt(fstat_spec, dir_fd, name, kind) catch |stat_error| {
                builtin.assert(stat_error == error.NoSuchFileOrDirectory);
            };
        }
        fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.Status {
            return file.statusAt(fstat_spec, builder.dir_fd, name) catch null;
        }
        fn getFileSize(builder: *Builder, name: [:0]const u8) u64 {
            return if (getFileStatus(builder, name)) |st| st.size else 0;
        }
        fn makeZigCacheDir(builder: *Builder) sys.Call(mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(mkdir_spec, builder.dir_fd, builder_spec.options.zig_cache_dir, file.dir_mode));
        }
        fn makeZigOutDir(builder: *Builder) sys.Call(mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(mkdir_spec, builder.dir_fd, builder_spec.options.zig_out_dir, file.dir_mode));
        }
        fn makeBinDir(builder: *Builder) sys.Call(mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(mkdir_spec, builder.dir_fd, builder_spec.options.zig_exe_out_dir, file.dir_mode));
        }
        fn makeAuxDir(builder: *Builder) sys.Call(mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(mkdir_spec, builder.dir_fd, builder_spec.options.zig_aux_out_dir, file.dir_mode));
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
        pub const debug = struct {
            const about_run_s: [:0]const u8 = builtin.debug.about("run");
            const about_build_s: [:0]const u8 = builtin.debug.about("build");
            const about_format_s: [:0]const u8 = builtin.debug.about("format");
            const about_state_0_s: [:0]const u8 = builtin.debug.about("state");
            const about_state_1_s: [:0]const u8 = builtin.debug.about("state-fault");
            const error_s: *const [5:0]u8 = "error";
            const note_s: *const [4:0]u8 = "note";
            inline fn tildeStyle() [:0]const u8 {
                return "\x1b[38;5;46m";
            }
            inline fn errorStyle() [:0]const u8 {
                return "\x1b[0;1m";
            }
            inline fn noteStyle() [:0]const u8 {
                return "\x1b[38;5;123m";
            }
            inline fn traceStyle() [:0]const u8 {
                return "\x1b[38;5;247m";
            }
            inline fn locationStyle() [:0]const u8 {
                return "\x1b[2m";
            }
            pub fn exchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
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
                var buf: [32768]u8 = undefined;
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
                var buf: [32768]u8 = undefined;
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
                var buf: [32768]u8 = undefined;
                var len: u64 = mach.memcpyMulti(&buf, &.{ about_build_s, name, ", " });
                if (old_size == 0) {
                    len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                        "\x1b[93m", builtin.fmt.ud64(new_size).readAll(), "*\x1b[0m bytes ",
                    });
                } else if (new_size == old_size) {
                    len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(new_size).readAll(), " bytes, ",
                    });
                } else if (new_size > old_size) {
                    len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(old_size).readAll(),             "(\x1b[91m+",
                        builtin.fmt.ud64(new_size -% old_size).readAll(), "\x1b[0m) => ",
                        builtin.fmt.ud64(new_size).readAll(),             " bytes, ",
                    });
                } else {
                    len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                        builtin.fmt.ud64(old_size).readAll(),             "(\x1b[92m-",
                        builtin.fmt.ud64(old_size -% new_size).readAll(), "\x1b[0m) => ",
                        builtin.fmt.ud64(new_size).readAll(),             " bytes, ",
                    });
                }
                len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                    builtin.fmt.ud64(durat.sec).readAll(),        ".",
                    builtin.fmt.nsec(durat.nsec).readAll()[0..3], "s\n",
                });
                builtin.debug.logAlways(buf[0..len]);
            }
            fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                var len: u64 = mach.memcpyMulti(&buf, &.{ about, name, ", " });
                len = len +% mach.memcpyMulti(buf[len..].ptr, &.{
                    "rc=", builtin.fmt.ud64(rc).readAll(),
                    ", ",  builtin.fmt.ud64(durat.sec).readAll(),
                    ".",   builtin.fmt.nsec(durat.nsec).readAll()[0..3],
                    "s\n",
                });
                builtin.debug.logAlways(buf[0..len]);
            }
            pub fn writeAndWalk(target: *Target) void {
                var buf0: [1048576]u8 = undefined;
                var buf1: [32768]u8 = undefined;
                @memcpy(&buf0, target.name.ptr, target.name.len);
                var len: u64 = target.name.len;
                len = writeAndWalkInternal(&buf0, len, &buf1, 0, target);
                builtin.debug.logAlways(buf0[0..len]);
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, target: *Builder.Target) u64 {
                @setRuntimeSafety(false);
                const deps: []Target.Dependency = target.buildDependencies();
                var len: u64 = len0;
                buf0[len] = '\n';
                len = len +% 1;
                for (deps, 0..) |dep, idx| {
                    @memcpy(buf1 + len1, if (idx == deps.len -% 1) "  " else "| ", 2);
                    @memcpy(buf0 + len, buf1, len1 +% 2);
                    len = len +% len1 +% 2;
                    @memcpy(buf0 + len, if (idx == deps.len -% 1) "\x08\x08`-" else "\x08\x08|-", 4);
                    len = len +% 4;
                    @memcpy(buf0 + len, if (dep.target.deps_len == 0) "> " else "+ ", 2);
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
                    @memcpy(buf0[len..].ptr, ":\n", 2);
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
                            @memcpy(buf0[len..].ptr, "\x1b[2m", 4);
                            len = len +% 4;
                            len = writeAndWalkInternal(&buf0, len, &buf1, 8, target);
                            @memcpy(buf0[len..].ptr, "\x1b[0m", 4);
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
                    @memcpy(buf + len, errorStyle().ptr, errorStyle().len);
                    len = len +% errorStyle().len;
                } else if (about.ptr == note_s) {
                    @memcpy(buf + len, noteStyle().ptr, noteStyle().len);
                    len = len +% noteStyle().len;
                }
                @memcpy(buf + len, about.ptr, about.len);
                len = len +% about.len;
                @memcpy(buf + len, ": ", 2);
                len = len +% 2;
                @memcpy(buf + len, "\x1b[0;1m", 6);
                return len +% 6;
            }
            fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(false);
                const err: *types.ErrorMessage = builtin.ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = builtin.ptrCast(*types.SourceLocation, extra + err.src_loc);
                var len: u64 = 4;
                @memcpy(buf + len, "\x1b[1m", 4);
                if (err.src_loc != 0) {
                    len = len +% writeSourceLocation(
                        buf + len,
                        meta.manyToSlice(bytes + src.src_path),
                        src.line +% 1,
                        src.column +% 1,
                    );
                    @memcpy(buf + len, ": ", 2);
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
                const pos: u64 = len +% about.len -% 2;
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
                var len: u64 = locationStyle().len;
                @memcpy(buf, locationStyle().ptr, locationStyle().len);
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
                @memcpy(buf, "\x1b[2m (", 6);
                var len: u64 = 6;
                @memcpy(buf + len, count_s.ptr, count_s.len);
                len = len +% count_s.len;
                @memcpy(buf + len, " times)\x1b[0m\n", 12);
                len = len +% 12;
                return len;
            }
            fn writeCaret(buf: [*]u8, bytes: [*:0]u8, src: *types.SourceLocation) u64 {
                @setRuntimeSafety(false);
                const line: [:0]u8 = meta.manyToSlice(bytes + src.src_line);
                const before_caret: u64 = src.span_main -% src.span_start;
                const indent: u64 = src.column -% before_caret;
                const after_caret: u64 = src.span_end -% src.span_main -| 1;
                @memcpy(buf, line.ptr, line.len);
                var len: u64 = line.len;
                buf[len] = '\n';
                len = len +% 1;
                @memset(buf + len, ' ', indent);
                len = len +% indent;
                @memcpy(buf + len, tildeStyle().ptr, tildeStyle().len);
                len = len +% tildeStyle().len;
                @memset(buf + len, '~', before_caret);
                len = len +% before_caret;
                buf[len] = '^';
                len = len +% 1;
                @memset(buf + len, '~', after_caret);
                len = len +% after_caret;
                @memcpy(buf + len, "\x1b[0m", 4);
                len = len +% 4;
                buf[len] = '\n';
                return len +% 1;
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
                @memcpy(buf + len, "\x1b[0m", 4);
                len = len +% 4;
                buf[len] = '\n';
                return len +% 1;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: u64, ref_len: u64) u64 {
                @setRuntimeSafety(false);
                var ref_idx: u64 = start +% types.SourceLocation.len;
                var idx: u64 = 0;
                var len: u64 = 0;
                @memcpy(buf + len, traceStyle().ptr, traceStyle().len);
                len +%= traceStyle().len;
                @memcpy(buf + len, "referenced by:\n", 15);
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
                        @memcpy(buf + len, ": ", 2);
                        len = len +% 2;
                        len = len +% writeSourceLocation(buf + len, src_file, ref_src.line +% 1, ref_src.column +% 1);
                        buf[len] = '\n';
                        len = len +% 1;
                    }
                    ref_idx +%= types.ReferenceTrace.len;
                }
                @memcpy(buf + len, "\x1b[0m\n", 5);
                return len +% 5;
            }
            fn writeErrors(allocator: *Allocator, hdr: *types.Message.ErrorHeader) void {
                @setRuntimeSafety(false);
                var buf: [*]u8 = allocate(allocator, u8, 1024 *% 1024).ptr;
                const extra: [*]u32 = hdr.extra();
                const bytes: [*:0]u8 = hdr.bytes();
                const list: *types.ErrorMessageList = builtin.ptrCast(*types.ErrorMessageList, extra);
                for ((extra + list.start)[0..list.len]) |err_msg_idx| {
                    builtin.debug.write(buf[0..writeError(buf, extra, bytes, err_msg_idx, error_s)]);
                }
                builtin.debug.write(meta.manyToSlice(bytes + list.compile_log_text));
                builtin.proc.exitGroup(2);
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
