const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const elf = zl.elf;
const spec = zl.spec;
const proc = zl.proc;
const meta = zl.meta;
const build = zl.build;
const debug = zl.debug;
const virtual = zl.virtual;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;

pub const logging_default = spec.logging.default.verbose;

const AddressSpace = virtual.GenericRegularAddressSpace(virtual.RegularAddressSpaceSpec{
    .label = "builder_space",
    .lb_addr = 0x40000000,
    .up_addr = 0x80000000,
    .divisions = 1,
    .alignment = 4096,
    .subspace = virtual.genericSlice(.{
        .{
            .label = "Loader",
            .list = &[2]mem.Arena{ .{
                .lb_addr = 0x40000000,
                .up_addr = 0x50000000,
            }, .{
                .lb_addr = 0x50000000,
                .up_addr = 0x60000000,
            } },
        },
        .{
            .label = "Heap",
            .lb_addr = 0x60000000,
            .up_addr = 0x70000000,
            .divisions = 16,
            .alignment = 4096,
            .options = .{ .thread_safe = false },
        },
        .{
            .label = "Stack",
            .lb_addr = 0x70000000,
            .up_addr = 0x80000000,
            .divisions = 16,
            .alignment = 4096,
            .options = .{ .thread_safe = true },
        },
    }),
});
const LoaderAddressSpace = AddressSpace.SubSpace("Loader");

