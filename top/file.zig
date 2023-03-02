const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const builtin = @import("./builtin.zig");
const _dir = @import("./dir.zig");
pub usingnamespace _dir;
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
const Term = opaque {
    const Input = meta.EnumBitField(enum(u32) {
        ignore_break = IN.IGNBRK,
        break_interrupt = IN.BRKINT,
        ignore_errors = IN.IGNPAR,
        mark_errors = IN.PARMRK,
        check_input_parity = IN.INPCK,
        strip = IN.STRIP,
        ignore_carriage_return = IN.IGNCR,
        translate_carriage_return = IN.CRNL,
        lower = IN.UCLC,
        upper = IN.LCUC,
        const IN = sys.TC.I;
    });
    const Output = meta.EnumBitField(enum(u32) {
        post_processing = OUT.POST,
        translate_carriage_return = OUT.CRNL,
        no_carriage_return = OUT.NOCR,
        newline_return = OUT.NLRET,
        lower = OUT.UCLC,
        upper = OUT.LCUC,
        const OUT = sys.TC.O;
    });
    const Control = meta.EnumBitField(enum(u32) {
        baud_rate = CTL.BAUD,
        baud_rate_extra = CTL.BAUDEX,
        baud_rate_input = CTL.IBAUD,
        char_size = CTL.SIZE,
        enable_receiver = CTL.READ,
        parity = CTL.PARENB,
        parity_odd = CTL.PARODD,
        ignore_modem = CTL.LOCAL,
        const CTL = sys.TC.C;
    });
    const Local = meta.EnumBitField(enum(u32) {
        signal = LOC.ISIG,
        signal_disable_flush = LOC.NOFLSH,
        canonical_mode = LOC.ICANON,
        echo = LOC.ECHO,
        canonical_echo_erase = LOC.ECHOE,
        canonical_echo_kill = LOC.ECHOK,
        canonical_echo_newline = LOC.ECHONL,
        const LOC = sys.TC.L;
    });
    const Special = meta.EnumBitField(enum(u8) {
        end_of_file = SPEC.EOF,
        end_of_line = SPEC.EOL,
        erase = SPEC.ERASE,
        interrupt = SPEC.INTR,
        const SPEC = sys.TC.V;
    });
};
pub const Domain = enum(u64) {
    unix = AF.UNIX,
    ipv4 = AF.INET,
    ipv6 = AF.INET6,
    const AF = sys.AF;
};
pub const Connection = enum(u64) {
    tcp = SOCK.STREAM,
    udp = SOCK.DGRAM,
    const SOCK = sys.SOCK;
};
pub const Socket = meta.EnumBitField(enum(u64) {
    non_block = SOCK.NONBLOCK,
    close_on_exec = SOCK.CLOEXEC,
    pub const Address = extern struct {
        family: u16,
        data: [14]u8,
    };
    pub const AddressIPv4 = extern struct {
        family: u16,
        port: u16,
        addr: extern struct { addr: u32 },
        @"0": [8]u8,
    };
    pub const AddressIPv6 = extern struct {
        family: u16,
        port: u16,
        flow_info: u32,
        addr: extern struct { addr: [8]u16 },
        scope_id: u32,
    };
    const SOCK = sys.SOCK;
});
pub const FileStatus = extern struct {
    dev: u64,
    ino: u64,
    nlink: u64,
    mode: Mode,
    @"0": [2]u8,
    uid: u32,
    gid: u32,
    @"1": [4]u8,
    rdev: u64,
    size: u64,
    blksize: u64,
    blocks: u64,
    atime: time.TimeSpec = .{},
    mtime: time.TimeSpec = .{},
    ctime: time.TimeSpec = .{},
    pub fn isDirectory(st: FileStatus) bool {
        return st.mode.check(.directory);
    }
    pub fn isCharacterSpecial(st: FileStatus) bool {
        return st.mode.check(.character_special);
    }
    pub fn isBlockSpecial(st: FileStatus) bool {
        return st.mode.check(.block_special);
    }
    pub fn isRegular(st: FileStatus) bool {
        return st.mode.check(.regular);
    }
    pub fn isNamedPipe(st: FileStatus) bool {
        return st.mode.check(.named_pipe);
    }
    pub fn isSymbolicLink(st: FileStatus) bool {
        return st.mode.check(.symbolic_link);
    }
    pub fn isSocket(st: FileStatus) bool {
        return st.mode.check(.socket);
    }
    pub fn isExecutable(st: FileStatus, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.check(.owner_execute);
        }
        if (group_id == st.gid) {
            return st.mode.check(.group_execute);
        }
        return st.mode.check(.other_execute);
    }
};
pub const Stat = FileStatus;
pub const FileStatusExtra = extern struct {
    mask: u32,
    blksize: u32,
    attributes: u64,
    nlink: u32,
    uid: u32,
    gid: u32,
    mode: u16,
    @"0": [2]u8,
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
    @"1": [104]u8,
};
pub const DirectoryEntry = extern struct {
    inode: u64,
    offset: u64,
    reclen: u16,
    kind: u8,
    array: u8,
};
pub const TerminalAttributes = extern struct {
    input: Term.Input,
    output: Term.Output,
    control: Term.Control,
    local: Term.Local,
    line: u8,
    special: [32]u8,
    in_speed: u32,
    out_speed: u32,
    pub fn character(termios: *const TerminalAttributes, tag: Term.Special.Tag) u8 {
        return termios.special[@enumToInt(tag)];
    }
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
};
pub const ReadSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.read_errors },
    logging: builtin.Logging.SuccessErrorFault = .{},
};
pub const WriteSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.write_errors },
    logging: builtin.Logging.SuccessErrorFault = .{},
};
pub const OpenSpec = struct {
    options: Options,
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    logging: builtin.Logging.AcquireErrorFault = .{},
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
};
pub const SocketSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.socket_errors },
    logging: builtin.Logging.AcquireErrorFault = .{},
    return_type: type = u64,
    const Specification = @This();
    const Options = struct {
        non_block: bool = true,
        close_on_exec: bool = true,
    };
    fn flags(comptime spec: SocketSpec) Socket {
        var flags_bitfield: Socket = .{ .val = 0 };
        if (spec.options.non_block) {
            flags_bitfield.set(.non_block);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        return flags_bitfield;
    }
};
pub const MakeDirSpec = struct {
    options: Options = .{},
    mode: ModeSpec = ModeSpec.dir_mode,
    errors: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessErrorFault = .{},
    const Specification = @This();
    const Options = struct {
        exclusive: bool = true,
    };
};
pub const CreateSpec = struct {
    options: Options = .{},
    mode: ModeSpec = ModeSpec.file_mode,
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    return_type: type = u64,
    logging: builtin.Logging.AcquireErrorFault = .{},
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
};
pub const PathSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    return_type: type = u64,
    logging: builtin.Logging.AcquireErrorFault = .{},
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
};
pub const StatSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
    logging: builtin.Logging.SuccessErrorFault = .{},
    return_type: type = void,
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
};
pub const GetWorkingDirectorySpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: builtin.Logging.SuccessErrorFault = .{},
    const Specification = @This();
};
pub const ReadLinkSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: builtin.Logging.SuccessErrorFault = .{},
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
};
pub const MapSpec = struct {
    options: Options,
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    return_type: type = void,
    logging: builtin.Logging.AcquireErrorFault = .{},
    const Specification = @This();
    pub const Options = struct {
        anonymous: bool = false,
        visibility: Visibility = .shared,
        read: bool = true,
        write: bool = true,
        exec: bool = false,
        populate: bool = false,
        grows_down: bool = false,
        sync: bool = false,
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
};
pub const CloseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    return_type: type = void,
    logging: builtin.Logging.ReleaseErrorFault = .{},
    const Specification = @This();
};
pub const UnlinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.unlink_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessErrorFault = .{},
    const Specification = @This();
};
pub const RemoveDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.rmdir_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessErrorFault = .{},
    const Specification = @This();
    const special_fn = sys.special.rmdir;
};
pub const TruncateSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.truncate_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessErrorFault = .{},
    const Specification = @This();
};
pub fn read(comptime spec: ReadSpec, fd: u64, read_buf: []u8, read_count: u64) sys.Call(spec.errors.throw, u64) {
    const read_buf_addr: u64 = @ptrToInt(read_buf.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.read, spec.errors, u64, .{ fd, read_buf_addr, read_count }))) |ret| {
        if (logging.Success) {
            debug.readNotice(fd, ret);
        }
        return ret;
    } else |read_error| {
        if (logging.Error) {
            debug.readError(read_error, fd);
        }
        return read_error;
    }
}
pub fn write(comptime spec: WriteSpec, fd: u64, write_buf: []const u8) sys.Call(spec.errors.throw, void) {
    const write_buf_addr: u64 = @ptrToInt(write_buf.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.write, spec.errors, u64, .{ fd, write_buf_addr, write_buf.len }))) |ret| {
        if (logging.Success) {
            debug.writeNotice(fd, ret);
        }
    } else |write_error| {
        if (logging.Error) {
            debug.writeError(write_error, fd);
        }
        return write_error;
    }
}
pub fn open(comptime spec: OpenSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = spec.flags();
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, 0 }))) |fd| {
        if (logging.Acquire) {
            debug.openNotice(pathname, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.openError(open_error, pathname);
        }
        return open_error;
    }
}
pub fn openAt(comptime spec: OpenSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const flags: Open = spec.flags();
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags.val }))) |fd| {
        if (logging.Acquire) {
            debug.openAtNotice(dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.openAtError(open_error, dir_fd, name);
        }
        return open_error;
    }
}
pub fn socket(comptime spec: SocketSpec, domain: Domain, connection: Connection) sys.Call(spec.errors.throw, spec.return_type) {
    const flags: Socket = spec.flags();
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.socket, spec.errors, spec.return_type, .{ @enumToInt(domain), flags.val | @enumToInt(connection), 0 }))) |fd| {
        if (logging.Acquire) {
            debug.socketNotice(fd, domain, connection);
        }
        return fd;
    } else |socket_error| {
        if (logging.Error) {
            debug.socketError(socket_error, domain, connection);
        }
        return socket_error;
    }
}
fn pathnameLimit(pathname: []const u8) u64 {
    if (pathname.len == 0) {
        return 0;
    }
    var index: u64 = pathname.len -% 1;
    if (builtin.int2a(bool, pathname[index] == '/', index != 0)) {
        while (pathname[index] == '/') index -%= 1;
        while (pathname[index] != '/') index -%= 1;
    } else {
        while (builtin.int2a(bool, pathname[index] == '/', index != 0)) index -%= 1;
        while (builtin.int2a(bool, pathname[index] != '/', index != 0)) index -%= 1;
    }
    return index;
}
pub fn indexOfDirnameFinish(pathname: []const u8) u64 {
    return pathnameLimit(pathname);
}
pub fn indexOfBasenameStart(pathname: []const u8) u64 {
    const index: u64 = pathnameLimit(pathname);
    return index + builtin.int(u64, pathname[index] == '/');
}
pub fn dirname(pathname: []const u8) []const u8 {
    return pathname[0..indexOfDirnameFinish(pathname)];
}
pub fn basename(pathname: []const u8) []const u8 {
    return pathname[indexOfBasenameStart(pathname)..];
}
pub fn path(comptime spec: PathSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = spec.flags();
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, 0 }))) |fd| {
        if (logging.Acquire) {
            debug.openNotice(pathname, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Fault) {}
        if (logging.Error) {
            debug.openError(open_error, pathname);
        }
        return open_error;
    }
}
pub fn pathAt(comptime spec: PathSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, spec.pathFlags() }))) |fd| {
        if (logging.Acquire) {
            debug.openAtNotice(dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.openAtError(open_error, dir_fd, name);
        }
        return open_error;
    }
}
pub fn create(comptime spec: CreateSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = spec.flags();
    const mode: Mode = spec.mode.mode();
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, mode.val }))) |fd| {
        if (logging.Acquire) {
            debug.createNotice(pathname, fd, debug.describeMode(spec.mode));
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.createError(open_error, pathname, debug.describeMode(spec.mode));
        }
        return open_error;
    }
}
pub fn close(comptime spec: CloseSpec, fd: u64) sys.Call(spec.errors.throw, spec.return_type) {
    const logging: builtin.Logging.ReleaseErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.close, spec.errors, spec.return_type, .{fd}))) {
        if (logging.Release) {
            debug.closeNotice(fd);
        }
    } else |close_error| {
        if (logging.Error) {
            debug.closeError(close_error, fd);
        }
        return close_error;
    }
}
pub fn makeDir(comptime spec: MakeDirSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const mode: Mode = spec.mode.mode();
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.mkdir, spec.errors, spec.return_type, .{ pathname_buf_addr, mode.val }))) {
        if (logging.Success) {
            debug.makeDirNotice(pathname, debug.describeMode(spec.mode));
        }
    } else |mkdir_error| {
        if (logging.Error) {
            debug.makeDirError(mkdir_error, pathname);
        }
        return mkdir_error;
    }
}
pub fn makeDirAt(comptime spec: MakeDirSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const mode: Mode = spec.mode.mode();
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.mkdirat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, mode.val }))) {
        if (logging.Success) {
            debug.makeDirAtNotice(dir_fd, name, debug.describeMode(spec.mode));
        }
    } else |mkdir_error| {
        if (logging.Error) {
            debug.makeDirAtError(mkdir_error, dir_fd, name, debug.describeMode(spec.mode));
        }
        return mkdir_error;
    }
}
pub fn getCwd(comptime spec: GetWorkingDirectorySpec, buf: []u8) sys.Call(spec.errors.throw, [:0]const u8) {
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.getcwd, spec.errors, spec.return_type, .{ buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        const ret: [:0]const u8 = buf[0..len :0];
        if (logging.Success) {
            debug.getCwdNotice(ret);
        }
        return ret;
    } else |getcwd_error| {
        if (logging.Error) {
            debug.getCwdError(getcwd_error);
        }
        return getcwd_error;
    }
}
pub fn readLink(comptime spec: ReadLinkSpec, pathname: [:0]const u8, buf: []u8) sys.Call(spec.errors.throw, [:0]const u8) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.readlink, spec.errors, spec.return_type, .{ pathname_buf_addr, buf_addr, buf.len }))) |len| {
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            debug.readLinkError(readlink_error, pathname);
        }
        return readlink_error;
    }
}
pub fn readLinkAt(comptime spec: ReadLinkSpec, dir_fd: u64, name: [:0]const u8, buf: []u8) sys.Call(spec.errors.throw, [:0]const u8) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.readlinkat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, buf_addr, buf.len }))) |len| {
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            debug.readLinkAtError(readlink_error, dir_fd, name);
        }
        return readlink_error;
    }
}
pub fn unlink(comptime spec: UnlinkSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.unlink, spec.errors, spec.return_type, .{pathname_buf_addr}))) {
        if (logging.Success) {
            debug.unlinkNotice(pathname);
        }
    } else |unlink_error| {
        if (logging.Error) {
            debug.unlinkError(unlink_error, pathname);
        }
        return unlink_error;
    }
}
pub fn unlinkAt(comptime spec: UnlinkSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.unlinkat, spec.errors, spec.return_type, .{dir_fd, name_buf_addr, 0}))) {
        if (logging.Success) {
            debug.unlinkAtNotice(dir_fd, name);
        }
    } else |unlink_error| {
        if (logging.Error) {
            debug.unlinkAtError(unlink_error, dir_fd, name);
        }
        return unlink_error;
    }
}
pub fn removeDir(comptime spec: RemoveDirSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (sys.call(.rmdir, spec.errors, spec.return_type, .{pathname_buf_addr})) {
        if (logging.Success) {
            debug.removeDirNotice(pathname);
        }
    } else |rmdir_error| {
        if (logging.Error) {
            debug.removeDirError(rmdir_error, pathname);
        }
        return rmdir_error;
    }
}
pub fn stat(comptime spec: StatSpec, pathname: [:0]const u8) sys.Call(spec.errors.throw, Stat) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    var st: Stat = undefined;
    const st_buf_addr: u64 = @ptrToInt(&st);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    meta.wrap(sys.call(.stat, spec.errors, void, .{ pathname_buf_addr, st_buf_addr })) catch |stat_error| {
        if (logging.Error) {
            debug.statError(stat_error, pathname);
        }
        return stat_error;
    };
    return st;
}
pub fn fstat(comptime spec: StatSpec, fd: u64) sys.Call(spec.errors.throw, Stat) {
    var st: Stat = undefined;
    const st_buf_addr: u64 = @ptrToInt(&st);
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.fstat, spec.errors, void, .{ fd, st_buf_addr }))) {
        if (logging.Success) {
            debug.fstatNotice(fd, &st);
        }
    } else |stat_error| {
        if (logging.Error) {
            debug.fstatError(stat_error, fd);
        }
        return stat_error;
    }
    return st;
}
pub fn fstatAt(comptime spec: StatSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors.throw, Stat) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    var st: Stat = undefined;
    const st_buf_addr: u64 = @ptrToInt(&st);
    const flags: Open = spec.flags();
    meta.wrap(sys.call(.newfstatat, .{ dir_fd, name_buf_addr, st_buf_addr, flags.val })) catch |stat_error| {
        if (builtin.override().Error) {
            debug.fstatAtError(stat_error, dir_fd, name);
        }
        return stat_error;
    };
    return st;
}
/// Returns a pointer to the end of the file. In terms of library containers:
/// ```zig
/// struct {
///     lb_addr: u64 = addr,
///     ub_addr: u64 = addr + st.size,
///     up_addr: u64 = alignAbove(addr + st.size, page_size),
/// };
/// ```
pub fn map(comptime spec: MapSpec, addr: u64, fd: u64) sys.Call(spec.errors.throw, u64) {
    const flags: mem.Map = spec.flags();
    const prot: mem.Prot = spec.prot();
    const logging: builtin.Logging.AcquireErrorFault = spec.logging.override();
    const st: Stat = fstat(.{ .errors = .{ .abort = &.{sys.ErrorCode.OPAQUE} } }, fd);
    const len: u64 = mach.alignA64(st.size, 4096);
    if (meta.wrap(sys.call(.mmap, spec.errors, spec.return_type, .{ addr, len, prot.val, flags.val, fd, 0 }))) {
        if (logging.Acquire) {
            mem.debug.mapNotice(addr, len);
        }
        return addr + st.size;
    } else |map_error| {
        if (logging.Error) {
            mem.debug.mapError(map_error, addr, len);
        }
        return map_error;
    }
}
pub fn truncate(comptime spec: TruncateSpec, pathname: [:0]const u8, offset: u64) sys.Call(spec.errors.throw, spec.return_type) {
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.truncate, spec.errors, spec.return_type, .{ pathname, offset }))) |ret| {
        if (logging.Success) {
            debug.truncateNotice(pathname, offset);
        }
        return ret;
    } else |truncate_error| {
        if (logging.Error) {
            debug.ftruncateError(truncate_error, pathname, offset);
        }
        return truncate_error;
    }
}
pub fn ftruncate(comptime spec: TruncateSpec, fd: u64, offset: u64) sys.Call(spec.errors.throw, spec.return_type) {
    const logging: builtin.Logging.SuccessErrorFault = spec.logging.override();
    if (meta.wrap(sys.call(.ftruncate, spec.errors, spec.return_type, .{ fd, offset }))) |ret| {
        if (logging.Success) {
            debug.ftruncateNotice(fd, offset);
        }
        return ret;
    } else |truncate_error| {
        if (logging.Error) {
            debug.ftruncateError(truncate_error, fd, offset);
        }
        return truncate_error;
    }
}
// Getting terminal attributes is classed as a resource acquisition.
const TerminalAttributesSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.ioctl_errors },
    return_type: type = void,
    logging: builtin.Logging.Default = .{},
};
const IOControlSpec = struct {
    const TC = sys.TC;
    const TIOC = sys.TIOC;
};
// Soon.
fn ioctl(comptime _: IOControlSpec, _: u64) TerminalAttributes {}
fn getTerminalAttributes() void {}
fn setTerminalAttributes() void {}

