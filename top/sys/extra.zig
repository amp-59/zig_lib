pub const MemMap = struct {
    pub const default_values = struct {
        pub const SHARED = false;
        pub const PRIVATE = true;
        pub const SHARED_VALIDATE = false;
        pub const FIXED = false;
        pub const ANONYMOUS = true;
        pub const GROWSDOWN = false;
        pub const DENYWRITE = false;
        pub const EXECUTABLE = false;
        pub const LOCKED = false;
        pub const NORESERVE = false;
        pub const POPULATE = false;
        pub const NONBLOCK = false;
        pub const STACK = false;
        pub const HUGETLB = false;
        pub const SYNC = false;
        pub const FIXED_NOREPLACE = true;
    };
    pub const field_names = struct {
        pub const SHARED = "shared";
        pub const PRIVATE = "private";
        pub const SHARED_VALIDATE = "shared_validate";
        pub const FIXED = "fixed";
        pub const ANONYMOUS = "anonymous";
        pub const GROWSDOWN = "grows_down";
        pub const DENYWRITE = "deny_write";
        pub const EXECUTABLE = "executable";
        pub const LOCKED = "locked";
        pub const NORESERVE = "no_reserve";
        pub const POPULATE = "populate";
        pub const NONBLOCK = "non_block";
        pub const STACK = "stack";
        pub const HUGETLB = "hugetlb";
        pub const SYNC = "sync";
        pub const FIXED_NOREPLACE = "fixed_noreplace";
    };
    pub const set_names = .{
        "visibility",
    };
    pub const backing_integer = usize;
};
pub const FileMap = struct {
    pub const default_values = struct {
        pub const SHARED = false;
        pub const PRIVATE = true;
        pub const SHARED_VALIDATE = false;
        pub const FIXED = true;
        pub const ANONYMOUS = false;
        pub const GROWSDOWN = false;
        pub const DENYWRITE = false;
        pub const EXECUTABLE = false;
        pub const LOCKED = false;
        pub const NORESERVE = false;
        pub const POPULATE = false;
        pub const NONBLOCK = false;
        pub const STACK = false;
        pub const HUGETLB = false;
        pub const SYNC = false;
        pub const FIXED_NOREPLACE = false;
    };
    pub const field_names = struct {
        pub const SHARED = "shared";
        pub const PRIVATE = "private";
        pub const SHARED_VALIDATE = "shared_validate";
        pub const FIXED = "fixed";
        pub const ANONYMOUS = "anonymous";
        pub const GROWSDOWN = "grows_down";
        pub const DENYWRITE = "deny_write";
        pub const EXECUTABLE = "executable";
        pub const LOCKED = "locked";
        pub const NORESERVE = "no_reserve";
        pub const POPULATE = "populate";
        pub const NONBLOCK = "non_block";
        pub const STACK = "stack";
        pub const HUGETLB = "hugetlb";
        pub const SYNC = "sync";
        pub const FIXED_NOREPLACE = "fixed_noreplace";
    };
    pub const set_names = .{
        "visibility",
    };
    pub const backing_integer = usize;
};
pub const MemFd = struct {
    pub const default_values = struct {
        pub const CLOEXEC = false;
        pub const ALLOW_SEALING = false;
        pub const HUGETLB = false;
    };
    pub const field_names = struct {
        pub const CLOEXEC = "close_on_exec";
        pub const ALLOW_SEALING = "allow_sealing";
        pub const HUGETLB = "hugetlb";
    };
    pub const backing_integer = usize;
};
pub const MemSync = struct {
    pub const default_values = struct {
        pub const ASYNC = false;
        pub const INVALIDATE = false;
        pub const SYNC = false;
    };
    pub const field_names = struct {
        pub const ASYNC = "async";
        pub const INVALIDATE = "invalidate";
        pub const SYNC = "sync";
    };
    pub const backing_integer = usize;
};
pub const MemProt = struct {
    pub const default_values = struct {
        pub const NONE = false;
        pub const READ = true;
        pub const WRITE = true;
        pub const EXEC = false;
        pub const GROWSDOWN = false;
        pub const GROWSUP = false;
    };
    pub const field_names = struct {
        pub const NONE = "none";
        pub const READ = "read";
        pub const WRITE = "write";
        pub const EXEC = "exec";
        pub const GROWSDOWN = "grows_down";
        pub const GROWSUP = "grows_up";
    };
    pub const backing_integer = usize;
};
pub const Remap = struct {
    pub const default_values = struct {
        pub const RESIZE = false;
        pub const MAYMOVE = false;
        pub const FIXED = false;
        pub const DONTUNMAP = false;
    };
    pub const field_names = struct {
        pub const RESIZE = "resize";
        pub const MAYMOVE = "may_move";
        pub const FIXED = "fixed";
        pub const DONTUNMAP = "no_unmap";
    };
    pub const backing_integer = usize;
};
pub const MAdvise = struct {
    pub const default_values = struct {
        pub const NORMAL = false;
        pub const RANDOM = false;
        pub const SEQUENTIAL = false;
        pub const WILLNEED = false;
        pub const DONTNEED = false;
        pub const FREE = false;
        pub const REMOVE = false;
        pub const DONTFORK = false;
        pub const DOFORK = false;
        pub const MERGEABLE = false;
        pub const UNMERGEABLE = false;
        pub const HUGEPAGE = false;
        pub const NOHUGEPAGE = false;
        pub const DONTDUMP = false;
        pub const DODUMP = false;
        pub const WIPEONFORK = false;
        pub const KEEPONFORK = false;
        pub const COLD = false;
        pub const PAGEOUT = false;
        pub const HWPOISON = false;
    };
    pub const field_names = struct {
        pub const NORMAL = "normal";
        pub const RANDOM = "random";
        pub const SEQUENTIAL = "sequential";
        pub const WILLNEED = "do_need";
        pub const DONTNEED = "do_not_need";
        pub const FREE = "free";
        pub const REMOVE = "remove";
        pub const DONTFORK = "do_not_fork";
        pub const DOFORK = "do_fork";
        pub const MERGEABLE = "mergeable";
        pub const UNMERGEABLE = "unmergeable";
        pub const HUGEPAGE = "hugepage";
        pub const NOHUGEPAGE = "no_hugepage";
        pub const DONTDUMP = "do_not_dump";
        pub const DODUMP = "do_dump";
        pub const WIPEONFORK = "wipe_on_fork";
        pub const KEEPONFORK = "keep_on_fork";
        pub const COLD = "cold";
        pub const PAGEOUT = "pageout";
        pub const HWPOISON = "hw_poison";
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const MCL = struct {
    pub const default_values = struct {
        pub const CURRENT = false;
        pub const FUTURE = false;
        pub const ONFAULT = false;
    };
    pub const field_names = struct {
        pub const CURRENT = "current";
        pub const FUTURE = "future";
        pub const ONFAULT = "on_fault";
    };
    pub const backing_integer = usize;
};
pub const Open = struct {
    pub const default_values = struct {
        pub const LARGEFILE = false;
        pub const RDONLY = false;
        pub const WRONLY = false;
        pub const RDWR = false;
        pub const CREAT = false;
        pub const EXCL = false;
        pub const NOCTTY = false;
        pub const TRUNC = false;
        pub const APPEND = false;
        pub const NONBLOCK = false;
        pub const DSYNC = false;
        pub const ASYNC = false;
        pub const DIRECT = false;
        pub const DIRECTORY = false;
        pub const NOFOLLOW = false;
        pub const NOATIME = false;
        pub const CLOEXEC = false;
        pub const PATH = false;
        pub const TMPFILE = false;
    };
    pub const field_names = struct {
        pub const LARGEFILE = "large_file";
        pub const RDONLY = "read_only";
        pub const WRONLY = "write_only";
        pub const RDWR = "read_write";
        pub const CREAT = "create";
        pub const EXCL = "exclusive";
        pub const NOCTTY = "no_ctty";
        pub const TRUNC = "truncate";
        pub const APPEND = "append";
        pub const NONBLOCK = "non_block";
        pub const DSYNC = "data_sync";
        pub const ASYNC = "async";
        pub const DIRECT = "direct";
        pub const DIRECTORY = "directory";
        pub const NOFOLLOW = "no_follow";
        pub const NOATIME = "no_atime";
        pub const CLOEXEC = "close_on_exec";
        pub const PATH = "path";
        pub const TMPFILE = "tmpfile";
    };
    pub const backing_integer = usize;
};
pub const Lock = struct {
    pub const default_values = struct {
        pub const SH = false;
        pub const EX = false;
        pub const NB = false;
        pub const UN = false;
    };
    const _field_names = struct {
        pub const SH = 
            \\sh
        ;
        pub const EX = 
            \\ex
        ;
        pub const NB = 
            \\nb
        ;
        pub const UN = 
            \\un
        ;
    };
    pub const backing_integer = usize;
};
pub const Clone = struct {
    pub const default_values = struct {
        pub const CLEAR_SIGHAND = false;
        pub const INTO_CGROUP = false;
        pub const NEWTIME = false;
        pub const VM = true;
        pub const FS = true;
        pub const FILES = true;
        pub const SIGHAND = true;
        pub const PIDFD = false;
        pub const PTRACE = false;
        pub const VFORK = false;
        pub const THREAD = true;
        pub const NEWNS = false;
        pub const SYSVSEM = true;
        pub const SETTLS = false;
        pub const PARENT_SETTID = true;
        pub const CHILD_CLEARTID = true;
        pub const DETACHED = false;
        pub const UNTRACED = false;
        pub const CHILD_SETTID = true;
        pub const NEWCGROUP = false;
        pub const NEWUTS = false;
        pub const NEWIPC = false;
        pub const NEWUSER = false;
        pub const NEWPID = false;
        pub const NEWNET = false;
        pub const IO = false;
    };
    pub const field_names = struct {
        pub const CLEAR_SIGHAND = "clear_signal_handlers";
        pub const NEWTIME = "new_time";
        pub const VM = "vm";
        pub const FS = "fs";
        pub const FILES = "files";
        pub const SIGHAND = "signal_handlers";
        pub const PIDFD = "pid_fd";
        pub const PTRACE = "trace_child";
        pub const VFORK = "vfork";
        pub const THREAD = "thread";
        pub const NEWNS = "new_namespace";
        pub const SYSVSEM = "sysvsem";
        pub const SETTLS = "set_thread_local_storage";
        pub const PARENT_SETTID = "set_parent_thread_id";
        pub const CHILD_CLEARTID = "clear_child_thread_id";
        pub const DETACHED = "detached";
        pub const UNTRACED = "untraced";
        pub const CHILD_SETTID = "set_child_thread_id";
        pub const NEWCGROUP = "new_cgroup";
        pub const NEWUTS = "new_uts";
        pub const NEWIPC = "new_ipc";
        pub const NEWUSER = "new_user";
        pub const NEWPID = "new_pid";
        pub const NEWNET = "new_net";
        pub const IO = "io";
    };
    pub const backing_integer = usize;
};
pub const Id = struct {
    pub const default_values = struct {
        pub const ALL = false;
        pub const PID = false;
        pub const PGID = false;
        pub const PIDFD = false;
    };
    pub const field_names = struct {
        pub const ALL = "all";
        pub const PID = "pid";
        pub const PGID = "pgid";
        pub const PIDFD = "pidfd";
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const Wait = struct {
    pub const default_values = struct {
        pub const NOHANG = false;
        pub const STOPPED = false;
        pub const EXITED = false;
        pub const CONTINUED = false;
        pub const NOWAIT = false;
        pub const NOTHREAD = false;
        pub const ALL = false;
        pub const CLONE = false;
    };
    pub const field_names = struct {
        pub const NOHANG = "no_hang";
        pub const STOPPED = "stopped";
        pub const EXITED = "exited";
        pub const CONTINUED = "continued";
        pub const NOWAIT = "no_wait";
        pub const NOTHREAD = "no_thread";
        pub const ALL = "all";
        pub const CLONE = "clone";
    };
    pub const backing_integer = usize;
};
pub const Shut = struct {
    pub const default_values = struct {
        pub const RD = false;
        pub const WR = false;
        pub const RDWR = false;
    };
    pub const field_names = struct {
        pub const RD = "read";
        pub const WR = "write";
        pub const RDWR = "read_write";
    };
    pub const backing_integer = usize;
};
pub const MountAttr = struct {
    pub const default_values = struct {
        pub const RELATIME = false;
        pub const RDONLY = false;
        pub const NOSUID = false;
        pub const NODEV = false;
        pub const NOEXEC = false;
        pub const NOATIME = false;
        pub const STRICTATIME = false;
        pub const NODIRATIME = false;
        pub const IDMAP = false;
    };
    pub const field_names = struct {
        pub const RELATIME = "relatime";
        pub const RDONLY = "read_only";
        pub const NOSUID = "no_suid";
        pub const NODEV = "no_dev";
        pub const NOEXEC = "no_exec";
        pub const NOATIME = "no_atime";
        pub const STRICTATIME = "strict_atime";
        pub const NODIRATIME = "no_dir_atime";
        pub const IDMAP = "id_map";
    };
    pub const backing_integer = usize;
};
pub const PTrace = struct {
    pub const default_values = struct {
        pub const GETREGSET = false;
        pub const SETREGSET = false;
        pub const SEIZE = false;
        pub const INTERRUPT = false;
        pub const LISTEN = false;
        pub const PEEKSIGINFO = false;
        pub const GETSIGMASK = false;
        pub const SETSIGMASK = false;
        pub const SECCOMP_GET_FILTER = false;
        pub const GET_SYSCALL_INFO = false;
    };
    pub const field_names = struct {
        pub const GETREGSET = "get_regset";
        pub const SETREGSET = "set_regset";
        pub const SEIZE = "seize";
        pub const INTERRUPT = "interrupt";
        pub const LISTEN = "listen";
        pub const PEEKSIGINFO = "peek_siginfo";
        pub const GETSIGMASK = "get_sigmask";
        pub const SETSIGMASK = "set_sigmask";
        pub const SECCOMP_GET_FILTER = "seccomp_get_filter";
        pub const GET_SYSCALL_INFO = "get_syscall_info";
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const AF = struct {
    pub const default_values = struct {
        pub const UNIX = false;
        pub const INET = false;
        pub const INET6 = false;
        pub const NETLINK = false;
    };
    const _field_names = struct {
        pub const UNIX = 
            \\unix
        ;
        pub const INET = 
            \\inet
        ;
        pub const INET6 = 
            \\inet6
        ;
        pub const NETLINK = 
            \\netlink
        ;
    };
    pub const backing_integer = usize;
};
pub const SOCK = struct {
    pub const default_values = struct {
        pub const STREAM = false;
        pub const DGRAM = false;
        pub const RAW = false;
        pub const NONBLOCK = false;
        pub const CLOEXEC = false;
    };
    const _field_names = struct {
        pub const STREAM = 
            \\stream
        ;
        pub const DGRAM = 
            \\dgram
        ;
        pub const RAW = 
            \\raw
        ;
        pub const NONBLOCK = 
            \\nonblock
        ;
        pub const CLOEXEC = 
            \\cloexec
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const IPPROTO = struct {
    pub const default_values = struct {
        pub const IP = false;
        pub const HOPOPTS = false;
        pub const ICMP = false;
        pub const IGMP = false;
        pub const IPIP = false;
        pub const TCP = false;
        pub const EGP = false;
        pub const PUP = false;
        pub const UDP = false;
        pub const IDP = false;
        pub const TP = false;
        pub const DCCP = false;
        pub const IPV6 = false;
        pub const ROUTING = false;
        pub const FRAGMENT = false;
        pub const RSVP = false;
        pub const GRE = false;
        pub const ESP = false;
        pub const AH = false;
        pub const ICMPV6 = false;
        pub const NONE = false;
        pub const DSTOPTS = false;
        pub const MTP = false;
        pub const BEETPH = false;
        pub const ENCAP = false;
        pub const PIM = false;
        pub const COMP = false;
        pub const L2TP = false;
        pub const SCTP = false;
        pub const MH = false;
        pub const UDPLITE = false;
        pub const MPLS = false;
        pub const ETHERNET = false;
        pub const RAW = false;
        pub const MPTCP = false;
        pub const MAX = false;
    };
    const _field_names = struct {
        pub const IP = 
            \\ip
        ;
        pub const HOPOPTS = 
            \\hopopts
        ;
        pub const ICMP = 
            \\icmp
        ;
        pub const IGMP = 
            \\igmp
        ;
        pub const IPIP = 
            \\ipip
        ;
        pub const TCP = 
            \\tcp
        ;
        pub const EGP = 
            \\egp
        ;
        pub const PUP = 
            \\pup
        ;
        pub const UDP = 
            \\udp
        ;
        pub const IDP = 
            \\idp
        ;
        pub const TP = 
            \\tp
        ;
        pub const DCCP = 
            \\dccp
        ;
        pub const IPV6 = 
            \\ipv6
        ;
        pub const ROUTING = 
            \\routing
        ;
        pub const FRAGMENT = 
            \\fragment
        ;
        pub const RSVP = 
            \\rsvp
        ;
        pub const GRE = 
            \\gre
        ;
        pub const ESP = 
            \\esp
        ;
        pub const AH = 
            \\ah
        ;
        pub const ICMPV6 = 
            \\icmpv6
        ;
        pub const NONE = 
            \\none
        ;
        pub const DSTOPTS = 
            \\dstopts
        ;
        pub const MTP = 
            \\mtp
        ;
        pub const BEETPH = 
            \\beetph
        ;
        pub const ENCAP = 
            \\encap
        ;
        pub const PIM = 
            \\pim
        ;
        pub const COMP = 
            \\comp
        ;
        pub const L2TP = 
            \\l2tp
        ;
        pub const SCTP = 
            \\sctp
        ;
        pub const MH = 
            \\mh
        ;
        pub const UDPLITE = 
            \\udplite
        ;
        pub const MPLS = 
            \\mpls
        ;
        pub const ETHERNET = 
            \\ethernet
        ;
        pub const RAW = 
            \\raw
        ;
        pub const MPTCP = 
            \\mptcp
        ;
        pub const MAX = 
            \\max
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const IPPORT = struct {
    pub const default_values = struct {
        pub const ECHO = false;
        pub const DISCARD = false;
        pub const SYSTAT = false;
        pub const DAYTIME = false;
        pub const NETSTAT = false;
        pub const FTP = false;
        pub const TELNET = false;
        pub const SMTP = false;
        pub const TIMESERVER = false;
        pub const NAMESERVER = false;
        pub const WHOIS = false;
        pub const MTP = false;
        pub const TFTP = false;
        pub const RJE = false;
        pub const FINGER = false;
        pub const TTYLINK = false;
        pub const SUPDUP = false;
        pub const EXECSERVER = false;
        pub const LOGINSERVER = false;
        pub const CMDSERVER = false;
        pub const EFSSERVER = false;
        pub const USERRESERVED = false;
        pub const RESERVED = false;
    };
    const _field_names = struct {
        pub const ECHO = 
            \\echo
        ;
        pub const DISCARD = 
            \\discard
        ;
        pub const SYSTAT = 
            \\systat
        ;
        pub const DAYTIME = 
            \\daytime
        ;
        pub const NETSTAT = 
            \\netstat
        ;
        pub const FTP = 
            \\ftp
        ;
        pub const TELNET = 
            \\telnet
        ;
        pub const SMTP = 
            \\smtp
        ;
        pub const TIMESERVER = 
            \\timeserver
        ;
        pub const NAMESERVER = 
            \\nameserver
        ;
        pub const WHOIS = 
            \\whois
        ;
        pub const MTP = 
            \\mtp
        ;
        pub const TFTP = 
            \\tftp
        ;
        pub const RJE = 
            \\rje
        ;
        pub const FINGER = 
            \\finger
        ;
        pub const TTYLINK = 
            \\ttylink
        ;
        pub const SUPDUP = 
            \\supdup
        ;
        pub const EXECSERVER = 
            \\execserver
        ;
        pub const LOGINSERVER = 
            \\loginserver
        ;
        pub const CMDSERVER = 
            \\cmdserver
        ;
        pub const EFSSERVER = 
            \\efsserver
        ;
        pub const USERRESERVED = 
            \\userreserved
        ;
        pub const RESERVED = 
            \\reserved
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const SignalAction = struct {
    pub const default_values = struct {
        pub const NOCLDSTOP = false;
        pub const NOCLDWAIT = false;
        pub const SIGINFO = true;
        pub const UNSUPPORTED = false;
        pub const EXPOSE_TAGBITS = false;
        pub const RESTORER = true;
        pub const ONSTACK = false;
        pub const RESTART = true;
        pub const NODEFER = false;
        pub const RESETHAND = true;
    };
    pub const field_names = struct {
        pub const NOCLDSTOP = "no_child_stop";
        pub const NOCLDWAIT = "no_child_wait";
        pub const SIGINFO = "siginfo";
        pub const UNSUPPORTED = "unsupported";
        pub const EXPOSE_TAGBITS = "expose_tagbits";
        pub const RESTORER = "restorer";
        pub const ONSTACK = "on_stack";
        pub const RESTART = "restart";
        pub const NODEFER = "no_defer";
        pub const RESETHAND = "reset_handler";
    };
    pub const backing_integer = usize;
};
pub const SignalStack = struct {
    pub const default_values = struct {
        pub const ONSTACK = false;
        pub const DISABLE = false;
        pub const AUTODISARM = false;
    };
    pub const field_names = struct {
        pub const ONSTACK = "on_stack";
        pub const DISABLE = "disable";
        pub const AUTODISARM = "auto_disarm";
    };
    pub const backing_integer = u32;
};
pub const Signal = struct {
    pub const default_values = struct {
        pub const DFL = false;
        pub const HUP = false;
        pub const INT = false;
        pub const QUIT = false;
        pub const ILL = false;
        pub const TRAP = false;
        pub const ABRT = false;
        pub const BUS = false;
        pub const FPE = false;
        pub const KILL = false;
        pub const USR1 = false;
        pub const SEGV = false;
        pub const USR2 = false;
        pub const PIPE = false;
        pub const ALRM = false;
        pub const TERM = false;
        pub const STKFLT = false;
        pub const CHLD = false;
        pub const CONT = false;
        pub const STOP = false;
        pub const TSTP = false;
        pub const TTIN = false;
        pub const TTOU = false;
        pub const URG = false;
        pub const XCPU = false;
        pub const XFSZ = false;
        pub const VTALRM = false;
        pub const PROF = false;
        pub const WINCH = false;
        pub const IO = false;
        pub const PWR = false;
        pub const SYS = false;
    };
    const _field_names = struct {
        pub const DFL = 
            \\dfl
        ;
        pub const HUP = 
            \\hup
        ;
        pub const INT = 
            \\int
        ;
        pub const QUIT = 
            \\quit
        ;
        pub const ILL = 
            \\ill
        ;
        pub const TRAP = 
            \\trap
        ;
        pub const ABRT = 
            \\abrt
        ;
        pub const BUS = 
            \\bus
        ;
        pub const FPE = 
            \\fpe
        ;
        pub const KILL = 
            \\kill
        ;
        pub const USR1 = 
            \\usr1
        ;
        pub const SEGV = 
            \\segv
        ;
        pub const USR2 = 
            \\usr2
        ;
        pub const PIPE = 
            \\pipe
        ;
        pub const ALRM = 
            \\alrm
        ;
        pub const TERM = 
            \\term
        ;
        pub const STKFLT = 
            \\stkflt
        ;
        pub const CHLD = 
            \\chld
        ;
        pub const CONT = 
            \\cont
        ;
        pub const STOP = 
            \\stop
        ;
        pub const TSTP = 
            \\tstp
        ;
        pub const TTIN = 
            \\ttin
        ;
        pub const TTOU = 
            \\ttou
        ;
        pub const URG = 
            \\urg
        ;
        pub const XCPU = 
            \\xcpu
        ;
        pub const XFSZ = 
            \\xfsz
        ;
        pub const VTALRM = 
            \\vtalrm
        ;
        pub const PROF = 
            \\prof
        ;
        pub const WINCH = 
            \\winch
        ;
        pub const IO = 
            \\io
        ;
        pub const PWR = 
            \\pwr
        ;
        pub const SYS = 
            \\sys
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const TIOC = struct {
    pub const default_values = struct {
        pub const PKT_DATA = false;
        pub const PKT_FLUSHREAD = false;
        pub const PKT_FLUSHWRITE = false;
        pub const PKT_STOP = false;
        pub const PKT_START = false;
        pub const PKT_NOSTOP = false;
        pub const PKT_DOSTOP = false;
        pub const PKT_IOCTL = false;
        pub const EXCL = false;
        pub const NXCL = false;
        pub const SCTTY = false;
        pub const GPGRP = false;
        pub const SPGRP = false;
        pub const OUTQ = false;
        pub const STI = false;
        pub const GWINSZ = false;
        pub const SWINSZ = false;
        pub const MGET = false;
        pub const MBIS = false;
        pub const MBIC = false;
        pub const MSET = false;
        pub const GSOFTCAR = false;
        pub const SSOFTCAR = false;
        pub const INQ = false;
        pub const LINUX = false;
        pub const CONS = false;
        pub const GSERIAL = false;
        pub const SSERIAL = false;
        pub const PKT = false;
        pub const NOTTY = false;
        pub const SETD = false;
        pub const GETD = false;
        pub const SBRK = false;
        pub const CBRK = false;
        pub const GSID = false;
        pub const GRS485 = false;
        pub const SRS485 = false;
        pub const SERCONFIG = false;
        pub const SERGWILD = false;
        pub const SERSWILD = false;
        pub const GLCKTRMIOS = false;
        pub const SLCKTRMIOS = false;
        pub const SERGSTRUCT = false;
        pub const SERGETLSR = false;
        pub const SERGETMULTI = false;
        pub const SERSETMULTI = false;
        pub const MIWAIT = false;
        pub const GICOUNT = false;
    };
    const _field_names = struct {
        pub const PKT_DATA = 
            \\pkt_data
        ;
        pub const PKT_FLUSHREAD = 
            \\pkt_flushread
        ;
        pub const PKT_FLUSHWRITE = 
            \\pkt_flushwrite
        ;
        pub const PKT_STOP = 
            \\pkt_stop
        ;
        pub const PKT_START = 
            \\pkt_start
        ;
        pub const PKT_NOSTOP = 
            \\pkt_nostop
        ;
        pub const PKT_DOSTOP = 
            \\pkt_dostop
        ;
        pub const PKT_IOCTL = 
            \\pkt_ioctl
        ;
        pub const EXCL = 
            \\excl
        ;
        pub const NXCL = 
            \\nxcl
        ;
        pub const SCTTY = 
            \\sctty
        ;
        pub const GPGRP = 
            \\gpgrp
        ;
        pub const SPGRP = 
            \\spgrp
        ;
        pub const OUTQ = 
            \\outq
        ;
        pub const STI = 
            \\sti
        ;
        pub const GWINSZ = 
            \\gwinsz
        ;
        pub const SWINSZ = 
            \\swinsz
        ;
        pub const MGET = 
            \\mget
        ;
        pub const MBIS = 
            \\mbis
        ;
        pub const MBIC = 
            \\mbic
        ;
        pub const MSET = 
            \\mset
        ;
        pub const GSOFTCAR = 
            \\gsoftcar
        ;
        pub const SSOFTCAR = 
            \\ssoftcar
        ;
        pub const INQ = 
            \\inq
        ;
        pub const LINUX = 
            \\linux
        ;
        pub const CONS = 
            \\cons
        ;
        pub const GSERIAL = 
            \\gserial
        ;
        pub const SSERIAL = 
            \\sserial
        ;
        pub const PKT = 
            \\pkt
        ;
        pub const NOTTY = 
            \\notty
        ;
        pub const SETD = 
            \\setd
        ;
        pub const GETD = 
            \\getd
        ;
        pub const SBRK = 
            \\sbrk
        ;
        pub const CBRK = 
            \\cbrk
        ;
        pub const GSID = 
            \\gsid
        ;
        pub const GRS485 = 
            \\grs485
        ;
        pub const SRS485 = 
            \\srs485
        ;
        pub const SERCONFIG = 
            \\serconfig
        ;
        pub const SERGWILD = 
            \\sergwild
        ;
        pub const SERSWILD = 
            \\serswild
        ;
        pub const GLCKTRMIOS = 
            \\glcktrmios
        ;
        pub const SLCKTRMIOS = 
            \\slcktrmios
        ;
        pub const SERGSTRUCT = 
            \\sergstruct
        ;
        pub const SERGETLSR = 
            \\sergetlsr
        ;
        pub const SERGETMULTI = 
            \\sergetmulti
        ;
        pub const SERSETMULTI = 
            \\sersetmulti
        ;
        pub const MIWAIT = 
            \\miwait
        ;
        pub const GICOUNT = 
            \\gicount
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const FIO = struct {
    pub const default_values = struct {
        pub const NBIO = false;
        pub const NCLEX = false;
        pub const CLEX = false;
        pub const ASYNC = false;
        pub const QSIZE = false;
    };
    const _field_names = struct {
        pub const NBIO = 
            \\nbio
        ;
        pub const NCLEX = 
            \\nclex
        ;
        pub const CLEX = 
            \\clex
        ;
        pub const ASYNC = 
            \\async
        ;
        pub const QSIZE = 
            \\qsize
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const UTIME = struct {
    pub const default_values = struct {
        pub const OMIT = false;
        pub const NOW = false;
    };
    const _field_names = struct {
        pub const OMIT = 
            \\omit
        ;
        pub const NOW = 
            \\now
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const Seek = struct {
    pub const default_values = struct {
        pub const SET = false;
        pub const CUR = false;
        pub const END = false;
        pub const DATA = false;
        pub const HOLE = false;
    };
    pub const field_names = struct {
        pub const SET = "set";
        pub const CUR = "cur";
        pub const END = "end";
        pub const DATA = "data";
        pub const HOLE = "hole";
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const STATX = struct {
    pub const default_values = struct {
        pub const TYPE = false;
        pub const MODE = false;
        pub const NLINK = false;
        pub const UID = false;
        pub const GID = false;
        pub const ATIME = false;
        pub const MTIME = false;
        pub const CTIME = false;
        pub const INO = false;
        pub const SIZE = false;
        pub const BLOCKS = false;
        pub const BTIME = false;
        pub const MNT_ID = false;
    };
    pub const field_names = struct {
        pub const TYPE = "type";
        pub const MODE = "mode";
        pub const NLINK = "nlink";
        pub const UID = "uid";
        pub const GID = "gid";
        pub const ATIME = "atime";
        pub const MTIME = "mtime";
        pub const CTIME = "ctime";
        pub const INO = "ino";
        pub const SIZE = "size";
        pub const BLOCKS = "blocks";
        pub const BTIME = "btime";
        pub const MNT_ID = "mount_id";
    };
    pub const backing_integer = usize;
};
pub const STATX_ATTR = struct {
    pub const default_values = struct {
        pub const COMPRESSED = false;
        pub const IMMUTABLE = false;
        pub const APPEND = false;
        pub const NODUMP = false;
        pub const ENCRYPTED = false;
        pub const AUTOMOUNT = false;
        pub const MOUNT_ROOT = false;
        pub const VERITY = false;
        pub const DAX = false;
    };
    pub const field_names = struct {
        pub const COMPRESSED = "compressed";
        pub const IMMUTABLE = "immutable";
        pub const APPEND = "append";
        pub const NODUMP = "nodump";
        pub const ENCRYPTED = "encrypted";
        pub const AUTOMOUNT = "automount";
        pub const MOUNT_ROOT = "mount_root";
        pub const VERITY = "verity";
        pub const DAX = "dax";
    };
    pub const backing_integer = usize;
};
pub const At = struct {
    pub const default_values = struct {
        pub const SYMLINK_NOFOLLOW = false;
        pub const REMOVEDIR = false;
        pub const SYMLINK_FOLLOW = false;
        pub const NO_AUTOMOUNT = false;
        pub const EMPTY_PATH = false;
    };
    pub const field_names = struct {
        pub const SYMLINK_NOFOLLOW = "symlink_no_follow";
        pub const REMOVEDIR = "remove_dir";
        pub const SYMLINK_FOLLOW = "symlink_follow";
        pub const NO_AUTOMOUNT = "no_automount";
        pub const EMPTY_PATH = "empty_path";
    };
    pub const backing_integer = usize;
};
pub const AUX = struct {
    pub const default_values = struct {
        pub const EXECFD = false;
        pub const PHDR = false;
        pub const PHENT = false;
        pub const PHNUM = false;
        pub const PAGESZ = false;
        pub const BASE = false;
        pub const FLAGS = false;
        pub const ENTRY = false;
        pub const EUID = false;
        pub const GID = false;
        pub const EGID = false;
        pub const PLATFORM = false;
        pub const HWCAP = false;
        pub const CLKTCK = false;
        pub const FPUCW = false;
        pub const DCACHEBSIZE = false;
        pub const ICACHEBSIZE = false;
        pub const UCACHEBSIZE = false;
        pub const SECURE = false;
        pub const BASE_PLATFORM = false;
        pub const RANDOM = false;
        pub const EXECFN = false;
        pub const SYSINFO = false;
        pub const SYSINFO_EHDR = false;
        pub const L1I_CACHESIZE = false;
        pub const L1I_CACHEGEOMETRY = false;
        pub const L1D_CACHESIZE = false;
        pub const L1D_CACHEGEOMETRY = false;
        pub const L2_CACHESIZE = false;
        pub const L2_CACHEGEOMETRY = false;
        pub const L3_CACHESIZE = false;
        pub const L3_CACHEGEOMETRY = false;
    };
    const _field_names = struct {
        pub const EXECFD = 
            \\execfd
        ;
        pub const PHDR = 
            \\phdr
        ;
        pub const PHENT = 
            \\phent
        ;
        pub const PHNUM = 
            \\phnum
        ;
        pub const PAGESZ = 
            \\pagesz
        ;
        pub const BASE = 
            \\base
        ;
        pub const FLAGS = 
            \\flags
        ;
        pub const ENTRY = 
            \\entry
        ;
        pub const EUID = 
            \\euid
        ;
        pub const GID = 
            \\gid
        ;
        pub const EGID = 
            \\egid
        ;
        pub const PLATFORM = 
            \\platform
        ;
        pub const HWCAP = 
            \\hwcap
        ;
        pub const CLKTCK = 
            \\clktck
        ;
        pub const FPUCW = 
            \\fpucw
        ;
        pub const DCACHEBSIZE = 
            \\dcachebsize
        ;
        pub const ICACHEBSIZE = 
            \\icachebsize
        ;
        pub const UCACHEBSIZE = 
            \\ucachebsize
        ;
        pub const SECURE = 
            \\secure
        ;
        pub const BASE_PLATFORM = 
            \\base_platform
        ;
        pub const RANDOM = 
            \\random
        ;
        pub const EXECFN = 
            \\execfn
        ;
        pub const SYSINFO = 
            \\sysinfo
        ;
        pub const SYSINFO_EHDR = 
            \\sysinfo_ehdr
        ;
        pub const L1I_CACHESIZE = 
            \\l1i_cachesize
        ;
        pub const L1I_CACHEGEOMETRY = 
            \\l1i_cachegeometry
        ;
        pub const L1D_CACHESIZE = 
            \\l1d_cachesize
        ;
        pub const L1D_CACHEGEOMETRY = 
            \\l1d_cachegeometry
        ;
        pub const L2_CACHESIZE = 
            \\l2_cachesize
        ;
        pub const L2_CACHEGEOMETRY = 
            \\l2_cachegeometry
        ;
        pub const L3_CACHESIZE = 
            \\l3_cachesize
        ;
        pub const L3_CACHEGEOMETRY = 
            \\l3_cachegeometry
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const FLOCK = struct {
    pub const default_values = struct {
        pub const RDLCK = false;
        pub const WRLCK = false;
        pub const UNLCK = false;
    };
    const _field_names = struct {
        pub const RDLCK = 
            \\rdlck
        ;
        pub const WRLCK = 
            \\wrlck
        ;
        pub const UNLCK = 
            \\unlck
        ;
    };
    pub const backing_integer = usize;
};
pub const F = struct {
    pub const default_values = struct {
        pub const GETFD = false;
        pub const SETFD = false;
        pub const GETFL = false;
        pub const SETFL = false;
        pub const GETLK = false;
        pub const SETLK = false;
        pub const SETLKW = false;
        pub const SETOWN = false;
        pub const GETOWN = false;
        pub const DUPFD_CLOEXEC = false;
    };
    const _field_names = struct {
        pub const GETFD = 
            \\getfd
        ;
        pub const SETFD = 
            \\setfd
        ;
        pub const GETFL = 
            \\getfl
        ;
        pub const SETFL = 
            \\setfl
        ;
        pub const GETLK = 
            \\getlk
        ;
        pub const SETLK = 
            \\setlk
        ;
        pub const SETLKW = 
            \\setlkw
        ;
        pub const SETOWN = 
            \\setown
        ;
        pub const GETOWN = 
            \\getown
        ;
        pub const DUPFD_CLOEXEC = 
            \\dupfd_cloexec
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const SI = struct {
    pub const default_values = struct {
        pub const USER = false;
        pub const KERNEL = false;
        pub const TKILL = false;
        pub const SIGIO = false;
        pub const ASYNCIO = false;
        pub const MESGQ = false;
        pub const TIMER = false;
        pub const QUEUE = false;
    };
    const _field_names = struct {
        pub const USER = 
            \\user
        ;
        pub const KERNEL = 
            \\kernel
        ;
        pub const TKILL = 
            \\tkill
        ;
        pub const SIGIO = 
            \\sigio
        ;
        pub const ASYNCIO = 
            \\asyncio
        ;
        pub const MESGQ = 
            \\mesgq
        ;
        pub const TIMER = 
            \\timer
        ;
        pub const QUEUE = 
            \\queue
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const ReadWrite = struct {
    pub const default_values = struct {
        pub const HIPRI = false;
        pub const DSYNC = false;
        pub const SYNC = false;
        pub const NOWAIT = false;
        pub const APPEND = false;
    };
    pub const field_names = struct {
        pub const HIPRI = "high_priority";
        pub const DSYNC = "data_sync";
        pub const SYNC = "file_sync";
        pub const NOWAIT = "no_wait";
        pub const APPEND = "append";
    };
    pub const backing_integer = usize;
};
pub const POSIX_FADV = struct {
    pub const default_values = struct {
        pub const NORMAL = false;
        pub const RANDOM = false;
        pub const SEQUENTIAL = false;
        pub const WILLNEED = false;
        pub const DONTNEED = false;
        pub const NOREUSE = false;
    };
    const _field_names = struct {
        pub const NORMAL = 
            \\normal
        ;
        pub const RANDOM = 
            \\random
        ;
        pub const SEQUENTIAL = 
            \\sequential
        ;
        pub const WILLNEED = 
            \\willneed
        ;
        pub const DONTNEED = 
            \\dontneed
        ;
        pub const NOREUSE = 
            \\noreuse
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const ITIMER = struct {
    pub const default_values = struct {
        pub const REAL = false;
        pub const VIRTUAL = false;
        pub const PROF = false;
    };
    const _field_names = struct {
        pub const REAL = 
            \\real
        ;
        pub const VIRTUAL = 
            \\virtual
        ;
        pub const PROF = 
            \\prof
        ;
    };
    pub const backing_integer = usize;
};
pub const SEGV = struct {
    pub const default_values = struct {
        pub const MAPERR = false;
        pub const ACCERR = false;
        pub const BNDERR = false;
        pub const PKUERR = false;
    };
    const _field_names = struct {
        pub const MAPERR = 
            \\maperr
        ;
        pub const ACCERR = 
            \\accerr
        ;
        pub const BNDERR = 
            \\bnderr
        ;
        pub const PKUERR = 
            \\pkuerr
        ;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const FS = struct {
    pub const default_values = struct {
        pub const SECRM_FL = false;
        pub const UNRM_FL = false;
        pub const COMPR_FL = false;
        pub const SYNC_FL = false;
        pub const IMMUTABLE_FL = false;
        pub const APPEND_FL = false;
        pub const NODUMP_FL = false;
        pub const NOATIME_FL = false;
        pub const JOURNAL_DATA_FL = false;
        pub const NOTAIL_FL = false;
        pub const DIRSYNC_FL = false;
        pub const TOPDIR_FL = false;
        pub const NOCOW_FL = false;
        pub const PROJINHERIT_FL = false;
    };
    const _field_names = struct {
        pub const SECRM_FL = 
            \\secrm_fl
        ;
        pub const UNRM_FL = 
            \\unrm_fl
        ;
        pub const COMPR_FL = 
            \\compr_fl
        ;
        pub const SYNC_FL = 
            \\sync_fl
        ;
        pub const IMMUTABLE_FL = 
            \\immutable_fl
        ;
        pub const APPEND_FL = 
            \\append_fl
        ;
        pub const NODUMP_FL = 
            \\nodump_fl
        ;
        pub const NOATIME_FL = 
            \\noatime_fl
        ;
        pub const JOURNAL_DATA_FL = 
            \\journal_data_fl
        ;
        pub const NOTAIL_FL = 
            \\notail_fl
        ;
        pub const DIRSYNC_FL = 
            \\dirsync_fl
        ;
        pub const TOPDIR_FL = 
            \\topdir_fl
        ;
        pub const NOCOW_FL = 
            \\nocow_fl
        ;
        pub const PROJINHERIT_FL = 
            \\projinherit_fl
        ;
    };
    pub const backing_integer = usize;
};
