const mem = @import("mem.zig");
const fmt = @import("fmt.zig");
const sys = @import("sys.zig");
const elf = @import("elf.zig");
const file = @import("file.zig");
const perf = @import("perf.zig");
const bits = @import("bits.zig");
const meta = @import("meta.zig");
const proc = @import("proc.zig");
const time = @import("time.zig");
const trace = @import("trace.zig");
const debug = @import("debug.zig");
const cache = @import("cache.zig");
const builtin = @import("builtin.zig");
const testing = @import("testing.zig");
pub const tasks = @import("build/tasks.zig");
pub const types = @import("build/types.zig");
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
    /// zig build [task] [flags] <primary_command> [cmd_args] (split) [run_args]
    ///          (a)    (b)     (c)               (d)        (e)     (f)
    ///
    /// a) Which task to execute for the primary command. Overriding task default.
    ///    Examples:
    ///     `zig build run main`        ;; Runs the output binary produced by
    ///                                    task `main`.
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
    /// e) Default is `++`. Command line argument used to split command and run
    ///    arguments. (`--` is already taken by `-cflags` to stop parsing commands).
    ///
    /// f) For tasks with binary executable output, set run command line for use
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
        max_arena_aligned_bytes: usize = 8 * 1024 * 1024 * 1024,
        /// Bytes allowed per thread stack (default=8MiB)
        max_stack_aligned_bytes: usize = 8 * 1024 * 1024,
        /// Bytes allowed for shallow cache check file buffers (default=1MiB).
        max_cache_path_aligned_bytes: usize = 1024 * 1024,
        /// Bytes allowed for shallow cache check file buffers (default=1GiB).
        max_cache_file_aligned_bytes: usize = 1024 * 1024 * 1024,
        /// Bytes allowed for dynamic metadata sections (default=1TiB)
        max_load_meta_aligned_bytes: usize = 1024 * 1024 * 1024 * 1024,
        /// Bytes allowed for dynamic libraries program segments (default=1TiB)
        max_load_prog_aligned_bytes: usize = 1024 * 1024 * 1024 * 1024,
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
        /// Maximum time between dependency scans.
        timeout: time.TimeSpec = .{ .sec = 0, .nsec = 5_000_000 },
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
        /// Never list special nodes among or allow explicit building.
        show_special: bool = false,
        /// Show output paths in task summary.
        show_output_destination: bool = false,
        /// Print the number of succeeded tasks and the number of errors
        /// following each command.
        show_high_level_summary: bool = true,
        /// Report `open` Acquire and Error.
        open: debug.Logging.AttemptAcquireError = .{},
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
        /// Report `futex` Attempt and Success and Error.
        futex: debug.Logging.AttemptSuccessAcquireReleaseError = .{},
        /// Report `perf_event_open` Success and Error.
        perf_event_open: debug.Logging.SuccessError = .{},
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
        /// Error values for `getcwd` system function.
        getcwd: sys.ErrorPolicy = .{},
        /// Error values for `fork` system function.
        futex: sys.ErrorPolicy = .{ .throw = &.{.TIMEDOUT} },
        /// Error values for `perf_event_open` system function.
        perf_event_open: sys.ErrorPolicy = .{},
    };
};
pub fn GenericBuilder(comptime builder_spec: BuilderSpec) type {
    // Enables system commands and `run` task prefix
    comptime var have_run: bool = builder_spec.options.add_run_task_to_executables;
    // Enables `fetch` tasks
    comptime var have_fetch: bool = false;
    // Enables `format` tasks
    comptime var have_format: bool = false;
    // Enables `archive` tasks
    comptime var have_archive: bool = false;
    // Enables `objcopy` tasks
    comptime var have_objcopy: bool = false;
    // Enables lazy features.
    comptime var have_lazy: bool = builder_spec.options.extensions_policy == .emergency;
    // Enables --list command line option.
    comptime var have_list: bool = builder_spec.options.list_command != null;
    // Enables --perf command line option.
    comptime var have_perf: bool = builder_spec.options.perf_command != null;
    // Enables --size command line option.
    comptime var have_size: bool = builder_spec.options.size_command != null;
    // Enables --trace command line option.
    comptime var have_trace: bool = builder_spec.options.trace_command != null;
    const map = .{ .errors = builder_spec.errors.map, .logging = builder_spec.logging.map };
    const stat = .{ .errors = builder_spec.errors.stat, .logging = builder_spec.logging.stat };
    const link = .{ .errors = builder_spec.errors.link, .logging = builder_spec.logging.link };
    const pipe = .{ .errors = builder_spec.errors.pipe, .logging = builder_spec.logging.pipe };
    const open = .{ .errors = builder_spec.errors.open, .logging = builder_spec.logging.open };
    const read = .{ .errors = builder_spec.errors.read, .logging = builder_spec.logging.read, .return_type = usize };
    const dup3 = .{ .errors = builder_spec.errors.dup3, .logging = builder_spec.logging.dup3, .return_type = void };
    const poll = .{ .errors = builder_spec.errors.poll, .logging = builder_spec.logging.poll, .return_type = bool };
    const clock = .{ .errors = builder_spec.errors.clock };
    const sleep = .{ .errors = builder_spec.errors.sleep };
    const mkdir = .{ .errors = builder_spec.errors.mkdir, .logging = builder_spec.logging.mkdir };
    const write = .{ .errors = builder_spec.errors.write, .logging = builder_spec.logging.write };
    const close = .{ .errors = builder_spec.errors.close, .logging = builder_spec.logging.close };
    const create = .{ .errors = builder_spec.errors.create, .logging = builder_spec.logging.create };
    const unlink = .{ .errors = builder_spec.errors.unlink, .logging = builder_spec.logging.unlink };
    const waitpid = .{ .errors = builder_spec.errors.waitpid, .logging = builder_spec.logging.waitpid };
    const fork = .{
        .errors = builder_spec.errors.fork,
        .logging = builder_spec.logging.fork,
        .return_type = u32,
    };
    const write2 = .{
        .errors = builder_spec.errors.write,
        .logging = builder_spec.logging.write,
        .child = Message.ClientHeader,
    };
    const read3 = .{
        .child = Message.ServerHeader,
        .errors = builder_spec.errors.read,
        .logging = builder_spec.logging.read,
        .return_type = void,
    };
    const execve = .{
        .errors = builder_spec.errors.execve,
        .logging = builder_spec.logging.execve,
        .args_type = [][*:0]u8,
        .vars_type = [][*:0]u8,
    };
    const ar_s = fmt.about("ar");
    const fmt_s = fmt.about("fmt");
    const init_s = fmt.about("init-0");
    const main_s = fmt.about("main-1");
    const cmdline_s = fmt.about("cmdline-2");
    const exec_s = fmt.about("exec-3");
    const regen_s = fmt.about("regen-4");
    const errors_s = fmt.about("errors");
    const finished_s = fmt.about("finished");
    const cmd_args_s = fmt.about("cmd-args");
    const run_args_s = fmt.about("run-args");
    const build_run_s = fmt.about("build-run");
    const build_exe_s = fmt.about("build-exe");
    const build_obj_s = fmt.about("build-obj");
    const build_lib_s = fmt.about("build-lib");
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
        /// Our shallow cache.
        mc: *MirrorCache,
        /// Function pointers for JIT compiled functions.
        fp: *FunctionPointers,
        /// Task state futex.
        st: *u32,
        /// Thread space futex.
        ts: packed union { futex: *u32, lock: *ThreadSpace },
        /// Address space futex.
        as: packed union { futex: *u32, lock: *AddressSpace },
        /// Number of errors since processing user command line.
        errors: usize,
        /// Number of tasks finished.
        finished: usize,
        pub const Shared = @This();
        pub const FunctionPointers = struct {
            proc: struct {
                executeCommandClone: ?*const fn (
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
                ) void = null,
            },
            about: struct {
                perf: struct {
                    openFds: *const @TypeOf(PerfEvents.openFds),
                    readResults: *const @TypeOf(PerfEvents.readResults),
                    writeResults: *const @TypeOf(PerfEvents.writeResults),
                },
                generic: struct {
                    aboutTask: *const @TypeOf(about.aboutTask),
                    printErrors: *const @TypeOf(about.printErrors),
                    writeTaskDataConfig: *const @TypeOf(about.writeTaskDataConfig),
                },
            },
            build: struct {
                formatWriteBuf: *const fn (*tasks.BuildCommand, []const u8, []const types.Path, [*]u8) usize,
                formatLength: *const fn (*tasks.BuildCommand, []const u8, []const types.Path) usize,
                formatParseArgs: *const fn (*tasks.BuildCommand, *types.Allocator, [][*:0]u8) void,
            },
            format: struct {
                formatWriteBuf: *const fn (*tasks.FormatCommand, []const u8, types.Path, [*]u8) usize,
                formatLength: *const fn (*tasks.FormatCommand, []const u8, types.Path) usize,
                formatParseArgs: *const fn (*tasks.FormatCommand, *types.Allocator, [][*:0]u8) void,
            },
            archive: struct {
                formatWriteBuf: *const fn (*tasks.ArchiveCommand, []const u8, []const types.Path, [*]u8) usize,
                formatLength: *const fn (*tasks.ArchiveCommand, []const u8, []const types.Path) usize,
                formatParseArgs: *const fn (*tasks.ArchiveCommand, *types.Allocator, [][*:0]u8) void,
            },
            objcopy: struct {
                formatWriteBuf: *const fn (*tasks.ObjcopyCommand, []const u8, types.Path, [*]u8) usize,
                formatLength: *const fn (*tasks.ObjcopyCommand, []const u8, types.Path) usize,
                formatParseArgs: *const fn (*tasks.ObjcopyCommand, *types.Allocator, [][*:0]u8) void,
            },
        };
        pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
            .label = "thread",
            .index_type = usize,
            .lb_addr = stack_lb_addr,
            .up_addr = stack_up_addr,
            .divisions = max_thread_count,
            .alignment = 4096,
            .options = .{ .thread_safe = true },
        });
        pub const AddressSpace = mem.GenericRegularAddressSpace(.{
            .label = "arena",
            .index_type = usize,
            .lb_addr = arena_lb_addr,
            .up_addr = arena_up_addr,
            .divisions = max_arena_count,
            .alignment = 4096,
            .options = .{ .thread_safe = false },
        });
        pub const LoaderSpace = mem.GenericDiscreteAddressSpace(.{
            .index_type = usize,
            .label = "ld",
            .list = &[2]mem.Arena{
                .{ .lb_addr = load_meta_lb_addr, .up_addr = load_meta_up_addr },
                .{ .lb_addr = load_prog_lb_addr, .up_addr = load_prog_up_addr },
            },
        });
        pub const CacheSpace = mem.GenericDiscreteAddressSpace(.{
            .index_type = usize,
            .label = "$",
            .list = &[2]mem.Arena{
                .{ .lb_addr = cache_file_lb_addr, .up_addr = cache_file_up_addr },
                .{ .lb_addr = cache_path_lb_addr, .up_addr = cache_path_up_addr },
            },
        });
        pub const DynamicLoader = elf.GenericDynamicLoader(.{
            .logging = dyn_loader_logging,
            .errors = dyn_loader_errors,
            .AddressSpace = LoaderSpace,
        });
        pub const MirrorCache = cache.GenericMirrorCache(.{
            .logging = cache_logging,
            .errors = cache_errors,
            .AddressSpace = CacheSpace,
        });
        pub const PerfEvents = perf.GenericPerfEvents(.{
            .logging = perf_events_logging,
            .errors = perf_events_errors,
        });
        pub const specification = &builder_spec;
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
        const cache_file_lb_addr: comptime_int = load_prog_up_addr;
        const cache_file_up_addr: comptime_int = cache_path_lb_addr + builder_spec.options.max_cache_path_aligned_bytes;
        const cache_path_lb_addr: comptime_int = bits.alignA64(cache_path_up_addr, 0x100000000000);
        const cache_path_up_addr: comptime_int = cache_file_lb_addr + builder_spec.options.max_cache_file_aligned_bytes;
        const stack_lb_addr: comptime_int = bits.alignA64(cache_path_up_addr, 0x100000000000);
        const stack_up_addr: comptime_int = stack_lb_addr + (max_thread_count * stack_aligned_bytes);
        const arena_lb_addr: comptime_int = bits.alignA64(stack_up_addr, 0x100000000000);
        const arena_up_addr: comptime_int = arena_lb_addr + (max_arena_count * arena_aligned_bytes);
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
            .stat = builder_spec.errors.stat,
            .close = builder_spec.errors.close,
            .map = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const dyn_loader_logging = .{
            .open = builder_spec.logging.open,
            .stat = builder_spec.logging.stat,
            .read = builder_spec.logging.read,
            .close = builder_spec.logging.close,
            .map = builder_spec.logging.map,
            .unmap = builder_spec.logging.unmap,
        };
        const cache_errors = .{
            .open = builder_spec.errors.open,
            .stat = builder_spec.errors.stat,
            .close = builder_spec.errors.close,
            .map = builder_spec.errors.map,
            .unmap = builder_spec.errors.unmap,
        };
        const cache_logging = .{
            .open = builder_spec.logging.open,
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
            .strip = true,
            .compiler_rt = false,
            .image_base = 65536,
        };
        const extn_flags = .{
            .is_special = true,
            .is_dynamic_extension = true,
            .want_build_context = false,
            .want_builder_decl = true,
            .want_absolute_state_decl = true,
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
            stack_traces: *Node,
        };
        pub const Node = struct {
            /// The node's 'first' name. Must be unique within the parent group.
            /// Names will only be checked for uniqueness once: when the node is
            /// added to its group with any of the `add(Build|Format...)`
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
            lists: Lists,
            /// Pointer to dependent node.
            slave: ?*Node,
            /// Pointer to the shared state. May consider storing allocators
            /// and address spaces here to make UX more convenient. It also
            /// saves a number of parameters in many functions.
            sh: *Shared,
            const Lists = struct {
                /// List of related nodes. nodes[0] = group node.
                nodes: []*Node,
                nodes_max_len: usize,
                /// List of dependencies. Each structure stores an index into
                /// `nodes`. Update using `dependOn` (noob) and `addDepn` (pro).
                depns: []Depn,
                depns_max_len: usize,
                /// List of configuration formatter data. Update using
                /// `addConfigBool`, `addConfigInt`, `addConfigString`, and
                /// `addConfigFormatter`.
                confs: []Conf,
                confs_max_len: usize,
                /// List of related file system paths. Update using
                /// `addPathname` and `addPathnames`.
                paths: []types.Path,
                paths_max_len: usize,
                /// List of related files. Every path has a file, but not every
                /// file has a path (e.g. cache hits)
                files: []types.File,
                files_max_len: usize,
                cmd_args: [][*:0]u8,
                cmd_args_max_len: usize,
                run_args: [][*:0]u8,
                run_args_max_len: usize,
            };
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
                /// Whether to write `AbsoluteState` to build configuration.
                want_absolute_state_decl: bool = false,
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
                zb: u10 = 0,
            };
            const Tasks = struct {
                /// Primary (default) task for this node.
                tag: Task,
                /// Compile command information for this node. Can be a pointer to any
                /// command struct.
                cmd: tasks.Command,
            };
            const DirFds = struct {
                build_root: usize,
                output_root: usize,
                cache_root: usize,
                config_root: usize,
            };
            pub const Depn = packed struct(usize) {
                /// The node holding this dependency will block on this task ...
                task: Task,
                /// Until the node referenced by this index ...
                node: u32,
                /// Has this task ...
                on_task: Task,
                /// In this state ...
                on_state: State,
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
                        ptr[7..12].* = if (val.*) "true\x00".* else "false".*;
                        ptr += @as(usize, 12) -% @intFromBool(val.*);
                    } else if (disp == 8) {
                        const val: *isize = @ptrFromInt(addr);
                        ptr[0..15].* = "\":comptime_int=".*;
                        ptr = fmt.Id64.write(ptr + 15, val.*);
                    } else if (disp == 16) {
                        const fp: **fn (*anyopaque, [*]u8) usize = @ptrFromInt(addr);
                        const val: *anyopaque = @ptrFromInt(addr +% 8);
                        ptr[0..2].* = "\"=".*;
                        ptr += 2;
                        ptr += @call(.auto, fp.*, .{ val, ptr });
                    } else {
                        str = mem.terminate(str.ptr + str.len + 1, 0);
                        ptr[0..2].* = "\"=".*;
                        if (cfg.data & (1 << ((@bitSizeOf(usize) -% 8) +% 4)) == 0) {
                            ptr[2] = '"';
                            ptr += 3;
                        } else {
                            ptr[2..4].* = "\\\\".*;
                            ptr += 4;
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
                    @setRuntimeSafety(builtin.is_safe);
                    var itr: Iterator = .{
                        .node = node,
                        .nodes = node.lists.nodes,
                        .depns = node.lists.depns,
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
                    @setRuntimeSafety(builtin.is_safe);
                    while (itr.idx != itr.max_len) {
                        const node: *Node = if (itr.node.flags.is_group)
                            itr.nodes[itr.idx]
                        else
                            itr.nodes[itr.depns[itr.idx].node];
                        itr.idx +%= 1;
                        if (itr.node == node or node.flags.is_hidden) {
                            continue;
                        }
                        if (node.slave) |slave| {
                            if (slave != itr.node) continue;
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
                time: time.TimeSpec,
                dir_fds: ?*DirFds = null,
                execve_res: ExecveResults,
                perf_events: *PerfEvents,
                binary_analysis: *BinaryAnalysis,
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
            pub const ExecveResults = struct {
                server: u8,
                status: u8,
                signal: u8,
            };
            pub const BinaryAnalysis = struct {
                cmp: DynamicLoader.compare.Cmp,
                before: ?DynamicLoader.ElfInfo = null,
                after: ?DynamicLoader.ElfInfo = null,
            };
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
                @setRuntimeSafety(builtin.is_safe);
                const files: []types.File = node.lists.files;
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
            fn createFileList(node: *const Node, allocator: *types.Allocator, key: types.File.Key) []types.File {
                @setRuntimeSafety(builtin.is_safe);
                const files: []types.File = node.lists.files;
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
            fn createPathList(node: *const Node, allocator: *types.Allocator, key: types.File.Key) []types.Path {
                @setRuntimeSafety(builtin.is_safe);
                const files: []types.File = node.lists.files;
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
                @setRuntimeSafety(builtin.is_safe);
                if (node.getFile(key)) |fs| {
                    if (node.getFilePath(fs)) |path| {
                        return path;
                    }
                }
                return null;
            }
            pub fn getFilePath(node: *const Node, fs: *const types.File) ?*types.Path {
                @setRuntimeSafety(builtin.is_safe);
                const paths: []types.Path = node.lists.paths;
                if (!fs.key.flags.is_cached) {
                    return @ptrCast(paths.ptr + fs.path_idx);
                }
                return null;
            }
            pub fn getFileStatus(node: *const Node, fs: *const types.File) ?*file.Status {
                @setRuntimeSafety(builtin.is_safe);
                if (node.getFilePath(fs)) |path| {
                    path.status(stat, fs.st);
                }
                return null;
            }
            /// Allocate a node pointer.
            fn addNode(node: *Node, allocator: *types.Allocator) **Node {
                @setRuntimeSafety(builtin.is_safe);
                defer node.lists.nodes.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf(*Node), @alignOf(*Node), 1, @ptrCast(&node.lists.nodes.ptr), &node.lists.nodes_max_len, node.lists.nodes.len));
            }
            fn addFile(node: *Node, allocator: *types.Allocator) *types.File {
                @setRuntimeSafety(builtin.is_safe);
                defer node.lists.files.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf(types.File), @alignOf(types.File), 1, @ptrCast(&node.lists.files.ptr), &node.lists.files_max_len, node.lists.files.len));
            }
            pub fn addCmdArg(node: *Node, allocator: *types.Allocator) *[*:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                defer node.lists.cmd_args.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf([*:0]u8), @alignOf([*:0]u8), 2, @ptrCast(&node.lists.cmd_args.ptr), &node.lists.cmd_args_max_len, node.lists.cmd_args.len));
            }
            pub fn addRunArg(node: *Node, allocator: *types.Allocator) *[*:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                defer node.lists.run_args.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf([*:0]u8), @alignOf([*:0]u8), 2, @ptrCast(&node.lists.run_args.ptr), &node.lists.run_args_max_len, node.lists.run_args.len));
            }
            fn addConfig(node: *Node, allocator: *types.Allocator) *Conf {
                @setRuntimeSafety(builtin.is_safe);
                defer node.lists.confs.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf(Conf), @alignOf(Conf), 1, @ptrCast(&node.lists.confs.ptr), &node.lists.confs_max_len, node.lists.confs.len));
            }
            pub fn addConfigString(node: *Node, allocator: *types.Allocator, name: []const u8, value: []const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(value.len +% name.len +% 2, 1);
                fmt.strcpyEqu(@ptrFromInt(addr), name)[0] = 0;
                fmt.strcpyEqu(@ptrFromInt(addr +% name.len +% 1), value)[0] = 0;
                node.addConfig(allocator).data = addr;
            }
            pub fn addConfigBool(node: *Node, allocator: *types.Allocator, name: []const u8, value: bool) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(name.len +% 2, 1);
                const ptr: *bool = @ptrFromInt(addr);
                ptr.* = value;
                fmt.strcpyEqu(@ptrFromInt(addr +% 1), name)[0] = 0;
                node.addConfig(allocator).data = (1 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            pub fn addConfigInt(node: *Node, allocator: *types.Allocator, name: []const u8, value: isize) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(name.len +% 1 +% 8, 8);
                const ptr: *isize = @ptrFromInt(addr);
                ptr.* = value;
                fmt.strcpyEqu(@ptrFromInt(addr +% @sizeOf(isize)), name)[0] = 0;
                node.addConfig(allocator).data = (8 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            pub fn addConfigFormatter(
                node: *Node,
                allocator: *types.Allocator,
                name: []const u8,
                formatWriteBuf: *const fn (*const anyopaque, [*]u8) usize,
                format: *const anyopaque,
            ) void {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = allocator.allocateRaw(16 +% name.len +% 1, 8);
                const lists: *[2]usize = @ptrFromInt(addr);
                lists[0] = @intFromPtr(formatWriteBuf);
                lists[1] = @intFromPtr(format);
                fmt.strcpyEqu(@ptrFromInt(addr +% 16), name)[0] = 0;
                node.addConfig(allocator).data = (16 << (@bitSizeOf(usize) -% 8)) | addr;
            }
            fn addPath(node: *Node, allocator: *types.Allocator, tag: types.File.Tag) *types.Path {
                @setRuntimeSafety(builtin.is_safe);
                const paths: []types.Path = node.lists.paths;
                const fs: *types.File = node.addFile(allocator);
                fs.* = .{
                    .path_idx = @intCast(paths.len),
                    .key = .{ .tag = tag },
                    .st = @ptrFromInt(8),
                };
                if (!fs.key.flags.is_cached) {
                    fs.st = @ptrFromInt(allocator.allocateRaw(144, 8));
                }
                defer node.lists.paths.len +%= 1;
                return @ptrFromInt(allocator.addGeneric(@sizeOf(types.Path), @alignOf(types.Path), 2, @ptrCast(&node.lists.paths.ptr), &node.lists.paths_max_len, node.lists.paths.len));
            }
            pub fn addPathname(node: *Node, allocator: *types.Allocator, tag: types.File.Tag, pathname: []const u8) *types.Path {
                @setRuntimeSafety(builtin.is_safe);
                return node.addPathnames(allocator, tag, &.{pathname});
            }
            pub fn addPathnames(node: *Node, allocator: *types.Allocator, tag: types.File.Tag, names: []const []const u8) *types.Path {
                @setRuntimeSafety(builtin.is_safe);
                const path: *types.Path = node.addPath(allocator, tag);
                path.* = .{};
                for (names) |name| {
                    path.addName(allocator).* = duplicate(allocator, name);
                }
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .add_file);
                }
                return path;
            }
            pub fn addToplevelArgs(node: *Node, allocator: *types.Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addRunArg(allocator).* = node.zigExe();
                node.addRunArg(allocator).* = node.buildRoot();
                node.addRunArg(allocator).* = node.cacheRoot();
                node.addRunArg(allocator).* = node.globalCacheRoot();
                if (node.sh.seed) |seed| {
                    node.addRunArg(allocator).* = @constCast("--seed");
                    node.addRunArg(allocator).* = seed.ptr;
                }
            }
            inline fn addDefineConfigs(node: *Node, allocator: *types.Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addConfigBool(allocator, "is_safe", false);
                node.addConfigString(allocator, "message_style", fmt.toStringLiteral(builtin.message_style orelse "null"));
                node.addConfigString(allocator, "message_prefix", fmt.toStringLiteral(builtin.message_prefix));
                node.addConfigString(allocator, "message_suffix", fmt.toStringLiteral(builtin.message_suffix));
                node.addConfigInt(allocator, "message_indent", builtin.message_indent);
            }
            inline fn addBuildContextConfigs(node: *Node, allocator: *types.Allocator) void {
                @setRuntimeSafety(builtin.is_safe);
                node.addConfigString(allocator, "zig_exe", node.zigExe());
                node.addConfigString(allocator, "build_root", node.buildRoot());
                node.addConfigString(allocator, "cache_root", node.cacheRoot());
                node.addConfigString(allocator, "global_cache_root", node.cacheRoot());
            }
            pub fn init(allocator: *types.Allocator, args: [][*:0]u8, vars: [][*:0]u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const node: *Node = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node), @alignOf(Node)));
                node.sh = @ptrFromInt(allocator.allocateRaw(@sizeOf(Shared), @alignOf(Shared)));
                node.sh.st = @ptrFromInt(allocator.allocateRaw(@sizeOf(usize), @sizeOf(usize)));
                node.sh.top = node;
                node.sh.args = args;
                node.sh.vars = vars;
                node.flags = .{ .is_top = true, .is_group = true };
                node.addNode(allocator).* = node;
                node.addPath(allocator, .zig_compiler_exe).addName(allocator).* = mem.terminate(args[1], 0);
                node.addPath(allocator, .build_root).addName(allocator).* = mem.terminate(args[2], 0);
                node.addPath(allocator, .cache_root).addName(allocator).* = mem.terminate(args[3], 0);
                node.addPath(allocator, .global_cache_root).addName(allocator).* = mem.terminate(args[4], 0);
                node.name = basename(node.buildRoot());
                initializeGroup(allocator, node);
                initializeExtensions(allocator, node);
                node.sh.mode = .Main;
                return node;
            }
            fn basename(pathname: [:0]u8) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var idx: usize = pathname.len -% 1;
                while (pathname[idx] != '/') idx -%= 1;
                return pathname[idx +% 1 .. :0];
            }
            pub fn addGroup(group: *Node, allocator: *types.Allocator, name: [:0]const u8, env_paths: ?EnvPaths) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const node: *Node = createNode(allocator, group, name, .{ .is_group = true }, .any, omni_lock);
                if (env_paths) |paths| {
                    node.addPath(allocator, .zig_compiler_exe).addName(allocator).* = paths.zig_exe;
                    node.addPath(allocator, .build_root).addName(allocator).* = paths.build_root;
                    node.addPath(allocator, .cache_root).addName(allocator).* = paths.cache_root;
                    node.addPath(allocator, .global_cache_root).addName(allocator).* = paths.global_cache_root;
                } else {
                    node.lists.paths = group.lists.paths;
                }
                initializeGroup(allocator, node);
                return node;
            }
            pub fn addBuild(group: *Node, allocator: *types.Allocator, build_cmd: tasks.BuildCommand, name: [:0]const u8, root_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                const node: *Node = createNode(allocator, group, name, .{}, .build, obj_lock);
                node.tasks.cmd.build = @ptrFromInt(allocator.allocateRaw(tasks.BuildCommand.size_of, tasks.BuildCommand.align_of));
                node.tasks.cmd.build.* = build_cmd;
                node.addBinaryOutputPath(allocator, @enumFromInt(@intFromEnum(build_cmd.kind)));
                node.addSourceInputPath(allocator, duplicate(allocator, root_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addFormat(group: *Node, allocator: *types.Allocator, format_cmd: tasks.FormatCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_format = true;
                const node: *Node = createNode(allocator, group, name, .{}, .format, format_lock);
                node.tasks.cmd.format = @ptrFromInt(allocator.allocateRaw(tasks.FormatCommand.size_of, tasks.FormatCommand.align_of));
                node.tasks.cmd.format.* = format_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addFetch(group: *Node, allocator: *types.Allocator, format_cmd: tasks.FormatCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_format = true;
                const node: *Node = createNode(allocator, group, name, .{}, .fetch, fetch_lock);
                node.tasks.cmd.format = @ptrFromInt(allocator.allocateRaw(tasks.FormatCommand.size_of, tasks.FormatCommand.align_of));
                node.tasks.cmd.format.* = format_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addArchive(group: *Node, allocator: *types.Allocator, archive_cmd: tasks.ArchiveCommand, name: [:0]const u8, depns: []const *Node) *Node {
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
            pub fn addObjcopy(group: *Node, allocator: *types.Allocator, objcopy_cmd: tasks.ObjcopyCommand, name: [:0]const u8, dest_pathname: []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_objcopy = true;
                const node: *Node = createNode(allocator, group, name, .{}, .objcopy, objcopy_lock);
                node.tasks.cmd.objcopy = @ptrFromInt(allocator.allocateRaw(tasks.ObjcopyCommand.size_of, tasks.ObjcopyCommand.align_of));
                node.tasks.cmd.objcopy.* = objcopy_cmd;
                node.addSourceInputPath(allocator, duplicate(allocator, dest_pathname));
                initializeCommand(allocator, node);
                return node;
            }
            pub fn addRun(group: *Node, allocator: *types.Allocator, name: [:0]const u8, args: []const []const u8) *Node {
                @setRuntimeSafety(builtin.is_safe);
                have_run = true;
                const node: *Node = createNode(allocator, group, name, .{}, .run, run_lock);
                for (args) |arg| node.addRunArg(allocator).* = duplicate(allocator, arg);
                initializeCommand(allocator, node);
                return node;
            }
            fn addSourceInputPath(node: *Node, allocator: *types.Allocator, name: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                const root_path: *types.Path = node.addPath(allocator, classifySourceInputName(name));
                root_path.* = .{};
                root_path.addName(allocator).* = node.buildRoot();
                root_path.addName(allocator).* = name;
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .add_file);
                }
            }
            fn addBinaryOutputPath(node: *Node, allocator: *types.Allocator, kind: types.File.Tag) void {
                @setRuntimeSafety(builtin.is_safe);
                const binary_path: *types.Path = node.addPath(allocator, kind);
                binary_path.* = .{};
                binary_path.addName(allocator).* = node.buildRoot();
                binary_path.addName(allocator).* = outputRelative(allocator, node, kind);
                if (builder_spec.logging.show_task_update) {
                    about.aboutNode(node, null, null, .add_file);
                }
            }
            pub fn addDepn(node: *Node, allocator: *types.Allocator, task: Task, on_node: *Node, on_task: Task) void {
                @setRuntimeSafety(builtin.is_safe);
                const idx: u32 = @intCast(node.lists.nodes.len);
                const depn: *Depn = @ptrFromInt(allocator.addGeneric(8, 8, 2, @ptrCast(&node.lists.depns.ptr), &node.lists.depns_max_len, node.lists.depns.len));
                node.lists.depns.len +%= 1;
                node.addNode(allocator).* = on_node;
                if (task == .build) {
                    if (on_task == .archive) {
                        node.addPath(allocator, .input_ar).* = on_node.lists.paths[0];
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, null, .add_file);
                        }
                    }
                    if (on_node.flags.have_task_data and
                        on_task == .build and
                        on_node.tasks.cmd.build.kind == .obj)
                    {
                        node.addPath(allocator, .input_obj).* = on_node.lists.paths[0];
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
                        node.addPath(allocator, .input_ar).* = on_node.lists.paths[0];
                        if (builder_spec.logging.show_task_update) {
                            about.aboutNode(node, null, null, .add_file);
                        }
                    }
                }
                depn.* = .{ .task = task, .on_task = on_task, .on_state = .finished, .node = idx };
            }
            pub fn dependOn(node: *Node, allocator: *types.Allocator, on_node: *Node) void {
                node.addDepn(
                    allocator,
                    if (node == on_node) .run else node.tasks.tag,
                    on_node,
                    on_node.tasks.tag,
                );
            }
            pub fn addGroupWithTask(
                group: *Node,
                allocator: *types.Allocator,
                name: [:0]const u8,
                task: Task,
            ) *Node {
                const node: *Node = group.addGroup(allocator, name, null);
                node.tasks.tag = task;
                return node;
            }
            pub fn addBuildAnon(
                group: *Node,
                allocator: *types.Allocator,
                build_cmd: tasks.BuildCommand,
                root_pathname: [:0]const u8,
            ) *Node {
                const name: [:0]const u8 = makeCommandName(allocator, root_pathname);
                const node: *Node = group.addBuild(allocator, build_cmd, name, root_pathname);
                return node;
            }
            pub fn zigExe(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return zigExe(node.lists.nodes[0]);
                }
                return node.lists.paths[0].names[0];
            }
            pub fn buildRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return buildRoot(node.lists.nodes[0]);
                }
                return node.lists.paths[1].names[0];
            }
            pub fn cacheRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return cacheRoot(node.lists.nodes[0]);
                }
                return node.lists.paths[2].names[0];
            }
            pub fn globalCacheRoot(node: *Node) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return globalCacheRoot(node.lists.nodes[0]);
                }
                return node.lists.paths[3].names[0];
            }
            pub fn buildRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return buildRootFd(node.lists.nodes[0]);
                }
                return node.extra.dir_fds.?.build_root;
            }
            pub fn configRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return configRootFd(node.lists.nodes[0]);
                }
                return node.extra.dir_fds.?.config_root;
            }
            pub fn outputRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return outputRootFd(node.lists.nodes[0]);
                }
                return node.extra.dir_fds.?.output_root;
            }
            pub fn cacheRootFd(node: *Node) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return cacheRootFd(node.lists.nodes[0]);
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
                const nodes: []*Node = node.lists.nodes;
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
                var len: usize = node.lists.nodes[0].formatLengthNameFull();
                len +%= @intFromBool(len != 0) +% node.name.len;
                return len;
            }
            pub fn formatWriteNameRelative(node: *const Node, group: *const Node, sep: u8, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (node != group) {
                    ptr += node.lists.nodes[0].formatWriteNameRelative(group, sep, ptr);
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
                    len +%= node.lists.nodes[0].formatLengthNameRelative(group);
                    len +%= @intFromBool(len != 0) +% node.name.len;
                }
                return len;
            }
            pub fn formatWriteConfigRoot(node: *Node, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                const paths: []types.Path = node.lists.paths;
                var ptr: [*]u8 = buf;
                if (node.flags.want_absolute_state_decl) {
                    ptr[0..99].* =
                        \\pub const AbsoluteState=struct{
                        \\home:[:0]const u8,
                        \\cwd:[:0]const u8,
                        \\proj:[:0]const u8,
                        \\pid:u16,};
                        \\
                    .*;
                    ptr += 99;
                }
                if (have_lazy and node.flags.want_builder_decl) {
                    ptr[0..24].* =
                        \\const zl=@import("zl");
                        \\
                    .*;
                    ptr += 24;
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
                for (node.lists.confs) |cfg| {
                    ptr += cfg.formatWriteBuf(ptr);
                }
                if (node.flags.have_task_data) {
                    ptr = about.writeTaskDataConfig(node, ptr);
                }
                return @intFromPtr(ptr) -% @intFromPtr(buf);
            }
            pub fn find(group: *Node, allocator: *types.Allocator, name: []const u8, sep: u8) ?*Node {
                @setRuntimeSafety(builtin.is_safe);
                blk: {
                    var idx: usize = 0;
                    while (idx != name.len) : (idx +%= 1) {
                        if (name[idx] == sep) {
                            break;
                        }
                    } else {
                        idx = 1;
                        for (group.lists.nodes[1..]) |node| {
                            if (mem.testEqualString(name, node.name)) {
                                return node;
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
                    for (group.lists.nodes[1..]) |node| {
                        if (node.flags.is_group and
                            mem.testEqualString(group_name, node.name))
                        {
                            return node.find(allocator, sub_name, sep);
                        }
                    }
                }
                if (have_list) {
                    about.writeAndWalk(allocator, group, .depns);
                }
                return null;
            }
        };
        pub fn configRootRelative(allocator: *types.Allocator, node: *Node) [:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const name_len: usize = node.formatLengthNameFull();
            const buf: [*:0]u8 = @ptrFromInt(allocator.allocateRaw(name_len +% 5, 1));
            fmt.strcpyEqu(buf + node.formatWriteNameFull('-', buf), ".zig")[0] = 0;
            return buf[0 .. name_len +% 4 :0];
        }
        fn createConfigRoot(allocator: *types.Allocator, node: *Node, pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = file.createAt(create, create_truncate_options, node.configRootFd(), pathname, file.mode.regular);
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(65536, 1));
            const len: usize = node.formatWriteConfigRoot(buf);
            file.write(write, fd, buf[0..len]);
            file.close(close, fd);
            @memset(buf[0..len], 0);
            allocator.restore(@intFromPtr(buf));
            node.flags.have_config_root = true;
        }
        pub fn outputRelative(allocator: *types.Allocator, node: *Node, tag: types.File.Tag) [:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var buf: [4096]u8 = undefined;
            const name: []u8 = if (builder_spec.options.naming_policy == .full_name) blk: {
                const len: usize = node.formatWriteNameFull('-', &buf);
                break :blk buf[0..len];
            } else node.name;
            return concatenate(allocator, switch (tag) {
                .output_exe => &[_][]const u8{ binary_prefix, name },
                .output_ar => &[_][]const u8{ archive_prefix, name, ".a" },
                .output_obj => &[_][]const u8{ binary_prefix, name, ".o" },
                .output_lib => &[_][]const u8{ library_prefix, name, ".so" },
                .output_llvm_ir => &[_][]const u8{ auxiliary_prefix, name, ".ll" },
                .output_llvm_bc => &[_][]const u8{ auxiliary_prefix, name, ".bc" },
                else => proc.exitErrorFault(error.InvalidOutput, @tagName(tag), 2),
            });
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
        fn createNode(allocator: *types.Allocator, group: *Node, name: [:0]const u8, flags: Node.Flags, task_tag: Task, lock: Lock) *Node {
            @setRuntimeSafety(builtin.is_safe);
            const node: *Node = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node), @alignOf(Node)));
            group.addNode(allocator).* = node;
            node.addNode(allocator).* = group;
            node.name = duplicate(allocator, name);
            node.sh = group.sh;
            node.tasks.tag = task_tag;
            node.flags = flags;
            node.lock = lock;
            node.descr = &.{};
            return node;
        }
        fn initializeExtensions(allocator: *types.Allocator, top: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            const zero: *Node = top.addGroup(allocator, "zero", .{
                .zig_exe = top.zigExe(),
                .build_root = builtin.lib_root,
                .cache_root = builtin.lib_root ++ "/" ++ builder_spec.options.cache_dir,
                .global_cache_root = Node.globalCacheRoot(top),
            });
            zero.flags.is_special = true;
            top.sh.dl = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(DynamicLoader),
                @alignOf(DynamicLoader),
            ));
            top.sh.dl.* = .{};
            top.sh.mc = @ptrFromInt(allocator.allocateRaw(
                @sizeOf(MirrorCache),
                @alignOf(MirrorCache),
            ));
            top.sh.mc.* = .{};
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
            top.sh.extns.stack_traces = zero.addBuild(allocator, trace_build_cmd, "stack_traces", "top/trace.zig");
            if (have_lazy) {
                var ptr: *[24][*:0]u8 = @ptrFromInt(allocator.allocateRaw(24 *% 8, 8));
                var tmp = [24][*:0]const u8{
                    top.zigExe(),         "build-lib",
                    "--cache-dir",        zero.cacheRoot(),
                    "--global-cache-dir", zero.globalCacheRoot(),
                    "--main-mod-path",    zero.buildRoot(),
                    "--mod",              "zl::" ++ builtin.lib_root ++ "/zig_lib.zig",
                    "-dynamic",           "--listen=-",
                    "--deps",             "zl",
                    "-fentry=load",       "-z",
                    "defs",               "-fsingle-threaded",
                    "-fno-compiler-rt",   "-fno-stack-check",
                    "-fno-unwind-tables", "-fno-function-sections",
                    "-fstrip",            "-ODebug",
                };
                for (ptr, tmp) |*dest, src| dest.* = @constCast(src);

                top.sh.extns.proc = createNode(allocator, zero, "proc", extn_flags, .build, obj_lock);
                top.sh.extns.proc.lists.cmd_args = ptr;
                top.sh.extns.proc.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.proc.addSourceInputPath(allocator, "top/build/proc.auto.zig");
                top.sh.extns.proc.lists.cmd_args_max_len = ptr.len;

                top.sh.extns.about = createNode(allocator, zero, "about", extn_flags, .build, obj_lock);
                top.sh.extns.about.lists.cmd_args = ptr;
                top.sh.extns.about.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.about.addSourceInputPath(allocator, "top/build/about.auto.zig");
                top.sh.extns.about.lists.cmd_args_max_len = ptr.len;

                top.sh.extns.build = createNode(allocator, zero, "build", extn_flags, .build, obj_lock);
                top.sh.extns.build.lists.cmd_args = ptr;
                top.sh.extns.build.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.build.addSourceInputPath(allocator, "top/build/build.auto.zig");
                top.sh.extns.build.lists.cmd_args_max_len = ptr.len;

                top.sh.extns.format = createNode(allocator, zero, "format", extn_flags, .build, obj_lock);
                top.sh.extns.format.lists.cmd_args = ptr;
                top.sh.extns.format.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.format.addSourceInputPath(allocator, "top/build/format.auto.zig");
                top.sh.extns.format.lists.cmd_args_max_len = ptr.len;

                top.sh.extns.objcopy = createNode(allocator, zero, "objcopy", extn_flags, .build, obj_lock);
                top.sh.extns.objcopy.lists.cmd_args = ptr;
                top.sh.extns.objcopy.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.objcopy.addSourceInputPath(allocator, "top/build/objcopy.auto.zig");
                top.sh.extns.objcopy.lists.cmd_args_max_len = ptr.len;

                top.sh.extns.archive = createNode(allocator, zero, "archive", extn_flags, .build, obj_lock);
                top.sh.extns.archive.lists.cmd_args = ptr;
                top.sh.extns.archive.addBinaryOutputPath(allocator, .output_lib);
                top.sh.extns.archive.addSourceInputPath(allocator, "top/build/archive.auto.zig");
                top.sh.extns.archive.lists.cmd_args_max_len = ptr.len;
            }
        }
        fn classifySourceInputName(name: []const u8) types.File.Tag {
            @setRuntimeSafety(builtin.is_safe);
            for ([_]struct { [:0]const u8, types.File.Tag }{
                .{ ".zig", .input_zig },
                .{ ".h", .input_c },
                .{ ".c", .input_c },
                .{ ".so", .input_lib },
                .{ ".a", .input_ar },
                .{ ".o", .input_obj },
                .{ ".s", .input_asm },
                .{ ".bc", .input_llvm_bc },
                .{ ".ll", .input_llvm_ir },
            }) |pair| {
                if (mem.testEqualString(name[name.len -% pair[0].len ..], pair[0])) {
                    return pair[1];
                }
            }
            return .input_generic;
        }
        pub fn initializeGroup(allocator: *types.Allocator, node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            var st: [2]file.Status = undefined;
            if (node.flags.is_top or
                !file.sameFile(stat, &st[0], node.lists.nodes[0].buildRoot(), &st[1], node.buildRoot()))
            {
                const dir_fds: *Node.DirFds = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node.DirFds), @alignOf(Node.DirFds)));
                dir_fds.build_root = file.openAt(open, dir_options, file.cwd, node.buildRoot());
                for ([4][:0]const u8{
                    builder_spec.options.cache_dir,
                    builder_spec.options.output_dir,
                    builder_spec.options.config_dir,
                    builder_spec.options.stat_dir,
                }) |name| {
                    mem.zero(file.Status, &st[0]);
                    file.statusAt(stat, .{}, dir_fds.build_root, name, &st[0]);
                    if (st[0].mode.kind == .unknown) {
                        file.makeDirAt(mkdir, dir_fds.build_root, name, file.mode.directory);
                    }
                }
                dir_fds.output_root = try meta.wrap(file.openAt(
                    open,
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
                    file.statusAt(stat, .{}, dir_fds.output_root, name, &st[0]);
                    if (st[0].mode.kind == .unknown) {
                        file.makeDirAt(mkdir, dir_fds.output_root, name, file.mode.directory);
                    }
                }
                dir_fds.cache_root = try meta.wrap(file.openAt(
                    open,
                    dir_options,
                    dir_fds.build_root,
                    builder_spec.options.cache_dir,
                ));
                dir_fds.config_root = try meta.wrap(file.openAt(
                    open,
                    dir_options,
                    dir_fds.build_root,
                    builder_spec.options.config_dir,
                ));
                node.extra.dir_fds = dir_fds;
            } else {
                node.extra.dir_fds = node.lists.nodes[0].extra.dir_fds;
            }
            if (node.flags.is_top) {
                if (max_thread_count != 0) {
                    mem.map(map, .{}, .{}, stack_lb_addr, stack_up_addr -% stack_lb_addr);
                }
            }
            initializeCommand(allocator, node);
        }
        pub fn initializeCommand(allocator: *types.Allocator, node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (node.sh.mode != .Regen and node.flags.do_init) {
                node.flags.do_init = false;
                if (builder_spec.options.init_inherit_special and
                    node.lists.nodes[0].flags.is_special)
                {
                    node.flags.is_special = true;
                    if (builder_spec.logging.show_task_update) {
                        about.aboutNode(node, .init_inherit_hidden, .is_special, .enable_flag);
                    }
                }
                if (builder_spec.options.init_inherit_hidden and
                    node.lists.nodes[0].flags.is_hidden)
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
                        if (builder_spec.options.add_stack_traces_to_debug_executables) {
                            node.flags.want_stack_traces = node.hasDebugInfo();
                            if (builder_spec.logging.show_task_update) {
                                about.aboutNode(node, .add_stack_traces_to_debug_executables, .want_stack_traces, .enable_flag);
                            }
                        }
                        if (builder_spec.options.add_run_task_to_executables) {
                            node.lock = exe_lock;
                            node.dependOn(allocator, node);
                            node.addRunArg(allocator).* = node.lists.paths[0].concatenate(allocator);
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
            allocator: *types.Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
            actionFn: *const fn (*AddressSpace, *ThreadSpace, *types.Allocator, *Node, Task, AddressSpace.Index) bool,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            if (actionFn(address_space, thread_space, allocator, node, task, arena_index)) {
                const nodes: []*Node = node.lists.nodes;
                if (node.flags.is_group) {
                    for (nodes[1..]) |sub| {
                        recursiveAction(address_space, thread_space, allocator, sub, task, arena_index, actionFn);
                    }
                } else {
                    const deps: []Node.Depn = node.lists.depns;
                    for (deps) |dep| {
                        recursiveAction(address_space, thread_space, allocator, nodes[dep.node], task, arena_index, actionFn);
                    }
                }
            }
        }
        fn taskArgs(allocator: *types.Allocator, node: *Node, args: *const []const usize, grp_args: *const []const usize) [][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const args_len: usize = args.len +% (if (node.flags.is_primary) grp_args.len else 0);
            const ret: [*]usize = @ptrFromInt(allocator.allocateRaw(8 *% (args_len +% 1), 8));
            @memcpy(ret, args.*);
            @memcpy(ret + args.len, grp_args.*);
            ret[args.len +% grp_args.len] = 0;
            return @ptrCast(ret[0..args_len]);
        }
        fn buildTaskArgs(allocator: *types.Allocator, node: *Node) ?[][*:0]u8 {
            @setRuntimeSafety(false);
            const paths: []types.Path = node.lists.paths[@as(usize, 1) +% @intFromBool(node.flags.have_config_root) ..];
            if (!node.flags.have_task_data) {
                return taskArgs(allocator, node, @ptrCast(&node.lists.cmd_args), @ptrCast(&node.lists.nodes[0].lists.cmd_args));
            }
            const save = node.tasks.cmd.build;
            defer node.tasks.cmd.build = save;
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.build.formatParseArgs(node.tasks.cmd.build, allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.BuildCommand = node.tasks.cmd.build;
                const max_len: usize = node.sh.fp.build.formatLength(cmd, node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.build.formatWriteBuf(cmd, node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.build.formatParseArgs(allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.BuildCommand = node.tasks.cmd.build;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        fn formatTaskArgs(allocator: *types.Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.format.formatParseArgs(node.tasks.cmd.format, allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.FormatCommand = node.tasks.cmd.format;
                const max_len: usize = node.sh.fp.format.formatLength(cmd, node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.format.formatWriteBuf(cmd, node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.format.formatParseArgs(allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.FormatCommand = node.tasks.cmd.format;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        fn fetchTaskArgs(allocator: *types.Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.fetch.fetchParseArgs(node.tasks.cmd.fetch, allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.fetchCommand = node.tasks.cmd.fetch;
                const max_len: usize = node.sh.fp.fetch.fetchLength(cmd, node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.fetch.fetchWriteBuf(cmd, node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.fetch.fetchParseArgs(allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.fetchCommand = node.tasks.cmd.fetch;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.fetchLength(node.zigExe(), paths[0]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.fetchWriteBuf(node.zigExe(), paths[0], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        fn objcopyTaskArgs(allocator: *types.Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.objcopy.formatParseArgs(node.tasks.cmd.objcopy, allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.ObjcopyCommand = node.tasks.cmd.objcopy;
                const max_len: usize = node.sh.fp.objcopy.formatLength(cmd, node.zigExe(), paths[1]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.objcopy.formatWriteBuf(cmd, node.zigExe(), paths[1], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.objcopy.formatParseArgs(allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.ObjcopyCommand = node.tasks.cmd.objcopy;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths[1]);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths[1], buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        fn archiveTaskArgs(allocator: *types.Allocator, node: *Node, paths: []types.Path) ?[][*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (node.flags.is_primary) {
                    node.sh.fp.archive.formatParseArgs(node.tasks.cmd.archive, allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.ArchiveCommand = node.tasks.cmd.archive;
                const max_len: usize = node.sh.fp.archive.formatLength(cmd, node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = node.sh.fp.archive.formatWriteBuf(cmd, node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            } else {
                if (node.flags.is_primary) {
                    node.tasks.cmd.archive.formatParseArgs(allocator, node.lists.nodes[0].lists.cmd_args);
                }
                const cmd: *tasks.ArchiveCommand = node.tasks.cmd.archive;
                const max_len: usize = builder_spec.options.max_cmdline_len orelse cmd.formatLength(node.zigExe(), paths);
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                const len: usize = cmd.formatWriteBuf(node.zigExe(), paths, buf);
                buf[len] = 0;
                return makeArgPtrs(allocator, buf[0..len :0]);
            }
        }
        fn executeRunCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const args: [][*:0]u8 = taskArgs(allocator, node, @ptrCast(&node.lists.run_args), @ptrCast(&node.lists.nodes[0].lists.run_args));
            system(node, mem.terminate(args[0], 0), args, node.sh.vars);
            return status(node.extra.execve_res);
        }
        fn executeBuildCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const dest_pathname: [:0]const u8 = node.lists.paths[0].concatenate(allocator);
            if (buildTaskArgs(allocator, node)) |args| {
                const in: file.Pipe = file.makePipe(pipe, pipe_options);
                const out: file.Pipe = file.makePipe(pipe, pipe_options);
                const pid: usize = serverOpen(node, args, in, out);
                serverLoop(allocator, node, dest_pathname, in, out);
                serverClose(node, in, out, pid);
            }
            if (have_lazy) {
                if (node.flags.is_dynamic_extension) {
                    node.sh.dl.load(dest_pathname).entry()(node.sh.fp);
                }
            }
            return status(node.extra.execve_res);
        }
        fn executeFormatCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const paths: []types.Path = node.lists.paths;
            if (formatTaskArgs(allocator, node, paths)) |args| {
                system(node, mem.terminate(args[0], 0), args, node.sh.vars);
            }
            return status(node.extra.execve_res);
        }
        fn executeFetchCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const paths: []types.Path = node.lists.paths;
            if (fetchTaskArgs(allocator, node, paths)) |args| {
                system(node, mem.terminate(args[0], 0), args, node.sh.vars);
            }
            return status(node.extra.execve_res);
        }
        fn executeArchiveCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const paths: []types.Path = node.lists.paths;
            if (archiveTaskArgs(allocator, node, paths)) |args| {
                system(node, mem.terminate(args[0], 0), args, node.sh.vars);
            }
            return status(node.extra.execve_res);
        }
        fn executeObjcopyCommand(allocator: *types.Allocator, node: *Node) bool {
            @setRuntimeSafety(builtin.is_safe);
            const paths: []types.Path = node.lists.paths;
            if (objcopyTaskArgs(allocator, node, paths)) |args| {
                system(node, mem.terminate(args[0], 0), args, node.sh.vars);
            }
            return status(node.extra.execve_res);
        }
        fn executeCommand(allocator: *types.Allocator, node: *Node, task: Task, arena_index: AddressSpace.Index) bool {
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
            allocator: *types.Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            if (node.flags.is_top or !node.flags.is_group) {
                for (node.lists.depns) |dep| {
                    if (node.lists.nodes[dep.node] == node and
                        dep.on_task == task or dep.task != task)
                    {
                        continue;
                    }
                    if (!keepGoing(node)) return;
                    if (exchange(node.lists.nodes[dep.node], dep.on_task, .ready, .blocking, arena_index)) {
                        if (node.lists.nodes[dep.node].slave == null) {
                            node.lists.nodes[dep.node].slave = node;
                        }
                        tryAcquireThread(address_space, thread_space, allocator, node.lists.nodes[dep.node], dep.on_task, arena_index);
                    }
                }
            } else {
                for (node.lists.nodes[1..]) |sub_node| {
                    if (sub_node == node and sub_node.tasks.tag == task) {
                        continue;
                    }
                    if (!keepGoing(node)) return;
                    if (exchange(sub_node, task, .ready, .blocking, arena_index)) {
                        if (sub_node.slave == null) {
                            sub_node.slave = node;
                        }
                        tryAcquireThread(address_space, thread_space, allocator, sub_node, task, arena_index);
                    }
                }
            }
        }
        fn tryAcquireThread(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *types.Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy and max_thread_count != 0) {
                if (node.sh.fp.proc.executeCommandClone) |executeCommandClone| {
                    for (0..max_thread_count) |thread_index| {
                        if (!mem.testAcquire(ThreadSpace, thread_space, thread_index)) {
                            continue;
                        }
                        return @call(.auto, executeCommandClone, .{
                            // Call parameters:
                            address_space,
                            thread_space,
                            node,
                            task,
                            thread_index,
                            // Call:
                            executeCommandThreaded,
                            // On stack:
                            ThreadSpace.low(thread_index),
                            stack_aligned_bytes,
                        });
                    }
                }
            }
            executeCommandSynchronised(address_space, thread_space, allocator, node, task, arena_index);
        }
        pub fn prepareCommand(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *types.Allocator,
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
            if (node.flags.is_group) {
                return true;
            }
            if (node.tasks.tag == .build) {
                for (node.lists.files) |fs| {
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
            if (node.flags.want_binary_analysis) {
                node.extra.binary_analysis = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(Node.BinaryAnalysis),
                    @alignOf(Node.BinaryAnalysis),
                ));
            }
            if (builder_spec.options.add_stack_traces_to_debug_executables) {
                if (node.flags.want_stack_traces) {
                    if (!node.hasDebugInfo()) {
                        node.tasks.cmd.build.strip = false;
                    }
                    node.dependOn(allocator, node.sh.extns.stack_traces);
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
                    (node.flags.is_group and node.lists.nodes.len > 2) or
                    (!node.flags.is_group and node.lists.depns.len > 1))
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
                        node.addCmdArg(allocator).* = builtin.zero([*:0]u8);
                        node.lists.cmd_args.len -%= 1;
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
            var allocator: types.Allocator = types.Allocator.fromArena(AddressSpace.arena(arena_index));
            executeCommandDependencies(address_space, thread_space, &allocator, node, task, arena_index);
            while (waitForNode(node, task, arena_index)) {
                time.sleep(sleep, builder_spec.options.timeout);
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
            allocator: *types.Allocator,
            node: *Node,
            task: Task,
            arena_index: AddressSpace.Index,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            executeCommandDependencies(address_space, thread_space, allocator, node, task, arena_index);
            const save: usize = allocator.next;
            while (waitForNode(node, task, arena_index)) {
                time.sleep(sleep, builder_spec.options.timeout);
            }
            if (node.lock.get(task) == .working) {
                if (executeCommand(allocator, node, task, arena_index)) {
                    allocator.next = save;
                    assertExchange(node, task, .working, .finished, arena_index);
                } else {
                    allocator.next = save;
                    assertExchange(node, task, .working, .failed, arena_index);
                }
            } else {
                allocator.next = save;
            }
        }
        pub fn executeSubNode(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *types.Allocator,
            node: *Node,
            task: Task,
        ) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (exchange(node, task, .ready, .blocking, max_thread_count)) {
                tryAcquireThread(address_space, thread_space, allocator, node, task, max_thread_count);
            }
            if (builder_spec.options.max_thread_count != 0) {
                while (thread_space.count() != 0) {
                    time.sleep(sleep, builder_spec.options.timeout);
                }
            }
            return node.lock.get(task) == .finished;
        }
        fn finishUp(node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            writeCacheBytes(node, "tab", @ptrCast(node.sh.fp), @sizeOf(FunctionPointers));
            writeCacheBytes(node, "prog", @ptrFromInt(node.sh.dl.lb_prog_addr), node.sh.dl.ub_prog_addr -% node.sh.dl.lb_prog_addr);
            writeCacheBytes(node, "meta", @ptrFromInt(node.sh.dl.lb_meta_addr), node.sh.dl.ub_meta_addr -% node.sh.dl.lb_meta_addr);
        }
        fn writeCacheBytes(node: *Node, name: [:0]const u8, buf: [*]u8, len: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = file.createAt(create, create_truncate_options, node.cacheRootFd(), name, file.mode.regular);
            file.write(write, fd, buf[0..len]);
            file.close(close, fd);
        }
        fn mapImmediate(allocator: *types.Allocator, node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (!(have_lazy and node.flags.is_dynamic_extension)) {
                return;
            }
            const fs: *types.File = node.getFile(.{ .tag = .output_lib }) orelse {
                return;
            };
            node.lists.paths[fs.path_idx].status(stat, fs.st);
            if (fs.st.mode.kind == .unknown) {
                return;
            }
            const save: usize = allocator.next;
            var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(4097, 1));
            var len: usize = node.lists.paths[fs.path_idx].formatWriteBuf(buf) -% 1;
            node.sh.dl.load(buf[0..len :0])(node.sh.fp);
            allocator.next = save;
            if (builder_spec.options.init_load_ok) {
                assertExchange(node, .build, .ready, .finished, max_thread_count);
            }
        }
        fn mapCacheBytes(node: *Node, name: [:0]const u8, prot: file.Map.Protection, addr: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (node.sh.top.extra.file_stats) |file_stats| {
                mem.zero(file.Status, &file_stats.cached);
                file.statusAt(stat, .{}, node.cacheRootFd(), name, &file_stats.cached);
                if (file_stats.cached.mode.kind == .regular) {
                    const fd: usize = file.openAt(open(), open_options, node.cacheRootFd(), name);
                    const len: usize = bits.alignA4096(file_stats.cached.size);
                    file.map(map, prot, .{ .fixed = true }, fd, addr, len, 0);
                    file.close(close, fd);
                    return addr +% len;
                }
            }
            return 0;
        }
        fn system(node: *Node, exe: [:0]const u8, args: [][*:0]u8, vars: [][*:0]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_perf and node.flags.want_perf_events) {
                startPerf(node);
            }
            node.extra.time = time.get(clock, .realtime);
            const pid: u64 = proc.fork(fork);
            if (pid == 0) {
                file.execPath(execve, exe, args, vars);
            }
            const ret: proc.Return = proc.waitPid(waitpid, .{ .pid = pid });
            node.extra.execve_res.status = proc.Status.exitStatus(ret.status);
            node.extra.execve_res.signal = proc.Status.termSignal(ret.status);
            node.extra.time = time.diff(time.get(clock, .realtime), node.extra.time);
            if (have_perf and node.flags.want_perf_events) {
                stopPerf(node);
            }
        }
        fn installFromCache(node: *Node, output_pathname: [:0]const u8, cached_pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            const output: *file.Status = node.getFile(.{ .tag = .output_generic }).?.st;
            const cached: *file.Status = node.getFile(.{ .tag = .cached_generic }).?.st;
            if (!file.sameFile(stat, output, output_pathname, cached, cached_pathname)) {
                if (have_size and
                    node.flags.want_binary_analysis)
                {
                    if (output.mode.kind == .regular and output.size != 0) {
                        node.extra.binary_analysis.before = node.sh.dl.load(output_pathname);
                    }
                    if (cached.mode.kind == .regular and cached.size != 0) {
                        node.extra.binary_analysis.after = node.sh.dl.load(cached_pathname);
                    }
                }
                file.unlink(unlink, output_pathname);
                file.link(link, cached_pathname, output_pathname);
            } else if (have_size and
                node.flags.want_binary_analysis)
            {
                if (cached.mode.kind == .regular and cached.size != 0) {
                    node.extra.binary_analysis.after = node.sh.dl.load(cached_pathname);
                }
            }
        }
        fn startPerf(node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (defined(node.sh.fp.about.perf.openFds)) {
                    node.sh.fp.about.perf.openFds(node.extra.perf_events);
                }
            } else {
                node.extra.perf_events.openFds();
            }
        }
        fn stopPerf(node: *Node) void {
            @setRuntimeSafety(builtin.is_safe);
            if (have_lazy) {
                if (defined(node.sh.fp.about.perf.readResults)) {
                    node.sh.fp.about.perf.readResults(node.extra.perf_events);
                }
            } else {
                node.extra.perf_events.readResults();
            }
        }
        fn serverOpen(node: *Node, args: [][*:0]u8, in: file.Pipe, out: file.Pipe) usize {
            if (have_perf) {
                if (node.flags.want_perf_events and node.flags.is_primary) {
                    startPerf(node);
                }
            }
            node.extra.time = time.get(clock, .realtime);
            const pid: usize = proc.fork(fork);
            if (pid == 0) {
                file.close(close, in.write);
                file.close(close, out.read);
                file.duplicateTo(dup3, .{}, in.read, 0);
                file.duplicateTo(dup3, .{}, out.write, 1);
                file.execPath(execve, node.zigExe(), args, node.sh.vars);
            }
            file.close(close, in.read);
            file.close(close, out.write);
            file.write(write2, in.write, update_exit_message[0..1]);
            return pid;
        }
        fn serverClose(node: *Node, in: file.Pipe, out: file.Pipe, pid: usize) void {
            const rc: proc.Return = proc.waitPid(waitpid, .{ .pid = pid });
            node.extra.execve_res.status = proc.Status.exitStatus(rc.status);
            node.extra.execve_res.signal = proc.Status.termSignal(rc.status);
            node.extra.time = time.diff(time.get(clock, .realtime), node.extra.time);
            if (have_perf and node.flags.want_perf_events and
                node.flags.is_primary)
            {
                stopPerf(node);
            }
            file.close(close, in.write);
            file.close(close, out.read);
        }
        fn serverLoop(allocator: *types.Allocator, node: *Node, dest_pathname: [:0]const u8, in: file.Pipe, out: file.Pipe) void {
            var hdr: Message.ServerHeader = undefined;
            var fd: [1]file.PollFd = .{.{ .fd = out.read, .expect = .{ .input = true } }};
            while (try meta.wrap(file.poll(poll, &fd, builder_spec.options.timeout_milliseconds))) {
                file.readOne(read3, out.read, &hdr);
                const buf: [*:0]u8 = @ptrFromInt(allocator.allocateRaw(hdr.bytes_len +% 1, 1));
                var len: usize = 0;
                while (len != hdr.bytes_len) {
                    len +%= file.read(read, out.read, buf[len..hdr.bytes_len]);
                }
                buf[len] = 0;
                if (hdr.tag == .emit_bin_path) {
                    node.extra.execve_res.server = buf[0];
                    break installFromCache(node, dest_pathname, mem.terminate(buf + 1, 0));
                }
                if (hdr.tag == .error_bundle) {
                    node.extra.execve_res.server = builder_spec.options.compiler_error_status;
                    break about.printErrors(allocator, node, buf);
                }
            }
            if (fd[0].actual.hangup) {
                node.extra.execve_res.server = builder_spec.options.compiler_unexpected_status;
            }
            if (node.extra.execve_res.server != builder_spec.options.compiler_unexpected_status) {
                file.write(write2, in.write, update_exit_message[1..2]);
            }
        }
        /// Despite having futexes (`proc.futex*`) this implementation opts for
        /// periodic scans with sleeping, because the task lock is not a perfect
        /// fit with futexes (u32). Extensions to `ThreadSafeSet` would permit.
        fn waitForNode(node: *Node, task: Task, arena_index: AddressSpace.Index) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (node.lock.get(task) == .blocking) {
                if (node.lists.depns.len != 0) {
                    if (testDeps(node, task, .failed) or
                        testDeps(node, task, .cancelled))
                    {
                        if (exchange(node, task, .blocking, .failed, arena_index)) {
                            exchangeDeps(node, task, .ready, .cancelled, arena_index);
                            exchangeDeps(node, task, .blocking, .cancelled, arena_index);
                        }
                        return false;
                    }
                    if (testDeps(node, task, .working) or
                        testDeps(node, task, .blocking))
                    {
                        return true;
                    }
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
                if (builder_spec.logging.show_high_level_summary) {
                    if (new_state == .finished) {
                        node.sh.finished +%= 1;
                    }
                }
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
            const ret: bool = node.lock.atomicExchange(task, old_state, new_state);
            if (ret) {
                if (builder_spec.logging.show_high_level_summary) {
                    if (new_state == .finished) {
                        node.sh.finished +%= 1;
                    }
                }
                node.sh.errors +%= @intFromBool(count_errors and new_state == .failed);
                if (builder_spec.logging.show_task_update) {
                    about.exchangeNotice(node, task, old_state, new_state, arena_index);
                }
            } else {
                if (builder_spec.logging.show_task_update) {
                    about.noExchangeNotice(node, task, old_state, new_state, arena_index);
                }
            }
            if (!ret) {
                proc.exitError(error.NoExchange, 2);
            }
        }
        fn testDeps(node: *const Node, task: Task, state: State) bool {
            @setRuntimeSafety(builtin.is_safe);
            if (!node.flags.is_group) {
                for (node.lists.depns) |*dep| {
                    if (node.lists.nodes[dep.node] == node and dep.on_task == task) {
                        continue;
                    }
                    if (node.lists.nodes[dep.node].lock.get(dep.on_task) == state) {
                        return true;
                    }
                }
            } else {
                for (node.lists.nodes[1..]) |sub_node| {
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
            const deps: []Node.Depn = node.lists.depns;
            const nodes: []*Node = node.lists.nodes;
            for (deps) |*dep| {
                if (nodes[dep.node] == node and dep.on_task == task) {
                    continue;
                }
                if (nodes[dep.node].lock.get(dep.on_task) != from) {
                    continue;
                }
                if (!exchange(nodes[dep.node], dep.on_task, from, to, arena_index)) {
                    return;
                }
            }
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
        fn status(stats: Node.ExecveResults) bool {
            if (stats.server == builder_spec.options.compiler_error_status or
                stats.server == builder_spec.options.compiler_unexpected_status)
            {
                return false;
            }
            return stats.status == builder_spec.options.system_expected_status;
        }
        pub fn processCommands(
            address_space: *AddressSpace,
            thread_space: *ThreadSpace,
            allocator: *types.Allocator,
            group: *Node,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            group.sh.mode = .Command;
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
                        for (node.lists.nodes[1..]) |sub_node| {
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
                        return about.writeAndWalk(allocator, node, .full);
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
                    const args_node: *Node = if (node.flags.is_group) node else node.lists.nodes[0];
                    cmd_args_idx +%= 1;
                    var run_args_idx: usize = cmd_args_idx;
                    while (run_args_idx != args.len) : (run_args_idx +%= 1) {
                        if (mem.testEqualString(
                            builder_spec.options.append_run_args_string,
                            mem.terminate(args[run_args_idx], 0),
                        )) {
                            args_node.lists.cmd_args = args[cmd_args_idx..run_args_idx];
                            run_args_idx +%= 1;
                            args_node.lists.run_args = args[run_args_idx..];
                            break;
                        }
                    } else {
                        args_node.lists.cmd_args = args[cmd_args_idx..];
                    }
                    if (builder_spec.logging.show_user_input) {
                        about.commandLineNotice(node);
                    }
                    node.sh.mode = .Exec;
                    recursiveAction(address_space, thread_space, allocator, node, task, max_thread_count, &prepareCommand);
                    const nodes: []*Node = node.sh.top.lists.nodes;
                    for (node.sh.top.lists.depns) |depn| {
                        if (!executeSubNode(address_space, thread_space, allocator, nodes[depn.node], depn.on_task)) {
                            proc.exitError(error.UnfinishedRequest, 2);
                        }
                    }
                    if (!executeSubNode(address_space, thread_space, allocator, node, task)) {
                        proc.exitError(error.UnfinishedRequest, 2);
                    }
                    if (builder_spec.logging.show_high_level_summary) {
                        about.writeErrorsAndFinished(group);
                    }
                    break;
                } else {
                    break;
                }
            } else {
                about.writeAndWalk(allocator, group, .basic);
            }
            group.sh.dl.unmapAll();
        }
        pub const about = struct {
            fn writeErrorsAndFinished(group: *Node) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                ptr[0..finished_s.len].* = finished_s.*;
                ptr += finished_s.len;
                ptr = fmt.Ud64.write(ptr, group.sh.finished);
                ptr[0] = '\n';
                ptr += 1;
                ptr[0..errors_s.len].* = errors_s.*;
                ptr += errors_s.len;
                ptr = fmt.Ud64.write(ptr, group.sh.errors);
                ptr[0] = '\n';
                ptr += 1;
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
                debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
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
                    debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
                }
            }
            fn lengthArenaIndex(arena_index: AddressSpace.Index) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (arena_index == max_thread_count) {
                    return 0;
                }
                return 2 +% fmt.Ud64.length(arena_index) +% 1;
            }
            fn writeArenaIndex(buf: [*]u8, arena_index: AddressSpace.Index) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (arena_index != max_thread_count) {
                    ptr[0..2].* = " [".*;
                    ptr = fmt.Ud64.write(ptr + 2, arena_index);
                    ptr[0] = ']';
                    ptr += 1;
                }
                return ptr;
            }
            fn lengthTask(allocator: *types.Allocator, node: *Node, task: Task, arena_index: AddressSpace.Index) usize {
                @setRuntimeSafety(builtin.is_safe);
                const about_s: fmt.AboutSrc = switch (task) {
                    else => if (node.tasks.tag == .build) build_run_s else exec_s,
                    .archive => ar_s,
                    .format => fmt_s,
                    .build => if (node.flags.have_task_data) switch (node.tasks.cmd.build.kind) {
                        .exe => build_exe_s,
                        .obj => build_obj_s,
                        .lib => build_lib_s,
                    } else build_lib_s,
                };
                const width: usize = fmt.aboutCentre(about_s);
                const signal: sys.SignalCode = @enumFromInt(node.extra.execve_res.signal);
                var len: usize = about_s.len;
                len +%= node.formatLengthNameFull();
                if (task == .build) {
                    if (builder_spec.logging.show_output_destination and
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_cache_hit_status or
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_expected_status)
                    {
                        len +%= 4;
                        len +%= node.lists.paths[0].lengthDisplay();
                    }
                    if (node.flags.have_task_data) {
                        len +%= 2;
                        switch (node.tasks.cmd.build.mode orelse .Debug) {
                            .Debug => {
                                len +%= 7;
                            },
                            .ReleaseSmall => {
                                len +%= 14;
                            },
                            .ReleaseFast => {
                                len +%= 13;
                            },
                            .ReleaseSafe => {
                                len +%= 13;
                            },
                        }
                        if (node.hasDebugInfo()) len +%= 2;
                        len +%= 8;
                    }
                }
                len +%= 7;
                if (task == .build) {
                    switch (node.extra.execve_res.server) {
                        builder_spec.options.compiler_expected_status => {
                            if (node.flags.is_special) {
                                len +%= 17;
                            } else {
                                len +%= 8;
                            }
                        },
                        builder_spec.options.compiler_cache_hit_status => {
                            if (node.flags.is_special) {
                                return 0;
                            }
                            len +%= 7;
                        },
                        builder_spec.options.compiler_error_status => {
                            len +%= 7;
                        },
                        else => {
                            len +%= 8;
                        },
                    }
                    if (node.extra.execve_res.status != 0) {
                        len +%= 1 +% fmt.Ud64.length(node.extra.execve_res.status);
                    }
                    if (node.extra.execve_res.signal != builder_spec.options.system_expected_status) {
                        len +%= 4;
                        len +%= @tagName(signal).len;
                    }
                    len +%= 1;
                } else {
                    if (node.extra.execve_res.signal != 0) {
                        len +%= 1;
                        len +%= fmt.Ud64.length(node.extra.execve_res.status);
                        len +%= 4;
                        len +%= 1;
                    } else {
                        len +%= fmt.Ud64.length(node.extra.execve_res.status);
                    }
                }
                if (!node.flags.want_binary_analysis) {
                    if (have_size and
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_cache_hit_status or
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_expected_status)
                    {
                        if (node.getFile(.{ .tag = .output_generic })) |output| {
                            if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                                len +%= 2;
                                len +%= fmt.BloatDiff.length(output.st.size, cached.st.size);
                            }
                        }
                    }
                }
                if (!node.flags.want_perf_events) {
                    len +%= 2;
                    len +%= lengthWallTime(node.extra.time.sec);
                }
                if (builder_spec.logging.show_arena_index) {
                    len +%= lengthArenaIndex(arena_index);
                }
                len +%= 1;
                if (have_size and task == .build and
                    node.flags.want_binary_analysis and
                    node.flags.is_primary)
                {
                    len +%= lengthFileSizeStats(allocator, node, width);
                }
                if (have_perf and
                    node.flags.want_perf_events and
                    node.flags.is_primary)
                {
                    len +%= lengthTimingStats(node, &node.extra.time, @max(width, 4));
                }
                return len;
            }
            fn writeTask(buf: [*]u8, node: *Node, task: Task, arena_index: AddressSpace.Index) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                const about_s: fmt.AboutSrc = switch (task) {
                    else => if (node.tasks.tag == .build) build_run_s else exec_s,
                    .archive => ar_s,
                    .format => fmt_s,
                    .build => if (node.flags.have_task_data) switch (node.tasks.cmd.build.kind) {
                        .exe => build_exe_s,
                        .obj => build_obj_s,
                        .lib => build_lib_s,
                    } else build_lib_s,
                };
                const width: usize = fmt.aboutCentre(about_s);
                const signal: sys.SignalCode = @enumFromInt(node.extra.execve_res.signal);
                ptr[0..about_s.len].* = about_s.*;
                ptr += about_s.len;
                ptr += node.formatWriteNameFull('.', ptr);
                if (task == .build) {
                    if (builder_spec.logging.show_output_destination and
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_cache_hit_status or
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_expected_status)
                    {
                        ptr[0..4].* = " => ".*;
                        ptr += 4;
                        ptr += node.lists.paths[0].formatWriteBufDisplay(ptr);
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
                    switch (node.extra.execve_res.server) {
                        builder_spec.options.compiler_expected_status => {
                            if (node.flags.is_special) {
                                ptr[1..17].* = "\x1b[96mupdated\x1b[0m".*;
                                ptr += 17;
                            } else {
                                ptr[1..8].* = "updated".*;
                                ptr += 8;
                            }
                        },
                        builder_spec.options.compiler_cache_hit_status => {
                            if (node.flags.is_special) {
                                return buf;
                            }
                            ptr[1..7].* = "cached".*;
                            ptr += 7;
                        },
                        builder_spec.options.compiler_error_status => {
                            ptr[1..7].* = "failed".*;
                            ptr += 7;
                        },
                        else => {
                            ptr[1..8].* = "unknown".*;
                            ptr += 8;
                        },
                    }
                    if (node.extra.execve_res.status != 0) {
                        ptr[0] = ',';
                        ptr = fmt.Ud64.write(ptr + 1, node.extra.execve_res.status);
                    }
                    if (node.extra.execve_res.signal != builder_spec.options.system_expected_status) {
                        ptr[0..4].* = ",SIG".*;
                        ptr = fmt.strcpyEqu(ptr + 4, @tagName(signal));
                    }
                    ptr[0] = ']';
                    ptr += 1;
                } else {
                    if (node.extra.execve_res.signal != 0) {
                        ptr[0] = '[';
                        ptr = fmt.Ud64.write(ptr + 1, node.extra.execve_res.status);
                        ptr[0..4].* = ",SIG".*;
                        ptr = fmt.strcpyEqu(ptr + 4, @tagName(signal));
                        ptr[0] = ']';
                        ptr += 1;
                    } else {
                        ptr = fmt.Ud64.write(ptr, node.extra.execve_res.status);
                    }
                }
                if (!node.flags.want_binary_analysis) {
                    if (have_size and
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_cache_hit_status or
                        node.extra.execve_res.server ==
                        builder_spec.options.compiler_expected_status)
                    {
                        if (node.getFile(.{ .tag = .output_generic })) |output| {
                            if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                                ptr[0..2].* = ", ".*;
                                ptr += 2;
                                ptr = fmt.BloatDiff.write(ptr, output.st.size, cached.st.size);
                            }
                        }
                    }
                }
                if (!node.flags.want_perf_events) {
                    ptr[0..2].* = ", ".*;
                    ptr = writeWallTime(ptr + 2, node.extra.time.sec, node.extra.time.nsec);
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
                    ptr = writeTimingStats(ptr, node, &node.extra.time, @max(width, 4));
                }
                return ptr;
            }
            pub fn aboutTask(allocator: *types.Allocator, node: *Node, task: Task, arena_index: AddressSpace.Index) void {
                @setRuntimeSafety(builtin.is_safe);
                if (have_lazy and builtin.output_mode == .Exe) {
                    if (defined(node.sh.fp.about.generic.aboutTask)) {
                        node.sh.fp.about.generic.aboutTask(allocator, node, task, arena_index);
                    }
                    return;
                }
                const save: usize = allocator.next;
                defer allocator.next = save;
                const len: usize = lengthTask(allocator, node, task, arena_index) *% 2;
                const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len, 1));
                const ptr: [*]u8 = writeTask(buf, node, task, arena_index);
                debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(buf)]);
            }
            fn lengthTimingStats(node: *Node, ts: *time.TimeSpec, width: usize) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = fmt.SideBarSubHeadingFormat.length(width, "perf");
                len +%= lengthWallTime(ts.sec);
                len +%= 1;
                len +%= PerfEvents.lengthResults(node.extra.perf_events, width);
                return len;
            }
            fn writeTimingStats(buf: [*]u8, node: *Node, ts: *time.TimeSpec, width: usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarSubHeadingFormat.write(buf, width, "perf");
                ptr = writeWallTime(ptr, ts.sec, ts.nsec);
                ptr[0] = '\n';
                ptr += 1;
                ptr = PerfEvents.writeResults(node.extra.perf_events, width, ptr);
                return ptr;
            }
            fn lengthFileSizeStats(allocator: *types.Allocator, node: *Node, width: usize) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = fmt.SideBarSubHeadingFormat.length(width, "size");
                if (node.getFile(.{ .tag = .output_generic })) |output| {
                    if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                        len +%= fmt.BloatDiff.length(output.st.size, cached.st.size);
                        len +%= 1;
                    }
                } else if (node.getFile(.{ .tag = .output_generic })) |output| {
                    len +%= fmt.Bytes.length(output.st.size);
                    len +%= 1;
                }
                if (node.flags.want_binary_analysis) {
                    if (node.extra.binary_analysis.after) |*after| {
                        if (node.extra.binary_analysis.before) |*before| {
                            len +%= DynamicLoader.compare.compareElfInfo(&node.extra.binary_analysis.cmp, allocator, before, after, width);
                        } else {
                            len +%= DynamicLoader.compare.lengthElf(&node.extra.binary_analysis.cmp, allocator, after, width);
                        }
                    }
                }
                return len;
            }
            fn writeFileSizeStats(buf: [*]u8, node: *Node, width: usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarSubHeadingFormat.write(buf, width, "size");
                if (node.getFile(.{ .tag = .output_generic })) |output| {
                    if (node.getFile(.{ .tag = .cached_generic })) |cached| {
                        ptr = fmt.BloatDiff.write(ptr, output.st.size, cached.st.size);
                        ptr[0] = '\n';
                        ptr += 1;
                    }
                } else if (node.getFile(.{ .tag = .output_generic })) |output| {
                    ptr = fmt.Bytes.write(ptr, output.st.size);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                if (node.flags.want_binary_analysis) {
                    if (node.extra.binary_analysis.after) |*after| {
                        if (node.extra.binary_analysis.before) |*before| {
                            ptr = DynamicLoader.compare.writeElfDifferences(&node.extra.binary_analysis.cmp, ptr, before, after, width);
                        } else {
                            ptr = DynamicLoader.compare.writeElf(&node.extra.binary_analysis.cmp, ptr, after, width);
                        }
                    }
                }
                return ptr;
            }
            pub fn commandLineNotice(node: *Node) void {
                @setRuntimeSafety(builtin.is_safe);
                if (!node.flags.is_group) {
                    return commandLineNotice(node.lists.nodes[0]);
                }
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                const cmd_args: [][*:0]u8 = node.lists.cmd_args;
                if (cmd_args.len != 0) {
                    ptr[0..cmd_args_s.len].* = cmd_args_s.*;
                    ptr += cmd_args_s.len;
                    ptr = file.about.writeArgs(ptr, &.{}, cmd_args);
                    ptr[0] = '\n';
                    ptr += 1;
                }
                const run_args: [][*:0]u8 = node.lists.run_args;
                if (run_args.len != 0) {
                    ptr[0..run_args_s.len].* = run_args_s.*;
                    ptr += run_args_s.len;
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
            const ListMode = enum {
                basic,
                files,
                depns,
                full,
            };
            pub fn writeAndWalk(allocator: *types.Allocator, node: *Node, mode: ListMode) void {
                @setRuntimeSafety(builtin.is_safe);
                const save: usize = allocator.save();
                var buf1: [4096]u8 = undefined;
                var width: ColumnWidth align(64) = .{ .cols = .{} };
                writeAndWalkColumnWidths(0, node, &width, mode);
                const is_top: bool = node.flags.is_top;
                defer node.flags.is_top = is_top;
                node.flags.is_top = true;
                width.vec +%= @splat(5);
                width.vec &= @splat(~@as(u16, 3));
                width.cols.name = @max(width.cols.name, width.cols.file);
                width.cols.file = width.cols.name;
                const max_len: usize = node.name.len +% 1 +% lengthAndWalkInternal(0, node, &width, mode) +% 4096;
                const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(max_len, 1));
                @memset(buf0[0..max_len], '@');
                var ptr0: [*]u8 = fmt.strcpyEqu(buf0, node.name);
                ptr0[0] = '\n';
                ptr0 = writeAndWalkInternal(ptr0 + 1, &buf1, 0, node, &width, mode);
                debug.write(buf0[0 .. @intFromPtr(ptr0) -% @intFromPtr(buf0)]);
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
            fn writeAndWalkColumnWidths(len1: usize, node: *const Node, width: *ColumnWidth, mode: ListMode) void {
                @setRuntimeSafety(builtin.is_safe);
                var itr: Node.Iterator = Node.Iterator.init(node);
                var buf: [4096:0]u8 = undefined;
                if (mode == .full or mode == .files or node.flags.is_top) {
                    for (node.lists.files) |*fs| {
                        width.cols.file = @intCast(@max(width.cols.file, len1 +% 4 +% @tagName(fs.key.tag).len));
                        if (node.getFilePath(fs)) |path| {
                            width.cols.path = @intCast(@max(width.cols.path, path.formatWriteBufDisplay(&buf)));
                        }
                    }
                }
                while (itr.next()) |next_node| {
                    if (mode == .full or mode == .depns or next_node.flags.is_group) {
                        writeAndWalkColumnWidths(len1 +% 2, next_node, width, mode);
                    }
                    width.cols.name = @intCast(@max(width.cols.name, len1 +% 4 +% next_node.name.len));
                    width.cols.descr = @intCast(@max(width.cols.descr, next_node.descr.len));
                }
            }
            fn lengthAndWalkInternal(len1: usize, node: *Node, width: *ColumnWidth, mode: ListMode) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = 0;
                var itr: Node.Iterator = Node.Iterator.init(node);
                if (mode == .full or mode == .files or node.flags.is_top) {
                    for (node.lists.files) |*fs| {
                        len +%= len1 +% 2;
                        if (node.getFilePath(fs) != null) {
                            len +%= 2 +% width.cols.file;
                        }
                        len +%= 1;
                    }
                }
                while (itr.next()) |next_node| {
                    len +%= len1 +% 7 +% width.cols.name +% width.cols.descr;
                    if (mode == .full or mode == .depns or next_node.flags.is_group) {
                        len +%= lengthAndWalkInternal(len1 +% 2, next_node, width, mode);
                    }
                }
                return len;
            }
            fn writeAndWalkInternal(buf0: [*]u8, buf1: [*]u8, len1: usize, node: *Node, width: *ColumnWidth, mode: ListMode) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var itr: Node.Iterator = Node.Iterator.init(node);
                var ptr1: [*]u8 = buf1 + len1;
                var ptr0: [*]u8 = buf0;
                if (mode == .full or mode == .files or node.flags.is_top) {
                    for (node.lists.files) |*fs| {
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
                    ptr0 += 1;
                    if (mode == .full or mode == .depns or next_node.flags.is_group) {
                        ptr0 = writeAndWalkInternal(ptr0, buf1, len1 +% 2, next_node, width, mode);
                    }
                }
                return ptr0;
            }
            pub fn printErrors(allocator: *types.Allocator, node: *Node, msg: [*:0]u8) void {
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
                    .Init => return init_s,
                    .Main => return main_s,
                    .Command => return cmdline_s,
                    .Exec => return exec_s,
                    .Regen => return regen_s,
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
                allocate: enum { binary_analysis, perf_events },
            };
            fn aboutNode(node: *Node, by_spec: ?SpecTag, by_flag: ?FlagTag, event: About) void {
                @setRuntimeSafety(builtin.is_safe);
                const about_s: fmt.AboutSrc = switch (node.sh.mode) {
                    .Init => init_s,
                    .Main => main_s,
                    .Command => cmdline_s,
                    .Exec => exec_s,
                    .Regen => regen_s,
                };
                var buf: [4096]u8 = undefined;
                buf[0..about_s.len].* = about_s.*;
                var ptr: [*]u8 = buf[about_s.len..];
                ptr += node.formatWriteNameFull('.', ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (by_spec) |which| {
                    ptr[0..5].* = "spec.".*;
                    ptr = fmt.strcpyEqu(ptr + 5, @tagName(which));
                    ptr[0..4].* = " => ".*;
                    ptr += 4;
                }
                if (by_flag) |which| {
                    ptr[0..5].* = "flag.".*;
                    ptr = fmt.strcpyEqu(ptr + 5, @tagName(which));
                    ptr[0..4].* = " => ".*;
                    ptr += 4;
                }
                switch (event) {
                    .add_cmd_arg => {
                        const cmd_args: [][*:0]u8 = node.lists.cmd_args;
                        const idx: usize = cmd_args.len -% 1;
                        ptr[0..9].* = "run_args[".*;
                        ptr = fmt.Ud64.write(ptr + 9, idx);
                        ptr[0..2].* = "]=".*;
                        ptr = fmt.strcpyEqu(ptr + 2, mem.terminate(cmd_args[idx], 0));
                    },
                    .add_run_arg => {
                        const run_args: [][*:0]u8 = node.lists.run_args;
                        const idx: usize = run_args.len -% 1;
                        ptr[0..9].* = "run_args[".*;
                        ptr = fmt.Ud64.write(ptr + 9, idx);
                        ptr[0..2].* = "]=".*;
                        ptr = fmt.strcpyEqu(ptr + 2, mem.terminate(run_args[idx], 0));
                    },
                    .add_file => {
                        const files = node.lists.files;
                        const idx: usize = files.len -% 1;
                        ptr = fmt.strcpyEqu(ptr, @tagName(files[idx].key.tag));
                        ptr[0..3].* = ", [".*;
                        ptr = fmt.Ud64.write(ptr + 3, idx);
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
                            .binary_analysis => @intFromPtr(node.extra.binary_analysis),
                            .perf_events => @intFromPtr(node.extra.perf_events),
                        };
                        ptr[0..6].* = "extra.".*;
                        ptr = fmt.strcpyEqu(ptr + 6, @tagName(field));
                        ptr[0] = '=';
                        ptr = fmt.Ux64.write(ptr + 1, addr);
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
                            ptr = fmt.strcpyEqu(ptr + 12, dependency.name);
                            ptr[0..16].* = "\":?[:0]const u8=".*;
                            ptr += 16;
                            if (dependency.import.len != 0) {
                                ptr[0] = '"';
                                ptr = fmt.strcpyEqu(ptr + 1, dependency.import);
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
                            ptr = fmt.strcpyEqu(ptr + 12, module.name);
                            ptr[0..15].* = "\":[:0]const u8=".*;
                            ptr[15] = '"';
                            ptr = fmt.strcpyEqu(ptr + 16, module.path);
                            ptr[0..3].* = "\";\n".*;
                            ptr += 3;
                        }
                    }
                }
                for (&[3]types.BinaryOutput{ .obj, .lib, .exe }) |out| {
                    ptr[0..13].* = "};\npub const ".*;
                    ptr = fmt.strcpyEqu(ptr + 13, switch (out) {
                        .obj => "compile",
                        .lib => "dynamic",
                        .exe => "executable",
                    });
                    ptr[0..52].* = "_units=[_]struct{@Type(.EnumLiteral),[:0]const u8}{\n".*;
                    ptr += 52;
                    for (node.lists.depns) |dep| {
                        if (dep.on_task == .build and
                            node.lists.nodes[dep.node] != node and
                            node.lists.nodes[dep.node].flags.have_task_data and
                            node.lists.nodes[dep.node].tasks.cmd.build.kind == out)
                        {
                            ptr[0..4].* = ".{.@".*;
                            ptr += 4;
                            ptr += fmt.stringLiteral(node.lists.nodes[dep.node].name).formatWriteBuf(ptr);
                            ptr[0..2].* = ",\"".*;
                            ptr += 2;
                            ptr += node.lists.nodes[dep.node].lists.paths[0].formatWriteBufLiteral(ptr);
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
                ptr = fmt.strcpyEqu(ptr + 2, @tagName(new));
                ptr[0] = '}';
                return ptr + 1;
            }
            fn writeExchangeTask(buf: [*]u8, node: *Node, task: Task) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const about_s: fmt.AboutSrc = switch (node.sh.mode) {
                    .Init => init_s,
                    .Main => main_s,
                    .Command => cmdline_s,
                    .Exec => exec_s,
                    .Regen => regen_s,
                };
                buf[0..about_s.len].* = about_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf + about_s.len, node.name);
                ptr[0] = '.';
                return fmt.strcpyEqu(ptr + 1, @tagName(task));
            }
        };
    };
    return T;
}
fn lengthWallTime(sec: usize) usize {
    return fmt.Ud64.length(sec) +% 5;
}
fn writeWallTime(buf: [*]u8, sec: usize, nsec: usize) [*]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = fmt.Ud64.write(buf, sec);
    ptr[0..4].* = ".000".*;
    const figs: usize = fmt.sigFigLen(usize, nsec, 10);
    _ = fmt.Ud64.write(ptr + 10 - figs, nsec);
    ptr[4] = 's';
    return ptr + 5;
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
pub fn duplicate(allocator: *types.Allocator, values: []const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    if (@intFromPtr(values.ptr) < 0x40000000) {
        return @constCast(values.ptr)[0..values.len :0];
    }
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(values.len +% 1, 1));
    @memcpy(buf, values);
    buf[values.len] = 0;
    return buf[0..values.len :0];
}
fn makeCommandName(allocator: *types.Allocator, root: [:0]const u8) [:0]const u8 {
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
pub fn concatenate(allocator: *types.Allocator, values: []const []const u8) [:0]u8 {
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
pub fn makeArgPtrs(allocator: *types.Allocator, args: [:0]u8) [][*:0]u8 {
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
                .futex = .{ .abort = proc.spec.futex.errors.all_timeout },
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
                .futex = .{ .throw = proc.spec.futex.errors.all_timeout },
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
            break :blk tmp;
        };
        pub const default: BuilderSpec.Logging = .{
            .write = .{},
            .read = .{},
            .mknod = .{},
            .dup3 = .{},
            .pipe = .{},
            .futex = .{},
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
