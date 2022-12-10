const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
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

pub const Stat = extern struct {
    dev: u64,
    ino: u64,
    nlink: u64,
    mode: Mode,
    _: [2]u8,
    uid: u32,
    gid: u32,
    __: [4]u8,
    rdev: u64,
    size: u64,
    blksize: u64,
    blocks: u64,
    atime: time.TimeSpec = .{},
    mtime: time.TimeSpec = .{},
    ctime: time.TimeSpec = .{},
    ___: [20]u8,
    pub fn isDirectory(st: Stat) bool {
        return st.mode.check(.directory);
    }
    pub fn isCharacterSpecial(st: Stat) bool {
        return st.mode.check(.character_special);
    }
    pub fn isBlockSpecial(st: Stat) bool {
        return st.mode.check(.block_special);
    }
    pub fn isRegular(st: Stat) bool {
        return st.mode.check(.regular);
    }
    pub fn isNamedPipe(st: Stat) bool {
        return st.mode.check(.named_pipe);
    }
    pub fn isSymbolicLink(st: Stat) bool {
        return st.mode.check(.symbolic_link);
    }
    pub fn isSocket(st: Stat) bool {
        return st.mode.check(.socket);
    }
    pub fn isExecutable(st: Stat, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.check(.owner_execute);
        }
        if (group_id == st.gid) {
            return st.mode.check(.group_execute);
        }
        return st.mode.check(.other_execute);
    }
    const S = sys.S;
};
pub const StatX = extern struct {
    mask: u32,
    blksize: u32,
    attributes: u64,
    nlink: u32,
    uid: u32,
    gid: u32,
    mode: u16,
    __pad0: [2]u8,
    ino: u64,
    size: u64,
    blocks: u64,
    attributes_mask: u64,
    atime: time.TimeSpec,
    btime: time.TimeSpec,
    ctime: time.TimeSpec,
    mtime: time.TimeSpec,
    rdev_major: u32,
    rdev_minor: u32,
    dev_major: u32,
    dev_minor: u32,
    mnt_id: u64,
    __pad3: [104]u8,
};
pub const DirectoryEntry = extern struct {
    inode: u64,
    offset: u64,
    reclen: u16,
    kind: u8,
    array: u8,
};
const Perms = struct { read: bool, write: bool, execute: bool };

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
