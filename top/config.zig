pub const zig = @import("builtin");
pub const root = @import("root");
pub const env = @import("env");
pub const native_endian = zig.cpu.arch.endian();
pub const is_little: bool = native_endian == .Little;
pub const is_big: bool = native_endian == .Big;
/// * Determines defaults for various allocator checks.
pub const is_safe: bool = define("is_safe", bool, zig.mode == .ReleaseSafe);
pub const is_small: bool = define("is_small", bool, zig.mode == .ReleaseSmall);
pub const is_fast: bool = define("is_fast", bool, zig.mode == .ReleaseFast);
/// * Determines whether `Acquire` and `Release` actions are logged by default.
/// * Determine whether signals for floating point errors should be handled verbosely.
pub const is_debug: bool = define("is_debug", bool, zig.mode == .Debug);
/// * Determines whether calling `panicUnwrapError` is legal.
pub const discard_errors: bool = define("discard_errors", bool, !(is_debug or is_safe));
/// * Determines whether `assert*` functions will be called at runtime.
pub const runtime_assertions: bool = define("runtime_assertions", bool, is_debug or is_safe);
/// * Determines whether `static.assert*` functions will be called at comptime time.
pub const comptime_assertions: bool = define("comptime_assertions", bool, is_debug);
/// The values define the default field values for all Logging sub-types used in
/// generic specifications.
pub const logging_default: Logging.Default = define(
    "logging_default",
    Logging.Default,
    .{ .Attempt = false, .Success = false, .Acquire = is_debug, .Release = is_debug, .Error = true, .Fault = true },
);
pub const logging_override: Logging.Override = define(
    "logging_override",
    Logging.Override,
    .{ .Attempt = null, .Success = null, .Acquire = null, .Release = null, .Error = null, .Fault = null },
);
pub const logging_general: Logging.Default = .{
    .Attempt = logging_override.Attempt orelse logging_default.Attempt,
    .Success = logging_override.Success orelse logging_default.Success,
    .Acquire = logging_override.Acquire orelse logging_default.Acquire,
    .Release = logging_override.Release orelse logging_default.Release,
    .Error = logging_override.Error orelse logging_default.Error,
    .Fault = logging_override.Fault orelse logging_default.Fault,
};
pub const signal_handlers: SignalHandlers = define(
    "signal_handlers",
    SignalHandlers,
    .{
        .segmentation_fault = logging_general.Fault,
        .illegal_instruction = logging_general.Fault,
        .bus_error = logging_general.Fault,
        .floating_point_error = logging_general.Fault,
    },
);
// These are defined by the library builder
const root_src_file: [:0]const u8 = define("root_src_file", [:0]const u8, undefined);
/// Return an absolute path to a project file.
pub fn absolutePath(comptime relative: [:0]const u8) [:0]const u8 {
    return env.build_root ++ "/" ++ relative;
}
/// Returns an absolute path to the compiler used to compile this program.
pub fn zigExe() [:0]const u8 {
    if (env.zig_exe[0] != '/') {
        @compileError("'" ++ env.zig_exe ++ "' must be an absolute path");
    }
    return env.zig_exe;
}
/// Returns an absolute path to the project root directory.
pub fn buildRoot() [:0]const u8 {
    if (env.build_root[0] != '/') {
        @compileError("'" ++ env.build_root ++ "' must be an absolute path");
    }
    return env.build_root;
}
/// Returns an absolute path to the project cache directory.
pub fn cacheDir() [:0]const u8 {
    if (env.cache_dir[0] != '/') {
        @compileError("'" ++ env.cache_dir ++ "' must be an absolute path");
    }
    return env.cache_root;
}
/// Returns an absolute path to the user (global) cache directory.
pub fn globalCacheDir() [:0]const u8 {
    if (env.global_cache_root[0] != '/') {
        @compileError("'" ++ env.global_cache_root ++ "' must be an absolute path");
    }
    return env.global_cache_root;
}
/// The primary reason that these constants exist is to distinguish between
/// reports from the build runner and reports from a run command.
///
/// The length of this string does not count to the length of the column.
/// Defining this string inserts `\x1b[0m` after the subject name.
pub const message_style: ?[:0]const u8 = define("message_style", ?[:0]const u8, null);
/// This text to the left of every subject name, to the right of the style.
pub const message_prefix: [:0]const u8 = define("message_prefix", [:0]const u8, "");
/// This text to the right of every string.
pub const message_suffix: [:0]const u8 = define("message_suffix", [:0]const u8, ":");
/// The total length of the subject column, to the left of the information column.
pub const message_indent: u8 = define("message_indent", u8, 16);
/// Sequence used to undo `message_style` if defined.
pub const message_no_style: [:0]const u8 = "\x1b[0m";
pub fn AddressSpace() type {
    if (!@hasDecl(root, "AddressSpace")) {
        @compileError(
            "toplevel address space required:\n" ++
                "declare 'pub const AddressSpace = <zig_lib>.spec.address_space.regular_128;' in program root\n" ++
                "address spaces are required by high level features with managed memory",
        );
    }
    return root.AddressSpace;
}
pub const SignalHandlers = packed struct {
    segmentation_fault: bool,
    illegal_instruction: bool,
    bus_error: bool,
    floating_point_error: bool,
};
pub const Logging = packed struct {
    pub const Default = packed struct {
        /// Report attempted actions
        Attempt: bool,
        /// Report major successful actions
        Success: bool,
        /// Report actions which acquire a finite resource
        Acquire: bool,
        /// Report actions which release a finite resource
        Release: bool,
        /// Report actions which throw an error
        Error: bool,
        /// Report actions which terminate the program
        Fault: bool,
    };
    pub const Override = struct {
        /// Report attempted actions
        Attempt: ?bool,
        /// Report major successful actions
        Success: ?bool,
        /// Report actions which acquire a finite resource
        Acquire: ?bool,
        /// Report actions which release a finite resource
        Release: ?bool,
        /// Report actions which throw an error
        Error: ?bool,
        /// Report actions which terminate the program
        Fault: ?bool,
    };
    pub const AttemptError = packed struct(u2) {
        Attempt: bool = logging_default.Attempt,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptError) AttemptError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessError = packed struct(u2) {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: SuccessError) SuccessError {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessError = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessError) AttemptSuccessError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireError = packed struct(u2) {
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AcquireError) AcquireError {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptAcquireError = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptAcquireError) AttemptAcquireError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessAcquireError = packed struct(u3) {
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: SuccessAcquireError) SuccessAcquireError {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessAcquireError = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessAcquireError) AttemptSuccessAcquireError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const ReleaseError = packed struct(u2) {
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: ReleaseError) ReleaseError {
            return .{
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptReleaseError = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptReleaseError) AttemptReleaseError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessReleaseError = packed struct(u3) {
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: SuccessReleaseError) SuccessReleaseError {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessReleaseError = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessReleaseError) AttemptSuccessReleaseError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireReleaseError = packed struct(u3) {
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AcquireReleaseError) AcquireReleaseError {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptAcquireReleaseError = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptAcquireReleaseError) AttemptAcquireReleaseError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessAcquireReleaseError = packed struct(u4) {
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: SuccessAcquireReleaseError) SuccessAcquireReleaseError {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessAcquireReleaseError = packed struct(u5) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessAcquireReleaseError) AttemptSuccessAcquireReleaseError {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptFault = packed struct(u2) {
        Attempt: bool = logging_default.Attempt,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptFault) AttemptFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessFault = packed struct(u2) {
        Success: bool = logging_default.Success,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessFault) SuccessFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessFault = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessFault) AttemptSuccessFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireFault = packed struct(u2) {
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireFault) AcquireFault {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireFault = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireFault) AttemptAcquireFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireFault = packed struct(u3) {
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireFault) SuccessAcquireFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireFault) AttemptSuccessAcquireFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseFault = packed struct(u2) {
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: ReleaseFault) ReleaseFault {
            return .{
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptReleaseFault = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptReleaseFault) AttemptReleaseFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessReleaseFault = packed struct(u3) {
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessReleaseFault) SuccessReleaseFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessReleaseFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessReleaseFault) AttemptSuccessReleaseFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireReleaseFault = packed struct(u3) {
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireReleaseFault) AcquireReleaseFault {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireReleaseFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireReleaseFault) AttemptAcquireReleaseFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireReleaseFault = packed struct(u4) {
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireReleaseFault) SuccessAcquireReleaseFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireReleaseFault = packed struct(u5) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireReleaseFault) AttemptSuccessAcquireReleaseFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ErrorFault = packed struct(u2) {
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: ErrorFault) ErrorFault {
            return .{
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptErrorFault = packed struct(u3) {
        Attempt: bool = logging_default.Attempt,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptErrorFault) AttemptErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessErrorFault = packed struct(u3) {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessErrorFault) SuccessErrorFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessErrorFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessErrorFault) AttemptSuccessErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireErrorFault = packed struct(u3) {
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireErrorFault) AcquireErrorFault {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireErrorFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireErrorFault) AttemptAcquireErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireErrorFault = packed struct(u4) {
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireErrorFault) SuccessAcquireErrorFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireErrorFault = packed struct(u5) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireErrorFault) AttemptSuccessAcquireErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseErrorFault = packed struct(u3) {
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: ReleaseErrorFault) ReleaseErrorFault {
            return .{
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptReleaseErrorFault = packed struct(u4) {
        Attempt: bool = logging_default.Attempt,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptReleaseErrorFault) AttemptReleaseErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessReleaseErrorFault = packed struct(u4) {
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessReleaseErrorFault) SuccessReleaseErrorFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessReleaseErrorFault = packed struct(u5) {
        Attempt: bool = logging_default.Attempt,
        Success: bool = logging_default.Success,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessReleaseErrorFault) AttemptSuccessReleaseErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Success = logging_override.Success orelse logging.Success,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireReleaseErrorFault = packed struct(u4) {
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireReleaseErrorFault) AcquireReleaseErrorFault {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireReleaseErrorFault = packed struct(u5) {
        Attempt: bool = logging_default.Attempt,
        Acquire: bool = logging_default.Acquire,
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireReleaseErrorFault) AttemptAcquireReleaseErrorFault {
            return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub fn Field(comptime Spec: type) type {
        return @TypeOf(@field(@as(Spec, undefined), "logging"));
    }
};
pub fn loggingTypes() []const type {
    var ret: []const type = &.{};
    var bits: u6 = 0;
    while (true) : (bits +%= 1) {
        var fields: @TypeOf(@typeInfo(Logging.Default).Struct.fields) = &.{};
        const logging: Logging.Default = @bitCast(Logging.Default, bits);
        inline for (@typeInfo(Logging.Default).Struct.fields) |field| {
            if (@field(logging, field.name)) {
                fields = fields ++ .{field};
            }
        }
        if (@popCount(bits) <= 1) {
            continue;
        }
        if (!logging.Error and !logging.Fault) {
            continue;
        }
        ret = ret ++ .{@Type(.{ .Struct = .{
            .layout = .Packed,
            .fields = fields,
            .decls = &.{},
            .is_tuple = false,
        } })};
        if (logging.Acquire and logging.Release and
            logging.Attempt and logging.Error and logging.Fault)
        {
            break;
        }
    }
    return ret;
}
pub fn define(
    comptime symbol: []const u8,
    comptime T: type,
    comptime default: anytype,
) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    }
    if (@typeInfo(@TypeOf(default)) != .Fn) {
        return default;
    }
    if (@TypeOf(default) != T) {
        return @call(.auto, default, .{});
    }
}
pub fn defineExtra(
    comptime symbol: []const u8,
    comptime T: type,
    comptime default: anytype,
    comptime args: anytype,
) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    } else if (@hasDecl(@cImport({}), symbol)) {
        const command = @field(@cImport({}), symbol);
        if (T == bool) {
            return @bitCast(T, @as(u1, command));
        }
        return command;
    } else if (@typeInfo(@TypeOf(default)) == .Fn) {
        return @call(.auto, default, args);
    }
    return default;
}
const debug = struct {
    const path = opaque {
        inline fn buildRoot() noreturn {
            @compileError(
                "program requires build root:\n" ++
                    "add '-Dbuild_root=<project_build_root>' to compile flags\n",
            );
        }
    };
    const address_space = opaque {
        inline fn defaultValue(comptime Struct: type) noreturn {
            @compileError(
                if (!@hasField(Struct, "AddressSpace"))
                    "expected field 'AddressSpace' in '" ++ @typeName(Struct) ++ "'"
                else
                    "toplevel address space required by default field value:\n" ++
                        "declare 'pub const AddressSpace = <zig_lib>.spec.address_space.regular_128;' in program root\n" ++
                        "initialize field 'AddressSpace' in '" ++ @typeName(Struct) ++ "' explicitly\n" ++
                        "address spaces are required by high level features with managed memory",
            );
        }
    };
};
