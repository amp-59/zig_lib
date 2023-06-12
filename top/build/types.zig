const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const time = @import("../time.zig");
const meta = @import("../meta.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const tasks = @import("./tasks.zig");
pub usingnamespace tasks;
pub const NodeKind = enum(u1) { group, worker };
pub const OutputMode = enum(u2) { exe, lib, obj };
pub const AuxOutputMode = enum(u3) { @"asm", llvm_ir, llvm_bc, h, docs, analysis };
pub const Task = enum(u8) {
    null = 0,
    any = 1,
    format = 2,
    build = 3,
    run = 4,
    archive = 5,
    pub const list: []const Task = meta.tagList(Task);
};
// zig fmt: off
pub const State = enum(u8) {
    /// The task does not exist for the target.
    null =      0b000000,
    /// The task was unable to complete due to an error.
    failed =    0b000001,
    /// The task is ready to begin.
    ready =     0b000010,
    /// The is waiting on dependencies.
    blocking =  0b000100,
    /// The task is in progress.
    working =   0b001000,
    /// The task was stopped without error.
    cancelled = 0b010000,
    /// The task is complete.
    finished =  0b100000,
    pub const list: []const State = meta.tagList(State);
};
// zig fmt: on
pub const Lock = mem.ThreadSafeSet(State.list.len, State, Task);
pub const NewPath = union {
    names: [][]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        @setRuntimeSafety(false);
        if (format.names.len != 0) {
            array.writeMany(format.names[0]);
            for (format.names[1..]) |name| {
                array.writeOne('/');
                array.writeMany(name);
            }
        }
        array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        var len: u64 = 0;
        if (format.names.len != 0) {
            mach.memcpy(buf + len, format.names[0].ptr, format.names[0].len);
            len +%= format.names[0].len;
            for (format.names[1..]) |name| {
                buf[len] = '/';
                len +%= 1;
                mach.memcpy(buf + len, name.ptr, name.len);
                len +%= name.len;
            }
        }
        buf[len] = 0;
        len +%= 1;
        return len;
    }
    pub fn formatLength(format: Format) u64 {
        @setRuntimeSafety(false);
        var len: u64 = 0;
        if (format.names.len != 0) {
            len +%= format.names[0].len;
            for (format.names[1..]) |name| {
                len +%= 1 +% name.len;
            }
        }
        return len +% 1;
    }
};
pub const Path = struct {
    absolute: [:0]const u8,
    relative: [:0]const u8 = &.{},
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.absolute);
        if (format.relative.len != 0) {
            array.writeOne('/');
            array.writeMany(format.relative.len);
        }
        array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        var len: u64 = format.absolute.len;
        mach.memcpy(buf, format.absolute.ptr, format.absolute.len);
        if (format.relative.len != 0) {
            buf[len] = '/';
            len = len +% 1;
            mach.memcpy(buf + len, format.relative.ptr, format.relative.len);
            len = len +% format.relative.len;
        }
        buf[len] = 0;
        return len +% 1;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = format.absolute.len;
        len +%= 1 +% format.relative.len;
        return len +% 1;
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
        @setRuntimeSafety(false);
        var len: u64 = 6;
        mach.memcpy(buf, "--mod\x00", 6);
        mach.memcpy(buf + len, mod.name.ptr, mod.name.len);
        len = len +% mod.name.len;
        buf[len] = ':';
        len +%= 1;
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                mach.memcpy(buf + len, dep_name.ptr, dep_name.len);
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
        mach.memcpy(buf + len, mod.path.ptr, mod.path.len);
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
        @setRuntimeSafety(false);
        var len: u64 = 7;
        mach.memcpy(buf, "--deps\x00", 7);
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                mach.memcpy(buf + len, name.ptr, name.len);
                len = len +% name.len;
                buf[len] = '=';
                len = len +% 1;
            }
            mach.memcpy(buf + len, mod_dep.name.ptr, mod_dep.name.len);
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
    value: ?[]const u8 = null,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        if (format.value) |value| {
            array.writeMany("=");
            array.writeMany(value);
        }
        array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        @ptrCast(*[2]u8, buf).* = "-D".*;
        mach.memcpy(buf + 2, format.name.ptr, format.name.len);
        var len: u64 = 2 +% format.name.len;
        if (format.value) |value| {
            buf[len] = '=';
            len = len +% 1;
            mach.memcpy(buf + len, value.ptr, value.len);
            len = len +% value.len;
        }
        buf[len] = 0;
        return len +% 1;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 2 +% format.name.len;
        if (format.value) |value| {
            len +%= 1 +% value.len;
        }
        return len +% 1;
    }
};
pub const Macros = Aggregate(Macro);
pub const CFlags = struct {
    value: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-cflags");
        array.writeOne(0);
        for (format.value) |flag| {
            array.writeMany(flag);
            array.writeOne(0);
        }
        array.writeMany("--\x00");
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        var len: u64 = 8;
        mach.memcpy(buf, "-cflags\x00", 8);
        for (format.value) |flag| {
            mach.memcpy(buf + len, flag.ptr, flag.len);
            len = len +% flag.len;
            buf[len] = 0;
            len = len +% 1;
        }
        mach.memcpy(buf + len, "--\x00", 3);
        return len +% 3;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 8;
        for (format.value) |flag| {
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
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        var len: u64 = 0;
        for (format.value) |path| {
            len = len +% path.formatWriteBuf(buf + len);
        }
        return len;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.value) |path| {
            len +%= path.formatLength();
        }
        return len;
    }
};
fn Aggregate(comptime T: type) type {
    return struct {
        value: []const T,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            for (format.value) |value| {
                value.formatWrite(array);
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            @setRuntimeSafety(false);
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
    };
    pub const ErrorHeader = extern struct {
        extra_len: u32,
        bytes_len: u32,
    };
};
pub const EmitBin = extern union {
    cache_hit: bool,
    status: u8,
};
pub const ErrorMessageList = extern struct {
    len: u32,
    start: u32,
    compile_log_text: u32,
    pub const Extra = extern struct {
        data: *ErrorMessageList,
        end: u64,
    };
    pub const len: u64 = 3;
};
pub const SourceLocation = extern struct {
    src_path: u32,
    line: u32,
    column: u32,
    span_start: u32,
    span_main: u32,
    span_end: u32,
    src_line: u32 = 0,
    ref_len: u32 = 0,
    pub const Extra = extern struct {
        data: *SourceLocation,
        end: u64,
    };
    pub const len: u64 = 8;
};
pub const ErrorMessage = extern struct {
    start: u32,
    count: u32 = 1,
    src_loc: u32 = 0,
    notes_len: u32 = 0,
    pub const Extra = extern struct {
        data: *ErrorMessage,
        end: u64,
    };
    pub const len: u64 = 4;
};
pub const ReferenceTrace = extern struct {
    decl_name: u32,
    src_loc: u32,
    pub const Extra = extern struct {
        data: *ReferenceTrace,
        end: u64,
    };
    pub const len: u64 = 2;
};
pub const Record = packed struct {
    /// Build duration in milliseconds, max 50 days
    durat: u32,
    /// Output size in bytes, max 4GiB
    size: u32,
    /// Extra
    detail: packed struct {
        /// Whether the output was stripped
        strip: bool,
        /// The optimisation/safety mode for the output
        mode: builtin.Mode,
    },
    pub fn init(ts: time.TimeSpec, size: u64, build_cmd: anytype) Record {
        const mode = build_cmd.mode orelse .Debug;
        const strip = build_cmd.strip orelse (mode == .ReleaseSmall);
        return .{
            .durat = @intCast(u32, (ts.sec * 1_000) +% (ts.nsec / 1_000_000)),
            .size = @intCast(u32, size),
            .detail = .{ .mode = mode, .strip = strip },
        };
    }
};
