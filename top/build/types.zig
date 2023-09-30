const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");

pub const Path = file.CompoundPath;

pub const Allocator = mem.SimpleAllocator;

pub const File = enum(u8) {
    exe = exe,
    lib = lib,
    obj = obj,
    ar = ar,
    @"asm" = @"asm",
    llvm_ir = llvm_ir,
    llvm_bc = llvm_bc,
    h = h,
    docs = docs,
    analysis = analysis,
    zig = zig,
    c = c,
    dir = dir,
    cfg = cfg,
    unknown,

    const exe = 0;
    const lib = 1;
    const obj = 2;
    const ar = 3;
    const @"asm" = 4;
    const llvm_ir = 5;
    const llvm_bc = 6;
    const h = 7;
    const docs = 8;
    const analysis = 9;
    const zig = 10;
    const c = 11;
    const dir = 12;
    const cfg = 13;
};
pub const BinaryOutput = enum(u8) {
    exe = File.exe,
    lib = File.lib,
    obj = File.obj,
};
pub const AuxiliaryOutput = enum(u8) {
    ar = File.ar,
    @"asm" = File.@"asm",
    llvm_ir = File.llvm_ir,
    llvm_bc = File.llvm_bc,
    h = File.h,
    docs = File.docs,
    analysis = File.analysis,
};
pub const Output = enum(u8) {
    exe = File.exe,
    lib = File.lib,
    obj = File.obj,
    ar = File.ar,
    @"asm" = File.@"asm",
    llvm_ir = File.llvm_ir,
    llvm_bc = File.llvm_bc,
    h = File.h,
    docs = File.docs,
    analysis = File.analysis,
};
pub const Input = enum(u8) {
    lib = File.lib,
    obj = File.obj,
    ar = File.ar,
    @"asm" = File.@"asm",
    llvm_ir = File.llvm_ir,
    llvm_bc = File.llvm_bc,
    h = File.h,
    zig = File.zig,
    c = File.c,
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
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: []const []const u8 = &.{},
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
        return @intFromPtr(ptr + 1) -% @intFromPtr(buf);
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
        const len: usize = @intFromPtr(ptr) -% @intFromPtr(buf);
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
        return @intFromPtr(ptr) -% @intFromPtr(buf);
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
        return @intFromPtr(ptr) -% @intFromPtr(buf);
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
