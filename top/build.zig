const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
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
    /// Errors for system calls called by builder. This excludes `clone3`,
    /// which must be implemented in assembly.
    errors: Errors = .{},
    pub const Options = struct {
        commands: struct {
            /// Enable `zig build-(exe|obj|lib)` command.
            build: bool = true,
            /// Enable `zig fmt` command.
            format: bool = true,
            /// Enable `zig ar` command.
            archive: bool = false,
            /// Enable `zig objcopy` command.
            objcopy: bool = false,
        } = .{},
        /// The maximum number of threads in addition to main.
        /// Bytes allowed per thread arena (dynamic maximum)
        arena_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (static maximum)
        stack_aligned_bytes: u64 = 8 * 1024 * 1024,
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u64 = 8,
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
        /// Enable assertions to ensure correct usage.
        enable_usage_validation: bool = false,
        /// Enable runtime safety.
        enable_safety: bool = false,
        /// Require build runner compile DWARF parser and stack trace writers.
        enable_history: bool = true,
        /// Enable advanced builder features, such as project-wide comptime
        /// constants and caching special modules.
        enable_build_configuration: bool = true,
        /// Nodes with this name prefix are hidden in pre.
        hide_based_on_name_prefix: ?u8 = '_',
        /// Nodes with hidden parent/group nodes are also hidden
        hide_based_on_group: bool = true,
        /// Never list special nodes among or allow explicit building.
        hide_special: bool = true,
        /// Disable all features related to default initialisation of nodes.
        never_initialize: bool = false,
        /// Disable all features related to automatic updating of nodes.
        never_update: bool = false,
        /// Add run task for all executable build outputs
        add_run_to_executables: bool = true,
        /// Enable stack traces in runtime errors for executables where mode is
        /// Debug with debugging symbols included
        add_debug_stack_traces: bool = true,
        /// Pass --main-pkg-path=<build_root> for all compile commands.
        main_pkg_path_to_build_root: bool = true,
        /// Record build command data in a condensed format.
        write_build_task_record: bool = false,
        /// Include build task record serialised in build configuration.
        write_hist_serial: bool = false,
        names: struct {
            /// Name of the toplevel 'builder' node.
            toplevel_node: [:0]const u8 = "toplevel",
            /// Name of the special command used to list available commands.
            toplevel_list_command: [:0]const u8 = "list",
            /// Name of the special command used to disable multi-threading.
            single_threaded_command: [:0]const u8 = "--single-threaded",
            /// Module containing full paths of zig_exe, build_root,
            /// cache_root, and global_cache_root. May be useful for
            /// metaprogramming.
            config: [:0]const u8 = "config",
            /// Basename of output directory relative to build root.
            zig_out_dir: [:0]const u8 = "zig-out",
            /// Basename of cache directory relative to build root.
            zig_cache_dir: [:0]const u8 = "zig-cache",
            /// Basename of statistics directory relative to build root.
            zig_stat_dir: [:0]const u8 = "zig-stat",
            /// Basename of configuration directory relative to build root.
            zig_build_dir: [:0]const u8 = "zig-build",
            /// Basename of executables output directory relative to output
            /// directory.
            exe_out_dir: [:0]const u8 = "bin",
            /// Basename of library output directory relative to output
            /// directory.
            lib_out_dir: [:0]const u8 = "lib",
            /// Basename of auxiliary output directory relative to output
            /// directory.
            aux_out_dir: [:0]const u8 = "aux",
            /// Optional pathname to root source used to compile tracer object.
            trace_root: ?[:0]const u8 = null,
        } = .{},
        special: struct {
            /// Defines formatter type used to pass configuration values to program.
            Config: type = types.Config,
            /// Defines compile commands for stack tracer object
            trace: ?types.tasks.BuildCommand = .{ .kind = .obj, .mode = .ReleaseSmall, .strip = true },
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
            /// Initial size of configuration value `cfgs` buffer.
            cfgs: u64 = 1,
        } = .{},
    };
    pub const Logging = packed struct {
        /// Report exchanges on task lock state:
        ///     Attempt => When resulting in no change of state.
        ///     Success => When resulting in change of state.
        ///     Fault   => When the change of state results in any abort.
        state: builtin.Logging.AttemptSuccessFault = .{},
        /// Report completion of tasks with summary of results:
        ///     Attempt => When the task was unable to complete due to a
        ///                dependency.
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
        tag: types.Node,
        name: [:0]u8,
        descr: [:0]const u8,
        task: Task,
        flags: packed struct {
            /// Whether the node will be shown by list commands.
            is_hidden: bool = false,
            is_special: bool = false,
            /// Whether a node will be processed before being returned to `buildMain`.
            do_init: bool = !builder_spec.options.never_initialize,
            /// Whether a node will be processed after returning from `buildMain`.
            do_update: bool = !builder_spec.options.never_update,
            /// Whether a node will be processed on invokation of a user defined update command.
            do_user_update: bool = !builder_spec.options.never_update,
            /// Flags relevant to group nodes.
            group: Group = .{},
            /// Flags relevant to build-* worker nodes.
            build: Build = .{},
            const Group = packed struct {
                /// Whether independent nodes will be processed in parallel.
                is_single_threaded: bool = false,
            };
            const Build = packed struct {
                /// Builder will create a configuration root. Enables usage of
                /// configuration constants.
                configure_root: bool = true,
                /// Builder will unconditionally add `trace` object to
                /// compile command.
                add_stack_traces: bool = false,
            };
        },
        impl: packed struct {
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
            cfgs: [*]Config,
            cfgs_max_len: u64,
            cfgs_len: u64,
        },
        const Node = @This();
        const GlobalState = struct {
            pub var args: [][*:0]u8 = undefined;
            pub var vars: [][*:0]u8 = undefined;
            pub var trace: *Node = undefined;
            pub var build_root_fd: u64 = undefined;
            pub var config_root_fd: u64 = undefined;
        };
        const Task = extern struct {
            tag: types.Task,
            lock: types.Lock,
            info: Info,
            const Info = extern union {
                build: *BuildCommand,
                format: *FormatCommand,
                archive: *ArchiveCommand,
                objcopy: *ObjcopyCommand,
            };
        };
        pub const specification: BuilderSpec = builder_spec;
        pub const max_thread_count: u64 =
            builder_spec.options.max_thread_count;
        pub const stack_aligned_bytes: u64 =
            builder_spec.options.stack_aligned_bytes;
        const BuildCommand = meta.maybe(
            builder_spec.options.commands.build,
            types.tasks.BuildCommand,
        );
        pub const Config = builder_spec.options.special.Config;
        const FormatCommand = meta.maybe(
            builder_spec.options.commands.build,
            types.tasks.FormatCommand,
        );
        const ArchiveCommand = meta.maybe(
            builder_spec.options.commands.build,
            types.tasks.ArchiveCommand,
        );
        const ObjcopyCommand = meta.maybe(
            builder_spec.options.commands.build,
            types.tasks.ObjcopyCommand,
        );
        const max_arena_count: u64 =
            if (max_thread_count == 0) 4 else max_thread_count + 1;
        const arena_aligned_bytes: u64 =
            builder_spec.options.arena_aligned_bytes;
        const stack_lb_addr: u64 = builder_spec.options.stack_lb_addr;
        const stack_up_addr: u64 = stack_lb_addr +
            (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: u64 = stack_up_addr;
        const arena_up_addr: u64 = arena_lb_addr +
            (max_arena_count * arena_aligned_bytes);
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
        const OtherAllocator = mem.GenericRtArenamem.SimpleAllocator(.{
            .logging = builtin.zero(mem.mem.SimpleAllocatorLogging),
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
        const init_len = builder_spec.options.init_len;
        fn addPath(node: *Node, allocator: *mem.SimpleAllocator) *types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(types.Path);
            const addr_buf: *u64 = @ptrCast(&node.impl.paths);
            const ret: *types.Path = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.paths, addr_buf, &node.impl.paths_max_len, node.impl.paths_len));
            node.impl.paths_len +%= 1;
            return ret;
        }
        fn addNode(node: *Node, allocator: *mem.SimpleAllocator) **Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(*Node);
            const addr_buf: *u64 = @ptrCast(&node.impl.nodes);
            const ret: **Node = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.nodes, addr_buf, &node.impl.nodes_max_len, node.impl.nodes_len));
            node.impl.nodes_len +%= 1;
            return ret;
        }
        fn addDep(node: *Node, allocator: *mem.SimpleAllocator) *Dependency {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(Dependency);
            const addr_buf: *u64 = @ptrCast(&node.impl.deps);
            const ret: *Dependency = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.deps, addr_buf, &node.impl.deps_max_len, node.impl.deps_len));
            node.impl.deps_len +%= 1;
            mem.zero(Dependency, ret);
            return ret;
        }
        fn addArg(node: *Node, allocator: *mem.SimpleAllocator) *[*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {}
            const size_of: comptime_int = @sizeOf([*:0]u8);
            const addr_buf: *u64 = @ptrCast(&node.impl.args);
            const ret: *[*:0]u8 = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.args, addr_buf, &node.impl.args_max_len, node.impl.args_len));
            node.impl.args_len +%= 1;
            return ret;
        }
        /// Add constant declaration to build configuration.
        /// `node` must be `build-exe` worker.
        pub fn addConfig(node: *Node, allocator: *mem.SimpleAllocator, config: Config) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {}
            const size_of: comptime_int = @sizeOf(Config);
            const addr_buf: *u64 = @ptrCast(&node.impl.cfgs);
            const ptr: *Config = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.cfgs, addr_buf, &node.impl.cfgs_max_len, node.impl.cfgs_len));
            ptr.* = config;
            node.impl.cfgs_len +%= 1;
        }
        pub fn addModule(node: *Node, allocator: *mem.SimpleAllocator, module: types.Module) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {}
            const size_of: comptime_int = @sizeOf(types.Module);
            const addr_buf: *u64 = @ptrCast(&node.impl.cfgs);
            const ptr: *types.Module = @ptrFromInt(allocator.addGeneric(size_of, //
                init_len.cfgs, addr_buf, &node.impl.cfgs_max_len, node.impl.cfgs_len));
            ptr.* = module;
            node.impl.cfgs_len +%= 1;
        }
        pub fn addRunArg(node: *Node, allocator: *mem.SimpleAllocator, arg: []const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (@intFromPtr(arg.ptr) <= arena_up_addr and
                @intFromPtr(arg.ptr) >= arena_lb_addr)
            {
                node.addArg(allocator).* = @ptrCast(@constCast(arg.ptr));
            } else {
                node.addArg(allocator).* = duplicate(allocator, arg);
            }
        }
        pub fn addToplevelArgs(node: *Node, allocator: *mem.SimpleAllocator) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for ([_][*:0]u8{
                GlobalState.args[1], GlobalState.args[2],
                GlobalState.args[3], GlobalState.args[4],
            }) |arg| {
                node.addArg(allocator).* = arg;
            }
        }
        fn makeRootDirectory(root_fd: u64, name: [:0]const u8) void {
            var st: file.Status = undefined;
            var rc: u64 = sys.call_noexcept(.mkdirat, u64, .{ root_fd, @intFromPtr(name.ptr), @as(u16, @bitCast(file.mode.directory)) });
            if (rc == 0) {
                return;
            }
            rc = sys.call_noexcept(.newfstatat, u64, .{ root_fd, @intFromPtr(name.ptr), @intFromPtr(&st), 0 });
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
                node.flags.is_hidden = prefix == node.name[0];
                return;
            }
            if (builder_spec.options.hide_based_on_group) {
                node.flags.is_hidden = toplevel.options.is_hidden;
                return;
            }
        }
        pub fn initSpecialNodes(allocator: *mem.SimpleAllocator, toplevel: *Node) void {
            if (builder_spec.options.special.trace) |build_cmd| {
                const special: *Node = toplevel.addBuild(allocator, build_cmd, "trace", paths.trace_root);
                special.flags.is_special = true;
                special.flags.build.configure_root = false;
                GlobalState.trace = special;
            }
        }
        pub fn cacheRoot(toplevel: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return toplevel.impl.paths[0].names[0];
        }
        pub fn globalCacheRoot(toplevel: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return toplevel.impl.paths[1].names[0];
        }
        pub fn initState(args: [][*:0]u8, vars: [][*:0]u8) void {
            GlobalState.args = args;
            GlobalState.vars = vars;
            GlobalState.build_root_fd = try meta.wrap(file.path(path1(), mach.manyToSlice80(args[2])));
        }
        /// Initialize a toplevel node.
        pub fn init(allocator: *mem.SimpleAllocator) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!thread_space_options.require_map) {
                mem.map(map(), .{}, .{}, stack_lb_addr, stack_aligned_bytes * max_thread_count);
            }
            var node: *Node = allocator.create(Node);
            node.flags = .{};
            node.addPath(allocator).addName(allocator).* = mach.manyToSlice80(GlobalState.args[2]);
            node.addPath(allocator).addName(allocator).* = mach.manyToSlice80(GlobalState.args[3]);
            node.name = duplicate(allocator, builder_spec.options.names.toplevel_node);
            node.tag = .group;
            node.impl.args = GlobalState.args.ptr;
            node.impl.args_max_len = GlobalState.args.len;
            node.impl.args_len = GlobalState.args.len;
            for ([6][:0]const u8{
                builder_spec.options.names.zig_out_dir,
                paths.zig_out_exe_dir,
                paths.zig_out_lib_dir,
                paths.zig_out_aux_dir,
                builder_spec.options.names.zig_build_dir,
                builder_spec.options.names.zig_stat_dir,
            }) |name| {
                makeRootDirectory(GlobalState.build_root_fd, name);
            }
            node.task.tag = .any;
            node.task.lock = omni_lock;
            writeBuildContext(node.cacheRoot(), node.globalCacheRoot());
            return node;
        }
        /// Initialize a new group command
        pub fn addGroup(toplevel: *Node, allocator: *mem.SimpleAllocator, name: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            node.flags = .{};
            toplevel.addNode(allocator).* = node;
            node.impl.paths = toplevel.impl.paths;
            node.tag = .group;
            node.name = duplicate(allocator, name);
            node.flags.is_hidden = name[0] == '_';
            node.task.tag = .any;
            node.task.lock = omni_lock;
            return node;
        }
        /// Initialize a new `zig fmt` command.
        pub fn addFormat(toplevel: *Node, allocator: *mem.SimpleAllocator, format_cmd: FormatCommand, name: []const u8, pathname: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!builder_spec.options.commands.format)
                @compileError("format task disabled");
            const node: *Node = allocator.create(Node);
            node.flags = .{};
            toplevel.addNode(allocator).* = node;
            node.tag = .worker;
            node.task.tag = .format;
            node.task.info = .{ .format = allocator.create(FormatCommand) };
            node.name = duplicate(allocator, name);
            const target_path: *types.Path = node.addPath(allocator);
            if (pathname[0] != '/') {
                target_path.addName(allocator).* = toplevel.impl.paths[0].names[0];
            }
            target_path.addName(allocator).* = duplicate(allocator, pathname);
            node.task.info.format.* = format_cmd;
            initializeCommand(allocator, toplevel, node);
            return node;
        }
        /// Initialize a new `zig ar` command.
        pub fn addArchive(toplevel: *Node, allocator: *mem.SimpleAllocator, archive_cmd: ArchiveCommand, name: []const u8, deps: []const *Node) *Node {
            if (!builder_spec.options.commands.archive)
                @compileError("archive task disabled");
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            node.flags = .{};
            toplevel.addNode(allocator).* = node;
            node.tag = .worker;
            node.task.tag = .archive;
            node.task.info = .{ .archive = allocator.create(ArchiveCommand) };
            node.name = duplicate(allocator, name);
            const archive_path: *types.Path = node.addPath(allocator);
            archive_path.addName(allocator).* = toplevel.impl.paths[0].names[0];
            archive_path.addName(allocator).* = archiveRelative(allocator, node.name);
            node.task.info.archive.* = archive_cmd;
            for (deps) |dep| {
                node.dependOnObject(allocator, dep);
            }
            initializeCommand(allocator, toplevel, node);
            return node;
        }
        pub fn addBuild(toplevel: *Node, allocator: *mem.SimpleAllocator, build_cmd: BuildCommand, name: []const u8, root: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!builder_spec.options.commands.build)
                @compileError("build task disabled");
            const main_pkg_path: [:0]const u8 = toplevel.impl.paths[0].names[0];
            const node: *Node = allocator.create(Node);
            node.flags = .{};
            toplevel.addNode(allocator).* = node;
            node.tag = .worker;
            node.task.tag = .build;
            node.task.info = .{ .build = allocator.create(BuildCommand) };
            node.name = duplicate(allocator, name);
            const binary_path: *types.Path = node.addPath(allocator);
            const root_path: *types.Path = node.addPath(allocator);
            binary_path.addName(allocator).* = main_pkg_path;
            binary_path.addName(allocator).* = binaryRelative(allocator, node.name, build_cmd.kind);
            if (root[0] != '/') {
                root_path.addName(allocator).* = main_pkg_path;
            }
            root_path.addName(allocator).* = duplicate(allocator, root);
            node.task.info.build.* = build_cmd;
            initializeCommand(allocator, toplevel, node);
            return node;
        }
        pub fn addObjcopy(toplevel: *Node, allocator: *mem.SimpleAllocator, objcopy_cmd: ObjcopyCommand, name: []const u8, holder: *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!builder_spec.options.commands.build)
                @compileError("objcopy task disabled");
            const node: *Node = allocator.create(Node);
            node.flags = .{};
            toplevel.addNode(allocator).* = node;
            node.tag = .worker;
            node.task.tag = .build;
            node.task.info = .{ .objcopy = allocator.create(ObjcopyCommand) };
            node.name = duplicate(allocator, name);
            node.addPath(allocator).* = holder.paths[0];
            node.task.info.objcopy.* = objcopy_cmd;
            initializeCommand(allocator, toplevel, node);
            return node;
        }
        /// Initialize a new group command with description.
        pub fn addGroupWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            name: []const u8,
            descr: [:0]const u8,
        ) *Node {
            const ret: *Node = toplevel.addGroup(allocator, name);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig fmt` command with description.
        pub fn addFormatWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            format_cmd: FormatCommand,
            name: []const u8,
            pathname: []const u8,
            descr: [:0]const u8,
        ) !*Node {
            const ret: *Node = toplevel.addFormat(allocator, format_cmd, name, pathname);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig ar` command with description.
        pub fn addArchiveWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            archive_cmd: ArchiveCommand,
            name: []const u8,
            deps: []const *Node,
            descr: [:0]const u8,
        ) *Node {
            const ret: *Node = toplevel.addArchive(allocator, archive_cmd, name, deps);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig build-*` command with description.
        pub fn addBuildWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            build_cmd: BuildCommand,
            name: []const u8,
            root: []const u8,
            descr: [:0]const u8,
        ) *Node {
            const ret: *Node = toplevel.addBuild(allocator, build_cmd, name, root);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig objcopy` command with description.
        pub fn addObjcopyWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            objcopy_cmd: ObjcopyCommand,
            name: []const u8,
            holder: *Node,
            descr: [:0]const u8,
        ) *Node {
            const ret: *Node = toplevel.addObjcopy(allocator, objcopy_cmd, name, holder);
            ret.descr = descr;
            return ret;
        }
        fn initializeCommand(allocator: *mem.SimpleAllocator, toplevel: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.flags.do_init = false;
            if (maybe_hide) {
                maybeHide(toplevel, node);
            }
            if (node.tag == .worker) {
                if (node.task.tag == .build) {
                    node.task.info.build.listen = .@"-";
                    if (builder_spec.options.main_pkg_path_to_build_root) {
                        node.task.info.build.main_pkg_path = toplevel.impl.paths[0].names[0];
                    }
                    node.task.lock = obj_lock;
                    if (node.task.info.build.kind == .exe and
                        builder_spec.options.add_run_to_executables)
                    {
                        node.task.lock = exe_lock;
                        node.dependOnSelfExe(allocator);
                    }
                }
                if (node.task.tag == .format) {
                    node.task.lock = format_lock;
                }
                if (node.task.tag == .run) {
                    node.task.lock = run_lock;
                }
                if (node.task.tag == .archive) {
                    node.task.lock = archive_lock;
                }
            }
            if (node.tag == .group) {
                node.task.lock = omni_lock;
            }
        }
        fn haveSpecialDep(node: *Node) bool {
            for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                if (dep.options.is_special) {
                    return true;
                }
            }
            return false;
        }
        fn updateCommand(allocator: *mem.SimpleAllocator, _: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.flags.do_update = false;
            if (node.tag == .worker) {
                if (node.task.tag == .build) {
                    if (defaultAddStackTracesCriteria(node.task.info.build) or
                        node.flags.build.add_stack_traces)
                    {
                        node.addConfig(allocator, .{
                            .name = "have_stack_traces",
                            .value = .{ .Bool = true },
                        });
                        node.dependOnObject(allocator, GlobalState.trace);
                    }
                    const root_basename: [:0]const u8 = node.impl.paths[1].relative();
                    if (root_basename[root_basename.len -% 1] == 'c') {
                        node.flags.build.configure_root = false;
                    }
                }
            }
        }
        fn defaultAddStackTracesCriteria(build_cmd: *BuildCommand) bool {
            if (builder_spec.options.add_debug_stack_traces) {
                if (build_cmd.kind == .exe) {
                    if (build_cmd.strip) |strip| {
                        return !strip;
                    }
                    return (build_cmd.mode orelse .Debug) != .ReleaseSmall;
                }
            }
            return false;
        }
        pub fn updateCommands(allocator: *mem.SimpleAllocator, toplevel: *Node, node: *Node) void {
            if (!node.flags.do_update) {
                return;
            }
            updateCommand(allocator, toplevel, node);
            for (node.impl.nodes[0..node.impl.nodes_len]) |sub| {
                updateCommands(allocator, toplevel, sub);
            }
            for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                updateCommands(allocator, toplevel, dep.on_node);
            }
        }
        pub fn addBuildAnon(toplevel: *Node, allocator: *mem.SimpleAllocator, build_cmd: BuildCommand, root: [:0]const u8) !*Node {
            return toplevel.addBuild(allocator, build_cmd, makeCommandName(allocator, root), root);
        }
        pub fn dependOn(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node, on_task: ?types.Task) void {
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = on_task orelse on_node.task.tag, .on_state = .finished };
        }
        pub fn dependOnObject(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.impl.paths[0];
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = .build, .on_state = .finished };
        }
        pub fn dependOnArchive(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.impl.paths[0];
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = .archive, .on_state = .finished };
        }
        fn dependOnSelfExe(node: *Node, allocator: *mem.SimpleAllocator) void {
            node.addArg(allocator).* = node.impl.paths[0].concatenate(allocator);
            node.addDep(allocator).* = .{ .task = .run, .on_node = node, .on_task = .build, .on_state = .finished };
        }
        pub const impl = struct {
            fn install(src_pathname: [:0]u8, dest_pathname: [:0]const u8) void {
                file.unlink(unlink(), dest_pathname);
                file.link(link(), src_pathname, dest_pathname);
            }
            fn clientLoop(allocator: *mem.SimpleAllocator, job: *types.JobInfo, out: file.Pipe, dest_pathname: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const header: *types.Message.ServerHeader = allocator.create(types.Message.ServerHeader);
                const save: u64 = allocator.next;
                defer allocator.next = save;
                var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
                while (try meta.wrap(file.pollOne(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                    try meta.wrap(file.readOne(read3(), out.read, header));
                    const ptrs: MessagePtrs = .{ .msg = allocator.allocateAligned(u8, header.bytes_len +% 8, 4).ptr };
                    mach.memset(ptrs.msg, 0, header.bytes_len +% 1);
                    var len: u64 = 0;
                    while (len != header.bytes_len) {
                        len +%= try meta.wrap(file.read(read2(), out.read, ptrs.msg[len..header.bytes_len]));
                    }
                    if (header.tag == .emit_bin_path) break {
                        job.ret.srv = ptrs.msg[0];
                        install(mach.manyToSlice80(ptrs.str + 1), dest_pathname);
                    };
                    if (header.tag == .error_bundle) break {
                        job.ret.srv = builder_spec.options.compiler_error_status;
                        debug.writeErrors(allocator, ptrs);
                    };
                    fd.actual = .{};
                    allocator.next = save;
                }
            }
            fn system(args: [][*:0]u8, job: *types.JobInfo) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const zig_exe: [:0]const u8 = mach.manyToSlice80(args[0]);
                job.ts = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(file.execPath(execve(), zig_exe, args, GlobalState.vars));
                }
                const ret: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                job.ts = time.diff(try meta.wrap(time.get(clock(), .realtime)), job.ts);
                job.ret.sys = proc.Status.exit(ret.status);
            }
            fn server(allocator: *mem.SimpleAllocator, args: [][*:0]u8, job: *types.JobInfo, dest_pathname: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const zig_exe: [:0]const u8 = mach.manyToSlice80(GlobalState.args[1]);
                const in: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                const out: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                job.ts = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(openChild(in, out));
                    try meta.wrap(file.execPath(execve(), zig_exe, args, GlobalState.vars));
                }
                try meta.wrap(openParent(in, out));
                try meta.wrap(file.write(write2(), in.write, &update_exit_message));
                try meta.wrap(clientLoop(allocator, job, out, dest_pathname));
                const rc: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                job.ts = time.diff(try meta.wrap(time.get(clock(), .realtime)), job.ts);
                job.ret.sys = proc.Status.exit(rc.status);
                try meta.wrap(file.close(close(), in.write));
                try meta.wrap(file.close(close(), out.read));
            }
            fn buildWrite(allocator: *mem.SimpleAllocator, cmd: *BuildCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), obj_paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), obj_paths, buf);
                return buf[0..len :0];
            }
            fn objcopyWrite(allocator: *mem.SimpleAllocator, cmd: *ObjcopyCommand, obj_path: types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), obj_path);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), obj_path, buf);
                return buf[0..len :0];
            }
            fn archiveWrite(allocator: *mem.SimpleAllocator, cmd: *ArchiveCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), obj_paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), obj_paths, buf);
                return buf[0..len :0];
            }
            fn formatWrite(allocator: *mem.SimpleAllocator, cmd: *FormatCommand, root_path: types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: u64 = builder_spec.options.max_cmdline_len orelse cmd.formatLength(mach.manyToSlice80(GlobalState.args[1]), root_path);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: u64 = cmd.formatWriteBuf(mach.manyToSlice80(GlobalState.args[1]), root_path, buf);
                return buf[0..len :0];
            }
            fn runWrite(allocator: *mem.SimpleAllocator, node: *Node, args: [][*:0]u8) [][*:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                for (args) |run_arg| node.addArg(allocator).* = run_arg;
                node.addArg(allocator).* = comptime builtin.zero([*:0]u8);
                node.impl.args_len -%= 1;
                return node.impl.args[0..node.impl.args_len];
            }
            inline fn taskArgs(allocator: *mem.SimpleAllocator, toplevel: *const Node, node: *Node, task: types.Task) [][*:0]u8 {
                if (builder_spec.options.commands.build and task == .build) {
                    return makeArgPtrs(allocator, try meta.wrap(buildWrite(allocator, node.task.info.build, node.impl.paths[1..node.impl.paths_len])));
                } else if (builder_spec.options.commands.format and task == .format) {
                    return makeArgPtrs(allocator, try meta.wrap(formatWrite(allocator, node.task.info.format, node.impl.paths[0])));
                } else if (builder_spec.options.commands.archive and task == .archive) {
                    return makeArgPtrs(allocator, try meta.wrap(archiveWrite(allocator, node.task.info.archive, node.impl.paths[0..node.impl.paths_len])));
                } else if (builder_spec.options.commands.objcopy and task == .objcopy) {
                    return makeArgPtrs(allocator, try meta.wrap(objcopyWrite(allocator, node.task.info.objcopy, node.impl.paths[1])));
                } else if (task == .run) {
                    return runWrite(allocator, node, GlobalState.args[toplevel.impl.args_len..toplevel.impl.args_max_len]);
                }
                unreachable;
            }
            fn executeCommandInternal(toplevel: *const Node, allocator: *mem.SimpleAllocator, node: *Node, task: types.Task, arena_index: u64) bool {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const job: *types.JobInfo = allocator.create(types.JobInfo);
                var old_size: u64 = 0;
                var new_size: u64 = 0;
                if (builder_spec.options.enable_build_configuration and
                    task == .build and
                    node.flags.build.configure_root)
                {
                    writeConfigRoot(allocator, node);
                }
                const args: [][*:0]u8 = taskArgs(allocator, toplevel, node, task);
                switch (task) {
                    .build, .archive => {
                        const name: [:0]const u8 = node.impl.paths[0].names[1];
                        if (0 == sys.call_noexcept(.newfstatat, u64, .{
                            GlobalState.build_root_fd, @intFromPtr(name.ptr), @intFromPtr(&job.st), 0,
                        })) {
                            old_size = job.st.size;
                        }
                        if (task == .build) {
                            try meta.wrap(impl.server(allocator, args, job, name));
                        } else {
                            try meta.wrap(impl.system(args, job));
                        }
                        if (0 == sys.call_noexcept(.newfstatat, u64, .{
                            GlobalState.build_root_fd, @intFromPtr(name.ptr), @intFromPtr(&job.st), 0,
                        })) {
                            new_size = job.st.size;
                        }
                    },
                    else => try meta.wrap(impl.system(args, job)),
                }
                if (builder_spec.options.write_build_task_record and task == .build) {
                    writeRecord(node, job);
                }
                if (builder_spec.options.show_stats) {
                    debug.taskNotice(node, task, arena_index, old_size, new_size, job);
                }
                return status(job);
            }
            fn spawnDeps(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *mem.SimpleAllocator,
                toplevel: *const Node,
                node: *const Node,
                task: types.Task,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
                    if (sub_node == node and sub_node.task.tag == task) {
                        continue;
                    }
                    if (sub_node.exchange(task, .ready, .blocking, max_thread_count)) {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, sub_node, task));
                    }
                }
                for (node.impl.deps[0..node.impl.deps_len]) |dep| {
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
                var allocator: mem.SimpleAllocator = mem.SimpleAllocator.init_arena(Node.AddressSpace.arena(arena_index));
                impl.spawnDeps(address_space, thread_space, &allocator, toplevel, node, task);
                while (nodeWait(node, task, arena_index)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task.lock.get(task) == .working) {
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
                allocator: *mem.SimpleAllocator,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
            ) void {
                const save: u64 = allocator.next;
                defer allocator.next = save;
                impl.spawnDeps(address_space, thread_space, allocator, toplevel, node, task);
                while (nodeWait(node, task, max_thread_count)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task.lock.get(task) == .working) {
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
                allocator: *mem.SimpleAllocator,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
            ) void {
                if (!(max_thread_count == 0 or toplevel.flags.group.is_single_threaded)) {
                    var arena_index: AddressSpace.Index = 0;
                    while (arena_index != max_thread_count) : (arena_index +%= 1) {
                        if (mem.testAcquire(ThreadSpace, thread_space, arena_index)) {
                            const stack_addr: u64 = ThreadSpace.low(arena_index);
                            return forwardToExecuteCloneThreaded(address_space, thread_space, toplevel, node, task, arena_index, stack_addr, stack_aligned_bytes);
                        }
                    }
                }
                try meta.wrap(impl.executeCommandSynchronised(address_space, thread_space, allocator, toplevel, node, task));
            }
        };
        pub fn executeToplevel(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *mem.SimpleAllocator,
            toplevel: *const Node,
            node: *Node,
            maybe_task: ?types.Task,
        ) bool {
            const task: types.Task = maybe_task orelse node.task.tag;
            if (node.exchange(task, .ready, .blocking, max_thread_count)) {
                try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, node, task));
            }
            while (toplevelWait(thread_space)) {
                try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
            }
            return node.task.lock.get(task) == .finished;
        }
        const state_logging: builtin.Logging.AttemptSuccessFault = builder_spec.logging.state.override();
        fn exchange(node: *Node, task: types.Task, old_state: types.State, new_state: types.State, arena_index: AddressSpace.Index) bool {
            const ret: bool = node.task.lock.atomicExchange(task, old_state, new_state);
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
            if (node.task.lock.atomicExchange(task, old_state, new_state)) {
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
        fn assertNode(node: *Node, chk: bool, msg: [:0]const u8) void {
            if (!chk) {
                debug.incorrectNodeUsageError(node, msg);
            }
        }
        fn testDeps(node: *const Node, task: types.Task, state: types.State) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for (node.impl.deps[0..node.impl.deps_len]) |*dep| {
                if (dep.on_node == node and dep.on_task == task) {
                    continue;
                }
                if (dep.on_node.task.lock.get(dep.on_task) == state) {
                    return true;
                }
            }
            for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
                if (sub_node == node and sub_node.task.tag == task) {
                    continue;
                }
                if (sub_node.task.lock.get(task) == state) {
                    return true;
                }
            }
            return false;
        }
        fn exchangeDeps(node: *Node, task: types.Task, from: types.State, to: types.State, arena_index: AddressSpace.Index) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for (node.impl.deps[0..node.impl.deps_len]) |*dep| {
                if (dep.on_node == node and dep.on_task == task) {
                    continue;
                }
                if (dep.on_node.task.lock.get(dep.on_task) != from) {
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
            if (node.task.lock.get(task) == .blocking) {
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
                if (node.tag == .worker) {
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
        fn status(job: *types.JobInfo) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (job.ret.srv == builder_spec.options.compiler_error_status) {
                return false;
            }
            if (job.ret.srv == builder_spec.options.compiler_cache_hit_status or
                job.ret.srv == builder_spec.options.compiler_expected_status)
            {
                return job.ret.sys == builder_spec.options.system_expected_status;
            }
            return job.ret.sys == builder_spec.options.system_expected_status;
        }
        fn openChild(in: file.Pipe, out: file.Pipe) void {
            try meta.wrap(file.close(close(), in.write));
            try meta.wrap(file.close(close(), out.read));
            try meta.wrap(file.duplicateTo(dup3(), in.read, 0));
            try meta.wrap(file.duplicateTo(dup3(), out.write, 1));
        }
        fn openParent(in: file.Pipe, out: file.Pipe) void {
            try meta.wrap(file.close(close(), in.read));
            try meta.wrap(file.close(close(), out.write));
        }
        fn binaryRelative(allocator: *mem.SimpleAllocator, name: [:0]u8, kind: types.OutputMode) [:0]const u8 {
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
        fn archiveRelative(allocator: *mem.SimpleAllocator, name: [:0]u8) [:0]const u8 {
            return concatenate(
                allocator,
                &[_][]const u8{ paths.zig_out_lib_dir ++ "/lib", name, builder_spec.options.extensions.ar },
            );
        }
        fn auxiliaryRelative(allocator: *mem.SimpleAllocator, name: [:0]u8, kind: types.AuxOutputMode) [:0]u8 {
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
            allocator: *mem.SimpleAllocator,
            toplevel: *Node,
            node: *Node,
            task: ?types.Task,
            arg_idx: u64,
        ) ?bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const name: [:0]const u8 = mach.manyToSlice80(GlobalState.args[arg_idx]);
            if (mach.testEqualMany8(name, node.name)) {
                toplevel.impl.args_len = arg_idx +% 1;
                return executeToplevel(address_space, thread_space, allocator, toplevel, node, task);
            } else {
                for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
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
            allocator: *mem.SimpleAllocator,
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
                if (mach.testEqualMany8(builder_spec.options.names.single_threaded_command, name)) {
                    node.flags.group.is_single_threaded = true;
                    continue :lo;
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
            .trace_root = builder_spec.options.names.trace_root orelse libraryRoot() ++ "/top/trace.zig",
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
            fn enumFromInt(srv: u8) UpdateAnswer {
                switch (srv) {
                    builder_spec.options
                        .compiler_cache_hit_status => return .cached,
                    builder_spec.options
                        .compiler_error_status => return .failed,
                    builder_spec.options
                        .compiler_expected_status => return .updated,
                    else => return .other,
                }
            }
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
        fn writeConfigRoot(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const build_cmd: *BuildCommand = node.task.info.build;
            var buf: [32768]u8 = undefined;
            var len: u64 = 0;
            @as(*[28]u8, @ptrCast(buf[len..].ptr)).* = "pub usingnamespace @import(\"".*;
            len +%= 28;
            @memcpy(buf[len..].ptr, builder_spec.options.names.config);
            len +%= builder_spec.options.names.config.len;
            @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = ".zig\");\n".*;
            len +%= 8;
            @as(*[31]u8, @ptrCast(buf[len..].ptr)).* = "pub usingnamespace @import(\"../".*;
            len +%= 31;
            @memcpy(buf[len..].ptr, node.impl.paths[1].names[1]);
            len +%= node.impl.paths[1].names[1].len;
            @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = "\");\n".*;
            len +%= 4;
            @as(*[31]u8, @ptrCast(buf[len..].ptr)).* = "pub const dependencies=struct{\n".*;
            len +%= 31;
            if (build_cmd.dependencies) |dependencies| {
                for (dependencies) |dependency| {
                    @as(*[12]u8, @ptrCast(buf[len..].ptr)).* = "pub const @\"".*;
                    len +%= 12;
                    @memcpy(buf[len..].ptr, dependency.name);
                    len +%= dependency.name.len;
                    @as(*[16]u8, @ptrCast(buf[len..].ptr)).* = "\":?[:0]const u8=".*;
                    len +%= 16;
                    if (dependency.import) |import| {
                        buf[len] = '"';
                        len +%= 1;
                        @memcpy(buf[len..].ptr, import);
                        len +%= import.len;
                        @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "\";\n".*;
                        len +%= 3;
                    } else {
                        @as(*[6]u8, @ptrCast(buf[len..].ptr)).* = "null;\n".*;
                        len +%= 6;
                    }
                }
            }
            @as(*[29]u8, @ptrCast(buf[len..].ptr)).* = "};\npub const modules=struct{\n".*;
            len +%= 29;
            if (build_cmd.modules) |modules| {
                for (modules) |module| {
                    @as(*[12]u8, @ptrCast(buf[len..].ptr)).* = "pub const @\"".*;
                    len +%= 12;
                    @memcpy(buf[len..].ptr, module.name);
                    len +%= module.name.len;
                    @as(*[15]u8, @ptrCast(buf[len..].ptr)).* = "\":[:0]const u8=".*;
                    len +%= 15;
                    buf[len] = '"';
                    len +%= 1;
                    @memcpy(buf[len..].ptr, module.path);
                    len +%= module.path.len;
                    @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "\";\n".*;
                    len +%= 3;
                }
            }
            @as(*[35]u8, @ptrCast(buf[len..].ptr)).* = "};\npub const compile_units=struct{\n".*;
            len +%= 35;
            for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                if (dep.on_node == node) {
                    continue;
                }
                if (dep.on_task == .build) {
                    @as(*[12]u8, @ptrCast(buf[len..].ptr)).* = "pub const @\"".*;
                    len +%= 12;
                    @memcpy(buf[len..].ptr, dep.on_node.name);
                    len +%= dep.on_node.name.len;
                    @as(*[15]u8, @ptrCast(buf[len..].ptr)).* = "\":[:0]const u8=".*;
                    len +%= 15;
                    buf[len] = '"';
                    len +%= 1;
                    len +%= dep.on_node.impl.paths[0].formatWriteBuf(buf[len..].ptr);
                    len -%= 1;
                    @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "\";\n".*;
                    len +%= 3;
                }
            }
            @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "};\n".*;
            len +%= 3;
            for (node.impl.cfgs[0..node.impl.cfgs_len]) |cfg| {
                len +%= cfg.formatWriteBuf(buf[len..].ptr);
            }
            if (builder_spec.options.write_hist_serial) {
                var hist: types.hist_tasks.BuildCommand = types.hist_tasks.BuildCommand.convert(node.task.info.build);
                const bytes = @as(*[@sizeOf(types.hist_tasks.BuildCommand)]u8, @ptrCast(&hist));
                @as(*[31]u8, @ptrCast(buf[len..].ptr)).* = "pub const serial:[]const u8=&.{".*;
                len +%= 31;
                for (bytes) |byte| {
                    const byte_s: []const u8 = builtin.fmt.ud64(byte).readAll();
                    @memcpy(buf[len..].ptr, byte_s);
                    len +%= byte_s.len;
                    buf[len] = ',';
                    len +%= 1;
                }
                len -%= 1;
                @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "};\n".*;
                len +%= 3;
            }
            const name: [:0]const u8 = concatenate(
                allocator,
                &[2][]const u8{ node.name, builder_spec.options.extensions.zig },
            );
            const root_fd: u64 = try meta.wrap(file.createAt(create(), GlobalState.config_root_fd, name, file.mode.regular));
            file.write(write(), root_fd, buf[0..len]);
            file.close(close(), root_fd);
            node.impl.paths[1].names[1] = builder_spec.options.names.zig_build_dir;
            node.impl.paths[1].addName(allocator).* = name;
        }
        fn writeBuildContext(build_root: [:0]const u8, cache_root: [:0]const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const cache_root_fd: u64 = try meta.wrap(file.pathAt(path1(), GlobalState.build_root_fd, builder_spec.options.names.zig_build_dir));
            const context_fd: u64 = try meta.wrap(file.createAt(create(), cache_root_fd, builder_spec.options.names.config ++
                builder_spec.options.extensions.zig, file.mode.regular));
            GlobalState.config_root_fd = cache_root_fd;
            var buf: [4096 *% 8]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                "pub const zig_exe: [:0]const u8 = \"",
                "\";\npub const build_root: [:0]const u8 = \"",
                "\";\npub const cache_root: [:0]const u8 = \"",
                "\";\npub const global_cache_root: [:0]const u8 = \"",
            }, [_][]const u8{
                mach.manyToSlice80(GlobalState.args[1]),
                build_root,
                cache_root,
                mach.manyToSlice80(GlobalState.args[4]),
            }) |decl, value| {
                @memcpy(buf[len..].ptr, decl);
                len +%= decl.len;
                @memcpy(buf[len..].ptr, value);
                len +%= value.len;
            }
            @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "\";\n".*;
            len +%= 3;
            try meta.wrap(
                file.write(write(), context_fd, buf[0..len]),
            );
            try meta.wrap(
                file.close(close(), context_fd),
            );
        }
        fn writeRecord(node: *Node, job: *types.JobInfo) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var buf: [4096]u8 = undefined;
            const rcd: types.Record = types.Record.init(job, node.task.info.build);
            const names: []const [:0]const u8 = &.{ builder_spec.options.names.zig_stat_dir, node.name };
            const len: u64 = types.Path.temporary(names).formatWriteBuf(&buf) -% 1;
            const fd: u64 = try meta.wrap(file.createAt(create2(), GlobalState.build_root_fd, buf[0..len :0], file.mode.regular));
            try meta.wrap(file.writeOne(write3(), fd, rcd));
            try meta.wrap(file.close(close(), fd));
        }
        pub fn duplicate(allocator: *mem.SimpleAllocator, values: []const u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const buf: [*]u8 = @as([*]u8, @ptrFromInt(allocator.allocateRaw(values.len +% 1, 1)));
            mach.memcpy(buf, values.ptr, values.len);
            buf[values.len] = 0;
            return buf[0..values.len :0];
        }
        pub fn concatenate(allocator: *mem.SimpleAllocator, values: []const []const u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var len: u64 = 0;
            for (values) |value| len +%= value.len;
            const buf: [*]u8 = @as([*]u8, @ptrFromInt(allocator.allocateRaw(len +% 1, 1)));
            var idx: u64 = 0;
            for (values) |value| {
                mach.memcpy(buf + idx, value.ptr, value.len);
                idx +%= value.len;
            }
            buf[len] = 0;
            return buf[0..len :0];
        }
        fn makeArgPtrs(allocator: *mem.SimpleAllocator, args: [:0]u8) [][*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var count: u64 = 0;
            for (args) |value| count +%= @intFromBool(value == 0);
            const ptrs: [*][*:0]u8 = @as([*][*:0]u8, @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 1)));
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
        fn makeCommandName(allocator: *mem.SimpleAllocator, root: [:0]const u8) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const buf: [*]u8 = allocator.allocate(u8, root.len +% 1).ptr;
            mach.memcpy(buf, root.ptr, root.len);
            buf[root.len] = 0;
            var idx: u64 = 0;
            while (idx != root.len and buf[idx] != 0x2e) : (idx +%= 1) {
                buf[idx] -%= @intFromBool(buf[idx] == 0x2f);
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
                .special_s = "\x1b[38;2;54;208;224;1m",
            };

            const fancy_hl_line: bool = false;
            fn writeWaitingOn(node: *Node, arena_index: AddressSpace.Index) void {
                var buf: [4096]u8 = undefined;
                @as(*[9]u8, @ptrCast(&buf)).* = "waiting: ".*;
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
                @as(*[2]u8, @ptrCast(buf)).* = "={".*;
                var len: u64 = 2;
                mach.memcpy(buf + len, @tagName(old).ptr, @tagName(old).len);
                len +%= @tagName(old).len;
                @as(*[2]u8, @ptrCast(buf + len)).* = "=>".*;
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
            fn noExchangeNotice(node: *Node, about_s: [:0]const u8, task: types.Task, old: types.State, new: types.State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task.lock.get(task);
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
            inline fn incorrectNodeUsageError(node: *Node, msg: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [32768]u8 = undefined;
                var len: u64 = 0;
                @as(*[24]u8, @ptrCast(&buf)).* = builtin.debug.about.error_p0_s.*;
                len +%= 24;
                @memcpy(buf[len..].ptr, node.name);
                len +%= node.name.len;
                @memcpy(buf[len..].ptr, msg);
                len +%= msg.len;
            }
            fn writeArenaIndex(buf: [*]u8, arena_index: AddressSpace.Index) u64 {
                const idx_s: []const u8 = builtin.fmt.ud64(arena_index).readAll();
                @as(*[2]u8, @ptrCast(buf)).* = " [".*;
                mach.memcpy(buf + 2, idx_s.ptr, idx_s.len);
                buf[2 +% idx_s.len] = ']';
                return 3 +% idx_s.len;
            }
            fn stateNotice(node: *Node, task: types.Task) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task.lock.get(task);
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
            fn taskNotice(node: *Node, task: types.Task, arena_index: AddressSpace.Index, old_size: u64, new_size: u64, job: *types.JobInfo) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const diff_size: u64 = @max(new_size, old_size) -% @min(new_size, old_size);
                const new_size_s: []const u8 = builtin.fmt.ud64(new_size).readAll();
                const old_size_s: []const u8 = builtin.fmt.ud64(old_size).readAll();
                const diff_size_s: []const u8 = builtin.fmt.ud64(diff_size).readAll();
                const sec_s: []const u8 = builtin.fmt.ud64(job.ts.sec).readAll();
                const nsec_s: []const u8 = builtin.fmt.nsec(job.ts.nsec).readAll();
                var buf: [32768]u8 = undefined;
                const about_s: []const u8 = switch (task) {
                    else => unreachable,
                    .archive => about.ar_s,
                    .format => about.format_s,
                    .run => about.run_s,
                    .build => switch (node.task.info.build.kind) {
                        .exe => about.build_exe_s,
                        .obj => about.build_obj_s,
                        .lib => about.build_lib_s,
                    },
                };
                var len: u64 = about_s.len;
                mach.memcpy(&buf, about_s.ptr, len);
                mach.memcpy(buf[len..].ptr, node.name.ptr, node.name.len);
                len +%= node.name.len;
                @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
                len +%= 2;
                if (task == .build) {
                    const mode: builtin.Mode = node.task.info.build.mode orelse .Debug;
                    const stripped: bool = node.task.info.build.strip orelse (mode == .ReleaseSmall);
                    mach.memcpy(buf[len..].ptr, @tagName(mode).ptr, @tagName(mode).len);
                    len +%= @tagName(mode).len;
                    @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
                    len +%= 2;
                    @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = "un".*;
                    if (!stripped) len +%= 2;
                    @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = "stripped".*;
                    len +%= 8;
                    @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
                    len +%= 2;
                }
                @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = "exit=".*;
                len +%= 5;
                const exit_s: []const u8 = builtin.fmt.ud64(job.ret.sys).readAll();
                if (task == .build) {
                    var style_s: []const u8 = about.bold_s;
                    const res: UpdateAnswer = UpdateAnswer.enumFromInt(job.ret.srv);
                    const msg_s: []const u8 = @tagName(res);
                    if (res == .failed) {
                        style_s = about.red_s;
                    }
                    if (node.flags.is_special) {
                        if (res == .cached) {
                            return;
                        }
                        style_s = about.special_s;
                    }
                    buf[len] = '[';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    mach.memcpy(buf[len..].ptr, msg_s.ptr, msg_s.len);
                    len +%= msg_s.len;
                    @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = about.reset_s.*;
                    len +%= 4;
                    buf[len] = ',';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                    buf[len] = ']';
                    len +%= 1;
                } else {
                    const style_s: []const u8 = switch (job.ret.sys) {
                        builder_spec.options.system_expected_status => about.bold_s,
                        else => about.red_s,
                    };
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    mach.memcpy(buf[len..].ptr, exit_s.ptr, exit_s.len);
                    len +%= exit_s.len;
                    @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = about.reset_s.*;
                    len +%= 4;
                }
                @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
                len +%= 2;
                if (task == .build or task == .archive) {
                    if (old_size == 0) {
                        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = about.gold_s.*;
                        len +%= 5;
                        mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                        len +%= new_size_s.len;
                        buf[len] = '*';
                        len +%= 1;
                        @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = about.reset_s.*;
                        len +%= 4;
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = about.bytes_s.*;
                        len +%= 8;
                    } else if (new_size == old_size) {
                        mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                        len +%= new_size_s.len;
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = about.bytes_s.*;
                        len +%= 8;
                    } else {
                        mach.memcpy(buf[len..].ptr, old_size_s.ptr, old_size_s.len);
                        len +%= old_size_s.len;
                        buf[len] = '(';
                        len +%= 1;
                        const larger: bool = new_size > old_size;
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = (if (larger) about.red_s ++ "+" else about.green_s ++ "-").*;
                        len +%= 8;
                        mach.memcpy(buf[len..].ptr, diff_size_s.ptr, diff_size_s.len);
                        len +%= diff_size_s.len;
                        @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = about.reset_s.*;
                        len +%= 4;
                        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = ") => ".*;
                        len +%= 5;
                        mach.memcpy(buf[len..].ptr, new_size_s.ptr, new_size_s.len);
                        len +%= new_size_s.len;
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = about.bytes_s.*;
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
                        @as(*@TypeOf(about.bold_s.*), @ptrCast(buf + len)).* = about.bold_s.*;
                        len +%= about.bold_s.len;
                    },
                    .note => {
                        @as(*@TypeOf(about.grey_s.*), @ptrCast(buf + len)).* = about.grey_s.*;
                        len +%= about.grey_s.len;
                    },
                }
                const about_s: [:0]const u8 = @tagName(kind);
                mach.memcpy(buf + len, about_s.ptr, about_s.len);
                len +%= about_s.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                @as(*@TypeOf(about.bold_s.*), @ptrCast(buf + len)).* = about.bold_s.*;
                return len +% about.bold_s.len;
            }
            inline fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @as(*types.ErrorMessage, @ptrCast(extra + err_msg_idx));
                const src: *types.SourceLocation = @as(*types.SourceLocation, @ptrCast(extra + err.src_loc));
                var len: u64 = about.bold_s.len;
                @as(*[4]u8, @ptrCast(buf)).* = about.bold_s.*;
                if (err.src_loc != 0) {
                    len +%= writeSourceLocation(
                        buf + len,
                        mach.manyToSlice80(bytes + src.src_path),
                        src.line +% 1,
                        src.column +% 1,
                    );
                    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                    len +%= 2;
                }
                return len;
            }
            fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @as(*types.ErrorMessage, @ptrCast(extra + err_msg_idx));
                const src: *types.SourceLocation = @as(*types.SourceLocation, @ptrCast(extra + err.src_loc));
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
                @as(*[11]u8, @ptrCast(buf + len)).* = about.trace_s.*;
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
                @as(*[4]u8, @ptrCast(buf + len)).* = about.reset_s.*;
                return len +% 4;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
                @as(*[4]u8, @ptrCast(buf - 1)).* = about.faint_s.*;
                var len: u64 = about.faint_s.len -% 1;
                @as(*[2]u8, @ptrCast(buf + len)).* = " (".*;
                len +%= 2;
                mach.memcpy(buf + len, count_s.ptr, count_s.len);
                len +%= count_s.len;
                @as(*[7]u8, @ptrCast(buf + len)).* = " times)".*;
                len +%= 7;
                @as(*[5]u8, @ptrCast(buf + len)).* = about.new_s.*;
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
                    @as(*[about.bold_s.len]u8, @ptrCast(buf + len)).* = about.bold_s.*;
                    len +%= about.bold_s.len;
                    mach.memcpy(buf + len, line[indent..pos].ptr, before_caret);
                    len +%= before_caret;
                    @as(*[about.hi_red_s.len]u8, @ptrCast(buf + len)).* = about.hi_red_s.*;
                    len +%= about.hi_red_s.len;
                    buf[len] = line[pos];
                    len +%= 1;
                    pos = pos +% 1;
                    @as(*[about.bold_s.len]u8, @ptrCast(buf + len)).* = about.bold_s.*;
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
                @as(*@TypeOf(about.hi_green_s.*), @ptrCast(buf + len)).* = about.hi_green_s.*;
                len +%= about.hi_green_s.len;
                mach.memset(buf + len, '~', before_caret);
                len +%= before_caret;
                buf[len] = '^';
                len +%= 1;
                mach.memset(buf + len, '~', after_caret);
                len +%= after_caret;
                @as(*[5]u8, @ptrCast(buf + len)).* = about.new_s.*;
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
                @as(*[5]u8, @ptrCast(buf + len)).* = about.new_s.*;
                return len +% about.new_s.len;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: u64, ref_len: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ref_idx: u64 = start +% types.SourceLocation.len;
                var idx: u64 = 0;
                var len: u64 = 0;
                @as(*@TypeOf(about.trace_s.*), @ptrCast(buf + len)).* = about.trace_s.*;
                len +%= about.trace_s.len;
                @as(*[15]u8, @ptrCast(buf + len)).* = "referenced by:\n".*;
                len +%= 15;
                while (idx != ref_len) : (idx +%= 1) {
                    const ref_trc: *types.ReferenceTrace = @as(*types.ReferenceTrace, @ptrCast(extra + ref_idx));
                    if (ref_trc.src_loc != 0) {
                        const ref_src: *types.SourceLocation = @as(*types.SourceLocation, @ptrCast(extra + ref_trc.src_loc));
                        const src_file: [:0]u8 = mach.manyToSlice80(bytes + ref_src.src_path);
                        const decl_name: [:0]u8 = mach.manyToSlice80(bytes + ref_trc.decl_name);
                        mach.memset(buf + len, ' ', 4);
                        len +%= 4;
                        mach.memcpy(buf + len, decl_name.ptr, decl_name.len);
                        len +%= decl_name.len;
                        @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                        len +%= 2;
                        len +%= writeSourceLocation(buf + len, src_file, ref_src.line +% 1, ref_src.column +% 1);
                        buf[len] = '\n';
                        len +%= 1;
                    }
                    ref_idx +%= types.ReferenceTrace.len;
                }
                @as(*[5]u8, @ptrCast(buf + len)).* = about.new_s.*;
                return len +% 5;
            }
            fn writeErrors(allocator: *mem.SimpleAllocator, ptrs: MessagePtrs) void {
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
            fn lengthAndWalkInternal(len1: u64, node: *const Node, name_width: *u64, root_width: *u64) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var deps_idx: u64 = 0;
                while (deps_idx != node.impl.deps_len) : (deps_idx +%= 1) {
                    const dep_node: *Node = node.impl.deps[deps_idx].on_node;
                    if (dep_node == node or
                        builder_spec.options.hide_special and dep_node.flags.is_special)
                    {
                        continue;
                    }
                    if (dep_node.impl.paths_len != 0) {
                        lengthSubNode(len1 +% 2, dep_node, name_width, root_width);
                    }
                    lengthAndWalkInternal(len1 +% 2, dep_node, name_width, root_width);
                }
            }
            fn lengthSubNode(len1: u64, sub_node: *const Node, name_width: *u64, root_width: *u64) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                name_width.* = @max(name_width.*, sub_node.name.len +% len1);
                const input: [:0]const u8 = sub_node.impl.paths[@intFromBool(sub_node.task.tag == .build)].names[1];
                if (input.len != 0) {
                    if (sub_node.descr.len != 0) {
                        root_width.* = @max(root_width.*, input.len);
                    }
                }
            }
            fn lengthToplevelCommandNotice(len1: u64, node: *const Node, name_width: *u64, root_width: *u64) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (node.impl.paths_len != 0) {
                    lengthSubNode(len1, node, name_width, root_width);
                }
                lengthAndWalkInternal(len1, node, name_width, root_width);
                for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
                    if (sub_node == node or
                        sub_node.flags.is_hidden or
                        builder_spec.options.hide_special and sub_node.flags.is_special)
                    {
                        continue;
                    }
                    if (sub_node.flags.is_hidden and sub_node.impl.paths_len != 0) {
                        lengthSubNode(len1 +% 4, sub_node, name_width, root_width);
                    }
                    lengthToplevelCommandNotice(len1 +% 2, sub_node, name_width, root_width);
                }
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: u64, buf1: [*]u8, len1: u64, node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = len0;
                var fin: *u8 = &buf0[0];
                var deps_idx: u64 = 0;
                while (deps_idx != node.impl.deps_len) : (deps_idx +%= 1) {
                    const dep_node: *Node = node.impl.deps[deps_idx].on_node;
                    if (dep_node == node or
                        builder_spec.options.hide_special and dep_node.flags.is_special)
                    {
                        continue;
                    }
                    const is_last: bool = deps_idx == node.impl.deps_len -% 1;
                    const is_only: bool = dep_node.impl.deps_len == 0;
                    mach.memcpy(buf1 + len1, if (is_last) "  " else "| ", 2);
                    buf0[len] = '\n';
                    len +%= 1;
                    mach.memcpy(buf0 + len, buf1, len1);
                    len +%= len1;
                    fin = &buf0[len];
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = "|-".*;
                    len +%= 2;
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (is_only) "> ".* else "+ ".*;
                    len +%= 2;
                    mach.memcpy(buf0 + len, dep_node.name.ptr, dep_node.name.len);
                    len +%= dep_node.name.len;
                    if (dep_node.flags.is_hidden and dep_node.impl.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 2, dep_node, name_width, root_width);
                    }
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep_node, name_width, root_width);
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return len;
            }
            fn writeSubNode(buf0: [*]u8, len1: u64, sub_node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = 0;
                var count: u64 = name_width -% (sub_node.name.len +% len1);
                const input: [:0]const u8 = sub_node.impl.paths[@intFromBool(sub_node.task.tag == .build)].names[1];
                if (input.len != 0) {
                    mach.memset(buf0 + len, ' ', count);
                    len +%= count;
                    @memcpy(buf0 + len, input);
                    len +%= input.len;
                    if (sub_node.descr.len != 0) {
                        count = root_width -% input.len;
                        mach.memset(buf0 + len, ' ', count);
                        len +%= count;
                        @memcpy(buf0 + len, sub_node.descr);
                        len +%= sub_node.descr.len;
                    }
                }
                return len;
            }
            fn writeToplevelCommandNotice(buf0: [*]u8, buf1: [*]u8, len1: u64, node: *const Node, name_width: u64, root_width: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: u64 = 0;
                var fin: *u8 = &buf0[0];
                if (node.impl.paths_len != 0) {
                    len +%= writeSubNode(buf0 + len, len1, node, name_width, root_width);
                }
                @as(*[4]u8, @ptrCast(buf0 + len)).* = about.faint_s.*;
                len +%= about.faint_s.len;
                len = writeAndWalkInternal(buf0, len, buf1, len1, node, name_width, root_width);
                @as(*[4]u8, @ptrCast(buf0 + len)).* = about.reset_s.*;
                len +%= about.reset_s.len;
                for (node.impl.nodes[0..node.impl.nodes_len], 0..) |sub_node, nodes_idx| {
                    if (sub_node == node or sub_node.flags.is_hidden or
                        builder_spec.options.hide_special and sub_node.flags.is_special)
                    {
                        continue;
                    }
                    const is_only: bool = sub_node.impl.nodes_len == 0;
                    @as(*[2]u8, @ptrCast(buf1 + len1)).* = if (nodes_idx == node.impl.nodes_len -% 1 or len1 == 0) "  ".* else "| ".*;
                    buf0[len] = '\n';
                    len +%= 1;
                    @memcpy(buf0 + len, buf1[0..len1]);
                    len +%= len1;
                    fin = &buf0[len];
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (len1 == 0) "  ".* else "|-".*;
                    len +%= 2;
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (is_only) "- ".* else "o ".*;
                    len +%= 2;
                    if (sub_node.flags.is_hidden and sub_node.impl.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 4, sub_node, name_width, root_width);
                    }
                    @memcpy(buf0 + len, sub_node.name);
                    len +%= sub_node.name.len;
                    len +%= writeToplevelCommandNotice(buf0 + len, buf1, len1 +% 2, sub_node, name_width, root_width);
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return len;
            }
            fn toplevelCommandNotice(allocator: *mem.SimpleAllocator, toplevel: *const Node) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: u64 = allocator.next;
                defer allocator.next = save;
                var name_width: u64 = 0;
                var root_width: u64 = 0;
                const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
                var len0: u64 = toplevel.name.len;
                const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
                @memcpy(buf0, toplevel.name);
                lengthToplevelCommandNotice(0, toplevel, &name_width, &root_width);
                name_width +%= 4;
                name_width &= ~@as(u64, 3);
                root_width +%= 4;
                root_width &= ~@as(u64, 3);
                len0 +%= writeToplevelCommandNotice(buf0 + len0, buf1, 0, toplevel, name_width, root_width);
                buf0[len0] = '\n';
                len0 +%= 1;
                builtin.debug.write(buf0[0..len0]);
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
        const pathname: [:0]const u8 = @src().file;
        var idx: u64 = pathname.len -% 1;
        while (pathname[idx] != '/') {
            idx -%= 1;
        }
        idx -%= 1;
        while (pathname[idx] != '/') {
            idx -%= 1;
            if (idx == 0) break;
        }
        if (idx == 0) {
            return ".";
        }
        return pathname[0..idx] ++ [0:0]u8{};
    }
}
