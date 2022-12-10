const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub const Open = meta.EnumBitField(enum(u64) {
    no_cache = OPEN.DIRECT,
    no_atime = OPEN.NOATIME,
    no_follow = OPEN.NOFOLLOW,
    no_block = OPEN.NONBLOCK,
    no_ctty = OPEN.NOCTTY,
    close_on_exec = OPEN.CLOEXEC,
    temporary = OPEN.TMPFILE,
    directory = OPEN.DIRECTORY,
    path = OPEN.PATH,
    append = OPEN.APPEND,
    truncate = OPEN.TRUNC,
    create = OPEN.CREAT,
    read_only = OPEN.RDONLY,
    write_only = OPEN.WRONLY,
    read_write = OPEN.RDWR,
    exclusive = OPEN.EXCL,
    const OPEN = sys.O;
});
const Mode = meta.EnumBitField(enum(u16) {
    owner_read = MODE.IRUSR,
    owner_write = MODE.IWUSR,
    owner_execute = MODE.IXUSR,
    group_read = MODE.IRGRP,
    group_write = MODE.IWGRP,
    group_execute = MODE.IXGRP,
    other_read = MODE.IROTH,
    other_write = MODE.IWOTH,
    other_execute = MODE.IXOTH,
    regular = MODE.IFREG,
    directory = MODE.IFDIR,
    character_special = MODE.IFCHR,
    block_special = MODE.IFBLK,
    named_pipe = MODE.IFIFO,
    socket = MODE.IFSOCK,
    symbolic_link = MODE.IFLNK,

    const MODE = sys.S;
});

pub fn read(fd: u64, read_buf: []u8, count: u64) !u64 {
    const read_buf_addr: u64 = @ptrToInt(read_buf.ptr);
    if (sys.read(fd, read_buf_addr, count)) |ret| {
        return ret;
    } else |read_error| {
        if (builtin.is_correct) {
            debug.readError(read_error, fd);
        }
        return read_error;
    }
}
pub fn write(fd: u64, write_buf: []const u8) !void {
    const write_buf_addr: u64 = @ptrToInt(write_buf.ptr);
    if (sys.write(fd, write_buf_addr, write_buf.len)) |ret| {
        builtin.assertEqual(u64, write_buf.len, ret);
    } else |write_error| {
        if (builtin.is_correct) {
            debug.writeError(write_error, fd);
        }
        return write_error;
    }
}
pub const noexcept = opaque {
    pub fn write(fd: u64, buf: []const u8) void {
        sys.noexcept.write(fd, @ptrToInt(buf.ptr), buf.len);
    }
};

const debug = opaque {
    const about_read_0_s: []const u8 = "read:           ";
    const about_read_1_s: []const u8 = "read-error:     ";
    const about_write_0_s: []const u8 = "write:          ";
    const about_write_1_s: []const u8 = "write-error:    ";

    fn print(buf: []u8, ss: []const []const u8) void {
        var len: u64 = 0;
        for (ss) |s| {
            for (s) |c, i| buf[len + i] = c;
            len += s.len;
        }
        noexcept.write(2, buf[0..len]);
    }
    fn readError(read_error: anytype, fd: u64) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        print(&buf, &[_][]const u8{ about_read_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), " (", @errorName(read_error), ")\n" });
    }
    fn writeError(write_error: anytype, fd: u64) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        print(&buf, &[_][]const u8{ about_write_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), " (", @errorName(write_error), ")\n" });
    }
};
