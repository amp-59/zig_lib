const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const gen = @import("../gen.zig");
const proc = @import("../proc.zig");
const time = @import("../time.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
const tab = @import("./tab.zig");
const com = @import("./com.zig");
const types = @This();
const tasks = @import("./tasks.zig");
pub usingnamespace tasks;
pub const Allocator = mem.SimpleAllocator;
pub const VTable = @import("./vtable.zig");
pub const Node = enum(u8) {
    group,
    worker,
};
pub const ExecMode = enum(u8) {
    Run,
    Regenerate,
    Analyse,
};
pub const OutputMode = enum(u2) {
    exe,
    lib,
    obj,
};
pub const AuxOutputMode = enum(u3) {
    @"asm",
    llvm_ir,
    llvm_bc,
    h,
    docs,
    analysis,
};
pub const AutoOnOff = enum {
    auto,
    off,
    on,
};
pub const Listen = enum {
    none,
    @"-",
    ipv4,
};
pub const BuildId = enum(u8) {
    fast,
    uuid,
    sha1,
    md5,
    none,
    _,
};
pub const LinkerFlags = enum {
    nodelete,
    notext,
    defs,
    origin,
    nocopyreloc,
    now,
    lazy,
    relro,
    norelro,
};
pub const Task = enum(u8) {
    null = 0,
    any = 1,
    format = 2,
    build = 3,
    run = 4,
    archive = 5,
    objcopy = 6,
    pub const list = [5]Task{ .format, .build, .run, .archive, .objcopy };
};
pub const State = enum(u8) {
    // zig fmt: off
    /// The task does not exist for the target.
    null =      0b000000,
    /// The task was unable to complete due to an error.
    failed =    0b000001,
    /// The task is ready to begin.
    ready =     0b000010,
    /// The task is waiting on dependencies.
    blocking =  0b000100,
    /// The task is in progress.
    working =   0b001000,
    /// The task was stopped without error.
    cancelled = 0b010000,
    /// The task is complete.
    finished =  0b100000,
    // zig fmt: on
    pub fn style(st: State) [:0]const u8 {
        switch (st) {
            .failed, .cancelled => return "\x1b[91m",
            .ready => return "\x1b[93m",
            .blocking => return "\x1b[96m",
            .working => return "\x1b[95m",
            .finished => return "\x1b[92m",
            .null => unreachable,
        }
    }
};
pub const Lock = mem.ThreadSafeSet(7, State, Task);
pub const Extension = struct {
    name: []const u8,
    path: []const u8,
    offset: usize = 0,
};
pub const Config = struct {
    name: []const u8,
    value: Value,
    pub const Value = union(enum) { Int: usize, Bool: bool, String: []const u8 };
    pub fn formatWriteBuf(cfg: Config, buf: [*]u8) u64 {
        @setRuntimeSafety(false);
        var ud64: fmt.Type.Ud64 = .{ .value = cfg.value.Int };
        @setRuntimeSafety(builtin.is_safe);
        buf[0..12].* = "pub const @\"".*;
        var ptr: [*]u8 = buf + 12;
        ptr = fmt.strcpyEqu(ptr, cfg.name);
        switch (cfg.value) {
            .Int => {
                ptr[0..18].* = "\": comptime_int = ".*;
                ptr += 18;
                ptr += ud64.formatWriteBuf(ptr);
            },
            .Bool => |value| {
                ptr[0..10].* = "\": bool = ".*;
                ptr += 10;
                ptr[0..5].* = if (value) "true\x00".* else "false".*;
                ptr += @as(usize, 5) -% @intFromBool(value);
            },
            .String => |value| {
                ptr[0..11].* = "\": *const [".*;
                ptr += 11;
                ud64.value = value.len;
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..8].* = ":0]u8 = ".*;
                ptr += 8;
                ptr[0] = '"';
                ptr += 1;
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = '"';
                ptr += 1;
            },
        }
        ptr[0..2].* = ";\n".*;
        return fmt.strlen(ptr, buf) +% 2;
    }
    pub fn formatWrite(cfg: Config, array: anytype) void {
        array.writeMany("pub const ");
        array.writeMany(cfg.name);
        array.writeMany(" = ");
        switch (cfg.value) {
            .Int => |value| {
                array.writeFormat(fmt.ud64(value));
            },
            .Bool => |value| {
                array.writeMany(if (value) "true" else "false");
            },
            .String => |value| {
                array.writeOne('"');
                array.writeMany(value);
                array.writeOne('"');
            },
        }
        array.writeMany(";\n");
    }
    pub fn formatLength(cfg: Config) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var ud64: fmt.Type.Ud64 = cfg.Int.value;
        var len: u64 = 10 +% cfg.name.len;
        switch (cfg.value) {
            .Int => {
                len +%= 17 +% ud64.formatLength();
            },
            .Bool => |value| {
                len +%= 9 +% (5 -% @intFromBool(value));
            },
            .String => |value| {
                ud64 = @bitCast(value.len);
                len +%= 18 +% ud64.formatLength() + value.len;
            },
        }
        return len +% 2;
    }
};
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: []const []const u8 = &.{},
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
        @setRuntimeSafety(builtin.is_safe);
        buf[0..6].* = "--mod\x00".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 6, mod.name);
        ptr[0] = ':';
        ptr += 1;
        for (mod.deps) |dep_name| {
            ptr = fmt.strcpyEqu(ptr, dep_name);
            ptr[0] = ',';
            ptr += 1;
        }
        if (mod.deps.len != 0) {
            ptr -= 1;
        }
        ptr[0] = ':';
        ptr = fmt.strcpyEqu(ptr + 1, mod.path);
        ptr[0] = 0;
        return fmt.strlen(ptr + 1, buf);
    }
    pub fn formatLength(mod: Module) u64 {
        var len: u64 = 6 +% mod.name.len +% 1;
        for (mod.deps) |dep_name| {
            len +%= dep_name.len +% 1;
        }
        if (mod.deps.len != 0) {
            len -%= 1;
        }
        return len +% 1 +% mod.path.len +% 1;
    }
    pub fn formatParseArgs(allocator: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) Module {
        var idx: usize = 0;
        var len: usize = 0;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ':') {
                if (len == 0) {
                    len = idx;
                } else {
                    break;
                }
            }
        } else {
            @panic(arg);
        }
        if (idx +% 1 == arg.len) {
            @panic(arg);
        }
        var ret: Module = .{ .name = arg[0..len], .path = arg[idx +% 1 ..] };
        if (idx != len +% 1) {
            idx = len +% 1;
            len = 1;
        } else {
            return ret;
        }
        var pos: usize = idx;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ',') {
                len +%= 1;
            }
        }
        var deps: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% len, 8));
        idx = pos;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ',') {
                deps[len] = arg[pos..idx];
                len +%= 1;
                pos = idx +% 1;
            }
        }
        return ret;
    }
};
pub const Modules = Aggregate(Module);
pub const ModuleDependency = struct {
    import: []const u8 = &.{},
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
        @setRuntimeSafety(builtin.is_safe);
        if (mod_deps.value.len == 0) {
            return 0;
        }
        buf[0..7].* = "--deps\x00".*;
        var ptr: [*]u8 = buf + 7;
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import.len != 0) {
                ptr = fmt.strcpyEqu(ptr, mod_dep.import);
                ptr[0] = '=';
                ptr += 1;
            }
            ptr = fmt.strcpyEqu(ptr, mod_dep.name);
            ptr[0] = ',';
            ptr += 1;
        }
        const len: usize = fmt.strlen(ptr, buf);
        buf[len -% 1] = 0;
        return len;
    }
    pub fn formatLength(mod_deps: ModuleDependencies) u64 {
        if (mod_deps.value.len == 0) {
            return 0;
        }
        var len: u64 = 7;
        for (mod_deps.value) |mod_dep| {
            len +%= mod_dep.import.len +% @intFromBool(mod_dep.import.len != 0);
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
        @setRuntimeSafety(builtin.is_safe);
        buf[0..2].* = "-D".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 2, format.name);
        if (format.value) |value| {
            ptr[0] = '=';
            ptr += 1;
            ptr = fmt.strcpyEqu(ptr, value);
        }
        ptr[0] = 0;
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 2 +% format.name.len;
        if (format.value) |value| {
            len +%= 1 +% value.len;
        }
        return len +% 1;
    }
    pub fn formatParseArgs(_: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) Macro {
        @setRuntimeSafety(builtin.is_safe);
        if (arg.len == 0) {
            @panic(arg);
        }
        var idx: usize = 0;
        var pos: usize = 0;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == '=') {
                pos = idx +% 1;
                if (pos == arg.len) {
                    break;
                }
                return .{
                    .name = arg[0..idx],
                    .value = arg[pos..],
                };
            }
        }
        return .{ .name = arg[0..idx] };
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
        @setRuntimeSafety(builtin.is_safe);
        buf[0..8].* = "-cflags\x00".*;
        var ptr: [*]u8 = buf + 8;
        for (format.value) |flag| {
            ptr = fmt.strcpyEqu(ptr, flag);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr[0..3].* = "--\x00".*;
        return fmt.strlen(ptr, buf);
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
pub const EnvPaths = struct {
    zig_exe: ?[]const u8 = null,
    build_root: ?[]const u8 = null,
    cache_root: ?[]const u8 = null,
    global_cache_root: ?[]const u8 = null,
};
pub const Path = extern struct {
    names: [*][:0]const u8,
    names_max_len: u64 = 1,
    names_len: u64 = 1,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
        if (format.names.len != 0) {
            array.writeMany(format.names[0]);
            for (format.names[1..]) |name| {
                array.writeOne('/');
                array.writeMany(name);
            }
            array.writeOne(0);
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf;
        if (format.names_len != 0) {
            ptr = fmt.strcpyEqu(ptr, format.names[0]);
            for (format.names[1..format.names_len]) |name| {
                ptr[0] = '/';
                ptr += 1;
                ptr = fmt.strcpyEqu(ptr, name);
            }
            ptr[0] = 0;
            ptr += 1;
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: Format) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: u64 = 0;
        if (format.names_len != 0) {
            len +%= format.names[0].len;
            for (format.names[1..format.names_len]) |name| {
                len +%= 1 +% name.len;
            }
            len +%= 1;
        }
        return len;
    }
    pub fn formatParseArgs(allocator: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) Path {
        @setRuntimeSafety(builtin.is_safe);
        if (arg.len == 0) {
            @panic(arg);
        }
        const names: [*][:0]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
        names[0] = arg;
        return .{ .names = names };
    }
    pub fn concatenate(path: Path, allocator: anytype) [:0]u8 {
        @setRuntimeSafety(builtin.is_safe);
        const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(path.formatLength(), 1));
        const len: u64 = path.formatWriteBuf(buf);
        return buf[0 .. len -% 1 :0];
    }
    pub fn addName(path: *Path, allocator: anytype) *[:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        const size_of: comptime_int = @sizeOf([:0]const u8);
        const addr_buf: *u64 = @ptrCast(&path.names);
        const ret: *[:0]const u8 = @ptrFromInt(allocator.addGeneric(size_of, //
            2, addr_buf, &path.names_max_len, path.names_len));
        path.names_len +%= 1;
        return ret;
    }
    pub fn temporary(names: []const [:0]const u8) Path {
        return .{ .names = @constCast(names.ptr), .names_len = names.len };
    }
    pub inline fn relative(path: *const Path) [:0]const u8 {
        return path.names[path.names_len -% 1];
    }
    pub inline fn create(comptime names: []const [:0]const u8) Path {
        return .{ .names = @constCast(names.ptr), .names_len = names.len };
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
        @setRuntimeSafety(builtin.is_safe);
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
pub const Record = packed struct {
    /// Build duration in milliseconds, max 50 days
    durat: u32,
    /// Output size in bytes, max 4GiB
    size: u32,
    /// Extra
    detail: @import("./hist_tasks.zig").BuildCommand,
    pub fn init(build_cmd: *types.BuildCommand, st: *const file.Status, ts: *const time.TimeSpec) Record {
        return .{
            .durat = @as(u32, @intCast((ts.sec * 1_000) +% (ts.nsec / 1_000_000))),
            .size = @as(u32, @intCast(st.size)),
            .detail = @import("./hist_tasks.zig").BuildCommand.convert(build_cmd),
        };
    }
};
pub fn GenericBuildCommand(comptime BuildCommand: type) type {
    return struct {
        pub fn addModule(cmd: *BuildCommand, allocator: *mem.SimpleAllocator, name: [:0]const u8, pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            if (cmd.modules) |src| {
                const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Module) *% src.len +% 1, 8));
                @memcpy(dest, src);
                dest[src.len] = .{ .name = name, .path = pathname };
                cmd.modules = dest[0 .. src.len +% 1];
            } else {
                const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Module), 8));
                dest[0] = .{ .name = name, .path = pathname };
                cmd.modules = dest[0..1];
            }
        }
        pub fn addModuleDependency(cmd: *BuildCommand, allocator: *mem.SimpleAllocator, name: [:0]const u8, pathname: [:0]const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            cmd.addModule(allocator, name, pathname);
            if (cmd.dependencies) |src| {
                const dest: [*]ModuleDependency = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Module) *% src.len +% 1, 8));
                @memcpy(dest, src);
                dest[src.len] = .{ .name = name };
                cmd.dependencies = dest[0 .. src.len +% 1];
            } else {
                const dest: [*]ModuleDependency = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Module), 8));
                dest[0] = .{ .name = name };
                cmd.dependencies = dest[0..1];
            }
        }
    };
}
pub fn GenericExtraCommand(comptime Command: type) type {
    const render_spec: fmt.RenderSpec = .{
        .infer_type_names = true,
        .forward = true,
    };
    const Editor = gen.StructEditor(render_spec, Command);
    const field_name: []const u8 = switch (Command) {
        types.BuildCommand => "build",
        types.FormatCommand => "format",
        types.ArchiveCommand => "archive",
        types.ObjcopyCommand => "objcopy",
        types.TableGenCommand => "tblgen",
        else => "unknown",
    };
    const T = struct {
        pub const manifest = .{
            .fieldEditDistance = gen.FnExport{ .prefix = field_name ++ "." },
            .writeFieldEditDistance = gen.FnExport{ .prefix = field_name ++ "." },
            .indexOfCommonLeastDifference = gen.FnExport{ .prefix = field_name ++ "." },
            .renderWriteBuf = gen.FnExport{ .prefix = field_name ++ "." },
        };
        pub fn renderWriteBuf(cmd: *const Command, buf: [*]u8) callconv(.C) usize {
            return fmt.render(render_spec, cmd.*).formatWriteBuf(buf);
        }
        pub const fieldEditDistance = Editor.fieldEditDistance;
        pub const writeFieldEditDistance = Editor.writeFieldEditDistance;
        pub const indexOfCommonLeastDifference = Editor.indexOfCommonLeastDifference;
    };
    return T;
}
pub fn GenericCommand(comptime Command: type) type {
    const field_name: []const u8 = switch (Command) {
        types.BuildCommand => "build",
        types.FormatCommand => "format",
        types.ArchiveCommand => "archive",
        types.ObjcopyCommand => "objcopy",
        types.TableGenCommand => "tblgen",
        else => "unknown",
    };
    const T = struct {
        pub const manifest = .{
            .formatWriteBuf = gen.FnExport{ .prefix = field_name ++ "." },
            .formatParseArgs = gen.FnExport{ .prefix = field_name ++ "." },
            .formatLength = gen.FnExport{ .prefix = field_name ++ "." },
        };
        pub const formatWriteBuf = Command.formatWriteBuf;
        pub const formatLength = Command.formatLength;
        pub const formatParseArgs = Command.formatParseArgs;
    };
    return T;
}
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
            @setRuntimeSafety(builtin.is_safe);
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
pub const Flags = packed struct {
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
    /// Builder will create a configuration root. Enables usage of
    /// configuration constants.
    want_build_config: bool = false,
    /// Whether to monitor build/run performance counters.
    want_perf_events: bool = false,
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
};

