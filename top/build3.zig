const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");
const types = @import("./build/types.zig");
const safety: bool = false;
pub usingnamespace types;
pub const BuilderSpec = struct {
    /// Builder options
    options: Options = .{},
    /// Logging for system calls called by the builder.
    logging: Logging,
    /// Errors for system calls called by builder. This excludes clone, which
    /// must be implemented in assembly.
    errors: Errors,
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// Bytes allowed per thread arena (dynamic maximum)
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (static maximum)
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u64 = 2,
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
        /// Enables source location for change of state of targets.
        show_detailed_targets: bool = false,
        /// Enables logging for build job statistics.
        show_stats: bool = true,
        /// Notices will represent the depth of a dependency relative to toplevel by
        /// increasing indentation.
        show_dependency_depth: bool = false,
        /// Enables detail for target dependecy listings.
        show_detailed_deps: bool = true,
        /// Use `SimpleAllocator` instead of configured generic allocator.
        /// This will slightly speed compilation.
        prefer_simple_allocator: bool = true,
        /// Determines whether to use the Zig compiler server
        enable_caching: bool = true,
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
};
pub fn GenericBuilder(comptime builder_spec: BuilderSpec) type {
    const Type = struct {
        dir_fd: u64,
        args: [][*:0]u8,
        args_len: u64,
        vars: [][*:0]u8,
        grps: []*Group = &.{},
        grps_len: u64 = 0,
        trgs: []*Target = &.{},
        trgs_len: u64 = 0,
        const Builder = @This();
        pub var zig_exe: [:0]const u8 = undefined;
        pub var build_root: [:0]const u8 = undefined;
        pub var cache_root: [:0]const u8 = undefined;
        pub var global_cache_root: [:0]const u8 = undefined;
        pub const max_thread_count: u64 = builder_spec.options.max_thread_count;
        const max_arena_count: u64 = if (max_thread_count == 0) 4 else max_thread_count + 1;
        const stack_aligned_bytes: u64 = builder_spec.options.stack_aligned_bytes;
        const arena_aligned_bytes: u64 = builder_spec.options.arena_aligned_bytes;
        const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        const stack_up_addr: u64 = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: u64 = stack_up_addr;
        const arena_up_addr: u64 = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        pub const AddressSpace = mem.GenericRegularAddressSpace(.{
            .label = "arena",
            .errors = address_space_errors,
            .logging = builtin.zero(mem.AddressSpaceLogging),
            .idx_type = u64,
            .divisions = max_arena_count,
            .lb_addr = arena_lb_addr,
            .up_addr = arena_up_addr,
            .options = address_space_options,
        });
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "stack",
            .errors = address_space_errors,
            .logging = builtin.zero(mem.AddressSpaceLogging),
            .idx_type = AddressSpace.Index,
            .divisions = max_thread_count,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .options = thread_space_options,
        });
        pub const Allocator = if (builder_spec.options.prefer_simple_allocator)
            mem.SimpleAllocator
        else
            mem.GenericRtArenaAllocator(.{
                .logging = builtin.zero(mem.AllocatorLogging),
                .errors = allocator_errors,
                .AddressSpace = AddressSpace,
                .options = allocator_options,
            });
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
                target.spawnAllDeps(address_space, thread_space, &allocator, builder, task, depth);
                while (targetWait(target, task)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (target.task_lock.get(task) != .working) return;
                if (executeCommandInternal(builder, &allocator, target, depth, task)) {
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
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
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
                target.spawnAllDeps(address_space, thread_space, allocator, builder, task, depth);
                while (targetWait(target, task)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (target.task_lock.get(task) != .working) return;
                if (executeCommandInternal(builder, allocator, target, depth, task)) {
                    target.assertExchange(task, .working, .finished);
                } else {
                    target.assertExchange(task, .working, .failed);
                }
            }
        };
        pub const Target = struct {
            name: [:0]const u8,
            descr: [:0]const u8,
            paths: []types.Path,
            paths_len: u64,
            deps: []Dependency,
            deps_len: u64,
            args: [][*:0]u8,
            args_len: u64,
            task: types.Task,
            task_lock: types.Lock,
            task_cmd: TaskCommand,
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
                    try meta.wrap(impl.executeCommand(builder, address_space, thread_space, allocator, target, task, depth));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (mem.testAcquire(ThreadSpace, thread_space, arena_index)) {
                            return @call(.never_inline, impl.forwardToExecuteCloneThreaded, .{
                                builder, address_space, thread_space, target, task, arena_index, depth, ThreadSpace.high(arena_index) -% 4096,
                            });
                        }
                    }
                    try meta.wrap(impl.executeCommand(builder, address_space, thread_space, allocator, target, task, depth));
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
                if (target.exchange(task, .ready, .blocking)) {
                    try meta.wrap(target.acquireThread(address_space, thread_space, allocator, builder, task, 0));
                }
                while (builderWait(address_space, thread_space, builder)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
            fn spawnAllDeps(
                target: *Target,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                builder: *Builder,
                task: types.Task,
                depth: u64,
            ) void {
                for (target.deps[0..target.deps_len]) |dep| {
                    if (dep.on_target != target or dep.on_task != task) {
                        if (dep.on_target.exchange(dep.on_task, .ready, .blocking)) {
                            try meta.wrap(dep.on_target.acquireThread(address_space, thread_space, allocator, builder, dep.on_task, depth));
                        }
                    }
                }
            }
            inline fn createBinaryPath(target: *Target, allocator: *Allocator) types.Path {
                return .{ .absolute = build_root, .relative = binaryRelative(allocator, target.task_cmd.build) };
            }
            inline fn createArchivePath(target: *Target, allocator: *Allocator) types.Path {
                return .{ .absolute = build_root, .relative = archiveRelative(allocator, target.name) };
            }
            fn createAuxiliaryPath(target: *Target, allocator: *Allocator, kind: types.AuxOutputMode) types.Path {
                return .{ .absolute = build_root, .relative = auxiliaryRelative(target, allocator, kind) };
            }
            pub fn emitAuxiliary(target: *Target, allocator: *Allocator, kind: types.AuxOutputMode) void {
                const aux_path = .{ .yes = createAuxiliaryPath(target, allocator, kind) };
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
                target.addPath(allocator, dependency.task_cmd.build.emit_bin.?.yes.?);
            }
            pub fn dependOnArchive(target: *Target, allocator: *Allocator, dependency: *Target) void {
                target.addDependency(allocator, target.task, dependency, .archive, .finished);
                target.addPath(allocator, dependency.paths[0]);
            }
            fn exchange(target: *Target, task: types.Task, old_state: types.State, new_state: types.State) bool {
                const ret: bool = target.task_lock.atomicExchange(task, old_state, new_state);
                if (builtin.logging_general.Success or builder_spec.options.show_targets) {
                    if (ret) {
                        debug.exchangeNotice(target, task, old_state, new_state, sourceLocation(@src()));
                    } else {
                        debug.noExchangeNotice(target, debug.about.state_0_s, task, old_state, new_state, sourceLocation(@src()));
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
                        debug.exchangeNotice(target, task, old_state, new_state, sourceLocation(@src()));
                    }
                } else {
                    if (builtin.logging_general.Fault or builder_spec.options.show_targets) {
                        debug.noExchangeNotice(target, debug.about.state_1_s, task, old_state, new_state, sourceLocation(@src()));
                    }
                    builtin.proc.exitGroup(2);
                }
            }
            pub fn addPath(target: *Target, allocator: *Allocator, path: types.Path) void {
                @setRuntimeSafety(safety);
                if (target.paths_len == target.paths.len) {
                    target.paths = allocator.reallocate(types.Path, target.paths, (target.paths_len +% 1) *% 2);
                }
                target.paths[target.paths_len] = path;
                target.paths_len +%= 1;
            }
            fn addDependency(target: *Target, allocator: *Allocator, task: types.Task, on_target: *Target, on_task: types.Task, on_state: types.State) void {
                @setRuntimeSafety(safety);
                if (target.deps_len == target.deps.len) {
                    target.deps = allocator.reallocate(Dependency, target.deps, (target.deps_len +% 1) *% 2);
                }
                target.deps[target.deps_len] = .{
                    .task = task,
                    .on_target = on_target,
                    .on_task = on_task,
                    .on_state = on_state,
                };
                target.deps_len +%= 1;
            }
            pub fn addRunCommand(target: *Target, allocator: *Allocator) void {
                @setRuntimeSafety(safety);
                target.args = allocator.allocate([*:0]u8, 16);
                const name: []u8 = allocator.allocate(u8, 4097);
                name[4096] = 0;
                target.args[0] = name[0..4096 :0];
                builtin.assert(target.task_cmd.build.emit_bin.?.yes.?.formatWriteBuf(target.args[0]) != 0);
                target.args_len = 1;
                if (target.exchange(.run, .null, .ready)) {
                    target.addDependency(allocator, .run, target, .build, .finished);
                }
            }
            pub fn addRunArgument(target: *Target, allocator: *Allocator, arg: []const u8) void {
                @setRuntimeSafety(safety);
                if (target.args_len == 0) {
                    target.addRunCommand(allocator);
                } else if (target.args_len == target.args.len -% 1) {
                    target.args = allocator.reallocate([*:0]u8, target.args, (target.args_len +% 1) *% 2);
                }
                target.args[target.args_len] = strdup(allocator, arg).ptr;
                target.args_len +%= @boolToInt(arg.len != 0);
            }
        };
        pub const Group = struct {
            name: [:0]const u8,
            trgs: []*Target = &.{},
            trgs_len: u64 = 0,
            builder: *Builder,
            hidden: bool = false,
            pub fn addBuild(group: *Group, allocator: *Allocator, build_cmd: types.BuildCommand, name: [:0]const u8, root: [:0]const u8) !*Target {
                const ret: *Target = try group.addTarget(allocator, name);
                const cmd: *types.BuildCommand = allocator.create(types.BuildCommand);
                cmd.* = build_cmd;
                ret.name = name;
                ret.task = .build;
                ret.task_cmd = .{ .build = cmd };
                ret.addPath(allocator, .{
                    .absolute = build_root,
                    .relative = root,
                });
                ret.args_len = 0;
                if (builder_spec.options.enable_caching) {
                    cmd.listen = .@"-";
                }
                if (cmd.name == null) {
                    cmd.name = name;
                }
                if (cmd.main_pkg_path == null) {
                    cmd.main_pkg_path = build_root;
                }
                if (cmd.cache_root == null) {
                    cmd.cache_root = cache_root;
                }
                if (cmd.global_cache_root == null) {
                    cmd.global_cache_root = global_cache_root;
                }
                cmd.emit_bin = .{ .yes = .{
                    .absolute = build_root,
                    .relative = binaryRelative(allocator, cmd),
                } };
                if (cmd.kind == .exe) {
                    ret.addRunCommand(allocator);
                }
                ret.hidden = group.hidden;
                ret.assertExchange(.build, .null, .ready);
                return ret;
            }
            pub fn addBuildAnonymous(group: *Group, allocator: *Allocator, build_cmd: types.BuildCommand, root: [:0]const u8) !*Target {
                return group.addBuild(allocator, build_cmd, makeTargetName(allocator, root), root);
            }
            pub fn addFormat(group: *Group, allocator: *Allocator, format_cmd: types.FormatCommand, name: [:0]const u8, pathname: [:0]const u8) !*Target {
                const ret: *Target = try group.addTarget(allocator, name);
                const cmd: *types.FormatCommand = allocator.create(types.FormatCommand);
                cmd.* = format_cmd;
                ret.name = name;
                ret.addPath(allocator, .{ .absolute = build_root, .relative = pathname });
                ret.task = .format;
                ret.task_cmd = .{ .format = cmd };
                ret.hidden = group.hidden;
                ret.name = name;
                ret.assertExchange(.format, .null, .ready);
                return ret;
            }
            pub fn addArchive(group: *Group, allocator: *Allocator, archive_cmd: types.ArchiveCommand, name: [:0]const u8, deps: []const *Target) !*Target {
                const ret: *Target = try group.addTarget(allocator, name);
                const cmd: *types.ArchiveCommand = allocator.create(types.ArchiveCommand);
                cmd.* = archive_cmd;
                ret.name = name;
                ret.addPath(allocator, .{ .absolute = build_root, .relative = archiveRelative(allocator, name) });
                ret.task = .archive;
                ret.task_cmd = .{ .archive = cmd };
                for (deps) |dep| ret.dependOnObject(allocator, dep);
                ret.hidden = group.hidden;
                ret.assertExchange(.archive, .null, .ready);
                return ret;
            }
            pub fn addTarget(group: *Group, allocator: *Allocator, name: [:0]const u8) !*Target {
                @setRuntimeSafety(safety);
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = allocator.reallocate(*Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = allocator.create(Target);
                mach.memset(@ptrCast([*]u8, ret), 0, @sizeOf(Target));
                group.trgs[group.trgs_len] = ret;
                group.trgs_len +%= 1;
                ret.deps = allocator.allocate(Target.Dependency, 4);
                ret.paths = allocator.allocate(types.Path, 4);
                ret.name = name;
                return ret;
            }
            pub fn executeToplevel(
                group: *Group,
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                maybe_task: ?types.Task,
            ) !void {
                @setRuntimeSafety(safety);
                for (group.trgs[0..group.trgs_len]) |target| {
                    const task: types.Task = maybe_task orelse target.task;
                    if (target.exchange(task, .ready, .blocking)) {
                        try meta.wrap(target.acquireThread(address_space, thread_space, allocator, group.builder, task, 0));
                    }
                }
                while (builderWait(address_space, thread_space, group.builder)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
        };
        pub fn addTarget(builder: *Builder, allocator: *Allocator, name: [:0]const u8) !*Target {
            @setRuntimeSafety(safety);
            if (builder.trgs_len == builder.trgs.len) {
                builder.trgs = allocator.reallocate(*Target, builder.trgs, (builder.trgs_len +% 1) *% 2);
            }
            const ret: *Target = allocator.create(Target);
            mach.memset(@ptrCast([*]u8, ret), 0, @sizeOf(Target));
            builder.trgs[builder.trgs_len] = ret;
            builder.trgs_len +%= 1;
            ret.deps = allocator.allocate(Target.Dependency, 4);
            ret.paths = allocator.allocate(types.Path, 4);
            ret.name = name;
            return ret;
        }
        inline fn clientLoop(allocator: *Allocator, out: file.Pipe, working_time: *time.TimeSpec, ret: []u8, pid: u64) void {
            @setRuntimeSafety(safety);
            const header: *types.Message.ServerHeader = allocator.create(types.Message.ServerHeader);
            const save: Allocator.Save = allocator.save();
            var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
            while (try meta.wrap(file.pollOne(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                try meta.wrap(
                    file.readOne(read3(), out.read, header),
                );
                const msg: []align(4) u8 = allocator.allocateAligned(u8, header.bytes_len, 4);
                mach.memset(msg.ptr, 0, header.bytes_len);
                var len: u64 = 0;
                while (len != header.bytes_len) {
                    len +%= try meta.wrap(
                        file.read(read2(), out.read, msg[len..header.bytes_len]),
                    );
                }
                if (header.tag == .emit_bin_path) break {
                    ret[1] = msg[0];
                };
                if (header.tag == .error_bundle) break {
                    debug.writeErrors(allocator, .{ .msg = msg.ptr });
                    ret[1] = builder_spec.options.compiler_error_status;
                };
                fd.actual = .{};
                allocator.restore(save);
            }
            allocator.restore(save);
            const rc: proc.Return = try meta.wrap(
                proc.waitPid(waitpid(), .{ .pid = pid }),
            );
            ret[0] = proc.Status.exit(rc.status);
            working_time.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), working_time.*);
            try meta.wrap(file.close(close(), out.read));
        }
        fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, u8) {
            ts.* = try meta.wrap(time.get(clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(fork()));
            if (pid == 0) try meta.wrap(
                file.execPath(execve(), meta.manyToSlice(args[0]), args, builder.vars),
            );
            const ret: proc.Return = try meta.wrap(
                proc.waitPid(waitpid(), .{ .pid = pid }),
            );
            ts.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), ts.*);
            return proc.Status.exit(ret.status);
        }
        fn server(builder: *const Builder, allocator: *Builder.Allocator, args: [][*:0]u8, ts: *time.TimeSpec, ret: []u8) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, void) {
            const in: file.Pipe = try meta.wrap(file.makePipe(pipe()));
            const out: file.Pipe = try meta.wrap(file.makePipe(pipe()));
            ts.* = try meta.wrap(time.get(clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(fork()));
            if (pid == 0) {
                try meta.wrap(openChild(in, out));
                try meta.wrap(
                    file.execPath(execve(), zig_exe, args, builder.vars),
                );
            }
            try meta.wrap(openParent(in, out));
            try meta.wrap(
                file.write(write2(), in.write, &update_exit_message),
            );
            try meta.wrap(
                file.close(close(), in.write),
            );
            try meta.wrap(
                clientLoop(allocator, out, ts, ret, pid),
            );
        }
        fn buildWrite(allocator: *Allocator, cmd: *types.BuildCommand, paths: []const types.Path) [:0]u8 {
            @setRuntimeSafety(safety);
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, paths);
            const buf: []u8 = allocator.allocate(u8, max_len);
            const len: u64 = cmd.formatWriteBuf(zig_exe, paths, buf.ptr);
            return buf[0..len :0];
        }
        fn archiveWrite(allocator: *Allocator, cmd: *types.ArchiveCommand, paths: []const types.Path) [:0]u8 {
            @setRuntimeSafety(safety);
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, paths);
            const buf: []u8 = allocator.allocate(u8, max_len);
            const len: u64 = cmd.formatWriteBuf(zig_exe, paths, buf.ptr);
            return buf[0..len :0];
        }
        fn formatWrite(allocator: *Allocator, cmd: *types.FormatCommand, root_path: types.Path) [:0]u8 {
            @setRuntimeSafety(safety);
            const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, root_path);
            const buf: []u8 = allocator.allocate(u8, max_len);
            const len: u64 = cmd.formatWriteBuf(zig_exe, root_path, buf.ptr);
            return buf[0..len :0];
        }
        fn runWrite(builder: *Builder, allocator: *Allocator, target: *Target) [][*:0]u8 {
            @setRuntimeSafety(safety);
            for (builder.args[builder.args_len..]) |run_arg| {
                target.addRunArgument(allocator, meta.manyToSlice(run_arg));
            }
            if (target.args_len == 0) {
                target.addRunCommand(allocator);
            }
            return target.args[0..target.args_len];
        }
        fn executeCommandInternal(builder: *Builder, allocator: *Allocator, target: *Target, depth: u64, task: types.Task) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
        }, bool) {
            @setRuntimeSafety(safety);
            var working_time: time.TimeSpec = undefined;
            var ret: []u8 = allocator.allocate(u8, ret_len);
            ret[0] = 0;
            ret[1] = 0;
            var old_size: u64 = 0;
            var new_size: u64 = 0;
            const args: [][*:0]u8 = try meta.wrap(switch (task) {
                .format => makeArgPtrs(allocator, try meta.wrap(
                    formatWrite(allocator, target.task_cmd.format, target.paths[0]),
                )),
                .archive => makeArgPtrs(allocator, try meta.wrap(
                    archiveWrite(allocator, target.task_cmd.archive, target.paths[0..target.paths_len]),
                )),
                .build => makeArgPtrs(allocator, try meta.wrap(
                    buildWrite(allocator, target.task_cmd.build, target.paths[0..target.paths_len]),
                )),
                else => runWrite(builder, allocator, target),
            });
            if (task == .build) {
                const out_path: [:0]const u8 = binaryRelative(allocator, target.task_cmd.build);
                old_size = builder.getFileSize(out_path);
                if (builder_spec.options.enable_caching) {
                    try meta.wrap(
                        builder.server(allocator, args, &working_time, ret),
                    );
                } else {
                    ret[0] = try meta.wrap(
                        builder.system(args, &working_time),
                    );
                }
                new_size = builder.getFileSize(out_path);
            } else {
                ret[0] = try meta.wrap(
                    builder.system(args, &working_time),
                );
            }
            switch (task) {
                .format, .run => {
                    debug.simpleTimedNotice(target, depth, working_time, task, ret);
                },
                .build, .archive => {
                    debug.buildNotice(target, depth, working_time, old_size, new_size, ret);
                },
                else => unreachable,
            }
            return status(ret);
        }
        pub fn init(args: [][*:0]u8, vars: [][*:0]u8) sys.ErrorUnion(.{
            .throw = builder_spec.errors.mkdir.throw ++
                builder_spec.errors.path.throw ++ builder_spec.errors.close.throw ++ builder_spec.errors.create.throw,
            .abort = builder_spec.errors.mkdir.abort ++
                builder_spec.errors.path.abort ++ builder_spec.errors.close.abort ++ builder_spec.errors.create.abort,
        }, Builder) {
            @setRuntimeSafety(safety);
            zig_exe = meta.manyToSlice(args[1]);
            build_root = meta.manyToSlice(args[2]);
            cache_root = meta.manyToSlice(args[3]);
            global_cache_root = meta.manyToSlice(args[4]);
            const build_root_fd: u64 = try meta.wrap(file.path(path1(), build_root));
            if (!thread_space_options.require_map) {
                mem.map(map(), stack_lb_addr, stack_up_addr -% stack_lb_addr);
            }
            try meta.wrap(
                file.makeDirAt(mkdir(), build_root_fd, builder_spec.options.names.zig_out_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(mkdir(), build_root_fd, builder_spec.options.names.zig_stat_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(mkdir(), build_root_fd, zig_out_exe_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(mkdir(), build_root_fd, zig_out_aux_dir, file.mode.directory),
            );
            try meta.wrap(
                file.makeDirAt(mkdir(), build_root_fd, zig_out_lib_dir, file.mode.directory),
            );
            const cache_root_fd: u64 = try meta.wrap(
                file.path(path1(), cache_root),
            );
            const env_fd: u64 = try meta.wrap(
                file.createAt(create(), cache_root_fd, env_basename, file.mode.regular),
            );
            writeEnv(env_fd);
            try meta.wrap(
                file.close(close(), env_fd),
            );
            try meta.wrap(
                file.close(close(), cache_root_fd),
            );
            return .{ .args = args, .args_len = args.len, .vars = vars, .dir_fd = build_root_fd };
        }
        pub fn addGroup(builder: *Builder, allocator: *Allocator, name: [:0]const u8) !*Group {
            @setRuntimeSafety(safety);
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
            @setRuntimeSafety(safety);
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
        fn depTest(target: *Target, task: types.Task, state: types.State) bool {
            for (target.deps[0..target.deps_len]) |*dep| {
                const t_st: types.State = dep.on_target.task_lock.get(dep.on_task);
                if (dep.on_target == target and
                    dep.on_task == task)
                {
                    continue;
                }
                if (t_st == state) {
                    return true;
                }
            }
            return false;
        }
        fn depExchange(target: *Target, task: types.Task, from: types.State, to: types.State) void {
            for (target.deps[0..target.deps_len]) |*dep| {
                const t_st: types.State = dep.on_target.task_lock.get(dep.on_task);
                _ = t_st;
                if (dep.on_target == target and
                    dep.on_task == task)
                {
                    continue;
                }
                _ = dep.on_target.exchange(dep.on_task, from, to);
            }
        }
        // In order to leave all must be cancelled, failed, or finished
        fn targetWait(target: *Target, task: types.Task) bool {
            @setRuntimeSafety(safety);
            const s_st: types.State = target.task_lock.get(task);
            if (s_st == .blocking) {
                if (depTest(target, task, .failed) or
                    depTest(target, task, .cancelled))
                {
                    target.assertExchange(task, .blocking, .failed);
                    return true;
                }
                if (depTest(target, task, .working) or
                    depTest(target, task, .blocking))
                {
                    return true;
                }
                target.assertExchange(task, .blocking, .working);
                return false;
            }
            if (s_st == .failed) {
                depExchange(target, task, .ready, .cancelled);
                depExchange(target, task, .blocking, .failed);
                return depTest(target, task, .working);
            }
            return false;
        }

        fn groupWait(group: *Group, maybe_task: ?types.Task) bool {
            @setRuntimeSafety(safety);
            for (group.trgs[0..group.trgs_len]) |target| {
                const task: types.Task = maybe_task orelse target.task;
                if (target.task_lock.get(task) == .working) {
                    return true;
                }
            }
            return false;
        }
        fn builderWait(address_space: *Builder.AddressSpace, thread_space: *Builder.ThreadSpace, builder: *Builder) bool {
            @setRuntimeSafety(safety);
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
        fn status(ret: []u8) bool {
            if (builder_spec.options.enable_caching) {
                if (ret[1] == builder_spec.options.compiler_error_status) {
                    return false;
                }
                if (ret[1] == builder_spec.options.compiler_cache_hit_status or
                    ret[1] == builder_spec.options.compiler_expected_status)
                {
                    return ret[0] == builder_spec.options.system_expected_status;
                }
            }
            return ret[0] == builder_spec.options.system_expected_status;
        }
        fn openChild(in: file.Pipe, out: file.Pipe) sys.ErrorUnion(.{
            .throw = builder_spec.errors.close.throw ++ builder_spec.errors.dup3.throw,
            .abort = builder_spec.errors.close.abort ++ builder_spec.errors.dup3.abort,
        }, void) {
            try meta.wrap(
                file.close(close(), in.write),
            );
            try meta.wrap(
                file.close(close(), out.read),
            );
            try meta.wrap(
                file.duplicateTo(dup3(), in.read, 0),
            );
            try meta.wrap(
                file.duplicateTo(dup3(), out.write, 1),
            );
        }
        fn openParent(in: file.Pipe, out: file.Pipe) sys.ErrorUnion(builder_spec.errors.close, void) {
            try meta.wrap(
                file.close(close(), in.read),
            );
            try meta.wrap(
                file.close(close(), out.write),
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
        const create_truncate_options: file.CreateSpec.Options = .{
            .exclusive = false,
            .truncate = true,
        };
        const create_append_options: file.CreateSpec.Options = .{
            .exclusive = false,
            .append = true,
            .truncate = false,
        };
        const thread_map_options: mem.MapSpec.Options = .{
            .grows_down = true,
        };
        const pipe_options: file.MakePipeSpec.Options = .{
            .close_on_exec = false,
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
        pub const allocator_errors: mem.AllocatorErrors = .{
            .map = .{},
            .remap = .{},
            .unmap = .{},
        };
        pub const address_space_errors: mem.AddressSpaceErrors = .{
            .release = .ignore,
            .acquire = .ignore,
            .map = .{},
            .unmap = .{},
        };
        const zig_out_exe_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.exe_out_dir;
        const zig_out_lib_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.lib_out_dir;
        const zig_out_aux_dir: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.aux_out_dir;
        const env_basename: [:0]const u8 = builder_spec.options.names.env ++ builder_spec.options.extensions.zig;
        const null_arg: [*:0]u8 = builtin.zero([*:0]u8);
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
                .green_s = "\x1b[92;1m",
                .red_s = "\x1b[91;1m",
                .new_s = "\x1b[0m\n",
                .reset_s = "\x1b[0m",
                .bold_s = "\x1b[1m",
                .faint_s = "\x1b[2m",
                .grey_s = "\x1b[0;38;5;250;1m",
                .trace_s = "\x1b[38;5;247m",
                .hi_green_s = "\x1b[38;5;46m",
                .hi_red_s = "\x1b[38;5;196m",
            };
            const fancy_hl_line: bool = false;
            fn writeFromTo(buf: [*]u8, old: types.State, new: types.State) u64 {
                @setRuntimeSafety(safety);
                @ptrCast(*[7]u8, buf).* = ", from=".*;
                var len: u64 = 7;
                mach.memcpy(buf + len, @tagName(old).ptr, @tagName(old).len);
                len +%= @tagName(old).len;
                @ptrCast(*[5]u8, buf + len).* = ", to=".*;
                len +%= 5;
                mach.memcpy(buf + len, @tagName(new).ptr, @tagName(new).len);
                len +%= @tagName(new).len;
                return len;
            }
            fn writeExchangeTask(buf: [*]u8, target: *Target, about_s: []const u8, task: types.Task) u64 {
                @setRuntimeSafety(safety);
                mach.memcpy(buf, about_s.ptr, about_s.len);
                var len: u64 = about_s.len;
                mach.memcpy(buf + len, target.name.ptr, target.name.len);
                len +%= target.name.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf + len, @tagName(task).ptr, @tagName(task).len);
                len +%= @tagName(task).len;
                return len;
            }
            fn exchangeNotice(target: *Target, task: types.Task, old: types.State, new: types.State, src: SourceLocation) void {
                @setRuntimeSafety(safety);
                var buf: [32768]u8 = undefined;
                var len: u64 = writeExchangeTask(&buf, target, about.state_0_s, task);
                len +%= writeFromTo(buf[len..].ptr, old, new);
                if (builder_spec.options.show_detailed_targets) {
                    @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                    len +%= 2;
                    len +%= writeSourceLocation(buf[len..].ptr, src.file, src.line, src.column);
                }
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn noExchangeNotice(target: *Target, about_s: [:0]const u8, task: types.Task, old: types.State, new: types.State, src: SourceLocation) void {
                @setRuntimeSafety(safety);
                var buf: [32768]u8 = undefined;
                var len: u64 = writeExchangeTask(&buf, target, about_s, task);
                @ptrCast(*[5]u8, buf[len..].ptr).* = ", state=".*;
                len +%= 5;
                const actual: types.State = target.task_lock.get(target.task);
                mach.memcpy(buf[len..].ptr, @tagName(actual).ptr, @tagName(actual).len);
                len +%= @tagName(actual).len;
                len +%= writeFromTo(buf[len..].ptr, old, new);
                if (builder_spec.options.show_detailed_targets) {
                    @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                    len +%= 2;
                    len +%= writeSourceLocation(buf[len..].ptr, src.file, src.line, src.column);
                }
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn buildNotice(target: *const Target, depth: u64, working_time: time.TimeSpec, old_size: u64, new_size: u64, ret: []u8) void {
                @setRuntimeSafety(safety);
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
                if (builder_spec.options.show_dependency_depth) {
                    mach.memset(buf[len..].ptr, ' ', depth *% 4);
                    len +%= depth *% 4;
                }
                mach.memcpy(buf[len..].ptr, target.name.ptr, target.name.len);
                len +%= target.name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                const mode: builtin.Mode = target.task_cmd.build.mode orelse .Debug;
                mach.memcpy(buf[len..].ptr, @tagName(mode).ptr, @tagName(mode).len);
                len +%= @tagName(mode).len;
                @ptrCast(*[7]u8, buf[len..].ptr).* = ", exit=".*;
                len +%= 7;
                if (builder_spec.options.enable_caching) {
                    const res: UpdateAnswer = @intToEnum(UpdateAnswer, ret[1]);
                    const msg_s: []const u8 = @tagName(res);
                    buf[len] = '[';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, msg_s.ptr, msg_s.len);
                    len +%= msg_s.len;
                    buf[len] = ',';
                    len +%= 1;
                    const exit_s: []const u8 = builtin.fmt.ud64(ret[0]).readAll();
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                    buf[len] = ']';
                    len +%= 1;
                } else {
                    const exit_s: []const u8 = builtin.fmt.ud64(ret[0]).readAll();
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                }
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
                    @ptrCast(*[8]u8, buf[len..].ptr).* = (if (larger) about.red_s ++ "+" else about.green_s ++ "-").*;
                    len +%= 8;
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
                builtin.debug.write(buf[0 .. len +% about.reset_s.len]);
            }
            fn simpleTimedNotice(target: *const Target, depth: u64, working_time: time.TimeSpec, task: types.Task, ret: []u8) void {
                @setRuntimeSafety(safety);
                const about_s: [:0]const u8 = switch (task) {
                    .format => about.format_s,
                    .archive => about.ar_s,
                    else => about.run_s,
                };
                const sec_s: []const u8 = builtin.fmt.ud64(working_time.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(working_time.nsec).readAll();
                var buf: [32768]u8 = undefined;
                mach.memcpy(&buf, about_s.ptr, about_s.len);
                var len: u64 = about_s.len;
                if (builder_spec.options.show_dependency_depth) {
                    mach.memset(buf[len..].ptr, ' ', depth *% 4);
                    len +%= depth *% 4;
                }
                mach.memcpy(buf[len..].ptr, target.name.ptr, target.name.len);
                len +%= target.name.len;
                @ptrCast(*[5]u8, buf[len..].ptr).* = ", rc=".*;
                len +%= 5;
                const exit_s: []const u8 = builtin.fmt.ud64(ret[0]).readAll();
                mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                len +%= exit_s.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = about.next_s.*;
                len +%= 2;
                mach.memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len +%= sec_s.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len +%= 3;
                @ptrCast(*[2]u8, buf[len..].ptr).* = "s\n".*;
                builtin.debug.write(buf[0 .. len +% 2]);
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, target: *Target, args: anytype) u64 {
                @setRuntimeSafety(safety);
                var deps_idx: u64 = 0;
                var len: u64 = len0;
                buf0[len] = '\n';
                len +%= 1;
                while (deps_idx != target.deps_len) : (deps_idx +%= 1) {
                    const dep: Target.Dependency = target.deps[deps_idx];
                    const dep_root: [:0]const u8 = dep.on_target.paths[0].relative.?;
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
                            mach.memcpy(buf0 + len, dep_root.ptr, dep_root.len);
                            len +%= dep_root.len;
                        }
                        if (dep.on_target.hidden and args.show_descr) {
                            count = args.root_max_width -% dep_root.len;
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
                @setRuntimeSafety(safety);
                var len: u64 = target.name.len;
                for (target.deps[0..target.deps_len]) |dep| {
                    if (dep.on_target != target) {
                        len = @max(len, width +% dependencyMaxNameWidth(dep.on_target, width +% 2));
                    }
                }
                return len;
            }
            fn dependencyMaxRootWidth(target: *const Target) u64 {
                @setRuntimeSafety(safety);
                var len: u64 = target.paths[0].relative.?.len;
                for (target.deps[0..target.deps_len]) |dep| {
                    if (dep.on_target != target) {
                        len = @max(len, dependencyMaxRootWidth(dep.on_target));
                    }
                }
                return len;
            }
            pub fn builderCommandNotice(builder: *Builder, show_root: bool, show_descr: bool, show_deps: bool) void {
                @setRuntimeSafety(safety);
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
                        const root: [:0]const u8 = target.paths[0].relative.?;
                        mach.memset(buf0[len..].ptr, ' ', 4);
                        len +%= 4;
                        mach.memcpy(buf0[len..].ptr, target.name.ptr, target.name.len);
                        len +%= target.name.len;
                        var count: u64 = name_max_width -% target.name.len;
                        if (show_root) {
                            mach.memset(buf0[len..].ptr, ' ', count);
                            len +%= count;
                            mach.memcpy(buf0[len..].ptr, root.ptr, root.len);
                            len +%= root.len;
                        }
                        if (show_descr) {
                            count = root_max_width -% root.len;
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
                @setRuntimeSafety(safety);
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
            inline fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(safety);
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
                @setRuntimeSafety(safety);
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
                @setRuntimeSafety(safety);
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
                @setRuntimeSafety(safety);
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
                @setRuntimeSafety(safety);
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
                @ptrCast(*@TypeOf(about.hi_green_s.*), buf + len).* = about.hi_green_s.*;
                len +%= about.hi_green_s.len;
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
                @setRuntimeSafety(safety);
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
                @setRuntimeSafety(safety);
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
            fn writeErrors(allocator: *Allocator, ptrs: packed union { msg: [*]align(4) u8, idx: [*]u32, str: [*:0]u8 }) void {
                @setRuntimeSafety(safety);
                const extra: [*]u32 = ptrs.idx + 2;
                const bytes: [*:0]u8 = ptrs.str + 8 + (ptrs.idx[0] *% 4);
                var buf: [*]u8 = allocator.allocate(u8, 1024 * 1024).ptr;
                for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
                    var len: u64 = writeError(buf, extra, bytes, err_msg_idx, about.error_s);
                    builtin.debug.write(buf[0..len]);
                }
                builtin.debug.write(meta.manyToSlice(bytes + extra[2]));
            }
        };
        fn writeRecord(builder: *Builder, name: [:0]const u8, record: types.Record) void {
            @setRuntimeSafety(safety);
            var buf: [4096]u8 = undefined;
            var len: u64 = 0;
            mach.memcpy(&buf, builder_spec.options.names.zig_stat_dir.ptr, builder_spec.options.names.zig_stat_dir.len);
            len +%= builder_spec.options.names.zig_stat_dir.len;
            buf[len] = '/';
            len +%= 1;
            mach.memcpy(buf[len..].ptr, name.ptr, name.len);
            len +%= name.len;
            buf[len] = 0;
            const fd: u64 = try meta.wrap(file.createAt(create2(), builder.dir_fd, buf[0..len :0], file.mode.regular));
            try meta.wrap(file.writeOne(write3(), fd, record));
            try meta.wrap(file.close(close(), fd));
        }
        fn writeEnv(env_fd: u64) void {
            @setRuntimeSafety(safety);
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
            try meta.wrap(file.write(write(), env_fd, buf[0..len]));
        }
        fn fastLineCol(buf: [*]const u8, buf_len: u64, s_line: u32, s_col: u32) void {
            @setRuntimeSafety(safety);
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
            @setRuntimeSafety(safety);
            var buf: [:0]u8 = @ptrCast([:0]u8, allocator.allocate(u8, values.len +% 1));
            mach.memcpy(buf.ptr, values.ptr, values.len);
            buf[values.len] = 0;
            return buf[0..values.len :0];
        }
        fn strdup2(allocator: *Allocator, values: []const []const u8) [][:0]const u8 {
            @setRuntimeSafety(safety);
            var buf: [][:0]u8 = @ptrCast([][:0]u8, allocator.allocate([:0]u8, values.len +% 1));
            var idx: u64 = 0;
            for (values) |value| {
                buf[idx] = strdup(allocator, value);
                idx +%= 1;
            }
        }
        fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
            @setRuntimeSafety(safety);
            var len: u64 = 0;
            for (values) |value| len +%= value.len;
            const buf: []u8 = allocator.allocate(u8, len +% 1);
            var idx: u64 = 0;
            for (values) |value| {
                mach.memcpy(buf[idx..].ptr, value.ptr, value.len);
                idx +%= value.len;
            }
            buf[len] = 0;
            return buf.ptr[0..len :0];
        }
        fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
            @setRuntimeSafety(safety);
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
        fn makeTargetName(allocator: *Allocator, root: [:0]const u8) [:0]const u8 {
            @setRuntimeSafety(safety);
            const buf: [*]u8 = allocator.allocate(u8, root.len +% 1).ptr;
            mach.memcpy(buf, root.ptr, root.len);
            buf[root.len] = 0;
            var idx: u64 = 0;
            while (idx != root.len and buf[idx] != 0x2e) : (idx +%= 1) {
                buf[idx] -%= @boolToInt(buf[idx] == 0x2f);
            }
            buf[idx] = 0;
            return buf[0..idx :0];
        }
        pub fn check(allocator: *Allocator, builder: *Builder) void {
            @setRuntimeSafety(safety);
            var trgs_len: u64 = 0;
            for (builder.grps[0..builder.grps_len]) |group| {
                trgs_len +%= group.trgs_len;
            }
            var trgs: []*Target = allocator.allocate(*Target, trgs_len);
            var trgs_idx: u64 = 0;
            for (builder.grps[0..builder.grps_len]) |grp| {
                for (grp.trgs[0..grp.trgs_len]) |trg| {
                    trgs[trgs_idx] = trg;
                    trgs_idx +%= 1;
                }
            }
            trgs_idx = 0;
            for (builder.grps[0..builder.grps_len], 0..) |grp, grp_idx| {
                while (trgs_idx != trgs.len) : (trgs_idx +%= 1) {
                    if (mach.testEqualMany8(trgs[trgs_idx].name, grp.name)) {
                        builtin.debug.write(builtin.fmt.ud64(grp_idx).readAll());
                        builtin.debug.write(" and ");
                        builtin.debug.write(builtin.fmt.ud64(trgs_idx).readAll());
                        builtin.debug.write(":");
                        builtin.debug.write(grp.name);
                        builtin.debug.write("\n");
                    }
                }
            }
            var l_idx: usize = 0;
            while (l_idx != trgs.len) : (l_idx +%= 1) {
                var r_idx: usize = l_idx;
                while (r_idx != trgs.len) : (r_idx +%= 1) {
                    if (l_idx != r_idx) {
                        if (mach.testEqualMany8(trgs[l_idx].name, trgs[r_idx].name)) {
                            builtin.debug.write(builtin.fmt.ud64(l_idx).readAll());
                            builtin.debug.write(" and ");
                            builtin.debug.write(builtin.fmt.ud64(r_idx).readAll());
                            builtin.debug.write(":");
                            builtin.debug.write(trgs[l_idx].name);
                            builtin.debug.write("\n");
                        }
                    }
                }
            }
            allocator.deallocate(*Target, trgs);
        }
        const ret_len: u64 = if (builder_spec.options.enable_caching) 2 else 1;
        fn clock() time.ClockSpec {
            return .{ .errors = builder_spec.errors.clock };
        }
        fn sleep() time.SleepSpec {
            return .{ .errors = builder_spec.errors.sleep };
        }
        fn path1() file.PathSpec {
            return .{
                .errors = builder_spec.errors.path,
                .logging = builder_spec.logging.path,
            };
        }
        fn mkdir() file.MakeDirSpec {
            return .{
                .errors = builder_spec.errors.mkdir,
                .logging = builder_spec.logging.mkdir,
            };
        }
        fn write() file.WriteSpec {
            return .{
                .errors = builder_spec.errors.write,
                .logging = builder_spec.logging.write,
            };
        }
        fn write2() file.WriteSpec {
            return .{
                .errors = builder_spec.errors.write,
                .logging = builder_spec.logging.write,
                .child = types.Message.ClientHeader,
            };
        }
        fn write3() file.WriteSpec {
            return .{
                .errors = builder_spec.errors.write,
                .logging = builder_spec.logging.write,
                .child = types.Record,
            };
        }
        fn read() file.ReadSpec {
            return .{
                .errors = builder_spec.errors.read,
                .logging = builder_spec.logging.read,
                .return_type = u64,
            };
        }
        fn read2() file.ReadSpec {
            return .{
                .errors = builder_spec.errors.read,
                .logging = builder_spec.logging.read,
                .return_type = u64,
            };
        }
        fn read3() file.ReadSpec {
            return .{
                .child = types.Message.ServerHeader,
                .errors = builder_spec.errors.read,
                .logging = builder_spec.logging.read,
                .return_type = void,
            };
        }
        fn close() file.CloseSpec {
            return .{
                .errors = builder_spec.errors.close,
                .logging = builder_spec.logging.close,
            };
        }
        fn unmap() mem.UnmapSpec {
            return .{
                .errors = builder_spec.errors.unmap,
                .logging = builder_spec.logging.unmap,
            };
        }
        fn stat() file.StatusSpec {
            return .{
                .errors = builder_spec.errors.stat,
                .logging = builder_spec.logging.stat,
            };
        }
        fn fork() proc.ForkSpec {
            return .{
                .errors = builder_spec.errors.fork,
                .logging = builder_spec.logging.fork,
            };
        }
        fn waitpid() proc.WaitSpec {
            return .{
                .errors = builder_spec.errors.waitpid,
                .logging = builder_spec.logging.waitpid,
                .return_type = proc.Return,
            };
        }
        fn mknod() file.MakeNodeSpec {
            return .{
                .errors = builder_spec.errors.mknod,
                .logging = builder_spec.logging.mknod,
            };
        }
        fn dup3() file.DuplicateSpec {
            return .{
                .errors = builder_spec.errors.dup3,
                .logging = builder_spec.logging.dup3,
                .return_type = void,
            };
        }
        fn poll() file.PollSpec {
            return .{
                .errors = builder_spec.errors.poll,
                .logging = builder_spec.logging.poll,
                .return_type = bool,
            };
        }
        fn pipe() file.MakePipeSpec {
            return .{
                .errors = builder_spec.errors.pipe,
                .logging = builder_spec.logging.pipe,
                .options = pipe_options,
            };
        }
        fn map() mem.MapSpec {
            return .{
                .errors = builder_spec.errors.map,
                .logging = builder_spec.logging.map,
                .options = thread_map_options,
            };
        }
        fn create() file.CreateSpec {
            return .{
                .errors = builder_spec.errors.create,
                .logging = builder_spec.logging.create,
                .options = create_truncate_options,
            };
        }
        fn create2() file.CreateSpec {
            return .{
                .errors = builder_spec.errors.create,
                .logging = builder_spec.logging.create,
                .options = create_append_options,
            };
        }
        fn unlink() file.UnlinkSpec {
            return .{
                .errors = builder_spec.errors.unlink,
                .logging = builder_spec.logging.unlink,
            };
        }
        fn execve() file.ExecuteSpec {
            return .{
                .errors = builder_spec.errors.execve,
                .logging = builder_spec.logging.execve,
                .args_type = [][*:0]u8,
                .vars_type = [][*:0]u8,
            };
        }
        const UpdateAnswer = enum(u8) {
            updated = builder_spec.options.compiler_expected_status,
            cached = builder_spec.options.compiler_cache_hit_status,
            failed = builder_spec.options.compiler_error_status,
        };
        const SourceLocation = if (builder_spec.options.show_detailed_targets) builtin.SourceLocation else void;
        inline fn sourceLocation(comptime src: builtin.SourceLocation) SourceLocation {
            if (builder_spec.options.show_detailed_targets) {
                return src;
            }
        }
    };
    return Type;
}
