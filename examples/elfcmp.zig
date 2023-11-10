const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const debug = zl.debug;
pub usingnamespace zl.start;
pub const LoaderSpace = mem.GenericDiscreteAddressSpace(.{
    .index_type = u8,
    .label = "ld",
    .list = &[2]mem.Arena{
        .{ .lb_addr = 0x400000000, .up_addr = 0x800000000 },
        .{ .lb_addr = 0x800000000, .up_addr = 0xc00000000 },
    },
});
pub const DynamicLoader = zl.elf.GenericDynamicLoader(.{
    .errors = .{},
    .options = .{},
    .AddressSpace = LoaderSpace,
    .logging = .{
        .show_insignificant = true,
        .show_insignificant_additions = true,
        .show_insignificant_deletions = true,
        .show_insignificant_increases = true,
        .show_insignificant_decreases = true,
    },
});
const about_s: fmt.AboutSrc = fmt.about("xelf");
const width: usize = fmt.aboutCentre(about_s);
fn findPath(allocator: *mem.SimpleAllocator, vars: [][*:0]u8, name: [:0]u8) ![:0]u8 {
    if (name[0] == '/') {
        return name;
    }
    if (zl.file.accessAt(.{}, .{ .symlink_no_follow = false }, zl.file.cwd, name, .{ .read = true })) |_| {
        return name;
    } else |err| {
        if (err != error.NoSuchFileOrDirectory and
            err != error.Access)
        {
            return err;
        }
    }
    var itr: zl.proc.PathIterator = .{
        .paths = zl.proc.environmentValue(vars, "PATH").?,
    };
    defer itr.done();
    while (itr.next()) |dirname| {
        const dir_fd: usize = try zl.file.path(.{}, .{}, dirname);
        try zl.file.close(.{}, dir_fd);
        const ret: bool = zl.file.accessAt(.{}, .{ .symlink_no_follow = false }, dir_fd, name, .{ .read = true }) catch {
            continue;
        };
        if (ret) {
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(dirname.len, 1));
            var ptr: [*]u8 = fmt.strcpyEqu(buf, dirname);
            ptr[0] = '/';
            ptr = fmt.strcpyEqu(ptr + 1, name);
            ptr[1] = 0;
            return mem.terminate(buf, 0);
        }
    }
    return name;
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    var ei1: *DynamicLoader.ElfInfo = allocator.create(DynamicLoader.ElfInfo);
    var ei2: *DynamicLoader.ElfInfo = allocator.create(DynamicLoader.ElfInfo);
    var cmp: *DynamicLoader.compare.Cmp = allocator.create(DynamicLoader.compare.Cmp);
    var ld: DynamicLoader = .{};
    defer ld.unmapAll();
    if (args.len == 1) {
        return;
    }
    if (args.len >= 2) {
        ei1.* = try ld.load(try findPath(&allocator, vars, mem.terminate(args[1], 0)));
    }
    if (args.len == 2) {
        const len: usize = DynamicLoader.compare.lengthElf(cmp, &allocator, ei1, width);
        const buf: []u8 = allocator.allocate(u8, len);
        const end: [*]u8 = DynamicLoader.compare.writeElf(cmp, buf.ptr, ei1, width);
        debug.assertEqual(usize, len, fmt.strlen(end, buf.ptr));
        debug.write(buf[0..len]);
    } else for (args[2..]) |arg| {
        const name: [:0]u8 = mem.terminate(arg, 0);
        ei2.* = try ld.load(try findPath(&allocator, vars, name));
        var len: usize = DynamicLoader.compare.compareElfInfo(cmp, &allocator, ei1, ei2, 2);
        const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len, 1));
        fmt.print(DynamicLoader.compare.writeElfDifferences(cmp, buf, ei1, ei2, 2), buf);
    }
}
