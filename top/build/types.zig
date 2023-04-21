const mem = @import("../mem.zig");
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
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= format.absolute.len;
        if (format.relative) |relative| {
            len +%= 1;
            len +%= relative.len;
        }
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
        constant: usize,
        path: Path,
    };
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        array.writeMany("=");
        switch (format.value) {
            .constant => |constant| {
                array.writeAny(spec.reinterpret.print, constant);
            },
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
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        len +%= 1;
        switch (format.value) {
            .constant => |constant| {
                len +%= mem.reinterpret.lengthAny(u8, spec.reinterpret.print, constant);
            },
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
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.value) |path| {
            len +%= path.formatLength();
            len +%= 1;
        }
        return len;
    }
};

pub const Errors = struct {
    extra: []u32,
    bytes: []u8,
    pub const Header = extern struct {
        extra_len: u32,
        bytes_len: u32,
    };
    pub fn extraData(errors: Errors, comptime T: type, index: usize) T.Extra {
        @setRuntimeSafety(false);
        return .{
            .data = @ptrCast(*T, errors.extra[index..].ptr),
            .end = index +% T.len,
        };
    }
};
pub const ClientMessage = extern struct {
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
pub const ServerMessage = extern struct {
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
    pub fn version(message: *ServerMessage) [:0]const u8 {
        @setRuntimeSafety(false);
        const string_addr: u64 = @ptrToInt(message) +% @sizeOf(ServerMessage);
        return @intToPtr([*:0]u8, string_addr)[0..message.bytes_len :0];
    }
    pub fn pathname(message: *ServerMessage) [:0]const u8 {
        @setRuntimeSafety(false);
        const string_addr: u64 = @ptrToInt(message) +% @sizeOf(ServerMessage) +% 1;
        return meta.manyToSlice(@intToPtr([*:0]u8, string_addr));
    }
    pub fn errors(message: *ServerMessage) Errors {
        @setRuntimeSafety(false);
        const hdr_addr: u64 = @ptrToInt(message) +% @sizeOf(ServerMessage);
        const data_addr: u64 = hdr_addr +% @sizeOf(Errors.Header);
        const errors_header: *Errors.Header = @intToPtr(*Errors.Header, hdr_addr);
        return .{
            .extra = @intToPtr([*]u32, data_addr)[0..errors_header.extra_len],
            .bytes = @intToPtr([*]u8, data_addr +% errors_header.extra_len *% 4)[0..errors_header.bytes_len],
        };
    }
    pub const len: u64 = @sizeOf(@This());
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
pub const EmitBinPath = extern struct {
    flags: Flags,
    pub const Flags = packed struct(u8) {
        cache_hit: bool,
        reserved: u7 = 0,
    };
};
