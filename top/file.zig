const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const bits = @import("./bits.zig");
const time = @import("./time.zig");
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const cwd: comptime_int = @as(usize, @bitCast(@as(isize, -100)));
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
pub const Flags = struct {
    pub const Socket = packed struct(usize) {
        conn: enum(u2) {
            tcp = 1,
            udp = 2,
            raw = 3,
        },
        zb2: u9 = 0,
        non_block: bool = false,
        zb12: u7 = 0,
        close_on_exec: bool = false,
        zb20: u44 = 0,
    };
    const MemFd = packed struct(usize) {
        close_on_exec: bool = false,
        allow_sealing: bool = false,
        huge_tlb: bool = false,
        zb3: u61 = 0,
        pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
            var ptr: [*]u8 = buf;
            if (format.CLOEXEC) {
                ptr += fmt.strcpyEqu(ptr, "CLOEXEC");
            }
            if (format.ALLOW_SEALING) {
                if (ptr != buf) {
                    ptr[0] = '|';
                    ptr += 1;
                }
                ptr += fmt.strcpyEqu(ptr, "ALLOW_SEALING");
            }
            if (format.HUGETLB) {
                if (ptr != buf) {
                    ptr[0] = '|';
                    ptr += 1;
                }
                ptr += fmt.strcpyEqu(ptr, "HUGETLB");
            }
        }
        pub fn formatLength(format: @This()) usize {
            var len: usize = 0;
            if (format.CLOEXEC) {
                len += 7;
            }
            if (format.ALLOW_SEALING) {
                len += 13;
            }
            if (format.HUGETLB) {
                len += 7;
            }
        }
    };
    pub const Duplicate = packed struct(usize) {
        zb0: u19 = 0,
        close_on_exec: bool = false,
        zb20: u44 = 0,
    };
    pub const Pipe = packed struct(usize) {
        zb0: u11 = 0,
        non_block: bool = false,
        zb12: u2 = 0,
        direct: bool = false,
        zb15: u4 = 0,
        close_on_exec: bool = false,
        zb20: u44 = 0,
    };
    pub const Create = packed struct(usize) {
        write_only: bool = false,
        read_write: bool = false,
        zb2: u4 = 0,
        create: bool = true,
        exclusive: bool = false,
        no_ctty: bool = true,
        truncate: bool = true,
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
    pub const Open = packed struct(usize) {
        write_only: bool = false,
        read_write: bool = false,
        zb2: u4 = 0,
        create: bool = false,
        exclusive: bool = false,
        no_ctty: bool = true,
        truncate: bool = false,
        append: bool = false,
        non_block: bool = true,
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
pub const Whence = enum(usize) { // set, cur, end
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
    pub const Domain = enum(u16) {
        unix = AF.UNIX,
        ipv4 = AF.INET,
        ipv6 = AF.INET6,
        netlink = AF.NETLINK,
        const AF = sys.AF;
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
    zb240: u16,
    uid: u32,
    gid: u32,
    zbA: u32 = 0,
    rdev: u64,
    size: u64,
    blksize: u64,
    blocks: u64,
    atime: time.TimeSpec,
    mtime: time.TimeSpec,
    ctime: time.TimeSpec,
    zbB: u64 = 0,
    zbC: u64 = 0,
    zbD: u64 = 0,
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
    pub inline fn formatWrite(format: *const Status, array: anytype) void {
        return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
    }
    pub inline fn formatWriteBuf(format: *const Status, buf: [*]u8) usize {
        return fmt.strlen(about.writeStatus(buf, format), buf);
    }
    pub fn formatLength(format: *const Status) usize {
        return 6 +% fmt.length(u64, format.ino, 10) +%
            6 +% fmt.length(u64, format.dev >> 8, 10) +%
            19 +% fmt.length(u64, format.dev & 0xff, 10) +%
            fmt.Bytes.formatLength(.{ .value = format.size });
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
pub const DirectoryEntry = packed struct {
    inode: usize,
    offset: usize,
    reclen: u16,
    zb: u4,
    kind: Kind,
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
pub const AccessSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.access.errors.all },
    return_type: type = bool,
    logging: debug.Logging.SuccessError = .{},
};
pub const OpenSpec = struct {
    return_type: type = usize,
    errors: sys.ErrorPolicy = .{ .throw = spec.open.errors.all },
    logging: debug.Logging.AttemptAcquireError = .{},
};
pub const ReadSpec = struct {
    child: type = u8,
    return_type: type = usize,
    errors: sys.ErrorPolicy = .{ .throw = spec.read.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const Read2Spec = struct {
    return_type: type = usize,
    errors: sys.ErrorPolicy = .{ .throw = spec.read.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const WriteSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = spec.write.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const Write2Spec = struct {
    child: type = []const u8,
    return_type: type = usize,
    errors: sys.ErrorPolicy = .{ .throw = spec.read.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const SyncSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.sync.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const SeekSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.seek.errors.all },
    return_type: type = usize,
    logging: debug.Logging.SuccessError = .{},
};
pub const PollSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.poll.errors.all },
    return_type: type = void,
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const StatusSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.stat.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub const StatusExtendedSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.statx.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub const MakePipeSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = spec.pipe.errors.all },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = packed struct(u3) {
        close_on_exec: bool = false,
        direct: bool = false,
        non_block: bool = false,
    };
};
pub const SocketSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.socket.errors.all },
    logging: debug.Logging.AcquireError = .{},
    return_type: type = u64,
    const Specification = @This();
};
pub const BindSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.bind.errors.all },
    logging: debug.Logging.AcquireError = .{},
};
pub const ListenSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.listen.errors.all },
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const AcceptSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.accept.errors.all },
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const ConnectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.connect.errors.all },
    return_type: type = void,
    logging: debug.Logging.AttemptSuccessError = .{},
};
pub const GetSockNameSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.getsockname.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const ReceiveFromSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.recv.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const GetPeerNameSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.getpeername.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const SendToSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.send.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const SocketOptionSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.sockopt.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const ShutdownSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.shutdown.errors.all },
    logging: debug.Logging.SuccessError = .{},
};
pub const MakeDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mkdir.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const GetDirectoryEntriesSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.getdents.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const MakePathSpec = struct {
    errors: MakePathErrors = .{},
    logging: MakePathLogging = .{},
    const Specification = @This();
    const MakePathErrors = struct {
        stat: sys.ErrorPolicy = .{ .throw = spec.mkdir.errors.all },
        mkdir: sys.ErrorPolicy = .{ .throw = spec.stat.errors.all },
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
    errors: sys.ErrorPolicy = .{ .throw = spec.open.errors.all },
    return_type: type = u64,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
};
pub const PathSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.open.errors.all },
    return_type: type = u64,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
};
pub const MakeNodeSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mkdir.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const ExecuteSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.execve.errors.all },
    logging: debug.Logging.AttemptError = .{},
    return_type: type = void,
    args_type: type = []const [*:0]u8,
    vars_type: type = []const [*:0]u8,
};
pub const GetWorkingDirectorySpec = struct {
    options: struct { init_state: bool = builtin.is_debug } = .{},
    errors: sys.ErrorPolicy = .{ .throw = spec.getcwd.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const ChangeWorkingirectorySpec = struct {
    options: struct { update_state: bool = builtin.is_debug } = .{},
    errors: sys.ErrorPolicy = .{ .throw = spec.chdir.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const ReadLinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.readlink.errors.all },
    return_type: type = [:0]const u8,
    logging: debug.Logging.SuccessError = .{},
};
pub const CopySpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.copy_file_range.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const SendSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.sendfile.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const LinkSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = spec.link.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Options = struct {
        follow: bool = false,
        empty_path: bool = false,
    };
};
pub const CloseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.close.errors.all },
    return_type: type = void,
    logging: debug.Logging.ReleaseError = .{},
};
pub const UnlinkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.unlink.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const RemoveDirSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.rmdir.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const TruncateSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.truncate.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const DuplicateSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.dup.errors.all },
    return_type: type = u64,
    logging: debug.Logging.SuccessError = .{},
};
pub const Duplicate3Spec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.dup3.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub fn execPath(comptime exec_spec: ExecuteSpec, pathname: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    const logging: debug.Logging.AttemptError = comptime exec_spec.logging.override();
    if (logging.Attempt) {
        about.executeNotice(pathname, args);
    }
    if (meta.wrap(sys.call(.execve, exec_spec.errors, exec_spec.return_type, .{
        @intFromPtr(pathname.ptr), @intFromPtr(args.ptr), @intFromPtr(vars.ptr),
    }))) {
        proc.exitFault("reached unreachable", 2);
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            about.executeErrorBrief(execve_error, pathname);
        } else if (logging.Error) {
            about.executeError(execve_error, pathname, args);
        }
        return execve_error;
    }
}
pub fn exec(comptime exec_spec: ExecuteSpec, fd: usize, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    return execAt(exec_spec, .{ .empty_path = true }, fd, "", args, vars);
}
pub fn execAt(comptime exec_spec: ExecuteSpec, flags: sys.flags.At, dir_fd: usize, name: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) sys.ErrorUnion(
    exec_spec.errors,
    exec_spec.return_type,
) {
    const logging: debug.Logging.AttemptError = comptime exec_spec.logging.override();
    if (logging.Attempt) {
        about.executeNotice(name, args);
    }
    if (meta.wrap(sys.call(.execveat, exec_spec.errors, exec_spec.return_type, .{
        dir_fd, @intFromPtr(name.ptr), @intFromPtr(args.ptr), @intFromPtr(vars.ptr), @bitCast(flags),
    }))) {
        proc.exitFault("reached unreachable", 2);
    } else |execve_error| {
        if (logging.Error and logging.Attempt) {
            about.executeErrorBrief(execve_error, name);
        } else if (logging.Error) {
            about.executeError(execve_error, name, args);
        }
        return execve_error;
    }
}
pub fn read(comptime read_spec: ReadSpec, fd: usize, read_buf: []read_spec.child) sys.ErrorUnion(
    read_spec.errors,
    read_spec.return_type,
) {
    @setRuntimeSafety(builtin.is_safe);
    const logging: debug.Logging.SuccessError = comptime read_spec.logging.override();
    if (meta.wrap(sys.call(.read, read_spec.errors, usize, .{ fd, @intFromPtr(read_buf.ptr), read_buf.len *% @sizeOf(read_spec.child) }))) |ret| {
        if (logging.Success) {
            about.aboutFdMaxLenLenNotice(about.read_s, fd, read_buf.len *% @sizeOf(read_spec.child), ret);
        }
        if (read_spec.return_type != void) {
            return @truncate(@divExact(ret, @sizeOf(read_spec.child)));
        }
    } else |read_error| {
        if (logging.Error) {
            about.aboutFdError(about.read_s, @errorName(read_error), fd);
        }
        return read_error;
    }
}
pub inline fn readOne(comptime read_spec: ReadSpec, fd: usize, read_buf: *read_spec.child) sys.ErrorUnion(
    read_spec.errors,
    read_spec.return_type,
) {
    return read(read_spec, fd, @as([*]read_spec.child, @ptrCast(read_buf))[0..1]);
}
pub fn write(comptime write_spec: WriteSpec, fd: usize, write_buf: []const write_spec.child) sys.ErrorUnion(
    write_spec.errors,
    write_spec.return_type,
) {
    @setRuntimeSafety(builtin.is_safe);
    const logging: debug.Logging.SuccessError = comptime write_spec.logging.override();
    if (meta.wrap(sys.call(.write, write_spec.errors, u64, .{ fd, @intFromPtr(write_buf.ptr), write_buf.len *% @sizeOf(write_spec.child) }))) |ret| {
        if (logging.Success) {
            about.aboutFdLenNotice(about.write_s, fd, ret);
        }
        if (write_spec.return_type != void) {
            return @truncate(@divExact(ret, @sizeOf(write_spec.child)));
        }
    } else |write_error| {
        if (logging.Error) {
            about.aboutFdError(about.write_s, @errorName(write_error), fd);
        }
        return write_error;
    }
}
pub inline fn writeOne(comptime write_spec: WriteSpec, fd: usize, write_val: write_spec.child) sys.ErrorUnion(
    write_spec.errors,
    write_spec.return_type,
) {
    return write(write_spec, fd, @as([*]const write_spec.child, @ptrCast(&write_val))[0..1]);
}
pub fn read2(comptime read_spec: Read2Spec, flags: sys.flags.ReadWrite, fd: usize, read_buf: []const mem.Vector, offset: usize) sys.ErrorUnion(
    read_spec.errors,
    read_spec.return_type,
) {
    @setRuntimeSafety(builtin.is_safe);
    const logging: debug.Logging.SuccessError = comptime read_spec.logging.override();
    if (meta.wrap(sys.call(.preadv2, read_spec.errors, usize, .{
        fd, @intFromPtr(read_buf.ptr), read_buf.len, offset, @bitCast(flags), 0,
    }))) |ret| {
        if (logging.Success) {
            about.aboutFdOffsetReadWriteMaxLenLenNotice(about.read_s, fd, offset, flags, about.totalLength(read_buf), ret);
        }
        if (read_spec.return_type != void) {
            return @truncate(ret);
        }
    } else |read_error| {
        if (logging.Error) {
            about.aboutFdOffsetReadWriteError(about.read_s, @errorName(read_error), fd, offset, flags);
        }
        return read_error;
    }
}
pub fn write2(comptime write_spec: WriteSpec, flags: sys.flags.ReadWrite, fd: usize, write_buf: []const mem.Vector, offset: usize) sys.ErrorUnion(
    write_spec.errors,
    write_spec.return_type,
) {
    @setRuntimeSafety(builtin.is_safe);
    if (write_spec.child != u8) {
        @compileError("Not yet implemented");
    }
    const logging: debug.Logging.SuccessError = comptime write_spec.logging.override();
    if (meta.wrap(sys.call(.pwritev2, write_spec.errors, usize, .{
        fd, @intFromPtr(write_buf.ptr), write_buf.len, offset, @bitCast(flags), 0,
    }))) |ret| {
        if (logging.Success) {
            about.aboutFdOffsetReadWriteMaxLenLenNotice(about.write_s, fd, offset, flags, about.totalLength(write_buf), ret);
        }
        if (write_spec.return_type != void) {
            return @truncate(@divExact(ret, @sizeOf(write_spec.child)));
        }
    } else |write_error| {
        if (logging.Error) {
            about.aboutFdOffsetReadWriteError(about.write_s, @errorName(write_error), fd, offset, flags);
        }
        return write_error;
    }
}
pub fn open(comptime open_spec: OpenSpec, flags: sys.flags.Open, pathname: [:0]const u8) sys.ErrorUnion(
    open_spec.errors,
    open_spec.return_type,
) {
    @setRuntimeSafety(builtin.is_safe);
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.AttemptAcquireError = comptime open_spec.logging.override();
    if (logging.Attempt) {
        about.aboutPathnameNotice(about.open_s, pathname);
    }
    if (meta.wrap(sys.call(.open, open_spec.errors, open_spec.return_type, .{ pathname_buf_addr, @bitCast(flags), 0 }))) |fd| {
        if (logging.Acquire) {
            about.aboutPathnameFdNotice(about.open_s, pathname, fd);
        }
        return @intCast(fd);
    } else |open_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.open_s, @errorName(open_error), pathname);
        }
        return open_error;
    }
}
pub fn openAt(comptime open_spec: OpenSpec, flags: Flags.Open, dir_fd: usize, name: [:0]const u8) sys.ErrorUnion(
    open_spec.errors,
    open_spec.return_type,
) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.AttemptAcquireError = comptime open_spec.logging.override();
    if (meta.wrap(sys.call(.openat, open_spec.errors, open_spec.return_type, .{ dir_fd, name_buf_addr, @bitCast(flags), 0 }))) |fd| {
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
pub fn socket(comptime socket_spec: SocketSpec, domain: Socket.Domain, flags: Flags.Socket, protocol: Socket.Protocol) sys.ErrorUnion(
    socket_spec.errors,
    socket_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime socket_spec.logging.override();
    if (meta.wrap(sys.call(.socket, socket_spec.errors, socket_spec.return_type, .{
        @intFromEnum(domain), @bitCast(flags), @intFromEnum(protocol),
    }))) |fd| {
        if (logging.Acquire) {
            about.socketNotice(fd, domain, flags);
        }
        return fd;
    } else |socket_error| {
        if (logging.Error) {
            about.socketError(socket_error, domain, flags);
        }
        return socket_error;
    }
}
pub fn socketPair(comptime socket_spec: SocketSpec, domain: Socket.Domain, flags: Flags.Socket, fds: *[2]u32) sys.ErrorUnion(
    socket_spec.errors,
    socket_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime socket_spec.logging.override();
    if (meta.wrap(sys.call(.socketpair, socket_spec.errors, socket_spec.return_type, .{
        @intFromEnum(domain), @bitCast(flags), 0, @intFromPtr(fds),
    }))) |fd| {
        if (logging.Acquire) {
            about.socketsNotice(fd, domain, flags);
        }
        return fd;
    } else |socket_error| {
        if (logging.Error) {
            about.socketsError(socket_error, domain, flags);
        }
        return socket_error;
    }
}
pub fn listen(comptime listen_spec: ListenSpec, sock_fd: usize, backlog: u64) sys.ErrorUnion(listen_spec.errors, void) {
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
pub fn bind(comptime bind_spec: BindSpec, sock_fd: usize, addr: *Socket.Address, addrlen: u32) sys.ErrorUnion(bind_spec.errors, void) {
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
pub fn accept(comptime accept_spec: AcceptSpec, fd: usize, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
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
pub fn connect(comptime conn_spec: ConnectSpec, fd: usize, addr: *const Socket.Address, addrlen: u64) sys.ErrorUnion(
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
pub fn sendTo(comptime send_spec: SendToSpec, fd: usize, buf: []u8, flags: u32, addr: *Socket.Address, addrlen: u32) sys.ErrorUnion(
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
pub fn receiveFrom(comptime recv_spec: ReceiveFromSpec, fd: usize, buf: []u8, flags: u32, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
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
fn getSocketName(comptime get_spec: GetSockNameSpec, fd: usize, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
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
fn getPeerName(comptime get_spec: GetPeerNameSpec, fd: usize, addr: *Socket.Address, addrlen: *u32) sys.ErrorUnion(
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
fn getSocketOption(comptime get_spec: SocketOptionSpec, fd: usize, level: u64, optname: u32, optval: *u8, optlen: *u32) sys.ErrorUnion(
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
fn setSocketOption(comptime set_spec: SocketOptionSpec, fd: usize, level: u64, optname: u32, optval: *u8, optlen: u32) sys.ErrorUnion(
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
pub fn shutdown(comptime shutdown_spec: ShutdownSpec, fd: usize, how: Shutdown) sys.ErrorUnion(
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
pub fn canonicalisePathVolatile(pathname: [:0]const u8, buf: []u8) [:0]const u8 {
    var tmp1: [4096]u8 = undefined;
    var tmp2: [4096]u8 = undefined;
    const save: [:0]const u8 = getCwd(.{ .errors = .{} }, &tmp1);
    defer changeCwd(.{ .errors = .{} }, save);
    fmt.strcpyEqu(&tmp2, dirname(pathname))[0] = 0;
    changeCwd(.{ .errors = .{} }, mem.terminate(&tmp2, 0));
    var ret: [:0]u8 = getCwd(.{ .errors = .{} }, buf);
    var ptr: [*]u8 = ret.ptr + ret.len;
    ptr[0] = '/';
    ptr = fmt.strcpyEqu(ptr + 1, basename(pathname));
    ptr[0] = 0;
    return buf[0 .. @intFromPtr(ptr) -% @intFromPtr(buf.ptr) :0];
}
pub fn path(comptime path_spec: PathSpec, flags: Flags.Open, pathname: [:0]const u8) sys.ErrorUnion(
    path_spec.errors,
    path_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.AcquireError = comptime path_spec.logging.override();
    if (meta.wrap(sys.call(.open, path_spec.errors, path_spec.return_type, .{ pathname_buf_addr, @bitCast(flags), 0 }))) |fd| {
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
pub fn pathAt(comptime path_spec: PathSpec, flags: Flags.Open, dir_fd: usize, name: [:0]const u8) sys.ErrorUnion(
    path_spec.errors,
    path_spec.return_type,
) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.AcquireError = comptime path_spec.logging.override();
    if (meta.wrap(sys.call(.openat, path_spec.errors, path_spec.return_type, .{ dir_fd, name_buf_addr, @bitCast(flags), 0 }))) |fd| {
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
    @memcpy(buf, pathname);
    buf[pathname.len] = 0;
    return buf[0..pathname.len :0];
}
fn makePathInternal(comptime mkpath_spec: MakePathSpec, pathname: [:0]u8, file_mode: Mode) sys.ErrorUnion(.{
    .throw = mkpath_spec.errors.mkdir.throw ++ mkpath_spec.errors.stat.throw,
    .abort = mkpath_spec.errors.mkdir.abort ++ mkpath_spec.errors.stat.abort,
}, void) {
    const stat_spec: StatusSpec = comptime mkpath_spec.stat();
    const make_dir_spec: MakeDirSpec = mkpath_spec.mkdir();
    var st: Status = comptime builtin.zero(Status);
    pathStatus(stat_spec, pathname, &st) catch |err| blk: {
        if (err == error.NoSuchFileOrDirectory) {
            const idx: u64 = indexOfDirnameFinish(pathname);
            debug.assertEqual(u8, pathname[idx], '/');
            if (idx != 0) {
                pathname[idx] = 0;
                try makePathInternal(mkpath_spec, pathname[0..idx :0], file_mode);
                pathname[idx] = '/';
            }
        }
        try makeDir(make_dir_spec, pathname, file_mode);
        break :blk try pathStatus(stat_spec, pathname, &st);
    };
    if (st.mode.kind != .directory) {
        return error.NotADirectory;
    }
}
pub fn makePath(comptime mkpath_spec: MakePathSpec, pathname: []const u8, file_mode: Mode) sys.ErrorUnion(.{
    .throw = mkpath_spec.errors.mkdir.throw ++ mkpath_spec.errors.stat.throw,
    .abort = mkpath_spec.errors.mkdir.abort ++ mkpath_spec.errors.stat.abort,
}, void) {
    var buf: [4096:0]u8 = undefined;
    const name: [:0]u8 = writePath(&buf, pathname);
    return makePathInternal(mkpath_spec, name, file_mode);
}
pub fn create(comptime creat_spec: CreateSpec, flags: Flags.Create, pathname: [:0]const u8, file_mode: Mode) sys.ErrorUnion(
    creat_spec.errors,
    creat_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime creat_spec.logging.override();
    if (meta.wrap(sys.call(.open, creat_spec.errors, creat_spec.return_type, .{ @intFromPtr(pathname.ptr), @bitCast(flags), @as(u16, @bitCast(file_mode)) & 0xfff }))) |fd| {
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
pub fn createAt(comptime creat_spec: CreateSpec, flags: Flags.Create, dir_fd: usize, name: [:0]const u8, file_mode: Mode) sys.ErrorUnion(
    creat_spec.errors,
    creat_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime creat_spec.logging.override();
    if (meta.wrap(sys.call(.openat, creat_spec.errors, creat_spec.return_type, .{ dir_fd, @intFromPtr(name.ptr), @bitCast(flags), @as(u16, @bitCast(file_mode)) & 0xfff }))) |fd| {
        if (logging.Acquire) {
            about.aboutDirFdNameFdModeNotice(about.create_s, dir_fd, name, fd, file_mode);
        }
        return fd;
    } else |open_error| {
        if (logging.Error) {
            about.aboutDirFdNameModeError(about.create_s, @errorName(open_error), dir_fd, name, file_mode);
        }
        return open_error;
    }
}
pub fn close(comptime close_spec: CloseSpec, fd: usize) sys.ErrorUnion(
    close_spec.errors,
    close_spec.return_type,
) {
    const logging: debug.Logging.ReleaseError = comptime close_spec.logging.override();
    if (meta.wrap(sys.call(.close, close_spec.errors, close_spec.return_type, .{fd}))) {
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
pub fn makeDir(comptime mkdir_spec: MakeDirSpec, pathname: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(
    mkdir_spec.errors,
    mkdir_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime mkdir_spec.logging.override();
    if (meta.wrap(sys.call(.mkdir, mkdir_spec.errors, mkdir_spec.return_type, .{ @intFromPtr(pathname.ptr), @as(u16, @bitCast(file_mode)) }))) {
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
pub fn makeDirAt(comptime mkdir_spec: MakeDirSpec, dir_fd: usize, name: [:0]const u8, comptime file_mode: Mode) sys.ErrorUnion(
    mkdir_spec.errors,
    mkdir_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime mkdir_spec.logging.override();
    if (meta.wrap(sys.call(.mkdirat, mkdir_spec.errors, mkdir_spec.return_type, .{ dir_fd, @intFromPtr(name.ptr), @as(u16, @bitCast(file_mode)) }))) {
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
pub fn getDirectoryEntries(comptime getdents_spec: GetDirectoryEntriesSpec, dir_fd: usize, stream_buf: []u8) sys.ErrorUnion(
    getdents_spec.errors,
    getdents_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime getdents_spec.logging.override();
    if (meta.wrap(sys.call(.getdents64, getdents_spec.errors, getdents_spec.return_type, .{ dir_fd, @intFromPtr(stream_buf.ptr), stream_buf.len }))) |ret| {
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
pub fn makeNode(comptime mknod_spec: MakeNodeSpec, pathname: [:0]const u8, file_mode: Mode, dev: Device) sys.ErrorUnion(
    mknod_spec.errors,
    mknod_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime mknod_spec.logging.override();
    if (meta.wrap(sys.call(.mknod, mknod_spec.errors, mknod_spec.return_type, .{
        pathname_buf_addr, @as(u16, @bitCast(file_mode)), @bitCast(dev),
    }))) {
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
pub fn makeNodeAt(comptime mknod_spec: MakeNodeSpec, dir_fd: usize, name: [:0]const u8, file_mode: Mode, dev: Device) sys.ErrorUnion(
    mknod_spec.errors,
    mknod_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime mknod_spec.logging.override();
    if (meta.wrap(sys.call(.mknodat, mknod_spec.errors, mknod_spec.return_type, .{
        dir_fd, @intFromPtr(name.ptr), @as(u16, @bitCast(file_mode)), @bitCast(dev),
    }))) {
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
pub fn changeCwd(comptime chdir_spec: ChangeWorkingirectorySpec, pathname: [:0]const u8) sys.ErrorUnion(chdir_spec.errors, void) {
    const buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime chdir_spec.logging.override();
    if (meta.wrap(sys.call(.chdir, chdir_spec.errors, chdir_spec.return_type, .{buf_addr}))) {
        if (logging.Success) {
            about.aboutPathnameNotice(about.chdir_s, pathname);
        }
    } else |chdir_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.chdir_s, @errorName(chdir_error), pathname);
        }
        return chdir_error;
    }
}
pub fn getCwd(comptime getcwd_spec: GetWorkingDirectorySpec, buf: []u8) sys.ErrorUnion(getcwd_spec.errors, [:0]u8) {
    const logging: debug.Logging.SuccessError = comptime getcwd_spec.logging.override();
    if (meta.wrap(sys.call(.getcwd, getcwd_spec.errors, getcwd_spec.return_type, .{ @intFromPtr(buf.ptr), buf.len }))) |len| {
        buf[len] = 0;
        const ret: [:0]u8 = buf[0 .. len -% 1 :0];
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
pub fn readLink(comptime readlink_spec: ReadLinkSpec, pathname: [:0]const u8, buf: []u8) sys.ErrorUnion(
    readlink_spec.errors,
    readlink_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const buf_addr: u64 = @intFromPtr(buf.ptr);
    const logging: debug.Logging.SuccessError = comptime readlink_spec.logging.override();
    if (meta.wrap(sys.call(.readlink, readlink_spec.errors, usize, .{ pathname_buf_addr, buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        const ret: [:0]u8 = buf[0..len :0];
        if (logging.Success) {
            about.aboutPathnameNotice(about.readlink_s, ret);
        }
        return ret;
    } else |readlink_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.readlink_s, @errorName(readlink_error), pathname);
        }
        return readlink_error;
    }
}
pub fn readLinkAt(comptime readlink_spec: ReadLinkSpec, dir_fd: usize, name: [:0]const u8, buf: []u8) sys.ErrorUnion(
    readlink_spec.errors,
    readlink_spec.return_type,
) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const buf_addr: u64 = @intFromPtr(buf.ptr);
    const logging: debug.Logging.SuccessError = comptime readlink_spec.logging.override();
    if (meta.wrap(sys.call(.readlinkat, readlink_spec.errors, usize, .{ dir_fd, name_buf_addr, buf_addr, buf.len }))) |len| {
        buf[len] = 0;
        return buf[0..len :0];
    } else |readlink_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.readlink_s, @errorName(readlink_error), dir_fd, name);
        }
        return readlink_error;
    }
}
pub fn unlink(comptime unlink_spec: UnlinkSpec, pathname: [:0]const u8) sys.ErrorUnion(
    unlink_spec.errors,
    unlink_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime unlink_spec.logging.override();
    if (meta.wrap(sys.call(.unlink, unlink_spec.errors, unlink_spec.return_type, .{pathname_buf_addr}))) {
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
pub fn unlinkAt(comptime unlink_spec: UnlinkSpec, dir_fd: usize, name: [:0]const u8) sys.ErrorUnion(
    unlink_spec.errors,
    unlink_spec.return_type,
) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const logging: debug.Logging.SuccessError = comptime unlink_spec.logging.override();
    if (meta.wrap(sys.call(.unlinkat, unlink_spec.errors, unlink_spec.return_type, .{ dir_fd, name_buf_addr, 0 }))) {
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
pub fn removeDir(comptime rmdir_spec: RemoveDirSpec, pathname: [:0]const u8) sys.ErrorUnion(
    rmdir_spec.errors,
    rmdir_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const logging: debug.Logging.SuccessError = comptime rmdir_spec.logging.override();
    if (sys.call(.rmdir, rmdir_spec.errors, rmdir_spec.return_type, .{pathname_buf_addr})) {
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
pub fn pathStatus(comptime stat_spec: StatusSpec, pathname: [:0]const u8, st: *Status) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    const pathname_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const st_buf_addr: u64 = @intFromPtr(st);
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (meta.wrap(sys.call(.stat, stat_spec.errors, void, .{ pathname_buf_addr, st_buf_addr }))) |ret| {
        if (logging.Success) {
            about.aboutDirFdNameStatusNotice(about.file_s, cwd, pathname, st);
        }
        if (stat_spec.return_type != void) {
            return @bitCast(ret);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.stat_s, @errorName(stat_error), pathname);
        }
        return stat_error;
    }
}
pub fn status(comptime stat_spec: StatusSpec, fd: usize, st: *Status) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (meta.wrap(sys.call(.fstat, stat_spec.errors, stat_spec.return_type, .{ fd, @intFromPtr(st) }))) |ret| {
        if (logging.Success) {
            about.aboutFdStatusNotice(about.stat_s, fd, st);
        }
        if (stat_spec.return_type != void) {
            return @bitCast(ret);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutFdError(about.stat_s, @errorName(stat_error), fd);
        }
        return stat_error;
    }
}
pub fn statusAt(comptime stat_spec: StatusSpec, at: sys.flags.At, dir_fd: usize, name: [:0]const u8, st: *Status) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    const name_buf_addr: usize = @intFromPtr(name.ptr);
    const st_buf_addr: usize = @intFromPtr(st);
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (meta.wrap(sys.call(.newfstatat, stat_spec.errors, void, .{ dir_fd, name_buf_addr, st_buf_addr, @bitCast(at) }))) {
        if (logging.Success) {
            about.aboutDirFdNameStatusNotice(about.stat_s, dir_fd, name, st);
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutDirFdNameError(about.stat_s, @errorName(stat_error), dir_fd, name);
        }
        return stat_error;
    }
}
pub fn statusExtended(
    comptime stat_spec: StatusExtendedSpec,
    at: sys.flags.AtStatX,
    mask: sys.flags.StatX,
    fd: usize,
    pathname: [:0]const u8,
    st: *StatusExtended,
) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (meta.wrap(sys.call(.statx, stat_spec.errors, void, .{
        fd, @intFromPtr(pathname.ptr), @bitCast(at), @bitCast(mask), @intFromPtr(st),
    }))) {
        if (logging.Success) {
            about.aboutDirFdNameStatusNotice(about.stat_s, fd, pathname, @ptrCast(st));
        }
    } else |stat_error| {
        if (logging.Error) {
            about.aboutFdError(about.stat_s, @errorName(stat_error), fd);
        }
        return stat_error;
    }
}
pub fn getPathStatus(comptime stat_spec: StatusSpec, pathname: [:0]const u8) sys.ErrorUnion(stat_spec.errors, Status) {
    var st: Status = undefined;
    try meta.wrap(pathStatus(stat_spec, pathname, &st));
    return st;
}
pub fn getStatus(comptime stat_spec: StatusSpec, fd: usize) sys.ErrorUnion(stat_spec.errors, Status) {
    var st: Status = undefined;
    try meta.wrap(status(stat_spec, fd, &st));
    return st;
}
pub fn getStatusAt(comptime stat_spec: StatusSpec, flags: sys.flags.At, dir_fd: usize, name: [:0]const u8) sys.ErrorUnion(
    stat_spec.errors,
    Status,
) {
    var st: Status = undefined;
    try meta.wrap(statusAt(stat_spec, flags, dir_fd, name, &st));
    return st;
}
pub fn getStatusExtended(comptime stat_spec: StatusExtendedSpec, at: sys.flags.At, fd: usize, pathname: [:0]const u8) sys.ErrorUnion(
    stat_spec.errors,
    StatusExtended,
) {
    var st: StatusExtended = undefined;
    try meta.wrap(statusExtended(stat_spec, at, fd, pathname, &st));
    return st;
}
pub fn map(comptime map_spec: mem.MapSpec, prot: sys.flags.FileProt, flags: sys.flags.FileMap, fd: usize, addr: u64, len: u64, off: u64) sys.ErrorUnion(
    map_spec.errors,
    map_spec.return_type,
) {
    const logging: debug.Logging.AcquireError = comptime map_spec.logging.override();
    const ret: isize = asm volatile ("syscall # mmap"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.mmap)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (prot),
          [_] "{r10}" (flags),
          [_] "{r8}" (fd),
          [_] "{r9}" (off),
        : "rcx", "r11", "memory"
    );
    if (map_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.throw, ret) catch |map_error| {
            if (logging.Error) {
                about.aboutFdAddrLenOffsetError(about.map_s, @errorName(map_error), addr, len, flags);
            }
            return map_error;
        };
    }
    if (map_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.abort, ret) catch |map_error| {
            if (logging.Error) {
                about.aboutFdAddrLenOffsetError(about.map_s, @errorName(map_error), fd, addr, len, off);
            }
            proc.exitError(map_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutFdAddrLenOffsetNotice(about.map_s, fd, addr, len, flags);
    }
    if (map_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub fn send(comptime send_spec: SendSpec, dest_fd: usize, src_fd: usize, offset: ?*u64, count: u64) sys.ErrorUnion(
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
pub fn copy(comptime copy_spec: CopySpec, dest_fd: usize, dest_offset: ?*u64, src_fd: usize, src_offset: ?*u64, count: u64) sys.ErrorUnion(
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
pub fn linkAt(comptime link_spec: LinkSpec, at: sys.flags.At, src_dir_fd: usize, from_name: [:0]const u8, dest_dir_fd: usize, to_name: [:0]const u8) sys.ErrorUnion(
    link_spec.errors,
    link_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime link_spec.logging.override();
    if (meta.wrap(sys.call(.linkat, link_spec.errors, link_spec.return_type, .{
        src_dir_fd, @intFromPtr(from_name.ptr), dest_dir_fd, @intFromPtr(to_name.ptr), @bitCast(at),
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
pub fn symbolicLinkAt(comptime link_spec: LinkSpec, pathname: [:0]const u8, dir_fd: usize, name: [:0]const u8) sys.ErrorUnion(
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
pub fn sync(comptime sync_spec: SyncSpec, fd: usize) sys.ErrorUnion(
    sync_spec.errors,
    sync_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime sync_spec.logging.override();
    const syscall: sys.Fn = if (true) .fsync else .fdatasync;
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
pub fn seek(comptime seek_spec: SeekSpec, fd: usize, offset: usize, whence: Whence) sys.ErrorUnion(
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
pub fn truncate(comptime truncate_spec: TruncateSpec, fd: usize, offset: usize) sys.ErrorUnion(
    truncate_spec.errors,
    truncate_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime truncate_spec.logging.override();
    if (meta.wrap(sys.call(.ftruncate, truncate_spec.errors, truncate_spec.return_type, .{ fd, offset }))) |ret| {
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
pub fn pathTruncate(comptime truncate_spec: TruncateSpec, pathname: [:0]const u8, offset: usize) sys.ErrorUnion(
    truncate_spec.errors,
    truncate_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime truncate_spec.logging.override();
    if (meta.wrap(sys.call(.truncate, truncate_spec.errors, truncate_spec.return_type, .{ @intFromPtr(pathname.ptr), offset }))) |ret| {
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
    errors: sys.ErrorPolicy = .{ .throw = spec.ioctl.errors.all },
    return_type: type = void,
    logging: debug.Logging.Default = .{},
};
const IOControlSpec = struct {
    const TC = sys.TC;
    const TIOC = sys.TIOC;
};
pub fn duplicate(comptime dup_spec: DuplicateSpec, old_fd: usize) sys.ErrorUnion(
    dup_spec.errors,
    dup_spec.return_type,
) {
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
pub fn duplicateTo(comptime dup3_spec: Duplicate3Spec, flags: Flags.Duplicate, old_fd: usize, new_fd: usize) sys.ErrorUnion(
    dup3_spec.errors,
    dup3_spec.return_type,
) {
    const logging: debug.Logging.SuccessError = comptime dup3_spec.logging.override();
    if (meta.wrap(sys.call(.dup3, dup3_spec.errors, dup3_spec.return_type, .{ old_fd, new_fd, @bitCast(flags) }))) |ret| {
        if (logging.Success) {
            about.aboutFdFdNotice(about.dup3_s, "old_fd=", "new_fd=", old_fd, new_fd);
        }
        return ret;
    } else |dup3_error| {
        if (logging.Error) {
            about.aboutFdFdError(about.dup_s, @errorName(dup3_error), "old_fd=", "new_fd=", old_fd, new_fd);
        }
        return dup3_error;
    }
}
pub fn makePipe(comptime pipe2_spec: MakePipeSpec, flags: Flags.Duplicate) sys.ErrorUnion(pipe2_spec.errors, Pipe) {
    var pipefd: Pipe = undefined;
    const pipefd_addr: u64 = @intFromPtr(&pipefd);
    const logging: debug.Logging.AcquireError = comptime pipe2_spec.logging.override();
    if (meta.wrap(sys.call(.pipe2, pipe2_spec.errors, void, .{ pipefd_addr, @bitCast(flags) }))) {
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
pub fn poll(comptime poll_spec: PollSpec, fds: []PollFd, timeout: u32) sys.ErrorUnion(
    poll_spec.errors,
    poll_spec.return_type,
) {
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
pub inline fn pollOne(comptime poll_spec: PollSpec, fd: *PollFd, timeout: u32) sys.ErrorUnion(
    poll_spec.errors,
    poll_spec.return_type,
) {
    return poll(poll_spec, @as([*]PollFd, @ptrCast(fd))[0..1], timeout);
}
// TODO:
//  bind
//  connect
//  ioctl
//  recvfrom
//  sendto
//  setsockopt
pub fn accessAt(comptime access_spec: AccessSpec, at: sys.flags.AtAccess, dir_fd: usize, name: [:0]const u8, ok: Access) sys.ErrorUnion(
    access_spec.errors,
    access_spec.return_type,
) {
    if (meta.wrap(sys.call(.faccessat2, access_spec.errors, usize, .{
        dir_fd, @intFromPtr(name.ptr), @bitCast(ok), @bitCast(at),
    }))) |ret| {
        if (access_spec.return_type == bool) {
            return ret == 0;
        }
        return ret;
    } else |access_error| {
        return access_error;
    }
}
pub fn access(comptime access_spec: AccessSpec, pathname: [:0]const u8, ok: Access) sys.ErrorUnion(
    access_spec.errors,
    access_spec.return_type,
) {
    if (meta.wrap(sys.call(.access, access_spec.errors, usize, .{
        @intFromPtr(pathname.ptr), @bitCast(ok),
    }))) |ret| {
        if (access_spec.return_type == bool) {
            return ret == 0;
        }
        return ret;
    } else |access_error| {
        return access_error;
    }
}
pub fn pathIs(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(pathStatus(stat_spec, pathname, &st));
    if (stat_spec.return_type == ?Status) {
        return if (st.mode.kind == kind) st else null;
    }
    return st.mode.kind == kind;
}
pub fn pathIsNot(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(pathStatus(stat_spec, pathname, &st));
    if (stat_spec.return_type == ?Status) {
        return if (st.mode.kind != kind) st else null;
    }
    return st.mode.kind != kind;
}
pub fn pathAssert(comptime stat_spec: StatusSpec, pathname: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(pathStatus(stat_spec, pathname, &st));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            about.pathMustBeFault(pathname, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type == Status) {
        return st;
    }
}
pub fn isAt(comptime stat_spec: StatusSpec, dir_fd: usize, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(statusAt(stat_spec, dir_fd, name, &st));
    if (stat_spec.return_type == ?Status) {
        return if (st.mode.kind == kind) st else null;
    }
    return st.mode.kind == kind;
}
pub fn isNotAt(comptime stat_spec: StatusSpec, dir_fd: usize, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(statusAt(stat_spec, dir_fd, name, &st));
    if (stat_spec.return_type == ?Status) {
        return if (st.mode.kind != kind) st else null;
    }
    return st.mode.kind != kind;
}
pub fn assertAt(comptime stat_spec: StatusSpec, at: sys.flags.At, dir_fd: usize, name: [:0]const u8, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(statusAt(stat_spec, at, dir_fd, name, &st));
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (st.mode.kind != kind) {
        if (logging.Fault) {
            about.atDirFdMustBeFault(dir_fd, name, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type == Status) {
        return st;
    }
}
pub fn is(comptime stat_spec: StatusSpec, fd: usize, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(status(stat_spec, fd, &st));
    if (stat_spec.return_type == ?Status) {
        return if (st.mode.kind == kind) st else null;
    }
    return st.mode.kind == kind;
}
pub fn isNot(comptime stat_spec: StatusSpec, kind: Kind, fd: usize) sys.ErrorUnion(
    stat_spec.errors,
    if (stat_spec.return_type == void) bool else stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(status(stat_spec, fd, &st));
    if (stat_spec.return_type == ?Status) {
        return bits.cmovZ(st.mode.kind != kind, st);
    }
    return st.mode.kind != kind;
}
pub fn assert(comptime stat_spec: StatusSpec, fd: usize, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(status(stat_spec, fd, &st));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (!res) {
        if (logging.Fault) {
            about.fdKindModeFault(fd, kind, st.mode);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type == Status) {
        return st;
    }
}
pub fn assertNot(comptime stat_spec: StatusSpec, fd: usize, kind: Kind) sys.ErrorUnion(
    stat_spec.errors,
    stat_spec.return_type,
) {
    var st: Status = comptime builtin.zero(Status);
    try meta.wrap(status(stat_spec, fd, &st));
    const res: bool = st.mode.kind == kind;
    const logging: debug.Logging.SuccessErrorFault = comptime stat_spec.logging.override();
    if (res) {
        if (logging.Fault) {
            about.fdNotKindFault(fd, kind);
        }
        proc.exit(2);
    }
    if (stat_spec.return_type == Status) {
        return st;
    }
}
fn getTerminalAttributes() void {}
fn setTerminalAttributes() void {}
pub fn readRandom(buf: []u8) !void {
    return sys.call(.getrandom, .{ .throw = spec.getrandom.errors.all }, void, .{ @intFromPtr(buf.ptr), buf.len, sys.GRND.RANDOM });
}
pub const DirStreamSpec = struct {
    Allocator: type,
    errors: Errors = .{},
    options: Options = .{},
    logging: Logging = .{},
    pub const Options = struct {
        initial_size: u64 = 1024,
        init_read_all: bool = true,
        shrink_after_read: bool = true,
        make_list: bool = true,
        close_on_deinit: bool = true,
    };
    pub const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = spec.open.errors.all },
        close: sys.ErrorPolicy = .{ .abort = spec.close.errors.all },
        getdents: sys.ErrorPolicy = .{ .throw = spec.getdents.errors.all },
    };
    pub const Logging = packed struct {
        open: debug.Logging.AttemptAcquireError = .{},
        close: debug.Logging.ReleaseError = .{},
        getdents: debug.Logging.SuccessError = .{},
    };
};
pub const SimplePath = struct {
    name: [:0]const u8,
};
pub const CompoundPath = extern struct {
    names: [*][:0]u8 = @ptrFromInt(8),
    names_len: usize = 0,
    names_max_len: usize = 0,
    pub fn addName(cp: *CompoundPath, allocator: anytype) *[:0]const u8 {
        @setRuntimeSafety(builtin.is_safe);
        const size_of: comptime_int = @sizeOf([:0]const u8);
        const addr_buf: *u64 = @ptrCast(&cp.names);
        const ret: *[:0]const u8 = @ptrFromInt(allocator.addGeneric(size_of, //
            2, 8, addr_buf, &cp.names_max_len, cp.names_len));
        cp.names_len +%= 1;
        return ret;
    }
    pub fn hasExtension(cp: *const CompoundPath, ext: [:0]const u8) bool {
        @setRuntimeSafety(builtin.is_safe);
        const name: [:0]const u8 = cp.names[cp.names_len -% 1];
        return mem.testEqualString(ext, name[name.len -% ext.len ..]);
    }
    pub fn status(cp: *const CompoundPath, comptime stat_spec: StatusSpec, st: *Status) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096:0]u8 = undefined;
        statusAt(stat_spec, .{}, cwd, buf[0 .. cp.formatWriteBuf(&buf) -% 1 :0], st);
    }
    pub fn concatenate(cp: *const CompoundPath, allocator: anytype) [:0]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(cp.formatLength(), 1));
        const len: usize = cp.formatWriteBuf(buf) -% 1;
        buf[len] = 0;
        return buf[0..len :0];
    }
    pub usingnamespace fmt.PathFormat(CompoundPath);
};
pub fn GenericDirStream(comptime dirs_spec: DirStreamSpec) type {
    return (struct {
        path: [:0]const u8,
        fd: usize,
        blk: Block,
        count: u64,
        const DirStream = @This();
        const Block = mem.pointer.ReadWriteResizeUnstructuredDisjunctAlignment(.{
            .low_alignment = 8,
            .high_alignment = 8,
        });
        pub const Allocator = dirs_spec.Allocator;
        pub const ListView = mem.list.GenericLinkedListView(.{ .child = Entry, .low_alignment = 8 });
        pub const Entry = opaque {
            pub fn possess(dirent: *const Entry, dir: *DirStream) void {
                @setRuntimeSafety(false);
                @as(*const Block, @ptrFromInt(@intFromPtr(dirent) +% 0)).* = dir.blk;
                close(dir_close_spec, dir.fd);
            }
            pub fn entries(dirent: *const Entry) Block {
                @setRuntimeSafety(false);
                return @as(*const Block, @ptrFromInt(@intFromPtr(dirent))).*;
            }
            pub fn len(dirent: *const Entry) u16 {
                @setRuntimeSafety(false);
                return @as(*const u16, @ptrFromInt(@intFromPtr(dirent) +% 8)).*;
            }
            pub fn kind(dirent: *const Entry) Kind {
                @setRuntimeSafety(false);
                return @as(*const Kind, @ptrFromInt(@intFromPtr(dirent) +% 10)).*;
            }
            pub fn name(dirent: *const Entry) [:0]const u8 {
                @setRuntimeSafety(false);
                return @as([*:0]u8, @ptrFromInt(@intFromPtr(dirent) +% 11))[0..dirent.len() :0];
            }
        };
        fn links(blk: Block) ListView.Links {
            return .{
                .major = blk.aligned_byte_address(),
                .minor = blk.aligned_byte_address() +% 48,
            };
        }
        const dir_open_spec: OpenSpec = .{
            .errors = dirs_spec.errors.open,
            .logging = dirs_spec.logging.open,
        };
        const dir_close_spec: CloseSpec = .{
            .errors = dirs_spec.errors.close,
            .logging = dirs_spec.logging.close,
        };
        pub fn list(dir: *DirStream) ListView {
            return .{ .links = links(dir.blk), .count = dir.count, .index = 0 };
        }
        fn getDirectoryEntries(dir: *const DirStream) sys.ErrorUnion(dirs_spec.errors.getdents, u64) {
            return sys.call(.getdents64, dirs_spec.errors.getdents, u64, .{
                dir.fd,
                dir.blk.undefined_byte_address(),
                dir.blk.undefined_byte_count(),
            });
        }
        fn grow(dir: *DirStream, allocator: *Allocator) Allocator.allocate_void {
            const s_bytes: u64 = dir.blk.writable_byte_count();
            const t_bytes: u64 = s_bytes * 2;
            const s_impl: Block = dir.blk;
            try meta.wrap(allocator.resizeManyAbove(Block, &dir.blk, .{ .bytes = t_bytes }));
            mem.addrset(s_impl.unwritable_byte_address(), 0, dir.blk.unwritable_byte_address() -% s_impl.unwritable_byte_address());
        }
        fn readAll(dir: *DirStream, allocator: *Allocator) !void {
            dir.blk.define(try dir.getDirectoryEntries());
            while (dir.blk.undefined_byte_count() < 528) {
                try meta.wrap(dir.grow(allocator));
                dir.blk.define(try meta.wrap(dir.getDirectoryEntries()));
            }
            if (dirs_spec.options.shrink_after_read) {
                allocator.resizeManyBelow(Block, &dir.blk, .{
                    .bytes = bits.alignA(dir.blk.defined_byte_count() +% 48, 8),
                });
            }
        }
        pub fn initAt(allocator: *Allocator, dir_fd: ?usize, name: [:0]const u8) !DirStream {
            const fd: usize = try openAt(dir_open_spec, .{ .directory = true }, dir_fd orelse cwd, name);
            const blk: Block = try meta.wrap(allocator.allocateMany(Block, .{ .bytes = dirs_spec.options.initial_size }));
            mem.addrset(blk.aligned_byte_address(), 0, dirs_spec.options.initial_size);
            var ret: DirStream = .{ .path = name, .fd = fd, .blk = blk, .count = 1 };
            if (dirs_spec.options.init_read_all) {
                try ret.readAll(allocator);
            }
            if (dirs_spec.options.make_list) {
                ret.count = List.interleaveXorListNodes(
                    ListView.Node,
                    ret.blk.aligned_byte_address(),
                    ret.blk.undefined_byte_address(),
                );
            }
            return ret;
        }
        pub fn init(allocator: *Allocator, pathname: [:0]const u8) !DirStream {
            const fd: usize = try open(dir_open_spec, .{ .directory = true }, pathname);
            const blk: Block = try meta.wrap(allocator.allocateMany(Block, .{ .bytes = dirs_spec.options.initial_size }));
            mem.addrset(blk.aligned_byte_address(), 0, dirs_spec.options.initial_size);
            var ret: DirStream = .{ .path = pathname, .fd = fd, .blk = blk, .count = 1 };
            if (dirs_spec.options.init_read_all) {
                try ret.readAll(allocator);
            }
            if (dirs_spec.options.make_list) {
                ret.count = List.interleaveXorListNodes(
                    ListView.Node,
                    ret.blk.aligned_byte_address(),
                    ret.blk.undefined_byte_address(),
                );
            }
            return ret;
        }
        /// Close directory file and free all allocated memory.
        pub fn deinit(dir: *DirStream, allocator: *Allocator) void {
            allocator.deallocateMany(Block, dir.blk);
            if (dir.fd != 0) {
                close(dir_close_spec, dir.fd);
                dir.fd = 0;
            }
        }
        comptime {
            if (dirs_spec.options.make_list) {
                debug.assert(dirs_spec.options.init_read_all);
            }
        }
    });
}
const List = opaque {
    const name_offset: u8 = @offsetOf(DirectoryEntry, "array");
    const reclen_offset: u8 = @offsetOf(DirectoryEntry, "reclen");
    const offset_offset: u8 = @offsetOf(DirectoryEntry, "offset");
    // Often the dot and dot-dot directory entries will not be the first
    // and second entries, and the addresses of the head and sentinel
    // nodes of our mangled list must be known--otherwise we would have
    // to store more metadata in the DirStream object.
    fn shiftBothBlocks(s_lb_addr: u64, major_src_addr: u64, minor_src_addr: u64) void {
        const major_save: [24]u8 = @as(*const [24]u8, @ptrFromInt(major_src_addr)).*;
        const major_dst_addr: u64 = s_lb_addr;
        const minor_save: [24]u8 = @as(*const [24]u8, @ptrFromInt(minor_src_addr)).*;
        const minor_dst_addr: u64 = s_lb_addr +% 24;
        const upper_src_addr: u64 = @max(major_src_addr, minor_src_addr);
        const lower_src_addr: u64 = @min(major_src_addr, minor_src_addr);
        var t_lb_addr: u64 = upper_src_addr;
        while (t_lb_addr != lower_src_addr +% 24) {
            t_lb_addr -= 8;
            @as(*u64, @ptrFromInt(t_lb_addr +% 24)).* = @as(*u64, @ptrFromInt(t_lb_addr)).*;
        }
        t_lb_addr = lower_src_addr;
        while (t_lb_addr != major_dst_addr) {
            t_lb_addr -= 8;
            @as(*u64, @ptrFromInt(t_lb_addr +% 48)).* = @as(*u64, @ptrFromInt(t_lb_addr)).*;
        }
        @as(*[24]u8, @ptrFromInt(major_dst_addr)).* = major_save;
        @as(*[24]u8, @ptrFromInt(minor_dst_addr)).* = minor_save;
    }
    // 11780 = [2]u8{ 4, 46 }, i.e. "d."
    // 46    = [2]u8{ 46, 0 }, i.e. ".\x00"
    // 1070  = [2]u8{ 46, 4 }
    // 11776 = [2]u8{ 0, 46 }
    // This method is about 25% faster than testing if starts with ".\0"
    // and "..\0", and cmoving the relevant index. I suppose this
    // respects endian, but have never tested it.
    fn classifyName(addrs: *[3]u64, s_lb_addr: u64) void {
        const w0: u16 = @as(*const u16, @ptrFromInt(s_lb_addr +% 18)).*;
        const w1: u16 = @as(*const u16, @ptrFromInt(s_lb_addr +% 20)).*;
        const j0: u8 = @intFromBool(w0 == if (builtin.native_endian == .Little) 11780 else 1070);
        const j1: u8 = j0 << @intFromBool(w1 == if (builtin.native_endian == .Little) 46 else 11776);
        const j2: u8 = j1 & (@as(u8, 1) << @intFromBool(w1 != 0));
        addrs[j2] = s_lb_addr;
    }
    fn mangle(s_lb_addr: u64) void {
        const len: u16 = @as(*u16, @ptrFromInt(s_lb_addr +% 16)).*;
        const a_0: u64 = (s_lb_addr +% len) -% 8;
        const a_1: u16 = 64 -% @clz(@as(*const u64, @ptrFromInt(a_0)).*);
        const a_2: u16 = (len +% (1 +% (a_1 / 8))) -% (name_offset +% 8);
        const a_3: *u8 = @as(*u8, @ptrFromInt(s_lb_addr +% name_offset +% (a_2 -% 1)));
        const name_len: u16 = a_2 -% @intFromBool(a_3.* == 0);
        @as(*u8, @ptrFromInt(s_lb_addr +% name_offset +% name_len)).* = 0;
        @as(*u16, @ptrFromInt(s_lb_addr +% reclen_offset)).* = name_len;
        @as(*u64, @ptrFromInt(s_lb_addr +% offset_offset)).* = 0;
    }
    fn rectifyEntryOrder(s_lb_addr: u64) void {
        var addrs: [3]u64 = .{0} ** 3;
        var t_lb_addr: u64 = s_lb_addr;
        classifyName(&addrs, t_lb_addr);
        t_lb_addr = nextAddress(t_lb_addr);
        classifyName(&addrs, t_lb_addr);
        while (addrs[1] *% addrs[2] == 0) : (t_lb_addr = nextAddress(t_lb_addr)) {
            classifyName(&addrs, t_lb_addr);
        }
        if (addrs[1] != s_lb_addr or
            addrs[2] != s_lb_addr +% 24)
        {
            shiftBothBlocks(s_lb_addr, addrs[1], addrs[2]);
        }
    }
    /// Converts linux directory stream to a linked list without moving
    /// or copying. '..' directory sacrificed to make room for the list
    /// sentinel node. Do not touch.
    pub fn interleaveXorListNodes(comptime Node: type, s_lb_addr: u64, s_up_addr: u64) u64 {
        rectifyEntryOrder(s_lb_addr);
        const t_node_addr: u64 = nextAddress(s_lb_addr);
        var s_node_addr: u64 = s_lb_addr;
        var p_node_addr: u64 = 0;
        var i_node_addr: u64 = nextAddress(t_node_addr);
        mangle(s_node_addr);
        Node.Link.mutate(s_node_addr, 0, t_node_addr);
        Node.Link.mutate(t_node_addr, s_node_addr, 0);
        mangle(t_node_addr);
        var count: u64 = 1;
        while (i_node_addr < s_up_addr) : (count +%= 1) {
            Node.Link.mutate(s_node_addr, p_node_addr, i_node_addr);
            Node.Link.mutate(i_node_addr, s_node_addr, t_node_addr);
            Node.Link.mutate(t_node_addr, i_node_addr, 0);
            p_node_addr = s_node_addr;
            s_node_addr = i_node_addr;
            i_node_addr = nextAddress(i_node_addr);
            mangle(s_node_addr);
        }
        return count;
    }
    pub fn nextAddress(s_lb_addr: u64) u64 {
        return s_lb_addr +% @as(*u16, @ptrFromInt(s_lb_addr +% reclen_offset)).*;
    }
};
pub fn DeviceRandomBytes(comptime bytes: u64) type {
    return struct {
        data: mem.array.StaticString(bytes) = .{},
        const Random = @This();
        const dev: u64 = if (builtin.is_safe)
            sys.GRND.RANDOM
        else
            sys.GRND.INSECURE;
        pub fn readOne(random: *Random, comptime T: type) T {
            @setRuntimeSafety(false);
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
            const s_ab_addr: u64 = bits.alignA64(s_lb_addr, low_alignment);
            const s_up_addr: u64 = s_ab_addr +% high_alignment;
            if (s_up_addr >= random.data.impl.unwritable_byte_address()) {
                random.data.undefineAll();
                const t_lb_addr: u64 = random.data.impl.undefined_byte_address();
                const t_ab_addr: u64 = bits.alignA64(t_lb_addr, low_alignment);
                const t_up_addr: u64 = t_ab_addr +% high_alignment;
                sys.call(.getrandom, .{}, void, .{ random.data.impl.aligned_byte_address(), bytes, dev });
                random.data.define(@max(1, t_up_addr - t_lb_addr));
                return @as(*const child, @ptrFromInt(t_ab_addr)).*;
            }
            random.data.impl.define(@max(1, s_up_addr - s_lb_addr));
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
    const chdir_s: fmt.AboutSrc = fmt.about("chdir");
    const socket_s: fmt.AboutSrc = fmt.about("socket");
    const listen_s: fmt.AboutSrc = fmt.about("listen");
    const create_s: fmt.AboutSrc = fmt.about("create");
    const execve_s: fmt.AboutSrc = fmt.about("execve");
    const getcwd_s: fmt.AboutSrc = fmt.about("getcwd");
    const unlink_s: fmt.AboutSrc = fmt.about("unlink");
    const symlink_s: fmt.AboutSrc = fmt.about("symlink");
    const getdents_s: fmt.AboutSrc = fmt.about("getdents");
    const truncate_s: fmt.AboutSrc = fmt.about("truncate");
    const readlink_s: fmt.AboutSrc = fmt.about("readlink");
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
    fn totalLength(vecs: []const mem.Vector) usize {
        @setRuntimeSafety(false);
        var max_len: usize = 0;
        for (vecs) |vec| {
            max_len +%= vec.len;
        }
        return max_len;
    }
    fn aboutFdNotice(about_s: fmt.AboutSrc, fd: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUdsize(ptr + 3, fd);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    pub fn aboutFdAddrLenOffsetNotice(about_s: fmt.AboutSrc, fd: usize, addr: u64, len: u64, offset: usize) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUx64(ptr + 2, addr);
        ptr[0..2].* = "..".*;
        ptr = fmt.writeUx64(ptr + 2, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeBytes(ptr + 2, len);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    fn aboutFdModeNotice(about_s: fmt.AboutSrc, fd: usize, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    fn aboutFdStatusNotice(about_s: fmt.AboutSrc, fd: usize, st: *const Status) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..2].* = ", ".*;
        ptr = writeStatus(ptr + 2, st);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    fn aboutFdLenNotice(about_s: fmt.AboutSrc, fd: usize, fd_len: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeBytes(ptr + 2, fd_len);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    fn aboutFdMaxLenLenNotice(about_s: fmt.AboutSrc, fd: usize, max_len: usize, act_len: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUd64(ptr + 2, act_len);
        ptr[0] = '/';
        ptr = fmt.writeUd64(ptr + 1, max_len);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn aboutFdReadWriteMaxLenLenNotice(about_s: fmt.AboutSrc, fd: usize, flags: sys.flags.ReadWrite, max_len: usize, act_len: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..][0..3].* = "fd=".*;
        var ptr: [*]u8 = fmt.writeUd64(buf[about_s.len +% 3 ..], fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        const len: usize = flags.formatWriteBuf(ptr + 2);
        if (len != 0) {
            ptr += len;
            ptr[0..2].* = ", ".*;
            ptr += 2;
        }
        ptr = fmt.writeUd64(ptr, act_len);
        ptr[0] = '/';
        ptr += 1;
        ptr = fmt.writeUd64(ptr, max_len);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn aboutFdOffsetReadWriteMaxLenLenNotice(about_s: fmt.AboutSrc, fd: usize, offset: usize, flags: sys.flags.ReadWrite, max_len: usize, act_len: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        const len: usize = flags.formatWriteBuf(ptr);
        if (len != 0) {
            ptr += len;
            ptr[0..2].* = ", ".*;
            ptr += 2;
        }
        ptr = fmt.writeUd64(ptr, act_len);
        ptr[0] = '/';
        ptr = fmt.writeUd64(ptr + 1, max_len);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn aboutFdFdNotice(about_s: fmt.AboutSrc, fd1_s: []const u8, fd2_s: []const u8, fd1: u64, fd2: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[about_s.len..], fd1_s);
        ptr = fmt.writeUd64(ptr, fd1);
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, fd2_s);
        ptr = fmt.writeUd64(ptr, fd2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameModeDeviceNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8, file_mode: Mode, dev: Device) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = writeDirFd(buf[about_s.len..], "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0..6].* = ", dev=".*;
        ptr = fmt.writeUd64(ptr + 6, dev.major);
        ptr[0] = ':';
        ptr = fmt.writeUd64(ptr + 1, dev.minor);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameStatusNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8, st: *const Status) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        if (name[0] != '/') {
            ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
            ptr[0..2].* = ", ".*;
            ptr += 2;
        }
        ptr = CompoundPath.writeDisplayPath(ptr, name);
        ptr[0..2].* = ", ".*;
        ptr = writeStatus(ptr + 2, st);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn writeDirFd(buf: [*]u8, dir_fd_s: []const u8, dir_fd: usize) [*]u8 {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = fmt.strcpyEqu(buf, dir_fd_s);
        if (dir_fd > 1024) {
            ptr[0..3].* = "CWD".*;
            return ptr + 3;
        } else {
            return fmt.writeUd64(ptr, dir_fd);
        }
    }
    fn aboutPathnameNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameModeNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[about_s.len..], pathname);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameFdNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, fd: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[about_s.len..], "fd=");
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, pathname);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameFdModeNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, fd: usize, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..][0..3].* = "fd=".*;
        var ptr: [*]u8 = fmt.writeUd64(buf[about_s.len +% 3 ..], fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, pathname);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameModeDeviceNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, file_mode: Mode, dev: Device) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[about_s.len..], pathname);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0..6].* = ", dev=".*;
        ptr += 6;
        ptr = fmt.writeUd64(ptr, dev.major);
        ptr[0] = ':';
        ptr += 1;
        ptr = fmt.writeUd64(ptr, dev.minor);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameModeNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameFdNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8, fd: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..5].* = ", fd=".*;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr + 5);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameFdModeNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8, fd: usize, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..5].* = ", fd=".*;
        ptr += fmt.ud64(fd).formatWriteBuf(ptr + 5);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameNotice(about_s: fmt.AboutSrc, dir_fd: usize, name: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameDirFdNameNotice(about_s: fmt.AboutSrc, dir_fd1_s: []const u8, relation_s: [:0]const u8, dir_fd2_s: []const u8, dir_fd1: u64, name1: [:0]const u8, dir_fd2: u64, name2: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = writeDirFd(ptr, dir_fd1_s, dir_fd1);
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, name1);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = writeDirFd(ptr, dir_fd2_s, dir_fd2);
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, name2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn socketNotice(fd: usize, dom: Socket.Domain, flags: Flags.Socket) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..socket_s.len].* = socket_s.*;
        var ptr: [*]u8 = buf[socket_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUdsize(ptr + 3, fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, @tagName(dom));
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, @tagName(flags.conn));
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnamePathnameNotice(about_s: fmt.AboutSrc, relation_s: [:0]const u8, pathname1: [:0]const u8, pathname2: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = CompoundPath.writeDisplayPath(ptr, pathname1);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = CompoundPath.writeDisplayPath(ptr, pathname2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameDirFdNameNotice(about_s: fmt.AboutSrc, relation_s: [:0]const u8, pathname: [:0]const u8, dir_fd: usize, name: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn sendNotice(dest_fd: usize, src_fd: usize, offset: ?*usize, max_count: usize, act_count: usize) void {
        @setRuntimeSafety(false);
        if (return) {}
        var buf: [32768]u8 = undefined;
        buf[0..send_s.len].* = send_s.*;
        var ptr: [*]u8 = buf[send_s.len..];
        ptr[0..7].* = "src_fd=".*;
        ptr = fmt.writeUd64(ptr, src_fd);
        ptr[0..10].* = ", dest_fd=".*;
        ptr = fmt.writeUd64(ptr + 10, dest_fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUd64(ptr + 2, act_count);
        ptr[0] = '/';
        ptr = fmt.writeUd64(ptr + 1, max_count);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (offset) |off| {
            ptr = writeUpdateFdOffset(ptr, src_fd, off.*);
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn copyNotice(dest_fd: usize, dest_offset: ?*usize, src_fd: usize, src_offset: ?*usize, max_count: usize, act_count: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..copy_s.len].* = copy_s.*;
        var ptr: [*]u8 = buf[copy_s.len..];
        ptr[0..7].* = "src_fd=".*;
        ptr = fmt.writeUdsize(ptr + 7, src_fd);
        ptr[0..10].* = ", dest_fd=".*;
        ptr = fmt.writeUdsize(ptr + 10, dest_fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUdsize(ptr + 2, act_count);
        ptr[0] = '/';
        ptr = fmt.writeUdsize(ptr + 1, max_count);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (src_offset) |off| {
            ptr = writeUpdateFdOffset(ptr, src_fd, off.*);
        }
        if (dest_offset) |off| {
            ptr = writeUpdateFdOffset(ptr, dest_fd, off.*);
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameOffsetNotice(about_s: fmt.AboutSrc, pathname: [:0]const u8, offset: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdOffsetNotice(about_s: fmt.AboutSrc, fd: usize, offset: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn seekNotice(fd: usize, offset: usize, whence: Whence, to: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..seek_s.len].* = seek_s.*;
        var ptr: [*]u8 = buf[seek_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0..6].* = ", cur=".*;
        ptr += 6;
        ptr = fmt.writeUd64(ptr, to);
        if (whence != .set) {
            ptr[0..2].* = ", ".*;
            ptr += 2;
            ptr = fmt.strcpyEqu(ptr, @tagName(whence));
            ptr[0] = '+';
            ptr += 1;
            ptr = fmt.writeUd64(ptr, offset);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn pollNotice(pollfds: []PollFd, timeout: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..poll_s.len].* = poll_s.*;
        var ptr: [*]u8 = buf[poll_s.len..].ptr;
        ptr[0..3].* = "fd=".*;
        ptr += 3;
        ptr = fmt.writeUd64(ptr, pollfds.len);
        ptr[0..10].* = ", timeout=".*;
        ptr += 10;
        ptr = fmt.writeUd64(ptr, timeout);
        ptr[0..3].* = "ms\n".*;
        ptr += 3;
        ptr = writePollFds(ptr, pollfds);
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn listenNotice(sock_fd: usize, backlog: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..listen_s.len].* = listen_s.*;
        var ptr: [*]u8 = buf[listen_s.len..].ptr;
        ptr[0..8].* = "sock_fd=".*;
        ptr += 8;
        ptr = fmt.writeUd64(ptr, sock_fd);
        ptr[0..10].* = ", backlog=".*;
        ptr += 10;
        ptr = fmt.writeUd64(ptr, backlog);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn executeNotice(pathname: [:0]const u8, args: []const [*:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..execve_s.len].* = execve_s.*;
        var ptr: [*]u8 = buf[execve_s.len..].ptr;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        if (args.len != 0) {
            ptr[0] = ' ';
            ptr = writeArgs(ptr + 1, pathname, args);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutFdAddrLenOffsetError(about_s: fmt.AboutSrc, error_name: []const u8, fd: usize, addr: u64, len: u64, offset: usize) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..5].* = ", fd=".*;
        ptr = fmt.writeUd64(ptr + 5, fd);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUx64(ptr + 2, addr);
        ptr[0..2].* = "..".*;
        ptr = fmt.writeUx64(ptr + 2, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeBytes(ptr + 2, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, dir_fd: usize, name: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr = writeDirFd(ptr + 2, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameModeError(about_s: fmt.AboutSrc, error_name: [:0]const u8, dir_fd: usize, name: [:0]const u8, file_mode: Mode) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr = writeDirFd(ptr + 2, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, file_mode);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, pathname: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdError(about_s: fmt.AboutSrc, error_name: [:0]const u8, fd: usize) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdReadWriteError(about_s: fmt.AboutSrc, error_name: [:0]const u8, fd: usize, flags: sys.flags.ReadWrite) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += flags.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdFdError(about_s: fmt.AboutSrc, error_name: [:0]const u8, fd1_s: []const u8, fd2_s: []const u8, fd1: u64, fd2: u64) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr = fmt.strcpyEqu(ptr + 2, fd1_s);
        ptr = fmt.writeUd64(ptr + fd1_s.len, fd1);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr + 2, fd2_s);
        ptr = fmt.writeUd64(ptr, fd2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnamePathnameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, relation_s: [:0]const u8, pathname1: [:0]const u8, pathname2: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, pathname1);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = fmt.strcpyEqu(ptr, pathname2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, relation_s: [:0]const u8, pathname: [:0]const u8, dir_fd: usize, name: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = CompoundPath.writeDisplayPath(ptr, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutDirFdNameDirFdNameError(about_s: fmt.AboutSrc, error_name: [:0]const u8, dir_fd1_s: []const u8, relation_s: [:0]const u8, dir_fd2_s: []const u8, dir_fd1: u64, name1: [:0]const u8, dir_fd2: u64, name2: [:0]const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        buf[about_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = writeDirFd(ptr, dir_fd1_s, dir_fd1);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, name1);
        ptr = fmt.strcpyEqu(ptr, relation_s);
        ptr = writeDirFd(ptr, dir_fd2_s, dir_fd2);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, name2);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn socketError(socket_error: anyerror, dom: Socket.Domain, flags: Flags.Socket) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..socket_s.len].* = socket_s.*;
        buf[socket_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], @errorName(socket_error));
        ptr += @errorName(socket_error).len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, @tagName(dom));
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.conn));
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn writeUpdateFdOffset(buf: [*]u8, fd: usize, offset: usize) [*]u8 {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf + fmt.writeSideBarIndex(buf, 4, fd);
        ptr[0..7].* = "offset=".*;
        ptr = fmt.writeUdsize(ptr + 7, offset);
        ptr[0] = '\n';
        return ptr + 1;
    }
    fn sendError(sendfile_error: anyerror, dest_fd: usize, src_fd: usize, offset: ?*u64, max_count: u64) void {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..send_s.len].* = send_s.*;
        buf[send_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], @errorName(sendfile_error));
        ptr[0..9].* = ", src_fd=".*;
        ptr += 9;
        ptr = fmt.writeUd64(ptr, src_fd);
        ptr[0..10].* = ", dest_fd=".*;
        ptr += 10;
        ptr = fmt.writeUd64(ptr, dest_fd);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.writeUd64(ptr, 0);
        ptr[0] = '/';
        ptr += 1;
        ptr = fmt.writeUd64(ptr, max_count);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (offset) |off| {
            ptr = writeUpdateFdOffset(ptr, src_fd, off.*);
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn copyError(copy_file_range_error: anyerror, dest_fd: usize, dest_offset: ?*u64, src_fd: usize, src_offset: ?*u64, max_count: u64) void {
        var buf: [32768]u8 = undefined;
        buf[0..copy_s.len].* = copy_s.*;
        buf[copy_s.len..fmt.about_err_len].* = debug.about.error_s.*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[fmt.about_err_len..], @errorName(copy_file_range_error));
        ptr[0..9].* = ", src_fd=".*;
        ptr = fmt.writeUd64(ptr + 9, src_fd);
        ptr[0..10].* = ", dest_fd=".*;
        ptr = fmt.writeUd64(ptr + 10, dest_fd);
        ptr[0..2].* = ", ".*;
        ptr = fmt.writeUd64(ptr + 2, 0);
        ptr[0] = '/';
        ptr = fmt.writeUd64(ptr + 1, max_count);
        ptr[0..7].* = " bytes\n".*;
        ptr += 7;
        if (src_offset) |off| {
            ptr = writeUpdateFdOffset(ptr, src_fd, off.*);
        }
        if (dest_offset) |off| {
            ptr = writeUpdateFdOffset(ptr, dest_fd, off.*);
        }
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameOffsetError(about_s: fmt.AboutSrc, error_name: []const u8, pathname: [:0]const u8, offset: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr = fmt.strcpyEqu(ptr + debug.about.error_s.len, error_name);
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, pathname);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdOffsetError(about_s: fmt.AboutSrc, error_name: []const u8, fd: usize, offset: usize) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, error_name);
        ptr[0..5].* = ", fd=".*;
        ptr = fmt.writeUd64(ptr + 5, fd);
        ptr[0..9].* = ", offset=".*;
        ptr = fmt.writeUd64(ptr + 9, offset);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdOffsetReadWriteError(about_s: fmt.AboutSrc, error_name: []const u8, fd: usize, offset: usize, flags: sys.flags.ReadWrite) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, error_name);
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0..9].* = ", offset=".*;
        ptr += 9;
        ptr = fmt.writeUd64(ptr, offset);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += flags.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn seekError(seek_error: anyerror, fd: usize, offset: usize, whence: Whence) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..seek_s.len].* = seek_s.*;
        var ptr: [*]u8 = buf[seek_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, @errorName(seek_error));
        ptr[0..5].* = ", fd=".*;
        ptr += 5;
        ptr = fmt.writeUd64(ptr, fd);
        ptr[0..5].* = ", to=".*;
        ptr += 5;
        ptr = fmt.writeUd64(ptr, offset);
        if (whence != .set) {
            ptr[0..2].* = ", ".*;
            ptr += 2;
            ptr = fmt.strcpyEqu(ptr, @tagName(whence));
            ptr[0] = '+';
            ptr += 1;
            ptr = fmt.writeUd64(ptr, offset);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn listenError(listen_error: anyerror, sock_fd: usize, backlog: u64) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..listen_s.len].* = listen_s.*;
        var ptr: [*]u8 = buf[listen_s.len..].ptr;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, @errorName(listen_error));
        ptr[0..10].* = ", sock_fd=".*;
        ptr += 10;
        ptr = fmt.writeUd64(ptr, sock_fd);
        ptr[0..10].* = ", backlog=".*;
        ptr += 10;
        ptr = fmt.writeUd64(ptr, backlog);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn executeErrorBrief(exec_error: anyerror, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..execve_s.len].* = execve_s.*;
        ptr += execve_s.len;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, @errorName(exec_error));
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn executeError(exec_error: anyerror, pathname: [:0]const u8, args: []const [*:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..execve_s.len].* = execve_s.*;
        ptr += execve_s.len;
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        ptr = fmt.strcpyEqu(ptr, @errorName(exec_error));
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, pathname);
        if (args.len != 0) {
            ptr[0] = ' ';
            ptr = writeArgs(ptr + 1, pathname, args);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn pathMustNotBeFault(pathname: [:0]const u8, kind: Kind) void {
        @setRuntimeSafety(false);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0..13].* = must_not_be_file_s.*;
        ptr = fmt.strcpyEqu(ptr + 13, descr_s);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn pathMustBeFault(pathname: [:0]const u8, kind: Kind, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..].ptr;
        ptr = CompoundPath.writeDisplayPath(ptr, pathname);
        ptr[0..9].* = must_be_file_s.*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, descr_s);
        ptr[0..5].* = is_file_s.*;
        ptr += 5;
        descr_s = describeKind(file_mode.kind);
        ptr = fmt.strcpyEqu(ptr, descr_s);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn fdNotKindFault(fd: usize, kind: Kind) void {
        @setRuntimeSafety(false);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..13].* = must_not_be_file_s.*;
        ptr = fmt.strcpyEqu(ptr + 13, descr_s);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn fdKindModeFault(fd: usize, kind: Kind, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var descr_s: []const u8 = describeKind(kind);
        var buf: [32768]u8 = undefined;
        buf[0..debug.about.fault_p0_s.len].* = debug.about.fault_p0_s.*;
        var ptr: [*]u8 = buf[debug.about.fault_p0_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.writeUd64(ptr + 3, fd);
        ptr[0..9].* = must_be_file_s.*;
        ptr = fmt.strcpyEqu(ptr + 9, descr_s);
        descr_s = describeKind(file_mode.kind);
        ptr[0..5].* = is_file_s.*;
        ptr = fmt.strcpyEqu(ptr + 5, descr_s);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn atDirFdMustBeFault(dir_fd: usize, name: [:0]const u8, kind: Kind, file_mode: Mode) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..file_s.len].* = file_s.*;
        var ptr: [*]u8 = buf[file_s.len..];
        if (name[0] != '/') {
            ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        }
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..must_be_file_s.len].* = must_be_file_s.*;
        ptr += must_be_file_s.len;
        ptr = fmt.strcpyEqu(ptr, describeKind(kind));
        ptr[0..5].* = "; is ".*;
        ptr = fmt.strcpyEqu(ptr + 5, describeKind(file_mode.kind));
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
    }
    fn atDirFdMustNotBeFault(dir_fd: usize, name: [:0]const u8, kind: Kind) void {
        @setRuntimeSafety(false);
        var buf: [32768]u8 = undefined;
        buf[0..file_s.len].* = file_s.*;
        var ptr: [*]u8 = buf[file_s.len..];
        if (name[0] != '/') {
            ptr = writeDirFd(ptr, "dir_fd=", dir_fd);
        }
        ptr[0..2].* = ", ".*;
        ptr = CompoundPath.writeDisplayPath(ptr + 2, name);
        ptr[0..must_not_be_file_s.len].* = must_not_be_file_s.*;
        ptr += must_not_be_file_s.len;
        ptr = fmt.strcpyEqu(ptr, describeKind(kind));
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr) -% @intFromPtr(&buf))]);
    }
    fn writeMode(buf: [*]u8, file_mode: Mode) [*]u8 {
        @setRuntimeSafety(false);
        buf[0..5].* = "mode=".*;
        @memset(buf[5..15], '-');
        buf[5] = switch (file_mode.kind) {
            .unknown => '-',
            .directory => 'd',
            .regular => 'f',
            .character_special => 'c',
            .block_special => 'b',
            .socket => 'S',
            .named_pipe => 'p',
            .symbolic_link => 'l',
        };
        if (file_mode.owner.read) buf[6] = 'r';
        if (file_mode.owner.write) buf[7] = 'w';
        if (file_mode.owner.execute) buf[8] = 'x';
        if (file_mode.group.read) buf[9] = 'r';
        if (file_mode.group.write) buf[10] = 'w';
        if (file_mode.group.execute) buf[11] = 'x';
        if (file_mode.other.read) buf[12] = 'r';
        if (file_mode.other.write) buf[13] = 'w';
        if (file_mode.other.execute) buf[14] = 'x';
        return buf + 15;
    }
    fn describeKind(kind: Kind) []const u8 {
        @setRuntimeSafety(false);
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
    pub fn writeStatus(buf: [*]u8, st: *const Status) [*]u8 {
        @setRuntimeSafety(false);
        buf[0..6].* = "inode=".*;
        var ptr: [*]u8 = buf + 6;
        ptr = fmt.writeUd64(ptr, st.ino);
        ptr[0..6].* = ", dev=".*;
        ptr = fmt.writeUd64(ptr + 6, st.dev >> 8);
        ptr[0] = ':';
        ptr = fmt.writeUd64(ptr + 1, st.dev & 0xff);
        ptr[0..2].* = ", ".*;
        ptr = writeMode(ptr + 2, st.mode);
        ptr[0..7].* = ", size=".*;
        ptr = fmt.writeBytes(ptr + 7, st.size);
        return ptr;
    }
    fn writePollFds(buf: [*]u8, pollfds: []PollFd) [*]u8 {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        for (pollfds) |*pollfd| {
            ptr += fmt.writeSideBarIndex(ptr, 4, pollfd.fd);
            ptr = writeEvents(ptr, pollfd, "expect=", 4);
            ptr = writeEvents(ptr, pollfd, " actual=", 6);
            ptr[0] = '\n';
            ptr += 1;
        }
        return ptr;
    }
    fn writeEvents(buf: [*]u8, pollfd: *PollFd, about_s: []const u8, off: usize) [*]u8 {
        @setRuntimeSafety(false);
        const events: Events = @as(*Events, @ptrFromInt(@intFromPtr(pollfd) + off)).*;
        if (@as(u16, @bitCast(events)) == 0) {
            return buf;
        }
        var ptr: [*]u8 = fmt.strcpyEqu(buf, about_s);
        inline for (@typeInfo(Events).Struct.fields) |field| {
            if (field.type != bool) {
                continue;
            }
            if (@field(events, field.name)) {
                ptr = fmt.strcpyEqu(ptr, field.name);
                ptr[0] = ',';
                ptr += 1;
            }
        }
        return ptr;
    }
    pub fn writeArgs(buf: [*]u8, pathname: []const u8, args: []const [*:0]const u8) [*]u8 {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        var idx: usize = 0;
        if (mem.testEqualString(
            pathname,
            mem.terminate(@constCast(args[0]), 0),
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
            ptr = fmt.strcpyEqu(ptr, args[idx][0..arg_len]);
            ptr[0] = ' ';
            ptr += 1;
        }
        if (idx != args.len) {
            ptr[0..9].* = " ... and ".*;
            ptr += 9;
            ptr = fmt.writeUd64(ptr, args.len -% idx);
            ptr[0..16].* = " more args ... \n".*;
            ptr += 16;
        }
        return ptr;
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
        var offset: usize = 4096;
        const name1: [:0]const u8 = "file1";
        const name2: [:0]const u8 = "file2";
        const expect: Events = .{ .input = true };
        const actual: Events = .{ .hangup = true };
        const pollfd: PollFd = .{ .fd = 1, .expect = expect, .actual = actual };
        var pollfds: [3]PollFd = .{pollfd} ** 3;
        const addr: usize = 0x40000000;
        const len: usize = 0x10000;
        var timeout: u64 = 86400;
        var off1: usize = 256;
        var off2: usize = 256;
        aboutFdNotice(about_s, fd1);
        aboutFdModeNotice(about_s, fd1, mode.regular);
        aboutFdLenNotice(about_s, fd1, 4096);
        aboutFdMaxLenLenNotice(about_s, fd1, 8192, 4096);
        aboutFdAddrLenOffsetNotice(about_s, fd1, addr, len, off1);
        aboutPathnameNotice(about_s, pathname1);
        aboutPathnameModeNotice(about_s, pathname1, mode.regular);
        aboutDirFdNameModeNotice(about_s, fd1, name1, mode.regular);
        aboutDirFdNameFdNotice(about_s, dir_fd1, name1, fd1);
        aboutPathnameFdNotice(about_s, pathname1, fd1);
        aboutPathnameFdModeNotice(about_s, pathname1, fd1, mode.regular);
        aboutPathnameModeDeviceNotice(about_s, pathname1, mode.regular, .{ .major = 255, .minor = 1 });
        pollNotice(&pollfds, timeout);
        copyNotice(fd1, &off1, fd2, &off2, 512, 256);
        sendNotice(fd1, fd2, &off2, 512, 256);
        listenNotice(fd1, 100);
        aboutFdFdNotice(about_s, "fd1=", "fd2=", fd1, fd2);
        aboutFdAddrLenOffsetError(about_s, "MapError", fd1, addr, len, off1);
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
        socketError(error.SocketError, .ipv4, .{ .conn = .tcp });
        sendError(error.SendError, fd1, fd2, &offset, 256);
        copyError(error.CopyError, fd1, &offset, fd2, &offset, 512);
        seekError(error.SeekError, fd1, offset, .set);
        listenError(error.ListenError, fd1, 100);
        executeError(error.ExecError, name1, &.{});
    }
};
pub const spec = struct {
    pub const bind = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,   .ADDRINUSE, .BADF,         .INVAL,
                .NOTSOCK, .ACCES,     .ADDRNOTAVAIL, .FAULT,
                .LOOP,
            };
        };
    };
    pub const recv = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .BADF,  .CONNREFUSED, .FAULT,   .INTR,
                .INVAL, .NOMEM, .NOTCONN,     .NOTSOCK,
            };
        };
    };
    pub const send = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,     .AGAIN,       .ALREADY, .BADF,
                .CONNRESET, .DESTADDRREQ, .FAULT,   .INTR,
                .INVAL,     .ISCONN,      .MSGSIZE, .NOBUFS,
                .NOMEM,     .NOTCONN,     .NOTSOCK, .OPNOTSUPP,
                .PIPE,
            };
        };
    };
    pub const connect = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,      .PERM,        .ADDRINUSE, .ADDRNOTAVAIL, .AGAIN, .ALREADY,
                .BADF,       .CONNREFUSED, .FAULT,     .INPROGRESS,   .INTR,  .ISCONN,
                .NETUNREACH, .NOTSOCK,     .PROTOTYPE, .TIMEDOUT,
            };
        };
    };
    pub const copy_file_range = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF,  .FBIG,      .INVAL,    .IO,   .ISDIR,  .NOMEM,
                .NOSPC, .OPNOTSUPP, .OVERFLOW, .PERM, .TXTBSY, .XDEV,
            };
        };
    };
    pub const sendfile = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .FAULT,    .INVAL, .IO,
                .NOMEM, .OVERFLOW, .SPIPE,
            };
        };
    };
    pub const sync = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .IO };
        };
    };
    pub const getrandom = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
            };
        };
    };
    pub const chdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
            };
        };
    };
    pub const open = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FBIG,        .NOTDIR,   .EXIST,  .OPNOTSUPP, .MFILE, .NOSPC,
                .NOENT, .NAMETOOLONG, .OVERFLOW, .TXTBSY, .AGAIN,     .BADF,  .ISDIR,
                .LOOP,  .NODEV,       .DQUOT,    .NOMEM,  .ROFS,      .NFILE, .INTR,
                .PERM,  .FAULT,       .INVAL,    .NXIO,   .BUSY,      .STALE,
            };
        };
    };
    pub const read = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
            };
        };
    };
    pub const clock_gettime = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
            };
        };
    };
    pub const execve = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
                .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
                .INVAL, .NOEXEC,
            };
        };
    };
    pub const fork = struct {
        pub const errors = struct {
            pub const all = &.{
                .NOSYS, .AGAIN, .NOMEM, .RESTART,
            };
        };
    };
    pub const getcwd = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
            };
        };
    };
    pub const getdents = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
            };
        };
    };
    pub const dup = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const dup2 = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const dup3 = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const poll = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INTR, .INVAL, .NOMEM,
            };
        };
    };
    pub const ioctl = struct {
        pub const errors = struct {
            pub const all = &.{
                .NOTTY, .BADF, .FAULT, .INVAL,
            };
        };
    };
    pub const mkdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
            };
            pub const noexcl = &.{
                .ACCES,       .BADF,  .DQUOT, .FAULT, .INVAL,  .LOOP, .MLINK,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM, .ROFS,
            };
        };
    };
    pub const memfd_create = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INVAL, .MFILE, .NOMEM,
            };
        };
    };
    pub const truncate = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,  .FAULT, .FBIG, .INTR,   .IO,    .ISDIR, .LOOP, .NAMETOOLONG,
                .NOTDIR, .PERM,  .ROFS, .TXTBSY, .INVAL, .BADF,
            };
        };
    };
    pub const mknod = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
            };
        };
    };
    pub const link = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .IO,   .LOOP,  .NAMETOOLONG,
                .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS, .MLINK, .XDEV,
                .INVAL,
            };
        };
    };
    pub const readlink = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .FAULT, .INVAL,  .IO, .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR,
            };
        };
    };
    pub const rmdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BUSY,  .FAULT,  .INVAL,    .LOOP, .NAMETOOLONG,
                .NOENT, .NOMEM, .NOTDIR, .NOTEMPTY, .PERM, .ROFS,
            };
        };
    };
    pub const socket = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .NXIO, .OVERFLOW, .SPIPE };
        };
    };
    pub const seek = struct {
        pub const errors = struct {
            pub const all = &.{ .ACCES, .AFNOSUPPORT, .INVAL, .MFILE, .NOBUFS, .NOMEM, .PROTONOSUPPORT };
        };
    };
    pub const stat = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .FAULT, .INVAL,  .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR, .OVERFLOW,
            };
            pub const all_noent = &.{
                .ACCES,       .BADF,  .FAULT,  .INVAL,    .LOOP,
                .NAMETOOLONG, .NOMEM, .NOTDIR, .OVERFLOW,
            };
        };
    };
    pub const unlink = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BUSY,  .FAULT,  .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
                .NOENT, .NOMEM, .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
            };
            pub const all_noent = &.{
                .ACCES, .BUSY,   .FAULT, .IO,   .ISDIR, .LOOP,  .NAMETOOLONG,
                .NOMEM, .NOTDIR, .PERM,  .ROFS, .BADF,  .INVAL,
            };
        };
    };
    pub const write = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .BADF,  .DESTADDRREQ, .DQUOT, .FAULT, .FBIG,
                .INTR,  .INVAL, .IO,          .NOSPC, .PERM,  .PIPE,
            };
        };
    };
    pub const pipe = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INVAL, .MFILE, .NFILE, .NOPKG,
            };
        };
    };
    pub const listen = struct {
        pub const errors = struct {
            pub const all = &.{ .INVAL, .ADDRINUSE, .BADF, .NOTSOCK, .OPNOTSUPP };
        };
    };
    pub const accept = struct {
        pub const errors = struct {
            pub const all = &.{ .AGAIN, .BADF, .CONNABORTED, .FAULT, .INTR, .INVAL, .MFILE, .NFILE, .NOBUFS, .NOMEM, .NOTSOCK, .OPNOTSUPP, .PERM, .PROTO };
        };
    };
    pub const getsockname = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .FAULT, .INVAL, .NOBUFS, .NOTSOCK };
        };
    };
    pub const getpeername = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .FAULT, .INVAL, .NOBUFS, .NOTCONN, .NOTSOCK };
        };
    };
    pub const sockopt = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .FAULT, .INVAL, .NOPROTOOPT, .NOTSOCK };
        };
    };
    pub const shutdown = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .INVAL, .NOTCONN, .NOTSOCK };
        };
    };
    pub const close = struct {
        pub const errors = struct {
            pub const all = &.{
                .INTR, .IO, .BADF, .NOSPC,
            };
        };
    };
    pub const access = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .FAULT, .INVAL,  .IO,   .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR, .PERM, .ROFS,
                .TXTBSY,
            };
        };
    };
    pub const statx = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,  .BADF,        .FAULT, .INVAL,
                .LOOP,   .NAMETOOLONG, .NOENT, .NOMEM,
                .NOTDIR,
            };
        };
    };
    pub const dir = struct {
        pub const options = struct {
            pub const eager: DirStreamSpec.Options = .{
                .init_read_all = true,
                .shrink_after_read = true,
                .make_list = true,
                .close_on_deinit = true,
            };
            pub const lazy: DirStreamSpec.Options = .{
                .init_read_all = false,
                .shrink_after_read = false,
                .make_list = false,
                .close_on_deinit = false,
            };
        };
        pub const logging = struct {
            pub const silent: DirStreamSpec.Logging = builtin.zero(DirStreamSpec.Logging);
            pub const verbose: DirStreamSpec.Logging = builtin.all(DirStreamSpec.Logging);
        };
        pub const errors = struct {
            pub const zen: DirStreamSpec.Errors = .{
                .open = .{ .throw = sys.open.errors.all },
                .close = .{ .abort = sys.open.errors.all },
                .getdents = .{ .throw = sys.getdents.errors.all },
            };
            pub const noexcept: DirStreamSpec.Errors = .{
                .open = .{},
                .close = .{},
                .getdents = .{},
            };
            pub const critical: DirStreamSpec.Errors = .{
                .open = .{ .throw = sys.open.errors.all },
                .close = .{ .throw = sys.open.errors.all },
                .getdents = .{ .throw = sys.getdents.errors.all },
            };
        };
    };
};
// * Add `executeNoticeBrief`
