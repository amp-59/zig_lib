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
    .logging = .{},
    .errors = .{},
    .AddressSpace = LoaderSpace,
});
const about_s: fmt.AboutSrc = fmt.about("xelf");
const width: usize = fmt.aboutCentre(about_s);

fn findPath(allocator: *mem.SimpleAllocator, vars: [][*:0]u8, name: [:0]u8) ![:0]u8 {
    if (name[0] == '/') {
        return name;
    }
    if (zl.file.accessAt(.{}, .{ .symlink_no_follow = false }, zl.file.cwd, name, .{ .exec = true })) |_| {
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
        defer zl.file.close(.{ .errors = .{} }, dir_fd);
        const ret: bool = zl.file.accessAt(.{}, .{ .symlink_no_follow = false }, dir_fd, name, .{ .exec = true }) catch {
            continue;
        };
        if (ret) {
            const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(dirname.len, 1));
            var ptr: [*]u8 = fmt.strcpyEqu(buf, dirname);
            ptr[0] = '/';
            ptr += 1;
            ptr = fmt.strcpyEqu(ptr, name);
            ptr[1] = 0;
            return mem.terminate(buf, 0);
        }
    }
    return name;
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var allocator: mem.SimpleAllocator = .{};
    var info1: *DynamicLoader.Info = @ptrFromInt(8);
    var info2: *DynamicLoader.Info = @ptrFromInt(8);
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024 *% 1024, 1));
    var ld: DynamicLoader = .{};
    if (args.len == 1) {
        return;
    }
    if (args.len >= 2) {
        const name: [:0]u8 = mem.terminate(args[1], 0);
        info1 = try ld.load(try findPath(&allocator, vars, name));
    }
    if (args.len == 2) {
        debug.write(buf[0..fmt.strlen(DynamicLoader.compare.writeBinary(buf, info1, width), buf)]);
    } else for (args[2..]) |arg| {
        const name: [:0]u8 = mem.terminate(arg, 0);
        info2 = try ld.load(try findPath(&allocator, vars, name));
        debug.write(buf[0..fmt.strlen(DynamicLoader.compare.writeBinaryDifference(buf, info1, info2, width), buf)]);
        info1 = info2;
    }
}
