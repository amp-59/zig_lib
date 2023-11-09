const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const logging_default: zl.debug.Logging.Default = zl.debug.spec.logging.default.silent;
pub const signal_handlers: zl.debug.SignalHandlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
};
const creat_flags = .{ .truncate = true, .read_write = true };
const statx_fields = .{ .ino = true, .mtime = true, .atime = true, .ctime = true };
const stat_at_flags = .{ .empty_path = true };
const open_flags = .{ .path = true, .directory = true };
const INodes = zl.mem.array.StaticArray(usize, 1024);
fn allocatePath(
    path_allocator: *zl.mem.SimpleAllocator,
    dirname: []const u8,
    basename: []const u8,
) [:0]const u8 {
    const buf: [*]u8 = @ptrFromInt(path_allocator.allocateRaw(dirname.len +% basename.len +% 2, 1));
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, dirname);
    if (basename.len == 1 and basename[0] == '.') {
        ptr[0] = 0;
        return buf[0..dirname.len :0];
    }
    ptr[0] = '/';
    ptr += @intFromBool(dirname.len != 0);
    ptr = zl.fmt.strcpyEqu(ptr, basename);
    ptr[0] = 0;
    return buf[0 .. dirname.len +% basename.len +% 1 :0];
}
fn allocateFileBuf(
    file_allocator: *zl.mem.SimpleAllocator,
    root_fd: usize,
    file_st: *const zl.file.StatusExtended,
    name: [:0]const u8,
) ![*:0]u8 {
    var buf: [*]u8 = @ptrFromInt(file_allocator.allocateRaw(file_st.size +% 1, 8));
    var cache_file_fd: usize = zl.file.openAt(.{ .errors = .{} }, .{}, root_fd, name);
    try zl.file.read(.{ .return_type = void }, cache_file_fd, buf[0..file_st.size]);
    try zl.file.close(.{}, cache_file_fd);
    buf[file_st.size] = 0;
    return buf[0..file_st.size :0];
}
fn createMirrorFileSystemCache(
    file_allocator: *zl.mem.SimpleAllocator,
    path_allocator: *zl.mem.SimpleAllocator,
    build_inodes: *INodes,
    build_root: [:0]const u8,
    build_root_fd: usize,
    cache_inodes: *INodes,
    cache_root: [:0]const u8,
    cache_root_fd: usize,
    name: [:0]const u8,
) !usize {
    var misses: usize = 0;
    var cache_file_st: zl.file.StatusExtended = .{};
    var build_file_st: zl.file.StatusExtended = .{};
    zl.file.statusExtended(.{ .errors = .{} }, .{}, statx_fields, cache_root_fd, name, &cache_file_st);
    for (cache_inodes.readAll()) |ino| {
        if (ino == cache_file_st.ino) return misses;
    }
    try zl.file.statusExtended(.{}, .{}, statx_fields, build_root_fd, name, &build_file_st);
    if (cache_file_st.mode.kind == .regular) blk: {
        const path_save: usize = path_allocator.next;
        const file_save: usize = file_allocator.next;
        if (cache_file_st.mtime.sec < build_file_st.mtime.sec or
            cache_file_st.mtime.sec == build_file_st.mtime.sec and
            cache_file_st.mtime.nsec < build_file_st.mtime.nsec)
        {
            misses +%= 1;
            break :blk;
        }
        cache_inodes.writeOne(cache_file_st.ino);
        const buf: [*:0]u8 = try allocateFileBuf(file_allocator, cache_root_fd, &cache_file_st, name);
        var ptr: [*]u8 = buf;
        while (buf + cache_file_st.size != ptr) : (path_allocator.next = path_save) {
            const import: []const u8 = zl.mem.terminate(ptr, 0);
            misses +%= try createMirrorFileSystemCache(file_allocator, path_allocator, //
                build_inodes, build_root, build_root_fd, cache_inodes, cache_root, cache_root_fd, //
                allocatePath(path_allocator, zl.file.dirname(name), import));
            ptr += import.len +% 1;
        }
        file_allocator.next = file_save;
        return misses;
    }
    for (build_inodes.readAll()) |ino| {
        if (ino == build_file_st.ino) return misses;
    }
    const save: usize = file_allocator.next;
    const dirname: []const u8 = zl.file.dirname(name);
    if (dirname.len != 0) {
        try zl.file.makePathAt(.{}, cache_root_fd, dirname, zl.file.mode.directory);
    }
    try zl.file.statusExtended(.{}, stat_at_flags, statx_fields, cache_root_fd, &.{}, &cache_file_st);
    const cache_file_fd: usize = try zl.file.createAt(.{}, creat_flags, cache_root_fd, name, zl.file.mode.regular);
    const buf: [*:0]u8 = try allocateFileBuf(file_allocator, build_root_fd, &build_file_st, name);
    var itr: zl.builtin.parse.TokenIterator = .{ .buf = buf[0..build_file_st.size :0] };
    var tok: zl.builtin.parse.Token = .{ .tag = .invalid, .loc = .{} };
    const tmp: []u8 = file_allocator.allocate(u8, build_file_st.size);
    var ptr: [*]u8 = tmp.ptr;
    while (tok.tag != .eof) : (tok = itr.nextToken()) {
        if (tok.tag == .builtin and zl.mem.testEqualString("@import", itr.buf[tok.loc.start..tok.loc.finish])) {
            tok = itr.nextToken();
            tok = itr.nextToken();
            if (zl.mem.testEqualString(".zig", itr.buf[tok.loc.finish -% 5 .. tok.loc.finish -% 1])) {
                itr.buf[tok.loc.finish -% 1] = 0;
                ptr = zl.fmt.strcpyEqu(ptr, itr.buf[tok.loc.start +% 1 .. tok.loc.finish :0]);
            }
        }
    }
    try zl.file.write(.{}, cache_file_fd, zl.fmt.slice(ptr, tmp.ptr));
    try zl.file.close(.{}, cache_file_fd);
    file_allocator.next = save;
    return misses +% try createMirrorFileSystemCache(file_allocator, path_allocator, //
        build_inodes, build_root, build_root_fd, cache_inodes, cache_root, cache_root_fd, name);
}
pub fn main(args: [][*:0]u8) !void {
    var file_allocator: zl.mem.SimpleAllocator = .{
        .start = 0x100000000,
        .next = 0x100000000,
        .finish = 0x100000000,
    };
    var path_allocator: zl.mem.SimpleAllocator = .{
        .start = 0x40000000,
        .next = 0x40000000,
        .finish = 0x40000000,
    };
    const build_root: [:0]const u8 = zl.mem.terminate(args[2], 0);
    const cache_root: [:0]const u8 = zl.mem.terminate(args[3], 0);
    const pathname: [:0]const u8 = zl.mem.terminate(args[5], 0);
    const cache_m_root: [:0]const u8 = allocatePath(&path_allocator, cache_root, "m");
    const build_root_fd: usize = try zl.file.openAt(.{}, open_flags, zl.file.cwd, build_root);
    var build_inodes: INodes = undefined;
    var cache_inodes: INodes = undefined;
    build_inodes.undefineAll();
    cache_inodes.undefineAll();
    zl.file.makeDirAt(.{ .errors = .{} }, build_root_fd, "zig-cache", zl.file.mode.directory);
    zl.file.makeDirAt(.{ .errors = .{} }, build_root_fd, "zig-cache/m", zl.file.mode.directory);
    const cache_m_root_fd: usize = try zl.file.openAt(.{}, open_flags, zl.file.cwd, cache_m_root);
    const misses: usize = try createMirrorFileSystemCache(&file_allocator, &path_allocator, &build_inodes, build_root, build_root_fd, &cache_inodes, cache_m_root, cache_m_root_fd, pathname);
    try zl.file.close(.{}, build_root_fd);
    try zl.file.close(.{}, cache_m_root_fd);
    if (misses == 0) {
        zl.debug.write("hit\n");
    } else {
        zl.debug.write("missed\n");
    }
}
