const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const builtin = @import("./builtin.zig");
const _dir = @import("./dir.zig");
const _chan = @import("./chan.zig");
pub usingnamespace _dir;
pub usingnamespace _chan;
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
pub const Kind = enum(u4) {
    unknown = 0,
    regular = MODE.IFREGR,
    directory = MODE.IFDIRR,
    character_special = MODE.IFCHRR,
    block_special = MODE.IFBLKR,
    named_pipe = MODE.IFIFOR,
    socket = MODE.IFSOCKR,
    symbolic_link = MODE.IFLNKR,
    const MODE = sys.S;
};
pub const At = meta.EnumBitField(enum(u64) {
    empty_path = AT.EMPTY_PATH,
    no_follow = AT.SYMLINK.NOFOLLOW,
    no_auto_mount = AT.NO_AUTOMOUNT,
    const AT = sys.AT;
});
pub const Device = extern struct {
    major: u32 = 0,
    minor: u8 = 0,
};
pub const Pipe = extern struct {
    read: u32,
    write: u32,
};
pub const Perms = packed struct(u3) {
    execute: bool = false,
    write: bool = false,
    read: bool = false,
};
pub const Mode = packed struct(u16) {
    other: Perms = .{ .read = false, .write = false, .execute = false },
    group: Perms = .{ .read = true, .write = false, .execute = false },
    owner: Perms = .{ .read = true, .write = true, .execute = false },
    sticky: bool = false,
    set_gid: bool = false,
    set_uid: bool = false,
    kind: Kind = .regular,
};
pub const Events = packed struct(u16) {
    input: bool = false,
    priority: bool = false,
    output: bool = false,
    @"error": bool = false,
    hangup: bool = false,
    invalid: bool = false,
    other: u10 = 0,
};
pub const PollFd = struct {
    fd: u32,
    expect: Events,
    actual: Events = .{},
};
pub const Term = opaque {
    pub const Input = meta.EnumBitField(enum(u32) {
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
    pub const Output = meta.EnumBitField(enum(u32) {
        post_processing = OUT.POST,
        translate_carriage_return = OUT.CRNL,
        no_carriage_return = OUT.NOCR,
        newline_return = OUT.NLRET,
        lower = OUT.UCLC,
        upper = OUT.LCUC,
        const OUT = sys.TC.O;
    });
    pub const Control = meta.EnumBitField(enum(u32) {
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
    pub const Local = meta.EnumBitField(enum(u32) {
        signal = LOC.ISIG,
        signal_disable_flush = LOC.NOFLSH,
        canonical_mode = LOC.ICANON,
        echo = LOC.ECHO,
        canonical_echo_erase = LOC.ECHOE,
        canonical_echo_kill = LOC.ECHOK,
        canonical_echo_newline = LOC.ECHONL,
        const LOC = sys.TC.L;
    });
    pub const Special = meta.EnumBitField(enum(u8) {
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
pub const Status = extern struct {
    dev: u64,
    ino: u64,
    nlink: u64,
    mode: Mode,
    @"0": u16,
    uid: u32,
    gid: u32,
    @"1": u32,
    rdev: u64,
    size: u64,
    blksize: u64,
    blocks: u64,
    atime: time.TimeSpec,
    mtime: time.TimeSpec,
    ctime: time.TimeSpec,
    pub fn isExecutable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.execute;
        }
        if (group_id == st.gid) {
            return st.mode.group.execute;
        }
        return st.mode.other.execute;
    }
    pub fn isReadable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
    pub fn isWritable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
};
pub const StatusExtended = extern struct {
    mask: u32,
    blksize: u32,
    attributes: u64,
    nlink: u32,
    uid: u32,
    gid: u32,
    mode: Mode,
    @"0": u16,
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
    pub const Attributes = meta.EnumBitField(enum(u64) {
        compressed = STATX.ATTR.COMPRESSED,
        immutable = STATX.ATTR.IMMUTABLE,
        append = STATX.ATTR.APPEND,
        nodump = STATX.ATTR.NODUMP,
        encrypted = STATX.ATTR.ENCRYPTED,
        verity = STATX.ATTR.VERITY,
        dax = STATX.ATTR.DAX,
        const STATX = sys.STATX;
    });
    pub const Fields = meta.EnumBitField(enum(u64) {
        type = STATX.TYPE,
        mode = STATX.MODE,
        nlink = STATX.NLINK,
        uid = STATX.UID,
        gid = STATX.GID,
        atime = STATX.ATIME,
        mtime = STATX.MTIME,
        ctime = STATX.CTIME,
        btime = STATX.BTIME,
        ino = STATX.INO,
        size = STATX.SIZE,
        blocks = STATX.BLOCKS,
        mnt_id = STATX.MNT_ID,
        const STATX = sys.STATX;
    });
    pub fn isExecutable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.execute;
        }
        if (group_id == st.gid) {
            return st.mode.group.execute;
        }
        return st.mode.other.execute;
    }
    pub fn isReadable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
    pub fn isWritable(st: Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
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
pub const dir_mode: Mode = .{
    .owner = .{ .read = true, .write = true, .execute = true },
    .group = .{ .read = true, .write = true, .execute = true },
    .other = .{ .read = false, .write = false, .execute = false },
    .sticky = false,
    .set_gid = false,
    .set_uid = false,
    .kind = .directory,
};
pub const file_mode: Mode = .{
    .owner = .{ .read = true, .write = true, .execute = false },
    .group = .{ .read = true, .write = false, .execute = false },
    .other = .{ .read = false, .write = false, .execute = false },
    .sticky = false,
    .set_gid = false,
    .set_uid = false,
    .kind = .regular,
};
pub const fifo_mode: Mode = .{
    .owner = .{ .read = true, .write = true, .execute = false },
    .group = .{ .read = true, .write = false, .execute = false },
    .other = .{ .read = false, .write = false, .execute = false },
    .sticky = false,
    .set_gid = false,
    .set_uid = false,
    .kind = .named_pipe,
};
pub const OpenSpec = struct {
    options: Options = .{},
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    logging: builtin.Logging.AcquireError = .{},
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
        comptime var flags_bitfield: Open = .{ .val = 0 };
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
pub const ReadSpec = struct {
    child: type = u8,
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.read_errors },
    logging: builtin.Logging.SuccessError = .{},
};
pub const WriteSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = sys.write_errors },
    logging: builtin.Logging.SuccessError = .{},
};
pub const PollSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.poll_errors },
    logging: builtin.Logging.SuccessError = .{},
};
pub const StatusSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
    logging: builtin.Logging.SuccessErrorFault = .{},
    return_type: ?type = null,
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
    };
    fn flags(comptime stat_spec: Specification) At {
        var flags_bitfield: At = .{ .val = 0 };
        if (stat_spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
};
pub const StatusExtendedSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.statx_errors },
    logging: builtin.Logging.SuccessErrorFault = .{},
    return_type: ?type = null,
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
        empty_path: bool = false,
        no_auto_mount: bool = true,
        fields: Fields = .{},
        const Fields = packed struct {
            type: bool = true,
            mode: bool = true,
            nlink: bool = true,
            uid: bool = true,
            gid: bool = true,
            atime: bool = true,
            mtime: bool = true,
            ctime: bool = true,
            btime: bool = false,
            ino: bool = true,
            size: bool = true,
            blocks: bool = true,
            mnt_id: bool = false,
        };
    };
    fn flags(comptime statx_spec: Specification) At {
        var flags_bitfield: At = .{ .val = 0 };
        if (statx_spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        if (statx_spec.options.no_auto_mount) {
            flags_bitfield.set(.no_auto_mount);
        }
        if (statx_spec.options.empty_path) {
            flags_bitfield.set(.empty_path);
        }
        return flags_bitfield;
    }
    fn fields(comptime statx_spec: Specification) StatusExtended.Fields {
        var fields_bitfield: StatusExtended.Fields = .{ .val = 0 };
        if (statx_spec.options.fields.type) {
            fields_bitfield.set(.type);
        }
        if (statx_spec.options.fields.mode) {
            fields_bitfield.set(.mode);
        }
        if (statx_spec.options.fields.nlink) {
            fields_bitfield.set(.nlink);
        }
        if (statx_spec.options.fields.uid) {
            fields_bitfield.set(.uid);
        }
        if (statx_spec.options.fields.gid) {
            fields_bitfield.set(.gid);
        }
        if (statx_spec.options.fields.atime) {
            fields_bitfield.set(.atime);
        }
        if (statx_spec.options.fields.mtime) {
            fields_bitfield.set(.mtime);
        }
        if (statx_spec.options.fields.ctime) {
            fields_bitfield.set(.ctime);
        }
        if (statx_spec.options.fields.btime) {
            fields_bitfield.set(.btime);
        }
        if (statx_spec.options.fields.ino) {
            fields_bitfield.set(.ino);
        }
        if (statx_spec.options.fields.size) {
            fields_bitfield.set(.size);
        }
        if (statx_spec.options.fields.blocks) {
            fields_bitfield.set(.blocks);
        }
        if (statx_spec.options.fields.mnt_id) {
            fields_bitfield.set(.mnt_id);
        }
        return fields_bitfield;
    }
};
pub const MakePipeSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.pipe_errors },
    return_type: type = void,
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();

    pub const Options = struct {
        close_on_exec: bool = false,
        direct: bool = false,
        non_block: bool = false,
    };
    fn flags(comptime pipe2_spec: Specification) Open {
        var flags_bitfield: Open = .{ .val = 0 };
        if (pipe2_spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (pipe2_spec.options.direct) {
            flags_bitfield.set(.direct);
        }
        if (pipe2_spec.options.non_block) {
            flags_bitfield.set(.non_block);
        }
        return flags_bitfield;
    }
};
pub const SocketSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.socket_errors },
    logging: builtin.Logging.AcquireError = .{},
    return_type: type = u64,
    const Specification = @This();
    pub const Options = struct {
        non_block: bool = true,
        close_on_exec: bool = true,
    };
    fn flags(comptime spec: SocketSpec) Socket {
        comptime var flags_bitfield: Socket = .{ .val = 0 };
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
    errors: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
};
pub const MakePathSpec = struct {
    errors: MakePathErrors = .{},
    logging: MakePathLogging = .{},
    const Specification = @This();
    const MakePathErrors = struct {
        stat: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
        mkdir: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
    };
    const MakePathLogging = struct {
        stat: builtin.Logging.SuccessErrorFault = .{},
        mkdir: builtin.Logging.SuccessError = .{},
    };
    fn stat(comptime mkpath_spec: Specification) StatusSpec {
        return .{
            .errors = mkpath_spec.errors.stat,
            .logging = mkpath_spec.logging.stat,
            .options = .{ .no_follow = true },
        };
    }
    fn mkdir(comptime mkpath_spec: Specification) MakeDirSpec {
        return .{
            .errors = mkpath_spec.errors.mkdir,
            .logging = mkpath_spec.logging.mkdir,
        };
    }
};
pub const CreateSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    return_type: type = u64,
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = struct {
        exclusive: bool = true,
        temporary: bool = false,
        close_on_exec: bool = true,
        write: ?OpenSpec.Write = .truncate,
        read: bool = false,
    };
    fn flags(comptime creat_spec: Specification) Open {
        var flags_bitfield: Open = .{ .val = 0 };
        flags_bitfield.set(.create);
        if (creat_spec.options.exclusive) {
            flags_bitfield.set(.exclusive);
        }
        if (creat_spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (creat_spec.options.temporary) {
            flags_bitfield.set(.temporary);
        }
        if (creat_spec.options.write) |w| {
            if (creat_spec.options.read) {
                flags_bitfield.set(.read_write);
            } else {
                flags_bitfield.set(.write_only);
            }
            if (w == .append) {
                flags_bitfield.set(.append);
            }
            if (w == .truncate) {
                flags_bitfield.set(.truncate);
            }
        } else if (creat_spec.options.read) {
            flags_bitfield.set(.read_only);
        }
        return flags_bitfield;
    }
};
pub const PathSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    return_type: type = u64,
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();
    const Options = struct {
        directory: bool = true,
        no_follow: bool = true,
        close_on_exec: bool = true,
    };
    pub fn flags(comptime spec: PathSpec) Open {
        comptime var flags_bitfield: Open = .{ .val = 0 };
        flags_bitfield.set(.path);
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
pub const MakeNodeSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const ExecuteSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.execve_errors },
    logging: builtin.Logging.AttemptError = .{},
    return_type: type = void,
    args_type: type = []const [*:0]u8,
    vars_type: type = []const [*:0]u8,
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
    };
    fn flags(comptime spec: Specification) At {
        var flags_bitfield: At = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
};
pub fn execPath(comptime spec: ExecuteSpec, pathname: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors, spec.return_type) {
    const filename_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const logging: builtin.Logging.AttemptError = comptime spec.logging.override();
    if (logging.Attempt) {
        debug.executeNotice(pathname, args);
    }
    if (meta.wrap(sys.call(.execve, spec.errors, spec.return_type, .{ filename_buf_addr, args_addr, vars_addr }))) {
        unreachable;
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            debug.executeErrorBrief(execve_error, pathname);
        } else if (logging.Error) {
            debug.executeError(execve_error, pathname, args);
        }
        return execve_error;
    }
}
pub fn exec(comptime spec: ExecuteSpec, fd: u64, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors, spec.return_type) {
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: At = comptime spec.flags();
    const logging: builtin.Logging.AttemptError = comptime spec.logging.override();
    if (logging.Attempt) {
        debug.executeNotice(args[0], args);
    }
    if (meta.wrap(sys.call(.execveat, spec.errors, spec.return_type, .{ fd, @ptrToInt(""), args_addr, vars_addr, flags.val }))) {
        unreachable;
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            debug.executeErrorBrief(execve_error, args[0]);
        } else if (logging.Error) {
            debug.executeError(execve_error, args[0], args);
        }
        return execve_error;
    }
}
pub fn execAt(comptime spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: At = comptime spec.flags();
    const logging: builtin.Logging.AttemptError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.execveat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val }))) {
        unreachable;
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            debug.executeErrorBrief(execve_error, name);
        } else if (logging.Error) {
            debug.executeError(execve_error, name, args);
        }
        return execve_error;
    }
}
pub const GetWorkingDirectorySpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const ReadLinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const MapSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    return_type: type = void,
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = struct {
        visibility: Visibility = .shared,
        read: bool = true,
        write: bool = true,
        exec: bool = false,
        populate: bool = false,
        sync: bool = false,
        const Visibility = enum { shared, shared_validate, private };
    };
    pub fn flags(comptime map_spec: Specification) mem.Map {
        var flags_bitfield: mem.Map = .{ .val = 0 };
        switch (map_spec.options.visibility) {
            .private => flags_bitfield.set(.private),
            .shared => flags_bitfield.set(.shared),
            .shared_validate => flags_bitfield.set(.shared_validate),
        }
        if (map_spec.options.populate) {
            builtin.static.assert(map_spec.options.visibility == .private);
            flags_bitfield.set(.populate);
        }
        if (map_spec.options.sync) {
            builtin.static.assert(map_spec.options.visibility == .shared_validate);
            flags_bitfield.set(.sync);
        }
        flags_bitfield.set(.fixed);
        return flags_bitfield;
    }
    pub fn prot(comptime map_spec: Specification) mem.Prot {
        var prot_bitfield: mem.Prot = .{ .val = 0 };
        if (map_spec.options.read) {
            prot_bitfield.set(.read);
        }
        if (map_spec.options.write) {
            prot_bitfield.set(.write);
        }
        if (map_spec.options.exec) {
            prot_bitfield.set(.exec);
        }
        return prot_bitfield;
    }
};
pub const CloseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    return_type: type = void,
    logging: builtin.Logging.ReleaseError = .{},
};
pub const UnlinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.unlink_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
};
pub const RemoveDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.rmdir_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
};
pub const TruncateSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.truncate_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
};
pub const DuplicateSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.dup_errors },
    return_type: type = u64,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
    const Options = struct {
        close_on_exec: bool = false,
    };
    fn flags(comptime dup3_spec: Specification) Open {
        var ret: Open = .{ .val = 0 };
        if (dup3_spec.options.close_on_exec) {
            ret.set(.close_on_exec);
        }
        return ret;
    }
};
pub fn poll(comptime poll_spec: PollSpec, fds: []PollFd, timeout: u32) sys.Call(poll_spec.errors, void) {
    if (meta.wrap(sys.call(.poll, poll_spec.errors, void, .{ @ptrToInt(fds.ptr), fds.len, timeout }))) {
        if (poll_spec.logging.Success) {
            debug.pollNotice(fds);
        }
    } else |poll_error| {
        return poll_error;
    }
}

