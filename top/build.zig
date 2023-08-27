const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const elf = @import("./elf.zig");
const perf = @import("./perf.zig");
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
    /// Program command line arguments
    pub var args: [][*:0]u8 = undefined;
    /// Environment variables
    pub var vars: [][*:0]u8 = undefined;
    /// Number of errors since `processCommands`.
    var error_count: u8 = undefined;
    /// Parsed to modify the task info = args[cmd_args_idx..run_args_idx]
    var cmd_args: [][*:0]u8 = undefined;
    /// Appended to (currently) any run command = args[run_args_idx..]
    var run_args: [][*:0]u8 = undefined;
};
pub const BuilderSpec = struct {
    /// Builder options.
    options: Options = .{},
    /// Logging for system calls called by the builder.
    logging: Logging = .{},
    /// Errors for system calls called by builder. This excludes `clone3`,
    /// which must be implemented in assembly.
    errors: Errors = .{},
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u8 = 8,
        /// Allow this many errors before exiting the thread group.
        /// A value of `null` will attempt to report all errors and exit from main.
        max_error_count: ?u8 = 0,
        /// Lowest allocated byte address.
        lb_addr: usize = 0x400000000000,
        /// Bytes allowed per thread arena (default=8MiB)
        max_arena_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (default=8MiB)
        max_stack_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed for dynamic loader metadata (default=8MiB)
        max_load_info_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed for dynamic libraries (.text + .rodata) (default=8MiB)
        max_load_sect_aligned_bytes: usize = 8 * 1024 * 1024,
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
        /// Enables logging for task creation.
        show_task_creation: bool = false,
        /// Enables logging for tasks waiting on dependencies.
        show_waiting_tasks: bool = false,
        /// Enables logging for command line arguments intended for task commands and run commands.
        show_command_lines: bool = false,
        /// Enables logging for build job statistics.
        show_stats: bool = true,
        /// Include arena/thread index in task summaries and change of state
        /// notices.
        show_arena_index: bool = true,
        /// Show the size of the declared tasks at startup.
        show_base_memory_usage: bool = false,
        /// Enable runtime safety.
        enable_safety: bool = builtin.is_safe,
        /// Never list special nodes among or allow explicit building.
        hide_special: bool = true,
        /// Enable stack traces in runtime errors for executables where mode is
        /// Debug with debugging symbols included
        update_debug_stack_traces: bool = true,
        /// Add run task for all executable build outputs
        update_executables: bool = true,
        /// Nodes with this name prefix are hidden in pre.
        init_hidden_by_name_prefix: ?u8 = '_',
        /// (Recommended) Pass --main-pkg-path=<build_root> for all compile commands.
        init_main_pkg_path: bool = true,
        /// (Recommended) Pass --cache-dir=<cache_root> for all compile commands.
        init_cache_root: bool = true,
        /// (Recommended) Pass --global-cache-dir=<cache_root> for all compile commands.
        init_global_cache_root: bool = true,
        /// Nodes with hidden parent/group nodes are also hidden
        inherit_hidden: bool = true,
        /// Nodes belonging to special groups are also special.
        inherit_special: bool = true,
        /// Enable advanced builder features, such as project-wide comptime
        /// constants and caching special modules.
        write_build_configuration: bool = true,
        /// Record build command data in a condensed format.
        write_build_task_record: bool = false,
        /// Include build task record serialised in build configuration.
        write_hist_serial: bool = false,
        /// Compile builder features as required.
        lazy_strategy: enum { none, dependency, emergency } = .emergency,
        /// Output naming strategy.
        output_strategy: enum { directories, first_name, full_name } = .full_name,
        /// Name separators for identifiers, commands, and output file names.
        namespace_separator: struct { id: u8 = '_', cmd: u8 = '.', fs: u8 = '-' } = .{},
        /// Name of the toplevel 'builder' node.
        toplevel_node: [:0]const u8 = "toplevel",
        /// Name of the special command used to list available commands.
        toplevel_list_command: [:0]const u8 = "list",
        /// Name of the special command used to disable multi-threading.
        single_threaded_command: [:0]const u8 = "--single-threaded",
        /// Basename of output directory. Relative to build root.
        output_dir: [:0]const u8 = "zig-out",
        /// Basename of cache directory. Relative to build root.
        cache_dir: [:0]const u8 = "zig-cache",
        /// Basename of statistics directory. Relative to build root.
        stat_dir: [:0]const u8 = "zig-stat",
        /// Basename of configuration directory. Relative to build root.
        config_dir: [:0]const u8 = "zig-build",
        /// Basename of executables output directory. Relative to output
        /// directory.
        exe_out_dir: [:0]const u8 = "bin",
        /// Basename of library output directory relative to output
        /// directory.
        lib_out_dir: [:0]const u8 = "lib",
        /// Basename of auxiliary output directory relative to output
        /// directory.
        aux_out_dir: [:0]const u8 = "aux",
        /// Pathname to root source used to compile tracer object.
        trace_root: [:0]const u8 = "top/trace.zig",
        /// Pathname to root source used to compile command line parser shared object.
        cmd_parsers_root: [:0]const u8 = "top/build/parsers.zig",
        /// Pathname to root source used to compile command line writer shared object.
        cmd_writers_root: [:0]const u8 = "top/build/writers.zig",
        /// Pathname to root source used to compile perf events manager shared object.
        perf_events_root: [:0]const u8 = "top/build/perf.zig",
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
        /// Report `seek` Acquire and Error.
        seek: debug.Logging.SuccessError = .{},
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
        /// Error values for `seek` system function.
        seek: sys.ErrorPolicy = .{},
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
    const T = struct {
        tag: types.Node,
        /// The tasks's 'first' name. Must be unique within the parent group.
        /// Names will only be checked for uniqueness once: when the node is
        /// added to its group with any of the `add(Build|Format|Archive|...)`
        /// functions. If a non-unique name is contrived by manually editing
        /// this field the state is undefined.
        name: [:0]u8,
        /// Description text to be printed with task listing.
        descr: [:0]const u8,
        task: Task,
        flags: packed struct {
            /// Self-explanatory. An alternative to this flag is testing whether
            /// node == node.impl.nodes[0], as the toplevel is its own parent node.
            is_toplevel: bool = false,
            /// Whether the node is maintained and defined by this library.
            is_special: bool = false,
            /// Whether the node will be shown by list commands.
            is_hidden: bool = false,
            /// Whether the node task command has been invoked directly from
            /// `processCommands` by the user command line.
            /// Determines whether command line arguments are appended.
            is_primary: bool = false,
            /// Whether a library pathname should be used to load function pointers.
            is_dyn_ext: bool = false,
            /// Flags relevant to group nodes.
            /// Whether independent nodes will be processed in parallel.
            is_single_threaded: bool = false,
            /// Whether a run task will be performed using the compiler server.
            is_build_command: bool = false,

            /// Whether a node will be processed before being returned to `buildMain`.
            do_init: bool = true,
            /// Whether a node will be processed after returning from `buildMain`.
            do_update: bool = true,
            /// Whether a node will be processed on invokation of a user defined update command.
            do_user_update: bool = false,
            /// Whether a node will be processed on request to regenerate the build program.
            do_regenerate: bool = true,

            /// Flags relevant to build-* worker nodes.
            /// Builder will create a configuration root. Enables usage of
            /// configuration constants.
            want_build_config: bool = false,
            /// Builder will unconditionally add `trace` object to
            /// compile command.
            want_stack_traces: bool = false,
            /// Only meaningful when zig lib is not acting as standard.
            want_zig_lib_rt: bool = false,
            /// Define the compiler path, build root, cache root, and global
            /// cache root as declarations to the build configuration root.
            want_build_context: bool = true,
            /// Whether modification times of output binaries and root sources may
            /// be used to determine a cache hit. Useful for generated files.
            /// This check is performed by the builder.
            want_shallow_cache_check: bool = false,
        },
        impl: packed struct {
            args: [*][*:0]u8,
            args_max_len: usize,
            args_len: usize,
            paths: [*]types.Path,
            paths_max_len: usize,
            paths_len: usize,
            nodes: [*]*Node,
            nodes_max_len: usize,
            nodes_len: usize,
            deps: [*]Dependency,
            deps_max_len: usize,
            deps_len: usize,
            cfgs: [*]types.Config,
            cfgs_max_len: usize,
            cfgs_len: usize,
        },
        extra: struct {
            build_root_fd: u32,
            config_root_fd: u32,
            output_root_fd: u32,
            wait_len: usize,
            wait_tick: usize,
            ptr: Pointer,
        },
        const Node = @This();
        const Task = extern struct {
            tag: types.Task,
            cmd: Command,
            lock: types.Lock,
        };
        const Command = extern union {
            build: *types.BuildCommand,
            format: *types.FormatCommand,
            archive: *types.ArchiveCommand,
            objcopy: *types.ObjcopyCommand,
        };
        const Pointer = extern union {
            addr: usize,
            any: ?*anyopaque,
            info: *DynamicLoader.Info,
        };
        const AboutKind = enum(u8) { @"error", note };
        const UpdateAnswer = enum(u8) {
            updated = builder_spec.options.compiler_expected_status,
            cached = builder_spec.options.compiler_cache_hit_status,
            failed = builder_spec.options.compiler_error_status,
            _,
        };
        const SystemReturn = enum(u8) {
            expected = builder_spec.options.system_expected_status,
            _,
        };
        pub const Special = struct {
            var trace: *Node = @ptrFromInt(8);
            var cmd_parsers: *Node = @ptrFromInt(8);
            var cmd_writers: *Node = @ptrFromInt(8);
            var perf_events: *Node = @ptrFromInt(8);
            var fns: build.Fns = .{};
            var dyn_loader: DynamicLoader = .{};
        };
        pub const Config = types.Config;
        pub const specification: BuilderSpec = builder_spec;
        const max_thread_count: comptime_int = builder_spec.options.max_thread_count;
        const max_arena_count: comptime_int = if (max_thread_count == 0) 4 else max_thread_count + 1;
        const load_info_aligned_bytes: comptime_int = builder_spec.options.max_load_info_aligned_bytes;
        const load_sect_aligned_bytes: comptime_int = builder_spec.options.max_load_sect_aligned_bytes;
        const arena_aligned_bytes: comptime_int = builder_spec.options.max_arena_aligned_bytes;
        const stack_aligned_bytes: comptime_int = builder_spec.options.max_stack_aligned_bytes;
        const load_info_lb_addr: comptime_int = builder_spec.options.lb_addr;
        const load_info_up_addr: comptime_int = load_info_lb_addr + builder_spec.options.max_load_info_aligned_bytes;
        const load_sect_lb_addr: comptime_int = load_info_up_addr;
        const load_sect_up_addr: comptime_int = load_sect_lb_addr + builder_spec.options.max_load_sect_aligned_bytes;
        const stack_lb_addr: comptime_int = load_sect_up_addr;
        const stack_up_addr: comptime_int = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: comptime_int = stack_up_addr;
        const arena_up_addr: comptime_int = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        const aligned_bytes: comptime_int =
            (max_thread_count * stack_aligned_bytes) +%
            (max_arena_count * arena_aligned_bytes) +%
            load_info_aligned_bytes +% load_sect_aligned_bytes;
        pub const AddressSpace = mem.GenericRegularAddressSpace(.{
            .label = "arena",
            .index_type = u8,
            .errors = address_space_errors,
            .logging = builtin.zero(mem.AddressSpaceLogging),
            .divisions = max_arena_count,
            .lb_addr = arena_lb_addr,
            .up_addr = arena_up_addr,
            .options = address_space_options,
        });
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .index_type = u8,
            .label = "stack",
            .errors = address_space_errors,
            .logging = builtin.zero(mem.AddressSpaceLogging),
            .divisions = max_thread_count,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .options = thread_space_options,
        });
        const DynamicLoader = elf.GenericDynamicLoader(.{
            .options = dyn_loader_options,
            .logging = dyn_loader_logging,
            .errors = dyn_loader_errors,
        });
        pub const Dependency = struct {
            task: types.Task,
            on_node: *Node,
            on_task: types.Task,
            on_state: types.State,
        };
        fn groupPaths(allocator: *mem.SimpleAllocator, args: [][*:0]u8) [*]types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const paths: [*]types.Path = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Path) *% args.len, @alignOf(types.Path)));
            const names: [*][:0]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% args.len, 8));
            for (0..args.len) |idx| {
                names[idx] = mem.terminate(args[idx], 0);
                paths[idx] = .{ .names = names + idx };
            }
            return paths;
        }
        fn addPath(node: *Node, allocator: *mem.SimpleAllocator) *types.Path {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(types.Path);
            const addr_buf: *u64 = @ptrCast(&node.impl.paths);
            const ret: *types.Path = @ptrFromInt(allocator.addGeneric(size_of, //
                builder_spec.options.init_len.paths, addr_buf, &node.impl.paths_max_len, node.impl.paths_len));
            node.impl.paths_len +%= 1;
            return ret;
        }
        fn addNode(node: *Node, allocator: *mem.SimpleAllocator) **Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(*Node);
            const addr_buf: *u64 = @ptrCast(&node.impl.nodes);
            const ret: **Node = @ptrFromInt(allocator.addGeneric(size_of, //
                builder_spec.options.init_len.nodes, addr_buf, &node.impl.nodes_max_len, node.impl.nodes_len));
            node.impl.nodes_len +%= 1;
            return ret;
        }
        fn addArg(node: *Node, allocator: *mem.SimpleAllocator) *[*:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf([*:0]u8);
            const addr_buf: *u64 = @ptrCast(&node.impl.args);
            const ret: *[*:0]u8 = @ptrFromInt(allocator.addGeneric(size_of, //
                builder_spec.options.init_len.args, addr_buf, &node.impl.args_max_len, node.impl.args_len));
            node.impl.args_len +%= 1;
            return ret;
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
        /// Add constant declaration to build configuration.
        /// `node` must be `build-exe` worker.
        pub fn addConfig(node: *Node, allocator: *mem.SimpleAllocator, name: [:0]const u8, value: types.Config.Value) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(types.Config);
            const addr_buf: *u64 = @ptrCast(&node.impl.cfgs);
            const ptr: *types.Config = @ptrFromInt(allocator.addGeneric(size_of, //
                builder_spec.options.init_len.cfgs, addr_buf, &node.impl.cfgs_max_len, node.impl.cfgs_len));
            ptr.* = .{ .name = name, .value = value };
            node.impl.cfgs_len +%= 1;
        }
        pub fn addDependency(node: *Node, allocator: *mem.SimpleAllocator, task: types.Task, on_node: *Node, on_task: types.Task) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const size_of: comptime_int = @sizeOf(Dependency);
            const addr_buf: *u64 = @ptrCast(&node.impl.deps);
            const ret: *Dependency = @ptrFromInt(allocator.addGeneric(size_of, //
                builder_spec.options.init_len.deps, addr_buf, &node.impl.deps_max_len, node.impl.deps_len));
            if (task == .run) {
                if (on_task == .build and node == on_node) {
                    node.addArg(allocator).* = node.impl.paths[0].concatenate(allocator);
                }
            }
            if (task == .build) {
                if (on_task == .archive) {
                    node.addPath(allocator).* = on_node.impl.paths[0];
                }
                if (on_task == .build and
                    on_node.task.cmd.build.kind == .obj)
                {
                    node.addPath(allocator).* = on_node.impl.paths[0];
                }
            }
            if (task == .archive) {
                if (on_task == .build and
                    on_node.task.cmd.build.kind == .obj)
                {
                    node.addPath(allocator).* = on_node.impl.paths[0];
                }
            }
            node.impl.deps_len +%= 1;
            mem.zero(Dependency, ret);
            ret.* = .{
                .task = task,
                .on_node = on_node,
                .on_task = on_task,
                .on_state = .finished,
            };
        }
        pub fn addToplevelArgs(node: *Node, allocator: *mem.SimpleAllocator) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for ([_][:0]const u8{
                node.zigExe(),    node.buildRoot(),
                node.cacheRoot(), node.globalCacheRoot(),
            }) |arg| {
                node.addArg(allocator).* = @constCast(arg);
            }
        }
        fn addSpecialNodes(toplevel: *Node, allocator: *mem.SimpleAllocator) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const zig_exe: []const u8 = toplevel.zigExe();
            const global_cache_root: []const u8 = toplevel.globalCacheRoot();
            const zero: *Node = toplevel.addGroupFull(
                allocator,
                "zero",
                zig_exe,
                builtin.lib_root,
                lib_cache_root,
                global_cache_root,
            );
            zero.flags = .{ .is_special = true };
            if (builder_spec.options.lazy_strategy != .none) {
                Special.cmd_writers = zero.addRun(allocator, "cmd_writers", &[_][]const u8{
                    zero.zigExe(),        "build-lib",
                    "--cache-dir",        zero.cacheRoot(),
                    "--global-cache-dir", zero.globalCacheRoot(),
                    "--main-pkg-path",    zero.buildRoot(),
                    "--listen",           "-",
                    "-OReleaseSmall",     "-fno-compiler-rt",
                    "-fstrip",            "-fno-stack-check",
                    "-fsingle-threaded",  "-dynamic",
                    cmd_writers_root,
                });
                Special.cmd_writers.flags.is_dyn_ext = true;
                Special.cmd_writers.flags.want_shallow_cache_check = true;
                Special.cmd_parsers = zero.addRun(allocator, "cmd_parsers", &[_][]const u8{
                    zero.zigExe(),        "build-lib",
                    "--cache-dir",        zero.cacheRoot(),
                    "--global-cache-dir", zero.globalCacheRoot(),
                    "--main-pkg-path",    zero.buildRoot(),
                    "--listen",           "-",
                    "-OReleaseSmall",     "-fno-compiler-rt",
                    "-fstrip",            "-fno-stack-check",
                    "-fsingle-threaded",  "-dynamic",
                    cmd_parsers_root,
                });
                Special.cmd_parsers.flags.is_dyn_ext = true;
                Special.cmd_parsers.flags.want_shallow_cache_check = true;
                Special.perf_events = zero.addRun(allocator, "perf_events", &[_][]const u8{
                    zero.zigExe(),        "build-lib",
                    "--cache-dir",        zero.cacheRoot(),
                    "--global-cache-dir", zero.globalCacheRoot(),
                    "--main-pkg-path",    zero.buildRoot(),
                    "--listen",           "-",
                    "-OReleaseSmall",     "-fno-compiler-rt",
                    "-fstrip",            "-fno-stack-check",
                    "-fsingle-threaded",  "-dynamic",
                    perf_events_root,
                });
                Special.perf_events.flags.is_dyn_ext = true;
                Special.perf_events.flags.want_shallow_cache_check = true;
            }
            Special.trace = zero.addBuild(allocator, trace_build_cmd, "trace", builder_spec.options.trace_root);
        }
        fn initializeCommand(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builtin.root.exec_mode != .Regenerate and node.flags.do_init) {
                node.flags.do_init = false;
                if (builder_spec.options.inherit_special and
                    node.impl.nodes[0].flags.is_special)
                {
                    node.flags.is_special = true;
                }
                if (builder_spec.options.inherit_hidden and
                    node.impl.nodes[0].flags.is_hidden)
                {
                    node.flags.is_hidden = true;
                }
                if (builder_spec.options.init_hidden_by_name_prefix) |prefix| {
                    node.flags.is_hidden = node.name[0] == prefix;
                }
                if (node.tag == .worker) {
                    if (node.task.tag == .format) {
                        node.task.lock = format_lock;
                    }
                    if (node.task.tag == .run) {
                        node.task.lock = run_lock;
                    }
                    if (node.task.tag == .archive) {
                        node.task.lock = archive_lock;
                    }
                    if (node.task.tag == .build) {
                        node.task.cmd.build.listen = .@"-";
                        node.task.lock = obj_lock;
                        if (builder_spec.options.update_debug_stack_traces and
                            node.task.cmd.build.kind == .exe and node.hasDebugInfo())
                        {
                            node.flags.want_stack_traces = true;
                        }
                        if (builder_spec.options.init_main_pkg_path) {
                            node.task.cmd.build.main_pkg_path = node.buildRoot();
                        }
                        if (builder_spec.options.init_cache_root) {
                            node.task.cmd.build.cache_root = node.cacheRoot();
                        }
                        if (builder_spec.options.init_global_cache_root) {
                            node.task.cmd.build.global_cache_root = node.globalCacheRoot();
                        }
                        if (builder_spec.options.update_executables and
                            node.task.cmd.build.kind == .exe)
                        {
                            node.task.lock = exe_lock;
                            node.dependOn(allocator, node);
                        }
                        if (testExtension(node.impl.paths[1].relative(), //
                            builder_spec.options.extensions.zig))
                        {
                            node.flags.want_build_config = true;
                        }
                    }
                }
                if (builder_spec.options.lazy_strategy == .dependency) {
                    if (node.tag == .worker and node.task.tag != .run) {
                        node.dependOn(allocator, Special.cmd_writers);
                    }
                    if (builder_spec.options.update_executables and
                        node.task.lock.int().* == exe_lock.int().*)
                    {
                        node.dependOn(allocator, Special.cmd_parsers);
                    }
                }
                if (node.tag == .group) {
                    node.task.lock = omni_lock;
                }
            }
            if (builder_spec.options.show_task_creation) {
                about.addNotice(node);
            }
        }
        fn updateCommand(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.flags.do_update = false;
            if (node.tag == .worker) {
                if (node.task.tag == .build) {
                    if (node.flags.want_build_config) {
                        if (node.flags.want_build_context) {
                            node.addConfig(allocator, "zig_exe", .{ .String = node.zigExe() });
                            node.addConfig(allocator, "build_root", .{ .String = node.buildRoot() });
                            node.addConfig(allocator, "cache_root", .{ .String = node.cacheRoot() });
                            node.addConfig(allocator, "global_cache_root", .{ .String = node.globalCacheRoot() });
                            if (node.task.cmd.build.main_pkg_path) |main_pkg_path| {
                                node.addConfig(allocator, "main_pkg_path", .{ .String = main_pkg_path });
                            }
                        }
                    }
                    if (builder_spec.options.update_debug_stack_traces) {
                        if (node.flags.want_stack_traces) {
                            if (!hasDebugInfo(node)) {
                                node.task.cmd.build.strip = false;
                            }
                            node.dependOn(allocator, Special.trace);
                            if (node.flags.want_build_config) {
                                node.addConfig(allocator, "have_stack_traces", .{ .Bool = true });
                            }
                        }
                    }
                }
                if (node.task.tag == .run) {
                    var arg: []const u8 = mem.terminate(node.impl.args[0], 0);
                    if (!mem.testEqualString(node.zigExe(), arg)) {
                        return;
                    }
                    arg = mem.terminate(node.impl.args[1], 0);
                    if (arg.len != 9) {
                        return;
                    }
                    for (&[_]types.OutputMode{ .exe, .obj, .lib }) |kind| {
                        if (mem.testEqualString(arg[arg.len -% 3 ..], @tagName(kind))) {
                            node.flags.is_build_command = true;
                            const binary_path: *types.Path = node.addPath(allocator);
                            binary_path.addName(allocator).* = node.buildRoot();
                            binary_path.addName(allocator).* = binaryRelative(allocator, node, kind);
                            break;
                        }
                    }
                }
            }
        }
        fn makeSubDirectories(node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            node.impl.build_root_fd = try meta.wrap(file.pathAt(path(), file.cwd, node.buildRoot()));
            for ([3][:0]const u8{
                builder_spec.options.output_dir,
                builder_spec.options.config_dir,
                builder_spec.options.stat_dir,
            }) |name| {
                var st: file.Status = comptime builtin.zero(file.Status);
                try meta.wrap(file.statusAt(stat(), node.impl.build_root_fd, name, &st));
                if (st.mode.kind == .unknown) {
                    try meta.wrap(file.makeDirAt(mkdir(), node.impl.build_root_fd, name, file.mode.directory));
                }
            }
            node.impl.output_root_fd = try meta.wrap(file.pathAt(path(), node.impl.build_root_fd, builder_spec.options.output_dir));
            for ([3][:0]const u8{
                builder_spec.options.exe_out_dir,
                builder_spec.options.lib_out_dir,
                builder_spec.options.aux_out_dir,
            }) |name| {
                var st: file.Status = comptime builtin.zero(file.Status);
                try meta.wrap(file.statusAt(stat(), node.impl.output_root_fd, name, &st));
                if (st.mode.kind == .unknown) {
                    try meta.wrap(file.makeDirAt(mkdir(), node.impl.output_root_fd, name, file.mode.directory));
                }
            }
            node.impl.config_root_fd = try meta.wrap(file.pathAt(path(), node.impl.build_root_fd, builder_spec.options.config_dir));
        }
        fn checkName(group: *Node, name: []const u8) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            for (name) |char| {
                if (char == builder_spec.options.namespace_separator.cmd) {
                    //
                }
                if (char == builder_spec.options.namespace_separator.fs) {
                    //
                }
            }
            var nodes_idx: usize = 1;
            while (nodes_idx != group.impl.nodes_len) : (nodes_idx +%= 1) {
                if (mem.testEqualString(name, group.impl.nodes[nodes_idx].name)) {
                    proc.exitErrorFault(error.DuplicateName, name, 2);
                }
            }
        }
        pub fn init(allocator: *mem.SimpleAllocator, args: [][*:0]u8, vars: [][*:0]u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            node.flags = .{ .is_toplevel = true };
            node.addNode(allocator).* = node;
            node.name = @constCast(builder_spec.options.toplevel_node);
            node.tag = .group;
            node.impl.paths = groupPaths(allocator, args[1..5]);
            node.impl.paths_len = 4;
            node.impl.paths_max_len = 4;
            node.task.tag = .any;
            node.task.lock = omni_lock;
            build.args = args;
            build.vars = vars;
            build.error_count = 0;
            makeSubDirectories(node);
            node.addSpecialNodes(allocator);
            if (max_thread_count != 0) {
                mem.map(map(), .{}, .{}, stack_lb_addr, stack_aligned_bytes * max_thread_count);
            }
            return node;
        }
        /// Initialize a new group command
        pub fn addGroupFull(group: *Node, allocator: *mem.SimpleAllocator, name: []const u8, zig_exe: []const u8, build_root: []const u8, cache_root: []const u8, global_cache_root: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .group;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.tag = .any;
            node.task.lock = omni_lock;
            node.addPath(allocator).addName(allocator).* = duplicate(allocator, zig_exe);
            node.addPath(allocator).addName(allocator).* = duplicate(allocator, build_root);
            node.addPath(allocator).addName(allocator).* = duplicate(allocator, cache_root);
            node.addPath(allocator).addName(allocator).* = duplicate(allocator, global_cache_root);
            if (!mem.testEqualString(node.buildRoot(), group.buildRoot())) {
                makeSubDirectories(node);
            } else {
                node.impl.build_root_fd = group.impl.build_root_fd;
                node.impl.config_root_fd = group.impl.config_root_fd;
                node.impl.output_root_fd = group.impl.output_root_fd;
            }
            initializeCommand(allocator, node);
            return node;
        }
        pub fn addGroup(group: *Node, allocator: *mem.SimpleAllocator, name: []const u8) *Node {
            return group.addGroupFull(allocator, name, group.zigExe(), group.buildRoot(), group.cacheRoot(), group.globalCacheRoot());
        }
        /// Initialize a new group command
        pub fn addRun(group: *Node, allocator: *mem.SimpleAllocator, name: []const u8, args: []const []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .worker;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.tag = .run;
            node.task.lock = run_lock;
            for (args) |arg| node.addArg(allocator).* = duplicate(allocator, arg);
            initializeCommand(allocator, node);
            return node;
        }
        /// Initialize a new `zig build-(exe|obj|lib)` command.
        pub fn addBuild(group: *Node, allocator: *mem.SimpleAllocator, build_cmd: types.BuildCommand, name: []const u8, root: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            comptime do_build = true;
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            const binary_path: *types.Path = node.addPath(allocator);
            const root_path: *types.Path = node.addPath(allocator);
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .worker;
            node.task.tag = .build;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.cmd.build = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(types.BuildCommand),
                @alignOf(types.BuildCommand),
            ));
            node.task.cmd.build.* = build_cmd;
            binary_path.addName(allocator).* = group.buildRoot();
            binary_path.addName(allocator).* = binaryRelative(allocator, node, build_cmd.kind);
            root_path.addName(allocator).* = group.buildRoot();
            root_path.names_len -%= @intFromBool(root[0] == '/');
            root_path.addName(allocator).* = duplicate(allocator, root);
            initializeCommand(allocator, node);
            return node;
        }
        /// Initialize a new `zig fmt` command.
        pub fn addFormat(group: *Node, allocator: *mem.SimpleAllocator, format_cmd: types.FormatCommand, name: []const u8, pathname: []const u8) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            comptime do_format = true;
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            const target_path: *types.Path = node.addPath(allocator);
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .worker;
            node.task.tag = .format;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.cmd.format = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(types.FormatCommand),
                @alignOf(types.FormatCommand),
            ));
            node.task.cmd.format.* = format_cmd;
            target_path.addName(allocator).* = group.buildRoot();
            target_path.names_len -%= @intFromBool(pathname[0] == '/');
            target_path.addName(allocator).* = duplicate(allocator, pathname);
            initializeCommand(allocator, node);
            return node;
        }
        /// Initialize a new `zig ar` command.
        pub fn addArchive(group: *Node, allocator: *mem.SimpleAllocator, archive_cmd: types.ArchiveCommand, name: []const u8, deps: []const *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            comptime do_archive = true;
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            const archive_path: *types.Path = node.addPath(allocator);
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .worker;
            node.task.tag = .archive;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.task.cmd.archive = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(types.ArchiveCommand),
                @alignOf(types.ArchiveCommand),
            ));
            node.task.cmd.archive.* = archive_cmd;
            archive_path.addName(allocator).* = group.buildRoot();
            archive_path.addName(allocator).* = archiveRelative(allocator, node.name);
            for (deps) |dep| node.dependOn(allocator, dep);
            initializeCommand(allocator, node);
            return node;
        }
        /// Initialize a new `zig objcopy` command.
        pub fn addObjcopy(group: *Node, allocator: *mem.SimpleAllocator, objcopy_cmd: types.ObjcopyCommand, name: []const u8, holder: *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            comptime do_objcopy = true;
            const node: *Node = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node),
                @alignOf(Node),
            ));
            checkName(group, name);
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.tag = .worker;
            node.task.tag = .build;
            node.flags = .{};
            node.name = duplicate(allocator, name);
            node.addPath(allocator).* = holder.paths[0];
            node.task.cmd.objcopy = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(types.ObjcopyCommand),
                @alignOf(types.ObjcopyCommand),
            ));
            node.task.cmd.objcopy.* = objcopy_cmd;
            initializeCommand(allocator, node);
            return node;
        }
        /// Initialize a new group command with default task.
        pub fn addGroupWithTask(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            name: []const u8,
            task: types.Task,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addGroup(allocator, name);
            ret.task.tag = task;
            return ret;
        }
        /// Initialize a new group command with description.
        pub fn addGroupWithDescr(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            name: []const u8,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addGroup(allocator, name);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig build-*` command with description.
        pub fn addBuildWithDescr(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            build_cmd: types.BuildCommand,
            name: []const u8,
            root: []const u8,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addBuild(allocator, build_cmd, name, root);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig fmt` command with description.
        pub fn addFormatWithDescr(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            format_cmd: types.FormatCommand,
            name: []const u8,
            pathname: []const u8,
            descr: [:0]const u8,
        ) !*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addFormat(allocator, format_cmd, name, pathname);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig ar` command with description.
        pub fn addArchiveWithDescr(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            archive_cmd: types.ArchiveCommand,
            name: []const u8,
            deps: []const *Node,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addArchive(allocator, archive_cmd, name, deps);
            ret.descr = descr;
            return ret;
        }
        /// Initialize a new `zig objcopy` command with description.
        pub fn addObjcopyWithDescr(
            group: *Node,
            allocator: *mem.SimpleAllocator,
            objcopy_cmd: types.ObjcopyCommand,
            name: []const u8,
            holder: *Node,
            descr: [:0]const u8,
        ) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const ret: *Node = group.addObjcopy(allocator, objcopy_cmd, name, holder);
            ret.descr = descr;
            return ret;
        }
        pub fn updateCommands(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (!node.flags.do_update) {
                return;
            }
            updateCommand(allocator, node);
            for (node.impl.nodes[1..node.impl.nodes_len]) |sub| {
                updateCommands(allocator, sub);
            }
            for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                updateCommands(allocator, dep.on_node);
            }
            if (builder_spec.options.show_base_memory_usage and
                node.flags.is_toplevel)
            {
                about.baseMemoryUsageNotice(allocator);
            }
        }
        pub fn addBuildAnon(group: *Node, allocator: *mem.SimpleAllocator, build_cmd: types.BuildCommand, root: [:0]const u8) *Node {
            return group.addBuild(allocator, build_cmd, makeCommandName(allocator, root), root);
        }
        pub const dependOnFull = addDependency;

        pub fn dependOn(node: *Node, allocator: *mem.SimpleAllocator, on_node: *Node) void {
            node.addDependency(allocator, if (node == on_node) .run else node.task.tag, on_node, on_node.task.tag);
        }
        pub const impl = struct {
            fn system(args: [][*:0]u8, ts: *time.TimeSpec) u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const exe: [:0]const u8 = mem.terminate(args[0], 0);
                ts.* = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(file.execPath(execve(), exe, args, build.vars));
                }
                const ret: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                ts.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), ts.*);
                return proc.Status.exit(ret.status);
            }
            fn server(allocator: *mem.SimpleAllocator, node: *Node, args: [][*:0]u8, ts: *time.TimeSpec, ans: *UpdateAnswer, dest_pathname: [:0]const u8) u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const in: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                const out: file.Pipe = try meta.wrap(file.makePipe(pipe()));
                ts.* = try meta.wrap(time.get(clock(), .realtime));
                const pid: u64 = try meta.wrap(proc.fork(fork()));
                if (pid == 0) {
                    try meta.wrap(openChild(in, out));
                    try meta.wrap(file.execPath(execve(), node.zigExe(), args, build.vars));
                }
                try meta.wrap(openParent(in, out));
                try meta.wrap(file.write(write2(), in.write, update_exit_message[0..1]));
                const save: u64 = allocator.next;
                var fd: file.PollFd = .{ .fd = out.read, .expect = .{ .input = true } };
                while (try meta.wrap(file.pollOne(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                    var hdr: types.Message.ServerHeader = comptime builtin.zero(types.Message.ServerHeader);
                    try meta.wrap(file.readOne(read3(), out.read, &hdr));
                    const msg: [*:0]align(4) u8 = @ptrFromInt(allocator.allocateRaw(hdr.bytes_len +% 64, 4));
                    @memset(msg[0 .. hdr.bytes_len +% 1], 0);
                    var len: usize = 0;
                    while (len != hdr.bytes_len) {
                        len +%= try meta.wrap(file.read(read2(), out.read, msg[len..hdr.bytes_len]));
                    }
                    if (hdr.tag == .emit_bin_path) {
                        ans.* = @enumFromInt(msg[0]);
                        const src_pathname: [:0]const u8 = mem.terminate(msg + 1, 0);
                        if (!sameFile(dest_pathname, src_pathname)) {
                            file.unlink(unlink(), dest_pathname);
                            file.link(link(), src_pathname, dest_pathname);
                        }
                        break;
                    }
                    if (hdr.tag == .error_bundle) {
                        ans.* = @enumFromInt(builder_spec.options.compiler_error_status);
                        about.writeErrors(allocator, @ptrCast(msg));
                        break;
                    }
                    allocator.next = save;
                } else if (fd.actual.hangup) {
                    ans.* = @enumFromInt(builder_spec.options.compiler_error_status);
                }
                try meta.wrap(file.write(write2(), in.write, update_exit_message[1..2]));
                const rc: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
                ts.* = time.diff(try meta.wrap(time.get(clock(), .realtime)), ts.*);
                try meta.wrap(file.close(close(), in.write));
                try meta.wrap(file.close(close(), out.read));
                return proc.Status.exit(rc.status);
            }
            fn taskArgs(allocator: *mem.SimpleAllocator, node: *Node, task: types.Task, arena_index: AddressSpace.Index) [][*:0]u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (task == .run) {
                    if (node.flags.is_primary) {
                        for (build.run_args) |run_arg| node.addArg(allocator).* = run_arg;
                    }
                    node.addArg(allocator).* = comptime builtin.zero([*:0]u8);
                    node.impl.args_len -%= 1;
                    return node.impl.args[0..node.impl.args_len];
                } else {
                    if (builder_spec.options.lazy_strategy != .none) {
                        if (node.flags.is_primary and build.cmd_args.len != 0) {
                            if (builder_spec.options.lazy_strategy == .emergency) {
                                executeCommandEmergency(allocator, Special.cmd_parsers, .run, arena_index);
                            }
                            if (do_build and task == .build) {
                                Special.fns.formatParseArgsBuildCommand(node.task.cmd.build, allocator, build.cmd_args.ptr, build.cmd_args.len);
                            }
                            if (do_format and task == .format) {
                                Special.fns.formatParseArgsFormatCommand(node.task.cmd.format, allocator, build.cmd_args.ptr, build.cmd_args.len);
                            }
                            if (do_archive and task == .archive) {
                                Special.fns.formatParseArgsArchiveCommand(node.task.cmd.archive, allocator, build.cmd_args.ptr, build.cmd_args.len);
                            }
                            if (do_objcopy and task == .objcopy) {
                                Special.fns.formatParseArgsObjcopyCommand(node.task.cmd.objcopy, allocator, build.cmd_args.ptr, build.cmd_args.len);
                            }
                        }
                        if (builder_spec.options.lazy_strategy == .emergency) {
                            executeCommandEmergency(allocator, Special.cmd_writers, .run, arena_index);
                        }
                        const zig_exe: []const u8 = node.zigExe();
                        if (do_build and task == .build) {
                            const paths: []const types.Path = node.impl.paths[1..node.impl.paths_len];
                            const cmd: *types.BuildCommand = node.task.cmd.build;
                            const max_len: usize = Special.fns.formatLengthBuildCommand(cmd, zig_exe.ptr, zig_exe.len, paths.ptr, paths.len);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = Special.fns.formatWriteBufBuildCommand(cmd, zig_exe.ptr, zig_exe.len, paths.ptr, paths.len, buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_format and task == .format) {
                            const cmd: *build.FormatCommand = node.task.cmd.format;
                            const max_len: usize = Special.fns.formatLengthFormatCommand(cmd, zig_exe.ptr, zig_exe.len, node.impl.paths[0]);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = Special.fns.formatWriteBufFormatCommand(cmd, zig_exe.ptr, zig_exe.len, node.impl.paths[0], buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_archive and task == .archive) {
                            const paths: []const types.Path = node.impl.paths[0..node.impl.paths_len];
                            const cmd: *build.ArchiveCommand = node.task.cmd.archive;
                            const max_len: usize = Special.fns.formatLengthArchiveCommand(cmd, zig_exe.ptr, zig_exe.len, paths.ptr, paths.len);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = Special.fns.formatWriteBufArchiveCommand(cmd, zig_exe.ptr, zig_exe.len, paths.ptr, paths.len, buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_objcopy and task == .objcopy) {
                            const cmd: *types.ObjcopyCommand = node.task.cmd.objcopy;
                            const max_len: usize = Special.fns.formatLengthObjcopyCommand(cmd, zig_exe.ptr, zig_exe.len, node.impl.paths[1]);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = Special.fns.formatWriteBufObjcopyCommand(cmd, zig_exe.ptr, zig_exe.len, node.impl.paths[1], buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                    } else {
                        if (node.flags.is_primary and build.cmd_args.len != 0) {
                            if (do_build and task == .build) {
                                node.task.cmd.build.formatParseArgs(allocator, build.cmd_args);
                            }
                            if (do_format and task == .format) {
                                node.task.cmd.format.formatParseArgs(allocator, build.cmd_args);
                            }
                            if (do_archive and task == .archive) {
                                node.task.cmd.archive.formatParseArgs(allocator, build.cmd_args);
                            }
                            if (do_objcopy and task == .objcopy) {
                                node.task.cmd.objcopy.formatParseArgs(allocator, build.cmd_args);
                            }
                        }
                        const zig_exe: []const u8 = node.zigExe();
                        if (do_build and task == .build) {
                            const paths: []const types.Path = node.impl.paths[1..node.impl.paths_len];
                            const cmd: *types.BuildCommand = node.task.cmd.build;
                            const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, paths);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = cmd.formatWriteBuf(zig_exe, paths, buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_format and task == .format) {
                            const cmd: *build.FormatCommand = node.task.cmd.format;
                            const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, node.impl.paths[0]);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = cmd.formatWriteBuf(zig_exe, node.impl.paths[0], buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_archive and task == .archive) {
                            const paths: []const types.Path = node.impl.paths[0..node.impl.paths_len];
                            const cmd: *build.ArchiveCommand = node.task.cmd.archive;
                            const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, paths);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = cmd.formatWriteBuf(zig_exe, paths, buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                        if (do_objcopy and task == .objcopy) {
                            const cmd: *types.ObjcopyCommand = node.task.cmd.objcopy;
                            const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(zig_exe, node.impl.paths[1]);
                            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                            const len: usize = cmd.formatWriteBuf(zig_exe, node.impl.paths[1], buf);
                            buf[len] = 0;
                            return makeArgPtrs(allocator, buf[0..len :0]);
                        }
                    }
                }
                proc.exitError(error.InvalidTask, 2);
            }
            fn executeCommandEmergency(
                allocator: *mem.SimpleAllocator,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: usize = allocator.next;
                defer allocator.next = save;
                if (keepGoing() and
                    node.exchange(task, .ready, .working, arena_index))
                {
                    if (executeCommandInternal(allocator, node, task, arena_index)) {
                        node.assertExchange(task, .working, .finished, arena_index);
                    } else {
                        if (count_errors) {
                            build.error_count +%= 1;
                        }
                        node.assertExchange(task, .working, .failed, arena_index);
                    }
                }
                while (node.task.lock.get(task) != .finished) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
            }
            fn executeCommandInternal(allocator: *mem.SimpleAllocator, node: *Node, task: types.Task, arena_index: AddressSpace.Index) bool {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: usize = allocator.next;
                defer allocator.next = save;
                var st: file.Status = comptime builtin.zero(file.Status);
                var ts: time.TimeSpec = comptime builtin.zero(time.TimeSpec);
                var ans: UpdateAnswer = .updated;
                var rc: u8 = 0;
                if (builder_spec.options.write_build_configuration and
                    node.flags.want_build_config and
                    task == .build)
                {
                    makeConfigRoot(allocator, node);
                }
                var old_size: u64 = 0;
                var new_size: u64 = 0;
                const args: [][*:0]u8 = taskArgs(allocator, node, task, arena_index);
                const dest_pathname: [:0]const u8 = node.impl.paths[0].concatenate(allocator);
                switch (task) {
                    else => {
                        rc = try meta.wrap(impl.system(args, &ts));
                    },
                    .build, .archive => {
                        try meta.wrap(file.statusAt(stat(), file.cwd, dest_pathname, &st));
                        old_size = st.size;
                        if (task == .build) {
                            rc = try meta.wrap(impl.server(allocator, node, args, &ts, &ans, dest_pathname));
                        } else {
                            rc = try meta.wrap(impl.system(args, &ts));
                        }
                        try meta.wrap(file.statusAt(stat(), file.cwd, dest_pathname, &st));
                        new_size = st.size;
                    },
                    .run => {
                        if (node.flags.is_build_command) {
                            const root_pathname: [:0]const u8 = mem.terminate(node.impl.args[node.impl.args_len -% 1], 0);
                            if (node.flags.want_shallow_cache_check) {
                                ans = shallowCacheCheck(&st, dest_pathname, root_pathname);
                            }
                            rc = try meta.wrap(impl.server(allocator, node, args, &ts, &ans, dest_pathname));
                        } else {
                            rc = try meta.wrap(impl.system(args, &ts));
                        }
                    },
                }
                if (builder_spec.options.show_stats and
                    keepGoing())
                {
                    about.taskNotice(node, task, arena_index, old_size, new_size, ts.sec, ts.nsec, ans, rc);
                }
                if (builder_spec.options.lazy_strategy != .none and
                    node.flags.is_dyn_ext)
                {
                    Special.dyn_loader.load(dest_pathname).loadPointers(build.Fns, &Special.fns);
                }
                return status(ans, rc);
            }
            fn shallowCacheCheck(st: *file.Status, dest_pathname: [:0]const u8, root_pathname: [:0]const u8) UpdateAnswer {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                try meta.wrap(file.statusAt(stat(), file.cwd, dest_pathname, st));
                const dest_sec: usize = st.mtime.sec;
                try meta.wrap(file.statusAt(stat(), file.cwd, root_pathname, st));
                const src_sec: usize = st.mtime.sec;
                return if (dest_sec > src_sec) .cached else .updated;
            }
            fn sameFile(pathname1: [:0]const u8, pathname2: [:0]const u8) bool {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var st1: file.Status = comptime builtin.zero(file.Status);
                var st2: file.Status = comptime builtin.zero(file.Status);
                try meta.wrap(file.statusAt(stat(), file.cwd, pathname1, &st1));
                if (st1.mode.kind == .unknown) {
                    return false;
                }
                try meta.wrap(file.statusAt(stat(), file.cwd, pathname2, &st2));
                if (st2.mode.kind == .unknown) {
                    return false;
                }
                return ((st1.dev == st2.dev) and (st1.ino == st2.ino));
            }
            fn spawnDeps(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *mem.SimpleAllocator,
                group: *Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                for (node.impl.nodes[1..node.impl.nodes_len]) |sub_node| {
                    if (sub_node == node and sub_node.task.tag == task) {
                        continue;
                    }
                    if (keepGoing() and
                        sub_node.exchange(task, .ready, .blocking, arena_index))
                    {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, group, sub_node, task, arena_index));
                    }
                }
                for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                    if (dep.on_node == node and
                        dep.on_task == task or dep.task != task)
                    {
                        continue;
                    }
                    if (keepGoing() and
                        dep.on_node.exchange(dep.on_task, .ready, .blocking, arena_index))
                    {
                        try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, group, dep.on_node, dep.on_task, arena_index));
                    }
                }
            }
            extern fn forwardToExecuteCloneThreaded(
                address_space: *Node.AddressSpace,
                thread_space: *Node.ThreadSpace,
                group: *const Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
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
                group: *Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (max_thread_count == 0) {
                    unreachable;
                }
                var allocator: mem.SimpleAllocator = mem.SimpleAllocator.init_arena(Node.AddressSpace.arena(arena_index));
                impl.spawnDeps(address_space, thread_space, &allocator, group, node, task, arena_index);
                while (keepGoing() and
                    nodeWait(node, task, arena_index))
                {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (keepGoing() and node.task.lock.get(task) == .working) {
                    if (executeCommandInternal(&allocator, node, task, arena_index)) {
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
                group: *Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const save: usize = allocator.next;
                defer allocator.next = save;
                impl.spawnDeps(address_space, thread_space, allocator, group, node, task, arena_index);
                while (keepGoing() and nodeWait(node, task, arena_index)) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                }
                if (node.task.lock.get(task) == .working) {
                    if (executeCommandInternal(allocator, node, task, arena_index)) {
                        node.assertExchange(task, .working, .finished, arena_index);
                    } else {
                        if (count_errors) {
                            build.error_count +%= 1;
                        }
                        node.assertExchange(task, .working, .failed, arena_index);
                    }
                }
            }
            fn tryAcquireThread(
                address_space: *AddressSpace,
                thread_space: *ThreadSpace,
                allocator: *mem.SimpleAllocator,
                group: *Node,
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (max_thread_count != 0) {
                    var idx: AddressSpace.Index = 0;
                    while (idx != max_thread_count) : (idx +%= 1) {
                        if (mem.testAcquire(ThreadSpace, thread_space, idx)) {
                            const addr: u64 = ThreadSpace.low(idx);
                            return forwardToExecuteCloneThreaded(address_space, thread_space, group, node, task, idx, addr, stack_aligned_bytes);
                        }
                    }
                }
                try meta.wrap(impl.executeCommandSynchronised(address_space, thread_space, allocator, group, node, task, arena_index));
            }
        };
        pub fn executeSubNode(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *mem.SimpleAllocator,
            group: *Node,
            node: *Node,
            maybe_task: ?types.Task,
        ) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const task: types.Task = maybe_task orelse node.task.tag;
            if (node.exchange(task, .ready, .blocking, max_thread_count)) {
                try meta.wrap(impl.tryAcquireThread(address_space, thread_space, allocator, group, node, task, max_thread_count));
            }
            while (toplevelWait(group, thread_space)) {
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
                proc.exitError(error.NoExchange, 2);
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
            for (node.impl.nodes[1..node.impl.nodes_len]) |sub_node| {
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
                if (keepGoing()) {
                    if (node.tag == .worker) {
                        node.assertExchange(task, .blocking, .working, arena_index);
                    } else {
                        node.assertExchange(task, .blocking, .finished, arena_index);
                    }
                } else {
                    node.assertExchange(task, .blocking, .failed, arena_index);
                }
            }
            return false;
        }
        fn toplevelWait(node: *Node, thread_space: *ThreadSpace) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (builder_spec.options.show_waiting_tasks) {
                if (node.impl.wait_len >> 28 > node.impl.wait_tick) {
                    about.writeWaitingOn(node, max_thread_count);
                    node.impl.wait_tick +%= 1;
                } else {
                    node.impl.wait_len +%= builder_spec.options.sleep_nanoseconds;
                }
            }
            if (max_thread_count == 0) {
                return false;
            }
            if (thread_space.count() != 0) {
                return true;
            }
            return false;
        }
        fn status(ans: UpdateAnswer, rc: u8) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (ans == .failed) {
                return false;
            }
            return rc == builder_spec.options.system_expected_status;
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
        pub fn toplevelNode(node: *Node) *Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.flags.is_toplevel) {
                return node;
            }
            return node.impl.nodes[0].toplevelNode();
        }
        pub fn zigExe(node: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].zigExe();
            }
            return node.impl.paths[0].names[0];
        }
        pub fn buildRoot(node: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].buildRoot();
            }
            return node.impl.paths[1].names[0];
        }
        pub fn cacheRoot(node: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].cacheRoot();
            }
            return node.impl.paths[2].names[0];
        }
        pub fn globalCacheRoot(node: *Node) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].globalCacheRoot();
            }
            return node.impl.paths[3].names[0];
        }
        pub fn buildRootFd(node: *Node) u32 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].buildRoot();
            }
            return node.impl.build_root_fd;
        }
        pub fn configRootFd(node: *Node) u32 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].configRootFd();
            }
            return node.impl.config_root_fd;
        }
        pub fn outputRootFd(node: *Node) u32 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.tag == .worker) {
                return node.impl.nodes[0].outputRootFd();
            }
            return node.impl.output_root_fd;
        }
        pub fn hasDebugInfo(node: *Node) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            if (node.task.cmd.build.strip) |strip| {
                return !strip;
            } else {
                return (node.task.cmd.build.mode orelse .Debug) != .ReleaseSmall;
            }
        }
        fn binaryRelative(allocator: *mem.SimpleAllocator, node: *Node, kind: types.OutputMode) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var buf: [512]u8 = undefined;
            const name: []u8 = if (builder_spec.options.output_strategy == .full_name) blk: {
                const len: usize = about.writeNodeNameFull(&buf, node, '-');
                break :blk buf[0..len];
            } else node.name;
            return concatenate(allocator, switch (kind) {
                .exe => &[_][]const u8{ binary_prefix, name },
                .obj => &[_][]const u8{ binary_prefix, name, builder_spec.options.extensions.obj },
                .lib => &[_][]const u8{ library_prefix, name, builder_spec.options.extensions.lib },
            });
        }
        fn archiveRelative(allocator: *mem.SimpleAllocator, name: [:0]u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return concatenate(allocator, &[_][]const u8{ archive_prefix, name, builder_spec.options.extensions.ar });
        }
        fn auxiliaryRelative(allocator: *mem.SimpleAllocator, node: *Node, kind: types.AuxOutputMode) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var buf: [512]u8 = undefined;
            const name: []u8 = if (builder_spec.options.output_strategy == .full_name) blk: {
                const len: usize = about.writeNodeNameFull(&buf, node, '-');
                break :blk buf[0..len];
            } else node.name;
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
        pub fn find(group: *Node, name: []const u8) ?*Node {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var idx: usize = 0;
            while (idx != name.len) : (idx +%= 1) {
                if (name[idx] == builder_spec.options.namespace_separator.cmd) {
                    break;
                }
            } else {
                idx = 1;
                while (idx != group.impl.nodes_len) : (idx +%= 1) {
                    if (mem.testEqualString(name, group.impl.nodes[idx].name)) {
                        return group.impl.nodes[idx];
                    }
                }
                return null;
            }
            const group_name: []const u8 = name[0..idx];
            idx +%= 1;
            if (idx == name.len) {
                return null;
            }
            const sub_name: []const u8 = name[idx..];
            idx = 1;
            while (idx != group.impl.nodes_len) : (idx +%= 1) {
                if (group.impl.nodes[idx].tag == .group and
                    mem.testEqualString(group_name, group.impl.nodes[idx].name))
                {
                    return find(group.impl.nodes[idx], sub_name);
                }
            }
            return null;
        }
        fn splitArguments(cmd_args_idx: usize) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var run_args_idx: usize = cmd_args_idx;
            while (run_args_idx != build.args.len) : (run_args_idx +%= 1) {
                if (mem.testEqualString("--", mem.terminate(build.args[run_args_idx], 0))) {
                    build.cmd_args = build.args[cmd_args_idx..run_args_idx];
                    run_args_idx +%= 1;
                    build.run_args = build.args[run_args_idx..];
                    break;
                }
            } else {
                build.cmd_args = build.args[cmd_args_idx..];
                build.run_args = build.args[cmd_args_idx..];
            }
            if (builder_spec.options.show_command_lines) {
                about.commandLineNotice();
            }
        }
        fn setPrimary(node: *Node, maybe_task: ?types.Task) void {
            if (node.tag == .group) {
                const task: types.Task = maybe_task orelse node.task.tag;
                for (node.impl.nodes[1..node.impl.nodes_len]) |sub_node| {
                    if (sub_node.task.tag == task) {
                        sub_node.flags.is_primary = true;
                    }
                }
            } else {
                node.flags.is_primary = true;
            }
        }
        pub fn processCommands(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *mem.SimpleAllocator,
            group: *Node,
        ) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            var maybe_task: ?types.Task = null;
            var cmd_args_idx: usize = 5;
            lo: while (cmd_args_idx != build.args.len) : (cmd_args_idx +%= 1) {
                var name: [:0]const u8 = mem.terminate(build.args[cmd_args_idx], 0);
                for (types.Task.list) |task| {
                    if (mem.testEqualString(name, @tagName(task))) {
                        maybe_task = task;
                        continue :lo;
                    }
                }
                if (mem.testEqualString(builder_spec.options.toplevel_list_command, name)) {
                    return about.groupCommandNotice(allocator, group, true);
                }
                if (group.find(name)) |node| {
                    setPrimary(node, maybe_task);
                    group.impl.args_len = @intCast(cmd_args_idx +% 1);
                    splitArguments(cmd_args_idx +% 1);
                    if (!executeSubNode(address_space, thread_space, allocator, group, node, maybe_task)) {
                        proc.exitError(error.UnfinishedRequest, 2);
                    }
                    break;
                }
            } else {
                if (group == group.impl.nodes[0]) {} else {
                    about.groupCommandNotice(allocator, group, false);
                    proc.exitErrorFault(error.NotACommand, //
                        if (build.args.len == 5) about.tab.null_s else mem.terminate(build.args[5], 0), 2);
                }
            }
        }

        fn clock() time.ClockSpec {
            return .{ .errors = builder_spec.errors.clock };
        }
        fn sleep() time.SleepSpec {
            return .{ .errors = builder_spec.errors.sleep };
        }
        fn path() file.PathSpec {
            return .{
                .return_type = u32,
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
        pub fn testExtension(name: []const u8, extension: []const u8) bool {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            return extension.len < name.len and
                mem.testEqualString(extension, name[name.len -% extension.len ..]);
        }
        fn keepGoing() bool {
            if (impl.count_errors) {
                return build.error_count <= builder_spec.options.max_error_count.?;
            } else {
                comptime return true;
            }
        }
        const lib_cache_root = builtin.lib_root ++ "/" ++ builder_spec.options.cache_dir;
        const cmd_writers_root = builtin.lib_root ++ "/" ++ builder_spec.options.cmd_writers_root;
        const cmd_parsers_root = builtin.lib_root ++ "/" ++ builder_spec.options.cmd_parsers_root;
        const perf_events_root = builtin.lib_root ++ "/" ++ builder_spec.options.perf_events_root;
        const binary_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.exe_out_dir ++ "/";
        const library_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.lib_out_dir ++ "/lib";
        const archive_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.lib_out_dir ++ "/lib";
        const auxiliary_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.aux_out_dir ++ "/";
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
            .map = builder_spec.errors.map,
            .remap = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const address_space_errors = .{
            .release = .ignore,
            .acquire = .ignore,
            .map = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const dyn_loader_options = .{
            .lb_info_addr = load_info_lb_addr,
            .lb_sect_addr = load_sect_lb_addr,
        };
        const dyn_loader_errors = .{
            .open = builder_spec.errors.open,
            .seek = builder_spec.errors.seek,
            .read = builder_spec.errors.read,
            .close = builder_spec.errors.close,
            .map = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const dyn_loader_logging = .{
            .open = builder_spec.logging.open,
            .seek = builder_spec.logging.seek,
            .read = builder_spec.logging.read,
            .close = builder_spec.logging.close,
            .map = builder_spec.logging.map,
            .unmap = builder_spec.logging.unmap,
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
        const trace_build_cmd = .{
            .kind = .obj,
            .pic = true,
            .mode = .ReleaseSmall,
            .strip = true,
            .compiler_rt = false,
        };
        const omni_lock: types.Lock = .{ .bytes = .{
            .null,  .ready, .ready, .ready,
            .ready, .ready, .null,
        } };
        const obj_lock: types.Lock = .{ .bytes = .{
            .null, .null, .null, .ready,
            .null, .null, .null,
        } };
        const exe_lock: types.Lock = .{ .bytes = .{
            .null,  .null, .null, .ready,
            .ready, .null, .null,
        } };
        const run_lock: types.Lock = .{ .bytes = .{
            .null,  .null, .null, .null,
            .ready, .null, .null,
        } };
        const format_lock: types.Lock = .{ .bytes = .{
            .null, .null, .ready, .null,
            .null, .null, .null,
        } };
        const archive_lock: types.Lock = .{ .bytes = .{
            .null, .null,  .null, .null,
            .null, .ready, .null,
        } };
        pub fn duplicate(allocator: *mem.SimpleAllocator, values: []const u8) [:0]u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(values.len +% 1, 1));
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
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len +% 1, 1));
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
            const ret: [*][*:0]u8 = @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 1));
            var len: usize = 0;
            var idx: usize = 0;
            var pos: u64 = 0;
            while (idx != args.len) : (idx +%= 1) {
                if (args[idx] == 0 or
                    args[idx] == '\n')
                {
                    ret[len] = args[pos..idx :0];
                    len +%= 1;
                    pos = idx +% 1;
                }
            }
            ret[len] = @ptrFromInt(8);
            ret[len] -= 8;
            return ret[0..len];
        }
        fn makeCommandName(allocator: *mem.SimpleAllocator, root: [:0]const u8) [:0]const u8 {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(root.len +% 1, 1));
            @memcpy(buf, root);
            buf[root.len] = 0;
            var idx: usize = 0;
            while (idx != root.len and buf[idx] != 0x2e) : (idx +%= 1) {
                buf[idx] -%= @intFromBool(buf[idx] == 0x2f);
            }
            buf[idx] = 0;
            return buf[0..idx :0];
        }
        fn makeConfigRoot(allocator: *mem.SimpleAllocator, node: *Node) void {
            @setRuntimeSafety(builder_spec.options.enable_safety);
            const build_cmd: *types.BuildCommand = node.task.cmd.build;
            if (!keepGoing()) {
                return;
            }
            var file_buf: [32768]u8 = undefined;
            var ptr: [*]u8 = &file_buf;
            ptr[0..31].* = "pub usingnamespace @import(\"../".*;
            ptr += 31;
            @memcpy(ptr, node.impl.paths[1].names[1]);
            ptr += node.impl.paths[1].names[1].len;
            ptr[0..4].* = "\");\n".*;
            ptr += 4;
            ptr[0..31].* = "pub const dependencies=struct{\n".*;
            ptr += 31;
            if (build_cmd.dependencies) |dependencies| {
                for (dependencies) |dependency| {
                    ptr[0..12].* = "pub const @\"".*;
                    ptr += 12;
                    @memcpy(ptr, dependency.name);
                    ptr += dependency.name.len;
                    ptr[0..16].* = "\":?[:0]const u8=".*;
                    ptr += 16;
                    if (dependency.import) |import| {
                        ptr[0] = '"';
                        ptr += 1;
                        @memcpy(ptr, import);
                        ptr += import.len;
                        ptr[0..3].* = "\";\n".*;
                        ptr += 3;
                    } else {
                        ptr[0..6].* = "null;\n".*;
                        ptr += 6;
                    }
                }
            }
            ptr[0..29].* = "};\npub const modules=struct{\n".*;
            ptr += 29;
            if (build_cmd.modules) |modules| {
                for (modules) |module| {
                    ptr[0..12].* = "pub const @\"".*;
                    ptr += 12;
                    @memcpy(ptr, module.name);
                    ptr += module.name.len;
                    ptr[0..15].* = "\":[:0]const u8=".*;
                    ptr += 15;
                    ptr[0] = '"';
                    ptr += 1;
                    @memcpy(ptr, module.path);
                    ptr += module.path.len;
                    ptr[0..3].* = "\";\n".*;
                    ptr += 3;
                }
            }
            for ([2]types.OutputMode{ .obj, .lib }) |out| {
                if (out == .obj) {
                    ptr[0..35].* = "};\npub const compile_units=struct{\n".*;
                    ptr += 35;
                } else {
                    ptr[0..35].* = "};\npub const dynamic_units=struct{\n".*;
                    ptr += 35;
                }
                for (node.impl.deps[0..node.impl.deps_len]) |dep| {
                    if (dep.on_node == node) {
                        continue;
                    }
                    if (dep.on_task == .build and
                        dep.on_node.task.cmd.build.kind == out)
                    {
                        ptr[0..12].* = "pub const @\"".*;
                        ptr += 12;
                        @memcpy(ptr, dep.on_node.name);
                        ptr += dep.on_node.name.len;
                        ptr[0..15].* = "\":[:0]const u8=".*;
                        ptr += 15;
                        ptr[0] = '"';
                        ptr += 1;
                        ptr += dep.on_node.impl.paths[0].formatWriteBuf(ptr);
                        ptr = ptr - 1;
                        ptr[0..3].* = "\";\n".*;
                        ptr += 3;
                    }
                }
            }
            ptr[0..3].* = "};\n".*;
            ptr += 3;
            for (node.impl.cfgs[0..node.impl.cfgs_len]) |cfg| {
                ptr += cfg.formatWriteBuf(ptr);
            }
            if (builder_spec.options.write_hist_serial) {
                var hist: types.hist_tasks.BuildCommand = types.hist_tasks.BuildCommand.convert(node.task.cmd.build);
                const bytes = @as(*[@sizeOf(types.hist_tasks.BuildCommand)]u8, @ptrCast(&hist));
                ptr[0..31].* = "pub const serial:[]const u8=&.{".*;
                ptr += 31;
                for (bytes) |byte| {
                    ptr += fmt.ud64(byte).formatWriteBuf(ptr);
                    ptr[0] = ',';
                    ptr += 1;
                }
                ptr = ptr - 1;
                ptr[0..3].* = "};\n".*;
                ptr += 3;
            }
            ptr[0..26].* = "pub const build_config=.@\"".*;
            ptr += 26;
            @memcpy(ptr, node.name);
            ptr += node.name.len;
            ptr[0..3].* = "\";\n".*;
            ptr += 3;
            const file_len: usize = @intFromPtr(ptr - @intFromPtr(&file_buf));
            var name_buf: [512]u8 = undefined;
            ptr = name_buf[about.writeNodeNameFull(&name_buf, node, '-')..].ptr;
            ptr[0..4].* = ".zig".*;
            ptr += 4;
            ptr[0] = 0;
            const name_len: usize = @intFromPtr(ptr - @intFromPtr(&name_buf));
            const root_fd: u64 = try meta.wrap(file.createAt(create(), node.configRootFd(), name_buf[0..name_len :0], file.mode.regular));
            file.write(write(), root_fd, file_buf[0..file_len]);
            file.close(close(), root_fd);
            node.impl.paths[1].names[1] = builder_spec.options.config_dir;
            node.impl.paths[1].addName(allocator).* = duplicate(allocator, name_buf[0..name_len :0]);
        }
        const about = struct {
            const tab = .{
                .ar_s = fmt.about("ar"),
                .run_s = fmt.about("run"),
                .add_s = fmt.about("add"),
                .mem_s = fmt.about("mem"),
                .fmt_s = fmt.about("fmt"),
                .perf_s = fmt.about("perf"),
                .unknown_s = fmt.about("unknown"),
                .cmd_args_s = fmt.about("cmd-args"),
                .run_args_s = fmt.about("run-args"),
                .build_exe_s = fmt.about("build-exe"),
                .build_obj_s = fmt.about("build-obj"),
                .build_lib_s = fmt.about("build-lib"),
                .state_s = fmt.about("state"),
                .state_1_s = fmt.about("state-fault"),
                .waiting_s = fmt.about("waiting"),
                .null_s = "(null)",
                .bytes_s = " bytes, ",
                .green_s = "\x1b[92;1m",
                .red_s = "\x1b[91;1m",
                .new_s = "\x1b[0m\n",
                .reset_s = "\x1b[0m",
                .gold_s = "\x1b[93m",
                .bold_s = "\x1b[1m",
                .faint_s = "\x1b[2m",
                .hi_green_s = "\x1b[38;5;46m",
                .hi_red_s = "\x1b[38;5;196m",
                .special_s = "\x1b[38;2;54;208;224;1m",
            };
            fn writeRecord(node: *Node, job: *types.JobInfo) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                const rcd: types.Record = types.Record.init(job, node.task.cmd.build);
                const names: []const [:0]const u8 = &.{ node.buildRoot(), builder_spec.options.stat_root, node.name };
                const len: usize = types.Path.temporary(names).formatWriteBuf(&buf) -% 1;
                const fd: u64 = try meta.wrap(file.createAt(create2(), 0, buf[0..len :0], file.mode.regular));
                try meta.wrap(file.writeOne(write3(), fd, rcd));
                try meta.wrap(file.close(close(), fd));
            }
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
            fn baseMemoryUsageNotice(allocator: *mem.SimpleAllocator) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                ptr[0..tab.mem_s.len].* = tab.mem_s.*;
                ptr += tab.mem_s.len;
                ptr += fmt.ud64(allocator.next -% allocator.start).formatWriteBuf(ptr);
                ptr[0..8].* = tab.bytes_s.*;
                ptr += 6;
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
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
                if (old != .finished) {
                    var buf: [32768]u8 = undefined;
                    var len = writeNoExchangeTask(&buf, node, about_s, task, old, new, arena_index);
                    buf[len] = '\n';
                    debug.write(buf[0 .. len +% 1]);
                }
            }
            fn incorrectNodeUsageError(node: *Node, msg: [:0]const u8) void {
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
                buf[0..2].* = " [".*;
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
            fn addNotice(node: *Node) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                ptr[0..tab.add_s.len].* = tab.add_s.*;
                ptr += tab.add_s.len;
                @memcpy(ptr, @tagName(node.tag));
                ptr += @tagName(node.tag).len;
                ptr[0] = '.';
                ptr += 1;
                @memcpy(ptr, @tagName(node.task.tag));
                ptr += @tagName(node.task.tag).len;
                ptr[0..2].* = ", ".*;
                ptr += 2;
                @memcpy(ptr, node.name);
                ptr += node.name.len;
                ptr[0] = ' ';
                ptr += 1;
                switch (node.task.tag) {
                    .build => {
                        ptr[0..5].* = "root=".*;
                        ptr += 5;
                        @memcpy(ptr, node.impl.paths[1].names[1]);
                        ptr += node.impl.paths[1].names[1].len;
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                        ptr[0..4].* = "bin=".*;
                        ptr += 4;
                        @memcpy(ptr, node.impl.paths[0].names[1]);
                        ptr += node.impl.paths[0].names[1].len;
                    },
                    .format => {
                        ptr[0..5].* = "path=".*;
                        ptr += 5;
                        @memcpy(ptr, node.impl.paths[0].names[1]);
                        ptr += node.impl.paths[0].names[1].len;
                    },
                    .archive => {
                        ptr[0..8].* = "archive=".*;
                        ptr += 8;
                        @memcpy(ptr, node.impl.paths[0].names[1]);
                        ptr += node.impl.paths[0].names[1].len;
                    },
                    .objcopy => {
                        ptr[0..4].* = "bin=".*;
                        ptr += 4;
                        @memcpy(ptr, node.impl.paths[0].names[1]);
                        ptr += node.impl.paths[0].names[1].len;
                    },
                    else => {},
                }
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
            }
            fn writeNodeNameFull(buf: [*]u8, node: *const Node, sep: u8) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ptr: [*]u8 = buf;
                if (!node.flags.is_toplevel) {
                    ptr += writeNodeNameFull(ptr, node.impl.nodes[0], sep);
                    if (ptr != buf) {
                        ptr[0] = sep;
                        ptr += 1;
                    }
                    @memcpy(ptr, node.name);
                    ptr += node.name.len;
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            fn lengthNodeNameFull(node: *const Node) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                if (!node.flags.is_toplevel) {
                    len +%= lengthNodeNameFull(node.impl.nodes[0]);
                    len +%= @intFromBool(len != 0) +% node.name.len;
                }
                return len;
            }
            fn writeNodeNameRelative(buf: [*]u8, toplevel: *const Node, node: *const Node, sep: u8) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ptr: [*]u8 = buf;
                if (node != toplevel) {
                    ptr += writeNodeNameRelative(ptr, node.impl.nodes[0], sep);
                    if (ptr != buf) {
                        ptr[0] = sep;
                        ptr += 1;
                    }
                    @memcpy(ptr, node.name);
                    ptr += node.name.len;
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            fn lengthNodeNameRelative(toplevel: *const Node, node: *const Node) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var len: usize = 0;
                if (node != toplevel) {
                    len +%= lengthNodeNameRelative(node.impl.nodes[0]);
                    len +%= @intFromBool(len != 0) +% node.name.len;
                }
                return len;
            }
            fn taskNotice(
                node: *Node,
                task: types.Task,
                arena_index: AddressSpace.Index,
                old_size: usize,
                new_size: usize,
                del_sec: usize,
                del_nsec: usize,
                ans: UpdateAnswer,
                rc: u8,
            ) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const ret: SystemReturn = @enumFromInt(rc);
                var ud64: fmt.Type.Ud64 = undefined;
                var buf: [32768]u8 = undefined;
                var ptr: [*]u8 = &buf;
                const about_s: []const u8 = switch (task) {
                    else => "",
                    .archive => tab.ar_s,
                    .format => tab.fmt_s,
                    .run => tab.run_s,
                    .build => switch (node.task.cmd.build.kind) {
                        .exe => tab.build_exe_s,
                        .obj => tab.build_obj_s,
                        .lib => tab.build_lib_s,
                    },
                };
                @memcpy(ptr, about_s);
                ptr += about_s.len;
                ptr += writeNodeNameFull(ptr, node, '.');
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (task == .build) {
                    const mode: builtin.Mode = node.task.cmd.build.mode orelse .Debug;
                    switch (mode) {
                        .Debug => {
                            ptr[0..9].* = "Debug, un".*;
                            ptr += 7;
                        },
                        .ReleaseSmall => {
                            ptr[0..16].* = "ReleaseSmall, un".*;
                            ptr += 14;
                        },
                        .ReleaseFast => {
                            ptr[0..15].* = "ReleaseFast, un".*;
                            ptr += 13;
                        },
                        .ReleaseSafe => {
                            ptr[0..15].* = "ReleaseSafe, un".*;
                            ptr += 13;
                        },
                    }
                    if (node.hasDebugInfo()) ptr += 2;
                    ptr[0..8].* = "stripped".*;
                    ptr += 8;
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                }
                ptr[0..5].* = "exit=".*;
                ptr += 5;
                ud64.value = rc;
                if (task == .build) {
                    ptr[0] = '[';
                    ptr += 1;
                    if (ans == .failed) {
                        ptr[0..tab.red_s.len].* = tab.red_s.*;
                        ptr += tab.red_s.len;
                    } else if (node.flags.is_special) {
                        //if (ans == .cached) {
                        //    return;
                        //}
                        ptr[0..tab.special_s.len].* = tab.special_s.*;
                        ptr += tab.special_s.len;
                    } else {
                        ptr[0..4].* = "\x1b[1m".*;
                        ptr += 4;
                    }
                    switch (ans) {
                        .updated => {
                            ptr[0..7].* = "updated".*;
                            ptr += 7;
                        },
                        .cached => {
                            ptr[0..6].* = "cached".*;
                            ptr += 6;
                        },
                        else => {
                            ptr[0..6].* = "failed".*;
                            ptr += 6;
                        },
                    }
                    ptr[0..4].* = tab.reset_s.*;
                    ptr += 4;
                    ptr[0] = ',';
                    ptr += 1;
                    ptr += ud64.formatWriteBuf(ptr);
                    ptr[0] = ']';
                    ptr += 1;
                } else {
                    if (ret == .expected) {
                        //if (node.flags.is_special) {
                        //    return;
                        //}
                        ptr[0..4].* = "\x1b[1m".*;
                        ptr += 4;
                    } else {
                        ptr[0..tab.red_s.len].* = tab.red_s.*;
                        ptr += tab.red_s.len;
                    }
                    ptr += ud64.formatWriteBuf(ptr);
                    ptr[0..4].* = tab.reset_s.*;
                    ptr += 4;
                }
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (task == .build or task == .archive) {
                    if (ans != .failed) {
                        if (old_size == 0) {
                            ptr[0..5].* = tab.gold_s.*;
                            ptr += 5;
                            ud64.value = new_size;
                            ptr += ud64.formatWriteBuf(ptr);
                            ptr[0..13].* = ("*" ++ tab.reset_s ++ tab.bytes_s).*;
                            ptr += 13;
                        } else if (new_size == old_size) {
                            ud64.value = new_size;
                            ptr += ud64.formatWriteBuf(ptr);
                            ptr[0..8].* = tab.bytes_s.*;
                            ptr += 8;
                        } else {
                            ud64.value = old_size;
                            ptr += ud64.formatWriteBuf(ptr);
                            ptr[0] = '(';
                            ptr += 1;
                            ptr[0..7].* = if (new_size > old_size) tab.red_s.* else tab.green_s.*;
                            ptr += 7;
                            ptr[0] = if (new_size > old_size) '+' else '-';
                            ptr += 1;
                            ud64.value = (@max(old_size, new_size) -% @min(old_size, new_size));
                            ptr += ud64.formatWriteBuf(ptr);
                            ptr[0..4].* = tab.reset_s.*;
                            ptr += 4;
                            ptr[0..5].* = ") => ".*;
                            ptr += 5;
                            ud64.value = new_size;
                            ptr += ud64.formatWriteBuf(ptr);
                            ptr[0..8].* = tab.bytes_s.*;
                            ptr += 8;
                        }
                    }
                }
                ud64.value = del_sec;
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..4].* = ".000".*;
                ptr += 1;
                ud64.value = del_nsec;
                const figs: usize = fmt.length(u64, del_nsec, 10);
                ptr += (9 -% figs);
                _ = ud64.formatWriteBuf(ptr);
                ptr += (figs -% 9);
                ptr += 3;
                ptr[0] = 's';
                ptr += 1;
                if (builder_spec.options.show_arena_index and arena_index != max_thread_count) {
                    ptr += writeArenaIndex(ptr, arena_index);
                }
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
            }
            fn writeAbout(buf: [*]u8, kind: AboutKind) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ptr: [*]u8 = buf;
                switch (kind) {
                    .@"error" => {
                        ptr[0..4].* = "\x1b[1m".*;
                        ptr += 4;
                    },
                    .note => {
                        ptr[0..15].* = "\x1b[0;38;5;250;1m".*;
                        ptr += 15;
                    },
                }
                @memcpy(ptr, @tagName(kind));
                ptr += @tagName(kind).len;
                ptr[0..2].* = ": ".*;
                ptr += 2;
                ptr[0..4].* = "\x1b[1m".*;
                ptr += 4;
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
                buf[0..4].* = "\x1b[1m".*;
                var ptr: [*]u8 = buf + 4;
                if (err.src_loc != 0) {
                    const src_file: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
                    ptr += writeSourceLocation(ptr, src_file, src.line +% 1, src.column +% 1);
                    ptr[0..2].* = ": ".*;
                    ptr += 2;
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
                const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
                const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
                var len: usize = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
                const pos: u64 = len +% @tagName(kind).len -% 11 -% 2;
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
            fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: usize, column: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ud64: fmt.Type.Ud64 = .{ .value = line };
                var ptr: [*]u8 = buf;
                ptr[0..11].* = "\x1b[38;5;247m".*;
                ptr += 11;
                @memcpy(ptr, pathname);
                ptr += pathname.len;
                ptr[0] = ':';
                ptr += 1;
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0] = ':';
                ptr += 1;
                ud64.value = column;
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..4].* = tab.reset_s.*;
                return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% 4;
            }
            fn writeTimes(buf: [*]u8, count: u64) u64 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ud64: fmt.Type.Ud64 = .{ .value = count };
                var ptr: [*]u8 = buf - 1;
                ptr[0..4].* = tab.faint_s.*;
                ptr += 4;
                ptr[0..2].* = " (".*;
                ptr += 2;
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..7].* = " times)".*;
                ptr += 7;
                ptr[0..5].* = tab.new_s.*;
                return @intFromPtr(ptr - @intFromPtr(buf)) +% 5;
            }
            fn writeCaret(buf: [*]u8, bytes: [*:0]u8, src: *types.SourceLocation) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const line: [:0]u8 = mem.terminate(bytes + src.src_line, 0);
                const before_caret: u64 = src.span_main -% src.span_start;
                const indent: u64 = src.column -% before_caret;
                const after_caret: u64 = src.span_end -% src.span_main -| 1;
                @memcpy(buf, line);
                var ptr: [*]u8 = buf + line.len;
                ptr[0] = '\n';
                ptr += 1;
                @memset(ptr[0..indent], ' ');
                ptr += indent;
                ptr[0..10].* = tab.hi_green_s.*;
                ptr += 10;
                @memset(ptr[0..before_caret], '~');
                ptr += before_caret;
                ptr[0] = '^';
                ptr += 1;
                @memset(ptr[0..after_caret], '~');
                ptr += after_caret;
                ptr[0..5].* = tab.new_s.*;
                return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% tab.new_s.len;
            }
            fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: usize, indent: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ptr: [*]u8 = buf;
                var next: usize = start;
                var idx: usize = start;
                while (bytes[idx] != 0) : (idx +%= 1) {
                    if (bytes[idx] == '\n') {
                        const line: []u8 = bytes[next..idx];
                        @memcpy(ptr, line);
                        ptr += line.len;
                        ptr[0] = '\n';
                        ptr += 1;
                        @memset(ptr[0..indent], ' ');
                        ptr += indent;
                        next = idx +% 1;
                    }
                }
                const line: []u8 = bytes[next..idx];
                @memcpy(ptr, line);
                ptr += line.len;
                ptr[0..5].* = tab.new_s.*;
                return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% tab.new_s.len;
            }
            fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: usize, ref_len: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var ref_idx: usize = start +% types.SourceLocation.len;
                buf[0..11].* = "\x1b[38;5;247m".*;
                var ptr: [*]u8 = buf + 11;
                ptr[0..15].* = "referenced by:\n".*;
                ptr += 15;
                var idx: usize = 0;
                while (idx != ref_len) : (idx +%= 1) {
                    const ref_trc: *types.ReferenceTrace = @ptrCast(extra + ref_idx);
                    if (ref_trc.src_loc != 0) {
                        const ref_src: *types.SourceLocation = @ptrCast(extra + ref_trc.src_loc);
                        const src_file: [:0]u8 = mem.terminate(bytes + ref_src.src_path, 0);
                        const decl_name: [:0]u8 = mem.terminate(bytes + ref_trc.decl_name, 0);
                        @memset(ptr[0..4], ' ');
                        ptr += 4;
                        @memcpy(ptr, decl_name);
                        ptr += decl_name.len;
                        ptr[0..2].* = ": ".*;
                        ptr += 2;
                        ptr += writeSourceLocation(ptr, src_file, ref_src.line +% 1, ref_src.column +% 1);
                        ptr[0] = '\n';
                        ptr += 1;
                    }
                    ref_idx +%= types.ReferenceTrace.len;
                }
                ptr[0..5].* = tab.new_s.*;
                return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% 5;
            }
            fn writeErrors(allocator: *mem.SimpleAllocator, idx: [*]u32) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const extra: [*]u32 = idx + 2;
                var bytes: [*:0]u8 = @ptrCast(idx);
                bytes += 8 + (idx[0] *% 4);
                var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
                for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
                    debug.write(buf[0..writeError(buf, extra, bytes, err_msg_idx, .@"error")]);
                }
                debug.write(mem.terminate(bytes + extra[2], 0));
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
            fn lengthToplevelCommandNotice(len1: usize, node: *const Node, show_deps: bool, name_width: *usize, root_width: *usize) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const nodes: []*Node = node.impl.nodes[1..node.impl.nodes_len];
                if (node.impl.paths_len != 0) {
                    lengthSubNode(len1, node, name_width, root_width);
                }
                if (show_deps) {
                    lengthAndWalkInternal(len1, node, name_width, root_width);
                }
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
                    lengthToplevelCommandNotice(len1 +% 2, sub_node, show_deps, name_width, root_width);
                    if (nodes_idx == last_idx) {
                        break;
                    }
                }
            }
            fn writeAndWalkInternal(buf: [*]u8, end: [*]u8, tmp: [*]u8, len: usize, node: *const Node, name_width: usize, root_width: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const deps: []Dependency = node.impl.deps[0..node.impl.deps_len];
                var ptr: [*]u8 = end;
                var fin: *u8 = &buf[0];
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
                    (tmp + len)[0..2].* = if (deps_idx == last_idx or len == 0) "  ".* else "| ".*;
                    ptr[0] = '\n';
                    ptr += 1;
                    @memcpy(ptr, tmp[0..len]);
                    ptr += len;
                    fin = &ptr[0];
                    ptr[0..2].* = "|-".*;
                    ptr += 2;
                    ptr[0..2].* = if (dep.on_node.impl.deps_len == 0) "> ".* else "+ ".*;
                    ptr += 2;
                    @memcpy(ptr, dep.on_node.name);
                    ptr += dep.on_node.name.len;
                    if (dep.on_node.impl.paths_len != 0) {
                        ptr += writeSubNode(ptr, len +% 2, dep.on_node, name_width, root_width);
                    }
                    ptr = buf + writeAndWalkInternal(buf, ptr, tmp, len +% 2, dep.on_node, name_width, root_width);
                    if (deps_idx == last_idx) {
                        break;
                    }
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return @intFromPtr(ptr - @intFromPtr(buf));
            }
            fn primaryInputName(node: *const Node) [:0]const u8 {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (node.tag == .worker) {
                    if (node.task.tag == .build or
                        node.task.tag == .archive)
                    {
                        return node.impl.paths[1].names[1];
                    }
                    if (node.task.tag == .format) {
                        return node.impl.paths[0].names[1];
                    }
                    if (node.task.tag == .run) {
                        if (node.flags.is_build_command) {
                            return mem.terminate(node.impl.args[node.impl.args_len -% 1], 0);
                        } else {
                            return node.impl.paths[0].names[1];
                        }
                    }
                }
                return tab.null_s;
            }
            fn writeSubNode(buf: [*]u8, len: usize, sub_node: *const Node, name_width: usize, root_width: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var count: usize = name_width -% (sub_node.name.len +% len);
                var ptr: [*]u8 = buf;
                const input: [:0]const u8 = primaryInputName(sub_node);
                if (input.len != 0) {
                    @memset(ptr[0..count], ' ');
                    ptr += count;
                    @memcpy(ptr, input);
                    ptr += input.len;
                    if (sub_node.descr.len != 0) {
                        count = root_width -% input.len;
                        @memset(ptr[0..count], ' ');
                        ptr += count;
                        @memcpy(ptr, sub_node.descr);
                        ptr += sub_node.descr.len;
                    }
                }
                return @intFromPtr(ptr - @intFromPtr(buf));
            }
            fn writeToplevelCommandNotice(buf: [*]u8, tmp: [*]u8, len: usize, node: *const Node, show_deps: bool, name_width: usize, root_width: usize) usize {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                const nodes: []*Node = node.impl.nodes[1..node.impl.nodes_len];
                var ptr: [*]u8 = buf;
                var fin: *u8 = &buf[0];
                if (node.impl.paths_len != 0) {
                    ptr += writeSubNode(buf, len, node, name_width, root_width);
                }
                if (show_deps) {
                    ptr[0..4].* = about.tab.faint_s.*;
                    ptr += 4;
                    ptr = buf + writeAndWalkInternal(buf, ptr, tmp, len, node, name_width, root_width);
                    ptr[0..4].* = about.tab.reset_s.*;
                    ptr += tab.reset_s.len;
                }
                var last_idx: usize = 0;
                for (nodes, 0..) |sub_node, idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    last_idx = idx;
                }
                for (nodes, 0..) |sub_node, idx| {
                    if (wouldSkip(node, sub_node)) {
                        continue;
                    }
                    (tmp + len)[0..2].* = if (idx == last_idx or len == 0) "  ".* else "| ".*;
                    ptr[0] = '\n';
                    ptr += 1;
                    @memcpy(ptr, tmp[0..len]);
                    ptr += len;
                    fin = &ptr[0];
                    ptr[0..2].* = if (len == 0) "  ".* else "|-".*;
                    ptr += 2;
                    ptr[0..2].* = if (sub_node.impl.nodes_len == 1) "- ".* else "o ".*;
                    ptr += 2;
                    if (sub_node.flags.is_hidden and
                        sub_node.impl.paths_len != 0)
                    {
                        ptr += writeSubNode(ptr, len +% 4, sub_node, name_width, root_width);
                    }
                    @memcpy(ptr, sub_node.name);
                    ptr += sub_node.name.len;
                    ptr += writeToplevelCommandNotice(ptr, tmp, len +% 2, sub_node, show_deps, name_width, root_width);
                    if (idx == last_idx) {
                        break;
                    }
                }
                if (fin.* == '|') {
                    fin.* = '`';
                }
                return @intFromPtr(ptr - @intFromPtr(buf));
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
            fn commandLineNotice() void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                if (build.cmd_args.len != 0) {
                    ptr[0..tab.cmd_args_s.len].* = tab.cmd_args_s.*;
                    ptr += tab.cmd_args_s.len;
                    ptr += file.about.writeArgs(ptr, &.{}, build.cmd_args);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                if (build.run_args.len != 0) {
                    ptr[0..tab.run_args_s.len].* = tab.run_args_s.*;
                    ptr += tab.run_args_s.len;
                    ptr += file.about.writeArgs(ptr, &.{}, build.run_args);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
            }
            fn groupCommandNotice(allocator: *mem.SimpleAllocator, node: *const Node, show_deps: bool) void {
                @setRuntimeSafety(builder_spec.options.enable_safety);
                if (node.tag == .worker) {
                    return groupCommandNotice(allocator, node.impl.nodes[0], show_deps);
                }
                const save: u64 = allocator.next;
                defer allocator.next = save;
                var name_width: u64 = 0;
                var root_width: u64 = 0;
                const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
                mach.memset(buf0, 'E', 1024 *% 1024);
                var len0: u64 = node.name.len;
                const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
                mach.memset(buf1, 'E', 4096);
                mach.memcpy(buf0, node.name.ptr, node.name.len);
                lengthToplevelCommandNotice(0, node, show_deps, &name_width, &root_width);
                name_width +%= 4;
                name_width &= ~@as(u64, 3);
                root_width +%= 4;
                root_width &= ~@as(u64, 3);
                len0 +%= writeToplevelCommandNotice(buf0 + len0, buf1, 0, node, show_deps, name_width, root_width);
                buf0[len0] = '\n';
                len0 +%= 1;
                debug.write(buf0[0..len0]);
            }
        };
    };
    return T;
}
