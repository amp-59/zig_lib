const root = @import("@build");
const zl = blk: {
    if (@hasDecl(root, "zl")) {
        break :blk root.zl;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
pub usingnamespace zl.start;
pub const is_safe: bool = enable_debugging;
pub const runtime_assertions: bool = enable_debugging;
pub const want_stack_traces: bool = enable_debugging;
pub const have_stack_traces: bool = false;
pub const AbsoluteState = struct {
    home: [:0]u8,
    cwd: [:0]u8,
    proj: [:0]u8,
    pid: u16,
};
pub const debug_write_fd = 2;
pub const Builder =
    if (@hasDecl(root, "Builder")) root.Builder else zl.builder.GenericBuilder(.{});
pub const message_style: [:0]const u8 =
    if (@hasDecl(root, "message_style")) root.message_style else "\x1b[2m";
pub const enable_debugging: bool = true;
pub const trace: zl.debug.Trace =
    if (@hasDecl(root, "trace")) root.trace else zl.builtin.zl_trace;
pub const logging_override: zl.debug.Logging.Override = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = true,
    .Fault = true,
};
pub const logging_default: zl.debug.Logging.Default = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = true,
    .Fault = true,
};
pub const signal_handlers = .{
    .IllegalInstruction = enable_debugging,
    .BusError = enable_debugging,
    .FloatingPointError = enable_debugging,
    .Trap = enable_debugging,
    .SegmentationFault = enable_debugging,
};
pub const BuildConfig = struct {
    packages: []Pkg,
    include_dirs: []const []const u8,
    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,
    };
};
const tab = .{
    .name = "\"name\":",
    .path = "\"path\":",
    .packages = "\"packages\":",
    .include_dirs = "\"include_dirs\":",
};
fn jsonLength(cfg: *const BuildConfig) usize {
    @setRuntimeSafety(zl.builtin.is_safe);
    var len: usize = 1 +% tab.packages.len;
    if (cfg.packages.len == 0) {
        len +%= 3;
    } else {
        len +%= 8 +%
            tab.name.len +% cfg.packages[0].name.len +%
            tab.path.len +% cfg.packages[0].path.len;
        var pkg_idx: usize = 1;
        while (pkg_idx != cfg.packages.len) : (pkg_idx +%= 1) {
            len +%= 8 +%
                tab.name.len +% cfg.packages[pkg_idx].name.len +%
                tab.path.len +% cfg.packages[pkg_idx].path.len;
        }
        len +%= 2;
    }
    len +%= tab.include_dirs.len;
    if (cfg.include_dirs.len == 0) {
        len +%= 2;
    } else {
        len +%= 3 +% cfg.include_dirs[0].len;
        var dir_idx: usize = 1;
        while (dir_idx != cfg.include_dirs.len) : (dir_idx +%= 1) {
            len +%= 3 +% cfg.include_dirs[dir_idx].len;
        }
        len +%= 1;
    }
    return len +% 1;
}
fn writePackage(pkg: BuildConfig.Pkg, buf: [*]u8) usize {
    @setRuntimeSafety(zl.builtin.is_safe);
    var ptr: [*]u8 = buf;
    ptr[0] = '{';
    ptr += 1;
    ptr[0..tab.name.len].* = tab.name.*;
    ptr += tab.name.len;
    ptr[0] = '"';
    ptr += 1;
    @memcpy(ptr, pkg.name);
    ptr += pkg.name.len;
    ptr[0] = '"';
    ptr[1] = ',';
    ptr += 2;
    ptr[0..tab.path.len].* = tab.path.*;
    ptr += tab.path.len;
    ptr[0] = '"';
    ptr += 1;
    @memcpy(ptr, pkg.path);
    ptr += pkg.path.len;
    ptr[0] = '"';
    ptr[1] = '}';
    return @intFromPtr(ptr - @intFromPtr(buf)) +% 2;
}
fn jsonWriteBuf(cfg: *const BuildConfig, buf: [*]u8) usize {
    @setRuntimeSafety(zl.builtin.is_safe);
    var ptr: [*]u8 = buf;
    ptr[0] = '{';
    ptr += 1;
    ptr[0..tab.packages.len].* = tab.packages.*;
    ptr += tab.packages.len;
    if (cfg.packages.len == 0) {
        ptr[0..3].* = "[],".*;
        ptr += 3;
    } else {
        ptr[0] = '[';
        ptr += 1;
        ptr += writePackage(cfg.packages[0], buf);
        var pkg_idx: usize = 1;
        while (pkg_idx != cfg.packages.len) : (pkg_idx +%= 1) {
            ptr[0] = ',';
            ptr += 1;
            ptr += writePackage(cfg.packages[pkg_idx], ptr);
        }
        ptr[0] = ']';
        ptr[1] = ',';
        ptr += 2;
    }
    ptr[0..tab.include_dirs.len].* = tab.include_dirs.*;
    ptr += tab.include_dirs.len;
    if (cfg.include_dirs.len == 0) {
        ptr[0..2].* = "[]".*;
        ptr += 2;
    } else {
        ptr[0] = '[';
        ptr[1] = '"';
        ptr += 2;
        ptr = zl.fmt.strcpyEqu(ptr, cfg.include_dirs[0]);
        ptr[0] = '"';
        ptr += 1;
        var dir_idx: usize = 1;
        while (dir_idx != cfg.include_dirs.len) : (dir_idx +%= 1) {
            ptr[0] = ',';
            ptr[1] = '"';
            ptr += 2;
            ptr = zl.fmt.strcpyEqu(ptr, cfg.include_dirs[dir_idx]);
            ptr[0] = '"';
            ptr += 1;
        }
        ptr[0] = ']';
        ptr += 1;
    }
    ptr[0] = '}';
    return @intFromPtr(ptr - @intFromPtr(buf)) +% 1;
}
fn lengthModules(node: *Builder.Node) usize {
    @setRuntimeSafety(zl.builtin.is_safe);
    var itr: Builder.Node.Iterator = Builder.Node.Iterator.init(node);
    var len: usize = 0;
    while (itr.next()) |sub_node| {
        if (sub_node.flags.is_group) {
            len +%= lengthModules(sub_node);
        } else if (sub_node.tasks.tag == .build and
            sub_node.flags.have_task_data)
        {
            if (sub_node.lists.mods.len != 1) {
                len +%= sub_node.lists.mods.len;
            }
        }
    }
    return len;
}
fn writeModulesBuf(allocator: *zl.builder.types.Allocator, pkgs: [*]BuildConfig.Pkg, node: *Builder.Node) usize {
    @setRuntimeSafety(zl.builtin.is_safe);
    var itr: Builder.Node.Iterator = Builder.Node.Iterator.init(node);
    var len: usize = 0;
    while (itr.next()) |sub_node| {
        if (sub_node.flags.is_group) {
            len +%= writeModulesBuf(allocator, pkgs, sub_node);
        } else if (sub_node.tasks.tag == .build and
            sub_node.flags.have_task_data)
        {
            const paths = sub_node.modulePathLists(allocator);
            if (sub_node.lists.mods.len != 1) {
                for (sub_node.lists.mods[1..], paths[1..]) |mod, path| {
                    pkgs[len] = .{
                        .name = mod.name orelse "anonymous",
                        .path = path.concatenate(allocator)[node.buildRoot().len +% 1 ..],
                    };
                    len +%= 1;
                }
            }
        }
    }
    return len;
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) void {
    @setRuntimeSafety(false);
    const arena = Builder.AddressSpace.arena(Builder.specification.options.max_thread_count);
    zl.mem.map(.{
        .errors = .{},
        .logging = .{ .Acquire = false },
    }, .{}, .{}, arena.lb_addr, 4096);
    var allocator: zl.builder.types.Allocator = .{
        .start = arena.lb_addr,
        .next = arena.lb_addr,
        .finish = arena.lb_addr +% 4096,
    };
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    const top: *Builder.Node = Builder.Node.init(&allocator, args, vars);
    top.sh.as.lock = &address_space;
    top.sh.ts.lock = &thread_space;
    try zl.meta.wrap(root.buildMain(&allocator, top));
    const pkgs_len: usize = lengthModules(top);
    const pkgs: []BuildConfig.Pkg = try zl.meta.wrap(
        allocator.allocate(BuildConfig.Pkg, pkgs_len),
    );
    const cfg: BuildConfig = .{
        .packages = pkgs[0..writeModulesBuf(&allocator, pkgs.ptr, top)],
        .include_dirs = &.{},
    };
    const buf: []u8 = try zl.meta.wrap(
        allocator.allocate(u8, jsonLength(&cfg)),
    );
    zl.file.write(.{ .errors = .{} }, 1, buf[0..jsonWriteBuf(&cfg, buf.ptr)]);
}
