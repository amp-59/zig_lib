const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const _dir = @import("./dir.zig");
const _chan = @import("./chan.zig");
pub usingnamespace _dir;
pub usingnamespace _chan;
pub const mode = struct {
    pub const regular: Mode = .{
        .owner = .{ .read = true, .write = true, .execute = false },
        .group = .{ .read = true, .write = false, .execute = false },
        .other = .{ .read = false, .write = false, .execute = false },
        .sticky = false,
        .set_gid = false,
        .set_uid = false,
        .kind = .regular,
    };
    pub const executable: Mode = .{
        .owner = .{ .read = true, .write = true, .execute = true },
        .group = .{ .read = true, .write = false, .execute = true },
        .other = .{ .read = false, .write = false, .execute = false },
        .sticky = false,
        .set_gid = false,
        .set_uid = false,
        .kind = .regular,
    };
    pub const named_pipe: Mode = .{
        .owner = .{ .read = true, .write = true, .execute = false },
        .group = .{ .read = true, .write = false, .execute = false },
        .other = .{ .read = false, .write = false, .execute = false },
        .sticky = false,
        .set_gid = false,
        .set_uid = false,
        .kind = .named_pipe,
    };
    pub const directory: Mode = .{
        .owner = .{ .read = true, .write = true, .execute = true },
        .group = .{ .read = true, .write = true, .execute = true },
        .other = .{ .read = false, .write = false, .execute = false },
        .sticky = false,
        .set_gid = false,
        .set_uid = false,
        .kind = .directory,
    };
};
pub const Access = packed struct(usize) {
    exec: bool = false,
    write: bool = false,
    read: bool = false,
    zb3: u61 = 0,
};
pub const Map = struct {
    pub const Flags = packed struct(usize) {
        visibility: Visibility = .private,
        zb2: u2 = 0,
        fixed: bool = true,
        anonymous: bool = false,
        @"32bit": bool = false,
        zb7: u1 = 0,
        grows_down: bool = false,
        zb9: u2 = 0,
        deny_write: bool = true,
        executable: bool = false,
        locked: bool = false,
        no_reserve: bool = false,
        populate: bool = true,
        non_block: bool = false,
        stack: bool = false,
        huge_tlb: bool = false,
        sync: bool = false,
        fixed_noreplace: bool = false,
        zb21: u43 = 0,
    };
    pub const Visibility = enum { shared, shared_validate, private };
    pub const Protection = packed struct(usize) {
        read: bool = true,
        write: bool = false,
        exec: bool = false,
        zb3: u21 = 0,
        grows_down: bool = false,
        grows_up: bool = false,
        zb26: u38 = 0,
    };
};
pub const Kind = enum(u4) {
    unknown = 0,
    regular = MODE.R.IFREG,
    directory = MODE.R.IFDIR,
    character_special = MODE.R.IFCHR,
    block_special = MODE.R.IFBLK,
    named_pipe = MODE.R.IFIFO,
    socket = MODE.R.IFSOCK,
    symbolic_link = MODE.R.IFLNK,
    const MODE = sys.S;
};
pub const Open = struct {
    pub const Flags = packed struct(usize) {
        write_only: bool = false,
        read_write: bool = false,
        zb2: u4 = 0,
        create: bool = false,
        exclusive: bool = false,
        no_ctty: bool = true,
        truncate: bool = false,
        append: bool = false,
        non_block: bool = false,
        dsync: bool = false,
        @"async": bool = false,
        no_cache: bool = false,
        zb15: u1 = 0,
        directory: bool = false,
        no_follow: bool = false,
        no_atime: bool = false,
        close_on_exec: bool = true,
        zb20: u1 = 0,
        path: bool = false,
        temporary: bool = false,
        zb23: u41 = 0,
    };
    pub const Options = meta.EnumBitField(enum(u64) {
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
        //file_sync = OPEN.SYNC,
        data_sync = OPEN.DSYNC,
        const OPEN = sys.O;
    });
};

