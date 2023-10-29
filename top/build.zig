const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const sys = @import("./sys.zig");
const elf = @import("./elf.zig");
const file = @import("./file.zig");
const perf = @import("./perf.zig");
const bits = @import("./bits.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const trace = @import("./trace.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
pub const tasks = @import("./build/tasks.zig");
pub const types = @import("./build/types.zig");
pub usingnamespace tasks;
pub const ExecPhase = enum(u8) {
    /// This phase initialises the toplevel node and the builder shared state.
    /// Transcript items from this phase are titled with `init-0`.
    Init = 0,
    /// This phase initialises all user-defined nodes. Defined by `buildMain`.
    /// Transcript items from this phase are titled with `main-1`.
    Main = 1,
    /// This phase parses the command line and prepares all depedencies
    /// implied by the primary command.
    /// Transcript items from this phase are titled with `cmdline-2`.
    ///
    /// zig build [task] [flags] <primary_command> [cmd_args] ++ [run_args]
    ///          (a)    (b)     (c)               (d)           (e)
    ///
    /// a) Which task to execute for the primary command. Overriding task default.
    ///    Examples:
    ///     `zig build run main`            ;; Runs the output binary produced by
    ///                                        task `main`.
    ///
    /// b) Enable node flags by flag name.
    ///    Examples:
    ///     ;; Request `elfcmp` for new output binaries against existing.
    ///     `zig build --binary-analysis`
    ///
    ///     ;; Request `perf` performance counters for task operation.
    ///     `zig build --perf`
    ///
    /// c) Set primary command by node name.
    ///     ;; Set the primary command to `main`.
    ///     `zig build main`
    ///
    ///     ;; Set the primary command to `tests`.
    ///     `zig build tests`
    ///
    /// d) Set task parameters by parameter switch.
    ///    Examples:
    ///     ;; Override `build` task command parameter `mode` with `ReleaseFast`
    ///        and task command parameter `strip` with `true`.
    ///     `zig build main -OReleaseFast -fstrip`
    ///
    ///     ;; Override `build` task command parameter `gc_sections` with `false`.
    ///     `zig build main --no-gc-sections`
    ///
    ///     ;; Override format task command parameter `ast_check` with `true`.
    ///     `zig build src
    ///
    /// e) For tasks with binary executable output, set run command line for use
    ///    by run task.
    ///     Examples:
    ///     ;; Run the output of `elfcmp` build task with two file arguments on
    ///     ;; task completion.
    ///     `zig build run elfcmp ++ zig-out/bin/main.old zig-out/bin/main`
    ///
    Command = 2,
    /// This phase executes the command queue, comprising all implicit
    /// dependencies and the primary command.
    /// Transcript items from this phase are titled with `exec-3`.
    Exec = 3,
    /// This special phase attempts to generate source code for user
    /// task definitions.
    /// Transcript items from this phase are titled with `regen-4`.
    Regen = 4,
};
pub const Task = enum(u8) {
    /// Invokes no work from any group element.
    null = 0,
    /// (Group) Invokes any and all work for all group elements.
    any = 1,
    /// (Worker) zig fmt
    format = 2,
    /// (Worker) zig build-*
    build = 3,
    /// (Worker) execve
    run = 4,
    /// (Worker) zig ar
    archive = 5,
    /// (Worker) zig objcopy
    objcopy = 6,
    /// (Worker) zig fetch
    fetch = 7,
};
pub const State = enum(u8) {
    /// The task does not exist for the target.
    null = 0,
    /// The task was unable to complete because it encountered an error.
    failed = 1,
    /// The task is ready to begin.
    ready = 2,
    /// The task is waiting on dependencies.
    blocking = 4,
    /// The task is in progress.
    working = 8,
    /// The task was unable to complete because:
    /// * Dependency encountered an error and cancelled dependants.
    /// * Continuing might exceed a user-defined limit.
    cancelled = 16,
    /// The task is complete.
    finished = 32,
};
pub const Allocator = types.Allocator;
pub const Lock = mem.ThreadSafeSet(8, State, Task);
pub const BuilderSpec = struct {
    /// Builder options.
    options: Options = .{},
    /// Logging for system calls called by the builder.
    logging: Logging = .{},
    /// Errors for system calls called by builder.
    errors: Errors = .{},
    pub const Options = struct {
        /// The maximum number of threads in addition to main.
        /// max_thread_count=0 is single-threaded.
        max_thread_count: u8 = 8,
        /// Allow this many errors before exiting the thread group.
        /// A value of `null` will attempt to report all errors and exit from main.
        max_error_count: ?u8 = 0,
        /// Lowest allocated byte address.
        lb_addr: usize = 0x10000000000,
        /// Bytes allowed per thread arena (default=8MiB)
        max_arena_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed per thread stack (default=8MiB)
        max_stack_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed for dynamic metadata sections (default=8MiB)
        max_load_meta_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed for dynamic libraries program segments (default=8MiB)
        max_load_prog_aligned_bytes: usize = 8 * 1024 * 1024,
        /// These values are compared with return codes to determine whether a
        /// system command succeeded.
        system_expected_status: u8 = 0,
        system_error_status: u8 = 2,
        /// These values are compared with return codes to determine whether a
        /// compile command succeeded. These are arbitrary.
        compiler_expected_status: u8 = 0,
        compiler_cache_hit_status: u8 = 1,
        compiler_error_status: u8 = 2,
        compiler_unexpected_status: u8 = 3,
        /// Assert no command line exceeds this length in bytes, making
        /// buildLength/formatLength unnecessary.
        max_cmdline_len: ?usize = 65536,
        /// Assert no command line exceeds this number of individual arguments.
        max_cmdline_args: ?usize = 1024,
        /// Time slept in nanoseconds between dependency scans.
        sleep_nanoseconds: usize = 50000,
        /// Time in milliseconds allowed per build node.
        timeout_milliseconds: usize = 1000 * 60 * 60 * 24,
        /// Add run task for all executable build outputs.
        add_run_task_to_executables: bool = true,
        /// Enable stack traces in runtime errors for executables where mode is
        /// Debug with debugging symbols included
        add_stack_traces_to_debug_executables: bool = true,
        /// Add size statistics for all ELF outputs.
        add_comparison_report_to_elf: bool = true,
        /// Allow usage of current working directory, to shorten displayed
        /// pathnames.
        enable_current_working_directory: bool = true,
        /// Allow parsing environment variables to derive home directory, to
        /// shorten displayed pathnames.
        enable_home_directory: bool = false,
        /// Add build configuration for Zig sources.
        init_config_zig_sources: bool = true,
        /// Nodes with this name prefix are hidden in pre.
        init_hidden_by_name_prefix: ?u8 = '_',
        /// (Recommended) Pass --main-mod-path=<build_root> for all compile commands.
        init_main_mod_path: bool = true,
        /// (Recommended) Pass --cache-dir=<cache_root> for all compile commands.
        init_cache_root: bool = true,
        /// (Recommended) Pass --global-cache-dir=<cache_root> for all compile commands.
        init_global_cache_root: bool = true,
        /// Nodes with hidden parent/group nodes are also hidden
        init_inherit_hidden: bool = true,
        /// Nodes belonging to special groups are also special.
        init_inherit_special: bool = true,
        /// Enable advanced builder features, such as project-wide comptime
        /// constants and caching special modules.
        enable_build_config: bool = true,
        /// Compile builder features as required.
        extensions_policy: enum { none, emergency } = .emergency,
        /// Output naming strategy.
        naming_policy: enum { directories, first_name, full_name } = .full_name,
        /// Name separators for identifiers, commands, and output file names.
        namespace_separator: struct { id: u8 = '_', cmd: u8 = '.', fs: u8 = '-' } = .{},
        /// Name of the top 'builder' node.
        top_node: [:0]const u8 = "top",
        /// Special switch used to split arguments between task command and run command.
        append_run_args_string: [:0]const u8 = "++",
        /// Name of the special command used to list available commands.
        list_command: ?[:0]const u8 = "--list",
        /// Name of the special command used to request stack traces for executables.
        trace_command: ?[:0]const u8 = "--trace",
        /// Name of the special command used to request performance statistics for task.
        perf_command: ?[:0]const u8 = "--perf",
        /// Name of the special command used to request size breakdown for  task.
        size_command: ?[:0]const u8 = "--size",
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
        /// Extension for Zig source files.
        zig_ext: [:0]const u8 = ".zig",
        /// Extension for C header source files.
        h_ext: [:0]const u8 = ".h",
        /// Extension for shared object files.
        lib_ext: [:0]const u8 = ".so",
        /// Extension for archives.
        ar_ext: [:0]const u8 = ".a",
        /// Extension for object files.
        obj_ext: [:0]const u8 = ".o",
        /// Extension for assembly source files.
        asm_ext: [:0]const u8 = ".s",
        /// Extension for LLVM bitcode files.
        llvm_bc_ext: [:0]const u8 = ".bc",
        /// Extension for LLVM intermediate representation files.
        llvm_ir_ext: [:0]const u8 = ".ll",
        /// Extension for JSON files.
        analysis_ext: [:0]const u8 = ".json",
        /// Extension for documentation files.
        docs_ext: [:0]const u8 = ".html",
        /// Use library traces for compile error messages.
        trace_compile_errors: bool = true,
        /// (Devel.) Exclude `writeErrors` from dynamic extensions.
        eager_compile_errors: bool = false,
        /// (Devel.) Start dependencies in new threads regardless of
        /// total number.
        eager_multi_threading: bool = true,
        /// (Devel.) Restore dynamic environment from the cache.
        restore_dyn_env: bool = false,
        /// (Devel.) Save dynamic environment to the cache.
        save_dyn_env: bool = false,
        /// (Devel.) Try to load the library at initialisation.
        try_init_load: bool = false,
        /// (Devel.) If this succeeds, do not bother recompiling.
        init_load_ok: bool = false,
    };
    pub const Logging = packed struct {
        /// Report exchanges on task lock state:
        ///     Attempt => When resulting in no change of state.
        ///     Success => When resulting in change of state.
        ///     Fault   => When the change of state results in any abort.
        show_state: debug.Logging.AttemptSuccessFault = .{},
        /// Report completion of tasks with summary of results:
        ///     Attempt => When the task was unable to complete due to a
        ///                dependency.
        ///     Success => When the task completes without any errors.
        ///     Error   => When the task completes with errors.
        show_stats: debug.Logging.SuccessError = .{},
        ///
        /// P0: Builder Init.
        /// P1: Build Main -> Task Init.
        /// P1: Build Main -> Task Init.
        /// ...
        /// P2: User Input
        /// P3: Task Prep.
        /// P4: Task Exec.
        ///
        /// Provide overview of task node creation.
        show_task_creation: bool = false,
        /// Enables transcript of task update phase.
        show_task_update: bool = false,
        /// Enables transcript of user input.
        show_user_input: bool = false,
        /// Enables transcript of task preparation phase.
        show_task_prep: bool = false,
        /// Include arena/thread index in task summaries and change of state notices.
        show_arena_index: bool = true,
        /// Show the size of the declared tasks at startup.
        show_base_memory_usage: bool = false,
        /// Show when tasks have been waiting for a while with a list of blockers.
        show_waiting_tasks: bool = false,
        /// Never list special nodes among or allow explicit building.
        show_special: bool = false,
        /// --
        show_output_destination: bool = false,
        /// Report `open` Acquire and Error.
        open: debug.Logging.AttemptAcquireError = .{},
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
        /// Report `getcwd` Success and Error.
        getcwd: debug.Logging.SuccessError = .{},
        /// Report `perf_event_open` Success and Error.
        perf_event_open: debug.Logging.SuccessError = .{},
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
        /// Error values for `getcwd` system function.
        getcwd: sys.ErrorPolicy = .{},
        /// Error values for `perf_event_open` system function.
        perf_event_open: sys.ErrorPolicy = .{},
    };
};
pub fn GenericBuilder(comptime builder_spec: BuilderSpec) type {
    comptime var have_run: bool = false;
    comptime var have_fetch: bool = false;
    comptime var have_format: bool = false;
    comptime var have_archive: bool = false;
    comptime var have_objcopy: bool = false;
    const T = struct {
        /// Program arguments.
        args: [][*:0]u8,
        /// Environment variables.
        vars: [][*:0]u8,
        /// Phase of execution.
        mode: ExecPhase,
        /// RNG seed.
        seed: ?[:0]u8,
        /// Special toplevel node, initialised by args[1..5].
        top: *Node,
        /// Special library node, build root is always zig_lib.
        lib: *Node,
        /// Builder dynamic extensions.
        extns: *Extensions,
        /// Our dynamic loader.
        dl: *DynamicLoader,
        /// Function pointers for JIT compiled functions.
        fp: *FunctionPointers,
        /// Number of errors since processing user command line.
        errors: u8,
        // Enables lazy features.
        const have_lazy: bool = builder_spec.options.extensions_policy == .emergency;
        // Enables --list command line option.
        var have_list: bool = builder_spec.options.list_command != null;
        // Enables --perf command line option.
        var have_perf: bool = builder_spec.options.perf_command != null;
        // Enables --size command line option.
        var have_size: bool = builder_spec.options.size_command != null;
        // Enables --trace command line option.
        var have_trace: bool = builder_spec.options.trace_command != null;
        const lib_cache_root = builtin.lib_root ++ "/" ++ builder_spec.options.cache_dir;
        const binary_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.exe_out_dir ++ "/";
        const library_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.lib_out_dir ++ "/lib";
        const archive_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.lib_out_dir ++ "/lib";
        const auxiliary_prefix = builder_spec.options.output_dir ++ "/" ++ builder_spec.options.aux_out_dir ++ "/";
        const options_s = fmt.cx(builder_spec.options);
        const logging_s = fmt.cx(builder_spec.logging);
        const max_thread_count: comptime_int = builder_spec.options.max_thread_count;
        const max_arena_count: comptime_int = if (max_thread_count == 0) 4 else max_thread_count + 1;
        const arena_aligned_bytes: comptime_int = builder_spec.options.max_arena_aligned_bytes;
        const stack_aligned_bytes: comptime_int = builder_spec.options.max_stack_aligned_bytes;
        const load_meta_lb_addr: comptime_int = builder_spec.options.lb_addr;
        const load_meta_up_addr: comptime_int = load_meta_lb_addr + builder_spec.options.max_load_meta_aligned_bytes;
        const load_prog_lb_addr: comptime_int = bits.alignA64(load_meta_up_addr, 0x100000000000);
        const load_prog_up_addr: comptime_int = load_prog_lb_addr + builder_spec.options.max_load_prog_aligned_bytes;
        const stack_lb_addr: comptime_int = bits.alignA64(load_prog_up_addr, 0x100000000000);
        const stack_up_addr: comptime_int = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: comptime_int = bits.alignA64(stack_up_addr, 0x100000000000);
        const arena_up_addr: comptime_int = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
        pub const Shared = @This();
        pub const specification = &builder_spec;
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "thread",
            .index_type = u8,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .divisions = max_thread_count,
            .alignment = 4096,
            .options = .{ .thread_safe = true },
        });
        pub const AddressSpace = mem.GenericRegularAddressSpace(.{
            .label = "arena",
            .index_type = u8,
            .lb_addr = arena_lb_addr,
            .up_addr = arena_up_addr,
            .divisions = max_arena_count,
            .alignment = 4096,
            .options = .{ .thread_safe = false },
        });
        pub const LoaderSpace = mem.GenericDiscreteAddressSpace(.{
            .index_type = u8,
            .label = "ld",
            .list = &[2]mem.Arena{
                .{ .lb_addr = load_meta_lb_addr, .up_addr = load_meta_up_addr },
                .{ .lb_addr = load_prog_lb_addr, .up_addr = load_prog_up_addr },
            },
        });
        pub const DynamicLoader = elf.GenericDynamicLoader(.{
            .logging = dyn_loader_logging,
            .errors = dyn_loader_errors,
            .AddressSpace = LoaderSpace,
        });
        pub const PerfEvents = perf.GenericPerfEvents(.{
            .logging = perf_events_logging,
            .errors = perf_events_errors,
        });
        const update_exit_message: [2]Message.ClientHeader = .{
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
            .read_write = true,
            .exclusive = false,
            .truncate = true,
        };
        const thread_map_options = .{
            .grows_down = true,
        };
        const pipe_options = .{
            .close_on_exec = false,
        };
        const dir_options = .{
            .directory = true,
            .path = true,
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
        const dyn_loader_errors = .{
            .open = builder_spec.errors.open,
            .seek = builder_spec.errors.seek,
            .stat = builder_spec.errors.stat,
            .read = builder_spec.errors.read,
            .close = builder_spec.errors.close,
            .map = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const dyn_loader_logging = .{
            .open = builder_spec.logging.open,
            .seek = builder_spec.logging.seek,
            .stat = builder_spec.logging.stat,
            .read = builder_spec.logging.read,
            .close = builder_spec.logging.close,
            .map = builder_spec.logging.map,
            .unmap = builder_spec.logging.unmap,
        };
        const perf_events_errors = .{
            .open = builder_spec.errors.perf_event_open,
            .read = builder_spec.errors.read,
            .close = builder_spec.errors.close,
        };
        const perf_events_logging = .{
            .open = builder_spec.logging.perf_event_open,
            .read = builder_spec.logging.read,
            .close = builder_spec.logging.close,
        };
        const trace_build_cmd = .{
            .kind = .obj,
            .dynamic = true,
            .omit_frame_pointer = false,
            .mode = .ReleaseSmall,
            .stack_check = false,
            .stack_protector = false,
            .reference_trace = true,
            .single_threaded = true,
            .function_sections = false,
            .strip = false,
            .compiler_rt = false,
            .image_base = 65536,
        };
        const extn_flags = .{
            .is_dynamic_extension = true,
            .want_builder_decl = true,
            .want_build_config = true,
            .want_define_decls = true,
            .have_task_data = false,
        };
        pub const Extensions = struct {
            /// Raw commands build commands producing dynamic library
            /// Required for multi-threading.
            proc: *Node,
            /// Required for rendering.
            about: *Node,
            /// Required for build commands using task struct.
            build: *Node,
            /// Required for format commands using task struct.
            format: *Node,
            /// Required for archive commands using task struct.
            archive: *Node,
            /// Required for objcopy commands using task struct.
            objcopy: *Node,
            /// Full build command producing static linkable object.
            trace: *Node,
        };
        pub const Node = struct {
            /// The node's 'first' name. Must be unique within the parent group.
            /// Names will only be checked for uniqueness once: when the node is
            /// added to its group with any of the `add(Build|Format|Archive|...)`
            /// functions. If a non-unique name is contrived by manually editing
            /// this field the state is undefined.
            name: [:0]u8,
            /// Description text to be printed with task listing.
            descr: [:0]const u8,
            /// Stores task information. e.g.
            /// `node.tasks.cmd.build.mode = .ReleaseFast;`
            tasks: Tasks,
            /// (Internal)
            flags: Flags,
            /// (Internal)
            extra: Extra,
            /// (Internal)
            lock: Lock,
            /// (Internal)
            lists: types.Lists,
            /// Pointer to the shared state. May consider storing allocators
            /// and address spaces here to make UX more convenient. It also
            /// saves a number of paramters in many functions.
            sh: *Shared,
            pub const Flags = packed struct(u32) {
                /// (Internal) Whether the node is a parameter to the user
                /// defined function `buildMain`.
                is_top: bool = false,
                /// (Internal) Whether the node has the group command property.
                is_group: bool = false,
                /// (Internal) Whether the node is maintained and defined by
                /// this library.
                is_special: bool = false,
                /// (Internal) Whether the node will be shown by list commands.
                is_hidden: bool = false,
                /// (Internal) Whether the node task command has been invoked
                /// directly from `processCommands` by the user command line.
                /// Determines whether command line arguments are appended.
                is_primary: bool = false,
                /// (Internal) Whether independent nodes will be processed in
                /// parallel.
                is_single_threaded: bool = false,
                /// (Internal) Whether to execute `autoLoad` functions on
                /// completion of build tasks.
                is_dynamic_extension: bool = false,
                /// (Internal) Whether a node will be processed before being
                /// returned to `buildMain`.
                do_init: bool = true,
                /// (Internal) Whether a node will be processed before executing
                /// from command line.
                do_prepare: bool = true,
                /// (Internal) Whether a node will be processed on request to
                /// regenerate the build program.
                do_regenerate: bool = true,
                /// (Internal) Whether a node stores a valid pointer to a task
                /// struct matching its task type. Raw commands set this flag
                /// to false.
                have_task_data: bool = true,
                /// (Internal) Whether the configuration root source for a
                /// build task exists.
                have_config_root: bool = false,
                /// Whether to create a configuration root. Enables usage of
                /// configuration constants.
                want_build_config: bool = false,
                /// Whether to monitor build/run performance counters.
                want_perf_events: bool = false,
                /// Whether to display section/symbol differences between
                /// updated output binaries.
                want_binary_analysis: bool = false,
                /// Whether to write `Builder` declaration to build
                /// configuration.
                want_builder_decl: bool = false,
                /// Whether to write builtin configuration constants to build
                /// configuration.
                want_define_decls: bool = false,
                /// Whether to add `trace` object to compile command.
                want_stack_traces: bool = false,
                /// Only meaningful when zig lib is not acting as standard.
                want_zig_lib_rt: bool = false,
                /// Define the compiler path, build root, cache root, and global
                /// cache root as declarations to the build configuration root.
                want_build_context: bool = true,
                /// Whether modification times of output binaries and root
                /// sources may be used to determine a cache hit. Useful for
                /// generated files. This check is performed by the builder.
                want_shallow_cache_check: bool = false,

                // Padding
                zb: u11 = 0,
            };
            const Tasks = struct {
                /// Primary (default) task for this node.
                tag: Task,
                /// Compile command information for this node. Can be a pointer to any
                /// command struct.
                cmd: tasks.Command,
            };
            pub const Depn = packed struct(usize) {
                /// The node holding this dependency will block on this task ...
                task: Task,
                /// This task ...
                on_task: Task,
                /// In this state ...
                on_state: State,
                ///  For node given by this index.
                node_idx: u32,

                // Padding
                zb: u8 = 0,
            };
            pub const Conf = extern struct {
                data: u64,
                pub fn formatWriteBuf(cfg: Conf, buf: [*]u8) u64 {
                    @setRuntimeSafety(builtin.is_safe);
                    const addr: usize = cfg.data & ((1 << (@bitSizeOf(usize) -% 8)) -% 1);
                    const disp: usize = cfg.data >> (@bitSizeOf(usize) -% 8);
                    var str: [:0]const u8 = mem.terminate(@ptrFromInt(addr +% disp), 0);
                    buf[0..12].* = "pub const @\"".*;
                    var ptr: [*]u8 = fmt.strcpyEqu(buf + 12, str);
                    if (disp == 1) {
                        const val: *bool = @ptrFromInt(addr);
                        ptr[0..7].* = "\":bool=".*;
                        ptr += 7;
                        ptr[0..5].* = if (val.*) "true\x00".* else "false".*;
                        ptr += @as(usize, 5) -% @intFromBool(val.*);
                    } else if (disp == 8) {
                        const val: *isize = @ptrFromInt(addr);
                        ptr[0..15].* = "\":comptime_int=".*;
                        ptr += 15;
                        var id64: fmt.Id64 = .{ .value = val.* };
                        ptr += id64.formatWriteBuf(ptr);
                    } else if (disp == 16) {
                        const fp: **fn (*anyopaque, [*]u8) usize = @ptrFromInt(addr);
                        const val: *anyopaque = @ptrFromInt(addr +% 8);
                        ptr[0..2].* = "\"=".*;
                        ptr += 2;
                        ptr += @call(.auto, fp.*, .{ val, ptr });
                    } else {
                        str = mem.terminate(str.ptr + str.len + 1, 0);
                        ptr[0..2].* = "\"=".*;
                        ptr += 2;
                        if (cfg.data & (1 << ((@bitSizeOf(usize) -% 8) +% 4)) == 0) {
                            ptr[0] = '"';
                            ptr += 1;
                        } else {
                            ptr[0..2].* = "\\\\".*;
                            ptr += 2;
                        }
                        ptr = fmt.strcpyEqu(ptr, str);
                        if (cfg.data & (1 << ((@bitSizeOf(usize) -% 8) +% 4)) == 0) {
                            ptr[0] = '"';
                        } else {
                            ptr[0] = '\n';
                        }
                        ptr += 1;
                    }
                    ptr[0..2].* = ";\n".*;
                    return @intFromPtr(ptr + 2) -% @intFromPtr(buf);
                }
            };
            pub const Iterator = struct {
                node: *const Node,
                idx: usize = 0,
                max_len: usize = 0,
                max_idx: usize = 0,
                nodes: []const *Node,
                depns: []const Node.Depn,
                pub fn init(node: *const Node) Iterator {
                    @setRuntimeSafety(false);
                    var itr: Iterator = .{
                        .node = node,
                        .nodes = node.getNodes(),
                        .depns = node.getDepns(),
                        .idx = @intFromBool(node.flags.is_group),
                    };
                    if (node.flags.is_group) {
                        itr.max_len = itr.nodes.len;
                    } else {
                        itr.max_len = itr.depns.len;
                    }
                    while (itr.next()) |_| {
                        continue;
                    }
                    itr.idx = @intFromBool(node.flags.is_group);
                    return itr;
                }
                pub fn next(itr: *Iterator) ?*Node {
                    @setRuntimeSafety(false);
                    while (itr.idx != itr.max_len) {
                        const node: *Node =
                            if (itr.node.flags.is_group)
                            itr.nodes[itr.idx]
                        else
                            itr.nodes[itr.depns[itr.idx].node_idx];
                        itr.idx +%= 1;
                        if (itr.node == node or
                            node.flags.is_hidden)
                        {
                            continue;
                        }
                        if (!builder_spec.logging.show_special and
                            node.flags.is_special)
                        {
                            continue;
                        }
                        itr.max_idx = @max(itr.max_idx, itr.idx);
                        return node;
                    }
                    return null;
                }
            };
            pub const Extra = struct {
                dir_fds: ?*DirFds = null,
                wait: ?*Wait = null,
                results: ?*Results = null,
                perf_events: ?*PerfEvents = null,
                info_before: ?*DynamicLoader.Info = null,
                info_after: ?*DynamicLoader.Info = null,
            };
            const EnvPaths = struct {
                zig_exe: [:0]const u8,
                build_root: [:0]const u8,
                cache_root: [:0]const u8,
                global_cache_root: [:0]const u8,
            };
            pub const Wait = struct {
                total: usize = 0,
                tick: usize = 0,
            };
            pub const DirFds = struct {
                build_root: usize,
                cache_root: usize,
                config_root: usize,
                output_root: usize,
            };
            pub const Results = struct {
                server: u8,
                status: u8,
                signal: u8,
                time: time.TimeSpec,
            };
            pub fn getNodes(node: *const Node) []*Node {
                @setRuntimeSafety(false);
                return @as(*[]*Node, @ptrCast(node.lists.get(.nodes))).*;
            }
            pub fn getPaths(node: *const Node) []types.Path {
                @setRuntimeSafety(false);
                return @as(*[]types.Path, @ptrCast(node.lists.get(.paths))).*;
            }
            pub fn getFiles(node: *const Node) []types.File {
                @setRuntimeSafety(false);
                return @as(*[]types.File, @ptrCast(node.lists.get(.files))).*;
            }
            pub fn getConfigs(node: *const Node) []Conf {
                @setRuntimeSafety(false);
                return @as(*[]Conf, @ptrCast(node.lists.get(.confs))).*;
            }
            pub fn getCmdArgs(node: *const Node) [][*:0]u8 {
                @setRuntimeSafety(false);
                return @as(*[][*:0]u8, @ptrCast(node.lists.get(.cmd_args))).*;
            }
            pub fn getRunArgs(node: *const Node) [][*:0]u8 {
                @setRuntimeSafety(false);
                return @as(*[][*:0]u8, @ptrCast(node.lists.get(.run_args))).*;
            }
            pub fn getDepns(node: *const Node) []Depn {
                @setRuntimeSafety(false);
                return @as(*[]Depn, @ptrCast(node.lists.get(.depns))).*;
            }
            /// Examples:
            ///
            /// Get output binaries for build tasks by tag:
            /// .{ .tag = output_exe }
            /// .{ .tag = output_lib }
            /// .{ .tag = output_obj }
            ///     ...
            ///
            /// Get input or output by flags:
            /// .{ .flags = .{ .output = true } }
            /// .{ .flags = .{ .input = true } }
            ///     ...
            ///
            pub fn getFile(node: *const Node, key: types.File.Key) ?*types.File {
                @setRuntimeSafety(false);
                const files: []types.File = node.getFiles();
                var idx: usize = 0;
                var mat_idx: usize = 0;
                var mat_pc: u16 = 0;
                while (idx != files.len) : (idx +%= 1) {
                    const tag_bits: u8 = @intFromEnum(files[idx].key.tag);
                    if (tag_bits == key.id) {
                        return @ptrCast(files.ptr + idx);
                    } else {
                        const idx_pc: u16 = @popCount(tag_bits & key.id);
                        if (idx_pc > mat_pc) {
                            mat_pc = idx_pc;
                            mat_idx = idx;
                        }
                    }
                }
                if (mat_pc != 0) {
                    return @ptrCast(files.ptr + mat_idx);
                }
                return null;
            }
            fn createFileList(node: *const Node, allocator: *Allocator, key: types.File.Key) []types.File {
                @setRuntimeSafety(false);
                const files: []types.File = node.getFiles();
                var idx: usize = 0;
                var len: usize = 0;
                while (idx != files.len) : (idx +%= 1) {
                    len +%= @intFromBool(@intFromEnum(files[idx].tag) & key.id != 0);
                }
                var buf: [*]types.File = @ptrFromInt(allocator.allocateRaw(
                    len *% @sizeOf(types.File),
                    @alignOf(types.File),
                ));
                len = 0;
                while (idx != files.len) : (idx +%= 1) {
                    if (@intFromEnum(files[idx].tag) & key.id != 0) {
                        buf[len] = files[idx];
                        len +%= 1;
                    }
                }
                return buf[0..len];
            }
            fn createPathList(node: *const Node, allocator: *Allocator, key: types.File.Key) []types.Path {
                @setRuntimeSafety(false);
                const files: []types.File = node.getFiles();
                var len: usize = 0;
                var idx: usize = 0;
                while (idx != files.len) : (idx +%= 1) {
                    len +%= @intFromBool(@intFromEnum(files[idx].key.tag) & key.id != 0);
                }
                var buf: [*]types.Path = @ptrFromInt(allocator.allocateRaw(
                    len *% @sizeOf(types.Path),
                    @alignOf(types.Path),
                ));
                len = 0;
                while (idx != files.len) : (idx +%= 1) {
                    if (@intFromEnum(files[idx].key.tag) & key.id != 0) {
                        if (getFilePath(node, @ptrCast(files.ptr + idx))) |path| {
                            buf[len] = path.*;
                            len +%= 1;
                        }
                    }
                }
                return buf[0..len];
            }
            pub fn getPath(node: *const Node, key: types.File.Key) ?*types.Path {
                @setRuntimeSafety(false);
                if (node.getFile(key)) |fs| {
                    if (node.getFilePath(fs)) |path| {
                        return path;
                    }
                }
                return null;
            }
            pub fn getFilePath(node: *const Node, fs: *const types.File) ?*types.Path {
                @setRuntimeSafety(false);
                const paths: []types.Path = node.getPaths();
                if (!fs.key.flags.is_cached) {
                    return @ptrCast(paths.ptr + fs.path_idx);
                }
                return null;
            }
            pub fn getFileStatus(node: *const Node, fs: *const types.File) ?*file.Status {
                @setRuntimeSafety(false);
                if (node.getFilePath(fs)) |path| {
                    path.status(stat(), fs.st);
                }
                return null;
            }
            /// Allocate a node pointer.
            fn addNode(node: *Node, allocator: *Allocator) **Node {
                @setRuntimeSafety(false);
                return @ptrFromInt(node.lists.add(allocator, .nodes));
            }
            fn addFile(node: *Node, allocator: *Allocator) *types.File {
                @setRuntimeSafety(false);
                return @ptrFromInt(node.lists.add(allocator, .files));
            }
            fn addPath(node: *Node, allocator: *Allocator, tag: types.File.Tag) *types.Path {
                @setRuntimeSafety(false);
                const list: *types.Lists.List = @ptrCast(node.lists.get(.paths));
                const fs: *types.File = node.addFile(allocator);
                fs.* = .{
                    .path_idx = @intCast(list.len),
                    .key = .{ .tag = tag },
                    .st = @ptrFromInt(allocator.allocateRaw(144, 8)),
                };
                return @ptrFromInt(list.add(allocator, .{ .tag = .paths }));
            }
            pub fn addPathname(node: *Node, allocator: *Allocator, tag: types.File.Tag, pathname: []const u8) *types.Path {
                @setRuntimeSafety(false);
                return node.addPathnames(allocator, tag, &.{pathname});
            }
            pub fn addPathnames(node: *Node, allocator: *Allocator, tag: types.File.Tag, names: []const []const u8) *types.Path {
                @setRuntimeSafety(false);
                const path: *types.Path = node.addPath(allocator, tag);
                path.* = .{};
                for (names) |name| {
                    path.addName(allocator).* = duplicate(allocator, name);
                }
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, about.flagTagFromFile(tag), .add_file);
                }
                return path;
            }
            pub fn addCmdArg(node: *Node, allocator: *Allocator) *[*:0]u8 {
                @setRuntimeSafety(false);
                return @ptrFromInt(node.lists.add(allocator, .cmd_args));
            }
            pub fn addRunArg(node: *Node, allocator: *Allocator) *[*:0]u8 {
                @setRuntimeSafety(false);
                return @ptrFromInt(node.lists.add(allocator, .run_args));
            }
            fn addConfig(node: *Node, allocator: *Allocator) *Conf {
                @setRuntimeSafety(false);
                return @ptrFromInt(node.lists.add(allocator, .confs));
            }
            pub fn addConfigString(node: *Node, allocator: *Allocator, name: []const u8, value: []const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(value.len +% name.len +% 2, 1);
                fmt.strcpyEqu(@ptrFromInt(addr), name)[0] = 0;
                fmt.strcpyEqu(@ptrFromInt(addr +% name.len +% 1), value)[0] = 0;
                node.addConfig(allocator).data = addr;
            }
            pub fn addConfigBool(node: *Node, allocator: *Allocator, name: []const u8, value: bool) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(name.len +% 2, 1);
                const ptr: *bool = @ptrFromInt(addr);
                ptr.* = value;
                fmt.strcpyEqu(@ptrFromInt(addr +% 1), name)[0] = 0;
                node.addConfig(allocator).data = (1 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            pub fn addConfigInt(node: *Node, allocator: *Allocator, name: []const u8, value: isize) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(name.len +% 1 +% 8, 8);
                const ptr: *isize = @ptrFromInt(addr);
                ptr.* = value;
                fmt.strcpyEqu(@ptrFromInt(addr +% @sizeOf(isize)), name)[0] = 0;
                node.addConfig(allocator).data = (8 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            pub fn addConfigFormatter(
                node: *Node,
                allocator: *Allocator,
                name: []const u8,
                formatWriteBuf: *const fn (*const anyopaque, [*]u8) usize,
                format: *const anyopaque,
            ) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(16 +% name.len +% 1, 8);
                const ptrs: *[2]usize = @ptrFromInt(addr);
                ptrs[0] = @intFromPtr(formatWriteBuf);
                ptrs[1] = @intFromPtr(format);
                fmt.strcpyEqu(@ptrFromInt(addr +% 16), name)[0] = 0;
                node.addConfig(allocator).data = (16 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            pub fn addToplevelArgs(node: *Node, allocator: *Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addRunArg(allocator).* = node.zigExe();
                node.addRunArg(allocator).* = node.buildRoot();
                node.addRunArg(allocator).* = node.cacheRoot();
                node.addRunArg(allocator).* = node.globalCacheRoot();
                node.addRunArg(allocator).* = @constCast("--seed");
                if (node.sh.seed) |seed| {
                    node.addRunArg(allocator).* = seed.ptr;
                } else {
                    node.addRunArg(allocator).* = @constCast("0x000000");
                }
            }
            inline fn addDefineConfigs(node: *Node, allocator: *Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addConfigBool(allocator, "is_safe", false);
                node.addConfigString(allocator, "message_style", fmt.toStringLiteral(builtin.message_style orelse "null"));
                node.addConfigString(allocator, "message_prefix", fmt.toStringLiteral(builtin.message_prefix));
                node.addConfigString(allocator, "message_suffix", fmt.toStringLiteral(builtin.message_suffix));
                node.addConfigInt(allocator, "message_indent", builtin.message_indent);
            }
            inline fn addBuildContextConfigs(node: *Node, allocator: *Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addConfigString(allocator, "zig_exe", node.zigExe());
                node.addConfigString(allocator, "build_root", node.buildRoot());
                node.addConfigString(allocator, "cache_root", node.cacheRoot());
                node.addConfigString(allocator, "global_cache_root", node.cacheRoot());
            }
            pub fn init(allocator: *Allocator, name: []const u8, args: [][*:0]u8, vars: [][*:0]u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const sh: *Shared = @ptrFromInt(allocator.allocateRaw(@sizeOf(Shared), @alignOf(Shared)));
                const node: *Node = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node), @alignOf(Node)));
                sh.top = node;
                sh.args = args;
                sh.vars = vars;
                node.sh = sh;
                node.flags = .{ .is_top = true, .is_group = true };
                node.addNode(allocator).* = node;
                node.name = duplicate(allocator, name);
                node.addPath(allocator, .zig_compiler_exe).addName(allocator).* = duplicate(allocator, mem.terminate(args[1], 0));
                node.addPath(allocator, .build_root).addName(allocator).* = duplicate(allocator, mem.terminate(args[2], 0));
                node.addPath(allocator, .cache_root).addName(allocator).* = duplicate(allocator, mem.terminate(args[3], 0));
                node.addPath(allocator, .global_cache_root).addName(allocator).* = duplicate(allocator, mem.terminate(args[4], 0));
                initializeGroup(allocator, node);
                initializeExtensions(allocator, node);
                sh.mode = .Main;
                return node;
            }
            pub fn addGroup(group: *Node, allocator: *Allocator, name: [:0]const u8, env_paths: ?EnvPaths) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const node: *Node = createNode(allocator, group, name, .{ .is_group = true }, .any, omni_lock);
                if (env_paths) |paths| {
                    node.addPath(allocator, .zig_compiler_exe).addName(allocator).* = paths.zig_exe;
                    node.addPath(allocator, .build_root).addName(allocator).* = paths.build_root;
                    node.addPath(allocator, .cache_root).addName(allocator).* = paths.cache_root;
                    node.addPath(allocator, .global_cache_root).addName(allocator).* = paths.global_cache_root;
                } else {
                    node.lists.set(types.Path, .paths, group.getPaths());
                }
                initializeGroup(allocator, node);
                return node;
            }
            pub fn addBuild(group: *Node, allocator: *Allocator, build_cmd: tasks.BuildCommand, name: [:0]const u8, root_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const node: *Node = createNode(allocator, group, name, .{}, .build, obj_lock);
                node.tasks.cmd.build = @ptrFromInt(allocator.allocateRaw(tasks.BuildCommand.size_of, tasks.BuildCommand.align_of));
                node.tasks.cmd.build.* = build_cmd;
                node.addBinaryOutputPath(allocator, @enumFromInt(@intFromEnum(build_cmd.kind)));
                node.addSourceInputPath(allocator, duplicate(allocator, root_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addFormat(group: *Node, allocator: *Allocator, format_cmd: tasks.FormatCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_format = true;
                const node: *Node = createNode(allocator, group, name, .{}, .format, format_lock);
                node.tasks.cmd.format = @ptrFromInt(allocator.allocateRaw(tasks.FormatCommand.size_of, tasks.FormatCommand.align_of));
                node.tasks.cmd.format.* = format_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addFetch(group: *Node, allocator: *Allocator, format_cmd: tasks.FormatCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_format = true;
                const node: *Node = createNode(allocator, group, name, .{}, .fetch, fetch_lock);
                node.tasks.cmd.format = @ptrFromInt(allocator.allocateRaw(tasks.FormatCommand.size_of, tasks.FormatCommand.align_of));
                node.tasks.cmd.format.* = format_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addArchive(group: *Node, allocator: *Allocator, archive_cmd: tasks.ArchiveCommand, name: [:0]const u8, depns: []const *Node) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_archive = true;
                const node: *Node = createNode(allocator, group, name, .{}, .archive, archive_lock);
                node.tasks.cmd.archive = @ptrFromInt(allocator.allocateRaw(tasks.ArchiveCommand.size_of, tasks.ArchiveCommand.align_of));
                node.tasks.cmd.archive.* = archive_cmd;
                node.addBinaryOutputPath(allocator, .output_ar);
                for (depns) |depn| node.dependOn(allocator, depn);
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addObjcopy(group: *Node, allocator: *Allocator, objcopy_cmd: tasks.ObjcopyCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_objcopy = true;
                const node: *Node = createNode(allocator, group, name, .{}, .objcopy, objcopy_lock);
                node.tasks.cmd.objcopy = @ptrFromInt(allocator.allocateRaw(tasks.ObjcopyCommand.size_of, tasks.ObjcopyCommand.align_of));
                node.tasks.cmd.objcopy.* = objcopy_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addRun(group: *Node, allocator: *Allocator, name: [:0]const u8, args: []const []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_run = true;
                const node: *Node = createNode(allocator, group, name, .{}, .run, run_lock);
                for (args) |arg| node.addRunArg(allocator).* = duplicate(allocator, arg);
                initializeCommand(allocator, node);
                return node;
            }
            fn addSourceInputPath(node: *Node, allocator: *Allocator, name: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                const root_path: *types.Path = node.addPath(allocator, classifySourceInputName(name));
                root_path.* = .{};
                root_path.addName(allocator).* = node.buildRoot();
                root_path.addName(allocator).* = name;
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .add_file);
                }
            }
            fn addBinaryOutputPath(node: *Node, allocator: *Allocator, kind: types.File.Tag) void {
                @setRuntimeSafety(builtin.is_safe);
                const binary_path: *types.Path = node.addPath(allocator, kind);
                binary_path.* = .{};
                binary_path.addName(allocator).* = node.buildRoot();
                binary_path.addName(allocator).* = outputRelative(allocator, node, kind);
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .add_file);
                }
            }
            pub fn addDepn(node: *Node, allocator: *Allocator, task: Task, on_node: *Node, on_task: Task) void {
                @setRuntimeSafety(builtin.is_safe);
                const list: []*Node = node.getNodes();
                const node_idx: u16 = @intCast(list.len);
                const depn: *Depn = @ptrFromInt(node.lists.add(allocator, .depns));
                node.addNode(allocator).* = on_node;
                const on_paths: []types.Path = on_node.getPaths();
                if (task == .build) {
                    if (on_task == .archive) {
                        node.addPath(allocator, .input_ar).* = on_paths[0];
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, null, .add_file);
                        }
                    }
                    if (on_node.flags.have_task_data and
                        on_task == .build and
                        on_node.tasks.cmd.build.kind == .obj)
                    {
                        node.addPath(allocator, .input_obj).* = on_paths[0];
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, null, .add_file);
                        }
                    }
                }
                if (task == .archive) {
                    if (on_node.flags.have_task_data and
                        on_task == .build and
                        on_node.tasks.cmd.build.kind == .obj)
                    {
                        node.addPath(allocator, .input_ar).* = on_paths[0];
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, null, .add_file);
                        }
                    }
                }
                depn.* = .{ .task = task, .on_task = on_task, .on_state = .finished, .node_idx = node_idx };
            }
            pub fn dependOn(node: *Node, allocator: *Allocator, on_node: *Node) void {
                node.addDepn(
                    allocator,
                    if (node == on_node) .run else node.tasks.tag,
                    on_node,
                    on_node.tasks.tag,
                );
            }
            pub fn addGroupWithTask(
                group: *Node,
                allocator: *Allocator,
                name: [:0]const u8,
                task: Task,
            ) *Node {
                const node: *Node = group.addGroup(allocator, name, null);
                node.tasks.tag = task;
                return node;
            }
            pub fn addBuildAnon(
                group: *Node,
                allocator: *Allocator,
                build_cmd: tasks.BuildCommand,
                root_pathname: [:0]const u8,
            ) *Node {
                const name: [:0]const u8 = makeCommandName(allocator, root_pathname);
                const node: *Node = group.addBuild(allocator, build_cmd, name, root_pathname);
                return node;
            }
            pub fn groupNode(node: *Node) *Node {
                @setRuntimeSafety(builtin.is_safe);
                return node.getNodes()[0];
            }
            pub fn zigExe(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().zigExe();
                }
                return node.getPaths()[0].names[0];
            }
            pub fn buildRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().buildRoot();
                }
                return node.getPaths()[1].names[0];
            }
            pub fn cacheRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().cacheRoot();
                }
                return node.getPaths()[2].names[0];
            }
            pub fn globalCacheRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().globalCacheRoot();
                }
                return node.getPaths()[3].names[0];
            }
            pub fn buildRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().buildRootFd();
                }
                return node.extra.dir_fds.?.build_root;
            }
            pub fn configRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().configRootFd();
                }
                return node.extra.dir_fds.?.config_root;
            }
            pub fn outputRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().outputRootFd();
                }
                return node.extra.dir_fds.?.output_root;
            }
            pub fn cacheRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return node.groupNode().cacheRootFd();
                }
                return node.extra.dir_fds.?.cache_root;
            }
            pub fn hasDebugInfo(node: *Node) bool {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.have_task_data) {
                    return false;
                }
                if (node.tasks.cmd.build.strip) |strip| {
                    return !strip;
                } else {
                    return (node.tasks.cmd.build.mode orelse .Debug) != .ReleaseSmall;
                }
            }
            pub fn formatWriteNameFull(node: *const Node, sep: u8, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (node.flags.is_top) {
                    return 0;
                }
                const nodes: []*Node = node.getNodes();
                if (nodes.len != 0) {
                    ptr += nodes[0].formatWriteNameFull(sep, ptr);
                    if (ptr != buf) {
                        ptr[0] = sep;
                        ptr += 1;
                    }
                    ptr = fmt.strcpyEqu(ptr, node.name);
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            pub fn formatLengthNameFull(node: *const Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (node.flags.is_top) {
                    return 0;
                }
                var len: usize = node.getNodes()[0].formatLengthNameFull();
                len +%= @intFromBool(len != 0) +% node.name.len;
                return len;
            }
            pub fn formatWriteNameRelative(node: *const Node, group: *const Node, sep: u8, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (node != group) {
                    ptr += node.getNodes()[0].formatWriteNameRelative(group, sep, ptr);
                    if (ptr != buf) {
                        ptr[0] = sep;
                        ptr += 1;
                    }
                    ptr = fmt.strcpyEqu(ptr, node.name);
                }
                return fmt.strlen(ptr, buf);
            }
            pub fn formatLengthNameRelative(node: *const Node, group: *const Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = 0;
                if (node != group) {
                    len +%= node.getNodes()[0].formatLengthNameRelative(group);
                    len +%= @intFromBool(len != 0) +% node.name.len;
                }
                return len;
            }
            pub fn formatWriteConfigRoot(node: *Node, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                const paths: []types.Path = node.getPaths();
                var ptr: [*]u8 = buf;
                if (have_lazy and node.flags.want_builder_decl) {
                    buf[0..122].* =
                        \\const zl=@import("zl");
                        \\pub const AbsoluteState=struct{
                        \\home:[:0]const u8,
                        \\cwd:[:0]const u8,
                        \\proj:[:0]const u8,
                        \\pid:u16,};
                    .*;
                    ptr += 122;
                    ptr = fmt.strcpyEqu(ptr, "pub const Builder=zl.build.GenericBuilder(.{.options=");
                    ptr = fmt.strcpyEqu(ptr, options_s);
                    ptr -= 1;
                    ptr[0..2].* = ",}".*;
                    ptr += 2;
                    ptr = fmt.strcpyEqu(ptr, ",.logging=");
                    ptr = fmt.strcpyEqu(ptr, logging_s);
                    ptr -= 1;
                    ptr[0..2].* = ",}".*;
                    ptr += 2;
                    ptr = fmt.strcpyEqu(ptr, ",.errors=zl.build.spec.errors.kill(),});\n");
                }
                ptr[0..31].* = "pub usingnamespace @import(\"../".*;
                ptr += 31;
                ptr = fmt.strcpyEqu(ptr, paths[1].names[1]);
                ptr[0..4].* = "\");\n".*;
                ptr += 4;
                for (node.getConfigs()) |cfg| {
                    ptr += cfg.formatWriteBuf(ptr);
                }
                if (node.flags.have_task_data) {
                    ptr = about.writeTaskDataConfig(node, ptr);
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            pub fn find(group: *Node, allocator: *Allocator, name: []const u8, sep: u8) ?*Node {
                @setRuntimeSafety(builtin.is_safe);
                const nodes: []*Node = group.getNodes();
                blk: {
                    var idx: usize = 0;
                    while (idx != name.len) : (idx +%= 1) {
                        if (name[idx] == sep) {
                            break;
                        }
                    } else {
                        idx = 1;
                        while (idx != nodes.len) : (idx +%= 1) {
                            if (mem.testEqualString(name, nodes[idx].name)) {
                                return nodes[idx];
                            }
                        }
                        break :blk;
                    }
                    const group_name: []const u8 = name[0..idx];
                    idx +%= 1;
                    if (idx == name.len) {
                        break :blk;
                    }
                    const sub_name: []const u8 = name[idx..];
                    idx = 1;
                    while (idx != nodes.len) : (idx +%= 1) {
                        if (nodes[idx].flags.is_group and
                            mem.testEqualString(group_name, nodes[idx].name))
                        {
                            return nodes[idx].find(allocator, sub_name, sep);
                        }
                    }
                }
                if (have_list) {
                    about.writeAndWalk(allocator, group);
                }
                return null;
            }
        };
        pub fn configRootRelative(allocator: *Allocator, node: *Node) [:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const name_len: usize = node.formatLengthNameFull();
            const buf: [*:0]u8 = @ptrFromInt(allocator.allocateRaw(name_len +% 5, 1));
            fmt.strcpyEqu(buf + node.formatWriteNameFull('-', buf), ".zig")[0] = 0;
            return buf[0 .. name_len +% 4 :0];
        }
        fn createConfigRoot(allocator: *Allocator, node: *Node, pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = try meta.wrap(file.createAt(create(), create_truncate_options, node.configRootFd(), pathname, file.mode.regular));
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(65536, 1));
            const len: usize = node.formatWriteConfigRoot(buf);
            try meta.wrap(file.write(write(), fd, buf[0..len]));
            try meta.wrap(file.close(close(), fd));
            @memset(buf[0..len], 0);
            allocator.restore(@intFromPtr(buf));
            node.flags.have_config_root = true;
        }
        pub fn outputRelative(allocator: *Allocator, node: *Node, tag: types.File.Tag) [:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var buf: [4096]u8 = undefined;
            const name: []u8 = if (builder_spec.options.naming_policy == .full_name) blk: {
                const len: usize = node.formatWriteNameFull('-', &buf);
                break :blk buf[0..len];
            } else node.name;
            return concatenate(allocator, switch (tag) {
                .output_exe => &[_][]const u8{ binary_prefix, name },
                .output_ar => &[_][]const u8{ archive_prefix, name, builder_spec.options.ar_ext },
                .output_obj => &[_][]const u8{ binary_prefix, name, builder_spec.options.obj_ext },
                .output_lib => &[_][]const u8{ library_prefix, name, builder_spec.options.lib_ext },
                .output_llvm_ir => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.llvm_ir_ext },
                .output_llvm_bc => &[_][]const u8{ auxiliary_prefix, name, builder_spec.options.llvm_bc_ext },
                else => proc.exitErrorFault(error.InvalidOutput, @tagName(tag), 2),
            });
        }
        inline fn shallowCacheCheck(file_stats: *Node.FileStats, dest_pathname: [:0]const u8, root_pathname: [:0]const u8) u8 {
            @setRuntimeSafety(builtin.is_safe);
            try meta.wrap(file.statusAt(stat(), .{}, file.cwd, dest_pathname, &file_stats.input));
            try meta.wrap(file.statusAt(stat(), .{}, file.cwd, root_pathname, &file_stats.output));
            return if (file_stats.input.mtime.sec > file_stats.output.mtime.sec)
                builder_spec.options.compiler_expected_status
            else
                builder_spec.options.compiler_cache_hit_status;
        }
        fn sameFile(st1: *file.Status, pathname1: [:0]const u8, st2: *file.Status, pathname2: [:0]const u8) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (mem.testEqualString(pathname1, pathname2)) {
                return true;
            }
            mem.zero(file.Status, st1);
            try meta.wrap(file.statusAt(stat(), .{}, file.cwd, pathname1, st1));
            mem.zero(file.Status, st2);
            try meta.wrap(file.statusAt(stat(), .{}, file.cwd, pathname2, st2));
            return (st1.mode.kind != .unknown and st2.mode.kind != .unknown) and
                ((st1.dev == st2.dev) and (st1.ino == st2.ino));
        }
        inline fn validateUserPath(pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var dot_dot: bool = false;
            var sep_sep: bool = false;
            for (pathname) |byte| {
                if (byte == '.') {
                    if (dot_dot) {
                        proc.exitErrorFault(error.BadPath, pathname);
                    }
                    dot_dot = true;
                } else {
                    dot_dot = false;
                }
                if (byte == '/') {
                    if (sep_sep) {
                        proc.exitErrorFault(error.BadPath, pathname);
                    }
                    sep_sep = true;
                } else {
                    sep_sep = false;
                }
            }
        }
        fn createNode(allocator: *Allocator, group: *Node, name: [:0]const u8, flags: Node.Flags, task_tag: Task, lock: Lock) *Node {
            @setRuntimeSafety(builtin.is_safe);
            const node: *Node = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node), @alignOf(Node)));
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.name = duplicate(allocator, name);
            node.sh = group.sh;
            node.tasks.tag = task_tag;
            node.flags = flags;
            node.lock = lock;
            node.descr = "";
            return node;
        }
        const zig_lib_module = "zl::" ++ builtin.lib_root ++ "/zig_lib.zig";
        fn initializeExtensions(allocator: *Allocator, top: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            const zero: *Node = top.addGroup(allocator, "zero", .{
                .zig_exe = top.zigExe(),
                .build_root = builtin.lib_root,
                .cache_root = lib_cache_root,
                .global_cache_root = top.globalCacheRoot(),
            });
            zero.flags.is_special = true;
            top.sh.dl = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(DynamicLoader),
                @alignOf(DynamicLoader),
            ));
            top.sh.dl.* = .{};
            top.sh.fp = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(FunctionPointers),
                @alignOf(FunctionPointers),
            ));
            mem.zero(FunctionPointers, top.sh.fp);
            top.sh.extns = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Extensions),
                @alignOf(Extensions),
            ));
            mem.zero(Extensions, top.sh.extns);
            top.sh.extns.trace = zero.addBuild(allocator, trace_build_cmd, "trace", "top/trace.zig");
            if (have_lazy) {
                var ptr: *[25][*:0]u8 = @ptrFromInt(allocator.allocateRaw(25 *% 8, 8));
                var tmp = [25][*:0]const u8{
                    top.zigExe(),             "build-lib",
                    "--cache-dir",            zero.cacheRoot(),
                    "--global-cache-dir",     zero.globalCacheRoot(),
                    "--main-mod-path",        zero.buildRoot(),
                    "--mod",                  zig_lib_module,
                    "-dynamic",               "--listen=-",
                    "--deps",                 "zl",
                    "--entry",                "load",
                    "-z",                     "defs",
                    "-fsingle-threaded",      "-fno-compiler-rt",
                    "-fno-stack-check",       "-fno-unwind-tables",
                    "-fno-function-sections", "-fstrip",
                    "-ODebug",
                };
                for (ptr, tmp) |*dest, src| dest.* = @constCast(src);
                top.sh.extns.proc = createNode(allocator, zero, "proc", extn_flags, .build, obj_lock);
                top.sh.extns.about = createNode(allocator, zero, "about", extn_flags, .build, obj_lock);
                top.sh.extns.build = createNode(allocator, zero, "build", extn_flags, .build, obj_lock);
                top.sh.extns.format = createNode(allocator, zero, "format", extn_flags, .build, obj_lock);
                top.sh.extns.objcopy = createNode(allocator, zero, "objcopy", extn_flags, .build, obj_lock);
                top.sh.extns.archive = createNode(allocator, zero, "archive", extn_flags, .build, obj_lock);
                top.sh.extns.proc.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.proc.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.proc.addSourceInputPath(allocator, "top/build/proc.auto.zig");
                top.sh.extns.about.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.about.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.about.addSourceInputPath(allocator, "top/build/about.auto.zig");
                top.sh.extns.build.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.build.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.build.addSourceInputPath(allocator, "top/build/build.auto.zig");
                top.sh.extns.format.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.format.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.format.addSourceInputPath(allocator, "top/build/format.auto.zig");
                top.sh.extns.objcopy.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.objcopy.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.objcopy.addSourceInputPath(allocator, "top/build/objcopy.auto.zig");
                top.sh.extns.archive.lists.set([*:0]u8, .cmd_args, ptr);
                top.sh.extns.archive.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.archive.addSourceInputPath(allocator, "top/build/archive.auto.zig");
            }
        }
        fn classifySourceInputName(name: []const u8) types.File.Tag {
            @setRuntimeSafety(builtin.is_safe);
            for ([_]struct { [:0]const u8, types.File.Tag }{
                .{ builder_spec.options.zig_ext, .input_zig },
                .{ builder_spec.options.h_ext, .input_c },
                .{ builder_spec.options.lib_ext, .input_lib },
                .{ builder_spec.options.ar_ext, .input_ar },
                .{ builder_spec.options.obj_ext, .input_obj },
                .{ builder_spec.options.asm_ext, .input_asm },
                .{ builder_spec.options.llvm_bc_ext, .input_llvm_bc },
                .{ builder_spec.options.llvm_ir_ext, .input_llvm_ir },
            }) |pair| {
                if (mem.testEqualString(name[name.len -% pair[0].len ..], pair[0])) {
                    return pair[1];
                }
            }
            return .input_generic;
        }
        pub fn initializeGroup(allocator: *Allocator, node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            var st: [2]file.Status = undefined;
            if (node.flags.is_top or
                !sameFile(&st[0], node.groupNode().buildRoot(), &st[1], node.buildRoot()))
            {
                const dir_fds: *Node.DirFds = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node.DirFds), @alignOf(Node.DirFds)));
                dir_fds.build_root = try meta.wrap(file.openAt(open(), dir_options, file.cwd, node.buildRoot()));
                for ([4][:0]const u8{
                    builder_spec.options.cache_dir,
                    builder_spec.options.output_dir,
                    builder_spec.options.config_dir,
                    builder_spec.options.stat_dir,
                }) |name| {
                    mem.zero(file.Status, &st[0]);
                    try meta.wrap(file.statusAt(stat(), .{}, dir_fds.build_root, name, &st[0]));
                    if (st[0].mode.kind == .unknown) {
                        try meta.wrap(file.makeDirAt(mkdir(), dir_fds.build_root, name, file.mode.directory));
                    }
                }
                dir_fds.output_root = try meta.wrap(file.openAt(
                    open(),
                    dir_options,
                    dir_fds.build_root,
                    builder_spec.options.output_dir,
                ));
                for ([3][:0]const u8{
                    builder_spec.options.exe_out_dir,
                    builder_spec.options.lib_out_dir,
                    builder_spec.options.aux_out_dir,
                }) |name| {
                    mem.zero(file.Status, &st[0]);
                    try meta.wrap(file.statusAt(stat(), .{}, dir_fds.output_root, name, &st[0]));
                    if (st[0].mode.kind == .unknown) {
                        try meta.wrap(file.makeDirAt(mkdir(), dir_fds.output_root, name, file.mode.directory));
                    }
                }
                dir_fds.cache_root = try meta.wrap(file.openAt(
                    open(),
                    dir_options,
                    dir_fds.build_root,
                    builder_spec.options.cache_dir,
                ));
                dir_fds.config_root = try meta.wrap(file.openAt(
                    open(),
                    dir_options,
                    dir_fds.build_root,
                    builder_spec.options.config_dir,
                ));
                node.extra.dir_fds = dir_fds;
            } else {
                node.extra.dir_fds = node.groupNode().extra.dir_fds;
            }
            if (node.flags.is_top) {
                if (max_thread_count != 0) {
                    mem.map(map(), .{}, .{}, stack_lb_addr, stack_up_addr -% stack_lb_addr);
                }
            }
            initializeCommand(allocator, node);
        }
        pub fn initializeCommand(allocator: *Allocator, node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (node.sh.mode != .Regen and node.flags.do_init) {
                node.flags.do_init = false;
                if (builder_spec.options.init_inherit_special and
                    node.groupNode().flags.is_special)
                {
                    node.flags.is_special = true;
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, .init_inherit_hidden, .is_special, .enable_flag);
                    }
                }
                if (builder_spec.options.init_inherit_hidden and
                    node.groupNode().flags.is_hidden)
                {
                    node.flags.is_hidden = true;
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, .init_inherit_hidden, .is_hidden, .enable_flag);
                    }
                }
                if (builder_spec.options.init_hidden_by_name_prefix) |prefix| {
                    node.flags.is_hidden = node.name[0] == prefix;
                    if (builder_spec.logging.show_task_update and
                        node.flags.is_hidden)
                    {
                        about.aboutNode(node, .init_hidden_by_name_prefix, .is_hidden, .enable_flag);
                    }
                }
                if (node.tasks.tag == .build) {
                    if (builder_spec.options.add_stack_traces_to_debug_executables and
                        node.tasks.cmd.build.kind == .exe and node.hasDebugInfo())
                    {
                        node.flags.want_stack_traces = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, .add_stack_traces_debug_executables, .want_stack_traces, .enable_flag);
                        }
                    }
                    if (builder_spec.options.init_main_mod_path) {
                        node.tasks.cmd.build.main_mod_path = node.buildRoot();
                    }
                    if (builder_spec.options.init_cache_root) {
                        node.tasks.cmd.build.cache_root = node.cacheRoot();
                    }
                    if (builder_spec.options.init_global_cache_root) {
                        node.tasks.cmd.build.global_cache_root = node.globalCacheRoot();
                    }
                    if (builder_spec.options.add_comparison_report_to_elf) {
                        if (node.tasks.cmd.build.format) |format| {
                            node.flags.want_binary_analysis = format == .elf;
                        }
                    }
                    if (node.tasks.cmd.build.kind == .exe) {
                        if (builder_spec.options.add_run_task_to_executables) {
                            node.lock = exe_lock;
                            node.dependOn(allocator, node);
                            node.addRunArg(allocator).* = node.getPaths()[0].concatenate(allocator);
                            if (builder_spec.logging.show_task_update) {
                                about.aboutNode(node, .add_run_task_to_executables, null, .add_run_arg);
                            }
                        }
                        if (builder_spec.options.add_comparison_report_to_elf) {
                            node.flags.want_binary_analysis = true;
                        }
                    }
                    if (builder_spec.options.init_config_zig_sources and
                        node.getFile(.{ .tag = .input_zig }) != null)
                    {
                        node.flags.want_build_config = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, .init_config_zig_sources, .want_build_config, .enable_flag);
                        }
                    }
                    node.tasks.cmd.build.listen = .@"-";
                }
            }
        }
        pub fn recursiveAction(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
            actionFn: *const fn (*AddressSpace, *ThreadSpace, *Allocator, *Node, Task, AddressSpace.Index) bool,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            if (actionFn(address_space, thread_space, allocator, node, task, arena_index)) {
                const nodes: []*Node = node.getNodes();
                if (node.flags.is_group) {
                    for (nodes[1..]) |sub| {
                        recursiveAction(address_space, thread_space, allocator, sub, task, arena_index, actionFn);
                    }
                } else {
                    const deps: []Node.Depn = node.getDepns();
                    for (deps) |dep| {
                        recursiveAction(address_space, thread_space, allocator, nodes[dep.node_idx], task, arena_index, actionFn);
                    }
                }
            }
        }
        fn taskArgs(allocator: *Allocator, node: *Node, tag: types.Lists.Tag) [][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const args: *const []const usize = @ptrCast(node.lists.get(tag));
            const grp_args: *const []const usize = @ptrCast(node.groupNode().lists.get(tag));
            const args_len: usize = args.len +% (if (node.flags.is_primary) grp_args.len else 0);
            const ret: [*]usize = @ptrFromInt(allocator.allocateRaw(8 *% (args_len +% 1), 8));
            @memcpy(ret, args.*);
            @memcpy(ret + args.len, grp_args.*);
            ret[args.len +% grp_args.len] = 0;
            return @ptrCast(ret[0..args_len]);
        }
        inline fn buildTaskArgs(allocator: *Allocator, node: *Node) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const paths: []types.Path = node.getPaths()[@as(usize, 1) +% @intFromBool(node.flags.have_config_root) ..];
            if (!node.flags.have_task_data) {
                return taskArgs(allocator, node, .cmd_args);
            }
            const save = node.tasks.cmd.build;
            defer node.tasks.cmd.build = save;
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.build.formatParseArgs(node.tasks.cmd.build, allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.BuildCommand = node.tasks.cmd.build;
                const max_len: usize = node.sh.fp.build.formatLength(cmd, node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.build.formatWriteBuf(cmd, node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.build.formatParseArgs(allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.BuildCommand = node.tasks.cmd.build;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        inline fn formatTaskArgs(allocator: *Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.format.formatParseArgs(node.tasks.cmd.format, allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.FormatCommand = node.tasks.cmd.format;
                const max_len: usize = node.sh.fp.format.formatLength(cmd, node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.format.formatWriteBuf(cmd, node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.format.formatParseArgs(allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.FormatCommand = node.tasks.cmd.format;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        inline fn fetchTaskArgs(allocator: *Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.fetch.fetchParseArgs(node.tasks.cmd.fetch, allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.fetchCommand = node.tasks.cmd.fetch;
                const max_len: usize = node.sh.fp.fetch.fetchLength(cmd, node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.fetch.fetchWriteBuf(cmd, node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.fetch.fetchParseArgs(allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.fetchCommand = node.tasks.cmd.fetch;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.fetchLength(node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.fetchWriteBuf(node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        inline fn objcopyTaskArgs(allocator: *Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.objcopy.formatParseArgs(node.tasks.cmd.objcopy, allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.ObjcopyCommand = node.tasks.cmd.objcopy;
                const max_len: usize = node.sh.fp.objcopy.formatLength(cmd, node.zigExe(), paths[1]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.objcopy.formatWriteBuf(cmd, node.zigExe(), paths[1], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.objcopy.formatParseArgs(allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.ObjcopyCommand = node.tasks.cmd.objcopy;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths[1]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths[1], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        inline fn archiveTaskArgs(allocator: *Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.archive.formatParseArgs(node.tasks.cmd.archive, allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.ArchiveCommand = node.tasks.cmd.archive;
                const max_len: usize = node.sh.fp.archive.formatLength(cmd, node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.archive.formatWriteBuf(cmd, node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.archive.formatParseArgs(allocator, node.groupNode().getCmdArgs());
                }
                const cmd: *tasks.ArchiveCommand = node.tasks.cmd.archive;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        inline fn executeRunCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const args: [][*:0]u8 = taskArgs(allocator, node, .run_args);
            try meta.wrap(system(node, results, mem.terminate(args[0], 0), args, node.sh.vars));
            return status(results);
        }
        inline fn executeBuildCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const dest_pathname: [:0]const u8 = node.getPaths()[0].concatenate(allocator);
            results.server = builder_spec.options.compiler_expected_status;
            if (results.server == builder_spec.options.compiler_expected_status) {
                if (buildTaskArgs(allocator, node)) |args| {
                    const in: file.Pipe = try meta.wrap(file.makePipe(pipe(), pipe_options));
                    const out: file.Pipe = try meta.wrap(file.makePipe(pipe(), pipe_options));
                    const pid: usize = try meta.wrap(serverOpen(node, args, in, out));
                    serverLoop(allocator, node, dest_pathname, in, out);
                    serverClose(node, in, out, pid);
                }
            }
            if (have_lazy and keepGoing(node) and
                node.flags.is_dynamic_extension)
            {
                node.sh.dl.load(dest_pathname).autoLoad(node.sh.fp);
            }
            return status(results);
        }
        inline fn executeFormatCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const paths: []types.Path = node.getPaths();
            if (formatTaskArgs(allocator, node, paths)) |args| {
                try meta.wrap(system(node, results, mem.terminate(args[0], 0), args, node.sh.vars));
            }
            return status(results);
        }
        inline fn executeFetchCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const paths: []types.Path = node.getPaths();
            if (fetchTaskArgs(allocator, node, paths)) |args| {
                try meta.wrap(system(node, results, mem.terminate(args[0], 0), args, node.sh.vars));
            }
            return status(results);
        }
        inline fn executeArchiveCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const paths: []types.Path = node.getPaths();
            if (archiveTaskArgs(allocator, node, paths)) |args| {
                try meta.wrap(system(node, results, mem.terminate(args[0], 0), args, node.sh.vars));
            }
            return status(results);
        }
        inline fn executeObjcopyCommand(allocator: *Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const results: *Node.Results = node.extra.results.?;
            const paths: []types.Path = node.getPaths();
            if (objcopyTaskArgs(allocator, node, paths)) |args| {
                try meta.wrap(system(node, results, mem.terminate(args[0], 0), args, node.sh.vars));
            }
            return status(results);
        }
        fn executeCommand(allocator: *Allocator, node: *Node, task: Task, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builtin.is_safe);
            const ret: bool = switch (task) {
                .build => executeBuildCommand(allocator, node),
                .fetch => have_fetch and executeFormatCommand(allocator, node),
                .format => have_format and executeFormatCommand(allocator, node),
                .archive => have_archive and executeArchiveCommand(allocator, node),
                .objcopy => have_objcopy and executeObjcopyCommand(allocator, node),
                else => have_run and executeRunCommand(allocator, node),
            };
            about.aboutTask(allocator, node, task, arena_index);
            return ret;
        }
        fn executeCommandDependencies(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            const nodes: []*Node = node.getNodes();
            if (node.flags.is_group) {
                for (nodes[1..]) |sub_node| {
                    if (sub_node == node and sub_node.tasks.tag == task) {
                        continue;
                    }
                    if (!keepGoing(node)) return;
                    if (exchange(sub_node, task, .ready, .blocking, arena_index)) {
                        try meta.wrap(tryAcquireThread(address_space, thread_space, allocator, sub_node, task, arena_index));
                    }
                }
            } else {
                for (node.getDepns()) |dep| {
                    if (nodes[dep.node_idx] == node and
                        dep.on_task == task or dep.task != task)
                    {
                        continue;
                    }
                    if (!keepGoing(node)) return;
                    if (exchange(nodes[dep.node_idx], dep.on_task, .ready, .blocking, arena_index)) {
                        try meta.wrap(tryAcquireThread(address_space, thread_space, allocator, nodes[dep.node_idx], dep.on_task, arena_index));
                    }
                }
            }
        }
        fn tryAcquireThread(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy and max_thread_count != 0 and
                defined(node.sh.fp.proc.executeCommandClone))
            {
                var thread_index: ThreadSpace.Index = 0;
                while (thread_index != max_thread_count) : (thread_index +%= 1) {
                    if (mem.testAcquire(ThreadSpace, thread_space, thread_index)) {
                        return @call(.auto, node.sh.fp.proc.executeCommandClone, .{
                            address_space, thread_space, node, task, thread_index, executeCommandThreaded, ThreadSpace.low(thread_index), stack_aligned_bytes,
                        });
                    }
                }
            }
            executeCommandSynchronised(address_space, thread_space, allocator, node, task, arena_index);
        }
        pub fn prepareCommand(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (node.flags.do_prepare) {
                node.flags.do_prepare = false;
            } else {
                return false;
            }
            if (builder_spec.logging.show_waiting_tasks) {
                node.extra.wait = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node.Wait), 8));
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .{ .allocate = .wait });
                }
            }
            if (node.flags.is_group) {
                return true;
            }
            if (node.tasks.tag == .build) {
                for (node.getFiles()) |fs| {
                    var tag: types.File.Tag = fs.key.tag;
                    if (tag.toggle(.{ .is_cached = true, .is_output = true })) {
                        node.addFile(allocator).* = .{
                            .key = .{ .tag = tag },
                            .st = @ptrFromInt(allocator.allocateRaw(144, 8)),
                        };
                    }
                }
            }
            if (node.flags.is_primary and node.flags.want_perf_events) {
                node.extra.perf_events = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(PerfEvents),
                    @alignOf(PerfEvents),
                ));
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, .want_perf_events, .{ .allocate = .perf_events });
                }
            }
            node.extra.results = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(Node.Results),
                @alignOf(Node.Results),
            ));
            if (builder_spec.logging.show_task_update) {
                about.aboutNode(node, null, null, .{ .allocate = .results });
            }
            if (builder_spec.options.add_stack_traces_to_debug_executables) {
                if (node.flags.want_stack_traces) {
                    if (!node.hasDebugInfo()) {
                        node.tasks.cmd.build.strip = false;
                    }
                    node.dependOn(allocator, node.sh.extns.trace);
                    if (node.flags.want_build_config) {
                        node.addConfigBool(allocator, "have_stack_traces", true);
                    }
                }
            }
            if (node.flags.want_build_config and !node.flags.have_config_root) {
                const cfg_root_path: *types.Path = node.addPath(allocator, .input_zig);
                cfg_root_path.addName(allocator).* = node.buildRoot();
                cfg_root_path.addName(allocator).* = builder_spec.options.config_dir;
                cfg_root_path.addName(allocator).* = configRootRelative(allocator, node);
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, .want_build_config, .add_file);
                }
                if (!node.flags.have_task_data) {
                    node.addCmdArg(allocator).* = cfg_root_path.concatenate(allocator);
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, null, .have_task_data, .add_cmd_arg);
                    }
                }
                if (node.flags.want_build_context) {
                    node.addBuildContextConfigs(allocator);
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, null, .want_build_context, .add_build_context_decls);
                    }
                }
                if (node.flags.want_define_decls) {
                    node.addDefineConfigs(allocator);
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, null, .want_define_decls, .add_define_decls);
                    }
                }
                createConfigRoot(allocator, node, cfg_root_path.names[2]);
            }
            if (have_lazy) {
                if (max_thread_count != 0 and builder_spec.options.eager_multi_threading or
                    (node.flags.is_group and node.getNodes().len > 2) or
                    (!node.flags.is_group and node.getDepns().len > 1))
                {
                    if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.proc, task, arena_index)) {
                        node.sh.top.dependOn(allocator, node.sh.extns.proc);
                    }
                }
                if (!node.flags.is_group) {
                    if (node.flags.have_task_data and !defined(node.sh.fp.about.generic.aboutTask)) {
                        if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.about, task, arena_index)) {
                            node.sh.top.dependOn(allocator, node.sh.extns.about);
                        }
                    }
                    if (node.flags.have_task_data) {
                        if (node.tasks.tag == .build and !defined(node.sh.fp.build.formatWriteBuf)) {
                            if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.build, task, arena_index)) {
                                node.sh.top.dependOn(allocator, node.sh.extns.build);
                            }
                        }
                        if (node.tasks.tag == .format and !defined(node.sh.fp.format.formatWriteBuf)) {
                            if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.format, task, arena_index)) {
                                node.sh.top.dependOn(allocator, node.sh.extns.format);
                            }
                        }
                        if (node.tasks.tag == .archive and !defined(node.sh.fp.archive.formatWriteBuf)) {
                            if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.archive, task, arena_index)) {
                                node.sh.top.dependOn(allocator, node.sh.extns.archive);
                            }
                        }
                        if (node.tasks.tag == .objcopy and !defined(node.sh.fp.objcopy.formatWriteBuf)) {
                            if (prepareCommand(address_space, thread_space, allocator, node.sh.extns.objcopy, task, arena_index)) {
                                node.sh.top.dependOn(allocator, node.sh.extns.objcopy);
                            }
                        }
                    } else {
                        node.addCmdArg(allocator).* = comptime builtin.zero([*:0]u8);
                        node.lists.list(.cmd_args).len -%= 1;
                    }
                }
            }
            return true;
        }
        pub fn executeCommandThreaded(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            var allocator: Allocator = Allocator.fromArena(AddressSpace.arena(arena_index));
            executeCommandDependencies(address_space, thread_space, &allocator, node, task, arena_index);
            while (keepGoing(node) and waitForNode(node, task, arena_index)) {
                try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
            }
            if (node.lock.get(task) == .working) {
                if (executeCommand(&allocator, node, task, arena_index)) {
                    allocator.unmapAll();
                    assertExchange(node, task, .working, .finished, arena_index);
                } else {
                    allocator.unmapAll();
                    assertExchange(node, task, .working, .failed, arena_index);
                }
            } else {
                allocator.unmapAll();
            }
            mem.release(ThreadSpace, thread_space, arena_index);
        }
        inline fn executeCommandSynchronised(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            executeCommandDependencies(address_space, thread_space, allocator, node, task, arena_index);
            const save: usize = allocator.save();
            while (keepGoing(node) and waitForNode(node, task, arena_index)) {
                try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
            }
            if (node.lock.get(task) == .working) {
                if (executeCommand(allocator, node, task, arena_index)) {
                    allocator.restore(save);
                    assertExchange(node, task, .working, .finished, arena_index);
                } else {
                    allocator.restore(save);
                    assertExchange(node, task, .working, .failed, arena_index);
                }
            } else {
                allocator.restore(save);
            }
        }
        pub fn executeSubNode(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            node: *Node,
            task: Task,
        ) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (exchange(node, task, .ready, .blocking, max_thread_count)) {
                try meta.wrap(tryAcquireThread(address_space, thread_space, allocator, node, task, max_thread_count));
            }
            if (max_thread_count != 0) {
                while (thread_space.count() != 0) {
                    try meta.wrap(time.sleep(sleep(), .{ .nsec = builder_spec.options.sleep_nanoseconds }));
                    if (builder_spec.logging.show_waiting_tasks) {
                        if (node.extra.wait) |wait| {
                            if (wait.total >> 28 > wait.tick) {
                                about.writeWaitingOn(node, max_thread_count);
                                wait.tick +%= 1;
                            } else {
                                wait.total +%= builder_spec.options.sleep_nanoseconds;
                            }
                        }
                    }
                }
            }
            return node.lock.get(task) == .finished;
        }
        pub fn processCommands(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *Allocator,
            group: *Node,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            group.sh.mode = .Command;
            if (builder_spec.logging.show_base_memory_usage) {
                about.aboutBaseMemoryUsageNotice(allocator);
            }
            const args: [][*:0]u8 = group.sh.args;
            var maybe_task: ?Task = null;
            var cmd_args_idx: usize = 5;
            var want_seed: bool = false;
            var want_list: bool = false;
            var want_perf: bool = false;
            var want_size: bool = false;
            var want_trace: bool = false;
            lo: while (cmd_args_idx != args.len) : (cmd_args_idx +%= 1) {
                var name: [:0]const u8 = mem.terminate(args[cmd_args_idx], 0);
                for ([5]Task{ .format, .build, .run, .archive, .objcopy }) |task| {
                    if (mem.testEqualString(name, @tagName(task))) {
                        maybe_task = task;
                        continue :lo;
                    }
                }
                if (!want_seed and mem.testEqualString("--seed", name)) {
                    cmd_args_idx +%= 1;
                    group.sh.seed = mem.terminate(args[cmd_args_idx], 0);
                    want_seed = true;
                    continue;
                }
                if (have_list and
                    mem.testEqualString(builder_spec.options.list_command.?, name))
                {
                    want_list = true;
                    continue;
                }
                if (have_perf and
                    mem.testEqualString(builder_spec.options.perf_command.?, name))
                {
                    want_perf = true;
                    continue;
                }
                if (have_size and
                    mem.testEqualString(builder_spec.options.size_command.?, name))
                {
                    want_size = true;
                    continue;
                }
                if (have_trace and
                    mem.testEqualString(builder_spec.options.trace_command.?, name))
                {
                    want_trace = true;
                    continue;
                }
                if (group.find(allocator, name, builder_spec.options.namespace_separator.cmd)) |node| {
                    const task: Task = maybe_task orelse node.tasks.tag;
                    if (node.flags.is_group) {
                        for (node.getNodes()[1..]) |sub_node| {
                            if (node.tasks.tag == .any or
                                sub_node.tasks.tag == task)
                            {
                                sub_node.flags.is_primary = true;
                                if (builder_spec.logging.show_task_update) {
                                    about.aboutNode(sub_node, null, .is_primary, .enable_flag);
                                }
                            }
                        }
                    } else {
                        node.flags.is_primary = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, .is_primary, .enable_flag);
                        }
                    }
                    if (have_list and want_list) {
                        return about.writeAndWalk(allocator, node);
                    }
                    if (have_perf and want_perf) {
                        node.flags.want_perf_events = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, .want_perf_events, .enable_flag);
                        }
                    }
                    if (have_size and want_size) {
                        node.flags.want_binary_analysis = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, .want_binary_analysis, .enable_flag);
                        }
                    }
                    if (have_trace and want_trace) {
                        node.flags.want_stack_traces = true;
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, .want_stack_traces, .enable_flag);
                        }
                    }
                    const args_node: *Node = if (node.flags.is_group) node else node.groupNode();
                    cmd_args_idx +%= 1;
                    var run_args_idx: usize = cmd_args_idx;
                    while (run_args_idx != args.len) : (run_args_idx +%= 1) {
                        if (mem.testEqualString(
                            builder_spec.options.append_run_args_string,
                            mem.terminate(args[run_args_idx], 0),
                        )) {
                            args_node.lists.set([*:0]u8, .cmd_args, args[cmd_args_idx..run_args_idx]);
                            run_args_idx +%= 1;
                            args_node.lists.set([*:0]u8, .run_args, args[run_args_idx..]);
                            break;
                        }
                    } else {
                        args_node.lists.set([*:0]u8, .cmd_args, args[cmd_args_idx..]);
                    }
                    if (builder_spec.logging.show_user_input) {
                        about.commandLineNotice(node);
                    }
                    node.sh.mode = .Exec;
                    recursiveAction(address_space, thread_space, allocator, node, task, max_thread_count, &prepareCommand);
                    const depns: []Node.Depn = node.sh.top.getDepns();
                    const nodes: []*Node = node.sh.top.getNodes();
                    for (depns) |depn| {
                        if (!executeSubNode(address_space, thread_space, allocator, nodes[depn.node_idx], depn.on_task)) {
                            proc.exitError(error.UnfinishedRequest, 2);
                        }
                    }
                    if (!executeSubNode(address_space, thread_space, allocator, node, task)) {
                        proc.exitError(error.UnfinishedRequest, 2);
                    }
                    break;
                }
            } else {
                if (args.len == @as(usize, if (want_seed) 7 else 5)) {
                    proc.exitErrorFault(error.NotACommand, "(null)", 2);
                } else {
                    proc.exitErrorFault(error.NotACommand, mem.terminate(args[args.len -% 1], 0), 2);
                }
            }
        }
        fn finishUp(node: *Node) void {
            @setRuntimeSafety(false);
            writeCacheBytes(node, "tab", @ptrCast(node.sh.fp), @sizeOf(FunctionPointers));
            writeCacheBytes(node, "prog", @ptrFromInt(node.sh.dl.lb_prog_addr), node.sh.dl.ub_prog_addr -% node.sh.dl.lb_prog_addr);
            writeCacheBytes(node, "meta", @ptrFromInt(node.sh.dl.lb_meta_addr), node.sh.dl.ub_meta_addr -% node.sh.dl.lb_meta_addr);
        }
        fn writeCacheBytes(node: *Node, name: [:0]const u8, buf: [*]u8, len: usize) void {
            @setRuntimeSafety(false);
            const fd: usize = try meta.wrap(file.createAt(create(), create_truncate_options, node.cacheRootFd(), name, file.mode.regular));
            file.write(write(), fd, buf[0..len]);
            file.close(close(), fd);
        }
        fn mapImmediate(allocator: *Allocator, node: *Node) void {
            @setRuntimeSafety(false);
            if (have_lazy and node.flags.is_dynamic_extension) {
                if (node.getFile(.{ .tag = .output_lib })) |fs| {
                    node.getPaths()[fs.path_idx].status(stat(), fs.st);
                    if (fs.st.mode.kind != .unknown) {
                        const save: usize = allocator.next;
                        var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(4097, 1));
                        var len: usize = node.getPaths()[fs.path_idx].formatWriteBuf(buf);
                        len -%= 1;
                        node.sh.dl.load(buf[0..len :0]).autoLoad(node.sh.fp);
                        allocator.next = save;
                        if (builder_spec.options.init_load_ok) {
                            assertExchange(node, .build, .ready, .finished, max_thread_count);
                        }
                    }
                }
            }
        }
        fn mapCacheBytes(node: *Node, name: [:0]const u8, prot: file.Map.Protection, addr: usize) usize {
            @setRuntimeSafety(false);
            if (node.sh.top.extra.file_stats) |file_stats| {
                mem.zero(file.Status, &file_stats.cached);
                file.statusAt(stat(), .{}, node.cacheRootFd(), name, &file_stats.cached);
                if (file_stats.cached.mode.kind == .regular) {
                    const fd: usize = try meta.wrap(file.openAt(open(), open_options, node.cacheRootFd(), name));
                    const len: usize = bits.alignA4096(file_stats.cached.size);
                    try meta.wrap(file.map(map(), prot, .{ .fixed = true }, fd, addr, len, 0));
                    file.close(close(), fd);
                    return addr +% len;
                }
            }
            return 0;
        }
        fn system(node: *Node, results: *Node.Results, exe: [:0]const u8, args: [][*:0]u8, vars: [][*:0]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_perf and node.flags.want_perf_events) {
                startPerf(node);
            }
            results.time = try meta.wrap(time.get(clock(), .realtime));
            const pid: u64 = try meta.wrap(proc.fork(fork()));
            if (pid == 0) {
                try meta.wrap(file.execPath(execve(), exe, args, vars));
            }
            const ret: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
            results.status = proc.Status.exitStatus(ret.status);
            results.signal = proc.Status.termSignal(ret.status);
            results.time = time.diff(try meta.wrap(time.get(clock(), .realtime)), results.time);
            if (have_perf and node.flags.want_perf_events) {
                stopPerf(node);
            }
        }
        inline fn installFromCache(node: *Node, output_pathname: [:0]const u8, cached_pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            const output: *file.Status = node.getFile(.{ .tag = .output_generic }).?.st;
            const cached: *file.Status = node.getFile(.{ .tag = .cached_generic }).?.st;
            if (!sameFile(output, output_pathname, cached, cached_pathname)) {
                if (have_size and
                    node.flags.want_binary_analysis)
                {
                    if (cached.mode.kind == .regular and cached.size != 0) {
                        node.extra.info_after = node.sh.dl.load(cached_pathname);
                    }
                    if (output.mode.kind == .regular and output.size != 0) {
                        node.extra.info_before = node.sh.dl.load(output_pathname);
                    }
                }
                try meta.wrap(file.unlink(unlink(), output_pathname));
                try meta.wrap(file.link(link(), cached_pathname, output_pathname));
            } else if (have_size and
                node.flags.want_binary_analysis)
            {
                if (cached.mode.kind == .regular and cached.size != 0) {
                    node.extra.info_after = node.sh.dl.load(cached_pathname);
                }
            }
        }
        fn startPerf(node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (node.extra.perf_events) |perf_events| {
                if (have_lazy) {
                    if (defined(node.sh.fp.about.perf.openFds)) {
                        try meta.wrap(node.sh.fp.about.perf.openFds(perf_events));
                    }
                } else {
                    try meta.wrap(perf_events.openFds());
                }
            }
        }
        fn stopPerf(node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (node.extra.perf_events) |perf_events| {
                if (have_lazy) {
                    if (defined(node.sh.fp.about.perf.readResults)) {
                        try meta.wrap(node.sh.fp.about.perf.readResults(perf_events));
                    }
                } else {
                    try meta.wrap(perf_events.readResults());
                }
            }
        }
        fn serverOpen(node: *Node, args: [][*:0]u8, in: file.Pipe, out: file.Pipe) usize {
            if (have_perf) {
                if (node.flags.want_perf_events and node.flags.is_primary) {
                    startPerf(node);
                }
            }
            if (node.extra.results) |results| {
                results.time = try meta.wrap(time.get(clock(), .realtime));
            }
            const pid: usize = try meta.wrap(proc.fork(fork()));
            if (pid == 0) {
                try meta.wrap(file.close(close(), in.write));
                try meta.wrap(file.close(close(), out.read));
                try meta.wrap(file.duplicateTo(dup3(), .{}, in.read, 0));
                try meta.wrap(file.duplicateTo(dup3(), .{}, out.write, 1));
                try meta.wrap(file.execPath(execve(), node.zigExe(), args, node.sh.vars));
            }
            try meta.wrap(file.close(close(), in.read));
            try meta.wrap(file.close(close(), out.write));
            try meta.wrap(file.write(write2(), in.write, update_exit_message[0..1]));
            return pid;
        }
        fn serverClose(node: *Node, in: file.Pipe, out: file.Pipe, pid: usize) void {
            const rc: proc.Return = try meta.wrap(proc.waitPid(waitpid(), .{ .pid = pid }));
            if (node.extra.results) |results| {
                results.status = proc.Status.exitStatus(rc.status);
                results.signal = proc.Status.termSignal(rc.status);
                results.time = time.diff(try meta.wrap(time.get(clock(), .realtime)), results.time);
            }
            if (have_perf and node.flags.want_perf_events and
                node.flags.is_primary)
            {
                stopPerf(node);
            }
            try meta.wrap(file.close(close(), in.write));
            try meta.wrap(file.close(close(), out.read));
        }
        fn serverLoop(allocator: *Allocator, node: *Node, dest_pathname: [:0]const u8, in: file.Pipe, out: file.Pipe) void {
            var hdr: Message.ServerHeader = undefined;
            var fd: [1]file.PollFd = .{.{ .fd = out.read, .expect = .{ .input = true } }};
            while (try meta.wrap(file.poll(poll(), &fd, builder_spec.options.timeout_milliseconds))) {
                try meta.wrap(file.readOne(read3(), out.read, &hdr));
                const buf: [*:0]u8 = @ptrFromInt(allocator.allocateRaw(hdr.bytes_len +% 1, 1));
                var len: usize = 0;
                while (len != hdr.bytes_len) {
                    len +%= try meta.wrap(file.read(read(), out.read, buf[len..hdr.bytes_len]));
                }
                buf[len] = 0;
                if (hdr.tag == .emit_bin_path) {
                    if (node.extra.results) |results| {
                        results.server = buf[0];
                    }
                    break try meta.wrap(installFromCache(node, dest_pathname, mem.terminate(buf + 1, 0)));
                }
                if (hdr.tag == .error_bundle) {
                    if (node.extra.results) |results| {
                        results.server = builder_spec.options.compiler_error_status;
                    }
                    break try meta.wrap(about.printErrors(allocator, node, buf));
                }
            } else if (fd[0].actual.hangup) {
                if (node.extra.results) |results| {
                    results.server = builder_spec.options.compiler_unexpected_status;
                }
            }
            if (node.extra.results) |results| {
                if (results.server != builder_spec.options.compiler_unexpected_status) {
                    try meta.wrap(file.write(write2(), in.write, update_exit_message[1..2]));
                }
            }
        }
        /// Despite having futexes (`proc.futex*`) this implementation opts for
        /// periodic scans with sleeping, because the task lock is not a perfect
        /// fit with futexes (u32). Extensions to `ThreadSafeSet` would permit.
        fn waitForNode(node: *Node, task: Task, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (builder_spec.logging.show_waiting_tasks) {
                if (node.extra.wait) |wait| {
                    if (wait.total >> 28 > wait.tick) {
                        about.writeWaitingOn(node, arena_index);
                        wait.tick +%= 1;
                    } else {
                        wait.total +%= builder_spec.options.sleep_nanoseconds;
                    }
                }
            }
            if (node.lock.get(task) == .blocking) {
                if (testDeps(node, task, .failed) or
                    testDeps(node, task, .cancelled))
                {
                    if (exchange(node, task, .blocking, .failed, arena_index)) {
                        exchangeDeps(node, task, .ready, .cancelled, arena_index);
                        exchangeDeps(node, task, .blocking, .cancelled, arena_index);
                    }
                    return true;
                }
                if (testDeps(node, task, .working) or
                    testDeps(node, task, .blocking))
                {
                    return true;
                }
                if (keepGoing(node)) {
                    if (!node.flags.is_group) {
                        assertExchange(node, task, .blocking, .working, arena_index);
                    } else {
                        assertExchange(node, task, .blocking, .finished, arena_index);
                    }
                } else {
                    assertExchange(node, task, .blocking, .failed, arena_index);
                }
            }
            return false;
        }
        fn exchange(node: *Node, task: Task, old_state: State, new_state: State, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builtin.is_safe);
            const ret: bool = node.lock.atomicExchange(task, old_state, new_state);
            if (ret) {
                node.sh.errors +%= @intFromBool(count_errors and new_state == .failed);
                if (builder_spec.logging.show_task_update) {
                    about.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (builder_spec.logging.show_task_update) {
                    about.noExchangeNotice(node, task, old_state, new_state, arena_index);
                }
            }
            return ret;
        }
        fn assertExchange(node: *Node, task: Task, old_state: State, new_state: State, arena_index: AddressSpace.Index) void {
            @setRuntimeSafety(builtin.is_safe);
            if (old_state == new_state) {
                return;
            }
            if (node.lock.atomicExchange(task, old_state, new_state)) {
                node.sh.errors +%= @intFromBool(count_errors and new_state == .failed);
                if (builder_spec.logging.show_task_update) {
                    about.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (builder_spec.logging.show_task_update) {
                    about.noExchangeNotice(node, task, old_state, new_state, arena_index);
                }
                proc.exitError(error.NoExchange, 2);
            }
        }
        fn testDeps(node: *const Node, task: Task, state: State) bool {
            @setRuntimeSafety(builtin.is_safe);
            const deps: []Node.Depn = node.getDepns();
            const nodes: []*Node = node.getNodes();
            if (!node.flags.is_group) {
                for (deps) |*dep| {
                    if (nodes[dep.node_idx] == node and dep.on_task == task) {
                        continue;
                    }
                    if (nodes[dep.node_idx].lock.get(dep.on_task) == state) {
                        return true;
                    }
                }
            } else {
                for (nodes[1..]) |sub_node| {
                    if (sub_node == node and sub_node.tasks.tag == task) {
                        continue;
                    }
                    if (sub_node.lock.get(task) == state) {
                        return true;
                    }
                }
            }
            return false;
        }
        fn exchangeDeps(node: *Node, task: Task, from: State, to: State, arena_index: AddressSpace.Index) void {
            @setRuntimeSafety(builtin.is_safe);
            const deps: []Node.Depn = node.getDepns();
            const nodes: []*Node = node.getNodes();
            for (deps) |*dep| {
                if (nodes[dep.node_idx] == node and dep.on_task == task) {
                    continue;
                }
                if (nodes[dep.node_idx].lock.get(dep.on_task) != from) {
                    continue;
                }
                if (!exchange(nodes[dep.node_idx], dep.on_task, from, to, arena_index)) {
                    return;
                }
            }
        }
        fn clock() time.ClockSpec {
            return .{ .errors = builder_spec.errors.clock };
        }
        fn sleep() time.SleepSpec {
            return .{ .errors = builder_spec.errors.sleep };
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
                .child = Message.ClientHeader,
            };
        }
        fn read() file.ReadSpec {
            return .{
                .errors = builder_spec.errors.read,
                .logging = builder_spec.logging.read,
                .return_type = u64,
            };
        }
        fn read2() file.Read2Spec {
            return .{
                .return_type = usize,
                .errors = builder_spec.errors.read,
                .logging = builder_spec.logging.read,
            };
        }
        fn read3() file.ReadSpec {
            return .{
                .child = Message.ServerHeader,
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
                .return_type = u32,
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
        fn dup3() file.Duplicate3Spec {
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
            };
        }
        fn perf_event_open() perf.PerfEventSpec {
            return .{
                .errors = builder_spec.errors.perf_event_open,
                .logging = builder_spec.logging.perf_event_open,
            };
        }
        fn create() file.CreateSpec {
            return .{
                .errors = builder_spec.errors.create,
                .logging = builder_spec.logging.create,
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
        fn getcwd() file.GetWorkingDirectorySpec {
            return .{
                .options = .{ .init_state = builder_spec.options.enable_current_working_directory },
                .errors = builder_spec.errors.getcwd,
                .logging = builder_spec.logging.getcwd,
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
        const count_errors: bool = builder_spec.options.max_error_count != null;
        fn keepGoing(node: *Node) bool {
            if (count_errors) {
                return node.sh.errors <= builder_spec.options.max_error_count.?;
            } else {
                return true;
            }
        }
        fn defined(fp: *const anyopaque) bool {
            return @intFromPtr(fp) >= load_prog_lb_addr and @intFromPtr(fp) < load_prog_up_addr;
        }
        fn status(stats: *Node.Results) bool {
            if (stats.server == builder_spec.options.compiler_error_status or
                stats.server == builder_spec.options.compiler_unexpected_status)
            {
                return false;
            }
            return stats.status == builder_spec.options.system_expected_status;
        }
        pub const FunctionPointers = struct {
            proc: struct {
                executeCommandClone: *const fn (
                    // Call parameters:
                    address_space: *AddressSpace,
                    thread_space: *ThreadSpace,
                    node: *Node,
                    task: Task,
                    arena_index: AddressSpace.Index,

                    // Callback
                    executeCommandThreaded: *const @TypeOf(executeCommandThreaded),

                    // On Stack:
                    addr: usize,
                    len: usize,
                ) void,
            },
            build: struct {
                formatWriteBuf: *const fn (
                    p_0: *tasks.BuildCommand,
                    p_1: []const u8,
                    p_2: []const types.Path,
                    p_3: [*]u8,
                ) usize,
                formatLength: *const fn (
                    p_0: *tasks.BuildCommand,
                    p_1: []const u8,
                    p_2: []const types.Path,
                ) usize,
                formatParseArgs: *const fn (
                    p_0: *tasks.BuildCommand,
                    p_1: *Allocator,
                    p_2: [][*:0]u8,
                ) void,
            },
            format: struct {
                formatWriteBuf: *const fn (
                    p_0: *tasks.FormatCommand,
                    p_1: []const u8,
                    p_2: types.Path,
                    p_3: [*]u8,
                ) usize,
                formatLength: *const fn (
                    p_0: *tasks.FormatCommand,
                    p_1: []const u8,
                    p_2: types.Path,
                ) usize,
                formatParseArgs: *const fn (
                    p_0: *tasks.FormatCommand,
                    p_1: *Allocator,
                    p_2: [][*:0]u8,
                ) void,
            },
            archive: struct {
                formatWriteBuf: *const fn (
                    p_0: *tasks.ArchiveCommand,
                    p_1: []const u8,
                    p_2: []const types.Path,
                    p_3: [*]u8,
                ) usize,
                formatLength: *const fn (
                    p_0: *tasks.ArchiveCommand,
                    p_1: []const u8,
                    p_2: []const types.Path,
                ) usize,
                formatParseArgs: *const fn (
                    p_0: *tasks.ArchiveCommand,
                    p_1: *Allocator,
                    p_2: [][*:0]u8,
                ) void,
            },
            objcopy: struct {
                formatWriteBuf: *const fn (
                    p_0: *tasks.ObjcopyCommand,
                    p_1: []const u8,
                    p_2: types.Path,
                    p_3: [*]u8,
                ) usize,
                formatLength: *const fn (
                    p_0: *tasks.ObjcopyCommand,
                    p_1: []const u8,
                    p_2: types.Path,
                ) usize,
                formatParseArgs: *const fn (
                    p_0: *tasks.ObjcopyCommand,
                    p_1: *Allocator,
                    p_2: [][*:0]u8,
                ) void,
            },
            about: struct {
                perf: struct {
                    openFds: *const @TypeOf(PerfEvents.openFds),
                    readResults: *const @TypeOf(PerfEvents.readResults),
                    writeResults: *const @TypeOf(PerfEvents.writeResults),
                },
                elf: struct {
                    writeBinary: *const @TypeOf(DynamicLoader.compare.writeBinary),
                    writeBinaryDifference: *const @TypeOf(DynamicLoader.compare.writeBinaryDifference),
                },
                generic: struct {
                    aboutTask: *const @TypeOf(about.aboutTask),
                    printErrors: *const @TypeOf(about.printErrors),
                    writeTaskDataConfig: *const @TypeOf(about.writeTaskDataConfig),
                },
            },
        };
        pub const about = struct {
            fn writeWaitingOn(node: *Node, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..tab.waiting_s.len].* = tab.waiting_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[tab.waiting_s.len..], node.name);
                if (builder_spec.logging.show_arena_index) {
                    ptr = about.writeArenaIndex(ptr, arena_index);
                }
                ptr[0] = '\n';
                ptr += 1;
                const nodes: []*Node = node.getNodes();
                for (node.getDepns()) |dep| {
                    ptr = writeNoExchangeTask(
                        ptr,
                        nodes[dep.node_idx],
                        dep.on_task,
                        nodes[dep.node_idx].lock.get(dep.on_task),
                        dep.on_state,
                        arena_index,
                    );
                    ptr[0] = '\n';
                    ptr += 1;
                }
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
            }
            fn exchangeNotice(node: *Node, task: Task, old: State, new: State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [32768]u8 = undefined;
                var ptr: [*]u8 = writeExchangeTask(&buf, node, task);
                ptr = writeFromTo(ptr, old, new);
                if (builder_spec.logging.show_arena_index) {
                    ptr = writeArenaIndex(ptr, arena_index);
                }
                ptr[0] = '\n';
                ptr += 1;
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
            }
            inline fn writeNoExchangeTask(buf: [*]u8, node: *Node, task: Task, old: State, new: State, arena_index: AddressSpace.Index) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const actual: State = node.lock.get(task);
                var ptr: [*]u8 = writeExchangeTask(buf, node, task);
                ptr[0] = '=';
                ptr += 1;
                ptr = fmt.strcpyEqu(ptr, @tagName(actual));
                const end: [*]u8 = writeFromTo(ptr, old, new);
                ptr[0] = '!';
                ptr = end;
                if (builder_spec.logging.show_arena_index) {
                    ptr = writeArenaIndex(ptr, arena_index);
                }
                return ptr;
            }
            fn noExchangeNotice(node: *Node, task: Task, old: State, new: State, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builtin.is_safe);
                if (old != .finished) {
                    var buf: [32768]u8 = undefined;
                    var ptr: [*]u8 = writeNoExchangeTask(&buf, node, task, old, new, arena_index);
                    ptr[0] = '\n';
                    ptr += 1;
                    debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
                }
            }
            fn writeArenaIndex(buf: [*]u8, arena_index: AddressSpace.Index) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (arena_index != max_thread_count) {
                    var ud64: fmt.Ud64 = .{ .value = arena_index };
                    buf[0..2].* = " [".*;
                    const len: usize = ud64.formatWriteBuf(buf + 2);
                    buf[2 +% len] = ']';
                    return buf + 3 + len;
                }
                return buf;
            }
            fn writeTask(buf: [*]u8, node: *Node, task: Task, arena_index: AddressSpace.Index) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!builder_spec.logging.show_special and
                    node.flags.is_special)
                {
                    return buf;
                }
                var ptr: [*]u8 = buf;
                const about_s: fmt.AboutSrc = switch (task) {
                    else => if (node.tasks.tag == .build) tab.build_run_s else tab.exec_s,
                    .archive => tab.ar_s,
                    .format => tab.fmt_s,
                    .build => if (node.flags.have_task_data) switch (node.tasks.cmd.build.kind) {
                        .exe => tab.build_exe_s,
                        .obj => tab.build_obj_s,
                        .lib => tab.build_lib_s,
                    } else tab.build_lib_s,
                };
                const width: usize = fmt.aboutCentre(about_s);
                if (node.extra.results) |results| {
                    const signal: sys.SignalCode = @enumFromInt(results.signal);
                    ptr[0..about_s.len].* = about_s.*;
                    ptr += about_s.len;
                    ptr += node.formatWriteNameFull('.', ptr);
                    if (task == .build) {
                        if (builder_spec.logging.show_output_destination and
                            results.server == builder_spec.options.compiler_cache_hit_status or
                            results.server == builder_spec.options.compiler_expected_status)
                        {
                            ptr[0..4].* = " => ".*;
                            ptr += 4;
                            ptr += node.getPaths()[0].formatWriteBufDisplay(ptr);
                        }
                        if (node.flags.have_task_data) {
                            ptr[0..2].* = ", ".*;
                            ptr += 2;
                            switch (node.tasks.cmd.build.mode orelse .Debug) {
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
                        }
                    }
                    ptr[0..7].* = ", exit=".*;
                    ptr += 7;
                    if (task == .build) {
                        ptr[0] = '[';
                        ptr += 1;
                        switch (results.server) {
                            builder_spec.options.compiler_expected_status => {
                                ptr[0..7].* = "updated".*;
                                ptr += 7;
                            },
                            builder_spec.options.compiler_cache_hit_status => {
                                ptr[0..6].* = "cached".*;
                                ptr += 6;
                            },
                            builder_spec.options.compiler_error_status => {
                                ptr[0..6].* = "failed".*;
                                ptr += 6;
                            },
                            else => {
                                ptr[0..7].* = "unknown".*;
                                ptr += 7;
                            },
                        }
                        if (results.status != 0) {
                            ptr[0] = ',';
                            ptr += 1;
                            ptr = fmt.writeUd64(ptr, results.status);
                        }
                        if (results.signal != builder_spec.options.system_expected_status) {
                            ptr[0..4].* = ",SIG".*;
                            ptr += 4;
                            ptr = fmt.strcpyEqu(ptr, @tagName(signal));
                        }
                        ptr[0] = ']';
                        ptr += 1;
                    } else {
                        if (results.signal != 0) {
                            ptr[0] = '[';
                            ptr += 1;
                            ptr = fmt.writeUd64(ptr, results.status);
                            ptr[0..4].* = ",SIG".*;
                            ptr += 4;
                            ptr = fmt.strcpyEqu(ptr, @tagName(signal));
                            ptr[0] = ']';
                            ptr += 1;
                        } else {
                            ptr = fmt.writeUd64(ptr, results.status);
                        }
                    }
                    if (!node.flags.want_binary_analysis) {
                        if (have_size and
                            results.server == builder_spec.options.compiler_cache_hit_status or
                            results.server == builder_spec.options.compiler_expected_status)
                        {
                            if (node.getFile(.{ .tag = .output_generic })) |output| {
                                if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                                    ptr[0..2].* = ", ".*;
                                    ptr += 2;
                                    ptr += fmt.bloatDiff(output.st.size, cached.st.size).formatWriteBuf(ptr);
                                }
                            }
                        }
                    }
                    if (!node.flags.want_perf_events) {
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                        ptr = writeWallTime(ptr, results.time.sec, results.time.nsec);
                    }
                    if (builder_spec.logging.show_arena_index) {
                        ptr = writeArenaIndex(ptr, arena_index);
                    }
                    ptr[0] = '\n';
                    ptr += 1;
                    if (have_size and task == .build and
                        node.flags.want_binary_analysis and
                        node.flags.is_primary)
                    {
                        ptr = writeFileSizeStats(ptr, node, width);
                    }
                    if (have_perf and
                        node.flags.want_perf_events and
                        node.flags.is_primary)
                    {
                        ptr = writeTimingStats(node, results, @max(width, 4), ptr);
                    }
                }
                return ptr;
            }
            pub fn aboutTask(allocator: *Allocator, node: *Node, task: Task, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builtin.is_safe);
                if (have_lazy and builtin.output_mode == .Exe) {
                    if (defined(node.sh.fp.about.generic.aboutTask)) {
                        node.sh.fp.about.generic.aboutTask(allocator, node, task, arena_index);
                    }
                    return;
                }
                const save: usize = allocator.save();
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
                const ptr: [*]u8 = writeTask(buf, node, task, arena_index);
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(buf)]);
                allocator.restore(save);
            }
            fn writeTimingStats(node: *Node, results: *Node.Results, width: usize, buf: [*]u8) [*]u8 {
                var ptr: [*]u8 = buf;
                ptr += fmt.writeSideBarSubHeading(buf, width, "perf");
                ptr = writeWallTime(ptr, results.time.sec, results.time.nsec);
                ptr[0] = '\n';
                ptr += 1;
                if (node.extra.perf_events) |perf_events| {
                    ptr = PerfEvents.writeResults(perf_events, width, ptr);
                }
                return ptr;
            }
            fn writeFileSizeStats(buf: [*]u8, node: *Node, width: usize) [*]u8 {
                var ptr: [*]u8 = buf + fmt.writeSideBarSubHeading(buf, width, "size");
                if (node.getFile(.{ .tag = .output_generic })) |output| {
                    if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                        ptr += fmt.bloatDiff(output.st.size, cached.st.size).formatWriteBuf(ptr);
                        ptr[0] = '\n';
                        ptr += 1;
                    }
                } else if (node.getFile(.{ .tag = .output_generic })) |output| {
                    ptr += fmt.bytes(output.st.size).formatWriteBuf(ptr);
                    ptr[0] = '\n';
                    ptr += 1;
                    return ptr + 1;
                }
                if (node.extra.info_after) |after| {
                    if (node.extra.info_before) |before| {
                        ptr = DynamicLoader.compare.writeBinaryDifference(ptr, before, after, width);
                    } else {
                        ptr = DynamicLoader.compare.writeBinary(ptr, after, width);
                    }
                }
                return ptr;
            }
            pub fn aboutBaseMemoryUsageNotice(allocator: *Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                ptr[0..tab.mem_s.len].* = tab.mem_s.*;
                ptr += tab.mem_s.len;
                ptr += fmt.ud64(allocator.next -% allocator.start).formatWriteBuf(ptr);
                ptr[0..7].* = " bytes\n".*;
                ptr += 7;
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
            }
            pub fn commandLineNotice(node: *Node) void {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return commandLineNotice(node.groupNode());
                }
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                const cmd_args: [][*:0]u8 = node.getCmdArgs();
                if (cmd_args.len != 0) {
                    ptr[0..tab.cmd_args_s.len].* = tab.cmd_args_s.*;
                    ptr += tab.cmd_args_s.len;
                    ptr = file.about.writeArgs(ptr, &.{}, cmd_args);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                const run_args: [][*:0]u8 = node.getRunArgs();
                if (run_args.len != 0) {
                    ptr[0..tab.run_args_s.len].* = tab.run_args_s.*;
                    ptr += tab.run_args_s.len;
                    ptr = file.about.writeArgs(ptr, &.{}, run_args);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
            }
            const ColumnWidth = extern union {
                vec: @Vector(7, u16),
                cols: extern struct {
                    name: u16 = 0,
                    file: u16 = 0,
                    path: u16 = 0,
                    size: u16 = 0,
                    stat: u16 = 0,
                    descr: u16 = 0,
                    key_tag: u16 = 0,
                },
            };
            pub fn writeAndWalk(allocator: *Allocator, node: *Node) void {
                @setRuntimeSafety(false);
                const save: usize = allocator.save();
                var buf1: [4096]u8 = undefined;
                var width: ColumnWidth align(64) = .{ .cols = .{} };
                writeAndWalkColumnWidths(0, node, &width);
                width.vec +%= @splat(5);
                width.vec &= @splat(~@as(u16, 3));
                width.cols.name = @max(width.cols.name, width.cols.file);
                width.cols.file = width.cols.name;
                const max_len: usize = node.name.len +% 1 +% lengthAndWalkInternal(0, node, &width);
                const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                var ptr0: [*]u8 = fmt.strcpyEqu(buf0, node.name);
                ptr0[0] = '\n';
                ptr0 += 1;
                ptr0 = writeAndWalkInternal(ptr0, &buf1, 0, node, &width);
                fmt.print(ptr0, buf0);
                allocator.restore(save);
            }
            const bar = struct {
                const spc_bs: [:0]const u8 = "  ";
                const bar_ws: [:0]const u8 = "│ ";
                const next_arrow_ws: [:0]const u8 = "├";
                const last_arrow_ws: [:0]const u8 = "└";
                const next_br_arrow_ws: [:0]const u8 = "├┬ ";
                const last_br_arrow_ws: [:0]const u8 = "└┬ ";
            };
            fn writeAndWalkColumnWidths(len1: usize, node: *const Node, width: *ColumnWidth) void {
                @setRuntimeSafety(false);
                var itr: Node.Iterator = Node.Iterator.init(node);
                var buf: [4096]u8 = undefined;
                const files: []types.File = node.getFiles();
                for (files) |*fs| {
                    width.cols.file = @intCast(@max(width.cols.file, len1 +% 4 +% @tagName(fs.key.tag).len));
                    if (node.getFilePath(fs)) |path| {
                        width.cols.path = @intCast(@max(width.cols.path, path.formatWriteBufDisplay(&buf)));
                    }
                }
                while (itr.next()) |next_node| {
                    writeAndWalkColumnWidths(len1 +% 2, next_node, width);
                    width.cols.name = @intCast(@max(width.cols.name, len1 +% 4 +% next_node.name.len));
                    width.cols.descr = @intCast(@max(width.cols.descr, next_node.descr.len));
                }
            }
            fn lengthAndWalkInternal(len1: usize, node: *Node, width: *ColumnWidth) usize {
                @setRuntimeSafety(false);
                var len: usize = 0;
                for (node.getFiles()) |*fs| {
                    len +%= len1;
                    len +%= 2;
                    if (!fs.key.flags.is_cached) {
                        len +%= (width.cols.file +% width.cols.path) -% (len1 +% 4);
                    }
                    len +%= 1;
                }
                var itr: Node.Iterator = Node.Iterator.init(node);
                while (itr.next()) |next_node| {
                    len +%= width.cols.name +% next_node.descr.len;
                    len +%= lengthAndWalkInternal(len1 +% 2, next_node, width);
                    len +%= 1;
                }
                return len;
            }
            fn writeAndWalkInternal(buf0: [*]u8, buf1: [*]u8, len1: usize, node: *Node, width: *ColumnWidth) [*]u8 {
                @setRuntimeSafety(false);
                var itr: Node.Iterator = Node.Iterator.init(node);
                var ptr1: [*]u8 = buf1 + len1;
                var ptr0: [*]u8 = buf0;
                for (node.getFiles()) |*fs| {
                    ptr0 = fmt.strcpyEqu(ptr0, buf1[0..len1]);
                    ptr0[0..2].* = if (itr.idx == itr.max_idx) "  ".* else "| ".*;
                    ptr0 += 2;
                    if (node.getFilePath(fs)) |path| {
                        ptr0 = fmt.strsetEqu(ptr0, ' ', width.cols.file -% (len1 +% 4 +% @tagName(fs.key.tag).len));
                        ptr0 = fmt.strcpyEqu(ptr0, @tagName(fs.key.tag));
                        ptr0[0..2].* = ": ".*;
                        ptr0 += 2;
                        ptr0 += path.formatWriteBufDisplay(ptr0);
                    }
                    ptr0[0] = '\n';
                    ptr0 += 1;
                }
                while (itr.next()) |next_node| {
                    ptr1[0..2].* = if (itr.idx == itr.max_idx) "  ".* else "| ".*;
                    ptr0 = fmt.strcpyEqu(ptr0, buf1[0..len1]);
                    ptr0 = fmt.strcpyEqu(ptr0, if (itr.idx == itr.max_idx) "`-" else "|-");
                    ptr0 = fmt.strcpyEqu(ptr0, if (1 == itr.max_idx) "> " else "+ ");
                    ptr0 = fmt.strcpyEqu(ptr0, next_node.name);
                    ptr0 = fmt.strsetEqu(ptr0, ' ', width.cols.name -% (len1 +% 6 +% next_node.name.len));
                    ptr0[0..2].* = ": ".*;
                    ptr0 = fmt.strcpyEqu(ptr0 + 2, next_node.descr);
                    ptr0[0] = '\n';
                    ptr0 = writeAndWalkInternal(ptr0 + 1, buf1, len1 +% 2, next_node, width);
                }
                return ptr0;
            }
            pub fn printErrors(allocator: *Allocator, node: *Node, msg: [*:0]u8) void {
                @setRuntimeSafety(builtin.is_safe);
                if (builder_spec.options.eager_compile_errors) {
                    if (builder_spec.options.trace_compile_errors) {
                        return trace.printCompileErrorsTrace(allocator, &builtin.trace, msg);
                    } else {
                        return trace.printCompileErrorsStandard(allocator, msg);
                    }
                }
                if (have_lazy and builtin.output_mode == .Exe) {
                    return if (defined(node.sh.fp.about.generic.printErrors)) {
                        node.sh.fp.about.generic.printErrors(allocator, node, msg);
                    };
                }
                if (builder_spec.options.trace_compile_errors) {
                    return trace.printCompileErrorsTrace(allocator, &builtin.trace, msg);
                } else {
                    return trace.printCompileErrorsStandard(allocator, msg);
                }
            }
            fn aboutPhase(node: *Node) fmt.AboutSrc {
                @setRuntimeSafety(builtin.is_safe);
                switch (node.sh.mode) {
                    .Init => return tab.init_s,
                    .Main => return tab.main_s,
                    .Command => return tab.cmdline_s,
                    .Exec => return tab.exec_s,
                    .Regen => return tab.regen_s,
                }
            }
            const SpecTag = meta.TagFromList(meta.fieldNames(BuilderSpec.Options));
            const FlagTag = meta.TagFromBitOffsets(Node.Flags);
            const About = union(enum) {
                add_cmd_arg,
                add_run_arg,
                add_file,
                add_builder_decl,
                add_build_context_decls,
                add_define_decls,
                enable_flag,
                disable_flag,
                simple: []const u8,
                implicit_depn: *Node,
                allocate: enum { wait, results, perf_events },
            };
            fn aboutNode(node: *Node, by_spec: ?SpecTag, by_flag: ?FlagTag, event: About) void {
                @setRuntimeSafety(false);
                const about_s: fmt.AboutSrc = switch (node.sh.mode) {
                    .Init => tab.init_s,
                    .Main => tab.main_s,
                    .Command => tab.cmdline_s,
                    .Exec => tab.exec_s,
                    .Regen => tab.regen_s,
                };
                var buf: [4096]u8 = undefined;
                buf[0..about_s.len].* = about_s.*;
                var ptr: [*]u8 = buf[about_s.len..];
                ptr += node.formatWriteNameFull('.', ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (by_spec) |which| {
                    ptr[0..5].* = "spec.".*;
                    ptr += 5;
                    ptr = fmt.strcpyEqu(ptr, @tagName(which));
                    ptr[0..4].* = " => ".*;
                    ptr += 4;
                }
                if (by_flag) |which| {
                    ptr[0..5].* = "flag.".*;
                    ptr += 5;
                    ptr = fmt.strcpyEqu(ptr, @tagName(which));
                    ptr[0..4].* = " => ".*;
                    ptr += 4;
                }
                switch (event) {
                    .add_cmd_arg => {
                        const cmd_args: [][*:0]u8 = node.getCmdArgs();
                        const idx: usize = cmd_args.len -% 1;
                        ptr[0..9].* = "run_args[".*;
                        ptr += 9;
                        ptr = fmt.writeUd64(ptr, idx);
                        ptr[0..2].* = "]=".*;
                        ptr += 2;
                        ptr = fmt.strcpyEqu(ptr, mem.terminate(cmd_args[idx], 0));
                    },
                    .add_run_arg => {
                        const run_args: [][*:0]u8 = node.getRunArgs();
                        const idx: usize = run_args.len -% 1;
                        ptr[0..9].* = "run_args[".*;
                        ptr += 9;
                        ptr = fmt.writeUd64(ptr, idx);
                        ptr[0..2].* = "]=".*;
                        ptr += 2;
                        ptr = fmt.strcpyEqu(ptr, mem.terminate(run_args[idx], 0));
                    },
                    .add_file => {
                        const files = node.getFiles();
                        const idx: usize = files.len -% 1;
                        ptr = fmt.strcpyEqu(ptr, @tagName(files[idx].key.tag));
                        ptr[0..3].* = ", [".*;
                        ptr += 3;
                        ptr = fmt.writeUd64(ptr, idx);
                        ptr[0..2].* = "] ".*;
                        ptr += 2;
                        if (node.getFilePath(&files[idx])) |path| {
                            ptr += path.formatWriteBufDisplay(ptr);
                        }
                    },
                    .add_builder_decl => {
                        ptr[0..42].* = "added `Builder` configuration declarations".*;
                        ptr += 42;
                    },
                    .add_build_context_decls => {
                        ptr[0..43].* = "added args[1..5] configuration declarations".*;
                        ptr += 43;
                    },
                    .add_define_decls => {
                        ptr[0..40].* = "added builtin configuration declarations".*;
                        ptr += 40;
                    },
                    .enable_flag => {
                        ptr[0..7].* = "enabled".*;
                        ptr += 7;
                    },
                    .disable_flag => {
                        ptr[0..8].* = "disabled".*;
                        ptr += 8;
                    },
                    .allocate => |field| {
                        const addr: usize = switch (field) {
                            .wait => @intFromPtr(node.extra.wait.?),
                            .results => @intFromPtr(node.extra.results.?),
                            .perf_events => @intFromPtr(node.extra.perf_events.?),
                        };
                        ptr[0..6].* = "extra.".*;
                        ptr += 6;
                        ptr = fmt.strcpyEqu(ptr, @tagName(field));
                        ptr[0] = '=';
                        ptr += 1;
                        ptr += fmt.ux64(addr).formatWriteBuf(ptr);
                    },
                    .simple => |message| {
                        ptr = fmt.strcpyEqu(ptr, message);
                    },
                    .implicit_depn => |extn| {
                        ptr[0..24].* = "execute extension task `".*;
                        ptr += 24;
                        ptr = fmt.strcpyEqu(ptr, extn.name);
                        ptr[0] = '`';
                        ptr += 1;
                    },
                }
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
            }
            pub fn writeTaskDataConfig(node: *Node, buf: [*]u8) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (have_lazy and
                    builtin.output_mode == .Exe)
                {
                    if (defined(node.sh.fp.about.generic.writeTaskDataConfig)) {
                        return node.sh.fp.about.generic.writeTaskDataConfig(node, buf);
                    }
                    return buf;
                }
                buf[0..31].* = "pub const dependencies=struct{\n".*;
                var ptr: [*]u8 = buf + 31;
                if (node.tasks.tag == .build) {
                    if (node.tasks.cmd.build.dependencies) |dependencies| {
                        for (dependencies) |dependency| {
                            ptr[0..12].* = "pub const @\"".*;
                            ptr += 12;
                            ptr = fmt.strcpyEqu(ptr, dependency.name);
                            ptr[0..16].* = "\":?[:0]const u8=".*;
                            ptr += 16;
                            if (dependency.import.len != 0) {
                                ptr[0] = '"';
                                ptr += 1;
                                ptr = fmt.strcpyEqu(ptr, dependency.import);
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
                    if (node.tasks.cmd.build.modules) |modules| {
                        for (modules) |module| {
                            ptr[0..12].* = "pub const @\"".*;
                            ptr += 12;
                            ptr = fmt.strcpyEqu(ptr, module.name);
                            ptr[0..15].* = "\":[:0]const u8=".*;
                            ptr += 15;
                            ptr[0] = '"';
                            ptr += 1;
                            ptr = fmt.strcpyEqu(ptr, module.path);
                            ptr[0..3].* = "\";\n".*;
                            ptr += 3;
                        }
                    }
                }
                for (&[3]types.BinaryOutput{ .obj, .lib, .exe }) |out| {
                    ptr[0..13].* = "};\npub const ".*;
                    ptr += 13;
                    ptr = fmt.strcpyEqu(ptr, switch (out) {
                        .obj => "compile",
                        .lib => "dynamic",
                        .exe => "executable",
                    });
                    ptr[0..52].* = "_units=[_]struct{@Type(.EnumLiteral),[:0]const u8}{\n".*;
                    ptr += 52;
                    for (node.getDepns()) |dep| {
                        if (dep.on_task == .build and
                            node.getNodes()[dep.node_idx] != node and
                            node.getNodes()[dep.node_idx].flags.have_task_data and
                            node.getNodes()[dep.node_idx].tasks.cmd.build.kind == out)
                        {
                            ptr[0..4].* = ".{.@".*;
                            ptr += 4;
                            ptr += fmt.stringLiteral(node.getNodes()[dep.node_idx].name).formatWriteBuf(ptr);
                            ptr[0..2].* = ",\"".*;
                            ptr += 2;
                            ptr += node.getNodes()[dep.node_idx].getPaths()[0].formatWriteBufLiteral(ptr);
                            ptr[0..4].* = "\"},\n".*;
                            ptr += 4;
                        }
                    }
                }
                ptr[0..3].* = "};\n".*;
                ptr += 3;
                return ptr;
            }
            fn writeFromTo(buf: [*]u8, old: State, new: State) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                buf[0..2].* = "={".*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf + 2, @tagName(old));
                ptr[0..2].* = "=>".*;
                ptr += 2;
                ptr = fmt.strcpyEqu(ptr, @tagName(new));
                ptr[0] = '}';
                ptr += 1;
                return ptr;
            }
            fn writeExchangeTask(buf: [*]u8, node: *Node, task: Task) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const about_s: fmt.AboutSrc = switch (node.sh.mode) {
                    .Init => tab.init_s,
                    .Main => tab.main_s,
                    .Command => tab.cmdline_s,
                    .Exec => tab.exec_s,
                    .Regen => tab.regen_s,
                };
                buf[0..about_s.len].* = about_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf + about_s.len, node.name);
                ptr[0] = '.';
                ptr += 1;
                ptr = fmt.strcpyEqu(ptr, @tagName(task));
                return ptr;
            }
        };
    };
    return T;
}
fn writeWallTime(buf: [*]u8, sec: usize, nsec: usize) [*]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var ud64: fmt.Ud64 = .{ .value = sec };
    var ptr: [*]u8 = buf + ud64.formatWriteBuf(buf);
    ptr[0..4].* = ".000".*;
    ptr += 1;
    ud64.value = nsec;
    const figs: usize = fmt.length(usize, nsec, 10);
    ptr += (9 -% figs);
    _ = ud64.formatWriteBuf(ptr);
    ptr += (figs -% 9);
    ptr += 3;
    ptr[0] = 's';
    ptr += 1;
    return ptr;
}
pub const Message = struct {
    pub const ClientHeader = extern struct {
        tag: Tag,
        bytes_len: u32,
        pub const Tag = enum(u32) {
            exit,
            update,
            run,
            hot_update,
            query_test_metadata,
            run_test,
        };
    };
    pub const ServerHeader = extern struct {
        tag: Tag,
        bytes_len: u32,
        pub const Tag = enum(u32) {
            zig_version,
            error_bundle,
            progress,
            emit_bin_path,
            test_metadata,
            test_results,
        };
    };
};
pub fn duplicate(allocator: *Allocator, values: []const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    if (@intFromPtr(values.ptr) < 0x40000000) {
        return @constCast(values.ptr)[0..values.len :0];
    }
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(values.len +% 1, 1));
    @memcpy(buf, values);
    buf[values.len] = 0;
    return buf[0..values.len :0];
}
fn makeCommandName(allocator: *Allocator, root: [:0]const u8) [:0]const u8 {
    @setRuntimeSafety(builtin.is_safe);
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(root.len +% 1, 1));
    @memcpy(buf, root);
    buf[root.len] = 0;
    var idx: usize = 0;
    while (idx != root.len and buf[idx] != 0x2e) : (idx +%= 1) {
        if (buf[idx] == 0x2f) {
            buf[idx] = 0x2d;
        }
    }
    buf[idx] = 0;
    return buf[0..idx :0];
}
pub fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var len: usize = 0;
    for (values) |value| {
        len +%= value.len;
    }
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len +% 1, 1));
    var idx: usize = 0;
    for (values) |value| {
        @memcpy(buf + idx, value);
        idx +%= value.len;
    }
    buf[len] = 0;
    return buf[0..len :0];
}
pub fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var count: usize = 0;
    for (args) |value| {
        count +%= @intFromBool(value == 0);
    }
    const buf: [*]usize = @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 8));
    var len: usize = 0;
    var idx: usize = 0;
    var pos: usize = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0 or
            args[idx] == '\n')
        {
            buf[len] = @intFromPtr(args.ptr + pos);
            len +%= 1;
            pos = idx +% 1;
        }
    }
    buf[len] = 0;
    return @ptrCast(buf[0..len]);
}
pub const omni_lock = .{ .bytes = .{ .null, .ready, .ready, .ready, .ready, .ready, .null, .null } };
pub const obj_lock = .{ .bytes = .{ .null, .null, .null, .ready, .null, .null, .null, .null } };
pub const exe_lock = .{ .bytes = .{ .null, .null, .null, .ready, .ready, .null, .null, .null } };
pub const run_lock = .{ .bytes = .{ .null, .null, .null, .null, .ready, .null, .null, .null } };
pub const format_lock = .{ .bytes = .{ .null, .null, .ready, .null, .null, .null, .null, .null } };
pub const fetch_lock = .{ .bytes = .{ .null, .null, .null, .null, .null, .null, .null, .ready } };
pub const archive_lock = .{ .bytes = .{ .null, .null, .null, .null, .null, .ready, .null, .null } };
pub const objcopy_lock = .{ .bytes = .{ .null, .null, .null, .null, .null, .null, .ready, .null } };
const tab = .{
    .ar_s = fmt.about("ar"),
    .add_s = fmt.about("add"),
    .mem_s = fmt.about("mem"),
    .fmt_s = fmt.about("fmt"),
    .perf_s = fmt.about("perf"),
    .size_s = fmt.about("size"),
    .state_s = fmt.about("state"),
    .init_s = fmt.about("init-0"),
    .main_s = fmt.about("main-1"),
    .cmdline_s = fmt.about("cmdline-2"),
    .exec_s = fmt.about("exec-3"),
    .regen_s = fmt.about("regen-4"),
    .unknown_s = fmt.about("unknown"),
    .waiting_s = fmt.about("waiting"),
    .cmd_args_s = fmt.about("cmd-args"),
    .run_args_s = fmt.about("run-args"),
    .build_run_s = fmt.about("build-run"),
    .build_exe_s = fmt.about("build-exe"),
    .build_obj_s = fmt.about("build-obj"),
    .build_lib_s = fmt.about("build-lib"),
    .state_1_s = fmt.about("state-fault"),
};
pub const spec = struct {
    pub const default = .{
        .errors = spec.errors.noexcept,
        .logging = spec.logging.default,
    };
    pub const errors = struct {
        pub fn noexcept() BuilderSpec.Errors {
            return .{
                .fork = .{},
                .write = .{},
                .read = .{},
                .mknod = .{},
                .dup3 = .{},
                .pipe = .{},
                .execve = .{},
                .waitpid = .{},
                .path = .{},
                .map = .{},
                .unmap = .{},
                .clock = .{},
                .sleep = .{},
                .create = .{},
                .mkdir = .{},
                .open = .{},
                .close = .{},
                .poll = .{},
                .stat = .{},
                .unlink = .{},
                .link = .{},
                .seek = .{},
                .getcwd = .{},
                .perf_event_open = .{},
            };
        }
        pub fn kill() BuilderSpec.Errors {
            return .{
                .write = .{ .abort = file.spec.write.errors.all },
                .read = .{ .abort = file.spec.read.errors.all },
                .mknod = .{ .abort = file.spec.mknod.errors.all },
                .dup3 = .{ .abort = file.spec.dup.errors.all },
                .pipe = .{ .abort = file.spec.pipe.errors.all },
                .fork = .{ .abort = file.spec.fork.errors.all },
                .execve = .{ .abort = file.spec.execve.errors.all },
                .waitpid = .{ .abort = proc.spec.wait.errors.all },
                .path = .{ .abort = file.spec.open.errors.all },
                .map = .{ .abort = mem.spec.mmap.errors.all },
                .stat = .{ .abort = file.spec.stat.errors.all_noent },
                .unmap = .{ .abort = mem.spec.munmap.errors.all },
                .clock = .{ .abort = file.spec.clock_gettime.errors.all },
                .sleep = .{ .abort = time.spec.nanosleep.errors.all },
                .create = .{ .abort = file.spec.open.errors.all },
                .mkdir = .{ .abort = file.spec.mkdir.errors.noexcl },
                .poll = .{ .abort = file.spec.poll.errors.all },
                .open = .{ .abort = file.spec.open.errors.all },
                .close = .{ .abort = file.spec.close.errors.all },
                .unlink = .{ .abort = file.spec.unlink.errors.all_noent },
                .link = .{ .abort = file.spec.link.errors.all },
                .seek = .{ .abort = file.spec.seek.errors.all },
                .getcwd = .{ .abort = file.spec.getcwd.errors.all },
                .perf_event_open = .{ .abort = perf.spec.perf_event_open.errors.all },
            };
        }
        pub fn zen() BuilderSpec.Errors {
            return .{
                .write = .{ .abort = file.spec.write.errors.all },
                .read = .{ .abort = file.spec.read.errors.all },
                .mknod = .{ .throw = file.spec.mknod.errors.all },
                .dup3 = .{ .throw = file.spec.dup.errors.all },
                .pipe = .{ .throw = file.spec.pipe.errors.all },
                .fork = .{ .throw = file.spec.fork.errors.all },
                .execve = .{ .throw = file.spec.execve.errors.all },
                .waitpid = .{ .throw = proc.spec.wait.errors.all },
                .path = .{ .throw = file.spec.open.errors.all },
                .map = .{ .throw = mem.spec.mmap.errors.all },
                .stat = .{ .throw = file.spec.stat.errors.all },
                .unmap = .{ .throw = mem.spec.munmap.errors.all },
                .clock = .{ .throw = file.spec.clock_gettime.errors.all },
                .sleep = .{ .throw = time.spec.nanosleep.errors.all },
                .create = .{ .throw = file.spec.open.errors.all },
                .mkdir = .{ .throw = file.spec.mkdir.errors.noexcl },
                .poll = .{ .throw = file.spec.poll.errors.all },
                .open = .{ .throw = file.spec.open.errors.all },
                .seek = .{ .throw = file.spec.seek.errors.all },
                .close = .{ .throw = file.spec.close.errors.all },
                .getcwd = .{ .throw = file.spec.getcwd.errors.all },
                .unlink = .{ .throw = file.spec.unlink.errors.all },
                .perf_event_open = .{ .throw = perf.spec.perf_event_open.errors.all },
            };
        }
    };
    pub const logging = struct {
        pub const transcript_only = blk: {
            var tmp = spec.logging.silent;
            tmp.show_task_creation = true;
            tmp.show_task_update = true;
            tmp.show_user_input = true;
            tmp.show_task_prep = true;
            tmp.show_arena_index = true;
            tmp.show_base_memory_usage = true;
            tmp.show_waiting_tasks = true;
            break :blk tmp;
        };
        pub const default: BuilderSpec.Logging = .{
            .write = .{},
            .read = .{},
            .mknod = .{},
            .dup3 = .{},
            .pipe = .{},
            .fork = .{},
            .execve = .{},
            .waitpid = .{},
            .path = .{},
            .map = .{},
            .stat = .{},
            .unmap = .{},
            .create = .{},
            .mkdir = .{},
            .poll = .{},
            .open = .{},
            .close = .{},
            .unlink = .{},
            .getcwd = .{},
        };
        pub const verbose: BuilderSpec.Logging = builtin.all(BuilderSpec.Logging);
        pub const silent: BuilderSpec.Logging = builtin.zero(BuilderSpec.Logging);
    };
};
// Error checks:
//  Group node has command arguments entering `processCommands`.
pub fn GenericCommand(comptime Command: type) type {
    const T = struct {
        const render_spec: fmt.RenderSpec = .{
            .infer_type_names = true,
            .forward = true,
        };
        //pub fn renderWriteBuf(cmd: *const Command, buf: [*]u8) callconv(.C) usize {
        //    return fmt.render(render_spec, cmd.*).formatWriteBuf(buf);
        //}
        //const gen = @import("./gen.zig");
        //const Editor = gen.StructEditor(render_spec, Command);
        //pub const fieldEditDistance = Editor.fieldEditDistance;
        //pub const writeFieldEditDistance = Editor.writeFieldEditDistance;
        //pub const indexOfCommonLeastDifference = Editor.indexOfCommonLeastDifference;
        pub const formatWriteBuf = Command.formatWriteBuf;
        pub const formatLength = Command.formatLength;
        pub const formatParseArgs = Command.formatParseArgs;
    };
    return T;
}
