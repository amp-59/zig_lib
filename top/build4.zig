const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const tracer = @import("./tracer.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
const virtual = @import("./virtual.zig");
const types = @import("./build/types.zig");
const build = @This();
pub usingnamespace types;
pub const BuilderSpec = struct {
    /// Builder options
    options: Options = .{},
    /// Logging for system calls called by the builder.
    logging: Logging = .{},
    /// Errors for system calls called by builder. This excludes `clone3`, which
    /// must be implemented in assembly.
    errors: Errors = .{},
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// Bytes allowed per thread arena (dynamic maximum)
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (static maximum)
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u64 = 16,
        /// Lowest allocated byte address for thread stacks. This field and the
        /// two previous fields derive the arena lowest allocated byte address,
        /// as this is the first unallocated byte address of the thread space.
        stack_lb_addr: u64 = 0x700000000000,
        /// This value is compared with return codes to determine whether a
        /// system or compile command succeeded.
        system_expected_status: u8 = 0,
        /// A compile job ended normally.
        compiler_expected_status: u8 = 0,
        /// A compile job ended in a cache hit.
        compiler_cache_hit_status: u8 = 1,
        /// A compile job ended in an error.
        compiler_error_status: u8 = 2,
        /// Assert no command line exceeds this length in bytes, making
        /// buildLength/formatLength unnecessary.
        max_cmdline_len: ?u64 = 65536,
        /// Assert no command line exceeds this number of individual arguments.
        max_cmdline_args: ?u64 = 1024,
        /// Time slept in nanoseconds between dependency scans.
        sleep_nanoseconds: u64 = 50000,
        /// Time in milliseconds allowed per build node.
        timeout_milliseconds: u64 = 1000 * 60 * 60 * 24,
        /// Enables logging for build job statistics.
        show_stats: bool = true,
        /// Enables detail for node dependecy listings.
        show_detailed_deps: bool = false,
        /// Include arena/thread index in task summaries and change of state
        /// notices.
        show_arena_index: bool = true,
        /// Enable runtime safety.
        enable_safety: bool = false,
        /// Require build runner compile DWARF parser and stack trace writers.
        enable_builder_stack_traces: bool = false,
        /// Nodes with this name prefix are hidden in pre.
        hide_based_on_name_prefix: ?u8 = '_',
        /// Nodes with hidden parent/group nodes are also hidden
        hide_based_on_group: bool = true,
        /// Never list special nodes among or allow explicit building.
        hide_special: bool = true,
        /// Disable all features related to default initialisation of nodes. TODO
        never_pre: bool = false,
        /// Disable all features related to automatic updating of nodes. TODO
        never_post: bool = false,
        /// Add run task for all executable build outputs
        add_run_to_executables: bool = true,
        /// Enable stack traces in runtime errors for executables where mode is
        /// Debug with debugging symbols included
        add_debug_stack_traces: bool = true,
        /// Pass --main-pkg-path=<build_root> for all build command.
        set_main_pkg_path_to_build_root: bool = true,
        names: struct {
            /// Name of the toplevel 'builder' node.
            toplevel_node: [:0]const u8 = "toplevel",
            /// Name of the special command used to list available commands.
            toplevel_list_command: [:0]const u8 = "list",
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
            /// Optional pathname to root source used to compile tracer object.
            tracer_root: ?[:0]const u8 = null,
        } = .{},
        special: struct {
            /// Defines compile commands for stack tracer object
            tracer: ?types.BuildCommand = .{ .kind = .obj, .mode = .ReleaseFast, .strip = true },
        } = .{},
        extensions: struct {
            /// Extension for Zig source files.
            zig: [:0]const u8 = ".zig",
            /// Extension for C header source files.
            h: [:0]const u8 = ".h",
            /// Extension for shared object files.
            lib: [:0]const u8 = ".so",
            /// Extension for archives.
            ar: [:0]const u8 = ".a",
            /// Extension for object files.
            obj: [:0]const u8 = ".o",
            /// Extension for assembly source files.
            @"asm": [:0]const u8 = ".s",
            /// Extension for LLVM bitcode files.
            llvm_bc: [:0]const u8 = ".bc",
            /// Extension for LLVM intermediate representation files.
            llvm_ir: [:0]const u8 = ".ll",
            /// Extension for JSON files.
            analysis: [:0]const u8 = ".json",
            /// Extension for documentation files.
            docs: [:0]const u8 = ".html",
        } = .{},
        init_len: struct {
            /// Initial size of all nodes' `paths` buffer.
            paths: u64 = 2,
            /// Initial size of worker nodes' `deps` buffer.
            deps: u64 = 1,
            /// Initial size of toplevel and group nodes' `nodes` buffers.
            nodes: u64 = 1,
            /// Initial size of group nodes `args` buffer.
            args: u64 = 4,
            /// Initial size of toplevel nodes `fds` buffer.
            fds: u64 = 1,
        } = .{},
    };
    pub const Logging = packed struct {
        /// Report exchanges on task lock state:
        ///     Attempt => When resulting in no change of state.
        ///     Success => When resulting in change of state.
        ///     Fault   => When the change of state results in any abort.
        state: builtin.Logging.AttemptSuccessFault = .{},
        /// Report completion of tasks with summary of results:
        ///     Attempt => When the task was unable to complete due to a dependency.
        ///     Success => When the task completes without any errors.
        ///     Error   => When the task completes with errors.
        stats: builtin.Logging.SuccessError = .{},
        /// Report `open` Acquire and Error.
        open: builtin.Logging.AcquireError = .{},
        /// Report `close` Release and Error.
        close: builtin.Logging.ReleaseError = .{},
        /// Report `create` Acquire and Error.
        create: builtin.Logging.AcquireError = .{},
        /// Report `dup3` Success and Error.
        dup3: builtin.Logging.SuccessError = .{},
        /// Report `execve` Success and Error.
        execve: builtin.Logging.AttemptError = .{},
        /// Report `fork` Attempt and Error.
        fork: builtin.Logging.SuccessError = .{},
        /// Report `map` Success and Error.
        map: builtin.Logging.AcquireError = .{},
        /// Report `mkdir` Success and Error.
        mkdir: builtin.Logging.SuccessError = .{},
        /// Report `mknod` Success and Error.
        mknod: builtin.Logging.SuccessError = .{},
        /// Report `path` Success and Error.
        path: builtin.Logging.AcquireError = .{},
        /// Report `pipe` Success and Error.
        pipe: builtin.Logging.AcquireError = .{},
        /// Report `waitpid` Success and Error.
        waitpid: builtin.Logging.SuccessError = .{},
        /// Report `read` Success and Error.
        read: builtin.Logging.SuccessError = .{},
        /// Report `unmap` Release and Error.
        unmap: builtin.Logging.ReleaseError = .{},
        /// Report `write` Success and Error.
        write: builtin.Logging.SuccessError = .{},
        /// Report `stat` Success and Error.
        stat: builtin.Logging.SuccessError = .{},
        /// Report `poll` Success and Error.
        poll: builtin.Logging.AttemptSuccessError = .{},
        /// Report `link` Success and Error.
        link: builtin.Logging.SuccessError = .{},
        /// Report `unlink` Success and Error.
        unlink: builtin.Logging.SuccessError = .{},
    };
    pub const Errors = struct {
        /// Error values for `open` system function.
        open: sys.ErrorPolicy = .{},
        /// Error values for `close` system function.
        close: sys.ErrorPolicy = .{},
        /// Error values for `create` system function.
        create: sys.ErrorPolicy = .{},
        /// Error values for `dup3` system function.
        dup3: sys.ErrorPolicy = .{},
        /// Error values for `execve` system function.
        execve: sys.ErrorPolicy = .{},
        /// Error values for `fork` system function.
        fork: sys.ErrorPolicy = .{},
        /// Error values for `map` system function.
        map: sys.ErrorPolicy = .{},
        /// Error values for `mkdir` system function.
        mkdir: sys.ErrorPolicy = .{},
        /// Error values for `mknod` system function.
        mknod: sys.ErrorPolicy = .{},
        /// Error values for `path` system function.
        path: sys.ErrorPolicy = .{},
        /// Error values for `pipe` system function.
        pipe: sys.ErrorPolicy = .{},
        /// Error values for `waitpid` system function.
        waitpid: sys.ErrorPolicy = .{},
        /// Error values for `read` system function.
        read: sys.ErrorPolicy = .{},
        /// Error values for `unmap` system function.
        unmap: sys.ErrorPolicy = .{},
        /// Error values for `write` system function.
        write: sys.ErrorPolicy = .{},
        /// Error values for `stat` system function.
        stat: sys.ErrorPolicy = .{},
        /// Error values for `poll` system function.
        poll: sys.ErrorPolicy = .{},
        /// Error values for `sleep` system function.
        sleep: sys.ErrorPolicy = .{},
        /// Error values for `clock` system function.
        clock: sys.ErrorPolicy = .{},
        /// Error values for `link` system function.
        link: sys.ErrorPolicy = .{},
        /// Error values for `unlink` system function.
        unlink: sys.ErrorPolicy = .{},
    };
};
pub fn GenericNode(comptime builder_spec: BuilderSpec) type {
    const Type = struct {
        name: [:0]u8,
        descr: [:0]const u8,
        args: [*][*:0]u8,
        args_max_len: u64,
        args_len: u64,
        paths: [*]types.Path,
        paths_max_len: u64,
        paths_len: u64,
        nodes: [*]*Node,
        nodes_max_len: u64,
        nodes_len: u64,
        deps: [*]Dependency,
        deps_max_len: u64,
        deps_len: u64,
        fds: [*]u32,
        fds_max_len: u64,
        fds_len: u64,
        kind: types.NodeKind,
        task: types.Task,
        task_lock: types.Lock,
        task_info: TaskInfo,
        options: packed struct {
            is_hidden: bool = false,
            is_special: bool = false,
            have_init: bool = false,
            have_update: bool = false,
        },
        const Node = @This();
        const GlobalState = struct {
            pub var args: [][*:0]u8 = undefined;
            pub var vars: [][*:0]u8 = undefined;
            pub var euid: u16 = undefined;
            pub var egid: u16 = undefined;
            pub var tracer: ?*Node = null;
        };
        pub usingnamespace GlobalState;
        pub const specification: BuilderSpec = builder_spec;
        pub const max_thread_count: u64 = builder_spec.options.max_thread_count;
        const max_arena_count: u64 = if (max_thread_count == 0) 4 else max_thread_count + 1;
        pub const stack_aligned_bytes: u64 = builder_spec.options.stack_aligned_bytes;
        const arena_aligned_bytes: u64 = builder_spec.options.arena_aligned_bytes;
        const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        const stack_up_addr: u64 = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: u64 = stack_up_addr;
        const arena_up_addr: u64 = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        const ret_len: u64 = 2;
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
        pub const Allocator = mem.SimpleAllocator;
        const OtherAllocator = mem.GenericRtArenaAllocator(.{
            .logging = builtin.zero(mem.AllocatorLogging),
            .errors = allocator_errors,
            .AddressSpace = AddressSpace,
            .options = allocator_options,
        });
        pub const Dependency = struct {
            task: types.Task,
            on_node: *Node,
            on_task: types.Task,
            on_state: types.State,
        };
        pub const TaskInfo = packed union {
            build: *types.BuildCommand,
            format: *types.FormatCommand,
            archive: *types.ArchiveCommand,
        };
        fn addPath(node: *Node, allocator: *Allocator) *types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(types.Path);
            const addr_buf: *u64 = @ptrCast(*u64, &node.paths);
            const ret: *types.Path = @intToPtr(*types.Path, allocator.addGeneric(size_of, builder_spec.options.init_len.paths, addr_buf, &node.paths_max_len, node.paths_len));
            node.paths_len +%= 1;
            return ret;
        }
        fn addNode(node: *Node, allocator: *Allocator) **Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(*Node);
            const addr_buf: *u64 = @ptrCast(*u64, &node.nodes);
            const ret: **Node = @intToPtr(**Node, allocator.addGeneric(size_of, builder_spec.options.init_len.nodes, addr_buf, &node.nodes_max_len, node.nodes_len));
            node.nodes_len +%= 1;
            return ret;
        }
        fn addDep(node: *Node, allocator: *Allocator) *Dependency {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(Dependency);
            const addr_buf: *u64 = @ptrCast(*u64, &node.deps);
            const ret: *Dependency = @intToPtr(*Dependency, allocator.addGeneric(size_of, builder_spec.options.init_len.deps, addr_buf, &node.deps_max_len, node.deps_len));
            node.deps_len +%= 1;
            return ret;
        }
        fn addArg(node: *Node, allocator: *Allocator) *[*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf([*:0]u8);
            const addr_buf: *u64 = @ptrCast(*u64, &node.args);
            const ret: *[*:0]u8 = @intToPtr(*[*:0]u8, allocator.addGeneric(size_of, builder_spec.options.init_len.args, addr_buf, &node.args_max_len, node.args_len));
            node.args_len +%= 1;
            return ret;
        }
        fn addFd(node: *Node, allocator: *Allocator, fd: u64) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(u32);
            const addr_buf: *u64 = @ptrCast(*u64, &node.fds);
            const ret: *u32 = @intToPtr(*u32, allocator.addGeneric(size_of, builder_spec.options.init_len.fds, addr_buf, &node.fds_max_len, node.fds_len));
            node.fds_len +%= 1;
            ret.* = @intCast(u32, fd);
        }
        pub fn addRunArg(node: *Node, allocator: *Allocator, arg: []const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (@ptrToInt(arg.ptr) <= arena_up_addr and
                @ptrToInt(arg.ptr) >= arena_lb_addr)
            {
                node.addArg(allocator).* = @ptrCast([*:0]u8, @constCast(arg.ptr));
            } else {
                node.addArg(allocator).* = duplicate(allocator, arg);
            }
        }
        pub fn addToplevelArgs(node: *Node, allocator: *Allocator) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for ([_][*:0]u8{
                GlobalState.args[1], GlobalState.args[2],
                GlobalState.args[3], GlobalState.args[4],
            }) |arg| {
                node.addArg(allocator).* = arg;
            }
        }
        fn makeRootDirectory(build_root_fd: u64, name: [:0]const u8) void {
            var st: file.Status = undefined;
            var rc: u64 = sys.call_noexcept(.mkdirat, u64, .{ build_root_fd, @ptrToInt(name.ptr), @bitCast(u16, file.mode.directory) });
            if (rc == 0) {
                return;
            }
            rc = sys.call_noexcept(.newfstatat, u64, .{ build_root_fd, @ptrToInt(name.ptr), @ptrToInt(&st), 0 });
            if (rc != 0) {
                builtin.proc.exitFault(name, 2);
            }
            if (st.mode.kind != .directory) {
                builtin.proc.exitFault(name, 2);
            }
        }
        const maybe_hide: bool =
            builder_spec.options.hide_based_on_name_prefix != null or
            builder_spec.options.hide_based_on_group;
        fn maybeHide(toplevel: *Node, node: *Node) void {
            if (builder_spec.options.hide_based_on_name_prefix) |prefix| {
                node.options.is_hidden = prefix == node.name[0];
                return;
            }
            if (builder_spec.options.hide_based_on_group) {
                node.options.is_hidden = toplevel.options.is_hidden;
                return;
            }
        }
        pub fn initSpecialNodes(allocator: *Allocator, toplevel: *Node) void {
            if (builder_spec.options.special.tracer) |build_cmd| {
                const special: *Node = try toplevel.addBuild(allocator, build_cmd, "tracer", paths.tracer_root);
                special.options.is_special = true;
                GlobalState.tracer = special;
            }
        }
        pub fn cacheRoot(toplevel: *Node) [:0]const u8 {
            return toplevel.paths[0].names[0];
        }
        pub fn globalCacheRoot(toplevel: *Node) [:0]const u8 {
            return toplevel.paths[1].names[0];
        }
        /// Initialize a toplevel node.
        pub fn init(allocator: *Allocator, args: [][*:0]u8, vars: [][*:0]u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!thread_space_options.require_map) {
                mem.map(map(), stack_lb_addr, stack_aligned_bytes * max_thread_count);
            }
            GlobalState.euid = sys.call_noexcept(.geteuid, u16, .{});
            GlobalState.egid = sys.call_noexcept(.getegid, u16, .{});
            GlobalState.args = args;
            GlobalState.vars = vars;
            var ret: *Node = allocator.create(Node);
            mem.zero(Node, ret);
            ret.addPath(allocator).addName(allocator).* = mach.manyToSlice80(GlobalState.args[2]);
            ret.addPath(allocator).addName(allocator).* = mach.manyToSlice80(GlobalState.args[3]);
            ret.name = duplicate(allocator, builder_spec.options.names.toplevel_node);
            ret.addFd(allocator, try meta.wrap(file.path(path1(), ret.paths[0].names[0])));
            ret.kind = .group;
            ret.task = .any;
            ret.args = Node.args.ptr;
            ret.args_max_len = Node.args.len;
            ret.args_len = Node.args.len;
            makeRootDirectory(ret.fds[0], builder_spec.options.names.zig_out_dir);
            makeRootDirectory(ret.fds[0], paths.zig_out_exe_dir);
            makeRootDirectory(ret.fds[0], paths.zig_out_lib_dir);
            makeRootDirectory(ret.fds[0], paths.zig_out_aux_dir);
            makeRootDirectory(ret.fds[0], builder_spec.options.names.zig_stat_dir);
            writeEnv(ret.cacheRoot(), ret.globalCacheRoot());
            return ret;
        }
        /// Initialize a new group command
        pub fn addGroup(toplevel: *Node, allocator: *Allocator, name: []const u8) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = allocator.create(Node);
            toplevel.addNode(allocator).* = ret;
            ret.paths = toplevel.paths;
            ret.kind = .group;
            ret.task = .any;
            ret.name = duplicate(allocator, name);
            initializeCommand(allocator, toplevel, ret);
            return ret;
        }
        /// Initialize a new `zig fmt` command.
        pub fn addFormat(toplevel: *Node, allocator: *Allocator, format_cmd: types.FormatCommand, name: []const u8, pathname: []const u8) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const main_pkg_path: [:0]const u8 = toplevel.paths[0].names[0];
            const ret: *Node = allocator.create(Node);
            toplevel.addNode(allocator).* = ret;
            ret.kind = .worker;
            ret.task = .format;
            ret.task_info = .{ .format = allocator.create(types.FormatCommand) };
            ret.name = duplicate(allocator, name);
            const target_path: *types.Path = ret.addPath(allocator);
            if (pathname[0] != '/') {
                target_path.addName(allocator).* = main_pkg_path;
            }
            target_path.addName(allocator).* = main_pkg_path;
            target_path.addName(allocator).* = duplicate(allocator, pathname);
            ret.task_info.format.* = format_cmd;
            initializeCommand(allocator, toplevel, ret);
            return ret;
        }
        /// Initialize a new `zig ar` command.
        pub fn addArchive(toplevel: *Node, allocator: *Allocator, archive_cmd: types.ArchiveCommand, name: []const u8, deps: []const *Node) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = allocator.create(Node);
            toplevel.addNode(allocator).* = ret;
            ret.kind = .worker;
            ret.task = .archive;
            ret.task_info = .{ .archive = allocator.create(types.ArchiveCommand) };
            ret.name = duplicate(allocator, name);
            const archive_path: *types.Path = ret.addPath(allocator);
            archive_path.addName(allocator).* = toplevel.paths[0].names[0];
            archive_path.addName(allocator).* = archiveRelative(allocator, name);
            ret.task_info.archive.* = archive_cmd;
            for (deps) |dep| {
                ret.dependOnObject(allocator, dep);
            }
            initializeCommand(allocator, toplevel, ret);
            return ret;
        }
        pub fn addBuild(toplevel: *Node, allocator: *Allocator, build_cmd: types.BuildCommand, name: []const u8, root: []const u8) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const main_pkg_path: [:0]const u8 = toplevel.paths[0].names[0];
            const ret: *Node = allocator.create(Node);
            toplevel.addNode(allocator).* = ret;
            ret.kind = .worker;
            ret.task = .build;
            ret.task_info = .{ .build = allocator.create(types.BuildCommand) };
            ret.name = duplicate(allocator, name);
            const binary_path: *types.Path = ret.addPath(allocator);
            const root_path: *types.Path = ret.addPath(allocator);
            binary_path.addName(allocator).* = main_pkg_path;
            binary_path.addName(allocator).* = binaryRelative(allocator, ret.name, build_cmd.kind);
            if (root[0] != '/') {
                root_path.addName(allocator).* = main_pkg_path;
            }
            root_path.addName(allocator).* = duplicate(allocator, root);
            ret.task_info.build.* = build_cmd;
            initializeCommand(allocator, toplevel, ret);
            return ret;
        }
        fn initializeCommand(allocator: *Allocator, toplevel: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.options.have_init = true;
            if (maybe_hide) {
                maybeHide(toplevel, node);
            }
            if (node.kind == .worker) {
                if (node.task == .build) {
                    node.task_info.build.listen = .@"-";
                    if (builder_spec.options.set_main_pkg_path_to_build_root) {
                        node.task_info.build.main_pkg_path = toplevel.paths[0].names[0];
                    }
                    node.task_lock = obj_lock;
                    if (node.task_info.build.kind == .exe and
                        builder_spec.options.add_run_to_executables)
                    {
                        node.task_lock = exe_lock;
                        node.dependOnSelfExe(allocator);
                    }
                }
                if (node.task == .run) {
                    node.task_lock = run_lock;
                }
                if (node.task == .archive) {
                    node.task_lock = archive_lock;
                }
            }
            if (node.kind == .group) {
                node.task_lock = omni_lock;
            }
        }
        fn updateCommand(allocator: *Allocator, _: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.options.have_update = true;
            if (node.kind == .worker and
                node.task == .build and
                node.task_info.build.kind == .exe)
            {
                const build_cmd: *types.BuildCommand = node.task_info.build;
                const mode: builtin.Mode = build_cmd.mode orelse .Debug;
                const strip: bool = build_cmd.strip orelse (mode != .ReleaseSmall);
                if (builder_spec.options.add_debug_stack_traces) {
                    if (!strip) {
                        if (GlobalState.tracer) |g| {
                            node.dependOnObject(allocator, g);
                        }
                    }
                }
            }
        }
        pub fn updateCommands(allocator: *Allocator, toplevel: *Node, node: *Node) void {
            if (node.options.have_update) {
                return;
            }
            updateCommand(allocator, toplevel, node);
            for (node.nodes[0..node.nodes_len]) |sub| {
                updateCommands(allocator, toplevel, sub);
            }
            for (node.deps[0..node.deps_len]) |dep| {
                updateCommands(allocator, toplevel, dep.on_node);
            }
        }
        pub fn addBuildAnon(toplevel: *Node, allocator: *Allocator, build_cmd: types.BuildCommand, root: [:0]const u8) !*Node {
            return toplevel.addBuild(allocator, build_cmd, makeCommandName(allocator, root), root);
        }
        pub fn dependOn(node: *Node, allocator: *Allocator, on_node: *Node, on_task: ?types.Task) void {
            node.addDep(allocator).* = .{ .task = node.task, .on_node = on_node, .on_task = on_task orelse on_node.task, .on_state = .finished };
        }
        pub fn dependOnObject(node: *Node, allocator: *Allocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.paths[0];
            node.addDep(allocator).* = .{ .task = node.task, .on_node = on_node, .on_task = .build, .on_state = .finished };
        }
        pub fn dependOnArchive(node: *Node, allocator: *Allocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.paths[0];
            node.addDep(allocator).* = .{ .task = node.task, .on_node = on_node, .on_task = .archive, .on_state = .finished };
        }
        inline fn dependOnSelfExe(node: *Node, allocator: *Allocator) void {
            node.addArg(allocator).* = node.paths[0].concatenate(allocator);
            node.addDep(allocator).* = .{ .task = .run, .on_node = node, .on_task = .build, .on_state = .finished };
        }
        pub const impl = struct {
            inline fn install(src_pathname: [:0]const u8, dest_pathname: [:0]const u8) void {
                file.unlink(unlink(), dest_pathname);
                file.link(link(), src_pathname, dest_pathname);
            }
            fn clientLoop(allocator: *Allocator, out: file.Pipe, ret: []u8, dest_pathname: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const header: *types.Message.ServerHeader = allocator.create(types.Message.ServerHeader);
                const save: Allocator.Save = allocator.save();
                var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
                while (try meta.wrap(file.pollOne(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                    try meta.wrap(
                        file.readOne(read3(), out.read, header),
                    );
                    const ptrs: MessagePtrs = .{
                        .msg = @intToPtr([*]align(4) u8, allocator.allocateRaw(header.bytes_len, 4)),
                    };
                    mach.memset(ptrs.msg, 0, header.bytes_len);
                    var len: u64 = 0;
                    while (len != header.bytes_len) {
                        len +%= try meta.wrap(
                            file.read(read2(), out.read, ptrs.msg[len..header.bytes_len]),
                        );
                    }
                    if (header.tag == .emit_bin_path) break {
                        ret[1] = ptrs.msg[0];
                        install(mach.manyToSlice80(ptrs.str + 1), dest_pathname);
                    };
                    if (header.tag == .error_bundle) break {
                        ret[1] = builder_spec.options.compiler_error_status;
                        debug.writeErrors(allocator, ptrs);
                    };
                    fd.actual = .{};
                    allocator.restore(save);
                }
                allocator.restore(save);
            }
            fn system(args: [][*:0]u8, ts: *time.TimeSpec) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, u8) {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                ts.* = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) try meta.wrap(
                    file.execPath(execve(), mach.manyToSlice80(args[0]), args, GlobalState.vars),
                );
                const ret: proc.Return = try meta.wrap(
                    proc.waitPid(waitpid(), .{ .pid = pid }),
                );
                ts.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), ts.*);
                return proc.Status.exit(ret.status);
            }
            fn server(allocator: *Allocator, args: [][*:0]u8, ts: *time.TimeSpec, ret: []u8, dest_pathname: [:0]const u8) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const in: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                const out: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                ts.* = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(openChild(in, out));
                    try meta.wrap(
                        file.execPath(execve(), mach.manyToSlice80(GlobalState.args[1]), args, GlobalState.vars),
                    );
                }
                try meta.wrap(openParent(in, out));
                try meta.wrap(
                    file.write(write2(), in.write, &update_exit_message),
                );
                try meta.wrap(
                    clientLoop(allocator, out, ret, dest_pathname),
                );
                const rc: proc.Return = try meta.wrap(
                    proc.waitPid(waitpid(), .{ .pid = pid }),
                );
                ret[0] = proc.Status.exit(rc.status);
                ts.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), ts.*);
                try meta.wrap(
                    file.close(close(), in.write),
                );
                try meta.wrap(file.close(close(), out.read));
            }
            fn buildWrite(allocator: *Allocator, cmd: *types.BuildCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), obj_paths);
                const buf: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), obj_paths, buf);
                return buf[0..len :0];
            }
            fn archiveWrite(allocator: *Allocator, cmd: *types.ArchiveCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), obj_paths);
                const buf: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), obj_paths, buf);
                return buf[0..len :0];
            }
            fn formatWrite(allocator: *Allocator, cmd: *types.FormatCommand, root_path: types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), root_path);
                const buf: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), root_path, buf);
                return buf[0..len :0];
            }
            fn runWrite(allocator: *Allocator, node: *Node, args: [][*:0]u8) [][*:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                for (args) |run_arg| node.addArg(allocator).* = run_arg;
                return node.args[0..node.args_len];
            }
            fn executeCommandInternal(toplevel: *const Node, allocator: *Allocator, node: *Node, task: types.Task, arena_index: u64) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, bool) {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ts: time.TimeSpec = undefined;
                var st: file.Status = undefined;
                var ret: [2]u8 = undefined;
                var old_size: u64 = 0;
                var new_size: u64 = 0;
                const args: [][*:0]u8 = try meta.wrap(switch (task) {
                    .format => makeArgPtrs(allocator, try meta.wrap(
                        formatWrite(allocator, node.task_info.format, node.paths[0]),
                    )),
                    .archive => makeArgPtrs(allocator, try meta.wrap(
                        archiveWrite(allocator, node.task_info.archive, node.paths[0..node.paths_len]),
                    )),
                    .build => makeArgPtrs(allocator, try meta.wrap(
                        buildWrite(allocator, node.task_info.build, node.paths[1..node.paths_len]),
                    )),
                    else => runWrite(allocator, node, GlobalState.args[toplevel.args_len..toplevel.args_max_len]),
                });
                switch (task) {
                    .build, .archive => {
                        const out_path: [:0]const u8 = node.paths[0].names[1];
                        old_size = sys.call_noexcept(.newfstatat, u64, .{
                            toplevel.fds[0], @ptrToInt(out_path.ptr), @ptrToInt(&st), 0,
                        });
                        old_size = if (old_size == 0) st.size else 0;
                        if (task == .build) {
                            try meta.wrap(
                                impl.server(allocator, args, &ts, &ret, out_path),
                            );
                        } else {
                            ret[0] = try meta.wrap(
                                impl.system(args, &ts),
                            );
                        }
                        new_size = sys.call_noexcept(.newfstatat, u64, .{
                            toplevel.fds[0], @ptrToInt(out_path.ptr), @ptrToInt(&st), 0,
                        });
                        new_size = if (new_size == 0) st.size else 0;
                    },
                    else => ret[0] = try meta.wrap(impl.system(args, &ts)),
                }
                if (builder_spec.options.show_stats) {
                    debug.taskNotice(node, task, arena_index, ts, old_size, new_size, &ret);
                }
                return status(&ret);
            }
            fn spawnDeps(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                toplevel: *const Node,
                node: *const Node,
                task: types.Task,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                for (node.nodes[0..node.nodes_len]) |sub_node| {
                    if (sub_node == node and sub_node.task == task) {
                        continue;
                    }
                    if (sub_node.exchange(task, .ready, .blocking, max_thread_count)) {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, sub_node, task));
                    }
                }
                for (node.deps[0..node.deps_len]) |dep| {
                    if (dep.on_node == node and dep.on_task == task) {
                        continue;
                    }
                    if (dep.on_node.exchange(dep.on_task, .ready, .blocking, max_thread_count)) {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, dep.on_node, dep.on_task));
                    }
                }
            }
            extern fn forwardToExecuteCloneThreaded(
                address_space: *Node.AddressSpace,
                thread_space: *Node.ThreadSpace,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
                arena_index: Node.AddressSpace.Index,
                stack_addr: u64,
                stack_len: u64,
            ) void;
            comptime {
                if (builtin.tracing_override orelse
                    builtin.tracing_default)
                {
                    _ = tracer.printStackTrace;
                }
                asm (@embedFile("./build/forwardToExecuteCloneThreaded4.s"));
            }
            pub export fn executeCommandThreaded(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                if (max_thread_count == 0) {
                    unreachable;
                }
                var allocator: Node.Allocator = if (Node.Allocator == mem.SimpleAllocator)
                    Node.Allocator.init_arena(Node.AddressSpace.arena(arena_index))
                else
                    Node.Allocator.init(address_space, arena_index);
                impl.spawnDeps(address_space, thread_space, &allocator, toplevel, node, task);
                while (nodeWait(node, task, arena_index)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task_lock.get(task) == .working) {
                    if (executeCommandInternal(toplevel, &allocator, node, task, arena_index)) {
                        node.assertExchange(task, .working, .finished, arena_index);
                    } else {
                        node.assertExchange(task, .working, .failed, arena_index);
                    }
                }
                allocator.unmap();
                mem.release(ThreadSpace, thread_space, arena_index);
            }
            fn executeCommandSynchronised(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            }, void) {
                impl.spawnDeps(address_space, thread_space, allocator, toplevel, node, task);
                while (nodeWait(node, task, max_thread_count)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task_lock.get(task) == .working) {
                    if (executeCommandInternal(toplevel, allocator, node, task, max_thread_count)) {
                        node.assertExchange(task, .working, .finished, max_thread_count);
                    } else {
                        node.assertExchange(task, .working, .failed, max_thread_count);
                    }
                }
            }
            fn tryAcquireThread(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *Allocator,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
            ) sys.ErrorUnion(.{
                .throw = builder_spec.errors.clock.throw ++
                    builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
                .abort = builder_spec.errors.clock.abort ++
                    builder_spec.errors.fork.abort ++ builder_spec.errors.execve.abort ++ builder_spec.errors.waitpid.abort,
            }, void) {
                if (max_thread_count == 0) {
                    try meta.wrap(impl.executeCommandSynchronised(address_space, thread_space, allocator, toplevel, node, task));
                } else {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (mem.testAcquire(ThreadSpace, thread_space, arena_index)) {
                            const stack_addr: u64 = ThreadSpace.low(arena_index);
                            return forwardToExecuteCloneThreaded(address_space, thread_space, toplevel, node, task, arena_index, stack_addr, stack_aligned_bytes);
                        }
                    }
                    try meta.wrap(impl.executeCommandSynchronised(address_space, thread_space, allocator, toplevel, node, task));
                }
            }
        };
        pub fn executeToplevel(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            toplevel: *const Node,
            node: *Node,
            maybe_task: ?types.Task,
        ) sys.ErrorUnion(.{
            .throw = builder_spec.errors.clock.throw ++ builder_spec.errors.sleep.throw ++
                builder_spec.errors.fork.throw ++ builder_spec.errors.execve.throw ++ builder_spec.errors.waitpid.throw,
            .abort = builder_spec.errors.clock.abort ++ builder_spec.errors.sleep.abort ++
                builder_spec.errors.fork.abort ++ builder_spec.errors.execve.abort ++ builder_spec.errors.waitpid.abort,
        }, bool) {
            const task: types.Task = maybe_task orelse node.task;
            if (node.exchange(task, .ready, .blocking, max_thread_count)) {
                try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, node, task));
            }
            while (toplevelWait(thread_space)) {
                try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
            }
            return node.task_lock.get(task) == .finished;
        }
        const state_logging: builtin.Logging.AttemptSuccessFault = builder_spec.logging.state.override();
        fn exchange(node: *Node, task: types.Task, old_state: types.State, new_state: types.State, arena_index: AddressSpace.Index) bool {
            const ret: bool = node.task_lock.atomicExchange(task, old_state, new_state);
            if (ret) {
                if (state_logging.Success) {
                    debug.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (state_logging.Attempt) {
                    debug.noExchangeNotice(node, debug.about.state_0_s, task, old_state, new_state, arena_index);
                }
            }
            return ret;
        }
        fn assertExchange(node: *Node, task: types.Task, old_state: types.State, new_state: types.State, arena_index: AddressSpace.Index) void {
            if (old_state == new_state) {
                return;
            }
            if (node.task_lock.atomicExchange(task, old_state, new_state)) {
                if (state_logging.Success) {
                    debug.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (state_logging.Fault) {
                    debug.noExchangeNotice(node, debug.about.state_1_s, task, old_state, new_state, arena_index);
                }
                builtin.proc.exitGroup(2);
            }
        }
        fn testDeps(node: *const Node, task: types.Task, state: types.State) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for (node.deps[0..node.deps_len]) |*dep| {
                if (dep.on_node == node and dep.on_task == task) {
                    continue;
                }
                if (dep.on_node.task_lock.get(dep.on_task) == state) {
                    return true;
                }
            }
            for (node.nodes[0..node.nodes_len]) |sub_node| {
                if (sub_node == node and sub_node.task == task) {
                    continue;
                }
                if (sub_node.task_lock.get(task) == state) {
                    return true;
                }
            }
            return false;
        }
        fn exchangeDeps(node: *Node, task: types.Task, from: types.State, to: types.State, arena_index: AddressSpace.Index) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for (node.deps[0..node.deps_len]) |*dep| {
                if (dep.on_node == node and dep.on_task == task) {
                    continue;
                }
                if (dep.on_node.task_lock.get(dep.on_task) != from) {
                    continue;
                }
                if (!dep.on_node.exchange(dep.on_task, from, to, arena_index)) {
                    return;
                }
            }
        }
        /// Despite having futexes (`proc.futex*`) this implementation opts for
        /// periodic scans with sleeping, because the task lock is not a perfect
        /// fit with futexes (u32). Extensions to `ThreadSafeSet` would permit.
        ///
        /// Invoking a group has the same effect as invoking every member in that group.
        pub fn nodeWait(node: *Node, task: types.Task, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.task_lock.get(task) == .blocking) {
                if (testDeps(node, task, .failed) or
                    testDeps(node, task, .cancelled))
                {
                    if (node.exchange(task, .blocking, .failed, arena_index)) {
                        exchangeDeps(node, task, .ready, .cancelled, arena_index);
                        exchangeDeps(node, task, .blocking, .failed, arena_index);
                    }
                    return true;
                }
                if (testDeps(node, task, .working) or
                    testDeps(node, task, .blocking))
                {
                    return true;
                }
                if (node.kind == .worker) {
                    node.assertExchange(task, .blocking, .working, arena_index);
                } else {
                    node.assertExchange(task, .blocking, .finished, arena_index);
                }
            }
            return false;
        }
        fn toplevelWait(thread_space: *ThreadSpace) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (max_thread_count == 0) {
                return false;
            }
            if (thread_space.count() != 0) {
                return true;
            }
            return false;
        }
        fn status(ret: []u8) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (ret[1] == builder_spec.options.compiler_error_status) {
                return false;
            }
            if (ret[1] == builder_spec.options.compiler_cache_hit_status or
                ret[1] == builder_spec.options.compiler_expected_status)
            {
                return ret[0] == builder_spec.options.system_expected_status;
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
        fn binaryRelative(allocator: *Allocator, name: [:0]u8, kind: types.OutputMode) [:0]const u8 {
            switch (kind) {
                .exe => return concatenate(allocator, &[_][]const u8{ paths.zig_out_exe_dir ++ "/", name }),
                .lib => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_exe_dir ++ "/", name, builder_spec.options.extensions.lib },
                ),
                .obj => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_exe_dir ++ "/", name, builder_spec.options.extensions.obj },
                ),
            }
        }
        fn archiveRelative(allocator: *Allocator, name: []const u8) [:0]const u8 {
            return concatenate(
                allocator,
                &[_][]const u8{ paths.zig_out_lib_dir ++ "/lib", name, builder_spec.options.extensions.ar },
            );
        }
        fn auxiliaryRelative(allocator: *Allocator, name: [:0]const u8, kind: types.AuxOutputMode) [:0]u8 {
            switch (kind) {
                .@"asm" => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.@"asm" },
                ),
                .llvm_ir => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.llvm_ir },
                ),
                .llvm_bc => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.llvm_bc },
                ),
                .h => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.h },
                ),
                .docs => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.docs },
                ),
                .analysis => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.analysis },
                ),
                .implib => return concatenate(
                    allocator,
                    &[_][]const u8{ paths.zig_out_aux_dir ++ "/", name, builder_spec.options.extensions.implib },
                ),
            }
        }
        pub fn processCommandsInternal(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            toplevel: *Node,
            node: *Node,
            task: ?types.Task,
            arg_idx: u64,
        ) ?bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const name: [:0]const u8 = mach.manyToSlice80(GlobalState.args[arg_idx]);
            if (mach.testEqualMany8(name, node.name)) {
                toplevel.args_len = arg_idx +% 1;
                return executeToplevel(address_space, thread_space, allocator, toplevel, node, task);
            } else {
                for (node.nodes[0..node.nodes_len]) |sub_node| {
                    if (processCommandsInternal(address_space, thread_space, allocator, toplevel, sub_node, task, arg_idx)) |result| {
                        return result;
                    }
                }
            }
            return null;
        }
        pub fn processCommands(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
        ) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var task: ?types.Task = null;
            var arg_idx: u64 = 5;
            lo: while (arg_idx != GlobalState.args.len) : (arg_idx +%= 1) {
                const name: [:0]const u8 = mach.manyToSlice80(GlobalState.args[arg_idx]);
                var task_idx: u64 = 0;
                while (task_idx != types.Task.list.len) : (task_idx +%= 1) {
                    if (mach.testEqualMany8(name, @tagName(types.Task.list[task_idx]))) {
                        task = types.Task.list[task_idx];
                        continue :lo;
                    }
                }
                if (mach.testEqualMany8(builder_spec.options.names.toplevel_list_command, name)) {
                    return debug.toplevelCommandNotice(allocator, node);
                }
                if (processCommandsInternal(address_space, thread_space, allocator, node, node, task, arg_idx)) |result| {
                    return if (!result) builtin.proc.exitError(error.UnfinishedRequest, 2);
                }
                builtin.proc.exitErrorFault(error.NotACommand, name, 2);
            }
        }
        const paths = .{
            .zig_out_exe_dir = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.exe_out_dir,
            .zig_out_lib_dir = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.lib_out_dir,
            .zig_out_aux_dir = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.aux_out_dir,
            .tracer_root = builder_spec.options.names.tracer_root orelse build.root ++ "/top/tracer.zig",
        };
        const update_exit_message: [2]types.Message.ClientHeader = .{
            .{ .tag = .update, .bytes_len = 0 },
            .{ .tag = .exit, .bytes_len = 0 },
        };
        const address_space_options = .{
            .thread_safe = true,
            .require_map = false,
            .require_unmap = false,
        };
        const thread_space_options = .{
            .thread_safe = true,
            .require_map = false,
            .require_unmap = false,
        };
        const open_options = .{
            .read = true,
            .no_follow = true,
        };
        const create_truncate_options = .{
            .exclusive = false,
            .truncate = true,
        };
        const create_append_options = .{
            .exclusive = false,
            .append = true,
            .truncate = false,
        };
        const thread_map_options = .{
            .grows_down = true,
        };
        const pipe_options = .{
            .close_on_exec = false,
        };
        const allocator_errors = .{
            .map = .{},
            .remap = .{},
            .unmap = .{},
        };
        const address_space_errors = .{
            .release = .ignore,
            .acquire = .ignore,
            .map = .{},
            .unmap = .{},
        };
        const allocator_options = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
            .init_commit = arena_aligned_bytes,
            .require_map = !address_space_options.require_map,
            .require_unmap = !address_space_options.require_unmap,
        };
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
        fn open() file.OpenSpec {
            return .{
                .errors = builder_spec.errors.open,
                .logging = builder_spec.logging.open,
                .options = open_options,
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
        fn link() file.LinkSpec {
            return .{
                .errors = builder_spec.errors.link,
                .logging = builder_spec.logging.link,
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
        fn clone() proc.CloneSpec {
            return .{ .errors = .{}, .return_type = void };
        }
        const MessagePtrs = packed union {
            msg: [*]align(4) u8,
            idx: [*]u32,
            str: [*:0]u8,
        };
        const AboutKind = enum { @"error", note };
        const UpdateAnswer = enum(u8) {
            updated = builder_spec.options.compiler_expected_status,
            cached = builder_spec.options.compiler_cache_hit_status,
            failed = builder_spec.options.compiler_error_status,
            other,
        };
        // any:     paths[0], build root directory
        // build:   paths[1], root/core source file pathname
        // format:  paths[0], source file or directory pathname
        // archive: paths[0], target archive file pathname
        fn primaryInput(node: *const Node) types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            switch (node.task) {
                .build => {
                    return node.paths[1];
                },
                .format, .archive, .any => {
                    return node.paths[0];
                },
                else => |tag| if (builtin.logging_general.Fault) {
                    builtin.proc.exitErrorFault(error.NoInput, @tagName(tag), 3);
                } else {
                    unreachable;
                },
            }
        }
        // any:     paths[1], cache root directory
        // build:   paths[0], binary installation file pathname
        // archive: paths[0], target archive file pathname
        fn primaryOutput(node: *const Node) types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            switch (node.task) {
                .build, .archive => {
                    return node.paths[0];
                },
                .any => {
                    return node.paths[1];
                },
                else => |tag| if (builtin.logging_general.Fault) {
                    builtin.proc.exitErrorFault(error.NoOutput, @tagName(tag), 3);
                } else {
                    unreachable;
                },
            }
        }
        fn writeEnv(build_root: [:0]const u8, cache_root: [:0]const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const cache_root_fd: u64 = try meta.wrap(
                file.path(path1(), cache_root),
            );
            const env_fd: u64 = try meta.wrap(
                file.createAt(create(), cache_root_fd, builder_spec.options.names.env ++
                    builder_spec.options.extensions.zig, file.mode.regular),
            );
            var buf: [4096 *% 8]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                debug.about.zig_exe_s,    debug.about.build_root_s,
                debug.about.cache_root_s, debug.about.global_cache_root_s,
            }, [_][]const u8{
                mach.manyToSlice80(GlobalState.args[1]),
                build_root,
                cache_root,
                mach.manyToSlice80(GlobalState.args[4]),
            }) |decl, value| {
                mach.memcpy(buf[len..].ptr, decl.ptr, decl.len);
                len +%= decl.len;
                mach.memcpy(buf[len..].ptr, value.ptr, value.len);
                len +%= value.len;
            }
            @ptrCast(*[3]u8, buf[len..].ptr).* = "\";\n".*;
            len +%= 3;
            try meta.wrap(
                file.write(write(), env_fd, buf[0..len]),
            );
            try meta.wrap(
                file.close(close(), cache_root_fd),
            );
            try meta.wrap(
                file.close(close(), env_fd),
            );
        }
        pub fn duplicate(allocator: *Allocator, values: []const u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const buf: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(values.len +% 1, 1));
            mach.memcpy(buf, values.ptr, values.len);
            buf[values.len] = 0;
            return buf[0..values.len :0];
        }
        pub fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var len: u64 = 0;
            for (values) |value| len +%= value.len;
            const buf: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(len +% 1, 1));
            var idx: u64 = 0;
            for (values) |value| {
                mach.memcpy(buf + idx, value.ptr, value.len);
                idx +%= value.len;
            }
            buf[len] = 0;
            return buf[0..len :0];
        }
        fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var count: u64 = 0;
            for (args) |value| count +%= @boolToInt(value == 0);
            const ptrs: [*][*:0]u8 = @intToPtr([*][*:0]u8, allocator.allocateRaw(8 *% (count +% 1), 1));
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
            ptrs[len] = comptime builtin.zero([*:0]u8);
            return ptrs[0..len];
        }
        fn makeCommandName(allocator: *Allocator, root: [:0]const u8) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
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
        const omni_lock = .{ .bytes = .{ .null, .ready, .ready, .ready, .ready, .ready, .null } };
        const obj_lock = .{ .bytes = .{ .null, .null, .null, .ready, .null, .null, .null } };
        const exe_lock = .{ .bytes = .{ .null, .null, .null, .ready, .ready, .null, .null } };
        const run_lock = .{ .bytes = .{ .null, .null, .null, .null, .ready, .null, .null } };
        const format_lock = .{ .bytes = .{ .null, .null, .ready, .null, .null, .null, .null } };
        const archive_lock = .{ .bytes = .{ .null, .null, .null, .null, .null, .ready, .null } };
        const debug = struct {
            const about = .{
                .ar_s = builtin.fmt.about("ar"),
                .run_s = builtin.fmt.about("run"),
                .format_s = builtin.fmt.about("fmt"),
                .build_exe_s = builtin.fmt.about("build-exe"),
                .build_obj_s = builtin.fmt.about("build-obj"),
                .build_lib_s = builtin.fmt.about("build-lib"),
                .state_0_s = builtin.fmt.about("state"),
                .state_1_s = builtin.fmt.about("state-fault"),
                .bytes_s = " bytes, ",
                .green_s = "\x1b[92;1m",
                .red_s = "\x1b[91;1m",
                .new_s = "\x1b[0m\n",
                .reset_s = "\x1b[0m",
                .gold_s = "\x1b[93m",
                .bold_s = "\x1b[1m",
                .faint_s = "\x1b[2m",
                .grey_s = "\x1b[0;38;5;250;1m",
                .trace_s = "\x1b[38;5;247m",
                .hi_green_s = "\x1b[38;5;46m",
                .hi_red_s = "\x1b[38;5;196m",
                .zig_exe_s = "pub const zig_exe: [:0]const u8 = \"",
                .build_root_s = "\";\npub const build_root: [:0]const u8 = \"",
                .cache_root_s = "\";\npub const cache_root: [:0]const u8 = \"",
                .global_cache_root_s = "\";\npub const global_cache_root: [:0]const u8 = \"",
            };
            const fancy_hl_line: bool = false;
            fn writeWaitingOn(node: *Node, arena_index: AddressSpace.Index) void {
                var buf: [4096]u8 = undefined;
                @ptrCast(*[9]u8, &buf).* = "waiting: ".*;
                var len: u64 = 9;
                mach.memcpy(buf[len..].ptr, node.name.ptr, node.name.len);
                len +%= node.name.len;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= debug.writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                len +%= 1;
                builtin.debug.write(buf[0..len]);
            }
            fn writeFromTo(buf: [*]u8, old: types.State, new: types.State) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                @ptrCast(*[2]u8, buf).* = "={".*;
                var len: u64 = 2;
                mach.memcpy(buf + len, @tagName(old).ptr, @tagName(old).len);
                len +%= @tagName(old).len;
                @ptrCast(*[2]u8, buf + len).* = "=>".*;
                len +%= 2;
                mach.memcpy(buf + len, @tagName(new).ptr, @tagName(new).len);
                len +%= @tagName(new).len;
                buf[len] = '}';
                len +%= 1;
                return len;
            }
            fn writeExchangeTask(buf: [*]u8, node: *const Node, about_s: []const u8, task: types.Task) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                mach.memcpy(buf, about_s.ptr, about_s.len);
                var len: u64 = about_s.len;
                mach.memcpy(buf + len, node.name.ptr, node.name.len);
                len +%= node.name.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf + len, @tagName(task).ptr, @tagName(task).len);
                len +%= @tagName(task).len;
                return len;
            }
            fn exchangeNotice(node: *const Node, task: types.Task, old: types.State, new: types.State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [32768]u8 = undefined;
                var len: u64 = writeExchangeTask(&buf, node, about.state_0_s, task);
                len +%= writeFromTo(buf[len..].ptr, old, new);
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn noExchangeNotice(node: *const Node, about_s: [:0]const u8, task: types.Task, old: types.State, new: types.State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task_lock.get(task);
                var buf: [32768]u8 = undefined;
                var len: u64 = writeExchangeTask(&buf, node, about_s, task);
                buf[len] = '=';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, @tagName(actual).ptr, @tagName(actual).len);
                len +%= @tagName(actual).len;
                const add: u64 = writeFromTo(buf[len..].ptr, old, new);
                buf[len] = '!';
                len +%= add;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn writeArenaIndex(buf: [*]u8, arena_index: AddressSpace.Index) u64 {
                const idx_s: []const u8 = builtin.fmt.ud64(arena_index).readAll();
                @ptrCast(*[2]u8, buf).* = " [".*;
                mach.memcpy(buf + 2, idx_s.ptr, idx_s.len);
                buf[2 +% idx_s.len] = ']';
                return 3 +% idx_s.len;
            }
            fn stateNotice(node: *Node, task: types.Task) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task_lock.get(task);
                var buf: [32768]u8 = undefined;
                mach.memcpy(&buf, about.state_0_s.ptr, about.state_0_s.len);
                var len: u64 = about.state_0_s.len;
                mach.memcpy(buf[len..].ptr, node.name.ptr, node.name.len);
                len +%= node.name.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, @tagName(task).ptr, @tagName(task).len);
                len +%= @tagName(task).len;
                buf[len] = '=';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, @tagName(actual).ptr, @tagName(actual).len);
                len +%= @tagName(actual).len;
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            fn taskNotice(node: *Node, task: types.Task, arena_index: AddressSpace.Index, ts: time.TimeSpec, old_size: u64, new_size: u64, ret: []u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const diff_size: u64 = @max(new_size, old_size) -% @min(new_size, old_size);
                const new_size_s: []const u8 = builtin.fmt.ud64(new_size).readAll();
                const old_size_s: []const u8 = builtin.fmt.ud64(old_size).readAll();
                const diff_size_s: []const u8 = builtin.fmt.ud64(diff_size).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(ts.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(ts.nsec).readAll();
                var buf: [32768]u8 = undefined;
                const about_s: []const u8 = switch (task) {
                    else => unreachable,
                    .archive => about.ar_s,
                    .format => about.format_s,
                    .run => about.run_s,
                    .build => switch (node.task_info.build.kind) {
                        .exe => about.build_exe_s,
                        .obj => about.build_obj_s,
                        .lib => about.build_lib_s,
                    },
                };
                var len: u64 = about_s.len;
                mach.memcpy(&buf, about_s.ptr, len);
                mach.memcpy(buf[len..].ptr, node.name.ptr, node.name.len);
                len +%= node.name.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len +%= 2;
                if (task == .build) {
                    const mode: builtin.Mode = node.task_info.build.mode orelse .Debug;
                    const stripped: bool = node.task_info.build.strip orelse (mode == .ReleaseSmall);
                    mach.memcpy(buf[len..].ptr, @tagName(mode).ptr, @tagName(mode).len);
                    len +%= @tagName(mode).len;
                    @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                    len +%= 2;
                    @ptrCast(*[2]u8, buf[len..].ptr).* = "un".*;
                    if (!stripped) len +%= 2;
                    @ptrCast(*[8]u8, buf[len..].ptr).* = "stripped".*;
                    len +%= 8;
                    @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                    len +%= 2;
                }
                @ptrCast(*[5]u8, buf[len..].ptr).* = "exit=".*;
                len +%= 5;
                const exit_s: []const u8 = builtin.fmt.ud64(ret[0]).readAll();
                if (task == .build) {
                    const res: UpdateAnswer = switch (ret[1]) {
                        builder_spec.options.compiler_cache_hit_status => .cached,
                        builder_spec.options.compiler_error_status => .failed,
                        builder_spec.options.compiler_expected_status => .updated,
                        else => .other,
                    };
                    const style_s: [:0]const u8 = switch (res) {
                        .failed => about.red_s,
                        else => about.bold_s,
                    };
                    const msg_s: []const u8 = @tagName(res);
                    buf[len] = '[';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    mach.memcpy(buf[len..].ptr, msg_s.ptr, msg_s.len);
                    len +%= msg_s.len;
                    @ptrCast(*[4]u8, buf[len..].ptr).* = about.reset_s.*;
                    len +%= 4;
                    buf[len] = ',';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                    buf[len] = ']';
                    len +%= 1;
                } else {
                    const style_s: [:0]const u8 = switch (ret[0]) {
                        builder_spec.options.system_expected_status => about.bold_s,
                        else => about.red_s,
                    };
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                    @ptrCast(*[4]u8, buf[len..].ptr).* = about.reset_s.*;
                    len +%= 4;
                }
                @ptrCast(*[2]u8, buf[len..].ptr).* = ", ".*;
                len +%= 2;
                if (task == .build or task == .archive) {
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
                }
                mach.memcpy(buf[len..].ptr, sec_s.ptr, sec_s.len);
                len +%= sec_s.len;
                buf[len] = '.';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, nsec_s.ptr, nsec_s.len);
                len +%= 3;
                buf[len] = 's';
                len +%= 1;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                builtin.debug.write(buf[0 .. len +% 1]);
            }
            inline fn writeAbout(buf: [*]u8, kind: AboutKind) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = 0;
                switch (kind) {
                    .@"error" => {
                        @ptrCast(*@TypeOf(about.bold_s.*), buf + len).* = about.bold_s.*;
                        len +%= about.bold_s.len;
                    },
                    .note => {
                        @ptrCast(*@TypeOf(about.grey_s.*), buf + len).* = about.grey_s.*;
                        len +%= about.grey_s.len;
                    },
                }
                const about_s: [:0]const u8 = @tagName(kind);
                mach.memcpy(buf + len, about_s.ptr, about_s.len);
                len +%= about_s.len;
                @ptrCast(*[2]u8, buf + len).* = ": ".*;
                len +%= 2;
                @ptrCast(*@TypeOf(about.bold_s.*), buf + len).* = about.bold_s.*;
                return len +% about.bold_s.len;
            }
            inline fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(*types.SourceLocation, extra + err.src_loc);
                var len: u64 = about.bold_s.len;
                @ptrCast(*[4]u8, buf).* = about.bold_s.*;
                if (err.src_loc != 0) {
                    len +%= writeSourceLocation(
                        buf + len,
                        mach.manyToSlice80(bytes + src.src_path),
                        src.line +% 1,
                        src.column +% 1,
                    );
                    @ptrCast(*[2]u8, buf + len).* = ": ".*;
                    len +%= 2;
                }
                return len;
            }
            fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @ptrCast(*types.ErrorMessage, extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(*types.SourceLocation, extra + err.src_loc);
                const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
                var len: u64 = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
                const pos: u64 = len +% @tagName(kind).len -% about.trace_s.len -% 2;
                len +%= writeAbout(buf + len, kind);
                len +%= writeMessage(buf + len, bytes, err.start, pos);
                if (err.src_loc == 0) {
                    if (err.count != 1)
                        len +%= writeTimes(buf + len, err.count);
                    for (0..err.notes_len) |idx|
                        len +%= writeError(buf + len, extra, bytes, notes[idx], .note);
                } else {
                    if (err.count != 1)
                        len +%= writeTimes(buf + len, err.count);
                    if (src.src_line != 0)
                        len +%= writeCaret(buf + len, bytes, src);
                    for (0..err.notes_len) |idx|
                        len +%= writeError(buf + len, extra, bytes, notes[idx], .note);
                    if (src.ref_len != 0)
                        len +%= writeTrace(buf + len, extra, bytes, err.src_loc, src.ref_len);
                }
                return len;
            }
            fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: u64, column: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
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
                len +%= column_s.len;
                @ptrCast(*[4]u8, buf + len).* = about.reset_s.*;
                return len +% 4;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const line: [:0]u8 = mach.manyToSlice80(bytes + src.src_line);
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
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
                        const src_file: [:0]u8 = mach.manyToSlice80(bytes + ref_src.src_path);
                        const decl_name: [:0]u8 = mach.manyToSlice80(bytes + ref_trc.decl_name);
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
            fn writeErrors(allocator: *Allocator, ptrs: MessagePtrs) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const extra: [*]u32 = ptrs.idx + 2;
                const bytes: [*:0]u8 = ptrs.str + 8 + (ptrs.idx[0] *% 4);
                var buf: [*]u8 = allocator.allocate(u8, 1024 *% 1024).ptr;
                for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
                    var len: u64 = writeError(buf, extra, bytes, err_msg_idx, .@"error");
                    builtin.debug.write(buf[0..len]);
                }
                builtin.debug.write(mach.manyToSlice80(bytes + extra[2]));
            }
            fn dependencyMaxNameWidth(node: *const Node, width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = if (builder_spec.options.hide_special and node.options.is_special) 0 else node.name.len +% 1;
                for (node.nodes[0..node.nodes_len]) |sub_node| {
                    if (sub_node != node) {
                        len = @max(len, width +% dependencyMaxNameWidth(sub_node, width +% 2));
                    }
                }
                for (node.deps[0..node.deps_len]) |dep| {
                    if (dep.on_node != node) {
                        len = @max(len, width +% dependencyMaxNameWidth(dep.on_node, width +% 2));
                    }
                }
                return len;
            }
            fn dependencyMaxRootWidth(node: *const Node) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = if (builder_spec.options.hide_special and
                    node.options.is_special) 0 else node.paths[@boolToInt(node.task == .build)].relative().len +% 1;
                for (node.nodes[0..node.nodes_len]) |sub_node| {
                    if (sub_node != node) {
                        len = @max(len, dependencyMaxRootWidth(sub_node));
                    }
                }
                for (node.deps[0..node.deps_len]) |dep| {
                    if (dep.on_node != node) {
                        len = @max(len, dependencyMaxRootWidth(dep.on_node));
                    }
                }
                return len;
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = len0;
                var deps_idx: u64 = 0;
                while (deps_idx != node.deps_len) : (deps_idx +%= 1) {
                    const dep_node: *Node = node.deps[deps_idx].on_node;
                    if (dep_node == node or
                        builder_spec.options.hide_special and dep_node.options.is_special)
                    {
                        continue;
                    }
                    const is_last: bool = deps_idx == node.deps_len -% 1;
                    const is_only: bool = dep_node.deps_len == 0;
                    mach.memcpy(buf1 + len1, if (is_last) "  " else "| ", 2);
                    buf0[len] = '\n';
                    len +%= 1;
                    mach.memcpy(buf0 + len, buf1, len1);
                    len +%= len1;
                    @ptrCast(*[2]u8, buf0 + len).* = if (is_last) "`-".* else "|-".*;
                    len +%= 2;
                    @ptrCast(*[2]u8, buf0 + len).* = if (is_only) "> ".* else "+ ".*;
                    len +%= 2;
                    mach.memcpy(buf0 + len, dep_node.name.ptr, dep_node.name.len);
                    len +%= dep_node.name.len;
                    if (dep_node.options.is_hidden and dep_node.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 2, dep_node, name_width, root_width);
                    }
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep_node, name_width, root_width);
                }
                return len;
            }
            fn writeSubNode(buf0: [*]u8, len1: u64, sub_node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = 0;
                var count: u64 = name_width -% (sub_node.name.len +% len1);
                const input: [:0]const u8 = sub_node.paths[@boolToInt(sub_node.task == .build)].names[1];
                if (input.len != 0) {
                    mach.memset(buf0 + len, ' ', count);
                    len +%= count;
                    mach.memcpy(buf0 + len, input.ptr, input.len);
                    len +%= input.len;
                    if (sub_node.descr.len != 0) {
                        count = root_width -% input.len;
                        mach.memset(buf0 + len, ' ', count);
                        len +%= count;
                        mach.memcpy(buf0 + len, sub_node.descr.ptr, sub_node.descr.len);
                        len +%= sub_node.descr.len;
                    }
                }
                return len;
            }
            fn toplevelCommandNoticeInternal(buf0: [*]u8, buf1: [*]u8, len1: u64, node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = 0;
                if (node.paths_len != 0) {
                    len +%= writeSubNode(buf0 + len, len1, node, name_width, root_width);
                }
                @ptrCast(*[4]u8, buf0 + len).* = about.faint_s.*;
                len +%= about.faint_s.len;
                len = writeAndWalkInternal(buf0, len, buf1, len1, node, name_width, root_width);
                @ptrCast(*[4]u8, buf0 + len).* = about.reset_s.*;
                len +%= about.reset_s.len;
                for (node.nodes[0..node.nodes_len], 0..) |sub_node, nodes_idx| {
                    if (sub_node == node or
                        sub_node.options.is_hidden or
                        builder_spec.options.hide_special and sub_node.options.is_special)
                    {
                        continue;
                    }
                    const is_last: bool = nodes_idx == node.nodes_len -% 1;
                    const is_only: bool = sub_node.nodes_len == 0;
                    if (len1 == 0) {
                        @ptrCast(*[2]u8, buf1 + len1).* = "  ".*;
                    } else {
                        @ptrCast(*[2]u8, buf1 + len1).* = if (is_last) "  ".* else "| ".*;
                    }
                    buf0[len] = '\n';
                    len +%= 1;
                    mach.memcpy(buf0 + len, buf1, len1);
                    len +%= len1;
                    @ptrCast(*[2]u8, buf0 + len).* = if (len1 == 0) "  ".* else if (is_last) "`-".* else "|-".*;
                    len +%= 2;
                    @ptrCast(*[2]u8, buf0 + len).* = if (is_only) "- ".* else "o ".*;
                    len +%= 2;
                    if (sub_node.options.is_hidden and sub_node.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 4, sub_node, name_width, root_width);
                    }
                    mach.memcpy(buf0 + len, sub_node.name.ptr, sub_node.name.len);
                    len +%= sub_node.name.len;
                    len +%= toplevelCommandNoticeInternal(buf0 + len, buf1, len1 +% 2, sub_node, name_width, root_width);
                }
                return len;
            }
            fn toplevelCommandNotice(allocator: *Allocator, toplevel: *const Node) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: u64 = allocator.next;
                defer allocator.next = save;
                var name_width: u64 = 0;
                var root_width: u64 = 0;
                for (toplevel.nodes[0..toplevel.nodes_len]) |node| {
                    if (!node.options.is_hidden) {
                        name_width = @max(name_width, dependencyMaxNameWidth(node, 2));
                        root_width = @max(root_width, dependencyMaxRootWidth(node));
                    }
                }
                name_width +%= 4;
                root_width +%= 4;
                name_width &= ~@as(u64, 3);
                root_width &= ~@as(u64, 3);
                const buf0: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(1024 *% 1024, 1));
                var len0: u64 = toplevel.name.len;
                const buf1: [*]u8 = @intToPtr([*]u8, allocator.allocateRaw(4096, 1));
                mach.memcpy(buf0, toplevel.name.ptr, toplevel.name.len);
                len0 +%= toplevelCommandNoticeInternal(buf0 + len0, buf1, 0, toplevel, name_width, root_width);
                buf0[len0] = '\n';
                len0 +%= 1;
                builtin.debug.write(buf0[0..len0]);
            }
            fn writeRecord(node: *Node, name: [:0]const u8, record: types.Record) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                var len: u64 = 0;
                mach.memcpy(&buf, builder_spec.options.names.zig_stat_dir.ptr, builder_spec.options.names.zig_stat_dir.len);
                len +%= builder_spec.options.names.zig_stat_dir.len;
                buf[len] = '/';
                len +%= 1;
                mach.memcpy(buf[len..].ptr, name.ptr, name.len);
                len +%= name.len;
                buf[len] = 0;
                const fd: u64 = try meta.wrap(file.createAt(create2(), node.fds[0], buf[0..len :0], file.mode.regular));
                try meta.wrap(file.writeOne(write3(), fd, record));
                try meta.wrap(file.close(close(), fd));
            }
        };
    };
    return Type;
}
pub usingnamespace struct {
    pub const root: [:0]const u8 = libraryRoot();
};
fn libraryRoot() [:0]const u8 {
    comptime {
        const build4: [:0]const u8 = @src().file;
        var idx: u64 = build4.len -% 1;
        while (build4[idx] != '/') {
            idx -%= 1;
        }
        idx -%= 1;
        while (build4[idx] != '/') {
            idx -%= 1;
            if (idx == 0) break;
        }
        return build4[0..idx] ++ [0:0]u8{};
    }
}
// TODO:
// * Every (primary) task with pre and post functions.
