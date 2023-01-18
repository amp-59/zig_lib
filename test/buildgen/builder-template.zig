//! start
const sys = struct {};
const mem = struct {};
const file = struct {};
const meta = struct {};
const proc = struct {};
const preset = struct {};
const builtin = struct {};
// start-document builder-struct.zig
const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.fmt;
    tmp.integral = .{ .format = .dec };
    break :blk tmp;
};
pub const BuildCmdSpec = struct {
    max_len: u64 = 1024 * 1024,
    max_args: u64 = 1024,
    Allocator: ?type = null,
};

pub const AddressSpace = preset.address_space.exact_8;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
pub const String = Allocator.StructuredVectorLowAligned(u8, 8);
pub const Pointers = Allocator.StructuredVector([*:0]u8);
pub const StaticString = mem.StructuredAutomaticVector(u8, null, max_len, 8, .{});
pub const StaticPointers = mem.StructuredAutomaticVector([*:0]u8, null, max_args, 8, .{});

const max_len: u64 = 65536;
const max_args: u64 = 512;

pub const BuildCmd = struct {
    const Builder: type = @This();
    const zig: [:0]const u8 = "zig";
    zig_exe: ?[:0]const u8 = null,
    cmd: enum { exe, lib, obj, fmt, ast_check, run },
    root: [:0]const u8,
    _: void,
    pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
        var array: String = try meta.wrap(String.init(allocator, build.buildLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, build.buildWrite(&array)));
        builtin.assertAboveOrEqual(u64, max_args, makeArgs(array, &args));
        builtin.assertAboveOrEqual(u64, max_len, array.len());
        defer args.deinit(allocator);
        return build.genericExec(args.referAllDefined(), vars);
    }
    pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        _ = build.buildWrite(&array);
        _ = makeArgs(&array, &args);
        return build.genericExec(args.referAllDefined(), vars);
    }
    fn genericExec(builder: Builder, args: [][*:0]u8, vars: [][*:0]u8) !u64 {
        return proc.command(.{}, builder.zig_exe.?, args, vars);
    }
};
/// Environment variables needed to find user home directory
pub fn zigCacheDirGlobal(vars: [][*:0]u8, buf: [:0]u8) ![:0]u8 {
    const home_pathname: [:0]const u8 = try file.home(vars);
    var len: u64 = 0;
    for (home_pathname) |c, i| buf[len + i] = c;
    len += home_pathname.len;
    for ("/.cache/zig") |c, i| buf[len + i] = c;
    return buf[0 .. len + 11 :0];
}
fn countArgs(array: anytype) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count += 1;
        }
    }
    return count + 1;
}
fn makeArgs(array: anytype, args: anytype) u64 {
    var idx: u64 = 0;
    for (array.readAll()) |c, i| {
        if (c == 0) {
            args.writeOne(array.referManyWithSentinelAt(idx, 0).ptr);
            idx = i + 1;
        }
    }
    if (args.len() != 0) {
        mem.set(args.impl.next(), @as(u64, 0), 1);
    }
    return args.len();
}
// finish-document builder-struct.zig
// start-document builder-types.zig
pub const Packages = []const Pkg;
pub const Macros = []const Macro;
pub const Pkg = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(pkg: Pkg, array: anytype) void {
        array.writeMany("--pkg-begin");
        array.writeOne(0);
        array.writeMany(pkg.name);
        array.writeOne(0);
        array.writeMany(pkg.path);
        array.writeOne(0);
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                array.writeOne(0);
                dep.formatWrite(array);
            }
        }
        array.writeMany("--pkg-end");
        array.writeOne(0);
    }
    pub fn formatLength(pkg: Pkg) u64 {
        var len: u64 = 0;
        len +%= 11;
        len +%= 1;
        len +%= pkg.name.len;
        len +%= 1;
        len +%= pkg.path.len;
        len +%= 1;
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                len +%= 1;
                len +%= dep.formatLength();
            }
        }
        len +%= 9;
        len +%= 1;
        return len;
    }
};
/// Zig says value does not need to be defined, in which case default to 1
pub const Macro = struct {
    name: []const u8,
    value: ?[]const u8,
    quote: bool = false,
    const Format = @This();

    fn looksLikePath(format: Format) bool {
        var no_sep: u64 = 0;
        if (format.value) |value| {
            for (value) |c| {
                if (c == '/') no_sep += 1;
            }
        }
        return no_sep > 1;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        if (format.value) |value| {
            array.writeMany("=");
            if (format.quote or format.looksLikePath()) {
                array.writeOne('"');
                array.writeMany(value);
                array.writeOne('"');
            } else {
                array.writeMany(value);
            }
        }
        array.writeOne(0);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        if (format.value) |value| {
            len +%= 1;
            if (format.quote or format.looksLikePath()) {
                len +%= 1;
                len +%= value.len;
                len +%= 1;
            } else {
                len +%= value.len;
            }
        }
        len +%= 1;
        return len;
    }
};
pub const Context = struct {
    zig_exe: [:0]const u8,
    build_root: [:0]const u8,
    cache_dir: [:0]const u8,
    global_cache_dir: [:0]const u8,
    args: [][*:0]u8,
    vars: [][*:0]u8,

    pub fn path(ctx: *Context, name: [:0]const u8) Path {
        return .{ .ctx = ctx, .relative = name };
    }
};
pub const Path = struct {
    ctx: *Context,
    relative: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.ctx.build_root);
        array.writeOne('/');
        array.writeMany(format.relative);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= format.ctx.build_root.len;
        len +%= 1;
        len +%= format.relative.len;
        return len;
    }
};
// finish-document builder-types.zig
