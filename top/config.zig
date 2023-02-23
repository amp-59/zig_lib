pub const zig = @import("builtin");
pub const root = @import("root");

pub const native_endian = zig.cpu.arch.endian();
pub const is_little: bool = native_endian == .Little;
pub const is_big: bool = native_endian == .Big;
pub const is_safe: bool = define("is_safe", bool, zig.mode == .ReleaseSafe);
pub const is_small: bool = define("is_small", bool, zig.mode == .ReleaseSmall);
pub const is_fast: bool = define("is_fast", bool, zig.mode == .ReleaseFast);
pub const is_debug: bool = define("is_debug", bool, zig.mode == .Debug);
pub const is_perf: bool = define("is_perf", bool, is_small or is_fast);
pub const is_verbose: bool = define("is_verbose", bool, is_debug);
pub const is_silent: bool = define("is_silent", bool, false);
pub const logging: Logging.Full = define("logging", Logging.Full, .{});
pub const runtime_assertions: bool = define("runtime_assertions", bool, is_debug or is_safe);
pub const comptime_assertions: bool = define("comptime_assertions", bool, is_debug);

// These are defined by the library builder
pub const zig_exe: ?[:0]const u8 = define("zig_exe", ?[:0]const u8, null);
pub const build_root: ?[:0]const u8 = define("build_root", ?[:0]const u8, null);
pub const cache_dir: ?[:0]const u8 = define("cache_dir", ?[:0]const u8, null);
pub const global_cache_dir: ?[:0]const u8 = define("global_cache_dir", ?[:0]const u8, null);
pub const root_src_file: ?[:0]const u8 = define("root_src_file", ?[:0]const u8, null);

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

pub const Logging = struct {
    pub const Full = packed struct {
        /// Report successful actions (not all actions are reported)
        Success: bool = default.Success,
        /// Report actions which acquire a finite resource
        Acquire: bool = default.Acquire,
        /// Report actions which release a finite resource
        Release: bool = default.Release,
        /// Report actions which throw an error
        Error: bool = default.Error,
        /// Report actions which terminate the program
        Fault: bool = default.Fault,
    };
    pub const SuccessError = packed struct {
        Success: bool = default.Success,
        Error: bool = default.Error,
    };
    pub const SuccessFault = packed struct {
        Success: bool = default.Success,
        Fault: bool = default.Fault,
    };
    pub const AcquireError = packed struct {
        Acquire: bool = default.Acquire,
        Error: bool = default.Error,
    };
    pub const AcquireFault = packed struct {
        Acquire: bool = default.Acquire,
        Fault: bool = default.Fault,
    };
    pub const ReleaseError = packed struct {
        Release: bool = default.Release,
        Error: bool = default.Error,
    };
    pub const ReleaseFault = packed struct {
        Release: bool = default.Release,
        Fault: bool = default.Fault,
    };
    pub const SuccessErrorFault = packed struct {
        Success: bool = default.Success,
        Error: bool = default.Error,
        Fault: bool = default.Fault,
    };
    pub const AcquireErrorFault = packed struct {
        Acquire: bool = default.Acquire,
        Error: bool = default.Error,
        Fault: bool = default.Fault,
    };
    pub const ReleaseErrorFault = packed struct {
        Release: bool = default.Release,
        Error: bool = default.Error,
        Fault: bool = default.Fault,
    };
    pub const default = .{
        .Success = is_verbose,
        .Acquire = is_verbose,
        .Release = is_verbose,
        .Error = !is_silent,
        .Fault = !is_silent,
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