pub const Whence = enum(u64) { // set, cur, end
    set = SEEK.SET,
    cur = SEEK.CUR,
    end = SEEK.END,
    const SEEK = sys.SEEK;
};
pub const Shutdown = enum(u64) {
    /// Further receptions will be disallowed
    read = SHUT.RD,
    /// Further transmissions will be disallowed
    write = SHUT.WR,
    /// Further receptions and transmissions will be disallowed
    read_write = SHUT.RDWR,
    const SHUT = sys.SHUT;
};
pub const ReadWrite = meta.EnumBitField(enum(u64) {
    append = RWF.APPEND,
    high_priority = RWF.HIPRI,
    no_wait = RWF.NOWAIT,
    file_sync = RWF.SYNC,
    data_sync = RWF.DSYNC,
    const RWF = sys.RWF;
});
pub const At = meta.EnumBitField(enum(u64) {
    empty_path = AT.EMPTY_PATH,
    no_follow = AT.SYMLINK_NOFOLLOW,
    follow = AT.SYMLINK_FOLLOW,
    no_auto_mount = AT.NO_AUTOMOUNT,
    const AT = sys.AT;
});
pub const Device = extern struct {
    major: u32 = 0,
    minor: u8 = 0,
};
pub const Pipe = packed struct {
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
        const IN = sys.TC.I;
    });
    pub const Output = meta.EnumBitField(enum(u32) {
        post_processing = OUT.POST,
        translate_carriage_return = OUT.CRNL,
        no_carriage_return = OUT.NOCR,
        newline_return = OUT.NLRET,
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
pub const Socket = struct {
    pub const Options = meta.EnumBitField(enum(u64) {
        non_block = SOCK.NONBLOCK,
        close_on_exec = SOCK.CLOEXEC,
        const SOCK = sys.SOCK;
    });
    pub const Type = struct {};
    pub const Domain = enum(u16) {
        unix = AF.UNIX,
        ipv4 = AF.INET,
        ipv6 = AF.INET6,
        netlink = AF.NETLINK,
        const AF = sys.AF;
    };
    pub const Connection = enum(u64) {
        tcp = SOCK.STREAM,
        udp = SOCK.DGRAM,
        raw = SOCK.RAW,
        const SOCK = sys.SOCK;
    };
    pub const AddressFamily = enum(u16) {
        ipv4 = AF.INET,
        ipv6 = AF.INET6,
        const AF = sys.AF;
    };
    pub const Address = extern union {
        ipv4: AddressIPv4,
        ipv6: AddressIPv6,
    };
    pub const AddressIPv4 = extern struct {
        family: AddressFamily = .ipv4,
        port: u16,
        addr: [4]u8,
        @"0": [8]u8 = undefined,
        pub const addrlen: u64 = @sizeOf(AddressIPv4);
        pub fn create(port: u16, addr: [4]u8) Address {
            return .{ .ipv4 = .{
                .port = @byteSwap(port),
                .addr = addr,
            } };
        }
    };
    pub const AddressIPv6 = extern struct {
        family: AddressFamily = .ipv6,
        port: u16,
        flow_info: u32,
        addr: [8]u16,
        scope_id: u32,
        pub const addrlen: u64 = @sizeOf(AddressIPv6);
        pub fn create(port: u16, flow_info: u32, addr: [8]u16, scope_id: u32) Address {
            return .{ .ipv6 = .{
                .port = @byteSwap(port),
                .flow_info = flow_info,
                .addr = addr,
                .scope_id = scope_id,
            } };
        }
    };
    pub const Protocol = enum(u64) {
        ip = 0,
        icmp = 1,
        igmp = 2,
        ipip = 4,
        tcp = 6,
        egp = 8,
        pup = 12,
        udp = 17,
        idp = 22,
        tp = 29,
        dccp = 33,
        ipv6 = 41,
        rsvp = 46,
        gre = 47,
        esp = 50,
        ah = 51,
        mtp = 92,
        beetph = 94,
        encap = 98,
        pim = 103,
        comp = 108,
        l2tp = 115,
        sctp = 132,
        udplite = 136,
        mpls = 137,
        ethernet = 143,
        raw = 255,
        mptcp = 262,
        max = 263,
        routing = 43,
        fragment = 44,
        icmpv6 = 58,
        none = 59,
        dstopts = 60,
        mh = 135,
    };
};
pub const Status = extern struct {
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
    atime: time.TimeSpec,
    mtime: time.TimeSpec,
    ctime: time.TimeSpec,
    @"2": [24]u8,
    pub fn isExecutable(st: *const Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.execute;
        }
        if (group_id == st.gid) {
            return st.mode.group.execute;
        }
        return st.mode.other.execute;
    }
    pub fn isReadable(st: *const Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
    pub fn isWritable(st: *const Status, user_id: u16, group_id: u16) bool {
        if (user_id == st.uid) {
            return st.mode.owner.read;
        }
        if (group_id == st.gid) {
            return st.mode.group.read;
        }
        return st.mode.other.read;
    }
    pub fn count(st: *const Status, comptime T: type) u64 {
        return st.size / @sizeOf(T);
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
    zb240: u16,
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
    zb1216: [13]u64,
    pub const Fields = packed struct(usize) {
        type: bool = true,
        mode: bool = true,
        nlink: bool = true,
        uid: bool = true,
        gid: bool = true,
        atime: bool = true,
        mtime: bool = true,
        ctime: bool = true,
        ino: bool = true,
        size: bool = true,
        blocks: bool = true,
        btime: bool = false,
        mnt_id: bool = false,
        zb13: u51 = 0,
    };
    const Attributes = packed struct(usize) {
        zb0: u2 = 0,
        compressed: bool = false,
        zb3: u1 = 0,
        immutable: bool = false,
        append: bool = false,
        nodump: bool = false,
        zb7: u4 = 0,
        encrypted: bool = false,
        automount: bool = false,
        mount_root: bool = false,
        zb14: u6 = 0,
        verity: bool = false,
        dax: bool = false,
        zb22: u42 = 0,
    };
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
        return termios.special[@intFromEnum(tag)];
    }
};
pub const OpenSpec = struct {
    options: Options = .{},
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = packed struct(usize) {
        write_only: bool = false,
        read_write: bool = false,
        zb2: u4 = 0,
        create: bool = false,
        exclusive: bool = false,
        no_ctty: bool = true,
        truncate: bool = false,
        append: bool = false,
        non_block: bool = false,
        dsync: bool = false,
        @"async": bool = false,
        no_cache: bool = false,
        zb15: u1 = 0,
        directory: bool = false,
        no_follow: bool = false,
        no_atime: bool = false,
        close_on_exec: bool = true,
        zb20: u1 = 0,
        path: bool = false,
        temporary: bool = false,
        zb23: u41 = 0,
    };
};
pub const ReadSpec = struct {
    child: type = u8,
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.read_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const WriteSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = sys.write_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const SyncSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.sync_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    pub const Options = packed struct {
        flush_metadata: bool = true,
    };
};
pub const AccessSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.access_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
    const Options = packed struct(usize) {
        zb0: u8 = 0,
        symlink_no_follow: bool = false,
        access: bool = false,
        symlink_follow: bool = false,
        no_automount: bool = false,
        empty_path: bool = false,
        zb13: u51 = 0,
    };
};
pub const SeekSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.seek_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const ReadExtraSpec = struct {
    child: type = u8,
    options: Options,
    return_type: type = u64,
    errors: sys.ErrorPolicy = .{ .throw = sys.read_errors },
    logging: debug.Logging.SuccessError = .{},
    const Options = packed struct(u2) {
        no_wait: bool = false,
        high_priority: bool = false,
    };
};
pub const WriteExtraSpec = struct {
    child: type = u8,
    options: Options,
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = sys.write_errors },
    logging: debug.Logging.SuccessError = .{},
    pub const Options = packed struct(u4) {
        append: bool = false,
        high_priority: bool = false,
        file_sync: bool = false,
        data_sync: bool = false,
    };
};
pub const PollSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.poll_errors },
    return_type: type = void,
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const StatusSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: ?type = null,
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
        empty_path: bool = true,
    };
    fn flags(comptime stat_spec: Specification) At {
        var flags_bitfield: At = .{ .val = 0 };
        if (stat_spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        if (stat_spec.options.empty_path) {
            flags_bitfield.set(.empty_path);
        }
        comptime return flags_bitfield;
    }
};
pub const StatusExtendedSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.statx_errors },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: ?type = null,
    const Specification = @This();
    pub const Options = struct {
        no_follow: bool = false,
        empty_path: bool = false,
        no_auto_mount: bool = true,
        fields: StatusExtended.Fields = .{},
    };
    pub fn flags(comptime statx_spec: Specification) At {
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
        comptime return flags_bitfield;
    }
};
pub const MakePipeSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.pipe_errors },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = packed struct(u3) {
        close_on_exec: bool = false,
        direct: bool = false,
        non_block: bool = false,
    };
    pub fn flags(comptime pipe2_spec: Specification) Open.Options {
        var flags_bitfield: Open.Options = .{ .val = 0 };
        if (pipe2_spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        if (pipe2_spec.options.direct) {
            flags_bitfield.set(.direct);
        }
        if (pipe2_spec.options.non_block) {
            flags_bitfield.set(.non_block);
        }
        comptime return flags_bitfield;
    }
};
pub const SocketSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.socket_errors },
    logging: debug.Logging.AcquireError = .{},
    return_type: type = u64,
    const Specification = @This();
    pub const Options = packed struct(u2) {
        non_block: bool = true,
        close_on_exec: bool = true,
    };
    pub fn flags(comptime spec: SocketSpec) Socket.Options {
        var flags_bitfield: Socket.Options = .{ .val = 0 };
        if (spec.options.non_block) {
            flags_bitfield.set(.non_block);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        comptime return flags_bitfield;
    }
};
pub const BindSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.bind_errors },
    logging: debug.Logging.AcquireError = .{},
};
pub const ListenSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.listen_errors },
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const AcceptSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.accept_errors },
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const ConnectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.connect_errors },
    return_type: type = void,
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const GetSockNameSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.getsockname_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const ReceiveFromSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.recv_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const GetPeerNameSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.getpeername_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const SendToSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.send_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const SocketOptionSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.sockopt_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const ShutdownSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.shutdown_errors },
    logging: debug.Logging.SuccessError = .{},
};
pub const MakeDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const GetDirectoryEntriesSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.getdents_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
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
        stat: debug.Logging.SuccessErrorFault = .{},
        mkdir: debug.Logging.SuccessError = .{},
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
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = packed struct {
        exclusive: bool = true,
        temporary: bool = false,
        close_on_exec: bool = true,
        truncate: bool = true,
        append: bool = false,
        write: bool = true,
        read: bool = false,
    };
    pub fn flags(comptime creat_spec: Specification) Open.Options {
        var flags_bitfield: Open.Options = .{ .val = 0 };
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
        if (creat_spec.options.read and
            creat_spec.options.write)
        {
            flags_bitfield.set(.read_write);
        } else if (creat_spec.options.read) {
            flags_bitfield.set(.read_only);
        } else {
            flags_bitfield.set(.write_only);
        }
        if (creat_spec.options.append) {
            flags_bitfield.set(.append);
        }
        if (creat_spec.options.truncate) {
            flags_bitfield.set(.truncate);
        }
        comptime return flags_bitfield;
    }
};
pub const PathSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    return_type: type = u64,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = struct {
        directory: bool = true,
        no_follow: bool = true,
        close_on_exec: bool = true,
    };
    pub fn flags(comptime spec: PathSpec) Open.Options {
        var flags_bitfield: Open.Options = .{ .val = 0 };
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
        comptime return flags_bitfield;
    }
};
pub const MakeNodeSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mkdir_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const ExecuteSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.execve_errors },
    logging: debug.Logging.AttemptError = .{},
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
        comptime return flags_bitfield;
    }
};
pub const GetWorkingDirectorySpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const ReadLinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.readlink_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const MapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
};
pub const CopySpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.copy_file_range_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const SendSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.sendfile_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const LinkSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.link_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Options = struct {
        follow: bool = false,
        empty_path: bool = false,
    };
    fn flags(comptime spec: LinkSpec) At {
        var flags_bitfield: At = .{ .val = 0 };
        if (spec.options.follow) {
            flags_bitfield.set(.follow);
        }
        if (spec.options.empty_path) {
            flags_bitfield.set(.empty_path);
        }
        comptime return flags_bitfield;
    }
};
pub const CloseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    return_type: type = void,
    logging: debug.Logging.ReleaseError = .{},
};
pub const UnlinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.unlink_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const RemoveDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.rmdir_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const TruncateSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.truncate_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const DuplicateSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.dup_errors },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
    const Options = struct {
        close_on_exec: bool = false,
    };
    fn flags(comptime dup3_spec: Specification) Open.Options {
        var ret: Open.Options = .{ .val = 0 };
        if (dup3_spec.options.close_on_exec) {
            ret.set(.close_on_exec);
        }
        return ret;
    }
};
pub fn execPath(comptime exec_spec: ExecuteSpec, pathname: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    const filename_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const args_addr: u64 = @intFromPtr(args.ptr);
    const vars_addr: u64 = @intFromPtr(vars.ptr);
    const logging: debug.Logging.AttemptError = comptime exec_spec.logging.override();
    if (logging.Attempt) {
        about.executeNotice(pathname, args);
    }
    if (meta.wrap(sys.call(.execve, exec_spec.errors, exec_spec.return_type, .{ filename_buf_addr, args_addr, vars_addr }))) {
        @panic("reached unreachable");
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            about.executeErrorBrief(execve_error, pathname);
        } else if (logging.Error) {
            about.executeError(execve_error, pathname, args);
        }
        return execve_error;
    }
}
pub fn exec(comptime exec_spec: ExecuteSpec, fd: u64, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    const args_addr: u64 = @intFromPtr(args.ptr);
    const vars_addr: u64 = @intFromPtr(vars.ptr);
    const flags: At = comptime exec_spec.flags();
    const logging: debug.Logging.AttemptError = comptime exec_spec.logging.override();
    if (logging.Attempt) {
        about.executeNotice(args[0], args);
    }
    if (meta.wrap(sys.call(.execveat, exec_spec.errors, exec_spec.return_type, .{ fd, @intFromPtr(""), args_addr, vars_addr, flags.val }))) {
        @panic("reached unreachable");
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            debug.executeErrorBrief(execve_error, args[0]);
        } else if (logging.Error) {
            about.executeError(execve_error, args[0], args);
        }
        return execve_error;
    }
}
pub fn execAt(comptime exec_spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const args_addr: u64 = @intFromPtr(args.ptr);
    const vars_addr: u64 = @intFromPtr(vars.ptr);
    const flags: At = comptime exec_spec.flags();
    const logging: debug.Logging.AttemptError = comptime exec_spec.logging.override();
    if (logging.Attempt) {
        about.executeNotice(name, args);
    }
    if (meta.wrap(sys.call(.execveat, exec_spec.errors, exec_spec.return_type, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val }))) {
        @panic("reached unreachable");
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            debug.executeErrorBrief(execve_error, name);
        } else if (logging.Error) {
            about.executeError(execve_error, name, args);
        }
        return execve_error;
    }
}
pub fn read(comptime spec: ReadSpec, fd: u64, read_buf: []spec.child) sys.ErrorUnion(spec.errors, spec.return_type) {
    const read_buf_addr: u64 = @intFromPtr(read_buf.ptr);
    const read_count_mul: u64 = @sizeOf(spec.child);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.read, spec.errors, u64, .{ fd, read_buf_addr, read_buf.len *% read_count_mul }))) |ret| {
        if (logging.Success) {
            about.aboutFdMaxLenLenNotice(about.read_s, fd, read_buf.len *% read_count_mul, ret);
        }
        if (spec.return_type != void) {
            return @as(spec.return_type, @intCast(@divExact(ret, read_count_mul)));
        }
    } else |read_error| {
        if (logging.Error) {
            about.aboutFdError(about.read_s, @errorName(read_error), fd);
        }
        return read_error;
    }
}
pub inline fn readOne(comptime spec: ReadSpec, fd: u64, read_buf: *spec.child) sys.ErrorUnion(spec.errors, spec.return_type) {
    return read(spec, fd, @as([*]spec.child, @ptrCast(read_buf))[0..1]);
}
pub fn write(comptime spec: WriteSpec, fd: u64, write_buf: []const spec.child) sys.ErrorUnion(spec.errors, spec.return_type) {
    const write_buf_addr: u64 = @intFromPtr(write_buf.ptr);
    const write_count_mul: u64 = @sizeOf(spec.child);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.write, spec.errors, u64, .{ fd, write_buf_addr, write_buf.len *% write_count_mul }))) |ret| {
        if (logging.Success) {
            about.aboutFdLenNotice(about.write_s, fd, ret);
        }
        if (spec.return_type != void) {
            return @as(spec.return_type, @intCast(@divExact(ret, write_count_mul)));
        }
    } else |write_error| {
        if (logging.Error) {
            about.aboutFdError(about.write_s, @errorName(write_error), fd);
        }
        return write_error;
    }
}
pub inline fn writeOne(comptime spec: WriteSpec, fd: u64, write_val: spec.child) sys.ErrorUnion(spec.errors, spec.return_type) {
    return write(spec, fd, @as([*]const spec.child, @ptrCast(&write_val))[0..1]);
}
pub fn writeExtra(comptime write_spec: WriteExtraSpec, write_buf: []const write_spec.child) sys.ErrorUnion(
    write_spec.errors,
    write_spec.return_type,
) {
    _ = write_buf;
}
pub fn open(comptime spec: OpenSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const flags: usize = @as(usize, @bitCast(spec.options));
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags, 0 }))) |fd| {
        if (logging.Acquire) {
            about.aboutPathnameFdNotice(about.open_s, pathname, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.open_s, @errorName(open_error), pathname);
        }
        return open_error;
    }
}
pub fn openAt(comptime spec: OpenSpec, dir_fd: u64, name: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const flags: usize = @as(usize, @bitCast(spec.options));
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags, 0 }))) |fd| {
        if (logging.Acquire) {
            about.aboutDirFdNameFdNotice(about.open_s, dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.open_s, @errorName(open_error), dir_fd, name);
        }
        return open_error;
    }
}
pub fn socket(comptime spec: SocketSpec, domain: Socket.Domain, connection: Socket.Connection, protocol: Socket.Protocol) sys.ErrorUnion(
    spec.errors,
    spec.return_type,
) {
    const flags: Socket.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.socket, spec.errors, spec.return_type, .{
        @intFromEnum(domain), flags.val | @intFromEnum(connection), @intFromEnum(protocol),
    }))) |fd| {
        if (logging.Acquire) {
            about.socketNotice(fd, domain, connection);
        }
        return fd;
    } else |socket_error| {
        if (logging.Error) {
            about.socketError(socket_error, domain, connection);
        }
        return socket_error;
    }
}
pub fn socketPair(comptime spec: SocketSpec, domain: Socket.Domain, connection: Socket.Connection, fds: *[2]u32) sys.ErrorUnion(
    spec.errors,
    spec.return_type,
) {
    const flags: Socket = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.socketpair, spec.errors, spec.return_type, .{
        @intFromEnum(domain), flags.val | @intFromEnum(connection), 0, @intFromPtr(fds),
    }))) |fd| {
        if (logging.Acquire) {
            about.socketsNotice(fd, domain, connection);
        }
        return fd;
    } else |socket_error| {
        if (logging.Error) {
            about.socketsError(socket_error, domain, connection);
        }
        return socket_error;
    }
}
pub fn listen(comptime listen_spec: ListenSpec, sock_fd: u64, backlog: u64) sys.ErrorUnion(listen_spec.errors, void) {
    const logging: debug.Logging.AttemptSuccessError = comptime listen_spec.logging.override();
    if (meta.wrap(sys.call(.listen, listen_spec.errors, void, .{ sock_fd, backlog }))) {
        if (logging.Success) {
            about.listenNotice(sock_fd, backlog);
        }
    } else |listen_error| {
        if (logging.Error) {
            about.listenError(listen_error, sock_fd, backlog);
        }
        return listen_error;
    }
}
pub fn bind(comptime bind_spec: BindSpec, sock_fd: u64, addr: *Socket.Address, addrlen: u32) sys.ErrorUnion(bind_spec.errors, void) {
    const logging: debug.Logging.AcquireError = comptime bind_spec.logging.override();
    if (meta.wrap(sys.call(.bind, bind_spec.errors, void, .{ sock_fd, @intFromPtr(addr), addrlen }))) {
        if (logging.Acquire) {
            //about.bindNotice(sock_fd, addr, addrlen);
        }
    } else |bind_error| {
        if (logging.Error) {
            //about.bindError(bind_error, sock_fd, addr, addrlen);
        }
        return bind_error;
    }
}
pub fn accept(comptime accept_spec: AcceptSpec, fd: u64, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
    accept_spec.errors,
    accept_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime accept_spec.logging.override();
    if (meta.wrap(sys.call(.accept, accept_spec.errors, void, .{ fd, @intFromPtr(addr), @intFromPtr(addrlen) }))) {
        //
    } else |accept_error| {
        if (logging.Error) {
            //
        }
        return accept_error;
    }
}
pub fn connect(comptime conn_spec: ConnectSpec, fd: u64, addr: *const Socket.Address, addrlen: u64) sys.ErrorUnion(
    conn_spec.errors,
    conn_spec.return_type,
) {
    const logging: debug.Logging.AttemptSuccessError = comptime conn_spec.logging.override();
    if (meta.wrap(sys.call(.connect, conn_spec.errors, void, .{ fd, @intFromPtr(addr), addrlen }))) {
        //
    } else |connect_error| {
        if (logging.Error) {
            //
        }
        return connect_error;
    }
}
pub fn sendTo(comptime send_spec: SendToSpec, fd: u64, buf: []u8, flags: u32, addr: *Socket.Address, addrlen: u32) sys.ErrorUnion(
    send_spec.errors,
    send_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime send_spec.logging.override();
    if (meta.wrap(sys.call(.sendto, send_spec.errors, send_spec.return_type, .{
        fd, @intFromPtr(buf.ptr), buf.len, flags, @intFromPtr(addr), addrlen,
    }))) |ret| {
        return ret;
    } else |sendto_error| {
        if (logging.Error) {
            //
        }
        return sendto_error;
    }
}
pub fn receiveFrom(comptime recv_spec: ReceiveFromSpec, fd: u64, buf: []u8, flags: u32, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
    recv_spec.errors,
    recv_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime recv_spec.logging.override();
    if (meta.wrap(sys.call(.recvfrom, recv_spec.errors, recv_spec.return_type, .{
        fd, @intFromPtr(buf.ptr), buf.len, flags, @intFromPtr(addr), @intFromPtr(addrlen),
    }))) |ret| {
        //
        return ret;
    } else |recvfrom_error| {
        if (logging.Error) {
            //
        }
        return recvfrom_error;
    }
}
fn getSocketName(comptime get_spec: GetSockNameSpec, fd: u64, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
    get_spec.errors,
    get_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime get_spec.logging.override();
    if (meta.wrap(sys.call(.getsockname, get_spec.errors, void, .{ fd, @intFromPtr(addr), @intFromPtr(addrlen) }))) {
        //
    } else |getsockname_error| {
        if (logging.Error) {
            //
        }
        return getsockname_error;
    }
}
fn getPeerName(comptime get_spec: GetPeerNameSpec, fd: u64, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
    get_spec.errors,
    get_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime get_spec.logging.override();
    if (meta.wrap(sys.call(.getpeername, get_spec.errors, void, .{ fd, @intFromPtr(addr), @intFromPtr(addrlen) }))) {
        //
    } else |getpeername_error| {
        if (logging.Error) {
            //
        }
        return getpeername_error;
    }
}
fn getSocketOption(comptime get_spec: SocketOptionSpec, fd: u64, level: u64, optname: u32, optval: *u8, optlen: *u32) sys.ErrorUnion(
    get_spec.errors,
    get_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime get_spec.logging.override();
    if (meta.wrap(sys.call(.getsockopt, get_spec.errors, u64, .{ fd, level, optname, @intFromPtr(optval), @intFromPtr(optlen) }))) {
        //
    } else |getsockopt_error| {
        if (logging.Error) {
            //
        }
        return getsockopt_error;
    }
}
fn setSocketOption(comptime set_spec: SocketOptionSpec, fd: u64, level: u64, optname: u32, optval: *u8, optlen: u32) sys.ErrorUnion(
    set_spec.errors,
    set_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime set_spec.logging.override();
    if (meta.wrap(sys.call(.setsockopt, set_spec.errors, u64, .{ fd, level, optname, @intFromPtr(optval), @intFromPtr(optlen) }))) {
        //
    } else |setsockopt_error| {
        if (logging.Error) {
            //
        }
        return setsockopt_error;
    }
}
pub fn shutdown(comptime shutdown_spec: ShutdownSpec, fd: u64, how: Shutdown) sys.ErrorUnion(
    shutdown_spec.errors,
    shutdown_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime shutdown_spec.logging.override();
    if (meta.wrap(sys.call(.shutdown, shutdown_spec.errors, u64, .{ fd, @intFromEnum(how) }))) {
        //
    } else |shutdown_error| {
        if (logging.Error) {
            //
        }
        return shutdown_error;
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
pub fn dirname(pathname: [:0]const u8) []const u8 {
    return pathname[0..indexOfDirnameFinish(pathname)];
}
pub fn basename(pathname: [:0]const u8) [:0]const u8 {
    return pathname[indexOfBasenameStart(pathname)..];
}
pub fn path(comptime spec: PathSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const flags: Open.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, 0 }))) |fd| {
        if (logging.Acquire) {
            about.aboutPathnameFdNotice(about.open_s, pathname, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.open_s, @errorName(open_error), pathname);
        }
        return open_error;
    }
}
pub fn pathAt(comptime spec: PathSpec, dir_fd: u64, name: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const flags: Open.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags.val, 0 }))) |fd| {
        if (logging.Acquire) {
            about.aboutDirFdNameFdNotice(about.open_s, dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.open_s, @errorName(open_error), dir_fd, name);
        }
        return open_error;
    }
}
fn writePath(buf: *[4096]u8, pathname: []const u8) [:0]u8 {
    mach.memcpy(buf, pathname.ptr, pathname.len);
    buf[pathname.len] = 0;
    return buf[0..pathname.len :0];
}
fn makePathInternal(comptime spec: MakePathSpec, pathname: [:0]u8, comptime file_mode: Mode) sys.ErrorUnion(.{
    .throw = spec.errors.mkdir.throw ++ spec.errors.stat.throw,
    .abort = spec.errors.mkdir.abort ++ spec.errors.stat.abort,
}, void) {
    const stat_spec: StatusSpec = comptime spec.stat();
    const make_dir_spec: MakeDirSpec = spec.mkdir();
    const st: Status = pathStatus(stat_spec, pathname) catch |err| blk: {
        if (err == error.NoSuchFileOrDirectory) {
            const idx: u64 = indexOfDirnameFinish(pathname);
            debug.assertEqual(u8, pathname[idx], '/');
            if (idx != 0) {
                pathname[idx] = 0;
                try makePathInternal(spec, pathname[0..idx :0], file_mode);
                pathname[idx] = '/';
            }
        }
        try makeDir(make_dir_spec, pathname, file_mode);
        break :blk try pathStatus(stat_spec, pathname);
    };
    if (st.mode.kind != .directory) {
        return error.NotADirectory;
    }
}
pub fn makePath(comptime spec: MakePathSpec, pathname: []const u8, comptime file_mode: Mode) sys.ErrorUnion(.{
    .throw = spec.errors.mkdir.throw ++ spec.errors.stat.throw,
    .abort = spec.errors.mkdir.abort ++ spec.errors.stat.abort,
}, void) {
    var buf: [4096:0]u8 = undefined;
    const name: [:0]u8 = writePath(&buf, pathname);
    return makePathInternal(spec, name, file_mode);
}
pub fn create(comptime spec: CreateSpec, pathname: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const flags: Open.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.open, spec.errors, spec.return_type, .{ pathname_buf_addr, flags.val, @as(u16, @bitCast(file_mode)) & 0xfff }))) |fd| {
        if (logging.Acquire) {
            about.aboutPathnameFdModeNotice(about.create_s, pathname, fd, file_mode);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.create_s, @errorName(open_error), pathname);
        }
        return open_error;
    }
}
pub fn createAt(comptime spec: CreateSpec, dir_fd: u64, name: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const flags: Open.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.openat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, flags.val, @as(u16, @bitCast(file_mode)) & 0xfff }))) |fd| {
        if (logging.Acquire) {
            about.aboutDirFdNameFdNotice(about.create_s, dir_fd, name, fd);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.create_s, @errorName(open_error), dir_fd, name);
        }
        return open_error;
    }
}
pub fn close(comptime spec: CloseSpec, fd: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.ReleaseError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.close, spec.errors, spec.return_type, .{fd}))) {
        if (logging.Release) {
            about.aboutFdNotice(about.close_s, fd);
        }
    } else |close_error| {
        if (logging.Error) {
            about.aboutFdError(about.close_s, @errorName(close_error), fd);
        }
        return close_error;
    }
}
pub fn makeDir(comptime spec: MakeDirSpec, pathname: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mkdir, spec.errors, spec.return_type, .{ pathname_buf_addr, @as(u16, @bitCast(file_mode)) }))) {
        if (logging.Success) {
            about.aboutPathnameModeNotice(about.mkdir_s, pathname, file_mode);
        }
    } else |mkdir_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.mkdir_s, @errorName(mkdir_error), pathname);
        }
        return mkdir_error;
    }
}
pub fn makeDirAt(comptime spec: MakeDirSpec, dir_fd: u64, name: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mkdirat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, @as(u16, @bitCast(file_mode)) }))) {
        if (logging.Success) {
            about.aboutDirFdNameModeNotice(about.mkdir_s, dir_fd, name, file_mode);
        }
    } else |mkdir_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.mkdir_s, @errorName(mkdir_error), dir_fd, name);
        }
        return mkdir_error;
    }
}
pub fn getDirectoryEntries(comptime getdents_spec: GetDirectoryEntriesSpec, dir_fd: u64, stream_buf: []u8) sys.ErrorUnion(getdents_spec.errors, getdents_spec.return_type) {
    const stream_buf_addr: u64 = @intFromPtr(stream_buf.ptr);
    const logging: debug.Logging.SuccessError = comptime getdents_spec.logging.override();
    if (meta.wrap(sys.call(.getdents64, getdents_spec.errors, getdents_spec.return_type, .{ dir_fd, stream_buf_addr, stream_buf.len }))) |ret| {
        if (logging.Success) {
            about.aboutFdMaxLenLenNotice(about.getdents_s, dir_fd, stream_buf.len, ret);
        }
        return ret;
    } else |getdents_error| {
        if (logging.Error) {
            about.aboutFdError(about.getdents_s, @errorName(getdents_error), dir_fd);
        }
        return getdents_error;
    }
}
pub fn makeNode(comptime spec: MakeNodeSpec, pathname: [:0]const u8, comptime file_mode: Mode, comptime dev: Device) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mknod, spec.errors, spec.return_type, .{ pathname_buf_addr, @as(u16, @bitCast(file_mode)), @as(u64, @bitCast(dev)) }))) {
        if (logging.Success) {
            about.aboutPathnameModeDeviceNotice(about.mknod_s, pathname, file_mode, dev);
        }
    } else |mknod_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.mknod_s, @errorName(mknod_error), pathname);
        }
        return mknod_error;
    }
}
pub fn makeNodeAt(comptime spec: MakeNodeSpec, dir_fd: u64, name: [:0]const u8, comptime file_mode: Mode, comptime dev: Device) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mknodat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, @as(u16, @bitCast(file_mode)), @as(u64, @bitCast(dev)) }))) {
        if (logging.Success) {
            about.aboutDirFdNameModeDeviceNotice(about.mknod_s, dir_fd, name, file_mode, dev);
        }
    } else |mknod_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.mknod_s, @errorName(mknod_error), dir_fd, name);
        }
        return mknod_error;
    }
}
pub fn getCwd(comptime spec: GetWorkingDirectorySpec, buf: []u8) sys.ErrorUnion(spec.errors, [:0]const u8) {
    const buf_addr: u64 = @intFromPtr(buf.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.getcwd, spec.errors, spec.return_type, .{ buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        const ret: [:0]const u8 = buf[0 .. len -% 1 :0];
        if (logging.Success) {
            about.aboutPathnameNotice(about.getcwd_s, ret);
        }
        return ret;
    } else |getcwd_error| {
        if (logging.Error) {
            debug.about.aboutError(about.getcwd_s, @errorName(getcwd_error));
        }
        return getcwd_error;
    }
}
pub fn readLink(comptime spec: ReadLinkSpec, pathname: [:0]const u8, buf: []u8) sys.ErrorUnion(spec.errors, [:0]const u8) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const buf_addr: u64 = @intFromPtr(buf.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.readlink, spec.errors, spec.return_type, .{ pathname_buf_addr, buf_addr, buf.len }))) |len| {
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.readlink_s, @errorName(readlink_error), pathname);
        }
        return readlink_error;
    }
}
pub fn readLinkAt(comptime spec: ReadLinkSpec, dir_fd: u64, name: [:0]const u8, buf: []u8) sys.ErrorUnion(spec.errors, [:0]const u8) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const buf_addr: u64 = @intFromPtr(buf.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.readlinkat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.readlink_s, @errorName(readlink_error), dir_fd, name);
        }
        return readlink_error;
    }
}
pub fn unlink(comptime spec: UnlinkSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.unlink, spec.errors, spec.return_type, .{pathname_buf_addr}))) {
        if (logging.Success) {
            about.aboutPathnameNotice(about.unlink_s, pathname);
        }
    } else |unlink_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.unlink_s, @errorName(unlink_error), pathname);
        }
        return unlink_error;
    }
}
pub fn unlinkAt(comptime spec: UnlinkSpec, dir_fd: u64, name: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.unlinkat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, 0 }))) {
        if (logging.Success) {
            about.aboutDirFdNameNotice(about.unlink_s, dir_fd, name);
        }
    } else |unlinkat_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.unlink_s, @errorName(unlinkat_error), dir_fd, name);
        }
        return unlinkat_error;
    }
}
pub fn removeDir(comptime spec: RemoveDirSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (sys.call(.rmdir, spec.errors, spec.return_type, .{pathname_buf_addr})) {
        if (logging.Success) {
            about.aboutPathnameNotice(about.rmdir_s, pathname);
        }
    } else |rmdir_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.rmdir_s, @errorName(rmdir_error), pathname);
        }
        return rmdir_error;
    }
}
pub fn pathStatus(comptime spec: StatusSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, Status) {
    var st: Status = undefined;
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const st_buf_addr: u64 = @intFromPtr(&st);
    const logging: debug.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.stat, spec.errors, void, .{ pathname_buf_addr, st_buf_addr }))) {
        if (logging.Success) {
            about.aboutPathnameModeNotice(about.file_s, pathname, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.stat_s, @errorName(stat_error), pathname);
        }
        return stat_error;
    }
    return st;
}
pub fn status(comptime spec: StatusSpec, fd: u64) sys.ErrorUnion(spec.errors, Status) {
    var st: Status = undefined;
    const st_buf_addr: u64 = @intFromPtr(&st);
    const logging: debug.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.fstat, spec.errors, void, .{ fd, st_buf_addr }))) {
        if (logging.Success) {
            about.aboutFdModeNotice(about.stat_s, fd, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutFdError(about.stat_s, @errorName(stat_error), fd);
        }
        return stat_error;
    }
    return st;
}
pub fn statusAt(comptime spec: StatusSpec, dir_fd: u64, name: [:0]const u8) sys.ErrorUnion(spec.errors, Status) {
    var st: Status = undefined;
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const st_buf_addr: u64 = @intFromPtr(&st);
    const flags: At = comptime spec.flags();
    const logging: debug.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.newfstatat, spec.errors, void, .{ dir_fd, name_buf_addr, st_buf_addr, flags.val }))) {
        if (logging.Success) {
            about.aboutDirFdNameModeNotice(about.stat_s, dir_fd, name, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.stat_s, @errorName(stat_error), dir_fd, name);
        }
        return stat_error;
    }
    return st;
}
pub fn statusExtended(comptime spec: StatusExtendedSpec, fd: u64, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, StatusExtended) {
    var st: StatusExtended = undefined;
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const st_buf_addr: u64 = @intFromPtr(&st);
    const flags: At = comptime spec.flags();
    const mask: usize = @as(usize, @bitCast(spec.options.fields));
    const logging: debug.Logging.SuccessErrorFault = comptime spec.logging.override();
    if (meta.wrap(sys.call(.statx, spec.errors, void, .{ fd, pathname_buf_addr, flags.val, mask, st_buf_addr }))) {
        if (logging.Success) {
            about.aboutDirFdNameModeNotice(about.stat_s, fd, pathname, st.mode);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutFdError(about.stat_s, @errorName(stat_error), fd);
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
pub fn map(comptime map_spec: MapSpec, prot: Map.Protection, flags: Map.Flags, fd: u64, addr: u64, len: u64, off: u64) sys.ErrorUnion(map_spec.errors, map_spec.return_type) {
    const logging: debug.Logging.AcquireError = comptime map_spec.logging.override();
    if (meta.wrap(sys.call(.mmap, map_spec.errors, map_spec.return_type, [6]usize{ addr, len, @bitCast(prot), @bitCast(flags), fd, off }))) |ret| {
        if (logging.Acquire) {
            mem.about.aboutAddrLenNotice(about.map_s, if (map_spec.return_type != void) ret else addr, len);
        }
        return ret;
    } else |map_error| {
        if (logging.Error) {
            mem.about.aboutAddrLenError(about.map_s, @errorName(map_error), addr, len);
        }
        return map_error;
    }
}
pub fn send(comptime send_spec: SendSpec, dest_fd: u64, src_fd: u64, offset: ?*u64, count: u64) sys.ErrorUnion(
    send_spec.errors,
    send_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime send_spec.logging.override();
    if (meta.wrap(sys.call(.sendfile, send_spec.errors, u64, .{
        dest_fd, src_fd, @intFromPtr(offset), count,
    }))) |ret| {
        if (logging.Success) {
            about.sendNotice(dest_fd, src_fd, offset, count, ret);
        }
        if (send_spec.return_type == u64) {
            return ret;
        }
    } else |sendfile_error| {
        if (logging.Error) {
            about.sendError(sendfile_error, dest_fd, src_fd, offset, count);
        }
        return sendfile_error;
    }
}
pub fn copy(comptime copy_spec: CopySpec, dest_fd: u64, dest_offset: ?*u64, src_fd: u64, src_offset: ?*u64, count: u64) sys.ErrorUnion(
    copy_spec.errors,
    copy_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime copy_spec.logging.override();
    if (meta.wrap(sys.call(.copy_file_range, copy_spec.errors, copy_spec.return_type, .{
        src_fd, @intFromPtr(src_offset), dest_fd, @intFromPtr(dest_offset), count, 0,
    }))) |ret| {
        if (logging.Success) {
            about.copyNotice(src_fd, src_offset, dest_fd, dest_offset, count, ret);
        }
        if (copy_spec.return_type == u64) {
            return ret;
        }
    } else |copy_file_range_error| {
        if (logging.Error) {
            about.copyError(copy_file_range_error, src_fd, src_offset, dest_fd, dest_offset, count);
        }
        return copy_file_range_error;
    }
}
pub fn link(comptime link_spec: LinkSpec, from_pathname: [:0]const u8, to_pathname: [:0]const u8) sys.ErrorUnion(
    link_spec.errors,
    link_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime link_spec.logging.override();
    if (meta.wrap(sys.call(.link, link_spec.errors, link_spec.return_type, .{ @intFromPtr(from_pathname.ptr), @intFromPtr(to_pathname.ptr) }))) |ret| {
        if (logging.Success) {
            about.aboutPathnamePathnameNotice(about.link_s, " -> ", from_pathname, to_pathname);
        }
        return ret;
    } else |link_error| {
        if (logging.Error) {
            about.aboutPathnamePathnameError(about.link_s, @errorName(link_error), " -> ", from_pathname, to_pathname);
        }
        return link_error;
    }
}
pub fn linkAt(comptime link_spec: LinkSpec, src_dir_fd: u64, from_name: [:0]const u8, dest_dir_fd: u64, to_name: [:0]const u8) sys.ErrorUnion(
    link_spec.errors,
    link_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime link_spec.logging.override();
    const flags: At = comptime link_spec.flags();
    if (meta.wrap(sys.call(.linkat, link_spec.errors, link_spec.return_type, .{
        src_dir_fd, @intFromPtr(from_name.ptr), dest_dir_fd, @intFromPtr(to_name.ptr), flags.val,
    }))) |ret| {
        if (logging.Success) {
            about.aboutDirFdNameDirFdNameNotice(about.link_s, "src_dir_fd=", " -> ", "dest_dir_fd=", src_dir_fd, from_name, dest_dir_fd, to_name);
        }
        return ret;
    } else |linkat_error| {
        if (logging.Error) {
            about.aboutDirFdNameDirFdNameError(about.link_s, @errorName(linkat_error), "src_dir_fd=", " -> ", "dest_dir_fd=", src_dir_fd, from_name, dest_dir_fd, to_name);
        }
        return linkat_error;
    }
}
pub fn symbolicLink(comptime link_spec: LinkSpec, from_pathname: [:0]const u8, to_pathname: [:0]const u8) sys.ErrorUnion(
    link_spec.errors,
    link_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime link_spec.logging.override();
    if (meta.wrap(sys.call(.symlink, link_spec.errors, link_spec.return_type, .{
        @intFromPtr(from_pathname.ptr), @intFromPtr(to_pathname.ptr),
    }))) |ret| {
        if (logging.Success) {
            about.aboutPathnamePathnameNotice(about.symlink_s, " -> ", from_pathname, to_pathname);
        }
        return ret;
    } else |symlink_error| {
        if (logging.Error) {
            about.aboutPathnamePathnameError(about.symlink_s, @errorName(symlink_error), " -> ", from_pathname, to_pathname);
        }
        return symlink_error;
    }
}
pub fn symbolicLinkAt(comptime link_spec: LinkSpec, pathname: [:0]const u8, dir_fd: u64, name: [:0]const u8) sys.ErrorUnion(
    link_spec.errors,
    link_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime link_spec.logging.override();
    if (meta.wrap(sys.call(.symlinkat, link_spec.errors, link_spec.return_type, .{
        @intFromPtr(pathname.ptr), dir_fd, @intFromPtr(name.ptr),
    }))) |ret| {
        if (logging.Success) {
            about.aboutPathnameDirFdNameNotice(about.symlink_s, " -> ", pathname, dir_fd, name);
        }
        return ret;
    } else |symlinkat_error| {
        if (logging.Error) {
            about.aboutPathnameDirFdNameError(about.symlink_s, @errorName(symlinkat_error), " -> ", pathname, dir_fd, name);
        }
        return symlinkat_error;
    }
}
pub fn sync(comptime sync_spec: SyncSpec, fd: u64) sys.ErrorUnion(sync_spec.errors, sync_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime sync_spec.logging.override();
    const syscall: sys.Fn = if (sync_spec.options.flush_metadata) .fsync else .fdatasync;
    if (meta.wrap(sys.call(syscall, sync_spec.errors, sync_spec.return_type, .{fd}))) |ret| {
        if (logging.Success) {
            about.aboutFdNotice(about.sync_s, fd);
        }
        return ret;
    } else |sync_error| {
        if (logging.Error) {
            about.aboutFdError(about.sync_s, @errorName(sync_error), fd);
        }
        return sync_error;
    }
}
pub fn seek(comptime seek_spec: SeekSpec, fd: u64, offset: u64, whence: Whence) sys.ErrorUnion(
    seek_spec.errors,
    seek_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime seek_spec.logging.override();
    if (meta.wrap(sys.call(.lseek, seek_spec.errors, usize, .{ fd, offset, @intFromEnum(whence) }))) |ret| {
        if (logging.Success) {
            about.seekNotice(fd, offset, whence, ret);
        }
        if (seek_spec.return_type != void) {
            return ret;
        }
    } else |seek_error| {
        if (logging.Error) {
            about.seekError(seek_error, fd, offset, whence);
        }
        return seek_error;
    }
}
pub fn truncate(comptime spec: TruncateSpec, fd: u64, offset: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.ftruncate, spec.errors, spec.return_type, .{ fd, offset }))) |ret| {
        if (logging.Success) {
            about.aboutFdOffsetNotice(about.truncate_s, fd, offset);
        }
        return ret;
    } else |truncate_error| {
        if (logging.Error) {
            about.aboutFdOffsetError(about.truncate_s, @errorName(truncate_error), fd, offset);
        }
        return truncate_error;
    }
}
pub fn pathTruncate(comptime spec: TruncateSpec, pathname: [:0]const u8, offset: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.truncate, spec.errors, spec.return_type, .{ @intFromPtr(pathname.ptr), offset }))) |ret| {
        if (logging.Success) {
            about.aboutPathnameOffsetNotice(about.truncate_s, pathname, offset);
        }
        return ret;
    } else |truncate_error| {
        if (logging.Error) {
            about.aboutPathnameOffsetError(about.truncate_s, @errorName(truncate_error), pathname, offset);
        }
        return truncate_error;
    }
}
// Getting terminal attributes is classed as a resource acquisition.
const TerminalAttributesSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.ioctl_errors },
    return_type: type = void,
    logging: debug.Logging.Default = .{},
};
const IOControlSpec = struct {
    const TC = sys.TC;
    const TIOC = sys.TIOC;
};