pub fn readRandom(buf: []u8) void {
    sys.call(.getrandom, .{}, void, .{ @ptrToInt(buf.ptr), buf.len, if (builtin.is_fast)
        sys.GRND.INSECURE
    else
        sys.GRND.RANDOM });
}
pub fn DeviceRandomBytes(comptime bytes: u64) type {
    return struct {
        data: mem.StaticString(bytes) = .{},
        const Random = @This();
        const dev: u64 = if (builtin.is_fast)
            sys.GRND.INSECURE
        else
            sys.GRND.RANDOM;
        pub fn readOne(random: *Random, comptime T: type) T {
            const child: type = meta.AlignSizeAW(T);
            const high_alignment: u64 = @sizeOf(child);
            const low_alignment: u64 = @alignOf(child);
            if (random.data.len() == 0) {
                sys.call(.getrandom, .{}, void, .{ random.data.impl.aligned_byte_address(), bytes, dev });
            }
            if (high_alignment + low_alignment > bytes) {
                @compileError("requested type " ++ @typeName(T) ++ " is too large");
            }
            const s_lb_addr: u64 = random.data.impl.undefined_byte_address();
            const s_ab_addr: u64 = mach.alignA64(s_lb_addr, low_alignment);
            const s_up_addr: u64 = s_ab_addr + high_alignment;
            if (s_up_addr >= random.data.impl.unwritable_byte_address()) {
                random.data.undefineAll();
                const t_lb_addr: u64 = random.data.impl.undefined_byte_address();
                const t_ab_addr: u64 = mach.alignA64(t_lb_addr, low_alignment);
                const t_up_addr: u64 = t_ab_addr + high_alignment;
                sys.call(.getrandom, .{}, void, .{ random.data.impl.aligned_byte_address(), bytes, dev });
                random.data.define(t_up_addr - t_lb_addr);
                return @truncate(T, @intToPtr(*const child, t_ab_addr).*);
            }
            random.data.impl.define(s_up_addr - s_lb_addr);
            return @truncate(T, @intToPtr(*const child, s_ab_addr).*);
        }
        pub fn readOneConditionally(random: *Random, comptime T: type, comptime function: anytype) T {
            var ret: T = random.readOne(T);
            if (meta.Return(function) == bool) {
                if (meta.FnParam0(function) != *T) {
                    while (!function(ret)) {
                        ret = random.readOne(T);
                    }
                } else while (!function(&ret)) {}
            } else if (meta.Return(function) == T) {
                return function(ret);
            } else {
                @compileError("condition function must return " ++
                    @typeName(T) ++ " or " ++ @typeName(bool));
            }
            return ret;
        }
        pub fn readCount(random: *Random, comptime T: type, comptime count: u64) [count]T {
            var ret: [count]T = undefined;
            for (&ret) |*value| value.* = random.readOne(T);
            return ret;
        }
        pub fn readCountConditionally(random: *Random, comptime T: type, comptime count: u64) [count]T {
            var ret: [count]T = undefined;
            for (&ret) |*value| value.* = random.readOneConditionally(T);
            return ret;
        }
    };
}
pub fn determineFound(dir_pathname: [:0]const u8, file_name: [:0]const u8) ?u64 {
    const path_spec: PathSpec = .{ .options = .{ .directory = false } };
    const stat_spec: StatSpec = .{ .options = .{ .no_follow = false } };
    const dir_fd: u64 = path(path_spec, dir_pathname) catch return null;
    const st: Stat = fstatAt(stat_spec, dir_fd, file_name) catch return null;
    if (st.isExecutable(sys.geteuid(), sys.getegid())) {
        return dir_fd;
    }
    return null;
}
pub fn find(vars: []const [*:0]u8, name: [:0]const u8) !u64 {
    const path_key_s: []const u8 = "PATH=";
    for (vars) |entry_ptr| {
        const entry: [:0]u8 = meta.manyToSlice(entry_ptr);
        if (mem.testEqualManyFront(u8, path_key_s, entry)) {
            const path_s: [:0]u8 = entry[path_key_s.len..];
            var i: u64 = 0;
            var j: u64 = 0;
            while (i < path_s.len) : (i += 1) {
                i += builtin.int(u64, path_s[i] == '\\');
                if (path_s[i] == ':') {
                    path_s[i] = 0;
                    defer path_s[i] = ':';
                    defer j = i + 1;
                    if (determineFound(path_s[j..i :0], name)) |dir_fd| {
                        return dir_fd;
                    }
                }
            }
        }
    }
    return error.NoExecutableInEnvironmentPath;
}
pub fn home(vars: [][*:0]u8) ![:0]const u8 {
    const home_key_s: []const u8 = "HOME=";
    for (vars) |entry_ptr| {
        const entry: [:0]u8 = meta.manyToSlice(entry_ptr);
        if (mem.testEqualManyFront(u8, home_key_s, entry)) {
            return entry[home_key_s.len..];
        }
    }
    return error.NoHomeInEnvironment;
}
const debug = opaque {
    const about_open_0_s: []const u8 = "open:           ";
    const about_open_1_s: []const u8 = "open-error:     ";
    const about_read_0_s: []const u8 = "read:           ";
    const about_read_1_s: []const u8 = "read-error:     ";
    const about_stat_1_s: []const u8 = "stat-error:     ";
    const about_fstat_1_s: []const u8 = "fstat-error:    ";
    const about_close_0_s: []const u8 = "close:          ";
    const about_close_1_s: []const u8 = "close-error:    ";
    const about_mkdir_0_s: []const u8 = "mkdir:          ";
    const about_mkdir_1_s: []const u8 = "mkdir-error:    ";
    const about_rmdir_0_s: []const u8 = "rmdir:          ";
    const about_rmdir_1_s: []const u8 = "rmdir-error:    ";
    const about_write_0_s: []const u8 = "write:          ";
    const about_write_1_s: []const u8 = "write-error:    ";
    const about_create_0_s: []const u8 = "create:         ";
    const about_create_1_s: []const u8 = "create-error:   ";
    const about_getcwd_0_s: []const u8 = "getcwd:         ";
    const about_getcwd_1_s: []const u8 = "getcwd-error:   ";
    const about_openat_0_s: []const u8 = "openat:         ";
    const about_openat_1_s: []const u8 = "openat-error:   ";
    const about_unlink_0_s: []const u8 = "unlink:         ";
    const about_unlink_1_s: []const u8 = "unlink-error:   ";
    const about_socket_0: [:0]const u8 = "socket:         ";
    const about_socket_1: [:0]const u8 = "socket-error:   ";
    const about_fstatat_1_s: []const u8 = "fstatat-error:  ";
    const about_fexecve_1_s: []const u8 = "fexecve-error:  ";
    const about_unlinkat_0_s: []const u8 = "unlinkat:       ";
    const about_unlinkat_1_s: []const u8 = "unlinkat-error: ";
    const about_readlink_1_s: []const u8 = "readlink-error: ";
    const about_truncate_0_s: []const u8 = "truncate:       ";
    const about_truncate_1_s: []const u8 = "truncate-error: ";

    fn readNotice(fd: u64, len: u64) void {
        var buf: [16 + 32]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{
            about_write_1_s,                 "fd=",
            builtin.fmt.ud64(fd).readAll(),  " +",
            builtin.fmt.ud64(len).readAll(), " bytes\n",
        });
    }
    fn writeNotice(fd: u64, len: u64) void {
        var buf: [16 + 32]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{
            about_write_1_s,                 "fd=",
            builtin.fmt.ud64(fd).readAll(),  ", +",
            builtin.fmt.ud64(len).readAll(), " bytes\n",
        });
    }
    fn openNotice(pathname: [:0]const u8, fd: u64) void {
        var buf: [4096 + 32]u8 = undefined;
        builtin.debug.logAcquireAIO(&buf, &[_][]const u8{ about_open_0_s, "fd=", builtin.fmt.ud64(fd).readAll(), ", ", pathname, "\n" });
    }
    fn createNotice(pathname: [:0]const u8, fd: u64, comptime summary: []const u8) void {
        var buf: [4096 + 64 + summary.len]u8 = undefined;
        builtin.debug.logAcquireAIO(&buf, &[_][]const u8{ about_create_0_s, "fd=", builtin.fmt.ud64(fd).readAll(), ", ", pathname, ", ", summary, "\n" });
    }
    fn openAtNotice(dir_fd: u64, name: [:0]const u8, fd: u64) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096]u8 = undefined;
        builtin.debug.logAcquireAIO(&buf, &[_][]const u8{ about_openat_0_s, "fd=", builtin.fmt.ud64(fd).readAll(), ", dir_fd=", dir_fd_s, ", ", name, "\n" });
    }
    fn socketNotice(fd: u64, dom: Domain, conn: Connection) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAcquireAIO(&buf, &[_][]const u8{ about_socket_0, "fd=", builtin.fmt.ud64(fd).readAll(), ", ", @tagName(dom), ", ", @tagName(conn), "\n" });
    }
    fn makeDirNotice(pathname: [:0]const u8, comptime descr: []const u8) void {
        const max_len: u64 = 16 + 4096 + 2 + descr.len + 1;
        var buf: [max_len]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_mkdir_0_s, pathname, ", ", descr, "\n" });
    }
    fn makeDirAtNotice(dir_fd: u64, name: [:0]const u8, comptime descr: []const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096 + descr.len]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_mkdir_0_s, "dir_fd=", dir_fd_s, ", ", name, ", ", descr, "\n" });
    }
    fn getCwdNotice(pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 8]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_getcwd_0_s, pathname, "\n" });
    }
    fn truncateNotice(pathname: [:0]const u8, offset: u64) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_truncate_1_s, pathname, ", offset=", builtin.fmt.ud64(offset).readAll(), "\n" });
    }
    fn ftruncateNotice(fd: u64, offset: u64) void {
        var buf: [16 + 64 + 512]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{
            about_truncate_0_s,                 "fd=",
            builtin.fmt.ud64(fd).readAll(),     ", offset=",
            builtin.fmt.ud64(offset).readAll(), "\n",
        });
    }
    fn closeNotice(fd: u64) void {
        var buf: [16 + 32 + 4096]u8 = undefined;
        builtin.debug.logReleaseAIO(&buf, &[_][]const u8{ about_close_0_s, "fd=", builtin.fmt.ud64(fd).readAll(), "\n" });
    }
    fn unlinkNotice(pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 8]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_unlink_0_s, pathname, "\n" });
    }
    fn unlinkAtNotice(dir_fd: u64, name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_unlinkat_0_s, "dir_fd=", dir_fd_s, ", ", name, "\n" });
    }
    fn removeDirNotice(pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 1]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about_rmdir_0_s, pathname, "\n" });
    }
    fn fstatNotice(_: u64, _: *FileStatus) void {}
    fn statNotice(_: [:0]const u8, _: *FileStatus) void {}
    fn readError(read_error: anytype, fd: u64) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_read_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), " (", @errorName(read_error), ")\n" });
    }
    fn writeError(write_error: anytype, fd: u64) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_write_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), " (", @errorName(write_error), ")\n" });
    }
    fn openError(open_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_open_1_s, pathname, " (", @errorName(open_error), ")\n" });
    }
    fn openAtError(open_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_openat_1_s, "dir_fd=", dir_fd_s, ", ", name, " (", @errorName(open_error), ")\n" });
    }
    fn createError(open_error: anytype, pathname: [:0]const u8, comptime summary: []const u8) void {
        var buf: [4096 + 512 + summary.len]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_create_1_s, pathname, ", ", summary, " (", @errorName(open_error), ")\n" });
    }
    fn socketError(socket_error: anytype, dom: Domain, conn: Connection) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_socket_1, @tagName(dom), ", ", @tagName(conn), " (", @errorName(socket_error), ")\n" });
    }
    fn makeDirError(mkdir_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_mkdir_1_s, pathname, " (", @errorName(mkdir_error), ")\n" });
    }
    fn makeDirAtError(mkdir_error: anytype, dir_fd: u64, name: [:0]const u8, comptime descr: []const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096 + 512 + descr.len]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_mkdir_1_s, "dir_fd=", dir_fd_s, ", ", name, " (", @errorName(mkdir_error), ")\n" });
    }
    fn getCwdError(getcwd_error: anytype) void {
        var buf: [16 + 4096 + 8]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_getcwd_1_s, "(", @errorName(getcwd_error), ")\n" });
    }
    fn readLinkError(readlink_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 8]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_readlink_1_s, pathname, " (", @errorName(readlink_error), ")\n" });
    }
    fn readLinkAtError(readlink_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 64 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_readlink_1_s, "dir_fd=", dir_fd_s, ", ", name, " (", @errorName(readlink_error), ")\n" });
    }
    fn statError(stat_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_stat_1_s, pathname, " (", @errorName(stat_error), ")\n" });
    }
    fn fstatError(stat_error: anytype, fd: u64) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_fstat_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), ", (", @errorName(stat_error), ")\n" });
    }
    fn fstatAtError(stat_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_fstatat_1_s, "dir_fd=", dir_fd_s, ", ", name, " (", @errorName(stat_error), ")\n" });
    }
    fn truncateError(truncate_error: anytype, pathname: [:0]const u8, offset: u64) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_truncate_1_s, pathname, ", offset=", builtin.fmt.ud64(offset), " (", @errorName(truncate_error), ")\n" });
    }
    fn ftruncateError(truncate_error: anytype, fd: u64, offset: u64) void {
        var buf: [16 + 64 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_truncate_1_s, "fd=", builtin.fmt.ud64(fd).readAll(), ", offset=", builtin.fmt.ud64(offset).readAll(), ", (", @errorName(truncate_error), ")\n" });
    }
    fn closeError(close_error: anytype, fd: u64) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_close_1_s, builtin.fmt.ud64(fd).readAll(), " (", @errorName(close_error), ")\n" });
    }
    fn unlinkError(unlink_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_unlink_1_s, pathname, " (", @errorName(unlink_error), ")\n" });
    }
    fn unlinkAtError(unlinkat_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [16 + 32 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_unlinkat_1_s, "dir_fd=", dir_fd_s, ", ", name, " (", @errorName(unlinkat_error), ")\n" });
    }
    fn removeDirError(rmdir_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_rmdir_1_s, pathname, " (", @errorName(rmdir_error), ")\n" });
    }
    fn describePermsBriefly(comptime perms: Perms) []const u8 {
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
    fn describeMode(comptime mode_spec: ModeSpec) []const u8 {
        if (builtin.is_small) {
            return describePermsBriefly(mode_spec.owner) ++
                describePermsBriefly(mode_spec.group) ++
                describePermsBriefly(mode_spec.other);
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
