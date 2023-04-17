pub const zig = @import("builtin");
pub const root = @import("root");
pub const env = @import("env");

pub const native_endian = zig.cpu.arch.endian();
pub const is_little: bool = native_endian == .Little;
pub const is_big: bool = native_endian == .Big;
pub const is_safe: bool = zig.mode == .ReleaseSafe;
pub const is_small: bool = zig.mode == .ReleaseSmall;
pub const is_fast: bool = zig.mode == .ReleaseFast;
pub const is_debug: bool = zig.mode == .Debug;
pub const runtime_assertions: bool = define("runtime_assertions", bool, is_debug or is_safe);
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
        .floating_point_error = is_debug,
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
    return env.cache_dir;
}
/// Returns an absolute path to the user (global) cache directory.
pub fn globalCacheDir() [:0]const u8 {
    if (env.global_cache_dir[0] != '/') {
        @compileError("'" ++ env.global_cache_dir ++ "' must be an absolute path");
    }
    return env.global_cache_dir;
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
                debug.title_s ++ "declare 'pub const AddressSpace = <zig_lib>.spec.address_space.regular_128;' in program root\n" ++
                debug.title_s ++ "address spaces are required by high level features with managed memory",
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
    pub const AttemptError = packed struct {
        Attempt: bool = logging_default.Attempt,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptError) AttemptError {
            return .{
                .Attempt = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptFault = packed struct {
        Attempt: bool = logging_default.Attempt,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptFault) AttemptFault {
            return .{
                .Attempt = logging_override.Success orelse logging.Success,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptErrorFault = packed struct {
        Attempt: bool = logging_default.Attempt,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AttemptErrorFault) AttemptErrorFault {
            comptime return .{
                .Attempt = logging_override.Attempt orelse logging.Attempt,
                .Fault = logging_override.Fault orelse logging.Fault,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessError = packed struct {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: SuccessError) SuccessError {
            comptime return .{
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessFault = packed struct {
        Success: bool = logging_default.Success,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessFault) SuccessFault {
            comptime return .{
                .Success = logging_override.Success orelse logging.Success,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireError = packed struct {
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: AcquireError) AcquireError {
            comptime return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireFault = packed struct {
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireFault) AcquireFault {
            comptime return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseError = packed struct {
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(comptime logging: ReleaseError) ReleaseError {
            comptime return .{
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const ReleaseFault = packed struct {
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: ReleaseFault) ReleaseFault {
            comptime return .{
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessErrorFault = packed struct {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: SuccessErrorFault) SuccessErrorFault {
            comptime return .{
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireErrorFault = packed struct {
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: AcquireErrorFault) AcquireErrorFault {
            comptime return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseErrorFault = packed struct {
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(comptime logging: ReleaseErrorFault) ReleaseErrorFault {
            comptime return .{
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
};

pub fn define(
    comptime symbol: []const u8,
    comptime T: type,
    comptime default: anytype,
) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    }
    if (@typeInfo(@TypeOf(default)) == .Fn and
        @TypeOf(default) != T)
    {
        return @call(.auto, default, .{});
    }
    return default;
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
    const title_s: []const u8 = "\r\t\x1b[96;1mnote\x1b[0;1m: ";
    const point_s: []const u8 = "\r\t    : ";
    const space_s: []const u8 = "\r\t       ";
    const path = opaque {
        inline fn buildRoot() noreturn {
            @compileError(
                "program requires build root:\n" ++
                    title_s ++ "add '-Dbuild_root=<project_build_root>' to compile flags\n",
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
                        title_s ++ "declare 'pub const AddressSpace = <zig_lib>.spec.address_space.regular_128;' in program root\n" ++
                        point_s ++ "initialize field 'AddressSpace' in '" ++ @typeName(Struct) ++ "' explicitly\n" ++
                        title_s ++ "address spaces are required by high level features with managed memory",
            );
        }
    };
};
