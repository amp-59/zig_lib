pub const zig = @import("builtin");
pub const root = @import("root");

pub const native_endian = zig.cpu.arch.endian();
pub const is_little: bool = native_endian == .Little;
pub const is_big: bool = native_endian == .Big;
pub const is_safe: bool = zig.mode == .ReleaseSafe;
pub const is_small: bool = zig.mode == .ReleaseSmall;
pub const is_fast: bool = zig.mode == .ReleaseFast;
pub const is_debug: bool = zig.mode == .Debug;
pub const runtime_assertions: bool = define("runtime_assertions", bool, is_debug or is_safe);
pub const comptime_assertions: bool = define("comptime_assertions", bool, is_debug);

pub const logging_default: Logging.Default = define(
    "logging_default",
    Logging.Default,
    .{ .Success = is_debug, .Acquire = is_debug, .Release = is_debug, .Error = true, .Fault = true },
);
pub const logging_override: Logging.Override = define(
    "logging_override",
    Logging.Override,
    .{ .Success = null, .Acquire = null, .Release = null, .Error = null, .Fault = null },
);
pub const logging_general: Logging.Default = .{
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
pub const zig_exe: ?[:0]const u8 = define("zig_exe", ?[:0]const u8, null);
pub const build_root: ?[:0]const u8 = define("build_root", ?[:0]const u8, null);
pub const cache_dir: ?[:0]const u8 = define("cache_dir", ?[:0]const u8, null);
pub const global_cache_dir: ?[:0]const u8 = define("global_cache_dir", ?[:0]const u8, null);
pub const root_src_file: ?[:0]const u8 = define("root_src_file", ?[:0]const u8, null);

pub const about_prefix: [:0]const u8 = "";
pub const about_suffix: [:0]const u8 = "";
pub const about_indent: [:0]const u8 = "\t\t";

pub fn AddressSpace() type {
    if (@hasDecl(root, "AddressSpace")) {
        return root.AddressSpace;
    }
    @compileError(
        "toplevel address space required:\n" ++
            debug.title_s ++ "declare 'pub const AddressSpace = <zig_lib>.preset.address_space.regular_128;' in program root\n" ++
            debug.title_s ++ "address spaces are required by high level features with managed memory",
    );
}
pub const SignalHandlers = packed struct {
    segmentation_fault: bool,
    illegal_instruction: bool,
    bus_error: bool,
    floating_point_error: bool,
};
pub const Logging = struct {
    pub const Default = packed struct {
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
    pub const SuccessError = packed struct {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        pub fn override(logging: SuccessError) SuccessError {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessFault = packed struct {
        Success: bool = logging_default.Success,
        Fault: bool = logging_default.Fault,
        pub fn override(logging: SuccessFault) SuccessFault {
            return .{
                .Success = logging_override.Success orelse logging.Success,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireError = packed struct {
        Acquire: bool = logging_default.Acquire,
        Error: bool = logging_default.Error,
        pub fn override(logging: AcquireError) AcquireError {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireFault = packed struct {
        Acquire: bool = logging_default.Acquire,
        Fault: bool = logging_default.Fault,
        pub fn override(logging: AcquireFault) AcquireFault {
            return .{
                .Acquire = logging_override.Acquire orelse logging.Acquire,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseError = packed struct {
        Release: bool = logging_default.Release,
        Error: bool = logging_default.Error,
        pub fn override(logging: ReleaseError) ReleaseError {
            return .{
                .Release = logging_override.Release orelse logging.Release,
                .Error = logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const ReleaseFault = packed struct {
        Release: bool = logging_default.Release,
        Fault: bool = logging_default.Fault,
        pub fn override(logging: ReleaseFault) ReleaseFault {
            return .{
                .Release = logging_override.Release orelse logging.Release,
                .Fault = logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessErrorFault = packed struct {
        Success: bool = logging_default.Success,
        Error: bool = logging_default.Error,
        Fault: bool = logging_default.Fault,
        pub fn override(logging: SuccessErrorFault) SuccessErrorFault {
            return .{
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
        pub fn override(logging: AcquireErrorFault) AcquireErrorFault {
            return .{
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
        pub fn override(logging: ReleaseErrorFault) ReleaseErrorFault {
            return .{
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
    if (@hasDecl(@cImport({}), symbol)) {
        const command = @field(@cImport({}), symbol);
        if (T == bool) {
            return @bitCast(T, @as(u1, command));
        }
        return command;
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
                        title_s ++ "declare 'pub const AddressSpace = <zig_lib>.preset.address_space.regular_128;' in program root\n" ++
                        point_s ++ "initialize field 'AddressSpace' in '" ++ @typeName(Struct) ++ "' explicitly\n" ++
                        title_s ++ "address spaces are required by high level features with managed memory",
            );
        }
    };
};