pub fn read(comptime spec: ReadSpec, fd: u64, read_buf: []spec.child, read_count: u64) sys.Call(spec.errors, spec.return_type) {
    const read_buf_addr: u64 = @ptrToInt(read_buf.ptr);
    const read_count_mul: u64 = @sizeOf(spec.child);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.read, spec.errors, u64, .{ fd, read_buf_addr, read_count *% read_count_mul }))) |ret| {
        if (logging.Success) {
            debug.readNotice(fd, read_count, ret);
        }
        if (spec.return_type != void) {
            return @intCast(spec.return_type, @divExact(ret, read_count_mul));
        }
    } else |read_error| {
        if (logging.Error) {
            debug.readError(read_error, fd);
        }
        return read_error;
    }
}
pub fn write(comptime spec: WriteSpec, fd: u64, write_buf: []const spec.child) sys.Call(spec.errors, spec.return_type) {
    const write_buf_addr: u64 = @ptrToInt(write_buf.ptr);
    const write_count_mul: u64 = @sizeOf(spec.child);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.write, spec.errors, u64, .{ fd, write_buf_addr, write_buf.len *% write_count_mul }))) |ret| {
        if (logging.Success) {
            debug.writeNotice(fd, ret);
        }
        if (spec.return_type != void) {
            return @intCast(spec.return_type, @divExact(ret, write_count_mul));
        }
    } else |write_error| {
        if (logging.Error) {
            debug.writeError(write_error, fd);
        }
        return write_error;
    }
}
pub fn open(comptime spec: OpenSpec, pathname: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
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
pub fn openAt(comptime spec: OpenSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const flags: Open = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags.val, 0 }))) |fd| {
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
pub fn socket(comptime spec: SocketSpec, domain: Domain, connection: Connection) sys.Call(spec.errors, spec.return_type) {
    const flags: Socket = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
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
    return index +% builtin.int(u64, pathname[index] == '/');
}
pub fn dirname(pathname: []const u8) []const u8 {
    return pathname[0..indexOfDirnameFinish(pathname)];
}
pub fn basename(pathname: []const u8) []const u8 {
    return pathname[indexOfBasenameStart(pathname)..];
}
pub fn path(comptime spec: PathSpec, pathname: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
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
pub fn pathAt(comptime spec: PathSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
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
fn writePath(buf: *[4096]u8, pathname: []const u8) [:0]u8 {
    mach.memcpy(buf, pathname.ptr, pathname.len);
    buf[pathname.len] = 0;
    return buf[0..pathname.len :0];
}
fn makePathInternal(comptime spec: MakePathSpec, pathname: [:0]u8, comptime mode: Mode) sys.Call(spec.errors.mkdir, sys.Call(spec.errors.stat, void)) {
    const stat_spec: StatusSpec = spec.stat();
    const make_dir_spec: MakeDirSpec = spec.mkdir();
    const st: Status = pathStatus(stat_spec, pathname) catch |err| blk: {
        if (err == error.NoSuchFileOrDirectory) {
            const idx: u64 = indexOfDirnameFinish(pathname);
            builtin.assertEqual(u8, pathname[idx], '/');
            if (idx != 0) {
                pathname[idx] = 0;
                try makePathInternal(spec, pathname[0..idx :0], mode);
                pathname[idx] = '/';
            }
        }
        try makeDir(make_dir_spec, pathname, mode);
        break :blk try pathStatus(stat_spec, pathname);
    };
    if (st.mode.kind != .directory) {
        return error.NotADirectory;
    }
}
pub fn makePath(comptime spec: MakePathSpec, pathname: []const u8, comptime mode: Mode) sys.Call(spec.errors.mkdir, sys.Call(spec.errors.stat, void)) {
    var buf: [4096:0]u8 = undefined;
    const name: [:0]u8 = writePath(&buf, pathname);
    return makePathInternal(spec, name, mode);
}
pub fn create(comptime spec: CreateSpec, pathname: [:0]const u8, comptime mode: Mode) sys.Call(spec.errors, spec.return_type) {
    builtin.static.assertEqual(Kind, .regular, mode.kind);
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const flags: Open = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, @bitCast(u16, mode) & 0xfff }))) |fd| {
        if (logging.Acquire) {
            debug.createNotice(pathname, fd, mode);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.createError(open_error, pathname);
        }
        return open_error;
    }
}
pub fn createAt(comptime spec: CreateSpec, dir_fd: u64, name: [:0]const u8, comptime mode: Mode) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const flags: Open = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags.val, @bitCast(u16, mode) & 0xfff }))) |fd| {
        if (logging.Acquire) {
            debug.createAtNotice(dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            debug.createAtError(open_error, dir_fd, name);
        }
        return open_error;
    }
}
pub fn close(comptime spec: CloseSpec, fd: u64) sys.Call(spec.errors, spec.return_type) {
    const logging: builtin.Logging.ReleaseError = comptime spec.logging.override();
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
pub fn makeDir(comptime spec: MakeDirSpec, pathname: [:0]const u8, comptime mode: Mode) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mkdir, spec.errors, spec.return_type, .{ pathname_buf_addr, @bitCast(u16, mode) }))) {
        if (logging.Success) {
            debug.makeDirNotice(pathname, mode);
        }
    } else |mkdir_error| {
        if (logging.Error) {
            debug.makeDirError(mkdir_error, pathname);
        }
        return mkdir_error;
    }
}
pub fn makeDirAt(comptime spec: MakeDirSpec, dir_fd: u64, name: [:0]const u8, comptime mode: Mode) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mkdirat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, @bitCast(u16, mode) }))) {
        if (logging.Success) {
            debug.makeDirAtNotice(dir_fd, name, mode);
        }
    } else |mkdir_error| {
        if (logging.Error) {
            debug.makeDirAtError(mkdir_error, dir_fd, name);
        }
        return mkdir_error;
    }
}
pub fn makeNode(comptime spec: MakeNodeSpec, pathname: [:0]const u8, comptime mode: Mode, comptime dev: Device) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mknod, spec.errors, spec.return_type, .{ pathname_buf_addr, @bitCast(u16, mode), @bitCast(u64, dev) }))) {
        if (logging.Success) {
            debug.makeNodeNotice(pathname, mode, dev);
        }
    } else |mknod_error| {
        if (logging.Error) {
            debug.makeNodeError(mknod_error, pathname);
        }
        return mknod_error;
    }
}
pub fn makeNodeAt(comptime spec: MakeNodeSpec, dir_fd: u64, name: [:0]const u8, comptime mode: Mode, comptime dev: Device) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mknodat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, @bitCast(u16, mode), @bitCast(u64, dev) }))) {
        if (logging.Success) {
            debug.makeNodeAtNotice(dir_fd, name, mode);
        }
    } else |mknod_error| {
        if (logging.Error) {
            debug.makeNodeAtError(mknod_error, dir_fd, name);
        }
        return mknod_error;
    }
}
pub fn getCwd(comptime spec: GetWorkingDirectorySpec, buf: []u8) sys.Call(spec.errors, [:0]const u8) {
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
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
pub fn readLink(comptime spec: ReadLinkSpec, pathname: [:0]const u8, buf: []u8) sys.Call(spec.errors, [:0]const u8) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.readlink, spec.errors, spec.return_type, .{ pathname_buf_addr, buf_addr, buf.len }))) |len| {
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            debug.readLinkError(readlink_error, pathname);
        }
        return readlink_error;
    }
}
pub fn readLinkAt(comptime spec: ReadLinkSpec, dir_fd: u64, name: [:0]const u8, buf: []u8) sys.Call(spec.errors, [:0]const u8) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const buf_addr: u64 = @ptrToInt(buf.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.readlinkat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            debug.readLinkAtError(readlink_error, dir_fd, name);
        }
        return readlink_error;
    }
}
pub fn unlink(comptime spec: UnlinkSpec, pathname: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
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
pub fn unlinkAt(comptime spec: UnlinkSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.unlinkat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, 0 }))) {
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
pub fn removeDir(comptime spec: RemoveDirSpec, pathname: [:0]const u8) sys.Call(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
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
pub inline fn pathStatus(comptime spec: StatusSpec, pathname: [:0]const u8) sys.Call(spec.errors, Status) {
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    var st: Status = undefined;
    const st_buf_addr: u64 = @ptrToInt(&st);
    const logging: builtin.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (sys.call(.stat, spec.errors, void, .{ pathname_buf_addr, st_buf_addr })) {
        if (logging.Success) {
            debug.pathStatusNotice(pathname, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            debug.pathStatusError(stat_error, pathname);
        }
        return stat_error;
    }
    return st;
}
pub inline fn status(comptime spec: StatusSpec, fd: u64) sys.Call(spec.errors, Status) {
    var st: Status = undefined;
    const st_buf_addr: u64 = @ptrToInt(&st);
    const logging: builtin.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.fstat, spec.errors, void, .{ fd, st_buf_addr }))) {
        if (logging.Success) {
            debug.statusNotice(fd, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            debug.statusError(stat_error, fd);
        }
        return stat_error;
    }
    return st;
}
pub inline fn statusAt(comptime spec: StatusSpec, dir_fd: u64, name: [:0]const u8) sys.Call(spec.errors, Status) {
    var st: Status = undefined;
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const st_buf_addr: u64 = @ptrToInt(&st);
    const flags: At = comptime spec.flags();
    const logging: builtin.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.newfstatat, spec.errors, void, .{ dir_fd, name_buf_addr, st_buf_addr, flags.val }))) {
        if (logging.Success) {
            debug.statusAtNotice(dir_fd, name, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            debug.statusAtError(stat_error, dir_fd, name);
        }
        return stat_error;
    }
    return st;
}
pub inline fn statusExtended(comptime spec: StatusExtendedSpec, fd: u64, pathname: [:0]const u8) sys.Call(spec.errors, StatusExtended) {
    var st: StatusExtended = undefined;
    const pathname_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const st_buf_addr: u64 = @ptrToInt(&st);
    const flags: At = comptime spec.flags();
    const mask: StatusExtended.Fields = comptime spec.fields();
    const logging: builtin.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.statx, spec.errors, void, .{ fd, pathname_buf_addr, flags.val, mask.val, st_buf_addr }))) {
        if (logging.Success) {
            debug.statusNotice(fd, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            debug.statusError(stat_error, fd);
        }
        return stat_error;
    }
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
pub fn map(comptime spec: MapSpec, addr: u64, fd: u64) sys.Call(spec.errors, u64) {
    const flags: mem.Map = comptime spec.flags();
    const prot: mem.Prot = comptime spec.prot();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    const st: Status = status(.{ .errors = .{ .abort = &.{sys.ErrorCode.OPAQUE} } }, fd);
    const len: u64 = mach.alignA64(st.size, 4096);
    if (meta.wrap(sys.call(.mmap, spec.errors, spec.return_type, .{ addr, len, prot.val, flags.val, fd, 0 }))) {
        if (logging.Acquire) {
            mem.debug.mapNotice(addr, len);
        }
        return addr +% st.size;
    } else |map_error| {
        if (logging.Error) {
            mem.debug.mapError(map_error, addr, len);
        }
        return map_error;
    }
}
pub fn truncate(comptime spec: TruncateSpec, pathname: [:0]const u8, offset: u64) sys.Call(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
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
pub fn ftruncate(comptime spec: TruncateSpec, fd: u64, offset: u64) sys.Call(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
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
pub fn duplicate(comptime dup_spec: DuplicateSpec, fd: u64) sys.Call(dup_spec.errors, dup_spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime dup_spec.logging.override();
    if (meta.wrap(sys.call(.dup, dup_spec.errors, dup_spec.return_type, .{fd}))) |ret| {
        if (logging.Success) {
            debug.duplicateNotice(fd, ret);
        }
        if (dup_spec.return_type == u64) {
            return ret;
        }
    } else |dup_error| {
        if (logging.Error) {
            debug.duplicateError(dup_error, fd);
        }
        return dup_error;
    }
}
pub fn duplicateTo(comptime dup3_spec: DuplicateSpec, old_fd: u64, new_fd: u64) sys.Call(dup3_spec.errors, void) {
    const flags: Open = comptime dup3_spec.flags();
    const logging: builtin.Logging.SuccessError = comptime dup3_spec.logging.override();
    if (meta.wrap(sys.call(.dup3, dup3_spec.errors, void, .{ old_fd, new_fd, flags.val }))) {
        if (logging.Success) {
            debug.duplicateToNotice(old_fd, new_fd);
        }
    } else |dup3_error| {
        if (logging.Error) {
            debug.duplicateToError(dup3_error, old_fd, new_fd);
        }
        return dup3_error;
    }
}
pub fn makePipe(comptime pipe2_spec: MakePipeSpec, pipefd: *Pipe) sys.Call(pipe2_spec.errors, pipe2_spec.return_type) {
    const flags: Open = comptime pipe2_spec.flags();
    const pipefd_addr: u64 = @ptrToInt(pipefd);
    const logging: builtin.Logging.AcquireError = comptime pipe2_spec.logging.override();
    if (meta.wrap(sys.call(.pipe2, pipe2_spec.errors, void, .{ pipefd_addr, flags.val }))) {
        if (logging.Acquire) {
            debug.pipeNotice(pipefd.read, pipefd.write);
        }
    } else |pipe2_error| {
        if (logging.Error) {
            debug.pipeError(pipe2_error);
        }
    }
}
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
            if (high_alignment +% low_alignment > bytes) {
                @compileError("requested type " ++ @typeName(T) ++ " is too large");
            }
            const s_lb_addr: u64 = random.data.impl.undefined_byte_address();
            const s_ab_addr: u64 = mach.alignA64(s_lb_addr, low_alignment);
            const s_up_addr: u64 = s_ab_addr +% high_alignment;
            if (s_up_addr >= random.data.impl.unwritable_byte_address()) {
                random.data.undefineAll();
                const t_lb_addr: u64 = random.data.impl.undefined_byte_address();
                const t_ab_addr: u64 = mach.alignA64(t_lb_addr, low_alignment);
                const t_up_addr: u64 = t_ab_addr +% high_alignment;
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
pub fn pathIs(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(pathStatus(stat_spec, pathname));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind == kind, st);
        }
    }
    return st.mode.kind == kind;
}
pub inline fn pathIsNot(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(pathStatus(stat_spec, pathname));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind != kind, st);
        }
    }
    return st.mode.kind != kind;
}
pub fn pathAssert(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(pathStatus(stat_spec, pathname));
    const res: bool = st.mode.kind == kind;
    const logging: builtin.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            debug.pathMustBeFault(pathname, kind, st.mode);
        }
        builtin.proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn isAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(statusAt(stat_spec, dir_fd, name));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind == kind, st);
        }
    }
    return st.mode.kind == kind;
}
pub fn isNotAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(statusAt(stat_spec, dir_fd, name));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind != kind, st);
        }
    }
    return st.mode.kind != kind;
}
pub fn assertAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(statusAt(stat_spec, dir_fd, name));
    const logging: builtin.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (st.mode.kind != kind) {
        if (logging.Fault) {
            debug.atDirFdMustBeFault(dir_fd, name, kind, st.mode);
        }
        builtin.proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn is(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind == kind, st);
        }
    }
    return st.mode.kind == kind;
}
pub inline fn isNot(comptime stat_spec: StatusSpec, kind: Kind, fd: u64) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse bool,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    if (stat_spec.return_type) |return_type| {
        if (return_type == ?Status) {
            return mach.cmovZ(st.mode.kind != kind, st);
        }
    }
    return st.mode.kind != kind;
}
pub fn assert(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    const res: bool = st.mode.kind == kind;
    const logging: builtin.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            debug.fdKindModeFault(fd, kind, st.mode);
        }
        builtin.proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn assertNot(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.Call(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    const res: bool = st.mode.kind == kind;
    const logging: builtin.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (res) {
        if (logging.Fault) {
            debug.fdNotKindFault(fd, kind);
        }
        builtin.proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
const debug = opaque {
    const about_dup_0_s: [:0]const u8 = builtin.debug.about("dup");
    const about_dup_1_s: [:0]const u8 = builtin.debug.about("dup-error");
    const about_dup3_0_s: [:0]const u8 = builtin.debug.about("dup3");
    const about_dup3_1_s: [:0]const u8 = builtin.debug.about("dup3-error");
    const about_stat_0_s: [:0]const u8 = builtin.debug.about("stat");
    const about_open_0_s: [:0]const u8 = builtin.debug.about("open");
    const about_open_1_s: [:0]const u8 = builtin.debug.about("open-error");
    const about_file_0_s: [:0]const u8 = builtin.debug.about("file");
    const about_file_1_s: [:0]const u8 = builtin.debug.about("file-error");
    const about_file_2_s: [:0]const u8 = builtin.debug.about("file-fault");
    const about_read_0_s: [:0]const u8 = builtin.debug.about("read");
    const about_read_1_s: [:0]const u8 = builtin.debug.about("read-error");
    const about_stat_1_s: [:0]const u8 = builtin.debug.about("stat-error");
    const about_pipe_0_s: [:0]const u8 = builtin.debug.about("pipe");
    const about_pipe_1_s: [:0]const u8 = builtin.debug.about("pipe-error");
    const about_close_0_s: [:0]const u8 = builtin.debug.about("close");
    const about_close_1_s: [:0]const u8 = builtin.debug.about("close-error");
    const about_mkdir_0_s: [:0]const u8 = builtin.debug.about("mkdir");
    const about_mkdir_1_s: [:0]const u8 = builtin.debug.about("mkdir-error");
    const about_mknod_0_s: [:0]const u8 = builtin.debug.about("mknod");
    const about_mknod_1_s: [:0]const u8 = builtin.debug.about("mknod-error");
    const about_rmdir_0_s: [:0]const u8 = builtin.debug.about("rmdir");
    const about_rmdir_1_s: [:0]const u8 = builtin.debug.about("rmdir-error");
    const about_write_0_s: [:0]const u8 = builtin.debug.about("write");
    const about_write_1_s: [:0]const u8 = builtin.debug.about("write-error");
    const about_socket_0_s: [:0]const u8 = builtin.debug.about("socket");
    const about_socket_1_s: [:0]const u8 = builtin.debug.about("socket-error");
    const about_create_0_s: [:0]const u8 = builtin.debug.about("create");
    const about_create_1_s: [:0]const u8 = builtin.debug.about("create-error");
    const about_execve_0_s: [:0]const u8 = builtin.debug.about("execve");
    const about_execve_1_s: [:0]const u8 = builtin.debug.about("execve-error");
    const about_getcwd_0_s: [:0]const u8 = builtin.debug.about("getcwd");
    const about_getcwd_1_s: [:0]const u8 = builtin.debug.about("getcwd-error");
    const about_unlink_0_s: [:0]const u8 = builtin.debug.about("unlink");
    const about_unlink_1_s: [:0]const u8 = builtin.debug.about("unlink-error");
    const about_unlinkat_0_s: [:0]const u8 = builtin.debug.about("unlink");
    const about_unlinkat_1_s: [:0]const u8 = builtin.debug.about("unlink-error");
    const about_readlink_1_s: [:0]const u8 = builtin.debug.about("readlink-error");
    const about_truncate_0_s: [:0]const u8 = builtin.debug.about("truncate");
    const about_truncate_1_s: [:0]const u8 = builtin.debug.about("truncate-error");
    const unknown_s: [:0]const u8 = "an unknown file";
    const regular_s: [:0]const u8 = "a regular file";
    const directory_s: [:0]const u8 = "a directory";
    const character_special_s: [:0]const u8 = "a character special file";
    const block_special_s: [:0]const u8 = "a block special file";
    const named_pipe_s: [:0]const u8 = "a named pipe";
    const socket_s: [:0]const u8 = "a socket";
    const symbolic_link_s: [:0]const u8 = "a symbolic link";
    const new_fd_s: [:0]const u8 = "new_fd=";
    const old_fd_s: [:0]const u8 = "old_fd=";
    const read_fd_s: [:0]const u8 = "read_fd=";
    const write_fd_s: [:0]const u8 = "write_fd=";
    fn fdAboutNotice(fd: u64, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, "\n" });
    }
    fn fdModeAboutNotice(fd: u64, mode: Mode, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", mode=", &describeMode(mode), "\n" });
    }
    fn fdLenAboutNotice(fd: u64, len: u64, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", ", len_s, " bytes\n" });
    }
    fn fdMaxLenLenAboutNotice(fd: u64, max_len: u64, len: u64, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        const max_len_s: []const u8 = builtin.fmt.ud64(max_len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logSuccessAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", ", len_s, "/", max_len_s, " bytes\n" });
    }
    fn pathnameAboutNotice(pathname: [:0]const u8, about: [:0]const u8) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, pathname, "\n" });
    }
    fn pathnameModeAboutNotice(pathname: [:0]const u8, mode: Mode, about: [:0]const u8) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, pathname, ", mode=", &describeMode(mode), "\n" });
    }
    fn pathnameFdAboutNotice(pathname: [:0]const u8, fd: u64, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", ", pathname, "\n" });
    }
    fn pathnameFdModeAboutNotice(pathname: [:0]const u8, fd: u64, mode: Mode, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", ", pathname, ", mode=", &describeMode(mode), "\n" });
    }
    fn pathnameModeDeviceAboutNotice(pathname: [:0]const u8, mode: Mode, dev: Device, about: [:0]const u8) void {
        const maj_s: []const u8 = builtin.fmt.ud64(dev.major).readAll();
        const min_s: []const u8 = builtin.fmt.ud64(dev.minor).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, pathname, ", mode=", &describeMode(mode), ", dev=", maj_s, ":", min_s, "\n" });
    }
    fn dirFdNameModeAboutNotice(dir_fd: u64, name: [:0]const u8, mode: Mode, about: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "dir_fd=", dir_fd_s, ", ", name, ", mode=", &describeMode(mode), "\n" });
    }
    fn dirFdNameFdAboutNotice(dir_fd: u64, name: [:0]const u8, fd: u64, about: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", dir_fd=", dir_fd_s, ", ", name, "\n" });
    }
    fn dirFdNameAboutNotice(dir_fd: u64, name: [:0]const u8, about: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "dir_fd=", dir_fd_s, ", ", name, "\n" });
    }
    fn fdFdAboutNotice(fd1: u64, fd2: u64, about: [:0]const u8, about_fd1: [:0]const u8, about_fd2: [:0]const u8) void {
        const fd1_s: []const u8 = builtin.fmt.ud64(fd1).readAll();
        const fd2_s: []const u8 = builtin.fmt.ud64(fd2).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, about_fd1, fd1_s, " => ", about_fd2, fd2_s, "\n" });
    }
    fn dirFdNameModeDeviceAboutNotice(dir_fd: u64, name: [:0]const u8, mode: Mode, dev: Device, about: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        const maj_s: []const u8 = builtin.fmt.ud64(dev.major).readAll();
        const min_s: []const u8 = builtin.fmt.ud64(dev.minor).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "dir_fd=", dir_fd_s, ", ", name, ", mode=", &describeMode(mode), ", dev=", maj_s, ":", min_s, "\n" });
    }
    fn socketNotice(fd: u64, dom: Domain, conn: Connection) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_socket_0_s, "fd=", fd_s, ", ", @tagName(dom), ", ", @tagName(conn), "\n" });
    }
    fn getCwdNotice(pathname: [:0]const u8) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_getcwd_0_s, pathname, "\n" });
    }
    fn truncateNotice(pathname: [:0]const u8, offset: u64) void {
        const offset_s: []const u8 = builtin.fmt.ud64(offset).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_truncate_1_s, pathname, ", offset=", offset_s, "\n" });
    }
    fn ftruncateNotice(fd: u64, offset: u64) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        const offset_s: []const u8 = builtin.fmt.ud64(offset).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_truncate_0_s, "fd=", fd_s, ", offset=", offset_s, "\n" });
    }
    inline fn openNotice(pathname: [:0]const u8, fd: u64) void {
        pathnameFdAboutNotice(pathname, fd, about_open_0_s);
    }
    inline fn closeNotice(fd: u64) void {
        fdAboutNotice(fd, about_close_0_s);
    }
    inline fn duplicateNotice(old_fd: u64, new_fd: u64) void {
        fdFdAboutNotice(old_fd, new_fd, about_dup_0_s, old_fd_s, new_fd_s);
    }
    inline fn duplicateToNotice(old_fd: u64, new_fd: u64) void {
        fdFdAboutNotice(old_fd, new_fd, about_dup3_0_s, old_fd_s, new_fd_s);
    }
    inline fn pipeNotice(read_fd: u64, write_fd: u64) void {
        fdFdAboutNotice(read_fd, write_fd, about_pipe_0_s, read_fd_s, write_fd_s);
    }
    inline fn readNotice(fd: u64, max_len: u64, len: u64) void {
        fdMaxLenLenAboutNotice(fd, max_len, len, about_read_0_s);
    }
    inline fn writeNotice(fd: u64, len: u64) void {
        fdLenAboutNotice(fd, len, about_write_0_s);
    }
    inline fn createNotice(pathname: [:0]const u8, fd: u64, mode: Mode) void {
        pathnameFdModeAboutNotice(pathname, fd, mode, about_create_0_s);
    }
    inline fn makeDirNotice(pathname: [:0]const u8, mode: Mode) void {
        pathnameModeAboutNotice(pathname, mode, about_mkdir_0_s);
    }
    inline fn makeNodeNotice(pathname: [:0]const u8, mode: Mode, dev: Device) void {
        pathnameModeDeviceAboutNotice(pathname, mode, dev, about_mknod_0_s);
    }
    inline fn unlinkNotice(pathname: [:0]const u8) void {
        pathnameAboutNotice(pathname, about_unlink_0_s);
    }
    inline fn removeDirNotice(pathname: [:0]const u8) void {
        pathnameAboutNotice(pathname, about_rmdir_0_s);
    }
    inline fn makeNodeAtNotice(dir_fd: u64, name: [:0]const u8, mode: Mode, dev: Device) void {
        dirFdNameModeDeviceAboutNotice(dir_fd, name, mode, dev, about_mknod_0_s);
    }
    inline fn makeDirAtNotice(dir_fd: u64, name: [:0]const u8, mode: Mode) void {
        dirFdNameModeAboutNotice(dir_fd, name, mode, about_mkdir_0_s);
    }
    inline fn statusAtNotice(dir_fd: u64, name: [:0]const u8, mode: Mode) void {
        dirFdNameModeAboutNotice(dir_fd, name, mode, about_stat_0_s);
    }
    inline fn openAtNotice(dir_fd: u64, name: [:0]const u8, fd: u64) void {
        dirFdNameFdAboutNotice(dir_fd, name, fd, about_open_0_s);
    }
    inline fn createAtNotice(dir_fd: u64, name: [:0]const u8, fd: u64) void {
        dirFdNameFdAboutNotice(dir_fd, name, fd, about_create_0_s);
    }
    inline fn unlinkAtNotice(dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutNotice(dir_fd, name, about_unlink_0_s);
    }
    inline fn statusNotice(fd: u64, mode: Mode) void {
        fdModeAboutNotice(fd, mode, about_stat_0_s);
    }
    fn aboutError(about: [:0]const u8, error_name: [:0]const u8) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "(", error_name, ")\n" });
    }
    fn dirFdNameAboutError(dir_fd: u64, name: [:0]const u8, about: [:0]const u8, error_name: [:0]const u8) void {
        const dir_fd_s: []const u8 = if (dir_fd > 1024) "CWD" else builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "dir_fd=", dir_fd_s, ", ", name, " (", error_name, ")\n" });
    }
    fn pathnameAboutError(pathname: [:0]const u8, about: [:0]const u8, error_name: [:0]const u8) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, pathname, " (", error_name, ")\n" });
    }
    fn fdAboutError(fd: u64, about: [:0]const u8, error_name: [:0]const u8) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, "fd=", fd_s, ", (", error_name, ")\n" });
    }
    fn fdFdAboutError(fd1: u64, fd2: u64, about: [:0]const u8, about_fd1: [:0]const u8, about_fd2: [:0]const u8, error_name: [:0]const u8) void {
        const fd1_s: []const u8 = builtin.fmt.ud64(fd1).readAll();
        const fd2_s: []const u8 = builtin.fmt.ud64(fd2).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about, about_fd1, fd1_s, " => ", about_fd2, fd2_s, " (", error_name, ")\n" });
    }
    fn socketError(socket_error: anytype, dom: Domain, conn: Connection) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_socket_1_s, @tagName(dom), ", ", @tagName(conn), " (", @errorName(socket_error), ")\n" });
    }
    fn truncateError(truncate_error: anytype, pathname: [:0]const u8, offset: u64) void {
        const offset_s: []const u8 = builtin.fmt.ud64(offset).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_truncate_1_s, pathname, ", offset=", offset_s, " (", @errorName(truncate_error), ")\n" });
    }
    fn ftruncateError(truncate_error: anytype, fd: u64, offset: u64) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        const offset_s: []const u8 = builtin.fmt.ud64(offset).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_truncate_1_s, "fd=", fd_s, ", offset=", offset_s, ", (", @errorName(truncate_error), ")\n" });
    }
    inline fn getCwdError(getcwd_error: anytype) void {
        aboutError(about_getcwd_1_s, @errorName(getcwd_error));
    }
    inline fn duplicateError(dup_error: anytype, fd: u64) void {
        fdAboutError(fd, about_dup_1_s, @errorName(dup_error));
    }
    inline fn duplicateToError(dup3_error: anytype, old_fd: u64, new_fd: u64) void {
        fdFdAboutError(old_fd, new_fd, about_dup3_1_s, old_fd_s, new_fd_s, @errorName(dup3_error));
    }
    inline fn pipeError(pipe_error: anytype) void {
        aboutError(about_pipe_1_s, @errorName(pipe_error));
    }
    inline fn unlinkError(unlink_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_unlink_1_s, @errorName(unlink_error));
    }
    inline fn removeDirError(rmdir_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_rmdir_1_s, @errorName(rmdir_error));
    }
    inline fn pathNotice(pathname: [:0]const u8, mode: Mode) void {
        pathnameModeAboutNotice(pathname, mode, about_open_0_s);
    }
    inline fn pathStatusNotice(pathname: [:0]const u8, mode: Mode) void {
        pathnameModeAboutNotice(pathname, mode, about_file_0_s);
    }
    inline fn openAtError(open_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_open_1_s, @errorName(open_error));
    }
    inline fn createAtError(open_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_create_1_s, @errorName(open_error));
    }
    inline fn makeDirAtError(mkdir_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_mkdir_1_s, @errorName(mkdir_error));
    }
    inline fn makeNodeAtError(mknod_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_mknod_1_s, @errorName(mknod_error));
    }
    inline fn readLinkAtError(readlink_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_readlink_1_s, @errorName(readlink_error));
    }
    inline fn statusAtError(stat_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_stat_1_s, @errorName(stat_error));
    }
    inline fn unlinkAtError(unlinkat_error: anytype, dir_fd: u64, name: [:0]const u8) void {
        dirFdNameAboutError(dir_fd, name, about_unlink_1_s, @errorName(unlinkat_error));
    }
    inline fn openError(open_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_open_1_s, @errorName(open_error));
    }
    inline fn createError(open_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_create_1_s, @errorName(open_error));
    }
    inline fn pathStatusError(stat_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_stat_1_s, @errorName(stat_error));
    }
    inline fn readLinkError(readlink_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_readlink_1_s, @errorName(readlink_error));
    }
    inline fn makeDirError(mkdir_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_mkdir_1_s, @errorName(mkdir_error));
    }
    inline fn makeNodeError(mknod_error: anytype, pathname: [:0]const u8) void {
        pathnameAboutError(pathname, about_mknod_1_s, @errorName(mknod_error));
    }
    inline fn readError(read_error: anytype, fd: u64) void {
        fdAboutError(fd, about_read_1_s, @errorName(read_error));
    }
    inline fn writeError(write_error: anytype, fd: u64) void {
        fdAboutError(fd, about_write_1_s, @errorName(write_error));
    }
    inline fn statusError(stat_error: anytype, fd: u64) void {
        fdAboutError(fd, about_stat_1_s, @errorName(stat_error));
    }
    inline fn closeError(close_error: anytype, fd: u64) void {
        fdAboutError(fd, about_close_1_s, @errorName(close_error));
    }
    fn pathMustNotBeFault(pathname: [:0]const u8, kind: Kind) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(buf, &[_][]const u8{ about_file_2_s, "'", pathname, "' must not be ", describeKind(kind), "\n" });
    }
    fn pathMustBeFault(pathname: [:0]const u8, kind: Kind, mode: Mode) void {
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_file_2_s, "'", pathname, "' must be ", describeKind(kind), "; is ", describeKind(mode.kind), "\n" });
    }
    fn fdNotKindFault(fd: u64, kind: Kind) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_file_2_s, "fd=", fd_s, " must not be ", describeKind(kind), "\n" });
    }
    fn fdKindModeFault(fd: u64, kind: Kind, mode: Mode) void {
        const fd_s: []const u8 = builtin.fmt.ud64(fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_file_2_s, "fd=", fd_s, " must be ", describeKind(kind), "; is ", describeKind(mode.kind), "\n" });
    }
    fn atDirFdMustBeFault(dir_fd: u64, name: [:0]const u8, kind: Kind, mode: Mode) void {
        const dir_fd_s: []const u8 = builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_file_2_s, "dir_fd=", dir_fd_s, ", ", name, " must be ", describeKind(kind), "; is ", describeKind(mode.kind), "\n" });
    }
    fn atDirFdMustNotBeFault(dir_fd: u64, name: [:0]const u8, kind: Kind) void {
        const dir_fd_s: []const u8 = builtin.fmt.ud64(dir_fd).readAll();
        var buf: [32768]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_file_2_s, "dir_fd=", dir_fd_s, ", ", name, " must not be ", describeKind(kind), "\n" });
    }
    fn describePerms(buf: []u8, perms: Perms) void {
        if (perms.read) {
            buf[0] = 'r';
        }
        if (perms.write) {
            buf[1] = 'w';
        }
        if (perms.execute) {
            buf[2] = 'x';
        }
    }
    fn describeMode(mode: Mode) [10]u8 {
        var ret: [10]u8 = [1]u8{'-'} ** 10;
        ret[0] = switch (mode.kind) {
            .unknown => '-',
            .directory => 'd',
            .regular => 'f',
            .character_special => 'c',
            .block_special => 'b',
            .socket => 'S',
            .named_pipe => 'p',
            .symbolic_link => 'l',
        };
        describePerms(ret[1..], mode.owner);
        describePerms(ret[4..], mode.group);
        describePerms(ret[7..], mode.other);
        return ret;
    }
    fn describeKind(kind: Kind) []const u8 {
        switch (kind) {
            .unknown => return unknown_s,
            .regular => return regular_s,
            .directory => return directory_s,
            .character_special => return character_special_s,
            .block_special => return block_special_s,
            .named_pipe => return named_pipe_s,
            .socket => return socket_s,
            .symbolic_link => return symbolic_link_s,
        }
    }
    pub fn executeNotice(filename: [:0]const u8, args: []const [*:0]const u8) void {
        var argc: u64 = args.len;
        var buf: [4096 +% 128]u8 = undefined;
        var len: u64 = 0;
        var idx: u64 = 0;
        len +%= builtin.debug.writeMany(buf[len..], about_execve_0_s);
        len +%= builtin.debug.writeMany(buf[len..], filename);
        buf[len] = ' ';
        len +%= 1;
        if (filename.ptr == args[0]) {
            len +%= builtin.debug.writeMany(buf[len..], "[0] ");
            idx +%= 1;
        }
        while (idx != argc) : (idx +%= 1) {
            var arg_len: u64 = 0;
            while (args[idx][arg_len] != 0) arg_len +%= 1;
            if (arg_len == 0) {
                buf[len] = '\'';
                len +%= 1;
                buf[len] = '\'';
                len +%= 1;
            }
            if (len +% arg_len >= buf.len -% 37) {
                break;
            }
            for (args[idx][0..arg_len], 0..) |c, j| buf[len +% j] = c;
            len +%= arg_len;
            buf[len] = ' ';
            len +%= 1;
        }
        if (argc != idx) {
            len +%= builtin.debug.writeMany(buf[len..], " ... and ");
            len +%= builtin.debug.writeMany(buf[len..], builtin.fmt.ud64(argc -% idx).readAll());
            len +%= builtin.debug.writeMany(buf[len..], " more args ... \n");
        } else {
            buf[len] = '\n';
            len +%= 1;
        }
        builtin.debug.write(buf[0..len]);
    }
    pub fn executeErrorBrief(exec_error: anytype, filename: [:0]const u8) void {
        var buf: [4096 +% 128]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, [_][]const u8{ about_execve_1_s, "(", @errorName(exec_error), ") ", filename });
    }
    pub fn executeError(exec_error: anytype, filename: [:0]const u8, args: []const [*:0]const u8) void {
        const max_len: u64 = 4096 +% 128;
        var argc: u64 = args.len;
        var buf: [max_len]u8 = undefined;
        var idx: u64 = 0;
        var len: u64 = 0;
        len +%= builtin.debug.writeMany(buf[len..], about_execve_1_s);
        len +%= builtin.debug.writeMany(buf[len..], "(");
        len +%= builtin.debug.writeMany(buf[len..], @errorName(exec_error));
        len +%= builtin.debug.writeMany(buf[len..], ")");
        len +%= builtin.debug.writeMany(buf[len..], filename);
        buf[len] = ' ';
        len +%= 1;
        if (filename.ptr == args[0]) {
            len +%= builtin.debug.writeMany(buf[len..], "[0] ");
            idx +%= 1;
        }
        while (idx != argc) : (idx +%= 1) {
            var arg_len: u64 = 0;
            while (args[idx][arg_len] != 0) arg_len +%= 1;
            if (arg_len == 0) {
                buf[len] = '\'';
                len +%= 1;
                buf[len] = '\'';
                len +%= 1;
            }
            if (len +% arg_len >= max_len -% 37) {
                break;
            }
            for (args[idx][0..arg_len], 0..) |c, j| buf[len +% j] = c;
            len +%= arg_len;
            buf[len] = ' ';
            len +%= 1;
        }
        if (argc != idx) {
            len +%= builtin.debug.writeMany(buf[len..], " ... and ");
            len +%= builtin.debug.writeMany(buf[len..], builtin.fmt.ud64(argc -% idx).readAll());
            len +%= builtin.debug.writeMany(buf[len..], " more args ... \n");
        } else {
            buf[len] = '\n';
            len +%= 1;
        }
        builtin.debug.write(buf[0..len]);
    }
};
