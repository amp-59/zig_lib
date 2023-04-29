const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const meta = @import("../meta.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const tasks = @import("./tasks.zig");
pub usingnamespace tasks;
pub const Task = enum(u8) {
    build = 1,
    run = 2,
};
pub const State = enum(u8) {
    unavailable = 0,
    failed = 1,
    ready = 2,
    blocking = 3,
    invalid = 4,
    finished = 255,
};
pub const state_list: []const State = meta.tagList(State);
pub const task_list: []const Task = meta.tagList(Task);
pub const Lock = mem.ThreadSafeSet(state_list.len, State, Task);
pub const Path = struct {
    absolute: [:0]const u8,
    relative: ?[:0]const u8 = null,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.absolute);
        if (format.relative) |relative| {
            array.writeOne('/');
            array.writeMany(relative);
        }
        // array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        var len: u64 = format.absolute.len;
        @memcpy(buf, format.absolute.ptr, format.absolute.len);
        if (format.relative) |relative| {
            buf[len] = '/';
            len = len +% 1;
            @memcpy(buf + len, relative.ptr, relative.len);
            len = len +% relative.len;
        }
        buf[len] = 0;
        return len +% 1;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= format.absolute.len;
        if (format.relative) |relative| {
            len +%= 1;
            len +%= relative.len;
        }
        //return len +% 1;
        return len;
    }
};
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const []const u8 = null,
    pub fn formatWrite(mod: Module, array: anytype) void {
        array.writeMany("--mod\x00");
        array.writeMany(mod.name);
        array.writeOne(':');
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                array.writeMany(dep_name);
                array.writeOne(',');
            }
            if (deps.len != 0) {
                array.undefine(1);
            }
        }
        array.writeOne(':');
        array.writeMany(mod.path);
        array.writeOne(0);
    }
    pub fn formatWriteBuf(mod: Module, buf: [*]u8) u64 {
        var len: u64 = 6;
        @memcpy(buf, "--mod\x00", 6);
        @memcpy(buf + len, mod.name.ptr, mod.name.len);
        len = len +% mod.name.len;
        buf[len] = ':';
        len +%= 1;
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                @memcpy(buf + len, dep_name.ptr, dep_name.len);
                len = len +% dep_name.len;
                buf[len] = ',';
                len = len +% 1;
            }
            if (deps.len != 0) {
                len = len -% 1;
            }
        }
        buf[len] = ':';
        len = len +% 1;
        @memcpy(buf + len, mod.path.ptr, mod.path.len);
        len = len +% mod.path.len;
        buf[len] = 0;
        return len +% 1;
    }
    pub fn formatLength(mod: Module) u64 {
        var len: u64 = 0;
        len +%= 6;
        len +%= mod.name.len;
        len +%= 1;
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                len +%= dep_name.len;
                len +%= 1;
            }
            if (deps.len != 0) {
                len -%= 1;
            }
        }
        len +%= 1;
        len +%= mod.path.len;
        len +%= 1;
        return len;
    }
};
pub const Modules = Aggregate(Module);
pub const ModuleDependency = struct {
    import: ?[]const u8 = null,
    name: []const u8,
};
pub const ModuleDependencies = struct {
    value: []const ModuleDependency,
    pub fn formatWrite(mod_deps: ModuleDependencies, array: anytype) void {
        array.writeMany("--deps\x00");
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                array.writeMany(name);
                array.writeOne('=');
            }
            array.writeMany(mod_dep.name);
            array.writeOne(',');
        }
        array.overwriteOneBack(0);
    }
    pub fn formatWriteBuf(mod_deps: ModuleDependencies, buf: [*]u8) u64 {
        var len: u64 = 7;
        @memcpy(buf, "--deps\x00", 7);
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                @memcpy(buf + len, name.ptr, name.len);
                len = len +% name.len;
                buf[len] = '=';
                len = len +% 1;
            }
            @memcpy(buf + len, mod_dep.name.ptr, mod_dep.name.len);
            len = len +% mod_dep.name.len;
            buf[len] = ',';
            len = len +% 1;
        }
        buf[len - 1] = 0;
        return len;
    }
    pub fn formatLength(mod_deps: ModuleDependencies) u64 {
        var len: u64 = 0;
        len +%= 7;
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                len +%= name.len +% 1;
            }
            len +%= mod_dep.name.len +% 1;
        }
        return len;
    }
};
pub const Macro = struct {
    name: []const u8,
    value: Value,
    const Format = @This();
    const Value = union(enum) {
        string: [:0]const u8,
        symbol: [:0]const u8,
        path: Path,
    };
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        array.writeMany("=");
        switch (format.value) {
            .string => |string| {
                array.writeOne('"');
                array.writeMany(string);
                array.writeOne('"');
            },
            .path => |path| {
                array.writeOne('"');
                array.writeFormat(path);
                array.writeOne('"');
            },
            .symbol => |symbol| {
                array.writeMany(symbol);
            },
        }
        array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        var len: u64 = 2;
        @memcpy(buf, "-D", 2);
        @memcpy(buf + len, format.name.ptr, format.name.len);
        len = len +% format.name.len;
        buf[len] = '=';
        len = len +% 1;
        switch (format.value) {
            .string => |string| {
                buf[len] = '"';
                len = len +% 1;
                @memcpy(buf + len, string.ptr, string.len);
                len = len +% string.len;
                buf[len] = '"';
                len = len +% 1;
            },
            .path => |path| {
                buf[len] = '"';
                len = len +% 1;
                len = len + path.formatWriteBuf(buf + len);
                buf[len] = '"';
                len = len +% 1;
            },
            .symbol => |symbol| {
                @memcpy(buf + len, symbol.ptr, symbol.len);
                len = len +% symbol.len;
            },
        }
        buf[len] = 0;
        return len +% 1;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        len +%= 1;
        switch (format.value) {
            .string => |string| {
                len +%= 1 +% string.len +% 1;
            },
            .path => |path| {
                len +%= 1 +% path.formatLength() +% 1;
            },
            .symbol => |symbol| {
                len +%= symbol.len;
            },
        }
        len +%= 1;
        return len;
    }
};
pub const Macros = Aggregate(Macro);
pub const CFlags = struct {
    flags: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-cflags");
        array.writeOne(0);
        for (format.flags) |flag| {
            array.writeMany(flag);
            array.writeOne(0);
        }
        array.writeMany("--\x00");
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        var len: u64 = 8;
        @memcpy(buf, "-cflags\x00", 8);
        for (format.flags) |flag| {
            @memcpy(buf + len, flag.ptr, flag.len);
            len = len +% flag.len;
            buf[len] = 0;
            len = len +% 1;
        }
        @memcpy(buf + len, "--\x00", 3);
        return len +% 3;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 8;
        for (format.flags) |flag| {
            len +%= flag.len;
            len +%= 1;
        }
        len +%= 3;
        return len;
    }
};
pub const Files = struct {
    value: []const Path,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        for (format.value) |path| {
            array.writeFormat(path);
            array.writeOne(0);
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        var len: u64 = 0;
        for (format.value) |path| {
            len = len +% path.formatWriteBuf(buf + len);
            buf[len] = 0;
            len = len +% 1;
        }
        return len;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.value) |path| {
            len +%= path.formatLength();
            len +%= 1;
        }
        return len;
    }
};
fn Aggregate(comptime T: type) type {
    return struct {
        value: []const T,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) u64 {
            for (format.value) |value| {
                value.formatWrite(array);
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            var len: u64 = 0;
            for (format.value) |value| {
                len = len +% value.formatWriteBuf(buf + len);
            }
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            for (format.value) |value| {
                len = len +% value.formatLength();
            }
            return len;
        }
    };
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
        pub const size: u64 = @sizeOf(ClientHeader);
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
        pub const size: u64 = @sizeOf(ServerHeader);
    };
    pub const ErrorHeader = extern struct {
        extra_len: u32,
        bytes_len: u32,
        pub const size: u64 = @sizeOf(ErrorHeader);
        pub fn create(msg: []u8) *ErrorHeader {
            @setRuntimeSafety(false);
            return @ptrCast(*ErrorHeader, @alignCast(4, msg.ptr));
        }
        pub fn extra(hdr: *ErrorHeader) [*]u32 {
            @setRuntimeSafety(false);
            return @intToPtr([*]u32, @ptrToInt(hdr) +% size);
        }
        pub fn bytes(hdr: *ErrorHeader) [*:0]u8 {
            @setRuntimeSafety(false);
            return @intToPtr([*:0]u8, @ptrToInt(hdr) +% size +% (hdr.extra_len *% 4));
        }
    };
};
pub const EmitBin = extern struct {
    flags: Flags,
    pub const Flags = packed struct(u8) {
        cache_hit: bool,
        reserved: u7 = 0,
    };
};
pub const ErrorMessageList = struct {
    len: u32,
    start: u32,
    compile_log_text: u32,
    pub const Extra = struct {
        data: *ErrorMessageList,
        end: u64,
    };
    pub const len: u64 = 3;
};
pub const SourceLocation = struct {
    src_path: u32,
    line: u32,
    column: u32,
    span_start: u32,
    span_main: u32,
    span_end: u32,
    src_line: u32 = 0,
    ref_len: u32 = 0,
    pub const Extra = struct {
        data: *SourceLocation,
        end: u64,
    };
    pub const len: u64 = 8;
};
pub const ErrorMessage = struct {
    start: u32,
    count: u32 = 1,
    src_loc: u32 = 0,
    notes_len: u32 = 0,
    pub const Extra = struct {
        data: *ErrorMessage,
        end: u64,
    };
    pub const len: u64 = 4;
};
pub const ReferenceTrace = struct {
    decl_name: u32,
    src_loc: u32,
    pub const Extra = struct {
        data: *ReferenceTrace,
        end: u64,
    };
    pub const len: u64 = 2;
};

