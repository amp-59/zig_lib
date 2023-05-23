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
const cmdline = @import("./build/cmdline.zig");
pub usingnamespace types;
pub const BuilderSpec = struct {
    options: Options = .{},
    logging: Logging,
    errors: Errors,
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// Bytes allowed per thread arena (dynamic maximum)
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (static maximum)
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u64 = 32,
        /// Lowest allocated byte address for thread stacks. This field and the
        /// two previous fields derive the arena lowest allocated byte address,
        /// as this is the first unallocated byte address of the thread space.
        stack_lb_addr: u64 = 0x700000000000,
        /// This value is compared with return codes to determine whether a
        /// system or compile command succeeded.
        system_expected_status: u8 = 0,
        /// A compile job ended normally.
        compiler_expected_status: u8 = 0,
        /// A compile job ended in a cache hit
        compiler_cache_hit_status: u8 = 1,
        /// A compile job ended in an error
        compiler_error_status: u8 = 2,
        /// Assert no command line exceeds this length in bytes, making
        /// buildLength/formatLength unnecessary.
        max_cmdline_len: ?u64 = 65536,
        /// Assert no command line exceeds this number of individual arguments.
        max_cmdline_args: ?u64 = 1024,
        /// Time slept in nanoseconds between dependency scans.
        sleep_nanoseconds: u64 = 50000,
        /// Time in milliseconds allowed per build target.
        timeout_milliseconds: u64 = 1000 * 60 * 60 * 24,
        /// Enables logging for change of state of targets.
        show_targets: bool = false,
        /// Enables logging for build job statistics.
        show_stats: bool = true,
        /// Enables detail for target dependecy listings.
        show_detailed_deps: bool = true,
        /// Use `SimpleAllocator` instead of configured generic allocator.
        /// This will slightly speed compilation.
        prefer_simple_allocator: bool = true,
        names: struct {
            /// Module containing full paths of zig_exe, build_root, cache_root, and
            /// global_cache_root. May be useful for metaprogramming.
            env: [:0]const u8 = "env",
            /// Basename of output directory relative to build root.
            zig_out_dir: [:0]const u8 = "zig-out",
            /// Basename of cache directory relative to build root.
            zig_cache_dir: [:0]const u8 = "zig-cache",
            /// Basename of statistics directory relative to build root.
            zig_stat_dir: [:0]const u8 = "zig-stat",
            /// Basename of executables output directory relative to output directory.
            exe_out_dir: [:0]const u8 = "bin",
            /// Basename of library output directory relative to output directory.
            lib_out_dir: [:0]const u8 = "lib",
            /// Basename of auxiliary output directory relative to output directory.
            aux_out_dir: [:0]const u8 = "aux",
        } = .{},
        /// Configuration for output pathnames
        extensions: struct {
            /// Extension for Zig source files
            zig: [:0]const u8 = ".zig",
            /// Extension for C header source files
            h: [:0]const u8 = ".h",
            /// Extension for shared object files
            lib: [:0]const u8 = ".so",
            /// Extension for archives
            ar: [:0]const u8 = ".a",
            /// Extension for object files
            obj: [:0]const u8 = ".o",
            /// Extension for assembly source files
            @"asm": [:0]const u8 = ".s",
            /// Extension for LLVM bitcode files
            llvm_bc: [:0]const u8 = ".bc",
            /// Extension for LLVM intermediate representation files
            llvm_ir: [:0]const u8 = ".ll",
            /// Extension for JSON files
            analysis: [:0]const u8 = ".json",
            /// Extension for documentation files
            docs: [:0]const u8 = ".html",
        } = .{},
    };
    pub const Logging = packed struct {
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
        unlink: builtin.Logging.Field(file.UnlinkSpec),
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
        unlink: sys.ErrorPolicy,
    };
    usingnamespace Spec;
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
            .options = address_space_options,
        });
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "stack",
            .idx_type = AddressSpace.Index,
            .divisions = max_thread_count,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .errors = spec.address_space.errors.noexcept,
            .logging = spec.address_space.logging.silent,
            .options = thread_space_options,
        });
        pub const Allocator = if (builder_spec.options.prefer_simple_allocator)
            mem.SimpleAllocator
        else
            mem.GenericRtArenaAllocator(.{
                .AddressSpace = AddressSpace,
                .logging = spec.allocator.logging.silent,
                .errors = spec.allocator.errors.noexcept,
                .options = allocator_options,
            });
        pub const Target = struct {
            name: [:0]const u8 = &.{},
            descr: [:0]const u8 = &.{},
            root: [:0]const u8,
            paths: []types.Path = &.{},
            paths_len: u64 = 0,
            deps: []Dependency = &.{},
            deps_len: u64 = 0,
            args: [][*:0]u8 = &.{},
            args_len: u64 = 0,
            task: types.Task = .none,
            task_lock: types.Lock = undefined,
            task_cmd: TaskCommand = undefined,
            hidden: bool = false,
            pub const Dependency = struct {
                task: types.Task,
                comptime state: types.State = .ready,
                on_target: *Target,
                on_task: types.Task,
                on_state: types.State,
            };
            pub const TaskCommand = packed union {
                build: *types.BuildCommand,
                format: *types.FormatCommand,
                archive: *types.ArchiveCommand,
            };
            fn acquireThread(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: types.Task,
                depth: u64,
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.abort ++
                    builder_spec.errors.fork.abort ++ builder_spec.errors.execve.abort ++ builder_spec.errors.waitpid.abort,
            }, void) {
                if (max_thread_count == 0) {
                    try meta.wrap(impl.executeCommand(builder, allocator, target, task, depth));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (mem.testAcquire(ThreadSpace, thread_space, arena_index)) {
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
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.abort ++ builder_spec.errors.sleep.abort ++
                    builder_spec.errors.fork.abort ++ builder_spec.errors.execve.abort ++ builder_spec.errors.waitpid.abort,
            }, void) {
                @setRuntimeSafety(false);
                if (target.task_lock.get(task) == .waiting) {
                    for (target.deps[0..target.deps_len]) |dep| {
                        if (dep.task == task and
                            dep.on_target != target or dep.on_task != task)
                        {
                            try meta.wrap(dep.on_target.acquireLock(address_space, thread_space, allocator, builder, dep.on_task, arena_index, depth +% 1));
                        }
                    }
                    while (targetWait(target, task, arena_index)) {
                        try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                    }
                }
                if (target.exchange(task, .ready, .working)) {
                    try meta.wrap(target.acquireThread(address_space, thread_space, allocator, builder, task, depth));
                }
            }
            pub fn executeToplevel(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                maybe_task: ?types.Task,
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.abort ++ builder_spec.errors.sleep.abort ++
                    builder_spec.errors.fork.abort ++ builder_spec.errors.execve.abort ++ builder_spec.errors.waitpid.abort,
            }, void) {
                const task: types.Task = maybe_task orelse target.task;
                try meta.wrap(target.acquireLock(address_space, thread_space, allocator, builder, task, max_thread_count, 0));
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
            inline fn createBinaryPath(target: *Target, allocator: *Allocator, builder: *const Builder) types.Path {
                return .{
                    .absolute = builder.build_root,
                    .relative = binaryRelative(allocator, target.task_cmd.build),
                };
            }
            inline fn createArchivePath(target: *Target, allocator: *Allocator, builder: *const Builder) types.Path {
                return .{
                    .absolute = builder.build_root,
                    .relative = archiveRelative(allocator, target.name),
                };
            }
            fn createAuxiliaryPath(target: *Target, allocator: *Allocator, builder: *const Builder, kind: types.AuxOutputMode) types.Path {
                return .{ .absolute = builder.build_root, .relative = auxiliaryRelative(target, allocator, kind) };
            }
            pub fn emitAuxiliary(target: *Target, allocator: *Allocator, builder: *const Builder, kind: types.AuxOutputMode) void {
                const aux_path = .{ .yes = createAuxiliaryPath(target, allocator, builder, kind) };
                switch (kind) {
                    .@"asm" => target.task_cmd.build.emit_asm = aux_path,
                    .llvm_ir => target.task_cmd.build.emit_llvm_ir = aux_path,
                    .llvm_bc => target.task_cmd.build.emit_llvm_bc = aux_path,
                    .h => target.task_cmd.build.emit_h = aux_path,
                    .docs => target.task_cmd.build.emit_docs = aux_path,
                    .analysis => target.task_cmd.build.emit_analysis = aux_path,
                    .implib => target.task_cmd.build.emit_implib = aux_path,
                }
            }
            fn rootSourcePath(target: *Target, builder: *const Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = target.root };
            }
            pub fn dependOnFormat(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, target.task, dependency, .format, .finished);
            }
            pub fn dependOnBuild(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, target.task, dependency, .build, .finished);
            }
            pub fn dependOnRun(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, target.task, dependency, .run, .finished);
            }
            pub fn dependOnObject(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.dependOnBuild(allocator, dependency);
                target.addFile(allocator, dependency.task_cmd.build.emit_bin.?.yes.?);
            }
            pub fn dependOnArchive(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.dependOnBuild(allocator, dependency);
                target.addFile(allocator, dependency.task_cmd.archive.archive.?);
            }
            fn exchange(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) bool {
                const ret: bool = target.task_lock.atomicExchange(task, old_state, new_state);
                if (builtin.logging_general.Success or builder_spec.options.show_targets) {
                    if (ret) {
                        debug.exchangeNotice(target, task, old_state, new_state);
                    } else {
                        debug.noExchangeNotice(target, debug.about.state_0_s, task, old_state, new_state);
                    }
                }
                return ret;
            }
            fn assertExchange(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                if (old_state == new_state) {
                    return;
                }
                const res: bool = target.task_lock.atomicExchange(task, old_state, new_state);
                if (res) {
                    if (builtin.logging_general.Success or builder_spec.options.show_targets) {
                        debug.exchangeNotice(target, task, old_state, new_state);
                    }
                } else {
                    if (builtin.logging_general.Fault or builder_spec.options.show_targets) {
                        debug.noExchangeNotice(target, debug.about.state_1_s, task, old_state, new_state);
                    }
                    builtin.proc.exitGroup(2);
                }
            }
            pub fn addFile(target: *Target, allocator: *Allocator, path: types.Path) void {
                @setRuntimeSafety(false);
                if (target.paths_len == target.paths.len) {
                    target.paths = allocator.reallocate(types.Path, target.paths, (target.paths_len +% 1) *% 2);
                }
                target.paths[target.paths_len] = path;
                target.paths_len +%= 1;
            }
            fn addDependency(target: *Target, allocator: *Allocator, task: types.Task, on_target: *Target, on_task: types.Task, on_state: types.State) void {
                @setRuntimeSafety(false);
                if (target.deps_len == target.deps.len) {
                    target.deps = allocator.reallocate(Dependency, target.deps, (target.deps_len +% 1) *% 2);
                }
                target.assertExchange(task, target.task_lock.get(task), .waiting);
                target.deps[target.deps_len] = .{
                    .task = task,
                    .on_target = on_target,
                    .on_task = on_task,
                    .on_state = on_state,
                };
                target.deps_len +%= 1;
            }
            pub fn addRunCommand(target: *Target, allocator: *Allocator) void {
                @setRuntimeSafety(false);
                if (target.exchange(.run, .no_task, .ready)) {
                    target.addDependency(allocator, .run, target, .build, .finished);
                }
            }
            pub fn addRunArgument(target: *Target, allocator: *Allocator, arg: []const u8) void {
                @setRuntimeSafety(false);
                if (target.args_len == 0) {
                    target.args = allocator.allocate([*:0]u8, 5);
                    target.args[0] = allocator.allocate(u8, 4096)[0.. :0];
                    builtin.assert(target.task_cmd.build.emit_bin.?.yes.?.formatWriteBuf(target.args[0]) != 0);
                    target.args_len = 1;
                } else if (target.args_len == target.args.len) {
                    target.args = allocator.reallocate([*:0]u8, target.args, (target.args_len +% 1) *% 2);
                }
                target.args[target.args_len] = strdup(allocator, arg).ptr;
                target.args_len +%= @boolToInt(arg.len != 0);
            }
            fn generateName(target: *Target, allocator: *Allocator) [:0]const u8 {
                @setRuntimeSafety(false);
                if (target.name.len != 0) {
                    return strdup(allocator, target.name);
                }
                const buf: [*]u8 = allocator.allocate(u8, target.root.len +% 1).ptr;
                mach.memcpy(buf, target.root.ptr, target.root.len);
                buf[target.root.len] = 0;
                var idx: u64 = 0;
                while (idx != target.root.len) : (idx +%= 1) {
                    buf[idx] -%= @boolToInt(buf[idx] == 0x2f);
                }
                target.hidden = true;
                return buf[0..target.root.len :0];
            }
        };
        pub const Group = struct {
            name: [:0]const u8,
            builder: *Builder,
            trgs: []*Target = &.{},
            trgs_len: u64 = 0,
            hidden: bool = false,
            pub fn addBuild(group: *Group, allocator: *Allocator, build_cmd: types.BuildCommand, target: Target) !*Target {
                const ret: *Target = try group.addTarget(allocator);
                ret.* = target;
                const cmd: *types.BuildCommand = allocator.create(types.BuildCommand);
                cmd.* = build_cmd;
                ret.task = .build;
                ret.hidden = group.hidden;
                ret.name = ret.generateName(allocator);
                if (cmd.name == null) {
                    cmd.name = target.name;
                }
                if (cmd.main_pkg_path == null) {
                    cmd.main_pkg_path = group.builder.build_root;
                }
                if (cmd.cache_root == null) {
                    cmd.cache_root = group.builder.cache_root;
                }
                if (cmd.global_cache_root == null) {
                    cmd.global_cache_root = group.builder.global_cache_root;
                }
                cmd.emit_bin = .{ .yes = .{
                    .absolute = group.builder.build_root,
                    .relative = binaryRelative(allocator, cmd),
                } };
                if (cmd.kind == .exe) {
                    ret.addRunCommand(allocator);
                }
                ret.task_cmd = .{ .build = cmd };
                ret.assertExchange(.build, .no_task, .ready);
                return ret;
            }
            pub fn addFormat(group: *Group, allocator: *Allocator, format_cmd: types.FormatCommand, target: Target) !*Target {
                const ret: *Target = try group.addTarget(allocator);
                ret.* = target;
                const cmd: *types.FormatCommand = allocator.create(types.FormatCommand);
                cmd.* = format_cmd;
                ret.task = .format;
                ret.hidden = group.hidden;
                ret.name = ret.generateName(allocator);
                ret.task_cmd = .{ .format = cmd };
                ret.assertExchange(.format, .no_task, .ready);
                return ret;
            }
            pub fn addArchive(group: *Group, allocator: *Allocator, archive_cmd: types.ArchiveCommand, target: Target, deps: []const *Target) !*Target {
                const ret: *Target = try group.addTarget(allocator);
                ret.* = target;
                const cmd: *types.ArchiveCommand = allocator.create(types.ArchiveCommand);
                cmd.* = archive_cmd;
                ret.task = .archive;
                ret.hidden = group.hidden;
                ret.name = ret.generateName(allocator);
                for (deps) |dep| {
                    ret.dependOnObject(allocator, dep);
                }
                ret.task_cmd.archive.archive = .{
                    .absolute = group.builder.build_root,
                    .relative = archiveRelative(allocator, ret.name),
                };
                ret.task_cmd = .{ .archive = cmd };
                ret.assertExchange(.archive, .no_task, .ready);
                return ret;
            }
            pub fn describeTarget(group: *Group, target_name: []const u8, target_descr: []const u8) void {
                @setRuntimeSafety(false);
                for (group.trgs[0..group.trgs_len]) |target| {
                    if (mach.testEqualMany8(target_name, target.name)) {
                        target.descr = target_descr;
                    }
                }
            }
            pub fn addTarget(group: *Group, allocator: *Allocator) !*Target {
                @setRuntimeSafety(false);
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = allocator.reallocate(*Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = allocator.create(Target);
                group.trgs[group.trgs_len] = ret;
                group.trgs_len +%= 1;
                return ret;
            }
            pub fn executeToplevel(
                group: *Group,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                maybe_task: ?types.Task,
            ) !void {
                @setRuntimeSafety(false);
                for (group.trgs[0..group.trgs_len]) |target| {
                    const task: types.Task = maybe_task orelse target.task;
                    try meta.wrap(target.acquireLock(address_space, thread_space, allocator, group.builder, task, max_thread_count, 1));
                }
                while (groupWait(group, maybe_task)) {
                    try meta.wrap(time.sleep(builder_spec.sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
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
        inline fn clientLoop(allocator: *Allocator, out: file.Pipe, working_time: *time.TimeSpec, pid: u64) u8 {
            const hdr: *types.Message.ServerHeader = allocator.create(types.Message.ServerHeader);
            const save: Allocator.Save = allocator.save();
            var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
            var ret: u8 = builder_spec.options.compiler_expected_status;
            while (try meta.wrap(
                file.pollOne(builder_spec.poll(), &fd, builder_spec.options.timeout_milliseconds),
            )) : (fd.actual = .{}) {
                try meta.wrap(
                    file.readOne(builder_spec.read3(), out.read, hdr),
                );
                const msg: []u8 = allocator.allocate(u8, hdr.bytes_len);
                mach.memset(msg.ptr, 0, msg.len);
                var len: u64 = 0;
                while (len != hdr.bytes_len) {
                    len +%= try meta.wrap(
                        file.read(builder_spec.read2(), out.read, msg[len..hdr.bytes_len]),
                    );
                }
                if (hdr.tag == .emit_bin_path) break {
                    ret = msg[0];
                };
                if (hdr.tag == .error_bundle) break {
                    debug.writeErrors(allocator, types.Message.ErrorHeader.create(msg));
                    ret = builder_spec.options.compiler_error_status;
                };
                allocator.restore(save);
            }
            allocator.restore(save);
            try meta.wrap(
                proc.waitPid(builder_spec.waitpid(), .{ .pid = pid }),
            );
            working_time.* = time.diff(try meta.wrap(
                time.get(builder_spec.clock(), .realtime),
            ), working_time.*);
            try meta.wrap(
                file.close(builder_spec.close(), out.read),
            );
            return ret;
        }
        fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            ts.* = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) try meta.wrap(
                file.execPath(builder_spec.execve(), meta.manyToSlice(args[0]), args, builder.vars),
            );
            const ret: proc.Return = try meta.wrap(
                proc.waitPid(builder_spec.waitpid2(), .{ .pid = pid }),
            );
            ts.* = time.diff(try meta.wrap(time.get(builder_spec.clock(), .realtime)), ts.*);
            return proc.Status.exit(ret.status);
        }
        inline fn compile(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            ts.* = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) {
                try meta.wrap(
                    file.execPath(builder_spec.execve(), builder.zig_exe, args, builder.vars),
                );
            }
            const ret: proc.Return = try meta.wrap(
                proc.waitPid(builder_spec.waitpid2(), .{ .pid = pid }),
            );
            ts.* = time.diff(try meta.wrap(time.get(builder_spec.clock(), .realtime)), ts.*);
            return proc.Status.exit(ret.status);
        }
        inline fn compileServer(builder: *const Builder, allocator: *Builder.Allocator, args: [][*:0]u8, ts: *time.TimeSpec) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            const in: file.Pipe = try meta.wrap(file.makePipe(builder_spec.pipe()));
            const out: file.Pipe = try meta.wrap(file.makePipe(builder_spec.pipe()));
            ts.* = try meta.wrap(time.get(builder_spec.clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(builder_spec.fork()));
            if (pid == 0) {
                try meta.wrap(openChild(in, out));
                try meta.wrap(
                    file.execPath(builder_spec.execve(), builder.zig_exe, args, builder.vars),
                );
            }
            try meta.wrap(openParent(in, out));
            try meta.wrap(
                file.write(builder_spec.write2(), in.write, &update_exit_message),
            );
            try meta.wrap(
                file.close(builder_spec.close(), in.write),
            );
            return try meta.wrap(
                clientLoop(allocator, out, ts, pid),
            );
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
                var allocator: Builder.Allocator = if (Builder.Allocator == mem.SimpleAllocator)
                    Builder.Allocator.init_arena(Builder.AddressSpace.arena(arena_index))
                else
                    Builder.Allocator.init(address_space, arena_index);
                if (if (task == .run) meta.wrap(
                    executeRunCommand(builder, &allocator, target, depth),
                ) catch false else meta.wrap(
                    executeCompilerCommand(builder, &allocator, target, depth, task),
                ) catch false) {
                    target.assertExchange(task, .working, .finished);
                } else {
                    target.assertExchange(task, .working, .failed);
                }
                if (Builder.Allocator == mem.SimpleAllocator)
                    allocator.unmap()
                else
                    allocator.deinit(address_space, arena_index);
                mem.release(ThreadSpace, thread_space, arena_index);
            }
            fn executeCommand(
                builder: *Builder,
                allocator: *Allocator,
                target: *Target,
                task: types.Task,
                depth: u64,
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                if (if (task == .run) try meta.wrap(
                    executeRunCommand(builder, allocator, target, depth),
                ) else try meta.wrap(
                    executeCompilerCommand(builder, allocator, target, depth, task),
                )) {
                    target.assertExchange(task, .working, .finished);
                } else {
                    target.assertExchange(task, .working, .failed);
                }
            }
        };
        fn buildWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            const build_cmd: *types.BuildCommand = target.task_cmd.build;
            @setRuntimeSafety(false);
            build_cmd.files = target.paths[0..target.paths_len];
            if (max_thread_count != 0) {
                build_cmd.listen = .@"-";
            }
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse
                cmdline.buildLength(build_cmd, builder.zig_exe, root_path);
            if (@hasDecl(cmdline, "buildWrite")) {
                const Args = Allocator.StructuredVectorLowAlignedWithSentinel(u8, 0, 8);
                var array: Args = Args.init(allocator, max_len);
                cmdline.buildWrite(build_cmd, builder.zig_exe, root_path, &array);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, array.len());
                }
                return array.referAllDefinedWithSentinel(0);
            } else {
                const buf: []u8 = allocator.allocate(u8, max_len);
                const len: u64 = cmdline.buildWriteBuf(build_cmd, builder.zig_exe, root_path, buf.ptr);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, len);
                }
                return buf[0..len :0];
            }
        }
        fn archiveWrite(builder: *Builder, target: *Target, allocator: *Allocator) [:0]u8 {
            @setRuntimeSafety(false);
            const archive_cmd: *types.ArchiveCommand = target.task_cmd.archive;
            archive_cmd.files = target.paths[0..target.paths_len];
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse
                cmdline.archiveLength(archive_cmd, builder.zig_exe);
            if (@hasDecl(cmdline, "archiveWrite")) {
                const Args = Allocator.StructuredVectorLowAlignedWithSentinel(u8, 0, 8);
                var array: Args = Args.init(allocator, max_len);
                cmdline.archiveWrite(archive_cmd, builder.zig_exe, &array);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, array.len());
                }
                return array.referAllDefinedWithSentinel(0);
            } else {
                const buf: []u8 = allocator.allocate(u8, max_len);
                const len: u64 = cmdline.archiveWriteBuf(archive_cmd, builder.zig_exe, buf.ptr);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, len);
                }
                return buf[0..len :0];
            }
        }
        fn formatWrite(builder: *Builder, target: *Target, allocator: *Allocator, root_path: types.Path) [:0]u8 {
            @setRuntimeSafety(false);
            const format_cmd: *types.FormatCommand = target.task_cmd.format;
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse
                cmdline.formatLength(format_cmd, builder.zig_exe, root_path);
            if (@hasDecl(cmdline, "formatWrite")) {
                const Args = Allocator.StructuredVectorLowAlignedWithSentinel(u8, 0, 8);
                var array: Args = Args.init(allocator, max_len);
                cmdline.formatWrite(format_cmd, builder.zig_exe, root_path, &array);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, array.len());
                }
                return array.referAllDefinedWithSentinel(0);
            } else {
                const buf: []u8 = allocator.allocate(u8, max_len);
                const len: u64 = cmdline.formatWriteBuf(format_cmd, builder.zig_exe, root_path, buf.ptr);
                if (builder_spec.options.max_cmdline_len == null) {
                    builtin.assertEqual(u64, max_len, len);
                }
                return buf[0..len :0];
            }
        }
        fn executeCompilerCommand(builder: *Builder, allocator: *Allocator, target: *Target, _: u64, task: types.Task) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, bool) {
            @setRuntimeSafety(false);
            const root_path: types.Path = target.rootSourcePath(builder);
            var working_time: time.TimeSpec = undefined;
            var rc: u8 = undefined;
            var old_size: u64 = undefined;
            var new_size: u64 = undefined;
            const args: [:0]u8 = try meta.wrap(switch (task) {
                .format => formatWrite(builder, target, allocator, root_path),
                .archive => archiveWrite(builder, target, allocator),
                else => buildWrite(builder, target, allocator, root_path),
            });
            if (task == .build) {
                const out_path: [:0]const u8 = binaryRelative(
                    allocator,
                    target.task_cmd.build,
                );
                const ptrs: [][*:0]u8 = try meta.wrap(
                    makeArgPtrs(allocator, args),
                );
                old_size = builder.getFileSize(out_path);
                rc = try meta.wrap(
                    builder.compileServer(allocator, ptrs, &working_time),
                );
                new_size = builder.getFileSize(out_path);
            } else {
                const ptrs: [][*:0]u8 = try meta.wrap(
                    makeArgPtrs(allocator, args),
                );
                rc = try meta.wrap(
                    builder.system(ptrs, &working_time),
                );
            }
            if (task == .build or task == .archive) {
                debug.buildNotice(target, working_time, old_size, new_size, rc);
            }
            if (task == .run or task == .format) {
                debug.simpleTimedNotice(target, working_time, task, rc);
            }
            return status(rc);
        }
        fn executeRunCommand(builder: *Builder, allocator: *Allocator, target: *Target, _: u64) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, bool) {
            @setRuntimeSafety(false);
            for (builder.args[builder.args_len..]) |run_arg| {
                target.addRunArgument(allocator, meta.manyToSlice(run_arg));
            }
            target.addRunArgument(allocator, null_arg);
            const args: [][*:0]u8 = target.args[0..target.args_len];
            var working_time: time.TimeSpec = undefined;
            const rc: u8 = try meta.wrap(
                builder.system(args, &working_time),
            );
            if (builder_spec.options.show_stats) {
                debug.simpleTimedNotice(target, working_time, .run, rc);
            }
            return status(rc);
        }
        pub fn init(args: [][*:0]u8, vars: [][*:0]u8) sys.ErrorUnion(.{
            .throw = builder_spec.errors.mkdir.throw ++
                builder_spec.errors.path.throw ++ builder_spec.errors.close.throw ++ builder_spec.errors.create.throw,
            .abort = builder_spec.errors.mkdir.abort ++
                builder_spec.errors.path.abort ++ builder_spec.errors.close.abort ++ builder_spec.errors.create.abort,
        }, Builder) {
            @setRuntimeSafety(false);
            const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
            const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
            const cache_root: [:0]const u8 = meta.manyToSlice(args[3]);
            const global_cache_root: [:0]const u8 = meta.manyToSlice(args[4]);
            const build_root_fd: u64 = try meta.wrap(file.path(builder_spec.path(), build_root));
            if (!thread_space_options.require_map) {
                mem.map(builder_spec.map(), stack_lb_addr, stack_up_addr -% stack_lb_addr);
            }
            try meta.wrap(
                file.makeDirAt(builder_spec.mkdir(), build_root_fd, builder_spec.options.names.zig_out_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(builder_spec.mkdir(), build_root_fd, builder_spec.options.names.zig_stat_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(builder_spec.mkdir(), build_root_fd, zig_out_exe_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(builder_spec.mkdir(), build_root_fd, zig_out_aux_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(builder_spec.mkdir(), build_root_fd, zig_out_lib_dir, file.mode.directory),
            );
            const cache_root_fd: u64 = try meta.wrap(
                file.path(builder_spec.path(), cache_root),
            );
            const env_fd: u64 = try meta.wrap(
                file.createAt(builder_spec.create(), cache_root_fd, env_basename, file.mode.regular),
            );
            writeEnv(env_fd, zig_exe, build_root, cache_root, global_cache_root);
            try meta.wrap(
                file.close(builder_spec.close(), env_fd),
            );
            try meta.wrap(
                file.close(builder_spec.close(), cache_root_fd),
            );
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
                builder.grps = try meta.wrap(allocator.reallocate(*Group, builder.grps, (builder.grps_len +% 1) *% 2));
            }
            const ret: *Group = allocator.create(Group);
            builder.grps[builder.grps_len] = ret;
            builder.grps_len +%= 1;
            ret.* = .{ .name = name, .builder = builder, .trgs = &.{}, .trgs_len = 0, .hidden = name[0] == '_' };
            return ret;
        }
        inline fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.Status {
            return file.statusAt(.{ .errors = .{ .throw = sys.stat_errors } }, builder.dir_fd, name) catch null;
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
            @setRuntimeSafety(false);
            var target_task: ?types.Task = null;
            var idx: u64 = 5;
            lo: while (idx < builder.args_len) : (idx +%= 1) {
                const command: []const u8 = meta.manyToSlice(builder.args[idx]);
                if (builder.args_len == builder.args.len) {
                    if (mach.testEqualMany8(command, "--")) {
                        builder.args_len = idx;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "build")) {
                        target_task = .build;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "run")) {
                        target_task = .run;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "format")) {
                        target_task = .format;
                        continue :lo;
                    }
                    if (mach.testEqualMany8(command, "list")) {
                        debug.builderCommandNotice(builder, true, true, true);
                        continue :lo;
                    }
                }
                for (builder.grps[0..builder.grps_len]) |group| {
                    if (mach.testEqualMany8(command, group.name)) {
                        builder.args_len = idx +% 1;
                        try meta.wrap(group.executeToplevel(address_space, thread_space, allocator, target_task));
                        continue :lo;
                    }
                    for (group.trgs[0..group.trgs_len]) |target| {
                        if (mach.testEqualMany8(command, target.name)) {
                            builder.args_len = idx +% 1;
                            try meta.wrap(target.executeToplevel(address_space, thread_space, allocator, builder, target_task));
                            continue :lo;
                        }
                    }
                }
                builtin.proc.exitError(error.TargetDoesNotExist, 2);
            }
        }
        fn targetWait(target: *Target, task: types.Task, arena_index: AddressSpace.Index) bool {
            for (target.deps[0..target.deps_len]) |*dep| {
                if (dep.on_target == target and dep.on_task == task) {
                    continue;
                }
                if (dep.on_target.task_lock.get(dep.on_task) != dep.on_state) {
                    if (dep.on_target.task_lock.get(dep.on_task) == .failed) {
                        target.assertExchange(task, .waiting, .failed);
                        if (max_thread_count != 0) {
                            if (arena_index != max_thread_count) {
                                builtin.proc.exitError(error.Dependencyfailed, 2);
                            }
                        }
                        return false;
                    } else {
                        return true;
                    }
                }
            }
            target.assertExchange(task, .waiting, .ready);
            return false;
        }
        fn groupWait(group: *Group, maybe_task: ?types.Task) bool {
            @setRuntimeSafety(false);
            for (group.trgs[0..group.trgs_len]) |target| {
                const task: types.Task = maybe_task orelse target.task;
                if (target.task_lock.get(task) == .working) {
                    return true;
                }
            }
            return false;
        }
        fn builderWait(address_space: *Builder.AddressSpace, thread_space: *Builder.ThreadSpace, builder: *Builder) bool {
            @setRuntimeSafety(false);
            for (builder.grps[0..builder.grps_len]) |group| {
                for (group.trgs[0..group.trgs_len]) |target| {
                    for (types.Task.list) |task| {
                        if (target.task_lock.get(task) == .working) {
                            return true;
                        }
                    }
                }
            }
            if (max_thread_count == 0) {
                return false;
            }
            if (thread_space.count() != 0) {
                return true;
            }
            if (builder_spec.options.prefer_simple_allocator) {
                return false;
            }
            if (address_space.count() != 1) {
                return true;
            }
            return false;
        }
        fn status(rc: u8) bool {
            return rc == builder_spec.options.compiler_cache_hit_status or
                rc == builder_spec.options.compiler_expected_status or
                rc == builder_spec.options.system_expected_status;
        }
        fn openChild(in: file.Pipe, out: file.Pipe) sys.ErrorUnion(.{
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
        fn openParent(in: file.Pipe, out: file.Pipe) sys.ErrorUnion(builder_spec.errors.close, void) {
            try meta.wrap(
                file.close(builder_spec.close(), in.read),
            );
            try meta.wrap(
                file.close(builder_spec.close(), out.write),
            );
        }
        // Should be in a `GenericBuildCommand` namespace
        fn binaryRelative(allocator: *Allocator, build_cmd: *types.BuildCommand) [:0]const u8 {
            const kind: types.OutputMode = build_cmd.kind;
            switch (kind) {
                .exe => return concatenate(allocator, &[_][]const u8{ zig_out_exe_dir ++ "/", build_cmd.name.? }),
                .lib => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_exe_dir ++ "/", build_cmd.name.?, builder_spec.options.extensions.lib },
                ),
                .obj => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_exe_dir ++ "/", build_cmd.name.?, builder_spec.options.extensions.obj },
                ),
            }
        }
        fn archiveRelative(allocator: *Allocator, name: [:0]const u8) [:0]const u8 {
            return concatenate(
                allocator,
                &[_][]const u8{ zig_out_lib_dir ++ "/lib", name, builder_spec.options.extensions.ar },
            );
        }
        fn auxiliaryRelative(allocator: *Allocator, name: [:0]const u8, kind: types.AuxOutputMode) [:0]u8 {
            switch (kind) {
                .@"asm" => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.@"asm" },
                ),
                .llvm_ir => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.llvm_ir },
                ),
                .llvm_bc => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.llvm_bc },
                ),
                .h => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.h },
                ),
                .docs => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.docs },
                ),
                .analysis => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.analysis },
                ),
                .implib => return concatenate(
                    allocator,
                    &[_][]const u8{ zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.implib },
                ),
            }
        }
        const update_exit_message: [2]types.Message.ClientHeader = .{
            .{ .tag = .update, .bytes_len = 0 },
            .{ .tag = .exit, .bytes_len = 0 },
        };
        const address_space_options: mem.ArenaOptions = .{
            .thread_safe = true,
            .require_map = false,
            .require_unmap = false,
        };
        const thread_space_options: mem.ArenaOptions = .{
            .thread_safe = true,
            .require_map = false,
            .require_unmap = false,
        };
        const allocator_options: mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
            .init_commit = arena_aligned_bytes,
            .require_map = !address_space_options.require_map,
            .require_unmap = !address_space_options.require_unmap,
        };
        const zig_out_exe_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.exe_out_dir;
        const zig_out_lib_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.lib_out_dir;
        const zig_out_aux_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.aux_out_dir;
        const env_basename: [:0]const u8 = builder_spec.options.names.env ++ builder_spec.options.extensions.zig;
        const null_arg: [:0]const u8 = builtin.zero([:0]u8);
        pub const debug = struct {
            const about = .{
                .ar_s = builtin.fmt.about("ar"),
                .run_s = builtin.fmt.about("run"),
                .format_s = builtin.fmt.about("fmt"),
                .build_exe_s = builtin.fmt.about("build-exe"),
                .build_obj_s = builtin.fmt.about("build-obj"),
                .build_lib_s = builtin.fmt.about("build-lib"),
                .state_0_s = builtin.fmt.about("state"),
                .state_1_s = builtin.fmt.about("state-fault"),
                .next_s = ", ",
                .error_s = "error",
                .note_s = "note",
                .bytes_s = " bytes, ",
                .gold_s = "\x1b[93m",
                .green_s = "\x1b[92m",
                .red_s = "\x1b[91m",
                .new_s = "\x1b[0m\n",
                .reset_s = "\x1b[0m",
                .tilde_s = "\x1b[38;5;46m",
                .bold_s = "\x1b[1m",
                .faint_s = "\x1b[2m",
                .grey_s = "\x1b[0;38;5;250;1m",
                .trace_s = "\x1b[38;5;247m",
                .hi_red_s = "\x1b[38;5;196m",
            };
            const fancy_hl_line: bool = false;
            fn exchangeNotice(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                var ptr: [*]u8 = &buf;
                var len: u64 = 0;
                @ptrCast(*[about.state_0_s.len]u8, ptr).* = about.state_0_s.*;
                len = len + about.state_0_s.len;
                mach.memcpy(ptr + len, target.name.ptr, target.name.len);
                len +%= target.name.len;
                ptr[len] = '.';
                len +%= 1;
                mach.memcpy(ptr + len, @tagName(task).ptr, @tagName(task).len);
                len +%= @tagName(task).len;
                @ptrCast(*[2]u8, ptr + len).* = about.next_s.*;
                len +%= 2;
                mach.memcpy(ptr + len, @tagName(old_state).ptr, @tagName(old_state).len);
                len +%= @tagName(old_state).len;
                @ptrCast(*[4]u8, ptr + len).* = " -> ".*;
                len +%= 4;
                mach.memcpy(ptr + len, @tagName(new_state).ptr, @tagName(new_state).len);
                len +%= @tagName(new_state).len;
                ptr[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn noExchangeNotice(target: *Target, about_s: [:0]const u8, task: types.Task, old_state: types.State, new_state: types.State) void {
                @setRuntimeSafety(false);
                var buf: [32768]u8 = undefined;
                var ptr: [*]u8 = &buf;
                const actual: types.State = target.task_lock.get(task);
                mach.memcpy(ptr, about_s.ptr, about_s.len);
                var len: u64 = about_s.len;
                mach.memcpy(ptr + len, target.name.ptr, target.name.len);
                len +%= target.name.len;
                ptr[len] = '.';
                len +%= 1;
                mach.memcpy(ptr + len, @tagName(task).ptr, @tagName(task).len);
                len +%= @tagName(task).len;
                @ptrCast(*[2]u8, ptr + len).* = about.next_s.*;
                len +%= 2;
                mach.memcpy(ptr + len, @tagName(old_state).ptr, @tagName(old_state).len);
                len +%= @tagName(old_state).len;
                @ptrCast(*[2]u8, ptr + len).* = " (".*;
                len +%= 2;
                mach.memcpy(ptr + len, @tagName(actual).ptr, @tagName(actual).len);
                len +%= @tagName(actual).len;
                @ptrCast(*[2]u8, ptr + len).* = ") ".*;
                len +%= 2;
                @ptrCast(*[7]u8, ptr + len).* = " -!!-> ".*;
                len +%= 7;
                mach.memcpy(ptr + len, @tagName(new_state).ptr, @tagName(new_state).len);
                len +%= @tagName(new_state).len;
                ptr[len] = '\n';
                builtin.debug.write(ptr[0 .. len +% 1]);
            }
            fn buildNotice(target: *const Target, working_time: time.TimeSpec, old_size: u64, new_size: u64, rc: u8) void {
                @setRuntimeSafety(false);
                const diff_size: u64 = @max(new_size, old_size) -% @min(new_size, old_size);
                const new_size_s: []const u8 = builtin.fmt.ud64(new_size).readAll();
                const old_size_s: []const u8 = builtin.fmt.ud64(old_size).readAll();
                const diff_size_s: []const u8 = builtin.fmt.ud64(diff_size).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(working_time.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(working_time.nsec).readAll();
                var buf: [32768]u8 = undefined;
                var len: u64 = about.build_exe_s.len;
                mach.memcpy(&buf, switch (target.task_cmd.build.kind) {
                    .exe => about.build_exe_s,
                    .obj => about.build_obj_s,
                    .lib => about.build_lib_s,
                }.ptr, len);
                if (rc == builder_spec.options.compiler_cache_hit_status or working_time.nsec < 45000000 and
                    rc != builder_spec.options.compiler_error_status)
                {
                    mach.memcpy(buf[len..].ptr, about.trace_s.ptr, about.trace_s.len);
                    len +%= about.trace_s.len;
                }
                mach.memcpy(buf[len..].ptr, target.name.ptr, target.name.len);
                len +%= target.name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                const mode: builtin.Mode = target.task_cmd.build.mode orelse .Debug;
                mach.memcpy(buf[len..].ptr, @tagName(mode).ptr, @tagName(mode).len);
                len +%= @tagName(mode).len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                if (old_size == 0) {
                    @ptrCast(*[5]u8, buf[len..].ptr).* = about.gold_s.*;
                    len +%= 5;
                    mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len +%= new_size_s.len;
                    buf[len] = '*';
                    len +%= 1;
                    @ptrCast(*[4]u8, buf[len..].ptr).* = about.reset_s.*;
                    len +%= 4;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = about.bytes_s.*;
                    len +%= 8;
                } else if (new_size == old_size) {
                    mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len +%= new_size_s.len;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = about.bytes_s.*;
                    len +%= 8;
                } else {
                    mach.memcpy(buf[len..].ptr, old_size_s.ptr, old_size_s.len);
                    len +%= old_size_s.len;
                    buf[len] = '(';
                    len +%= 1;
                    const larger: bool = new_size > old_size;
                    @ptrCast(*[6]u8, buf[len..].ptr).* = (if (larger) about.red_s ++ "+" else about.green_s ++ "-").*;
                    len +%= 6;
                    mach.memcpy(buf[len..].ptr, diff_size_s.ptr, diff_size_s.len);
                    len +%= diff_size_s.len;
                    @ptrCast(*[4]u8, buf[len..].ptr).* = about.reset_s.*;
                    len +%= 4;
                    @ptrCast(*[5]u8, buf[len..].ptr).* = ") => ".*;
                    len +%= 5;
                    mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                    len +%= new_size_s.len;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = about.bytes_s.*;
                    len +%= 8;
                }
                mach.memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len +%= sec_s.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len +%= 3;
                @ptrCast(*[2]u8, buf[len..].ptr).* = "s\n".*;
                len +%= 2;
                @ptrCast(*[4]u8, buf[len..].ptr).* = about.reset_s.*;
                builtin.debug.logAlways(buf[0 .. len +% about.reset_s.len]);
            }
            fn simpleTimedNotice(target: *const Target, working_time: time.TimeSpec, task: types.Task, rc: u8) void {
                @setRuntimeSafety(false);
                const about_s: [:0]const u8 = switch (task) {
                    .format => about.format_s,
                    .archive => about.ar_s,
                    else => about.run_s,
                };
                const rc_s: []const u8 = builtin.fmt.ud64(rc).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(working_time.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(working_time.nsec).readAll();
                var buf: [32768]u8 = undefined;
                mach.memcpy(&buf, about_s.ptr, about_s.len);
                var len: u64 = about_s.len;
                mach.memcpy(buf[len..].ptr, target.name.ptr, target.name.len);
                len +%= target.name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                @ptrCast(*[3]u8, buf[len..].ptr).* = "rc=".*;
                len +%= 3;
                mach.memcpy(buf[len..].ptr, rc_s.ptr, rc_s.len);
                len +%= rc_s.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                mach.memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len +%= sec_s.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len +%= 3;
                @ptrCast(*[2]u8, buf[len..].ptr).* = "s\n".*;
                builtin.debug.logAlways(buf[0 .. len +% 2]);
            }
            fn writeAndWalk(target: *Target) void {
                var buf0: [1048576]u8 = undefined;
                var buf1: [32768]u8 = undefined;
                mach.memcpy(&buf0, target.name.ptr, target.name.len);
                builtin.debug.logAlways(buf0[0..writeAndWalkInternal(&buf0, target.name.len, &buf1, 0, target)]);
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, target: *Target, args: anytype) u64 {
                @setRuntimeSafety(false);
                var deps_idx: u64 = 0;
                var len: u64 = len0;
                buf0[len] = '\n';
                len +%= 1;
                while (deps_idx != target.deps_len) : (deps_idx +%= 1) {
                    const dep: Target.Dependency = target.deps[deps_idx];
                    if (dep.on_target == target) {
                        continue;
                    }
                    const is_last: bool = deps_idx == target.deps_len -% 1;
                    const is_only: bool = dep.on_target.deps_len == 0;
                    mach.memcpy(buf1 + len1, if (is_last) "  " else "| ", 2);
                    mach.memcpy(buf0 + len, buf1, len1 +% 2);
                    len +%= len1 +% 2;
                    @ptrCast(*[4]u8, buf0 + len).* = if (is_last) "\x08\x08`-".* else "\x08\x08|-".*;
                    len +%= 4;
                    @ptrCast(*[2]u8, buf0 + len).* = if (is_only) "> ".* else "+ ".*;
                    len +%= 2;
                    mach.memcpy(buf0 + len, dep.on_target.name.ptr, dep.on_target.name.len);
                    len +%= dep.on_target.name.len;
                    if (builder_spec.options.show_detailed_deps) {
                        var count: u64 = (args.name_max_width +% 4) -% (dep.on_target.name.len +% len1);
                        if (dep.on_target.hidden and args.show_root) {
                            mach.memset(buf0 + len, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0 + len, dep.on_target.root.ptr, dep.on_target.root.len);
                            len +%= dep.on_target.root.len;
                        }
                        if (dep.on_target.hidden and args.show_descr) {
                            count = args.root_max_width -% dep.on_target.root.len;
                            mach.memset(buf0 + len, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0 + len, dep.on_target.descr.ptr, dep.on_target.descr.len);
                            len +%= dep.on_target.descr.len;
                        }
                    }
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep.on_target, args);
                }
                return len;
            }
            fn dependencyMaxNameWidth(target: *const Target, width: u64) u64 {
                var len: u64 = target.name.len;
                for (target.deps[0..target.deps_len]) |dep| {
                    if (dep.on_target != target) {
                        len = @max(len, width +% dependencyMaxNameWidth(dep.on_target, width +% 2));
                    }
                }
                return len;
            }
            fn dependencyMaxRootWidth(target: *const Target) u64 {
                var len: u64 = target.root.len;
                for (target.deps[0..target.deps_len]) |dep| {
                    if (dep.on_target != target) {
                        len = @max(len, dependencyMaxRootWidth(dep.on_target));
                    }
                }
                return len;
            }
            pub fn builderCommandNotice(builder: *Builder, show_root: bool, show_descr: bool, show_deps: bool) void {
                @setRuntimeSafety(false);
                var buf0: [1024 * 1024]u8 = undefined;
                var buf1: [32768]u8 = undefined;
                var len: u64 = 0;
                var name_max_width: u64 = 0;
                var root_max_width: u64 = 0;
                for (builder.grps[0..builder.grps_len]) |group| {
                    if (group.hidden) {
                        continue;
                    }
                    for (group.trgs[0..group.trgs_len]) |target| {
                        name_max_width = @max(
                            name_max_width,
                            dependencyMaxNameWidth(target, 2),
                        );
                        if (show_root) {
                            root_max_width = @max(
                                root_max_width,
                                dependencyMaxRootWidth(target),
                            );
                        }
                    }
                }
                name_max_width +%= 4;
                root_max_width +%= 4;
                name_max_width &= ~@as(u64, 3);
                root_max_width &= ~@as(u64, 3);
                mach.memset(&buf1, ' ', 4);
                for (builder.grps[0..builder.grps_len]) |group| {
                    if (group.hidden) {
                        continue;
                    }
                    mach.memcpy(buf0[len..].ptr, group.name.ptr, group.name.len);
                    len +%= group.name.len;
                    @ptrCast(*[2]u8, buf0[len..].ptr).* = ":\n".*;
                    len +%= 2;
                    for (group.trgs[0..group.trgs_len]) |target| {
                        mach.memset(buf0[len..].ptr, ' ', 4);
                        len +%= 4;
                        mach.memcpy(buf0[len..].ptr, target.name.ptr, target.name.len);
                        len +%= target.name.len;
                        var count: u64 = name_max_width -% target.name.len;
                        if (show_root) {
                            mach.memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0[len..].ptr, target.root.ptr, target.root.len);
                            len +%= target.root.len;
                        }
                        if (show_descr) {
                            count = root_max_width -% target.root.len;
                            mach.memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0[len..].ptr, target.descr.ptr, target.descr.len);
                            len +%= target.descr.len;
                        }
                        if (show_deps) {
                            @ptrCast(*[4]u8, buf0[len..].ptr).* = about.faint_s.*;
                            len +%= about.faint_s.len;
                            len = writeAndWalkInternal(&buf0, len, &buf1, 8, target, &.{
                                .show_descr = show_descr,
                                .show_root = show_root,
                                .name_max_width = name_max_width,
                                .root_max_width = root_max_width,
                            });
                            @ptrCast(*[4]u8, buf0[len..].ptr).* = about.reset_s.*;
                            len +%= about.reset_s.len;
                        } else {
                            buf0[len] = '\n';
                            len +%= 1;
                        }
                    }
                }
                builtin.debug.write(buf0[0..len]);
            }
            inline fn writeAbout(buf: [*]u8, about_s: [:0]const u8) u64 {
                @setRuntimeSafety(false);
                var len: u64 = 0;
                if (about_s.ptr == about.error_s) {
                    @ptrCast(*@TypeOf(about.bold_s.*), buf + len).* = about.bold_s.*;
                    len +%= about.bold_s.len;
                } else if (about_s.ptr == about.note_s) {
                    @ptrCast(*@TypeOf(about.grey_s.*), buf + len).* = about.grey_s.*;
                    len +%= about.grey_s.len;
                }
                mach.memcpy(buf + len, about_s.ptr, about_s.len);
                len +%= about_s.len;
                @ptrCast(*[2]u8, buf + len).* = ": ".*;
                len +%= 2;
                @ptrCast(*@TypeOf(about.bold_s.*), buf + len).* = about.bold_s.*;
                return len +% about.bold_s.len;
            }
            fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(false);
                const err: *types.ErrorMessage = @ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(*types.SourceLocation, extra + err.src_loc);
                var len: u64 = about.bold_s.len;
                @ptrCast(*[4]u8, buf).* = about.bold_s.*;
                if (err.src_loc != 0) {
                    len +%= writeSourceLocation(
                        buf + len,
                        meta.manyToSlice(bytes + src.src_path),
                        src.line +% 1,
                        src.column +% 1,
                    );
                    @ptrCast(*[2]u8, buf + len).* = ": ".*;
                    len +%= 2;
                }
                return len;
            }
            fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, about_s: [:0]const u8) u64 {
                @setRuntimeSafety(false);
                const err: *types.ErrorMessage = @ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(*types.SourceLocation, extra + err.src_loc);
                const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
                var len: u64 = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
                const pos: u64 = len +% about_s.len -% about.trace_s.len -% 2;
                len +%= writeAbout(buf + len, about_s);
                len +%= writeMessage(buf + len, bytes, err.start, pos);
                if (err.src_loc == 0) {
                    if (err.count != 1)
                        len +%= writeTimes(buf + len, err.count);
                    for (0..err.notes_len) |idx|
                        len +%= writeError(buf + len, extra, bytes, notes[idx], about.note_s);
                } else {
                    if (err.count != 1)
                        len +%= writeTimes(buf + len, err.count);
                    if (src.src_line != 0)
                        len +%= writeCaret(buf + len, bytes, src);
                    for (0..err.notes_len) |idx|
                        len +%= writeError(buf + len, extra, bytes, notes[idx], about.note_s);
                    if (src.ref_len != 0)
                        len +%= writeTrace(buf + len, extra, bytes, err.src_loc, src.ref_len);
                }
                return len;
            }
            fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: u64, column: u64) u64 {
                @setRuntimeSafety(false);
                const line_s: []const u8 = builtin.fmt.ud64(line).readAll();
                const column_s: []const u8 = builtin.fmt.ud64(column).readAll();
                var len: u64 = 0;
                @ptrCast(*@TypeOf(about.trace_s.*), buf + len).* = about.trace_s.*;
                len +%= about.trace_s.len;
                mach.memcpy(buf + len, pathname.ptr, pathname.len);
                len +%= pathname.len;
                buf[len] = ':';
                len +%= 1;
                mach.memcpy(buf + len, line_s.ptr, line_s.len);
                len +%= line_s.len;
                buf[len] = ':';
                len +%= 1;
                mach.memcpy(buf + len, column_s.ptr, column_s.len);
                return len +% column_s.len;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(false);
                const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
                @ptrCast(*[4]u8, buf - 1).* = about.faint_s.*;
                var len: u64 = about.faint_s.len -% 1;
                @ptrCast(*[2]u8, buf + len).* = " (".*;
                len +%= 2;
                mach.memcpy(buf + len, count_s.ptr, count_s.len);
                len +%= count_s.len;
                mach.memcpy(buf + len, " times)", 7);
                len +%= 7;
                @ptrCast(*[5]u8, buf + len).* = about.new_s.*;
                return len +% 5;
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
                    mach.memcpy(buf, line.ptr, indent);
                    len +%= indent;
                    @ptrCast(*[about.bold_s.len]u8, buf + len).* = about.bold_s.*;
                    len +%= about.bold_s.len;
                    mach.memcpy(buf + len, line[indent..pos].ptr, before_caret);
                    len +%= before_caret;
                    @ptrCast(*[about.hi_red_s.len]u8, buf + len).* = about.hi_red_s.*;
                    len +%= about.hi_red_s.len;
                    buf[len] = line[pos];
                    len +%= 1;
                    pos = pos +% 1;
                    @ptrCast(*[about.bold_s.len]u8, buf + len).* = about.bold_s.*;
                    len +%= about.bold_s.len;
                    mach.memcpy(buf + len, line[pos .. pos + after_caret].ptr, after_caret);
                    len +%= after_caret;
                    buf[len] = '\n';
                    len +%= 1;
                } else {
                    mach.memcpy(buf, line.ptr, line.len);
                    len = line.len;
                    buf[len] = '\n';
                    len +%= 1;
                }
                mach.memset(buf + len, ' ', indent);
                len +%= indent;
                @ptrCast(*@TypeOf(about.tilde_s.*), buf + len).* = about.tilde_s.*;
                len +%= about.tilde_s.len;
                mach.memset(buf + len, '~', before_caret);
                len +%= before_caret;
                buf[len] = '^';
                len +%= 1;
                mach.memset(buf + len, '~', after_caret);
                len +%= after_caret;
                @ptrCast(*[5]u8, buf + len).* = about.new_s.*;
                return len +% about.new_s.len;
            }
            fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: u64, indent: u64) u64 {
                @setRuntimeSafety(false);
                var len: u64 = 0;
                var next: u64 = start;
                var idx: u64 = start;
                while (bytes[idx] != 0) : (idx +%= 1) {
                    if (bytes[idx] == '\n') {
                        const line: []u8 = bytes[next..idx];
                        mach.memcpy(buf + len, line.ptr, line.len);
                        len +%= line.len;
                        buf[len] = '\n';
                        len +%= 1;
                        mach.memset(buf + len, ' ', indent);
                        len +%= indent;
                        next = idx +% 1;
                    }
                }
                const line: []u8 = bytes[next..idx];
                mach.memcpy(buf + len, line.ptr, line.len);
                len +%= line.len;
                @ptrCast(*[5]u8, buf + len).* = about.new_s.*;
                return len +% about.new_s.len;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: u64, ref_len: u64) u64 {
                @setRuntimeSafety(false);
                var ref_idx: u64 = start +% types.SourceLocation.len;
                var idx: u64 = 0;
                var len: u64 = 0;
                @ptrCast(*@TypeOf(about.trace_s.*), buf + len).* = about.trace_s.*;
                len +%= about.trace_s.len;
                @ptrCast(*[15]u8, buf + len).* = "referenced by:\n".*;
                len +%= 15;
                while (idx != ref_len) : (idx +%= 1) {
                    const ref_trc: *types.ReferenceTrace = @ptrCast(*types.ReferenceTrace, extra + ref_idx);
                    if (ref_trc.src_loc != 0) {
                        const ref_src: *types.SourceLocation = @ptrCast(*types.SourceLocation, extra + ref_trc.src_loc);
                        const src_file: [:0]u8 = meta.manyToSlice(bytes + ref_src.src_path);
                        const decl_name: [:0]u8 = meta.manyToSlice(bytes + ref_trc.decl_name);
                        mach.memset(buf + len, ' ', 4);
                        len +%= 4;
                        mach.memcpy(buf + len, decl_name.ptr, decl_name.len);
                        len +%= decl_name.len;
                        @ptrCast(*[2]u8, buf + len).* = ": ".*;
                        len +%= 2;
                        len +%= writeSourceLocation(buf + len, src_file, ref_src.line +% 1, ref_src.column +% 1);
                        buf[len] = '\n';
                        len +%= 1;
                    }
                    ref_idx +%= types.ReferenceTrace.len;
                }
                @ptrCast(*[5]u8, buf + len).* = about.new_s.*;
                return len +% 5;
            }
            fn writeErrors(allocator: *Allocator, hdr: *types.Message.ErrorHeader) void {
                @setRuntimeSafety(false);
                const extra: [*]u32 = hdr.extra();
                const bytes: [*:0]u8 = hdr.bytes();
                var buf: [*]u8 = allocator.allocate(u8, 1024 * 1024).ptr;
                const list: types.ErrorMessageList = @ptrCast(*types.ErrorMessageList, extra).*;
                for ((extra + list.start)[0..list.len]) |err_msg_idx| {
                    var len: u64 = writeError(buf, extra, bytes, err_msg_idx, about.error_s);
                    builtin.debug.write(buf[0..len]);
                }
                builtin.debug.write(meta.manyToSlice(bytes + list.compile_log_text));
            }
        };
        fn writeRecord(builder: *Builder, name: [:0]const u8, record: types.Record) void {
            var buf: [4096]u8 = undefined;
            var len: u64 = 0;
            mach.memcpy(&buf, builder_spec.options.names.zig_stat_dir.ptr, builder_spec.options.names.zig_stat_dir.len);
            len +%= builder_spec.options.names.zig_stat_dir.len;
            buf[len] = '/';
            len +%= 1;
            mach.memcpy(buf[len..].ptr, name.ptr, name.len);
            len +%= name.len;
            buf[len] = 0;
            const fd: u64 = try meta.wrap(file.createAt(builder_spec.create2(), builder.dir_fd, buf[0..len :0], file.mode.regular));
            try meta.wrap(file.writeOne(builder_spec.write3(), fd, record));
            try meta.wrap(file.close(builder_spec.close(), fd));
        }
        fn writeEnv(env_fd: u64, zig_exe: []const u8, build_root: []const u8, cache_root: []const u8, global_cache_root: []const u8) void {
            var buf: [4096 *% 8]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                "pub const zig_exe: [:0]const u8 = \"",         "\";\npub const build_root: [:0]const u8 = \"",
                "\";\npub const cache_root: [:0]const u8 = \"", "\";\npub const global_cache_root: [:0]const u8 = \"",
            }, [_][]const u8{
                zig_exe, build_root, cache_root, global_cache_root,
            }) |decl, value| {
                mach.memcpy(buf[len..].ptr, decl.ptr, decl.len);
                len +%= decl.len;
                mach.memcpy(buf[len..].ptr, value.ptr, value.len);
                len +%= value.len;
            }
            @ptrCast(*[3]u8, buf[len..].ptr).* = "\";\n".*;
            len +%= 3;
            try meta.wrap(file.write(builder_spec.write(), env_fd, buf[0..len]));
        }
        fn fastLineCol(buf: [*]const u8, buf_len: u64, s_line: u32, s_col: u32) void {
            var i_idx: u32 = 0;
            var j_idx: u32 = 0;
            var k_idx: u32 = 0;
            while (i_idx != buf_len) : (i_idx +%= 1) {
                const lf: u1 = @boolToInt(buf[i_idx] == 0xA);
                j_idx = j_idx +% lf;
                k_idx = (k_idx * ~lf) +% ~lf;
                if (j_idx == s_line and
                    k_idx == s_col)
                {
                    j_idx = i_idx;
                    k_idx = i_idx;
                    while (j_idx != 0) : (j_idx -%= 1)
                        if (buf[j_idx] == 0xA) break;
                    while (k_idx != buf_len) : (k_idx +%= 1)
                        if (buf[k_idx] == 0xA) break;
                    break;
                }
            }
            builtin.debug.write(buf[j_idx..k_idx]);
        }
        fn strdup(allocator: *Allocator, values: []const u8) [:0]u8 {
            @setRuntimeSafety(false);
            var buf: [:0]u8 = @ptrCast([:0]u8, allocator.allocate(u8, values.len));
            mach.memcpy(buf.ptr, values.ptr, values.len);
            return buf;
        }
        fn strdup2(allocator: *Allocator, values: []const []const u8) [][:0]const u8 {
            @setRuntimeSafety(false);
            var buf: [][:0]u8 = @ptrCast([][:0]u8, allocator.allocate([:0]u8, values.len));
            var idx: u64 = 0;
            for (values) |value| {
                buf[idx] = strdup(allocator, value);
                idx +%= 1;
            }
        }
        fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
            @setRuntimeSafety(false);
            var len: u64 = 0;
            for (values) |value| len +%= value.len;
            const buf: [:0]u8 = @ptrCast([:0]u8, allocator.allocate(u8, len));
            var idx: u64 = 0;
            for (values) |value| {
                mach.memcpy(buf[idx..].ptr, value.ptr, value.len);
                idx +%= value.len;
            }
            return buf;
        }
        fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
            @setRuntimeSafety(false);
            var count: u64 = 0;
            for (args) |value| count +%= @boolToInt(value == 0);
            const ptrs: [][*:0]u8 = allocator.allocate([*:0]u8, count +% 1);
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
    };
    return Type;
}
const Spec = struct {
    const thread_map_options: mem.MapSpec.Options = .{
        .grows_down = true,
    };
    const pipe_options: file.MakePipeSpec.Options = .{
        .close_on_exec = false,
    };
    const create_truncate_options: file.CreateSpec.Options = .{
        .exclusive = false,
        .truncate = true,
    };
    const create_append_options: file.CreateSpec.Options = .{
        .exclusive = false,
        .append = true,
        .truncate = false,
    };
    fn clock(comptime builder_spec: BuilderSpec) time.ClockSpec {
        return .{ .errors = builder_spec.errors.clock };
    }
    fn sleep(comptime builder_spec: BuilderSpec) time.SleepSpec {
        return .{ .errors = builder_spec.errors.sleep };
    }
    fn path(comptime builder_spec: BuilderSpec) file.PathSpec {
        return .{ .errors = builder_spec.errors.path, .logging = builder_spec.logging.path };
    }
    fn mkdir(comptime builder_spec: BuilderSpec) file.MakeDirSpec {
        return .{ .errors = builder_spec.errors.mkdir, .logging = builder_spec.logging.mkdir };
    }
    fn write(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{ .errors = builder_spec.errors.write, .logging = builder_spec.logging.write };
    }
    fn write2(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{ .errors = builder_spec.errors.write, .logging = builder_spec.logging.write, .child = types.Message.ClientHeader };
    }
    fn write3(comptime builder_spec: BuilderSpec) file.WriteSpec {
        return .{ .errors = builder_spec.errors.write, .logging = builder_spec.logging.write, .child = types.Record };
    }
    fn read(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{ .errors = builder_spec.errors.read, .logging = builder_spec.logging.read, .return_type = u64 };
    }
    fn read2(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{ .errors = builder_spec.errors.read, .logging = builder_spec.logging.read, .return_type = u64 };
    }
    fn read3(comptime builder_spec: BuilderSpec) file.ReadSpec {
        return .{ .child = types.Message.ServerHeader, .errors = builder_spec.errors.read, .logging = builder_spec.logging.read, .return_type = void };
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
    fn fork(comptime builder_spec: BuilderSpec) proc.ForkSpec {
        return .{ .errors = builder_spec.errors.fork, .logging = builder_spec.logging.fork };
    }
    fn waitpid(comptime builder_spec: BuilderSpec) proc.WaitSpec {
        return .{ .errors = builder_spec.errors.waitpid, .logging = builder_spec.logging.waitpid, .return_type = void };
    }
    fn waitpid2(comptime builder_spec: BuilderSpec) proc.WaitSpec {
        return .{ .errors = builder_spec.errors.waitpid, .logging = builder_spec.logging.waitpid, .return_type = proc.Return };
    }
    fn mknod(comptime builder_spec: BuilderSpec) file.MakeNodeSpec {
        return .{ .errors = builder_spec.errors.mknod, .logging = builder_spec.logging.mknod };
    }
    fn dup3(comptime builder_spec: BuilderSpec) file.DuplicateSpec {
        return .{ .errors = builder_spec.errors.dup3, .logging = builder_spec.logging.dup3, .return_type = void };
    }
    fn poll(comptime builder_spec: BuilderSpec) file.PollSpec {
        return .{ .errors = builder_spec.errors.poll, .logging = builder_spec.logging.poll, .return_type = bool };
    }
    fn pipe(comptime builder_spec: BuilderSpec) file.MakePipeSpec {
        return .{ .errors = builder_spec.errors.pipe, .logging = builder_spec.logging.pipe, .options = pipe_options };
    }
    fn map(comptime builder_spec: BuilderSpec) mem.MapSpec {
        return .{ .errors = builder_spec.errors.map, .logging = builder_spec.logging.map, .options = thread_map_options };
    }
    fn create(comptime builder_spec: BuilderSpec) file.CreateSpec {
        return .{ .errors = builder_spec.errors.create, .logging = builder_spec.logging.create, .options = create_truncate_options };
    }
    fn create2(comptime builder_spec: BuilderSpec) file.CreateSpec {
        return .{ .errors = builder_spec.errors.create, .logging = builder_spec.logging.create, .options = create_append_options };
    }
    fn unlink(comptime builder_spec: BuilderSpec) file.UnlinkSpec {
        return .{ .errors = builder_spec.errors.unlink, .logging = builder_spec.logging.unlink };
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
