const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
const builtin = @import("./builtin.zig");

const dmode_owner: Perms = .{ .read = true, .write = true, .execute = true };
const dmode_group: Perms = .{ .read = true, .write = false, .execute = true };
const dmode_other: Perms = .{ .read = false, .write = false, .execute = false };
const fmode_owner: Perms = .{ .read = true, .write = true, .execute = false };
const fmode_group: Perms = .{ .read = true, .write = false, .execute = false };
const fmode_other: Perms = .{ .read = false, .write = false, .execute = false };

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

pub const ModeSpec = struct {
    owner: Perms,
    group: Perms,
    other: Perms,
    pub const file_mode: ModeSpec = .{
        .owner = fmode_owner,
        .group = fmode_group,
        .other = fmode_other,
    };
    pub const dir_mode: ModeSpec = .{
        .owner = dmode_owner,
        .group = dmode_group,
        .other = dmode_other,
    };
    fn mode(comptime mode_spec: ModeSpec) Mode {
        var mode_bitfield: Mode = .{ .val = 0 };
        if (mode_spec.owner.read) {
            mode_bitfield.set(.owner_read);
        }
        if (mode_spec.owner.write) {
            mode_bitfield.set(.owner_write);
        }
        if (mode_spec.owner.execute) {
            mode_bitfield.set(.owner_execute);
        }
        if (mode_spec.group.read) {
            mode_bitfield.set(.group_read);
        }
        if (mode_spec.group.write) {
            mode_bitfield.set(.group_write);
        }
        if (mode_spec.group.execute) {
            mode_bitfield.set(.group_execute);
        }
        if (mode_spec.other.read) {
            mode_bitfield.set(.other_read);
        }
        if (mode_spec.other.write) {
            mode_bitfield.set(.other_write);
        }
        if (mode_spec.other.execute) {
            mode_bitfield.set(.other_execute);
        }
        return mode_bitfield;
    }
    fn describeBriefly(comptime perms: Perms) []const u8 {
        var descr: []const u8 = meta.empty;
        if (perms.read) {
            descr = descr ++ "r";
        } else {
            descr = descr ++ "-";
        }
        if (perms.write) {
            descr = descr ++ "w";
        } else {
            descr = descr ++ "-";
        }
        if (perms.execute) {
            descr = descr ++ "x";
        } else {
            descr = descr ++ "-";
        }
        return descr;
    }
    fn describe(comptime mode_spec: ModeSpec) []const u8 {
        if (builtin.is_small) {
            var descr: []const u8 = meta.empty;
            descr = descr ++ describeBriefly(mode_spec.owner);
            descr = descr ++ describeBriefly(mode_spec.group);
            descr = descr ++ describeBriefly(mode_spec.other);
            return descr;
        } else {
            var owner: ?[]const u8 = null;
            if (mode_spec.owner.read) {
                owner = "owner: read";
            }
            if (mode_spec.owner.write) {
                owner = if (owner) |owner_s| owner_s ++ "+write" else "owner: write";
            }
            if (mode_spec.owner.execute) {
                owner = if (owner) |owner_s| owner_s ++ "+execute" else "owner: execute";
            }
            var group: ?[]const u8 = null;
            if (mode_spec.group.read) {
                group = "group: read";
            }
            if (mode_spec.group.write) {
                group = if (group) |group_s| group_s ++ "+write" else "group: write";
            }
            if (mode_spec.group.execute) {
                group = if (group) |group_s| group_s ++ "+execute, " else "group: execute";
            }
            var other: ?[]const u8 = null;
            if (mode_spec.other.read) {
                other = "other read";
            }
            if (mode_spec.other.write) {
                other = if (other) |other_s| other_s ++ "+write" else "other: write";
            }
            if (mode_spec.other.execute) {
                other = if (other) |other_s| other_s ++ "+execute" else "other: execute";
            }
            if (owner) |owner_s| {
                if (group) |group_s| {
                    if (other) |other_s| {
                        return owner_s ++ ", " ++ group_s ++ ", " ++ other_s;
                    }
                    return owner_s ++ ", " ++ group_s;
                } else if (other) |other_s| {
                    return owner_s ++ ", " ++ other_s;
                }
                return owner_s;
            }
            if (group) |group_s| {
                if (other) |other_s| {
                    return group_s ++ ", " ++ other_s;
                }
                return group_s;
            }
            if (other) |other_s| {
                return other_s;
            }
        }
    }
};
pub const MakeDirSpec = struct {
    options: Options = .{},
    mode: ModeSpec = ModeSpec.dir_mode,
    errors: ?[]const sys.ErrorCode = sys.mkdir_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
        exclusive: bool = true,
    };
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const RemoveDirSpec = struct {
    errors: ?[]const sys.ErrorCode = sys.rmdir_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const special_fn = sys.special.rmdir;
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const CreateSpec = struct {
    options: Options = .{},
    mode: ModeSpec = ModeSpec.file_mode,
    errors: ?[]const sys.ErrorCode = sys.open_errors,
    return_type: type = u64,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
        exclusive: bool = true,
        temporary: bool = false,
        close_on_exec: bool = true,
        write: ?OpenSpec.Write = .truncate,
        read: bool = false,
    };
    fn flags(comptime spec: CreateSpec) Open {
        var flags_bitfield: Open = .{ .tag = .create };
        if (spec.options.exclusive) {
            flags_bitfield.set(.exclusive);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (spec.options.temporary) {
            flags_bitfield.set(.temporary);
        }
        if (spec.options.write) |w| {
            if (spec.options.read) {
                flags_bitfield.set(.read_write);
            } else {
                flags_bitfield.set(.write_only);
            }
            switch (w) {
                .append => {
                    flags_bitfield.set(.append);
                },
                .truncate => {
                    flags_bitfield.set(.truncate);
                },
            }
        } else if (spec.options.read) {
            flags_bitfield.set(.read_only);
        }
        return flags_bitfield;
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const UnlinkSpec = struct {
    errors: ?[]const sys.ErrorCode = sys.unlink_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const PathSpec = struct {
    options: Options = .{},
    errors: ?[]const sys.ErrorCode = sys.open_errors,
    return_type: type = u64,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
        directory: bool = true,
        no_follow: bool = true,
        close_on_exec: bool = true,
    };
    pub fn flags(comptime spec: PathSpec) Open {
        var flags_bitfield: Open = .{ .tag = .path };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (spec.options.directory) {
            flags_bitfield.set(.directory);
        }
        return flags_bitfield;
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const OpenSpec = struct {
    options: Options,
    return_type: type = u64,
    errors: ?[]const sys.ErrorCode = sys.open_errors,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
        read: bool = true,
        write: ?Write = null,
        directory: bool = false,
        temporary: bool = false,
        no_atime: bool = false,
        no_ctty: bool = true,
        no_follow: bool = true,
        no_block: bool = false,
        no_cache: bool = false,
        close_on_exec: bool = true,
    };
    const Write = enum { append, truncate };
    pub fn flags(comptime spec: OpenSpec) Open {
        var flags_bitfield: Open = .{ .val = 0 };
        if (spec.options.no_cache) {
            flags_bitfield.set(.no_cache);
        }
        if (spec.options.no_atime) {
            flags_bitfield.set(.no_atime);
        }
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        if (spec.options.no_block) {
            flags_bitfield.set(.no_block);
        }
        if (spec.options.no_ctty) {
            flags_bitfield.set(.no_ctty);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (spec.options.temporary) {
            flags_bitfield.set(.temporary);
        }
        if (spec.options.directory) {
            flags_bitfield.set(.directory);
        }
        if (spec.options.write) |w| {
            if (spec.options.read) {
                flags_bitfield.set(.read_write);
            } else {
                flags_bitfield.set(.write_only);
            }
            switch (w) {
                .append => {
                    flags_bitfield.set(.append);
                },
                .truncate => {
                    flags_bitfield.set(.truncate);
                },
            }
        } else if (spec.options.read) {
            flags_bitfield.set(.read_only);
        }
        return flags_bitfield;
    }
    usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const CloseSpec = struct {
    logging: bool = builtin.is_verbose,
    errors: ?[]const sys.ErrorCode = sys.close_errors,
    return_type: type = void,
    const Specification = @This();
    usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const StatSpec = struct {
    options: Options = .{},
    errors: ?[]const sys.ErrorCode = sys.stat_errors,
    return_type: type = void,

    const STAT = sys.AT;
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
    };
    fn flags(comptime spec: StatSpec) Open {
        var flags_bitfield: Open = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
    usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const ReadLinkSpec = struct {
    options: Options = .{},
    errors: ?[]const sys.ErrorCode = sys.readlink_errors,
    return_type: type = u64,
    logging: bool = builtin.is_verbose,

    const STAT = sys.AT;
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
    };
    fn flags(comptime spec: StatSpec) Open {
        var flags_bitfield: Open = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
    usingnamespace sys.FunctionInterfaceSpec(Specification);
};

// TODO: Define default options suited to mapping files
pub const MapSpec = struct {
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.mmap_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
        anonymous: bool,
        visibility: Visibility,
        read: bool,
        write: bool,
        exec: bool,
        populate: bool,
        grows_down: bool,
        sync: bool,
    };
    const Visibility = enum { shared, shared_validate, private };
    pub fn flags(comptime spec: MapSpec) mem.Map {
        var flags_bitfield: mem.Map = .{ .tag = .fixed_no_replace };
        switch (spec.options.visibility) {
            .private => flags_bitfield.set(.private),
            .shared => flags_bitfield.set(.shared),
            .shared_validate => flags_bitfield.set(.shared_validate),
        }
        if (spec.options.anonymous) {
            flags_bitfield.set(.anonymous);
        }
        if (spec.options.grows_down) {
            flags_bitfield.set(.grows_down);
            flags_bitfield.set(.stack);
        }
        if (spec.options.populate) {
            builtin.static.assert(spec.options.visibility == .private);
            flags_bitfield.set(.populate);
        }
        if (spec.options.sync) {
            builtin.static.assert(spec.options.visibility == .shared_validate);
            flags_bitfield.set(.sync);
        }
        return flags_bitfield;
    }
    pub fn prot(comptime spec: MapSpec) mem.Prot {
        var prot_bitfield: mem.Prot = .{ .val = 0 };
        if (spec.options.read) {
            prot_bitfield.set(.read);
        }
        if (spec.options.write) {
            prot_bitfield.set(.write);
        }
        if (spec.options.exec) {
            prot_bitfield.set(.exec);
        }
        return prot_bitfield;
    }
    usingnamespace sys.FunctionInterfaceSpec(Specification);
};

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