fn testObjcopyCommand(args: [][*:0]u8, ptrs: *build.Fns) void {
    var format_cmd: build.ObjcopyCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.formatParseArgsObjcopyCommand(&format_cmd, &allocator, args.ptr, args.len);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.formatWriteBufObjcopyCommand(&format_cmd, builtin.root.zig_exe.ptr, builtin.root.zig_exe.len, &paths, 1, &buf);
    var pos: usize = 0;
    for (buf[0..len], 0..) |byte, idx| {
        if (byte == 0) {
            buf[idx] = '\n';
            debug.write(buf[pos .. idx + 1]);
            buf[idx] = 0;
            pos = idx +% 1;
        }
    }
}
fn testArchiveCommand(args: [][*:0]u8, ptrs: *build.Fns) void {
    var format_cmd: build.ArchiveCommand = .{ .operation = .x };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.formatParseArgsArchiveCommand(&format_cmd, &allocator, args.ptr, args.len);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.formatWriteBufArchiveCommand(&format_cmd, builtin.root.zig_exe.ptr, builtin.root.zig_exe.len, &paths, 1, &buf);
    var pos: usize = 0;
    for (buf[0..len], 0..) |byte, idx| {
        if (byte == 0) {
            buf[idx] = '\n';
            debug.write(buf[pos .. idx + 1]);
            buf[idx] = 0;
            pos = idx +% 1;
        }
    }
}
fn testFormatCommand(args: [][*:0]u8, ptrs: *build.Fns) void {
    var format_cmd: build.FormatCommand = .{ .ast_check = true };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.formatParseArgsFormatCommand(&format_cmd, &allocator, args.ptr, args.len);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.formatWriteBufFormatCommand(&format_cmd, builtin.root.zig_exe.ptr, builtin.root.zig_exe.len, paths[0], &buf);
    var pos: usize = 0;
    for (buf[0..len], 0..) |byte, idx| {
        if (byte == 0) {
            buf[idx] = '\n';
            debug.write(buf[pos .. idx + 1]);
            buf[idx] = 0;
            pos = idx +% 1;
        }
    }
}
fn testBuildCommand(args: [][*:0]u8, ptrs: *build.Fns) void {
    var build_cmd: build.BuildCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.formatParseArgsBuildCommand(&build_cmd, &allocator, args.ptr, args.len);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.formatWriteBufBuildCommand(&build_cmd, builtin.root.zig_exe.ptr, builtin.root.zig_exe.len, &paths, 1, &buf);
    var pos: usize = 0;
    for (buf[0..len], 0..) |byte, idx| {
        if (byte == 0) {
            buf[idx] = '\n';
            debug.write(buf[pos .. idx + 1]);
            buf[idx] = 0;
            pos = idx +% 1;
        }
    }
}
fn testEntryAutoLoader() !void {
    var loader: Loader = .{};
    const build_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_build_core));
    const build_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_build_extra));
    const format_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_format_core));
    const format_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_format_extra));
    const archive_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_archive_core));
    const archive_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_archive_extra));
    const objcopy_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_objcopy_core));
    const objcopy_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units._test_objcopy_extra));

    const VTable = struct {
        perf: @import("../top/build/perf.auto.zig") = .{},
        build_core: @import("../top/build/build_core.auto.zig") = .{},
        build_extra: @import("../top/build/build_extra.auto.zig") = .{},
        format_core: @import("../top/build/format_core.auto.zig") = .{},
        format_extra: @import("../top/build/format_extra.auto.zig") = .{},
        archive_core: @import("../top/build/archive_core.auto.zig") = .{},
        archive_extra: @import("../top/build/archive_extra.auto.zig") = .{},
        objcopy_core: @import("../top/build/objcopy_core.auto.zig") = .{},
        objcopy_extra: @import("../top/build/objcopy_extra.auto.zig") = .{},
    };
    var vtable: VTable = .{};

    build_core_info.autoLoad(&vtable.build_core);
    build_extra_info.autoLoad(&vtable.build_extra);
    format_core_info.autoLoad(&vtable.format_core);
    format_extra_info.autoLoad(&vtable.format_extra);
    objcopy_core_info.autoLoad(&vtable.objcopy_core);
    objcopy_extra_info.autoLoad(&vtable.objcopy_extra);
    archive_core_info.autoLoad(&vtable.archive_core);
    archive_extra_info.autoLoad(&vtable.archive_extra);

    {
        const cmd1 = .{ .kind = .lib, .mode = .ReleaseSafe };
        const cmd2 = .{ .kind = .exe, .mode = .ReleaseFast };
        const core = vtable.build_core;
        const extra = vtable.build_extra;

        var buf: [4096]u8 = undefined;
        var len: usize = 0;
        const zig_exe: []const u8 = builtin.root.zig_exe;
        const paths: []const build.Path = &.{build.Path.create(&.{ builtin.root.main_pkg_path, @src().file })};
        len = core.formatWriteBuf(@constCast(&cmd1), zig_exe, paths, &buf);
        debug.write(buf[0..len]);
        try debug.expect(len == core.formatLength(@constCast(&cmd1), zig_exe, paths));
        len = extra.writeFieldEditDistance(&buf, "name", @constCast(&cmd1), @constCast(&cmd2), false);
        debug.write(buf[0..len]);
        len = extra.fieldEditDistance(@constCast(&cmd1), @constCast(&cmd2));
        try debug.expect(len == 2);
    }
}
inline fn makeArgs(comptime args: []const [:0]const u8) [][*:0]u8 {
    comptime {
        var ret: [args.len][*:0]u8 = undefined;
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            ret[args_idx] = @constCast(args[args_idx].ptr);
        }
        return &ret;
    }
}
noinline fn doIt(loader: *Loader, pathname: [:0]const u8, ptrs: *build.Fns) blk: {
    const E = meta.ReturnErrorSet(Loader.load);
    if (E == error{}) {
        break :blk void;
    }
    break :blk E!void;
} {
    const info: *Loader.Info = try meta.wrap(loader.load(pathname));
    info.loadPointers(build.Fns, ptrs);
}
const Loader = elf.GenericDynamicLoader(.{
    .options = .{ .show_sections = true, .show_defined = true },
    .logging = .{},
    .errors = if (builtin.strip_debug_info) spec.loader.errors.noexcept else .{},
});
fn testConcurrentLoading() !void {
    var count: usize = 0;
    var allocator: mem.SimpleAllocator = .{};
    const stack1: []usize = allocator.allocate(usize, 1024 * 1024);
    const stack2: []usize = allocator.allocate(usize, 1024 * 1024);
    const ptrs: *build.Fns = allocator.create(build.Fns);
    var loader: Loader = .{};
    while (count != 100) : (count +%= 1) {
        ptrs.* = .{};
        stack1[0] = 0;
        stack2[0] = 0;
        if (builtin.strip_debug_info) {
            _ = try proc.clone(.{}, @intFromPtr(stack2.ptr), stack2.len, {}, doIt, .{
                &loader, builtin.root.dynamic_units._test_parsers, ptrs,
            });
            _ = try proc.clone(.{}, @intFromPtr(stack1.ptr), stack1.len, {}, doIt, .{
                &loader, builtin.root.dynamic_units._test_writers, ptrs,
            });
        } else {
            _ = try meta.wrap(@call(.auto, doIt, .{
                &loader, builtin.root.dynamic_units._test_parsers, ptrs,
            }));
            _ = try meta.wrap(@call(.auto, doIt, .{
                &loader, builtin.root.dynamic_units._test_writers, ptrs,
            }));
        }
        const words: *[@sizeOf(build.Fns) / @sizeOf(usize)]usize = @ptrCast(ptrs);
        lo: while (true) {
            for (words) |*word| {
                if (@atomicLoad(usize, word, .SeqCst) == 8) {
                    continue :lo;
                }
            } else {
                break;
            }
        }
        testBuildCommand(makeArgs(&.{ "-OReleaseFast", "-fClang" }), ptrs);
        testFormatCommand(makeArgs(&.{"--ast_check"}), ptrs);
        testArchiveCommand(makeArgs(&.{"cr"}), ptrs);
        lo: while (true) {
            if (@atomicLoad(usize, &stack1[0], .SeqCst) != 0) {
                continue :lo;
            }
            if (@atomicLoad(usize, &stack2[0], .SeqCst) != 0) {
                continue :lo;
            }
            break;
        }
        try mem.unmap(.{}, Loader.lb_info_addr, loader.ub_info_addr -% Loader.lb_info_addr);
        loader.ub_info_addr = Loader.lb_info_addr;
        try mem.unmap(.{}, Loader.lb_sect_addr, loader.ub_sect_addr -% Loader.lb_sect_addr);
        loader.ub_sect_addr = Loader.lb_sect_addr;
        // This is simply to mess up the starting alignment of the loader
        loader.ub_info_addr += count;
    }
}
pub fn main() !void {
    try testConcurrentLoading();
    try testEntryAutoLoader();
}
