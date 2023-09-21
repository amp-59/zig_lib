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
    pub const backing_integer = usize;
};
pub const PROT = struct {
    pub const default_values = struct {
        pub const NONE = false;
        pub const READ = false;
        pub const WRITE = false;
        pub const EXEC = false;
        pub const GROWSDOWN = false;
        pub const GROWSUP = false;
    };
    pub const backing_integer = usize;
};
pub const REMAP = struct {
    pub const default_values = struct {
        pub const RESIZE = false;
        pub const MAYMOVE = false;
        pub const FIXED = false;
        pub const DONTUNMAP = false;
    };
    pub const backing_integer = usize;
};
pub const MADV = struct {
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
    pub const backing_integer = usize;
};
pub const LOCK = struct {
    pub const default_values = struct {
        pub const SH = false;
        pub const EX = false;
        pub const NB = false;
        pub const UN = false;
    };
    pub const backing_integer = usize;
};
pub const Clone = struct {
    pub const default_values = struct {
        pub const CLEAR_SIGHAND = false;
        pub const INTO_CGROUP = false;
        pub const NEWTIME = false;
        pub const VM = false;
        pub const FS = false;
        pub const FILES = false;
        pub const SIGHAND = false;
        pub const PIDFD = false;
        pub const PTRACE = false;
        pub const VFORK = false;
        pub const THREAD = false;
        pub const NEWNS = false;
        pub const SYSVSEM = false;
        pub const SETTLS = false;
        pub const PARENT_SETTID = false;
        pub const CHILD_CLEARTID = false;
        pub const DETACHED = false;
        pub const UNTRACED = false;
        pub const CHILD_SETTID = false;
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
    pub const backing_integer = u32;
};
pub const Id = struct {
    pub const default_values = struct {
        pub const ALL = false;
        pub const PID = false;
        pub const PGID = false;
        pub const PIDFD = false;
    };
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const Wait = struct {
    pub const default_values = struct {
        pub const NOHANG = false;
        pub const UNTRACED = false;
        pub const STOPPED = false;
        pub const EXITED = false;
        pub const CONTINUED = false;
        pub const NOWAIT = false;
        pub const NOTHREAD = false;
        pub const ALL = false;
        pub const CLONE = false;
    };
    pub const backing_integer = usize;
};
pub const Shut = struct {
    pub const default_values = struct {
        pub const RD = false;
        pub const WR = false;
        pub const RDWR = false;
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
        pub const _ATIME = false;
        pub const NODIRATIME = false;
        pub const IDMAP = false;
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
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const SO = struct {
    pub const default_values = struct {
        pub const DEBUG = false;
        pub const REUSEADDR = false;
        pub const TYPE = false;
        pub const ERROR = false;
        pub const DONTROUTE = false;
        pub const BROADCAST = false;
        pub const SNDBUF = false;
        pub const RCVBUF = false;
        pub const KEEPALIVE = false;
        pub const OOBINLINE = false;
        pub const NO_CHECK = false;
        pub const PRIORITY = false;
        pub const LINGER = false;
        pub const BSDCOMPAT = false;
        pub const REUSEPORT = false;
        pub const PASSCRED = false;
        pub const PEERCRED = false;
        pub const RCVLOWAT = false;
        pub const SNDLOWAT = false;
        pub const RCVTIMEO_OLD = false;
        pub const RCVTIMEO = false;
        pub const SNDTIMEO_OLD = false;
        pub const SNDTIMEO = false;
        pub const SECURITY_AUTHENTICATION = false;
        pub const SECURITY_ENCRYPTION_TRANSPORT = false;
        pub const SECURITY_ENCRYPTION_NETWORK = false;
        pub const BINDTODEVICE = false;
        pub const ATTACH_FILTER = false;
        pub const GET_FILTER = false;
        pub const DETACH_FILTER = false;
        pub const DETACH_BPF = false;
        pub const PEERNAME = false;
        pub const TIMESTAMP_OLD = false;
        pub const TIMESTAMP = false;
        pub const ACCEPTCONN = false;
        pub const PEERSEC = false;
        pub const SNDBUFFORCE = false;
        pub const RCVBUFFORCE = false;
        pub const PASSSEC = false;
        pub const TIMESTAMPNS_OLD = false;
        pub const TIMESTAMPNS = false;
        pub const MARK = false;
        pub const TIMESTAMPING_OLD = false;
        pub const TIMESTAMPING = false;
        pub const PROTOCOL = false;
        pub const DOMAIN = false;
        pub const RXQ_OVFL = false;
        pub const WIFI_STATUS = false;
        pub const SCM_WIFI_STATUS = false;
        pub const PEEK_OFF = false;
        pub const NOFCS = false;
        pub const LOCK_FILTER = false;
        pub const SELECT_ERR_QUEUE = false;
        pub const BUSY_POLL = false;
        pub const MAX_PACING_RATE = false;
        pub const BPF_EXTENSIONS = false;
        pub const INCOMING_CPU = false;
        pub const ATTACH_BPF = false;
        pub const ATTACH_REUSEPORT_CBPF = false;
        pub const ATTACH_REUSEPORT_EBPF = false;
        pub const CNX_ADVICE = false;
        pub const SCM_TIMESTAMPING_OPT_STATS = false;
        pub const MEMINFO = false;
        pub const INCOMING_NAPI_ID = false;
        pub const COOKIE = false;
        pub const SCM_TIMESTAMPING_PKTINFO = false;
        pub const PEERGROUPS = false;
        pub const ZEROCOPY = false;
        pub const TXTIME = false;
        pub const SCM_TXTIME = false;
        pub const BINDTOIFINDEX = false;
        pub const TIMESTAMP_NEW = false;
        pub const TIMESTAMPNS_NEW = false;
        pub const TIMESTAMPING_NEW = false;
        pub const RCVTIMEO_NEW = false;
        pub const SNDTIMEO_NEW = false;
        pub const DETACH_REUSEPORT_BPF = false;
        pub const PREFER_BUSY_POLL = false;
        pub const BUSY_POLL_BUDGET = false;
        pub const NETNS_COOKIE = false;
        pub const BUF_LOCK = false;
        pub const RESERVE_MEM = false;
        pub const TXREHASH = false;
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
        pub const BIFFUDP = false;
        pub const LOGINSERVER = false;
        pub const WHOSERVER = false;
        pub const CMDSERVER = false;
        pub const EFSSERVER = false;
        pub const ROUTESERVER = false;
        pub const USERRESERVED = false;
        pub const RESERVED = false;
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
        pub const SIGINFO = false;
        pub const UNSUPPORTED = false;
        pub const EXPOSE_TAGBITS = false;
        pub const RESTORER = false;
        pub const ONSTACK = false;
        pub const RESTART = false;
        pub const NODEFER = false;
        pub const RESETHAND = false;
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
pub const SIG = struct {
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
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
pub const TIOC = struct {
    pub const default_values = struct {
        pub const PKT_DATA = false;
        pub const PKT_FLUSHREAD = false;
        pub const SER_TEMT = false;
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
    pub const set_names = .{
        "e0",
    };
    pub const backing_integer = usize;
};
