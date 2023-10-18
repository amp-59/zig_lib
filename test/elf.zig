const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const elf = zl.elf;
const proc = zl.proc;
const meta = zl.meta;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const logging_default = debug.spec.logging.default.verbose;
pub const Builder = build.GenericBuilder(.{});
pub const AbsoluteState = struct {
    home: [:0]u8,
    cwd: [:0]u8,
    proj: [:0]u8,
    pid: u16,
};
const AddressSpace = mem.GenericRegularAddressSpace(mem.RegularAddressSpaceSpec{
    .label = "builder_space",
    .lb_addr = 0x40000000,
    .up_addr = 0x80000000,
    .divisions = 1,
    .alignment = 4096,
    .subspace = mem.genericSlice(.{
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
fn testObjcopyCommand(args: [][*:0]u8, ptrs: *Builder.FunctionPointers) void {
    var format_cmd: build.ObjcopyCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.objcopy_cmd_core_fns.formatParseArgs(&format_cmd, &allocator, args);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.objcopy_cmd_core_fns.formatWriteBuf(&format_cmd, builtin.root.zig_exe, &paths, &buf);
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
fn testArchiveCommand(args: [][*:0]u8, ptrs: *Builder.FunctionPointers) void {
    var format_cmd: build.ArchiveCommand = .{ .operation = .x };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.archive_cmd_core_fns.formatParseArgs(&format_cmd, &allocator, args);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.archive_cmd_core_fns.formatWriteBuf(&format_cmd, builtin.root.zig_exe, &paths, &buf);
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
fn testFormatCommand(args: [][*:0]u8, ptrs: *Builder.FunctionPointers) void {
    var format_cmd: build.FormatCommand = .{ .ast_check = true };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.format_cmd_core_fns.formatParseArgs(&format_cmd, &allocator, args);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.format_cmd_core_fns.formatWriteBuf(&format_cmd, builtin.root.zig_exe, paths[0], &buf);
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
fn testBuildCommand(args: [][*:0]u8, ptrs: *Builder.FunctionPointers) void {
    var build_cmd: build.BuildCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};
    var buf: [32768]u8 = undefined;
    ptrs.build.formatParseArgs(&build_cmd, &allocator, args);
    const paths: [1]build.Path = .{.{ .names = @constCast(&[1][:0]const u8{"one.zig"}) }};
    var len: usize = ptrs.build.formatWriteBuf(&build_cmd, builtin.root.zig_exe, &paths, &buf);
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
    const build_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.build));
    const build_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.build_extra));
    const format_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.format));
    const format_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.format_extra));
    const archive_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.archive));
    const archive_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.archive_extra));
    const objcopy_core_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.objcopy));
    const objcopy_extra_info: *Loader.Info = try meta.wrap(loader.load(builtin.root.dynamic_units.objcopy_extra));
    var vtable: Builder.FunctionPointers = .{};
    build_core_info.autoLoad(&vtable);
    build_extra_info.autoLoad(&vtable);
    format_core_info.autoLoad(&vtable);
    format_extra_info.autoLoad(&vtable);
    objcopy_core_info.autoLoad(&vtable);
    objcopy_extra_info.autoLoad(&vtable);
    archive_core_info.autoLoad(&vtable);
    archive_extra_info.autoLoad(&vtable);
    {
        const cmd1 = .{ .kind = .lib, .mode = .ReleaseSafe };
        const cmd2 = .{ .kind = .exe, .mode = .ReleaseFast };
        const core = vtable.build_cmd_core_fns;
        const extra = vtable.build_cmd_extra_fns;
        var buf: [4096]u8 = undefined;
        var len: usize = 0;
        const zig_exe: []const u8 = builtin.root.zig_exe;
        const paths: []const build.Path = &.{build.Path.create(&.{ builtin.root.main_mod_path, @src().file })};
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
noinline fn doIt(loader: *Loader, pathname: [:0]const u8, ptrs: *Builder.FunctionPointers) blk: {
    const E = meta.ReturnErrorSet(Loader.load);
    if (E == error{}) {
        break :blk void;
    }
    break :blk E!void;
} {
    const info: *Loader.Info = try meta.wrap(loader.load(pathname));
    inline for (@typeInfo(Builder.FunctionPointers).Struct.fields) |field| {
        const load: *fn (*@TypeOf(@field(ptrs, field.name))) void = @ptrFromInt(info.ehdr.e_entry);
        load(&@field(ptrs, field.name));
    }
}
const Loader = elf.GenericDynamicLoader(.{
    .AddressSpace = LoaderAddressSpace,
    .logging = .{},
    .errors = if (builtin.strip_debug_info) elf.spec.loader.errors.noexcept else .{},
});
fn testConcurrentLoading() !void {
    const build_core = "../top/build/build.auto.zig";
    const format_core = "../top/build/format.auto.zig";
    const archive_core = "../top/build/archive.auto.zig";
    _ = archive_core;
    const objcopy_core = "../top/build/objcopy.auto.zig";
    _ = objcopy_core;
    var count: usize = 0;
    var allocator: mem.SimpleAllocator = .{};
    const stack1: []usize = allocator.allocate(usize, 1024 * 1024);
    const stack2: []usize = allocator.allocate(usize, 1024 * 1024);
    const ptrs: *Builder.FunctionPointers = allocator.create(Builder.FunctionPointers);
    var loader: Loader = .{};
    while (count != 100) : (count +%= 1) {
        mem.zero(Builder.FunctionPointers, ptrs);
        stack1[0] = 0;
        stack2[0] = 0;
        if (builtin.strip_debug_info) {
            _ = try proc.clone(.{}, @intFromPtr(stack2.ptr), stack2.len, {}, doIt, .{
                &loader, build_core, ptrs,
            });
            _ = try proc.clone(.{}, @intFromPtr(stack1.ptr), stack1.len, {}, doIt, .{
                &loader, format_core, ptrs,
            });
        } else {
            _ = try meta.wrap(@call(.auto, doIt, .{
                &loader, build_core, ptrs,
            }));
            _ = try meta.wrap(@call(.auto, doIt, .{
                &loader, format_core, ptrs,
            }));
        }
        const words: *[@sizeOf(Builder.FunctionPointers) / @sizeOf(usize)]usize = @ptrCast(ptrs);
        lo: while (true) {
            for (words) |*word| {
                if (@atomicLoad(usize, word, .SeqCst) == 8) {
                    continue :lo;
                }
            } else {
                break;
            }
        }
        testBuildCommand(makeArgs(&.{"-OReleaseFast"}), ptrs);
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
        try mem.unmap(.{}, Loader.lb_meta_addr, loader.ub_meta_addr -% Loader.lb_meta_addr);
        loader.ub_meta_addr = Loader.lb_meta_addr;
        try mem.unmap(.{}, Loader.lb_prog_addr, loader.ub_prog_addr -% Loader.lb_prog_addr);
        loader.ub_prog_addr = Loader.lb_prog_addr;
        // This is simply to mess up the starting alignment of the loader
        loader.ub_meta_addr += count;
    }
}
fn quickCompile(comptime builder_spec: build.BuilderSpec, build_cmd: build.BuildCommand, name: [:0]const u8, pathname: []const u8) !void {
    const LBuilder = build.GenericBuilder(builder_spec);
    var address_space: LBuilder.AddressSpace = .{};
    var thread_space: LBuilder.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.fromArena(
        LBuilder.AddressSpace.arena(LBuilder.max_thread_count),
    );
    var zig_exe = builtin.root.zig_exe.*;
    var build_root = builtin.root.build_root.*;
    var cache_root = builtin.root.cache_root.*;
    var global_cache_root = builtin.root.global_cache_root.*;
    var args: [5:builtin.zero([*:0]u8)][*:0]u8 = .{
        undefined,
        &zig_exe,
        &build_root,
        &cache_root,
        &global_cache_root,
    };
    var vars: [0:builtin.zero([*:0]u8)][*:0]u8 = .{};
    const top: *LBuilder.Node = LBuilder.Node.init(&allocator, "toplevel", &args, &vars);
    const node: *LBuilder.Node = top.addBuild(&allocator, build_cmd, name, pathname);
    if (!LBuilder.prepareCommand(&address_space, &thread_space, &allocator, node, node.tasks.tag, LBuilder.max_thread_count)) {
        return error.FailedToPrepareTask;
    }
    if (!LBuilder.executeSubNode(&address_space, &thread_space, &allocator, node, node.tasks.tag)) {
        return error.FailedToExecuteTask;
    }
    allocator.unmapAll();
}
fn testBasics() !void {
    var allocator: mem.SimpleAllocator = .{};
    var buf: []u8 = allocator.allocate(u8, 1024 * 1024);
    var loader: Loader = .{};
    if (@hasDecl(builtin.root.dynamic_units, "build")) {
        const info: *Loader.Info = try loader.load(builtin.root.dynamic_units.build);
        var vtable: Builder.FunctionPointers = .{};
        const ptr = Loader.about.aboutBinary(null, info, buf.ptr);
        debug.write(buf[0..fmt.strlen(ptr, buf.ptr)]);
        if (info.symbol("top.build.tasks.BuildCommand.formatWriteBuf")) |formatWriteBuf| {
            vtable.build.formatWriteBuf = @ptrFromInt(info.prog.addr +% formatWriteBuf.st_value);
        }
        var build_cmd: build.BuildCommand = .{ .kind = .exe };
        debug.write(buf[0..vtable.build.formatWriteBuf(
            &build_cmd,
            builtin.root.zig_exe,
            &.{build.Path.create(&.{@src().file})},
            buf.ptr,
        )]);
    }
}
pub fn main() !void {
    try quickCompile(.{
        .logging = build.spec.logging.silent,
    }, .{ .kind = .lib }, "build", "../top/build/build.auto.zig");
}
