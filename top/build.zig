const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const elf = @import("./elf.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
const virtual = @import("./virtual.zig");
const types = @import("./build/types.zig");
const build = @This();
pub usingnamespace types;
pub usingnamespace struct {
    /// Arguments after principal arguments, i.e. argv[5..]
    pub var args: [][*:0]u8 = undefined;
    /// Environment variables
    pub var vars: [][*:0]u8 = undefined;
    /// File system path of Zig executable.
    pub var zig_exe: [:0]u8 = undefined;
    /// File system path of directory containing build.zig.
    pub var build_root: [:0]u8 = undefined;
    /// File system path of package special cache directory.
    pub var cache_root: [:0]u8 = undefined;
    /// File system path of user login cache directory.
    pub var global_cache_root: [:0]u8 = undefined;
    /// File descriptor for directory containing `build.zig`
    pub var build_root_fd: u64 = undefined;
    /// File descriptor for directory containing build configuration root source files.
    pub var config_root_fd: u64 = undefined;
    /// File descriptor for directory containing build task output files.
    pub var output_root_fd: u64 = undefined;
    var cmd_idx: usize = undefined;
    var task_idx: usize = undefined;
    var error_count: u8 = undefined;
    /// File system path to the project root of zig_lib
    pub const root: [:0]const u8 = libraryRoot();
};
pub const BuilderSpec = struct {
    /// Builder options
    options: Options = .{},
    /// Logging for system calls called by the builder.
    logging: Logging = .{},
    /// Errors for system calls called by builder. This excludes `clone3`,
    /// which must be implemented in assembly.
    errors: Errors = .{},
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// Bytes allowed per thread arena (dynamic maximum)
        arena_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (static maximum)
        stack_aligned_bytes: usize = 8 * 1024 * 1024,
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u8 = 8,
        /// Allow this many errors before exiting the thread group.
        /// A value of `null` will attempt to report all errors and exit from main.
        max_error_count: ?u8 = 0,
        /// Lowest allocated byte address for thread stacks. This field and the
        /// two previous fields derive the arena lowest allocated byte address,
        /// as this is the first unallocated byte address of the thread space.
        stack_lb_addr: usize = 0x700000000000,
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
        max_cmdline_len: ?usize = 65536,
        /// Assert no command line exceeds this number of individual arguments.
        max_cmdline_args: ?usize = 1024,
        /// Time slept in nanoseconds between dependency scans.
        sleep_nanoseconds: usize = 50000,
        /// Time in milliseconds allowed per build node.
        timeout_milliseconds: usize = 1000 * 60 * 60 * 24,
        /// Enables logging for tasks waiting on dependencies.
        show_waiting_tasks: bool = false,
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
            trace_root: [:0]const u8 = build.root ++ "/top/trace.zig",
            /// Optional pathname to root source used to compile command line parser shared object.
            parse_root: [:0]const u8 = build.root ++ "/top/build/parsers.zig",
        } = .{},
        special: struct {
            /// Defines formatter type used to pass configuration values to program.
            Config: type = types.Config,
            /// Defines generid command type used to pass function pointers to node.
            Command: ?type = null,
            /// Defines compile commands for stack tracer object.
            trace: ?types.BuildCommand = .{ .kind = .obj, .mode = .ReleaseSmall, .strip = true },
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
        state: debug.Logging.AttemptSuccessFault = .{},
        /// Report completion of tasks with summary of results:
        ///     Attempt => When the task was unable to complete due to a
        ///                dependency.
        ///     Success => When the task completes without any errors.
        ///     Error   => When the task completes with errors.
        stats: debug.Logging.SuccessError = .{},
        /// Report `open` Acquire and Error.
        open: debug.Logging.AcquireError = .{},
        /// Report `close` Release and Error.
        close: debug.Logging.ReleaseError = .{},
        /// Report `create` Acquire and Error.
        create: debug.Logging.AcquireError = .{},
        /// Report `dup3` Success and Error.
        dup3: debug.Logging.SuccessError = .{},
        /// Report `execve` Success and Error.
        execve: debug.Logging.AttemptError = .{},
        /// Report `fork` Attempt and Error.
        fork: debug.Logging.SuccessError = .{},
        /// Report `map` Success and Error.
        map: debug.Logging.AcquireError = .{},
        /// Report `mkdir` Success and Error.
        mkdir: debug.Logging.SuccessError = .{},
        /// Report `mknod` Success and Error.
        mknod: debug.Logging.SuccessError = .{},
        /// Report `path` Success and Error.
        path: debug.Logging.AcquireError = .{},
        /// Report `pipe` Success and Error.
        pipe: debug.Logging.AcquireError = .{},
        /// Report `waitpid` Success and Error.
        waitpid: debug.Logging.SuccessError = .{},
        /// Report `read` Success and Error.
        read: debug.Logging.SuccessError = .{},
        /// Report `unmap` Release and Error.
        unmap: debug.Logging.ReleaseError = .{},
        /// Report `write` Success and Error.
        write: debug.Logging.SuccessError = .{},
        /// Report `stat` Success and Error.
        stat: debug.Logging.SuccessErrorFault = .{},
        /// Report `poll` Success and Error.
        poll: debug.Logging.AttemptSuccessError = .{},
        /// Report `link` Success and Error.
        link: debug.Logging.SuccessError = .{},
        /// Report `unlink` Success and Error.
        unlink: debug.Logging.SuccessError = .{},
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
    // Enables `zig build-(exe|obj|lib)` commands.
    comptime var do_build: bool = false;
    // Enables `zig fmt` commands.
    comptime var do_format: bool = false;
    // Enables `zig ar` commands.
    comptime var do_archive: bool = false;
    // Enables `zig objcopy` commands.
    comptime var do_objcopy: bool = false;
    // Enables logic to check for hid
    const maybe_hide: bool =
        builder_spec.options.hide_based_on_name_prefix != null or
        builder_spec.options.hide_based_on_group;
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
                do_configure: bool = false,
                /// Builder will unconditionally add `trace` object to
                /// compile command.
                add_stack_traces: bool = false,
                /// Only meaningful when zig lib is not acting as standard.
                add_zig_lib_rt: bool = false,
                /// Define the compiler path, build root, cache root, and global
                /// cache root as declarations to the build configuration root.
                add_build_context: bool = true,
            };
        },
        impl: packed struct {
            args: [*][*:0]u8,
            paths: [*]types.Path,
            nodes: [*]*Node,
            deps: [*]Dependency,
            cfgs: [*]Config,
            nodes_max_len: Size,
            nodes_len: Size,
            deps_max_len: Size,
            deps_len: Size,
            cfgs_max_len: Size,
            cfgs_len: Size,
            args_max_len: Size,
            args_len: Size,
            paths_max_len: Size,
            paths_len: Size,
            wait_len: usize,
            wait_tick: usize,
        },
        const Node = @This();
        const Size = usize;
        const Task = extern struct {
            tag: types.Task,
            lock: types.Lock,
            info: Info,
            const Info = extern union {
                build: *types.BuildCommand,
                format: *types.FormatCommand,
                archive: *types.ArchiveCommand,
                objcopy: *types.ObjcopyCommand,
            };
        };
        const special = struct {
            pub var toplevel: *Node = undefined;
            pub var trace: *Node = undefined;
            pub var parse: *Node = undefined;
            pub var parsers: build.ParseCommand = undefined;
        };
        pub const specification: BuilderSpec = builder_spec;
        pub const max_thread_count: u64 =
            builder_spec.options.max_thread_count;
        pub const stack_aligned_bytes: u64 =
            builder_spec.options.stack_aligned_bytes;
        pub const Config = builder_spec.options.special.Config;
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
            const ret: *types.Path = @ptrFromInt(allocator.addGenericSize(Size, size_of, //
                init_len.paths, addr_buf, &node.impl.paths_max_len, node.impl.paths_len));
            node.impl.paths_len +%= 1;
            return ret;
        }
        fn addNode(node: *Node, allocator: *mem.SimpleAllocator) **Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(*Node);
            const addr_buf: *u64 = @ptrCast(&node.impl.nodes);
            const ret: **Node = @ptrFromInt(allocator.addGenericSize(Size, size_of, //
                init_len.nodes, addr_buf, &node.impl.nodes_max_len, node.impl.nodes_len));
            node.impl.nodes_len +%= 1;
            return ret;
        }
        fn addDep(node: *Node, allocator: *mem.SimpleAllocator) *Dependency {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(Dependency);
            const addr_buf: *u64 = @ptrCast(&node.impl.deps);
            const ret: *Dependency = @ptrFromInt(allocator.addGenericSize(Size, size_of, //
                init_len.deps, addr_buf, &node.impl.deps_max_len, node.impl.deps_len));
            node.impl.deps_len +%= 1;
            mem.zero(Dependency, ret);
            return ret;
        }
        fn addArg(node: *Node, allocator: *mem.SimpleAllocator) *[*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {
                debug.assert(node.tag == .worker and (node.task.tag == .build or node.task.tag == .run));
            }
            const size_of: comptime_int = @sizeOf([*:0]u8);
            const addr_buf: *u64 = @ptrCast(&node.impl.args);
            const ret: *[*:0]u8 = @ptrFromInt(allocator.addGenericSize(Size, size_of, //
                init_len.args, addr_buf, &node.impl.args_max_len, node.impl.args_len));
            node.impl.args_len +%= 1;
            return ret;
        }
        /// Add constant declaration to build configuration.
        /// `node` must be `build-exe` worker.
        pub fn addConfig(node: *Node, allocator: *mem.SimpleAllocator, name: [:0]const u8, value: Config.Value) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {
                debug.assert(node.tag == .worker and node.task.tag == .build);
            }
            const size_of: comptime_int = @sizeOf(Config);
            const addr_buf: *u64 = @ptrCast(&node.impl.cfgs);
            const ptr: *Config = @ptrFromInt(allocator.addGenericSize(Size, size_of, //
                init_len.cfgs, addr_buf, &node.impl.cfgs_max_len, node.impl.cfgs_len));
            ptr.* = .{ .name = name, .value = value };
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
                build.zig_exe,    build.build_root,
                build.cache_root, build.global_cache_root,
            }) |arg| {
                node.addArg(allocator).* = arg;
            }
        }
        fn makeRootDirectory(root_fd: u64, name: [:0]const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var st: file.Status = undefined;
            var rc: u64 = sys.call_noexcept(.mkdirat, u64, .{ root_fd, @intFromPtr(name.ptr), @as(u16, @bitCast(file.mode.directory)) });
            if (rc == 0) {
                return;
            }
            rc = sys.call_noexcept(.newfstatat, u64, .{ root_fd, @intFromPtr(name.ptr), @intFromPtr(&st), 0 });
            if (rc != 0) {
                proc.exitErrorFault(error.NoSuchFileOrDirectory, name, 2);
            }
            if (st.mode.kind != .directory) {
                proc.exitErrorFault(error.NotADirectory, name, 2);
            }
        }
        fn maybeHide(toplevel: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.hide_based_on_name_prefix) |prefix| {
                node.flags.is_hidden = prefix == node.name[0];
                return;
            }
            if (builder_spec.options.hide_based_on_group) {
                node.flags.is_hidden = toplevel.options.is_hidden;
                return;
            }
        }
        fn loadAll(comptime Pointers: type, pathname: [:0]const u8) Pointers {
            @setRuntimeSafety(builtin.is_safe);
            const prot: file.Map.Protection = .{ .exec = true };
            const flags: file.Map.Flags = .{};
            var addr: usize = 0x80000000;
            var st: file.Status = undefined;
            const fd: u64 = sys.call_noexcept(.open, u64, .{ @intFromPtr(pathname.ptr), 0, 0 });
            if (fd > 1024) {
                proc.exitErrorFault(error.NoSuchFileOrDirectory, pathname, 2);
            }
            sys.call_noexcept(.fstat, void, .{ fd, @intFromPtr(&st) });
            const len: usize = mach.alignA64(st.size, 4096);
            const rc_addr1: usize = sys.call_noexcept(.mmap, usize, [6]usize{ addr, len, @bitCast(prot), @bitCast(flags), fd, 0 });
            if (rc_addr1 != addr) {
                proc.exitErrorFault(error.OutOfMemory, pathname, 2);
            }
            const elf_info: elf.ElfInfo = elf.ElfInfo.init(addr);
            addr +%= elf_info.executableOffset();
            const rc_addr2: usize = sys.call_noexcept(.mmap, usize, [6]usize{ addr, len, @bitCast(prot), @bitCast(flags), fd, 0 });
            if (rc_addr2 != addr) {
                proc.exitErrorFault(error.OutOfMemory, pathname, 2);
            }
            return elf_info.loadAll(Pointers);
        }
        pub fn initSpecialNodes(allocator: *mem.SimpleAllocator, toplevel: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.special.trace) |build_cmd| {
                const node: *Node = toplevel.addBuild(allocator, build_cmd, "trace", builder_spec.options.names.trace_root);
                node.flags.is_special = true;
                node.flags.build.do_configure = false;
                special.trace = node;
            }
            if (builder_spec.options.special.parse) |build_cmd| {
                const node: *Node = toplevel.addBuild(allocator, build_cmd, "parse", builder_spec.options.names.parse_root);
                node.flags.is_special = true;
                node.flags.build.do_configure = false;
                special.parse = node;
            }
        }
        pub fn initState(args: [][*:0]u8, vars: [][*:0]u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            build.args = args;
            build.vars = vars;
            build.zig_exe = mach.manyToSlice80(args[1]);
            build.build_root = mach.manyToSlice80(args[2]);
            build.cache_root = mach.manyToSlice80(args[3]);
            build.global_cache_root = mach.manyToSlice80(args[4]);
            build.build_root_fd = try meta.wrap(file.path(path1(), build.build_root));
            for ([3][:0]const u8{
                builder_spec.options.names.zig_out_dir,
                builder_spec.options.names.zig_build_dir,
                builder_spec.options.names.zig_stat_dir,
            }) |name| {
                makeRootDirectory(build.build_root_fd, name);
            }
            build.config_root_fd = try meta.wrap(file.pathAt(path1(), build.build_root_fd, builder_spec.options.names.zig_build_dir));
            build.output_root_fd = try meta.wrap(file.pathAt(path1(), build.build_root_fd, builder_spec.options.names.zig_out_dir));
            for ([3][:0]const u8{
                builder_spec.options.names.exe_out_dir,
                builder_spec.options.names.lib_out_dir,
                builder_spec.options.names.aux_out_dir,
            }) |name| {
                makeRootDirectory(build.output_root_fd, name);
            }
            build.cmd_idx = 5;
            build.task_idx = 5;
            build.error_count = 0;
        }
        /// Initialize a toplevel node.
        pub fn init(allocator: *mem.SimpleAllocator) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);

            node.flags = .{};
            node.name = duplicate(allocator, builder_spec.options.names.toplevel_node);
            node.tag = .group;
            node.impl.args = build.args.ptr;
            node.impl.args_max_len = build.args.len;
            node.impl.args_len = build.args.len;
            node.task.tag = .any;
            node.task.lock = omni_lock;

            mem.map(map(), .{}, .{}, stack_lb_addr, stack_aligned_bytes * max_thread_count);
            return node;
        }
        /// Initialize a new group command
        pub fn addGroup(toplevel: *Node, allocator: *mem.SimpleAllocator, name: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            toplevel.addNode(allocator).* = node;

            node.tag = .group;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.flags.is_hidden = name[0] == '_';
            node.task.tag = .any;
            node.task.lock = omni_lock;

            return node;
        }
        /// Initialize a new `zig fmt` command.
        pub fn addFormat(toplevel: *Node, allocator: *mem.SimpleAllocator, format_cmd: types.FormatCommand, name: []const u8, pathname: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            comptime do_format = true;
            const node: *Node = allocator.create(Node);
            const target_path: *types.Path = node.addPath(allocator);
            toplevel.addNode(allocator).* = node;

            node.tag = .worker;
            node.task.tag = .format;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.info.format = allocator.create(types.FormatCommand);
            node.task.info.format.* = format_cmd;

            target_path.addName(allocator).* = build.build_root;
            target_path.names_len -%= if (pathname[0] == '/') 1 else 0;
            target_path.addName(allocator).* = duplicate(allocator, pathname);

            initializeCommand(allocator, toplevel, node);
            return node;
        }
        /// Initialize a new `zig ar` command.
        pub fn addArchive(toplevel: *Node, allocator: *mem.SimpleAllocator, archive_cmd: types.ArchiveCommand, name: []const u8, deps: []const *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            const archive_path: *types.Path = node.addPath(allocator);
            comptime do_archive = true;
            toplevel.addNode(allocator).* = node;

            node.tag = .worker;
            node.task.tag = .archive;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.info.archive = allocator.create(types.ArchiveCommand);
            node.task.info.archive.* = archive_cmd;

            archive_path.addName(allocator).* = build.build_root;
            archive_path.addName(allocator).* = archiveRelative(allocator, node.name);

            for (deps) |dep| {
                node.dependOnObject(allocator, dep);
            }
            initializeCommand(allocator, toplevel, node);
            return node;
        }
        pub fn addBuild(toplevel: *Node, allocator: *mem.SimpleAllocator, build_cmd: types.BuildCommand, name: []const u8, root: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            const binary_path: *types.Path = node.addPath(allocator);
            const root_path: *types.Path = node.addPath(allocator);
            comptime do_build = true;
            toplevel.addNode(allocator).* = node;

            node.tag = .worker;
            node.task.tag = .build;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.info.build = allocator.create(types.BuildCommand);
            node.task.info.build.* = build_cmd;

            binary_path.addName(allocator).* = build.build_root;
            binary_path.addName(allocator).* = binaryRelative(allocator, node.name, build_cmd.kind);

            root_path.addName(allocator).* = build.build_root;
            root_path.names_len -%= if (root[0] == '/') 1 else 0;
            root_path.addName(allocator).* = duplicate(allocator, root);

            initializeCommand(allocator, toplevel, node);
            return node;
        }
        pub fn addObjcopy(toplevel: *Node, allocator: *mem.SimpleAllocator, objcopy_cmd: types.ObjcopyCommand, name: []const u8, holder: *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = allocator.create(Node);
            comptime do_objcopy = true;
            toplevel.addNode(allocator).* = node;

            node.tag = .worker;
            node.task.tag = .build;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.addPath(allocator).* = holder.paths[0];
            node.task.info.objcopy = allocator.create(types.ObjcopyCommand);
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
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = toplevel.addGroup(allocator, name);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig fmt` command with description.
        pub fn addFormatWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            format_cmd: types.FormatCommand,
            name: []const u8,
            pathname: []const u8,
            descr: [:0]const u8,
        ) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = toplevel.addFormat(allocator, format_cmd, name, pathname);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig ar` command with description.
        pub fn addArchiveWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            archive_cmd: types.ArchiveCommand,
            name: []const u8,
            deps: []const *Node,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = toplevel.addArchive(allocator, archive_cmd, name, deps);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig build-*` command with description.
        pub fn addBuildWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            build_cmd: types.BuildCommand,
            name: []const u8,
            root: []const u8,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = toplevel.addBuild(allocator, build_cmd, name, root);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig objcopy` command with description.
        pub fn addObjcopyWithDescr(
            toplevel: *Node,
            allocator: *mem.SimpleAllocator,
            objcopy_cmd: types.ObjcopyCommand,
            name: []const u8,
            holder: *Node,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
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
                        node.task.info.build.main_pkg_path = build.build_root;
                    }
                    node.task.lock = obj_lock;
                    if (node.task.info.build.kind == .exe and
                        builder_spec.options.add_run_to_executables)
                    {
                        node.task.lock = exe_lock;
                        node.dependOnSelfExe(allocator);
                    }
                    if (testExtension(
                        node.impl.paths[1].relative(),
                        builder_spec.options.extensions.zig,
                    )) {
                        node.flags.build.do_configure = true;
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
        fn updateCommand(allocator: *mem.SimpleAllocator, _: *Node, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.flags.do_update = false;
            if (node.tag == .worker) {
                if (node.task.tag == .build) {
                    if (node.flags.build.do_configure) {
                        node.addConfig(allocator, "zig_exe", .{ .String = build.zig_exe });
                        node.addConfig(allocator, "build_root", .{ .String = build.build_root });
                        node.addConfig(allocator, "cache_root", .{ .String = build.cache_root });
                        node.addConfig(allocator, "global_cache_root", .{ .String = build.global_cache_root });
                        if (defaultAddStackTracesCriteria(node.task.info.build) or
                            node.flags.build.add_stack_traces)
                        {
                            node.addConfig(allocator, "have_stack_traces", .{ .Bool = true });
                            node.dependOnObject(allocator, special.trace);
                        }
                    }
                }
            }
        }
        fn defaultAddStackTracesCriteria(build_cmd: *types.BuildCommand) bool {
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
        pub fn addBuildAnon(toplevel: *Node, allocator: *mem.SimpleAllocator, build_cmd: types.BuildCommand, root: [:0]const u8) !*Node {
            return toplevel.addBuild(allocator, build_cmd, makeCommandName(allocator, root), root);
        }
        pub fn dependOn(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node, on_task: ?types.Task) void {
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = on_task orelse on_node.task.tag, .on_state = .finished };
        }
        /// Must be worker.(archive|build)
        pub fn dependOnObject(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.impl.paths[0];
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = .build, .on_state = .finished };
        }
        /// Must be worker.archive
        pub fn dependOnArchive(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node) void {
            node.addPath(allocator).* = on_node.impl.paths[0];
            node.addDep(allocator).* = .{ .task = node.task.tag, .on_node = on_node, .on_task = .archive, .on_state = .finished };
        }
        /// Must be worker.build
        fn dependOnSelfExe(node: *Node, allocator: *mem.SimpleAllocator) void {
            node.addArg(allocator).* = node.impl.paths[0].concatenate(allocator);
            node.addDep(allocator).* = .{ .task = .run, .on_node = node, .on_task = .build, .on_state = .finished };
        }
        pub const impl = struct {
            fn install(_: *Node, src_pathname: [:0]u8, dest_pathname: [:0]const u8) void {
                file.unlink(unlink(), dest_pathname);
                file.link(link(), src_pathname, dest_pathname);
            }
            fn clientLoop(allocator: *mem.SimpleAllocator, node: *Node, job: *types.JobInfo, out: file.Pipe, dest_pathname: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const header: *types.Message.ServerHeader = allocator.create(types.Message.ServerHeader);
                const save: u64 = allocator.next;
                var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
                while (try meta.wrap(file.pollOne(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                    try meta.wrap(file.readOne(read3(), out.read, header));
                    const ptrs: MessagePtrs = .{ .msg = allocator.allocateAligned(u8, header.bytes_len +% 64, 4).ptr };
                    mach.memset(ptrs.msg, 0, header.bytes_len +% 1);
                    var len: usize = 0;
                    while (len != header.bytes_len) {
                        len +%= try meta.wrap(file.read(read2(), out.read, ptrs.msg[len..header.bytes_len]));
                    }
                    if (header.tag == .emit_bin_path) break {
                        job.ret.srv = ptrs.msg[0];
                        install(node, mach.manyToSlice80(ptrs.str + 1), dest_pathname);
                    };
                    if (header.tag == .error_bundle) break {
                        job.ret.srv = builder_spec.options.compiler_error_status;
                        about.writeErrors(allocator, ptrs);
                    };
                    fd.actual = .{};
                    allocator.next = save;
                }
            }
            fn system(args: [][*:0]u8, job: *types.JobInfo) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const exe: [:0]const u8 = mach.manyToSlice80(args[0]);
                job.ts = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(file.execPath(execve(), exe, args, build.vars));
                }
                const ret: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                job.ts = time.diff(try meta.wrap(time.get(clock(), .realtime)), job.ts);
                job.ret.sys = proc.Status.exit(ret.status);
            }
            fn server(allocator: *mem.SimpleAllocator, node: *Node, args: [][*:0]u8, job: *types.JobInfo, dest_pathname: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const in: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                const out: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                job.ts = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(openChild(in, out));
                    try meta.wrap(file.execPath(execve(), build.zig_exe, args, build.vars));
                }
                try meta.wrap(openParent(in, out));
                try meta.wrap(file.write(write2(), in.write, &update_exit_message));
                try meta.wrap(clientLoop(allocator, node, job, out, dest_pathname));
                const rc: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                job.ts = time.diff(try meta.wrap(time.get(clock(), .realtime)), job.ts);
                job.ret.sys = proc.Status.exit(rc.status);
                try meta.wrap(file.close(close(), in.write));
                try meta.wrap(file.close(close(), out.read));
            }
            fn buildWrite(allocator: *mem.SimpleAllocator, cmd: *types.BuildCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(build.zig_exe, obj_paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(build.zig_exe, obj_paths, buf);
                return buf[0..len :0];
            }
            fn objcopyWrite(allocator: *mem.SimpleAllocator, cmd: *types.ObjcopyCommand, obj_path: types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(build.zig_exe, obj_path);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(build.zig_exe, obj_path, buf);
                return buf[0..len :0];
            }
            fn archiveWrite(allocator: *mem.SimpleAllocator, cmd: *types.ArchiveCommand, obj_paths: []const types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(build.zig_exe, obj_paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(build.zig_exe, obj_paths, buf);
                return buf[0..len :0];
            }
            fn formatWrite(allocator: *mem.SimpleAllocator, cmd: *types.FormatCommand, root_path: types.Path) [:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(build.zig_exe, root_path);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(build.zig_exe, root_path, buf);
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (do_build and task == .build) {
                    node.task.info.build.formatParseArgs(allocator, build.args[build.cmd_idx..build.task_idx]);
                    return makeArgPtrs(allocator, try meta.wrap(buildWrite(allocator, node.task.info.build, node.impl.paths[1..node.impl.paths_len])));
                }
                if (do_format and task == .format) {
                    return makeArgPtrs(allocator, try meta.wrap(formatWrite(allocator, node.task.info.format, node.impl.paths[0])));
                }
                if (do_archive and task == .archive) {
                    return makeArgPtrs(allocator, try meta.wrap(archiveWrite(allocator, node.task.info.archive, node.impl.paths[0..node.impl.paths_len])));
                }
                if (do_objcopy and task == .objcopy) {
                    return makeArgPtrs(allocator, try meta.wrap(objcopyWrite(allocator, node.task.info.objcopy, node.impl.paths[1])));
                }
                if (task == .run) {
                    return runWrite(allocator, node, build.args[toplevel.impl.args_len..toplevel.impl.args_max_len]);
                }
                proc.exitError(error.InvalidTask, 2);
            }
            fn executeCommandInternal(toplevel: *const Node, allocator: *mem.SimpleAllocator, node: *Node, task: types.Task, arena_index: u64) bool {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const job: *types.JobInfo = allocator.create(types.JobInfo);
                var old_size: u64 = 0;
                var new_size: u64 = 0;
                if (builder_spec.options.enable_build_configuration and
                    node.flags.build.do_configure and
                    task == .build)
                {
                    writeConfigRoot(allocator, node);
                }
                const args: [][*:0]u8 = taskArgs(allocator, toplevel, node, task);
                switch (task) {
                    .build, .archive => {
                        const name: [:0]const u8 = node.impl.paths[0].names[1];
                        if (0 == sys.call_noexcept(.newfstatat, u64, .{
                            build.build_root_fd, @intFromPtr(name.ptr), @intFromPtr(&job.st), 0,
                        })) {
                            old_size = job.st.size;
                        }
                        if (task == .build) {
                            try meta.wrap(impl.server(allocator, node, args, job, name));
                        } else {
                            try meta.wrap(impl.system(args, job));
                        }
                        if (0 == sys.call_noexcept(.newfstatat, u64, .{
                            build.build_root_fd, @intFromPtr(name.ptr), @intFromPtr(&job.st), 0,
                        })) {
                            new_size = job.st.size;
                        }
                    },
                    else => try meta.wrap(impl.system(args, job)),
                }
                if (builder_spec.options.write_build_task_record and keepGoing() and
                    task == .build)
                {
                    writeRecord(node, job);
                }
                if (builder_spec.options.show_stats and keepGoing()) {
                    about.taskNotice(node, task, arena_index, old_size, new_size, job);
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
                    if (keepGoing() and sub_node.exchange(task, .ready, .blocking, max_thread_count)) {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, sub_node, task));
                    }
                }
                for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                    if (dep.on_node == node and dep.on_task == task) {
                        continue;
                    }
                    if (keepGoing() and dep.on_node.exchange(dep.on_task, .ready, .blocking, max_thread_count)) {
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
                stack_len: usize,
            ) void;
            comptime {
                asm (@embedFile("./build/forwardToExecuteCloneThreaded4.s"));
            }
            const count_errors: bool = builder_spec.options.max_error_count != null;
            pub export fn executeCommandThreaded(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                toplevel: *const Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (max_thread_count == 0) {
                    unreachable;
                }
                var allocator: mem.SimpleAllocator = mem.SimpleAllocator.init_arena(Node.AddressSpace.arena(arena_index));
                impl.spawnDeps(address_space, thread_space, &allocator, toplevel, node, task);
                while (keepGoing() and nodeWait(node, task, arena_index)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (keepGoing() and node.task.lock.get(task) == .working) {
                    if (executeCommandInternal(toplevel, &allocator, node, task, arena_index)) {
                        node.assertExchange(task, .working, .finished, arena_index);
                    } else {
                        if (count_errors) {
                            build.error_count +%= 1;
                        }
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: u64 = allocator.next;
                defer allocator.next = save;
                impl.spawnDeps(address_space, thread_space, allocator, toplevel, node, task);
                while (keepGoing() and nodeWait(node, task, max_thread_count)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task.lock.get(task) == .working) {
                    if (executeCommandInternal(toplevel, allocator, node, task, max_thread_count)) {
                        node.assertExchange(task, .working, .finished, max_thread_count);
                    } else {
                        if (count_errors) {
                            build.error_count +%= 1;
                        }
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
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
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const task: types.Task = maybe_task orelse node.task.tag;
            if (node.exchange(task, .ready, .blocking, max_thread_count)) {
                try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, toplevel, node, task));
            }
            while (toplevelWait(thread_space)) {
                try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
            }
            return node.task.lock.get(task) == .finished;
        }
        const state_logging: debug.Logging.AttemptSuccessFault = builder_spec.logging.state.override();
        fn exchange(node: *Node, task: types.Task, old_state: types.State, new_state: types.State, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: bool = node.task.lock.atomicExchange(task, old_state, new_state);
            if (ret) {
                if (state_logging.Success) {
                    about.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (state_logging.Attempt) {
                    about.noExchangeNotice(node, about.tab.state_s, task, old_state, new_state, arena_index);
                }
            }
            return ret;
        }
        fn assertExchange(node: *Node, task: types.Task, old_state: types.State, new_state: types.State, arena_index: AddressSpace.Index) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (old_state == new_state) {
                return;
            }
            if (node.task.lock.atomicExchange(task, old_state, new_state)) {
                if (state_logging.Success) {
                    about.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (state_logging.Fault) {
                    about.noExchangeNotice(node, about.tab.state_1_s, task, old_state, new_state, arena_index);
                }
                proc.exitGroup(2);
            }
        }
        fn assertNode(node: *Node, chk: bool, msg: [:0]const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!chk) {
                about.incorrectNodeUsageError(node, msg);
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
        pub fn nodeWait(node: *Node, task: types.Task, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.show_waiting_tasks) {
                if (node.impl.wait_len >> 28 > node.impl.wait_tick) {
                    about.writeWaitingOn(node, arena_index);
                    node.impl.wait_tick +%= 1;
                } else {
                    node.impl.wait_len +%= builder_spec.options.sleep_nanoseconds;
                }
            }
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
            @setRuntimeSafety(builder_spec.options.enable_safety);
            try meta.wrap(file.close(close(), in.write));
            try meta.wrap(file.close(close(), out.read));
            try meta.wrap(file.duplicateTo(dup3(), in.read, 0));
            try meta.wrap(file.duplicateTo(dup3(), out.write, 1));
        }
        fn openParent(in: file.Pipe, out: file.Pipe) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            try meta.wrap(file.close(close(), in.read));
            try meta.wrap(file.close(close(), out.write));
        }
        const binary_prefix: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.exe_out_dir ++ "/";
        const library_prefix: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.lib_out_dir ++ "/lib";
        const archive_prefix: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.lib_out_dir ++ "/lib";
        const auxiliary_prefix: [:0]const u8 = builder_spec.options.names.zig_out_dir ++ "/" ++ builder_spec.options.names.aux_out_dir ++ "/";
        fn binaryRelative(allocator: *mem.SimpleAllocator, name: [:0]u8, kind: types.OutputMode) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return concatenate(allocator, switch (kind) {
                .exe => &[_][]const u8{ binary_prefix, name },
                .obj => &[_][]const u8{ binary_prefix, name, builder_spec.options.extensions.obj },
                .lib => &[_][]const u8{ library_prefix, name, builder_spec.options.extensions.lib },
            });
        }
        fn archiveRelative(allocator: *mem.SimpleAllocator, name: [:0]u8) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return concatenate(allocator, &[_][]const u8{ archive_prefix, name, builder_spec.options.extensions.ar });
        }
        fn auxiliaryRelative(allocator: *mem.SimpleAllocator, name: [:0]u8, kind: types.AuxOutputMode) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return concatenate(allocator, switch (kind) {
                .llvm_ir => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.llvm_ir },
                .llvm_bc => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.llvm_bc },
                .h => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.h },
                .docs => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.docs },
                .analysis => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.analysis },
                .implib => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.implib },
                else => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.extensions.@"asm" },
            });
        }
        pub fn processCommandsInternal(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *mem.SimpleAllocator,
            toplevel: *Node,
            node: *Node,
            maybe_task: ?types.Task,
        ) ?bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var name: [:0]const u8 = mach.manyToSlice80(build.args[build.cmd_idx]);
            if (mach.testEqualMany8(name, node.name)) {
                toplevel.impl.args_len = build.cmd_idx +% 1;
                build.task_idx = build.cmd_idx;
                while (build.task_idx != build.args.len) : (build.task_idx +%= 1) {
                    name = mach.manyToSlice80(build.args[build.task_idx]);
                    if (mach.testEqualMany8(name, "--")) {
                        build.task_idx +%= 1;
                        break;
                    }
                }
                return executeToplevel(address_space, thread_space, allocator, toplevel, node, maybe_task);
            } else if (node.tag == .group) {
                for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
                    if (processCommandsInternal(address_space, thread_space, allocator, toplevel, sub_node, maybe_task)) |result| {
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
            defer build.cmd_idx = 5;
            var maybe_task: ?types.Task = null;
            lo: while (build.cmd_idx != build.args.len) : (build.cmd_idx +%= 1) {
                const name: [:0]const u8 = mach.manyToSlice80(build.args[build.cmd_idx]);
                for (types.Task.list) |task| {
                    if (mach.testEqualMany8(name, @tagName(task))) {
                        maybe_task = task;
                        continue :lo;
                    }
                }
                if (mach.testEqualMany8(builder_spec.options.names.single_threaded_command, name)) {
                    node.flags.group.is_single_threaded = true;
                    continue :lo;
                }
                if (mach.testEqualMany8(builder_spec.options.names.toplevel_list_command, name)) {
                    return about.toplevelCommandNotice(allocator, node);
                }
                if (processCommandsInternal(address_space, thread_space, allocator, node, node, maybe_task)) |result| {
                    return if (!result) {
                        proc.exitError(error.UnfinishedRequest, 2);
                    };
                }
            }
            const name: [:0]const u8 = if (build.args.len == 5) "null" else mach.manyToSlice80(build.args[5]);
            proc.exitErrorFault(error.NotACommand, name, 2);
        }
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
        pub fn archivePath(node: *Node) types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {
                assertNode(node, node.tag == .worker and node.task.tag == .archive);
            }
            return node.impl.paths[1];
        }
        pub fn binaryPath(node: *Node) types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {
                assertNode(node, node.tag == .worker and node.task.tag == .build);
            }
            return node.impl.paths[1];
        }
        pub fn rootPath(node: *Node) types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.enable_usage_validation) {
                assertNode(node, node.tag == .worker and node.task.tag == .build);
            }
            return node.impl.paths[1];
        }
        pub fn testExtension(name: []const u8, extension: []const u8) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return extension.len < name.len and
                mach.testEqualMany8(extension, name[name.len -% extension.len ..]);
        }
        const keepGoing = if (impl.count_errors) keepGoingB else keepGoingA;
        inline fn keepGoingA() bool {
            comptime return true;
        }
        fn keepGoingB() bool {
            return build.error_count <= builder_spec.options.max_error_count.?;
        }
        fn writeConfigRoot(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const build_cmd: *types.BuildCommand = node.task.info.build;
            var buf: [32768]u8 = undefined;
            var len: usize = 0;
            if (!keepGoing()) {
                return;
            }
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
                    mach.memcpy(buf[len..].ptr, dependency.name.ptr, dependency.name.len);
                    len +%= dependency.name.len;
                    @as(*[16]u8, @ptrCast(buf[len..].ptr)).* = "\":?[:0]const u8=".*;
                    len +%= 16;
                    if (dependency.import) |import| {
                        buf[len] = '"';
                        len +%= 1;
                        mach.memcpy(buf[len..].ptr, import.ptr, import.len);
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
                    mach.memcpy(buf[len..].ptr, module.name.ptr, module.name.len);
                    len +%= module.name.len;
                    @as(*[15]u8, @ptrCast(buf[len..].ptr)).* = "\":[:0]const u8=".*;
                    len +%= 15;
                    buf[len] = '"';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, module.path.ptr, module.path.len);
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
                    mach.memcpy(buf[len..].ptr, dep.on_node.name.ptr, dep.on_node.name.len);
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
                    len +%= fmt.ud64(byte).formatWriteBuf(buf[len..].ptr);
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
            const root_fd: u64 = try meta.wrap(file.createAt(create(), build.config_root_fd, name, file.mode.regular));
            file.write(write(), root_fd, buf[0..len]);
            file.close(close(), root_fd);
            node.impl.paths[1].names[1] = builder_spec.options.names.zig_build_dir;
            node.impl.paths[1].addName(allocator).* = name;
        }
        fn writeRecord(node: *Node, job: *types.JobInfo) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var buf: [4096]u8 = undefined;
            const rcd: types.Record = types.Record.init(job, node.task.info.build);
            const names: []const [:0]const u8 = &.{ builder_spec.options.names.zig_stat_dir, node.name };
            const len: usize = types.Path.temporary(names).formatWriteBuf(&buf) -% 1;
            const fd: u64 = try meta.wrap(file.createAt(create2(), build.build_root_fd, buf[0..len :0], file.mode.regular));
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
            var len: usize = 0;
            for (values) |value| {
                len +%= value.len;
            }
            const buf: [*]u8 = @as([*]u8, @ptrFromInt(allocator.allocateRaw(len +% 1, 1)));
            var idx: usize = 0;
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
            for (args) |value| {
                count +%= @intFromBool(value == 0);
            }
            const ptrs: [*][*:0]u8 = @as([*][*:0]u8, @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 1)));
            var len: usize = 0;
            var idx: usize = 0;
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
            var idx: usize = 0;
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
        const about = struct {
            const tab = .{
                .ar_s = fmt.about("ar"),
                .run_s = fmt.about("run"),
                .format_s = fmt.about("fmt"),
                .build_exe_s = fmt.about("build-exe"),
                .build_obj_s = fmt.about("build-obj"),
                .build_lib_s = fmt.about("build-lib"),
                .state_s = fmt.about("state"),
                .state_1_s = fmt.about("state-fault"),
                .waiting_s = fmt.about("waiting"),
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
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                @as(fmt.AboutDest, @ptrCast(&buf)).* = tab.waiting_s.*;
                var len: usize = tab.waiting_s.len;
                mach.memcpy(buf[len..].ptr, node.name.ptr, node.name.len);
                len +%= node.name.len;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= about.writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                len +%= 1;
                for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                    len +%= writeNoExchangeTask(
                        buf[len..].ptr,
                        dep.on_node,
                        tab.waiting_s,
                        dep.on_task,
                        dep.on_node.task.lock.get(dep.on_task),
                        dep.on_state,
                        arena_index,
                    );
                    buf[len] = '\n';
                    len +%= 1;
                }
                debug.write(buf[0..len]);
            }
            fn writeFromTo(buf: [*]u8, old: types.State, new: types.State) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                @as(*[2]u8, @ptrCast(buf)).* = "={".*;
                var len: usize = 2;
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
                var len: usize = about_s.len;
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
                var len: usize = writeExchangeTask(&buf, node, about.tab.state_s, task);
                len +%= writeFromTo(buf[len..].ptr, old, new);
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                debug.write(buf[0 .. len +% 1]);
            }
            fn writeNoExchangeTask(buf: [*]u8, node: *const Node, about_s: fmt.AboutSrc, task: types.Task, old: types.State, new: types.State, arena_index: AddressSpace.Index) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task.lock.get(task);
                var len: usize = writeExchangeTask(buf, node, about_s, task);
                buf[len] = '=';
                len +%= 1;
                mach.memcpy(buf + len, @tagName(actual).ptr, @tagName(actual).len);
                len +%= @tagName(actual).len;
                const add: u64 = writeFromTo(buf + len, old, new);
                buf[len] = '!';
                len +%= add;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf + len, arena_index);
                }
                return len;
            }
            fn noExchangeNotice(node: *Node, about_s: fmt.AboutSrc, task: types.Task, old: types.State, new: types.State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [32768]u8 = undefined;
                var len = writeNoExchangeTask(&buf, node, about_s, task, old, new, arena_index);
                buf[len] = '\n';
                debug.write(buf[0 .. len +% 1]);
            }
            inline fn incorrectNodeUsageError(node: *Node, msg: [:0]const u8) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [32768]u8 = undefined;
                var len: usize = 0;
                @as(*[24]u8, @ptrCast(&buf)).* = tab.error_p0_s.*;
                len +%= 24;
                mach.memcpy(buf[len..].ptr, node.name);
                len +%= node.name.len;
                mach.memcpy(buf[len..].ptr, msg);
                len +%= msg.len;
            }
            fn writeArenaIndex(buf: [*]u8, arena_index: AddressSpace.Index) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ud64: fmt.Type.Ud64 = @bitCast(@as(u64, arena_index));
                @as(*[2]u8, @ptrCast(buf)).* = " [".*;
                const len: usize = ud64.formatWriteBuf(buf + 2);
                buf[2 +% len] = ']';
                return 3 +% len;
            }
            fn stateNotice(node: *Node, task: types.Task) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const actual: types.State = node.task.lock.get(task);
                var buf: [32768]u8 = undefined;
                mach.memcpy(&buf, tab.state_s.ptr, tab.state_s.len);
                var len: usize = tab.state_s.len;
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
                debug.write(buf[0 .. len +% 1]);
            }
            fn taskNotice(node: *Node, task: types.Task, arena_index: AddressSpace.Index, old_size: u64, new_size: u64, job: *types.JobInfo) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const diff_size: u64 = @max(new_size, old_size) -% @min(new_size, old_size);
                var ud64: fmt.Type.Ud64 = undefined;
                var buf: [32768]u8 = undefined;
                const about_s: []const u8 = switch (task) {
                    else => unreachable,
                    .archive => tab.ar_s,
                    .format => tab.format_s,
                    .run => tab.run_s,
                    .build => switch (node.task.info.build.kind) {
                        .exe => tab.build_exe_s,
                        .obj => tab.build_obj_s,
                        .lib => tab.build_lib_s,
                    },
                };
                var len: usize = about_s.len;
                mach.memcpy(&buf, about_s.ptr, about_s.len);
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
                ud64 = @bitCast(@as(u64, job.ret.sys));
                if (task == .build) {
                    var style_s: []const u8 = tab.bold_s;
                    const res: UpdateAnswer = UpdateAnswer.enumFromInt(job.ret.srv);
                    const msg_s: []const u8 = @tagName(res);
                    if (res == .failed) {
                        style_s = tab.red_s;
                    }
                    if (node.flags.is_special) {
                        if (res == .cached) {
                            return;
                        }
                        style_s = tab.special_s;
                    }
                    buf[len] = '[';
                    len +%= 1;
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    mach.memcpy(buf[len..].ptr, msg_s.ptr, msg_s.len);
                    len +%= msg_s.len;
                    @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = tab.reset_s.*;
                    len +%= 4;
                    buf[len] = ',';
                    len +%= 1;
                    len +%= ud64.formatWriteBuf(buf[len..].ptr);
                    buf[len] = ']';
                    len +%= 1;
                } else {
                    const style_s: []const u8 = switch (job.ret.sys) {
                        builder_spec.options.system_expected_status => tab.bold_s,
                        else => tab.red_s,
                    };
                    mach.memcpy(buf[len..].ptr, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    len +%= ud64.formatWriteBuf(buf[len..].ptr);
                    @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = tab.reset_s.*;
                    len +%= 4;
                }
                @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
                len +%= 2;
                if (task == .build or task == .archive) {
                    if (old_size == 0) {
                        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = tab.gold_s.*;
                        len +%= 5;
                        ud64 = @bitCast(new_size);
                        len +%= ud64.formatWriteBuf(buf[len..].ptr);
                        @as(*[13]u8, @ptrCast(buf[len..].ptr)).* = ("*" ++ tab.reset_s ++ tab.bytes_s).*;
                        len +%= 13;
                    } else if (new_size == old_size) {
                        ud64 = @bitCast(new_size);
                        len +%= ud64.formatWriteBuf(buf[len..].ptr);
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = tab.bytes_s.*;
                        len +%= 8;
                    } else {
                        ud64 = @bitCast(old_size);
                        len +%= ud64.formatWriteBuf(buf[len..].ptr);
                        buf[len] = '(';
                        len +%= 1;
                        @as(*[7]u8, @ptrCast(buf[len..].ptr)).* = if (new_size > old_size) tab.red_s.* else tab.green_s.*;
                        len +%= 7;
                        buf[len] = if (new_size > old_size) '+' else '-';
                        len +%= 1;
                        ud64 = @bitCast(diff_size);
                        len +%= ud64.formatWriteBuf(buf[len..].ptr);
                        @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = tab.reset_s.*;
                        len +%= 4;
                        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = ") => ".*;
                        len +%= 5;
                        ud64 = @bitCast(new_size);
                        len +%= ud64.formatWriteBuf(buf[len..].ptr);
                        @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = tab.bytes_s.*;
                        len +%= 8;
                    }
                }
                ud64 = @bitCast(job.ts.sec);
                len +%= ud64.formatWriteBuf(buf[len..].ptr);
                @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = ".000".*;
                len +%= 1;
                ud64 = @bitCast(job.ts.nsec);
                const figs: usize = fmt.length(u64, job.ts.nsec, 10);
                len +%= 9 -% figs;
                _ = ud64.formatWriteBuf(buf[len..].ptr);
                len +%= figs -% 9;
                len +%= 3;
                buf[len] = 's';
                len +%= 1;
                if (builder_spec.options.show_arena_index and
                    arena_index != max_thread_count)
                {
                    len +%= writeArenaIndex(buf[len..].ptr, arena_index);
                }
                buf[len] = '\n';
                debug.write(buf[0 .. len +% 1]);
            }
            inline fn writeAbout(buf: [*]u8, kind: AboutKind) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                switch (kind) {
                    .@"error" => {
                        @as(*@TypeOf(tab.bold_s.*), @ptrCast(buf + len)).* = tab.bold_s.*;
                        len +%= tab.bold_s.len;
                    },
                    .note => {
                        @as(*@TypeOf(tab.grey_s.*), @ptrCast(buf + len)).* = tab.grey_s.*;
                        len +%= tab.grey_s.len;
                    },
                }
                const about_s: [:0]const u8 = @tagName(kind);
                mach.memcpy(buf + len, about_s.ptr, about_s.len);
                len +%= about_s.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                @as(*@TypeOf(tab.bold_s.*), @ptrCast(buf + len)).* = tab.bold_s.*;
                return len +% tab.bold_s.len;
            }
            inline fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
                var len: usize = tab.bold_s.len;
                @as(*[4]u8, @ptrCast(buf)).* = tab.bold_s.*;
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
                const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
                const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
                var len: usize = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
                const pos: u64 = len +% @tagName(kind).len -% tab.trace_s.len -% 2;
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
                var ud64: fmt.Type.Ud64 = @bitCast(line);
                var len: usize = 0;
                @as(*[11]u8, @ptrCast(buf + len)).* = tab.trace_s.*;
                len +%= tab.trace_s.len;
                mach.memcpy(buf + len, pathname.ptr, pathname.len);
                len +%= pathname.len;
                buf[len] = ':';
                len +%= 1;
                len +%= ud64.formatWriteBuf(buf + len);
                buf[len] = ':';
                len +%= 1;
                ud64 = @bitCast(column);
                len +%= ud64.formatWriteBuf(buf + len);
                @as(*[4]u8, @ptrCast(buf + len)).* = tab.reset_s.*;
                return len +% 4;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ud64: fmt.Type.Ud64 = @bitCast(count);
                @as(*[4]u8, @ptrCast(buf - 1)).* = tab.faint_s.*;
                var len: usize = tab.faint_s.len -% 1;
                @as(*[2]u8, @ptrCast(buf + len)).* = " (".*;
                len +%= 2;
                len +%= ud64.formatWriteBuf(buf + len);
                @as(*[7]u8, @ptrCast(buf + len)).* = " times)".*;
                len +%= 7;
                @as(*[5]u8, @ptrCast(buf + len)).* = tab.new_s.*;
                return len +% 5;
            }
            fn writeCaret(buf: [*]u8, bytes: [*:0]u8, src: *types.SourceLocation) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const line: [:0]u8 = mach.manyToSlice80(bytes + src.src_line);
                const before_caret: u64 = src.span_main -% src.span_start;
                const indent: u64 = src.column -% before_caret;
                const after_caret: u64 = src.span_end -% src.span_main -| 1;
                var len: usize = 0;
                if (fancy_hl_line) {
                    var pos: u64 = indent +% before_caret;
                    mach.memcpy(buf, line.ptr, indent);
                    len +%= indent;
                    @as(*[tab.bold_s.len]u8, @ptrCast(buf + len)).* = tab.bold_s.*;
                    len +%= tab.bold_s.len;
                    mach.memcpy(buf + len, line[indent..pos].ptr, before_caret);
                    len +%= before_caret;
                    @as(*[tab.hi_red_s.len]u8, @ptrCast(buf + len)).* = tab.hi_red_s.*;
                    len +%= tab.hi_red_s.len;
                    buf[len] = line[pos];
                    len +%= 1;
                    pos = pos +% 1;
                    @as(*[tab.bold_s.len]u8, @ptrCast(buf + len)).* = tab.bold_s.*;
                    len +%= tab.bold_s.len;
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
                @as(*@TypeOf(tab.hi_green_s.*), @ptrCast(buf + len)).* = tab.hi_green_s.*;
                len +%= tab.hi_green_s.len;
                mach.memset(buf + len, '~', before_caret);
                len +%= before_caret;
                buf[len] = '^';
                len +%= 1;
                mach.memset(buf + len, '~', after_caret);
                len +%= after_caret;
                @as(*[5]u8, @ptrCast(buf + len)).* = tab.new_s.*;
                return len +% tab.new_s.len;
            }
            fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: u64, indent: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                var next: u64 = start;
                var idx: usize = start;
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
                @as(*[5]u8, @ptrCast(buf + len)).* = tab.new_s.*;
                return len +% tab.new_s.len;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: u64, ref_len: usize) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ref_idx: usize = start +% types.SourceLocation.len;
                var idx: usize = 0;
                var len: usize = 0;
                @as(*[11]u8, @ptrCast(buf + len)).* = tab.trace_s.*;
                len +%= 11;
                @as(*[15]u8, @ptrCast(buf + len)).* = "referenced by:\n".*;
                len +%= 15;
                while (idx != ref_len) : (idx +%= 1) {
                    const ref_trc: *types.ReferenceTrace = @ptrCast(extra + ref_idx);
                    if (ref_trc.src_loc != 0) {
                        const ref_src: *types.SourceLocation = @ptrCast(extra + ref_trc.src_loc);
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
                @as(*[5]u8, @ptrCast(buf + len)).* = tab.new_s.*;
                return len +% 5;
            }
            fn writeErrors(allocator: *mem.SimpleAllocator, ptrs: MessagePtrs) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const extra: [*]u32 = ptrs.idx + 2;
                const bytes: [*:0]u8 = ptrs.str + 8 + (ptrs.idx[0] *% 4);
                var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
                for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
                    debug.write(buf[0..writeError(buf, extra, bytes, err_msg_idx, .@"error")]);
                }
                debug.write(mach.manyToSlice80(bytes + extra[2]));
            }
            fn wouldSkip(toplevel: *const Node, node: *const Node) bool {
                return toplevel == node or node.flags.is_hidden or
                    builder_spec.options.hide_special and node.flags.is_special;
            }
            fn lengthAndWalkInternal(len1: usize, node: *const Node, name_width: *usize, root_width: *usize) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const deps: []Dependency = node.impl.deps[0..node.impl.deps_len];
                var last_idx: usize = 0;
                for (deps, 0..) |dep, dep_idx| {
                    if (wouldSkip(node, dep.on_node)) {
                        continue;
                    }
                    last_idx = dep_idx +% 1;
                }
                for (deps, 0..) |dep, deps_idx| {
                    const dep_node: *Node = dep.on_node;
                    if (wouldSkip(node, dep_node)) {
                        continue;
                    }
                    if (dep_node.impl.paths_len != 0) {
                        lengthSubNode(len1 +% 2, dep_node, name_width, root_width);
                    }
                    lengthAndWalkInternal(len1 +% 2, dep_node, name_width, root_width);
                    if (deps_idx == last_idx) {
                        break;
                    }
                }
            }
            fn lengthSubNode(len1: usize, sub_node: *const Node, name_width: *usize, root_width: *usize) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                name_width.* = @max(name_width.*, sub_node.name.len +% len1);
                const input: [:0]const u8 = sub_node.impl.paths[@intFromBool(sub_node.task.tag == .build)].names[1];
                if (input.len != 0) {
                    if (sub_node.descr.len != 0) {
                        root_width.* = @max(root_width.*, input.len);
                    }
                }
            }
            fn lengthToplevelCommandNotice(len1: usize, node: *const Node, name_width: *usize, root_width: *usize) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const nodes: []*Node = node.impl.nodes[0..node.impl.nodes_len];
                if (node.impl.paths_len != 0) {
                    lengthSubNode(len1, node, name_width, root_width);
                }
                lengthAndWalkInternal(len1, node, name_width, root_width);
                var last_idx: usize = 0;
                for (nodes, 0..) |sub_node, nodes_idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    last_idx = nodes_idx;
                }
                for (nodes, 0..) |sub_node, nodes_idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    if (sub_node.flags.is_hidden and
                        sub_node.impl.paths_len != 0)
                    {
                        lengthSubNode(len1 +% 4, sub_node, name_width, root_width);
                    }
                    lengthToplevelCommandNotice(len1 +% 2, sub_node, name_width, root_width);
                    if (nodes_idx == last_idx) {
                        break;
                    }
                }
            }
            fn writeAndWalkInternal(buf0: [*]u8, len0: usize, buf1: [*]u8, len1: usize, node: *const Node, name_width: usize, root_width: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const deps: []Dependency = node.impl.deps[0..node.impl.deps_len];
                var len: usize = len0;
                var fin: *u8 = &buf0[0];
                var last_idx: usize = 0;
                for (deps, 0..) |dep, dep_idx| {
                    if (wouldSkip(node, dep.on_node)) {
                        continue;
                    }
                    last_idx = dep_idx;
                }
                for (deps, 0..) |dep, deps_idx| {
                    if (wouldSkip(node, dep.on_node)) {
                        continue;
                    }
                    @as(*[2]u8, @ptrCast(buf1 + len1)).* = if (deps_idx == last_idx) "  ".* else "| ".*;
                    buf0[len] = '\n';
                    len +%= 1;
                    mach.memcpy(buf0 + len, buf1, len1);
                    len +%= len1;
                    fin = &buf0[len];
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = "|-".*;
                    len +%= 2;
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (dep.on_node.impl.deps_len == 0) "> ".* else "+ ".*;
                    len +%= 2;
                    @memcpy(buf0 + len, dep.on_node.name);
                    len +%= dep.on_node.name.len;
                    if (dep.on_node.impl.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 2, dep.on_node, name_width, root_width);
                    }
                    len = writeAndWalkInternal(buf0, len, buf1, len1 +% 2, dep.on_node, name_width, root_width);
                    if (deps_idx == last_idx) {
                        break;
                    }
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return len;
            }
            fn writeSubNode(buf0: [*]u8, len1: usize, sub_node: *const Node, name_width: usize, root_width: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                var count: usize = name_width -% (sub_node.name.len +% len1);
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
                const nodes: []*Node = node.impl.nodes[0..node.impl.nodes_len];
                var len: usize = 0;
                var fin: *u8 = &buf0[0];
                if (node.impl.paths_len != 0) {
                    len = writeSubNode(buf0, len1, node, name_width, root_width);
                }
                @as(*[4]u8, @ptrCast(buf0 + len)).* = about.tab.faint_s.*;
                len +%= about.tab.faint_s.len;
                len = writeAndWalkInternal(buf0, len, buf1, len1, node, name_width, root_width);
                @as(*[4]u8, @ptrCast(buf0 + len)).* = about.tab.reset_s.*;
                len +%= tab.reset_s.len;
                var last_idx: usize = 0;
                for (nodes, 0..) |sub_node, nodes_idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    last_idx = nodes_idx;
                }
                for (nodes, 0..) |sub_node, nodes_idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    @as(*[2]u8, @ptrCast(buf1 + len1)).* = if (nodes_idx == last_idx or len1 == 0) "  ".* else "| ".*;
                    buf0[len] = '\n';
                    len +%= 1;
                    @memcpy(buf0 + len, buf1[0..len1]);
                    len +%= len1;
                    fin = &buf0[len];
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (len1 == 0) "  ".* else "|-".*;
                    len +%= 2;
                    @as(*[2]u8, @ptrCast(buf0 + len)).* = if (sub_node.impl.nodes_len == 0) "- ".* else "o ".*;
                    len +%= 2;
                    if (sub_node.flags.is_hidden and sub_node.impl.paths_len != 0) {
                        len +%= writeSubNode(buf0 + len, len1 +% 4, sub_node, name_width, root_width);
                    }
                    @memcpy(buf0 + len, sub_node.name);
                    len +%= sub_node.name.len;
                    len +%= writeToplevelCommandNotice(buf0 + len, buf1, len1 +% 2, sub_node, name_width, root_width);
                    if (nodes_idx == last_idx) {
                        break;
                    }
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return len;
            }
            fn writeStateSummary(buf: [*]u8, node: *const Node) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                var st: types.State = .null;
                if (do_build) {
                    st = node.task.lock.get(.build);
                    if (st != .null) {
                        const style_s: []const u8 = st.style();
                        mach.memcpy(buf + len, style_s.ptr, style_s.len);
                        len +%= style_s.len;
                        buf[len] = 'b';
                    }
                }
                if (do_format) {
                    st = node.task.lock.get(.format);
                    if (st != .null) {
                        const style_s: []const u8 = st.style();
                        mach.memcpy(buf + len, style_s.ptr, style_s.len);
                        len +%= style_s.len;
                        buf[len] = 'f';
                    }
                }
                if (do_archive) {
                    st = node.task.lock.get(.archive);
                    if (st != .null) {
                        const style_s: []const u8 = st.style();
                        mach.memcpy(buf + len, style_s.ptr, style_s.len);
                        len +%= style_s.len;
                        buf[len] = 'a';
                    }
                }
                st = node.task.lock.get(.run);
                if (st != .null) {
                    const style_s: []const u8 = st.style();
                    mach.memcpy(buf + len, style_s.ptr, style_s.len);
                    len +%= style_s.len;
                    buf[len] = 'x';
                }
                if (len != 0) {
                    @as(*[4]u8, @ptrCast(buf + len)).* = "\x1b[0m".*;
                    len +%= 4;
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
                mach.memset(buf0, '@', 1024 *% 1024);
                var len0: u64 = toplevel.name.len;
                const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
                mach.memset(buf1, '@', 4096);
                mach.memcpy(buf0, toplevel.name.ptr, toplevel.name.len);
                lengthToplevelCommandNotice(0, toplevel, &name_width, &root_width);
                name_width +%= 4;
                name_width &= ~@as(u64, 3);
                root_width +%= 4;
                root_width &= ~@as(u64, 3);
                len0 +%= writeToplevelCommandNotice(buf0 + len0, buf1, 0, toplevel, name_width, root_width);
                buf0[len0] = '\n';
                len0 +%= 1;
                debug.write(buf0[0..len0]);
            }
        };
    };
    return Type;
}
fn libraryRoot() [:0]const u8 {
    comptime {
        const pathname: [:0]const u8 = @src().file;
        var idx: usize = pathname.len -% 1;
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