pub const Node5 = struct {
    tag: types.Node,
    /// The node's 'first' name. Must be unique within the parent group.
    /// Names will only be checked for uniqueness once: when the node is
    /// added to its group with any of the `add(Build|Format|Archive|...)`
    /// functions. If a non-unique name is contrived by manually editing
    /// this field the state is undefined.
    name: [:0]u8,
    /// Description text to be printed with task listing.
    descr: [:0]const u8,

    tasks: Tasks,
    flags: Flags,
    lists: Lists,
    extra: Extra,

    const Tasks = struct {
        /// Primary (default) task for this node.
        tag: types.Task,
        /// Compile command information for this node. Can be a pointer to any
        /// command struct.
        cmd: types.Command,
        /// State information for any tasks associated with this node.
        lock: types.Lock,
    };
    const Size = u16;
    pub const Depn = struct {
        /// The node holding this dependency will block on this task ...
        task: types.Task,
        /// Until node given by nodes[on_idx] has ...
        on_idx: Size,
        /// This task ...
        on_task: types.Task,
        /// Is in this state.
        on_state: types.State,
    };
    pub const Lists = mem.GenericOptionalArrays(Size, union(enum) {
        nodes: *Node5,
        deps: Depn,
        paths: types.Path,
        args: [*:0]u8,
        vars: [*:0]u8,
        cmd_args: [*:0]u8,
        run_args: [*:0]u8,
        cfgs: types.Config,
    });
    pub const Extra = mem.GenericOptionals(union(enum) {
        dir_fds: DirFds,
        wait: Wait,
        load: Loadables,
        stats: BasicStats,
    });
    pub const Stats = struct {
        basic: BasicStats,
        extra: ExtraStats,
    };
    pub const Wait = struct {
        len: usize = 0,
        tick: usize = 0,
    };
    pub const DirFds = struct {
        build_root: usize,
        config_root: usize,
        output_root: usize,
    };
    pub const BasicStats = struct {
        status: u8,
        server: u8,
        time: time.TimeSpec,
        size: struct { old: usize, new: usize },
    };
    pub const ExtraStats = struct {
        elf_info_addr: usize,
        perf_events_addr: usize,
    };
    pub const Loadables = union {
        dyn_loader_addr: usize,
        vtable_addr: usize,
    };
    var toplevel: *Node5 = undefined;
    pub fn init(allocator: *mem.SimpleAllocator, name: [:0]const u8, args: [][*:0]u8, vars: [][*:0]u8) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        const node: *Node5 = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node5), @alignOf(Node5)));
        toplevel = node;
        node.flags = .{ .is_toplevel = true };
        node.lists.add(allocator, .nodes).* = node;
        node.name = com.duplicate(allocator, name);
        node.tag = .group;
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, mem.terminate(args[1], 0));
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, mem.terminate(args[2], 0));
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, mem.terminate(args[3], 0));
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, mem.terminate(args[4], 0));
        node.tasks.tag = .any;
        node.tasks.lock = tab.omni_lock;
        node.lists.set(allocator, .args, args);
        node.lists.set(allocator, .vars, vars);
        Builder.initializeGroup(allocator, node);
        Builder.initializeExtensions(allocator, node);
        return node;
    }
    pub fn addGroup(group: *Node5, allocator: *mem.SimpleAllocator, name: []const u8, paths: types.EnvPaths) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        const node: *Node5 = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node5), @alignOf(Node5)));
        group.lists.add(allocator, .nodes).* = node;
        node.lists.add(allocator, .nodes).* = group;
        node.tag = .group;
        node.flags = .{};
        node.name = com.duplicate(allocator, name);
        node.tasks.tag = .any;
        node.tasks.lock = tab.omni_lock;
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, paths.zig_exe orelse group.zigExe());
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, paths.build_root orelse group.buildRoot());
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, paths.cache_root orelse group.cacheRoot());
        node.lists.add(allocator, .paths).addName(allocator).* = com.duplicate(allocator, paths.global_cache_root orelse group.globalCacheRoot());
        Builder.initializeGroup(allocator, node);
        return node;
    }
    pub fn addBuild(group: *Node5, allocator: *mem.SimpleAllocator, build_cmd: types.BuildCommand, name: []const u8, root: []const u8) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        const node: *Node5 = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node5), @alignOf(Node5)));
        node.tasks.cmd.build = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.BuildCommand), @alignOf(types.BuildCommand)));
        const binary_path: *types.Path = node.lists.add(allocator, .paths);
        const root_path: *types.Path = node.lists.add(allocator, .paths);
        group.lists.add(allocator, .nodes).* = node;
        node.lists.add(allocator, .nodes).* = group;
        node.tag = .worker;
        node.tasks.tag = .build;
        node.flags = .{};
        node.name = com.duplicate(allocator, name);
        node.tasks.cmd.build.* = build_cmd;
        binary_path.addName(allocator).* = group.buildRoot();
        binary_path.addName(allocator).* = Builder.binaryRelative(allocator, node, build_cmd.kind);
        root_path.addName(allocator).* = group.buildRoot();
        root_path.addName(allocator).* = com.duplicate(allocator, root);
        Builder.initializeCommand(allocator, node);
        return node;
    }
    pub fn addRun(group: *Node5, allocator: *mem.SimpleAllocator, name: []const u8, args: []const []const u8) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        const node: *Node5 = @ptrFromInt(allocator.allocateRaw(@sizeOf(Node5), @alignOf(Node5)));
        group.lists.add(allocator, .nodes).* = node;
        node.lists.add(allocator, .nodes).* = group;
        node.tag = .worker;
        node.tasks.tag = .run;
        node.flags = .{};
        node.name = com.duplicate(allocator, name);
        for (args) |arg| node.lists.add(allocator, .run_args).* = com.duplicate(allocator, arg);
        Builder.initializeCommand(allocator, node);
        return node;
    }
    pub fn addDepn(node: *Node5, allocator: *mem.SimpleAllocator, task: types.Task, on_node: *Node5, on_task: types.Task) void {
        @setRuntimeSafety(builtin.is_safe);
        const idx: Size = node.lists.len(.nodes);
        const dep: *Depn = node.lists.add(allocator, .deps);
        node.lists.add(allocator, .nodes).* = on_node;
        if (task == .run) {
            if (on_task == .build and node == on_node) {
                node.lists.add(allocator, .args).* = node.lists.get(.paths)[0].concatenate(allocator);
            }
        }
        const on_paths: []types.Path = on_node.lists.get(.paths);
        if (task == .build) {
            if (on_task == .archive) {
                node.lists.add(allocator, .paths).* = on_paths[0];
            }
            if (on_task == .build and
                on_node.tasks.cmd.build.kind == .obj)
            {
                node.lists.add(allocator, .paths).* = on_paths[0];
            }
        }
        if (task == .archive) {
            if (on_task == .build and
                on_node.tasks.cmd.build.kind == .obj)
            {
                node.lists.add(allocator, .paths).* = on_paths[0];
            }
        }
        dep.* = .{ .task = task, .on_task = on_task, .on_state = .finished, .on_idx = idx };
    }
    pub fn dependOn(node: *Node5, allocator: *mem.SimpleAllocator, on_node: *Node5) void {
        node.addDepn(
            allocator,
            if (node == on_node) .run else node.tasks.tag,
            on_node,
            on_node.tasks.tag,
        );
    }
    pub fn groupNode(node: *Node5) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        return node.lists.get(.nodes)[0];
    }
    pub fn zigExe(node: *Node5) [:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().zigExe();
        }
        return node.lists.get(.paths)[0].names[0];
    }
    pub fn buildRoot(node: *Node5) [:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().buildRoot();
        }
        return node.lists.get(.paths)[1].names[0];
    }
    pub fn cacheRoot(node: *Node5) [:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().cacheRoot();
        }
        return node.lists.get(.paths)[2].names[0];
    }
    pub fn globalCacheRoot(node: *Node5) [:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().globalCacheRoot();
        }
        return node.lists.get(.paths)[3].names[0];
    }
    pub fn buildRootFd(node: *Node5) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().buildRoot();
        }
        return node.extra.get(.dir_fds).build_root;
    }
    pub fn configRootFd(node: *Node5) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().configRootFd();
        }
        return node.extra.get(.dir_fds).config_root;
    }
    pub fn outputRootFd(node: *Node5) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tag == .worker) {
            return node.groupNode().outputRootFd();
        }
        return node.extra.get(.dir_fds).output_root;
    }
    pub fn vTable() usize {
        @setRuntimeSafety(builtin.is_safe);
        return libraryNode().extra.get(.load).vtable_addr;
    }
    fn dynLoader() usize {
        @setRuntimeSafety(builtin.is_safe);
        return Node5.toplevel.extra.get(.loader_addr);
    }
    fn libraryNode() *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        return Node5.toplevel.find("zero", '.').?;
    }
    pub fn extensionNode(name: [:0]const u8) *Node5 {
        @setRuntimeSafety(builtin.is_safe);
        return libraryNode().find(name, '.').?;
    }
    pub fn hasDebugInfo(node: *Node5) bool {
        @setRuntimeSafety(builtin.is_safe);
        if (node.tasks.cmd.build.strip) |strip| {
            return !strip;
        } else {
            return (node.tasks.cmd.build.mode orelse .Debug) != .ReleaseSmall;
        }
    }
    pub fn formatWriteNameFull(node: *const Node5, sep: u8, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf;
        if (!node.flags.is_toplevel) {
            ptr += node.lists.get(.nodes)[0].formatWriteNameFull(sep, ptr);
            if (ptr != buf) {
                ptr[0] = sep;
                ptr += 1;
            }
            @memcpy(ptr, node.name);
            ptr += node.name.len;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLengthNameFull(node: *const Node5) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        if (!node.flags.is_toplevel) {
            len +%= node.lists.get(.nodes)[0].formatLengthNameFull();
            len +%= @intFromBool(len != 0) +% node.name.len;
        }
        return len;
    }
    pub fn formatWriteNameRelative(node: *const Node5, group: *const Node5, sep: u8, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf;
        if (node != group) {
            ptr += node.lists.get(.nodes)[0].formatWriteNameRelative(sep, ptr);
            if (ptr != buf) {
                ptr[0] = sep;
                ptr += 1;
            }
            @memcpy(ptr, node.name);
            ptr += node.name.len;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLengthNameRelative(node: *const Node5, group: *const Node5) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        if (node != group) {
            len +%= node.lists.get(.nodes)[0].formatLengthNameRelative(group);
            len +%= @intFromBool(len != 0) +% node.name.len;
        }
        return len;
    }
    pub fn formatWriteConfigRootName(node: *const Node5, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf + node.formatWriteNameFull('-', buf);
        ptr[0..4].* = ".zig".*;
        ptr += 4;
        ptr[0] = 0;
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    pub fn formatWriteConfigRoot(node: *const Node5, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        const paths: []types.Path = node.lists.get(.paths);
        const nodes: []*Node5 = node.lists.get(.nodes);
        const deps: []Depn = node.lists.get(.deps);
        const cfgs: []types.Config = node.lists.get(.cfgs);
        const build_cmd: *types.BuildCommand = node.tasks.cmd.build;
        var ptr: [*]u8 = buf;
        ptr[0..31].* = "pub usingnamespace @import(\"../".*;
        ptr += 31;
        @memcpy(ptr, paths[1].names[1]);
        ptr += paths[1].names[1].len;
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
            for (deps) |dep| {
                if (nodes[dep.on_idx] == node) {
                    continue;
                }
                if (dep.on_task == .build and
                    nodes[dep.on_idx].tasks.cmd.build.kind == out)
                {
                    const on_paths: []types.Path = nodes[dep.on_idx].lists.get(.paths);
                    ptr[0..12].* = "pub const @\"".*;
                    ptr += 12;
                    @memcpy(ptr, nodes[dep.on_idx].name);
                    ptr += nodes[dep.on_idx].name.len;
                    ptr[0..15].* = "\":[:0]const u8=".*;
                    ptr += 15;
                    ptr[0] = '"';
                    ptr += 1;
                    ptr += on_paths[0].formatWriteBuf(ptr);
                    ptr = ptr - 1;
                    ptr[0..3].* = "\";\n".*;
                    ptr += 3;
                }
            }
        }
        ptr[0..3].* = "};\n".*;
        ptr += 3;
        for (cfgs) |cfg| {
            ptr += cfg.formatWriteBuf(ptr);
        }
        ptr[0..26].* = "pub const build_config=.@\"".*;
        ptr += 26;
        @memcpy(ptr, node.name);
        ptr += node.name.len;
        ptr[0..3].* = "\";\n".*;
        ptr += 3;
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    pub fn find(group: *Node5, name: []const u8, sep: u8) ?*Node5 {
        @setRuntimeSafety(builtin.is_safe);
        const nodes: []*Node5 = group.lists.get(.nodes);
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
            return null;
        }
        const group_name: []const u8 = name[0..idx];
        idx +%= 1;
        if (idx == name.len) {
            return null;
        }
        const sub_name: []const u8 = name[idx..];
        idx = 1;
        while (idx != nodes.len) : (idx +%= 1) {
            if (nodes[idx].tag == .group and
                mem.testEqualString(group_name, nodes[idx].name))
            {
                return find(nodes[idx], sub_name, sep);
            }
        }
        return null;
    }
    const Builder = builtin.root.Builder;
};