pub const Variant = enum(u1) {
    length,
    write,
};
pub const ProtoTypeDescr = fmt.GenericTypeDescrFormat(.{
    .options = .{
        .default_field_values = true,
        .identifier_name = true,
    },
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
pub const ArgInfo = struct {
    /// Describes how the argument should be written to the command line buffer
    tag: Tag,
    /// Describes how the field type should be written to the command struct
    type: ProtoTypeDescr,

    const Tag = enum(u8) {
        boolean = 0,
        string = 1,
        tag = 2,
        integer = 3,
        formatter = 4,
        mapped = 5,
        optional_boolean = 8,
        optional_string = 9,
        optional_tag = 10,
        optional_integer = 11,
        optional_formatter = 12,
        optional_mapped = 13,
    };
    fn optionalTypeDescr(any: anytype) ProtoTypeDescr {
        if (@TypeOf(any) == type) {
            return optional(&ProtoTypeDescr.init(any));
        } else {
            return optional(&.{ .type_name = any });
        }
    }
    pub fn boolean() ArgInfo {
        return .{ .tag = .boolean, .type = ProtoTypeDescr.init(bool) };
    }
    pub fn string(comptime T: type) ArgInfo {
        return .{ .tag = .string, .type = ProtoTypeDescr.init(T) };
    }
    pub fn tag(comptime T: type) ArgInfo {
        return .{ .tag = .tag, .type = ProtoTypeDescr.init(T) };
    }
    pub fn integer(comptime T: type) ArgInfo {
        return .{ .tag = .integer, .type = ProtoTypeDescr.init(T) };
    }
    pub fn formatter(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .formatter, .type = .{ .type_name = type_name } };
    }
    pub fn mapped(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .mapped, .type = .{ .type_name = type_name } };
    }
    pub fn optional(@"type": *const ProtoTypeDescr) ProtoTypeDescr {
        return .{ .type_refer = .{ .spec = "?", .type = @"type" } };
    }
    pub fn optional_boolean() ArgInfo {
        return .{ .tag = .optional_boolean, .type = optionalTypeDescr(bool) };
    }
    pub fn optional_string(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_string, .type = optionalTypeDescr(any) };
    }
    pub fn optional_tag(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_tag, .type = optionalTypeDescr(any) };
    }
    pub fn optional_integer(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_integer, .type = optionalTypeDescr(any) };
    }
    pub fn optional_formatter(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_formatter, .type = optionalTypeDescr(any) };
    }
    pub fn optional_mapped(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_mapped, .type = optionalTypeDescr(any) };
    }
};
pub const OptionSpec = struct {
    /// Command struct field name
    name: []const u8,
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = ArgInfo.boolean(),
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?InverseOptionSpec = null,
    /// Maybe define default value of this field. Should be false or null, but
    /// allow the exception.
    default_value: ?[]const u8 = null,
    /// Description to be inserted above the field as documentation comment
    descr: ?[]const []const u8 = null,
};
pub const InverseOptionSpec = struct {
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = ArgInfo.boolean(),
};