pub fn duplicate(comptime dup_spec: DuplicateSpec, old_fd: u64) sys.ErrorUnion(dup_spec.errors, dup_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime dup_spec.logging.override();
    if (meta.wrap(sys.call(.dup, dup_spec.errors, dup_spec.return_type, .{old_fd}))) |new_fd| {
        if (logging.Success) {
            about.aboutFdFdNotice(about.dup_s, "old_fd=", "new_fd=", old_fd, new_fd);
        }
        if (dup_spec.return_type == u64) {
            return old_fd;
        }
    } else |dup_error| {
        if (logging.Error) {
            about.aboutFdError(about.dup_s, @errorName(dup_error), old_fd);
        }
        return dup_error;
    }
}
pub fn duplicateTo(comptime dup3_spec: DuplicateSpec, old_fd: u64, new_fd: u64) sys.ErrorUnion(dup3_spec.errors, void) {
    const flags: Open.Options = comptime dup3_spec.flags();
    const logging: debug.Logging.SuccessError = comptime dup3_spec.logging.override();
    if (meta.wrap(sys.call(.dup3, dup3_spec.errors, void, .{ old_fd, new_fd, flags.val }))) {
        if (logging.Success) {
            about.aboutFdFdNotice(about.dup3_s, "old_fd=", "new_fd=", old_fd, new_fd);
        }
    } else |dup3_error| {
        if (logging.Error) {
            about.aboutFdFdError(about.dup_s, @errorName(dup3_error), "old_fd=", "new_fd=", old_fd, new_fd);
        }
        return dup3_error;
    }
}
pub fn makePipe(comptime pipe2_spec: MakePipeSpec) sys.ErrorUnion(pipe2_spec.errors, Pipe) {
    var pipefd: Pipe = undefined;
    const pipefd_addr: u64 = @intFromPtr(&pipefd);
    const flags: Open.Options = comptime pipe2_spec.flags();
    const logging: debug.Logging.AcquireError = comptime pipe2_spec.logging.override();
    if (meta.wrap(sys.call(.pipe2, pipe2_spec.errors, void, .{ pipefd_addr, flags.val }))) {
        if (logging.Acquire) {
            about.aboutFdFdNotice(about.pipe_s, "read_fd=", "write_fd=", pipefd.read, pipefd.write);
        }
    } else |pipe2_error| {
        if (logging.Error) {
            debug.about.aboutError(about.pipe_s, @errorName(pipe2_error));
        }
    }
    return pipefd;
}
pub fn poll(comptime poll_spec: PollSpec, fds: []PollFd, timeout: u32) sys.ErrorUnion(poll_spec.errors, poll_spec.return_type) {
    const fds_addr: u64 = @intFromPtr(fds.ptr);
    const logging: debug.Logging.AttemptSuccessError = comptime poll_spec.logging.override();
    if (logging.Attempt) {
        about.pollNotice(fds, timeout);
    }
    if (meta.wrap(sys.call(.poll, poll_spec.errors, void, .{ fds_addr, fds.len, timeout }))) {
        if (logging.Success) {
            about.pollNotice(fds, timeout);
        }
        if (poll_spec.return_type == bool) {
            for (fds) |pollfd| {
                if (@as(u16, @bitCast(pollfd.expect)) !=
                    @as(u16, @bitCast(pollfd.actual)))
                {
                    return false;
                }
            }
            return true;
        }
    } else |poll_error| {
        return poll_error;
    }
}
pub inline fn pollOne(comptime poll_spec: PollSpec, fd: *PollFd, timeout: u32) sys.ErrorUnion(poll_spec.errors, poll_spec.return_type) {
    return poll(poll_spec, @as([*]PollFd, @ptrCast(fd))[0..1], timeout);
}
// TODO:
//  bind
//  connect
//  ioctl
//  readv
//  recvfrom
//  sendto
//  setsockopt
//  writev
// DONE:
//  openat
//  poll
//  read
//  socket
//  write
//  close
//  execve
//  exit_group
//  fstat
//  getrandom
pub fn accessAt(comptime access_spec: AccessSpec, dir_fd: u64, name: [:0]const u8, ok: Access) sys.ErrorUnion(access_spec.errors, void) {
    if (meta.wrap(sys.call(.faccessat2, access_spec.errors, void, .{
        dir_fd, @intFromPtr(name.ptr), @as(usize, @bitCast(ok)), @as(usize, @bitCast(access_spec.options)),
    }))) |ret| {
        return ret;
    } else |access_error| {
        return access_error;
    }
}
pub fn access(comptime access_spec: AccessSpec, pathname: [:0]const u8, ok: Access) sys.ErrorUnion(access_spec.errors, void) {
    if (meta.wrap(sys.call(.access, access_spec.errors, void, .{ @intFromPtr(pathname.ptr), @as(usize, @bitCast(ok)) }))) |ret| {
        return ret;
    } else |access_error| {
        return access_error;
    }
}
pub fn pathIs(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
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
pub fn pathIsNot(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
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
pub fn pathAssert(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(pathStatus(stat_spec, pathname));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            about.pathMustBeFault(pathname, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn isAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
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
pub fn isNotAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
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
pub fn assertAt(comptime stat_spec: StatusSpec, dir_fd: u64, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(statusAt(stat_spec, dir_fd, name));
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (st.mode.kind != kind) {
        if (logging.Fault) {
            debug.atDirFdMustBeFault(dir_fd, name, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn is(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.ErrorUnion(
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
pub fn isNot(comptime stat_spec: StatusSpec, kind: Kind, fd: u64) sys.ErrorUnion(
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
pub fn assert(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            about.fdKindModeFault(fd, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
pub fn assertNot(comptime stat_spec: StatusSpec, fd: u64, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type orelse void,
) {
    const st: Status = try meta.wrap(status(stat_spec, fd));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (res) {
        if (logging.Fault) {
            about.fdNotKindFault(fd, kind);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type) |return_type| {
        return mach.cmovV(return_type == Status, st);
    }
}
fn getTerminalAttributes() void {}
fn setTerminalAttributes() void {}
pub fn readRandom(buf: []u8) !void {
    return sys.call(.getrandom, .{ .throw = sys.getrandom_errors }, void, .{ @intFromPtr(buf.ptr), buf.len, sys.GRND.RANDOM });
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
            const child: type = T;
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
                return @as(*const child, @ptrFromInt(t_ab_addr)).*;
            }
            random.data.impl.define(s_up_addr - s_lb_addr);
            return @as(*const child, @ptrFromInt(s_ab_addr)).*;
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
pub const about = struct {
    const map_s: fmt.AboutSrc = fmt.about("map");
    const dup_s: fmt.AboutSrc = fmt.about("dup");
    const dup3_s: fmt.AboutSrc = fmt.about("dup3");
    const copy_s: fmt.AboutSrc = fmt.about("copy");
    const send_s: fmt.AboutSrc = fmt.about("send");
    const stat_s: fmt.AboutSrc = fmt.about("stat");
    const open_s: fmt.AboutSrc = fmt.about("open");
    const file_s: fmt.AboutSrc = fmt.about("file");
    const read_s: fmt.AboutSrc = fmt.about("read");
    const pipe_s: fmt.AboutSrc = fmt.about("pipe");
    const poll_s: fmt.AboutSrc = fmt.about("poll");
    const seek_s: fmt.AboutSrc = fmt.about("seek");
    const sync_s: fmt.AboutSrc = fmt.about("sync");
    const link_s: fmt.AboutSrc = fmt.about("link");
    const close_s: fmt.AboutSrc = fmt.about("close");
    const mkdir_s: fmt.AboutSrc = fmt.about("mkdir");
    const mknod_s: fmt.AboutSrc = fmt.about("mknod");
    const rmdir_s: fmt.AboutSrc = fmt.about("rmdir");
    const write_s: fmt.AboutSrc = fmt.about("write");
    const socket_s: fmt.AboutSrc = fmt.about("socket");
    const listen_s: fmt.AboutSrc = fmt.about("listen");
    const create_s: fmt.AboutSrc = fmt.about("create");
    const execve_s: fmt.AboutSrc = fmt.about("execve");
    const getcwd_s: fmt.AboutSrc = fmt.about("getcwd");
    const unlink_s: fmt.AboutSrc = fmt.about("unlink");
    const symlink_s: fmt.AboutSrc = fmt.about("symlink");
    const getdents_s: fmt.AboutSrc = fmt.about("getdents");
    const unlinkat_s: fmt.AboutSrc = fmt.about("unlink");
    const truncate_s: fmt.AboutSrc = fmt.about("truncate");
    const must_not_be_file_s: *const [13:0]u8 = " must not be ";
    const must_be_file_s: *const [9:0]u8 = " must be ";
    const is_file_s: *const [5:0]u8 = "; is ";
    const unknown_file_s: *const [15:0]u8 = "an unknown file";
    const regular_file_s: *const [14:0]u8 = "a regular file";
    const directory_file_s: *const [11:0]u8 = "a directory";
    const character_special_file_s: *const [24]u8 = "a character special file";
    const block_special_file_s: *const [20]u8 = "a block special file";
    const named_pipe_file_s: *const [12]u8 = "a named pipe";
    const socket_file_s: *const [8]u8 = "a socket";
    const symbolic_link_file_s: *const [15]u8 = "a symbolic link";

    fn aboutFdNotice(about_s: fmt.AboutSrc, fd: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdModeNotice(about_s: fmt.AboutSrc, fd: u64, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = fd };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdLenNotice(about_s: fmt.AboutSrc, fd: u64, fd_len: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = fd };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += ud64.formatWriteBuf(ptr);
        ud64.value = fd_len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn aboutFdMaxLenLenNotice(about_s: fmt.AboutSrc, fd: u64, max_len: u64, act_len: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = act_len };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ud64(max_len).formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        ud64.value = max_len;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn aboutFdFdNotice(about_s: fmt.AboutSrc, fd1_s: anytype, fd2_s: anytype, fd1: u64, fd2: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..fd1_s.len].* = fd1_s.*;
        ptr += fd1_s.len;
        ptr += fmt.ud64(fd1).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr[0..fd2_s.len].* = fd2_s.*;
        ptr += fd2_s.len;
        ptr += fmt.ud64(fd2).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameModeDeviceNotice(about_s: fmt.AboutSrc, dir_fd: u64, name: [:0]const u8, file_mode: Mode, dev: Device) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0..6].* = ", dev=".*;
        ptr += 6;
        ptr += fmt.ud64(dev.major).formatWriteBuf(ptr);
        ptr[0] = ':';
        ptr += 1;
        ptr += fmt.ud64(dev.minor).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn writeDirFd(buf: [*]u8, dir_fd_s: []const u8, dir_fd: usize) usize {
        @setRuntimeSafety(builtin.is_safe);
        @memcpy(buf, dir_fd_s);
        var ptr: [*]u8 = buf + dir_fd_s.len;
        var ud64: fmt.Type.Ud64 = .{ .value = dir_fd };
        if (dir_fd > 1024) {
            ptr[0..3].* = "CWD".*;
            ptr += 3;
        } else {
            ptr += ud64.formatWriteBuf(ptr);
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    fn aboutPathnameNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameModeNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameFdNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, fd: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameFdModeNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, fd: u64, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        var ud64: fmt.Type.Ud64 = .{ .value = fd };
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameModeDeviceNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, file_mode: Mode, dev: Device) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0..6].* = ", dev=".*;
        ptr += 6;
        ptr += fmt.ud64(dev.major).formatWriteBuf(ptr);
        ptr[0] = ':';
        ptr += 1;
        ptr += fmt.ud64(dev.minor).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameModeNotice(about_s: fmt.AboutSrc, dir_fd: u64, name: [:0]const u8, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0..7].* = ", mode=".*;
        ptr += 7;
        ptr[0..10].* = describeMode(file_mode);
        ptr += 10;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameFdNotice(about_s: fmt.AboutSrc, dir_fd: u64, name: [:0]const u8, fd: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameNotice(about_s: fmt.AboutSrc, dir_fd: u64, name: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameDirFdNameNotice(about_s: fmt.AboutSrc, dir_fd1_s: []const u8, relation_s: [:0]const u8, dir_fd2_s: []const u8, dir_fd1: u64, name1: [:0]const u8, dir_fd2: u64, name2: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr += writeDirFd(ptr, dir_fd1_s, dir_fd1);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name1);
        ptr += name1.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        ptr += writeDirFd(ptr, dir_fd2_s, dir_fd2);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name2);
        ptr += name2.len;
        ptr[0] = '\n';

        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn socketNotice(fd: u64, dom: Socket.Domain, conn: Socket.Connection) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..socket_s.len].* = socket_s.*;
        var ptr: [*]u8 = buf[socket_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(dom));
        ptr += @tagName(dom).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(conn));
        ptr += @tagName(conn).len;
        ptr[0] = '\n';

        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnamePathnameNotice(about_s: fmt.AboutSrc, relation_s: [:0]const u8, pathname1: [:0]const u8, pathname2: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname1);
        ptr += pathname1.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        @memcpy(ptr, pathname2);
        ptr += pathname2.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameDirFdNameNotice(about_s: fmt.AboutSrc, relation_s: [:0]const u8, pathname: [:0]const u8, dir_fd: u64, name: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn sendNotice(dest_fd: u64, src_fd: u64, offset: ?*u64, max_count: u64, act_count: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        if (return) {}
        var buf: [32768]u8 = undefined;
        buf[0..send_s.len].* = send_s.*;
        var ptr: [*]u8 = buf[send_s.len..].ptr;
        ptr[0..7].* = "src_fd=".*;
        ptr += 7;
        var ud64: fmt.Type.Ud64 = .{ .value = src_fd };
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..10].* = ", dest_fd=".*;
        ptr += 10;
        ud64.value = dest_fd;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ud64.value = act_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        ud64.value = max_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        ud64.value = src_fd;
        if (offset) |off| {
            ptr += writeUpdateOffset(ptr, ud64, @bitCast(off.*));
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn copyNotice(dest_fd: u64, dest_offset: ?*u64, src_fd: u64, src_offset: ?*u64, max_count: u64, act_count: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..copy_s.len].* = copy_s.*;
        var ptr: [*]u8 = buf[copy_s.len..].ptr;
        ptr[0..7].* = "src_fd=".*;
        ptr += 7;
        var ud64: fmt.Type.Ud64 = .{ .value = src_fd };
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..10].* = ", dest_fd=".*;
        ptr += 10;
        ud64.value = dest_fd;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ud64.value = act_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        ud64.value = max_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        ud64.value = src_fd;
        if (src_offset) |off| {
            ptr += writeUpdateOffset(ptr, ud64, @bitCast(off.*));
        }
        ud64.value = dest_fd;
        if (dest_offset) |off| {
            ptr += writeUpdateOffset(ptr, ud64, @bitCast(off.*));
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameOffsetNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, offset: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = offset };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..10].* = ", offset=".*;
        ptr += 10;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdOffsetNotice(about_s: fmt.AboutSrc, fd: u64, offset: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = fd };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..9].* = ", offset=".*;
        ptr += 9;
        ud64.value = offset;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn seekNotice(fd: u64, offset: u64, whence: Whence, to: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..seek_s.len].* = seek_s.*;
        var ptr: [*]u8 = buf[seek_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..6].* = ", cur=".*;
        ptr += 6;
        ptr += fmt.ud64(to).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(whence));
        ptr += @tagName(whence).len;
        ptr[0] = '+';
        ptr += 1;
        ptr += fmt.ud64(offset).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn pollNotice(pollfds: []PollFd, timeout: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..poll_s.len].* = poll_s.*;
        var ptr: [*]u8 = buf[poll_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(pollfds.len).formatWriteBuf(ptr);
        ptr[0..10].* = ", timeout=".*;
        ptr += 10;
        ptr += fmt.ud64(timeout).formatWriteBuf(ptr);
        ptr[0..3].* = "ms\n".*;
        ptr += 3;
        ptr += writePollFds(ptr, pollfds);
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn listenNotice(sock_fd: u64, backlog: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..listen_s.len].* = listen_s.*;
        var ptr: [*]u8 = buf[listen_s.len..].ptr;
        ptr[0..8].* = "sock_fd=".*;
        ptr += 8;
        ptr += fmt.ud64(sock_fd).formatWriteBuf(ptr);
        ptr[0..10].* = ", backlog=".*;
        ptr += 10;
        ptr += fmt.ud64(backlog).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    pub fn executeNotice(pathname: [:0]const u8, args: []const [*:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..execve_s.len].* = execve_s.*;
        var ptr: [*]u8 = buf[execve_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        if (args.len != 0) {
            ptr[0] = ' ';
            ptr += 1;
            ptr += writeArgs(ptr, pathname, args);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, dir_fd: u64, name: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, pathname: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdError(about_s: fmt.AboutSrc, error_name: [:0]const u8, fd: u64) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdFdError(about_s: fmt.AboutSrc, error_name: [:0]const u8, fd1_s: anytype, fd2_s: anytype, fd1: u64, fd2: u64) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr[0..fd1_s.len].* = fd1_s.*;
        ptr += fd1_s.len;
        ptr += fmt.ud64(fd1).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr[0..fd2_s.len].* = fd2_s.*;
        ptr += fd2_s.len;
        ptr += fmt.ud64(fd2).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnamePathnameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, relation_s: [:0]const u8, pathname1: [:0]const u8, pathname2: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname1);
        ptr += pathname1.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        @memcpy(ptr, pathname2);
        ptr += pathname2.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutPathnameDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, relation_s: [:0]const u8, pathname: [:0]const u8, dir_fd: u64, name: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        ptr += writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutDirFdNameDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, dir_fd1_s: []const u8, relation_s: [:0]const u8, dir_fd2_s: []const u8, dir_fd1: u64, name1: [:0]const u8, dir_fd2: u64, name2: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += writeDirFd(ptr, dir_fd1_s, dir_fd1);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name1);
        ptr += name1.len;
        @memcpy(ptr, relation_s);
        ptr += relation_s.len;
        ptr += writeDirFd(ptr, dir_fd2_s, dir_fd2);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, name2);
        ptr += name2.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn socketError(socket_error: anytype, dom: Socket.Domain, conn: Socket.Connection) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..socket_s.len].* = socket_s.*;
        var ptr: [*]u8 = buf[socket_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(socket_error));
        ptr += @errorName(socket_error).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(dom));
        ptr += @tagName(dom).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(conn));
        ptr += @tagName(conn).len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn sendError(sendfile_error: anytype, dest_fd: u64, src_fd: u64, offset: ?*u64, max_count: u64) void {
        @setCold(true);
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = src_fd };
        buf[0..send_s.len].* = send_s.*;
        var ptr: [*]u8 = buf[send_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(sendfile_error));
        ptr += @errorName(sendfile_error).len;
        ptr[0..9].* = ", src_fd=".*;
        ptr += 9;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..10].* = ", dest_fd=".*;
        ptr += 10;
        ud64.value = dest_fd;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ud64.value = 0;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        ud64.value = max_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (offset) |off| {
            ptr += writeUpdateOffset(ptr, @bitCast(src_fd), @bitCast(off.*));
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn copyError(copy_file_range_error: anytype, dest_fd: u64, dest_offset: ?*u64, src_fd: u64, src_offset: ?*u64, max_count: u64) void {
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = src_fd };
        buf[0..copy_s.len].* = copy_s.*;
        var ptr: [*]u8 = buf[copy_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(copy_file_range_error));
        ptr += @errorName(copy_file_range_error).len;
        ptr[0..9].* = ", src_fd=".*;
        ptr += 9;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..10].* = ", dest_fd=".*;
        ptr += 10;
        ud64.value = dest_fd;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ud64.value = 0;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        ud64.value = max_count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (src_offset) |off| {
            ptr += writeUpdateOffset(ptr, @bitCast(src_fd), @bitCast(off.*));
        }
        if (dest_offset) |off| {
            ptr += writeUpdateOffset(ptr, @bitCast(dest_fd), @bitCast(off.*));
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameOffsetError(about_s: fmt.AboutSrc, error_name: []const u8, pathname: [:0]const u8, offset: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = offset };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..9].* = ", offset=".*;
        ptr += 9;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn aboutFdOffsetError(about_s: fmt.AboutSrc, error_name: []const u8, fd: u64, offset: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ud64: fmt.Type.Ud64 = .{ .value = fd };
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..9].* = ", offset=".*;
        ptr += 9;
        ud64.value = offset;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn seekError(seek_error: anytype, fd: u64, offset: u64, whence: Whence) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..seek_s.len].* = seek_s.*;
        var ptr: [*]u8 = buf[seek_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(seek_error));
        ptr += @errorName(seek_error).len;
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..5].* = ", to=".*;
        ptr += 5;
        ptr += fmt.ud64(offset).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, @tagName(whence));
        ptr += @tagName(whence).len;
        ptr[0] = '+';
        ptr += 1;
        ptr += fmt.ud64(offset).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn listenError(listen_error: anytype, sock_fd: u64, backlog: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..listen_s.len].* = listen_s.*;
        var ptr: [*]u8 = buf[listen_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(listen_error));
        ptr += @errorName(listen_error).len;
        ptr[0..10].* = ", sock_fd=".*;
        ptr += 10;
        ptr += fmt.ud64(sock_fd).formatWriteBuf(ptr);
        ptr[0..10].* = ", backlog=".*;
        ptr += 10;
        ptr += fmt.ud64(backlog).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    pub fn executeErrorBrief(exec_error: anytype, pathname: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..execve_s.len].* = execve_s.*;
        ptr += execve_s.len;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(exec_error));
        ptr += @errorName(exec_error).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    pub fn executeError(exec_error: anytype, pathname: [:0]const u8, args: []const [*:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..execve_s.len].* = execve_s.*;
        ptr += execve_s.len;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(exec_error));
        ptr += @errorName(exec_error).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        if (args.len != 0) {
            ptr[0] = ' ';
            ptr += 1;
            ptr += writeArgs(ptr, pathname, args);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn pathMustNotBeFault(pathname: [:0]const u8, kind: Kind) void {
        @setRuntimeSafety(builtin.is_safe);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..13].* = must_not_be_file_s.*;
        ptr += 13;
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn pathMustBeFault(pathname: [:0]const u8, kind: Kind, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..9].* = must_be_file_s.*;
        ptr += 9;
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        ptr[0..5].* = is_file_s.*;
        ptr += 5;
        descr_s = describeKind(file_mode.kind);
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn fdNotKindFault(fd: u64, kind: Kind) void {
        @setRuntimeSafety(builtin.is_safe);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..13].* = must_not_be_file_s.*;
        ptr += 13;
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn fdKindModeFault(fd: u64, kind: Kind, file_mode: Mode) void {
        @setRuntimeSafety(builtin.is_safe);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr);
        ptr[0..9].* = must_be_file_s.*;
        ptr += 9;
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        descr_s = describeKind(file_mode.kind);
        ptr[0..5].* = is_file_s.*;
        ptr += 5;
        @memcpy(ptr, descr_s);
        ptr += descr_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
    }
    fn atDirFdMustBeFault(dir_fd: u64, name: [:0]const u8, kind: Kind, file_mode: Mode) void {
        _ = file_mode;
        _ = kind;
        _ = name;
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr += fmt.ud64(dir_fd).formatWriteBuf(ptr);
        //debug.logAlwaysAIO(&buf, &[_][]const u8{ file_2_s, "dir_fd=", dir_fd_s, ", ", name, must_be_s, describeKind(kind), "; is ", describeKind(file_mode.kind), "\n" });
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn atDirFdMustNotBeFault(dir_fd: u64, name: [:0]const u8, kind: Kind) void {
        _ = kind;
        _ = name;
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr += fmt.ud64(dir_fd).formatWriteBuf(ptr);
        //debug.logAlwaysAIO(&buf, &[_][]const u8{ file_2_s, "dir_fd=", dir_fd_s, ", ", name, must_not_be_s, describeKind(kind), "\n" });
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
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
    fn describeMode(file_mode: Mode) [10]u8 {
        var ret: [10]u8 = [1]u8{'-'} ** 10;
        ret[0] = switch (file_mode.kind) {
            .unknown => '-',
            .directory => 'd',
            .regular => 'f',
            .character_special => 'c',
            .block_special => 'b',
            .socket => 'S',
            .named_pipe => 'p',
            .symbolic_link => 'l',
        };
        describePerms(ret[1..], file_mode.owner);
        describePerms(ret[4..], file_mode.group);
        describePerms(ret[7..], file_mode.other);
        return ret;
    }
    fn describeKind(kind: Kind) []const u8 {
        switch (kind) {
            .unknown => return unknown_file_s,
            .regular => return regular_file_s,
            .directory => return directory_file_s,
            .character_special => return character_special_file_s,
            .block_special => return block_special_file_s,
            .named_pipe => return named_pipe_file_s,
            .socket => return socket_file_s,
            .symbolic_link => return symbolic_link_file_s,
        }
    }
    fn writeUpdateOffset(buf: [*]u8, fd: fmt.Type.Udsize, off: fmt.Type.Udsize) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf;
        var len: u64 = 4 -% fd.formatLength();
        @memset(ptr[0..len], ' ');
        ptr += len;
        ptr += fd.formatWriteBuf(ptr);
        ptr[0] = ':';
        ptr += 1;
        len = copy_s.len -% 5;
        @memset(ptr[0..len], ' ');
        ptr += len;
        ptr[0..7].* = "offset=".*;
        ptr += 7;
        ptr += off.formatWriteBuf(ptr);
        ptr[0] = '\n';
        return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% 1;
    }
    fn writePollFds(buf: [*]u8, pollfds: []PollFd) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = buf;
        var tmp: [24]u8 = undefined;
        var fd_fmt: fmt.Type.Ud64 = undefined;
        for (pollfds) |*pollfd| {
            fd_fmt = .{ .value = pollfd.fd };
            const len: usize = fmt.ud64(pollfd.fd).formatWriteBuf(&tmp);
            ptr[0..4].* = "    ".*;
            ptr += (4 -% len);
            @memcpy(ptr, tmp[0..len]);
            ptr += len;
            ptr[0] = ':';
            ptr += 1;
            @memset(ptr[0..11], ' ');
            ptr += 11;
            ptr += writeEvents(ptr, pollfd, "expect=", 4);
            ptr += writeEvents(ptr, pollfd, " actual=", 6);
            ptr[0] = '\n';
            ptr += 1;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    fn writeEvents(buf: [*]u8, pollfd: *PollFd, about_s: []const u8, off: u64) u64 {
        @setRuntimeSafety(builtin.is_safe);
        const events: Events = @as(*Events, @ptrFromInt(@intFromPtr(pollfd) + off)).*;
        if (@as(u16, @bitCast(events)) == 0) {
            return 0;
        }
        @memcpy(buf, about_s);
        var ptr: [*]u8 = buf + about_s.len;
        inline for (@typeInfo(Events).Struct.fields) |field| {
            if (field.type != bool) {
                continue;
            }
            if (@field(events, field.name)) {
                @memcpy(ptr, field.name);
                ptr += field.name.len;
                ptr[0] = ',';
                ptr += 1;
            }
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn writeArgs(buf: [*]u8, pathname: [:0]const u8, args: []const [*:0]const u8) usize {
        var ptr: [*]u8 = buf;
        var idx: usize = 0;
        if (mach.testEqualMany8(
            pathname,
            mach.manyToSlice80(@constCast(args[0])),
        )) {
            idx +%= 1;
        }
        while (idx != args.len) : (idx +%= 1) {
            var arg_len: u64 = 0;
            while (args[idx][arg_len] != 0) arg_len +%= 1;
            if (arg_len == 0) {
                ptr[0] = '\'';
                ptr += 1;
                ptr[0] = '\'';
                ptr += 1;
            }
            if ((@intFromPtr(ptr) -% @intFromPtr(buf)) +% arg_len >= 32768 -% 37) {
                break;
            }
            @memcpy(ptr, args[idx][0..arg_len]);
            ptr += arg_len;
            ptr[0] = ' ';
            ptr += 1;
        }
        if (idx != args.len) {
            ptr[0..9].* = " ... and ".*;
            ptr += 9;
            ptr += fmt.ud64(args.len -% idx).formatWriteBuf(ptr);
            ptr[0..16].* = " more args ... \n".*;
            ptr += 16;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn sampleAllReports() void {
        const about_s: fmt.AboutSrc = comptime fmt.about("about");
        const error_name: [:0]const u8 = "ErrorName";
        const pathname1: [:0]const u8 = "/file/test/path/name1";
        const pathname2: [:0]const u8 = "/file/test/path/name2";
        const fd1: u64 = 3;
        const fd2: u64 = 4;
        const dir_fd1: u64 = 5;
        const dir_fd2: u64 = 6;
        var offset: u64 = 4096;
        const name1: [:0]const u8 = "file1";
        const name2: [:0]const u8 = "file2";
        const expect: Events = .{ .input = true };
        const actual: Events = .{ .hangup = true };
        const pollfd: PollFd = .{ .fd = 1, .expect = expect, .actual = actual };
        var pollfds: [3]PollFd = .{pollfd} ** 3;
        var timeout: u64 = 86400;
        var off1: usize = 256;
        var off2: usize = 256;
        aboutFdNotice(about_s, fd1);
        aboutFdModeNotice(about_s, fd1, mode.regular);
        aboutFdLenNotice(about_s, fd1, 4096);
        aboutFdMaxLenLenNotice(about_s, fd1, 8192, 4096);
        aboutPathnameNotice(about_s, pathname1);
        aboutPathnameModeNotice(about_s, pathname1, mode.regular);
        aboutDirFdNameModeNotice(about_s, fd1, name1, mode.regular);
        aboutDirFdNameFdNotice(about_s, dir_fd1, name1, fd1);
        aboutPathnameFdNotice(about_s, pathname1, fd1);
        aboutPathnameFdModeNotice(about_s, pathname1, fd1, mode.regular);
        aboutPathnameModeDeviceNotice(about_s, pathname1, mode.regular, .{ .major = 255, .minor = 1 });
        pollNotice(&pollfds, timeout);
        copyNotice(fd1, &off1, fd2, &off2, 512, 256);
        listenNotice(fd1, 100);
        aboutFdFdNotice(about_s, "fd1=", "fd2=", fd1, fd2);
        aboutPathnameOffsetError(about_s, "TruncateError", pathname1, 256);
        aboutFdOffsetError(about_s, "TruncateError", fd1, offset);
        pathMustBeFault(pathname1, .regular, mode.directory);
        pathMustNotBeFault(pathname1, .directory);
        fdKindModeFault(fd1, .regular, mode.directory);
        fdNotKindFault(fd1, .directory);
        aboutDirFdNameNotice(about_s, dir_fd1, name1);
        aboutDirFdNameModeDeviceNotice(about_s, fd1, name1, mode.regular, .{ .major = 255, .minor = 1 });
        aboutDirFdNameDirFdNameNotice(about_s, " => ", ", ", " -> ", fd1, name1, dir_fd1, name2);
        aboutPathnamePathnameNotice(about_s, " -> ", pathname1, pathname2);
        aboutPathnameDirFdNameNotice(about_s, " -> ", pathname1, dir_fd1, name1);
        aboutDirFdNameError(about_s, error_name, dir_fd1, name1);
        aboutFdError(about_s, error_name, fd1);
        aboutFdFdError(about_s, error_name, "fd1=", "fd2=", fd1, fd2);
        aboutPathnamePathnameError(about_s, error_name, "->", pathname1, pathname2);
        aboutPathnameDirFdNameError(about_s, error_name, "->", pathname1, dir_fd2, name1);
        aboutDirFdNameDirFdNameError(about_s, error_name, "src_dir_fd=", ", ", "dest_dir_fd=", dir_fd1, name1, dir_fd2, name2);
        socketError(error.SocketError, .ipv4, .tcp);
        sendError(error.SendError, fd1, fd2, &offset, 256);
        copyError(error.CopyError, fd1, &offset, fd2, &offset, 512);
        seekError(error.SeekError, fd1, offset, .set);
        listenError(error.ListenError, fd1, 100);
        executeError(error.ExecError, name1, &.{});
    }
};
// * Add `executeNoticeBrief`
