const extra = @import("./extra.zig");
pub const MemMap = struct {
    pub const SHARED = 1;
    pub const PRIVATE = 2;
    pub const SHARED_VALIDATE = 3;
    pub const FIXED = 16;
    pub const ANONYMOUS = 32;
    pub const GROWSDOWN = 256;
    pub const DENYWRITE = 2048;
    pub const EXECUTABLE = 4096;
    pub const LOCKED = 8192;
    pub const NORESERVE = 16384;
    pub const POPULATE = 32768;
    pub const NONBLOCK = 65536;
    pub const STACK = 131072;
    pub const HUGETLB = 262144;
    pub const SYNC = 524288;
    pub const FIXED_NOREPLACE = 1048576;
    pub usingnamespace extra.MemMap;
};
pub const FileMap = struct {
    pub const SHARED = 1;
    pub const PRIVATE = 2;
    pub const SHARED_VALIDATE = 3;
    pub const FIXED = 16;
    pub const ANONYMOUS = 32;
    pub const GROWSDOWN = 256;
    pub const DENYWRITE = 2048;
    pub const EXECUTABLE = 4096;
    pub const LOCKED = 8192;
    pub const NORESERVE = 16384;
    pub const POPULATE = 32768;
    pub const NONBLOCK = 65536;
    pub const STACK = 131072;
    pub const HUGETLB = 262144;
    pub const SYNC = 524288;
    pub const FIXED_NOREPLACE = 1048576;
    pub usingnamespace extra.FileMap;
};
pub const MemFd = struct {
    pub const CLOEXEC = 1;
    pub const ALLOW_SEALING = 2;
    pub const HUGETLB = 4;
    pub usingnamespace extra.MemFd;
};
pub const MemSync = struct {
    pub const ASYNC = 1;
    pub const INVALIDATE = 2;
    pub const SYNC = 4;
    pub usingnamespace extra.MemSync;
};
pub const MemProt = struct {
    pub const NONE = 0;
    pub const READ = 1;
    pub const WRITE = 2;
    pub const EXEC = 4;
    pub const GROWSDOWN = 16777216;
    pub const GROWSUP = 33554432;
    pub usingnamespace extra.MemProt;
};
pub const Remap = struct {
    pub const RESIZE = 0;
    pub const MAYMOVE = 1;
    pub const FIXED = 2;
    pub const DONTUNMAP = 4;
    pub usingnamespace extra.Remap;
};
pub const MAdvise = struct {
    pub const NORMAL = 0;
    pub const RANDOM = 1;
    pub const SEQUENTIAL = 2;
    pub const WILLNEED = 3;
    pub const DONTNEED = 4;
    pub const FREE = 8;
    pub const REMOVE = 9;
    pub const DONTFORK = 10;
    pub const DOFORK = 11;
    pub const MERGEABLE = 12;
    pub const UNMERGEABLE = 13;
    pub const HUGEPAGE = 14;
    pub const NOHUGEPAGE = 15;
    pub const DONTDUMP = 16;
    pub const DODUMP = 17;
    pub const WIPEONFORK = 18;
    pub const KEEPONFORK = 19;
    pub const COLD = 20;
    pub const PAGEOUT = 21;
    pub const HWPOISON = 100;
    pub usingnamespace extra.MAdvise;
};
pub const MCL = struct {
    pub const CURRENT = 1;
    pub const FUTURE = 2;
    pub const ONFAULT = 4;
    pub usingnamespace extra.MCL;
};
pub const Open = struct {
    pub const LARGEFILE = 0;
    pub const RDONLY = 0;
    pub const WRONLY = 1;
    pub const RDWR = 2;
    pub const CREAT = 64;
    pub const EXCL = 128;
    pub const NOCTTY = 256;
    pub const TRUNC = 512;
    pub const APPEND = 1024;
    pub const NONBLOCK = 2048;
    pub const DSYNC = 4096;
    pub const ASYNC = 8192;
    pub const DIRECT = 16384;
    pub const DIRECTORY = 65536;
    pub const NOFOLLOW = 131072;
    pub const NOATIME = 262144;
    pub const CLOEXEC = 524288;
    pub const PATH = 2097152;
    pub const TMPFILE = 4194304;
    pub usingnamespace extra.Open;
};
pub const Lock = struct {
    pub const SH = 1;
    pub const EX = 2;
    pub const NB = 4;
    pub const UN = 8;
    pub usingnamespace extra.Lock;
};
pub const Clone = struct {
    pub const CLEAR_SIGHAND = 0;
    pub const INTO_CGROUP = 0;
    pub const NEWTIME = 128;
    pub const VM = 256;
    pub const FS = 512;
    pub const FILES = 1024;
    pub const SIGHAND = 2048;
    pub const PIDFD = 4096;
    pub const PTRACE = 8192;
    pub const VFORK = 16384;
    pub const THREAD = 65536;
    pub const NEWNS = 131072;
    pub const SYSVSEM = 262144;
    pub const SETTLS = 524288;
    pub const PARENT_SETTID = 1048576;
    pub const CHILD_CLEARTID = 2097152;
    pub const DETACHED = 4194304;
    pub const UNTRACED = 8388608;
    pub const CHILD_SETTID = 16777216;
    pub const NEWCGROUP = 33554432;
    pub const NEWUTS = 67108864;
    pub const NEWIPC = 134217728;
    pub const NEWUSER = 268435456;
    pub const NEWPID = 536870912;
    pub const NEWNET = 1073741824;
    pub const IO = 2147483648;
    pub usingnamespace extra.Clone;
};
pub const Id = struct {
    pub const ALL = 0;
    pub const PID = 1;
    pub const PGID = 2;
    pub const PIDFD = 3;
    pub usingnamespace extra.Id;
};
pub const Wait = struct {
    pub const NOHANG = 1;
    pub const STOPPED = 2;
    pub const EXITED = 4;
    pub const CONTINUED = 8;
    pub const NOWAIT = 16777216;
    pub const NOTHREAD = 536870912;
    pub const ALL = 1073741824;
    pub const CLONE = 2147483648;
    pub usingnamespace extra.Wait;
};
pub const Shut = struct {
    pub const RD = 0;
    pub const WR = 1;
    pub const RDWR = 2;
    pub usingnamespace extra.Shut;
};
pub const MountAttr = struct {
    pub const RELATIME = 0;
    pub const RDONLY = 1;
    pub const NOSUID = 2;
    pub const NODEV = 4;
    pub const NOEXEC = 8;
    pub const NOATIME = 16;
    pub const STRICTATIME = 32;
    pub const NODIRATIME = 128;
    pub const IDMAP = 1048576;
    pub usingnamespace extra.MountAttr;
};
pub const PTrace = struct {
    pub const GETREGSET = 16900;
    pub const SETREGSET = 16901;
    pub const SEIZE = 16902;
    pub const INTERRUPT = 16903;
    pub const LISTEN = 16904;
    pub const PEEKSIGINFO = 16905;
    pub const GETSIGMASK = 16906;
    pub const SETSIGMASK = 16907;
    pub const SECCOMP_GET_FILTER = 16908;
    pub const GET_SYSCALL_INFO = 16910;
    pub usingnamespace extra.PTrace;
};
pub const AF = struct {
    pub const UNIX = 1;
    pub const INET = 2;
    pub const INET6 = 10;
    pub const NETLINK = 16;
    pub usingnamespace extra.AF;
};
pub const SOCK = struct {
    pub const STREAM = 1;
    pub const DGRAM = 2;
    pub const RAW = 3;
    pub const NONBLOCK = 2048;
    pub const CLOEXEC = 524288;
    pub usingnamespace extra.SOCK;
};
pub const IPPROTO = struct {
    pub const IP = 0;
    pub const HOPOPTS = 0;
    pub const ICMP = 1;
    pub const IGMP = 2;
    pub const IPIP = 4;
    pub const TCP = 6;
    pub const EGP = 8;
    pub const PUP = 12;
    pub const UDP = 17;
    pub const IDP = 22;
    pub const TP = 29;
    pub const DCCP = 33;
    pub const IPV6 = 41;
    pub const ROUTING = 43;
    pub const FRAGMENT = 44;
    pub const RSVP = 46;
    pub const GRE = 47;
    pub const ESP = 50;
    pub const AH = 51;
    pub const ICMPV6 = 58;
    pub const NONE = 59;
    pub const DSTOPTS = 60;
    pub const MTP = 92;
    pub const BEETPH = 94;
    pub const ENCAP = 98;
    pub const PIM = 103;
    pub const COMP = 108;
    pub const L2TP = 115;
    pub const SCTP = 132;
    pub const MH = 135;
    pub const UDPLITE = 136;
    pub const MPLS = 137;
    pub const ETHERNET = 143;
    pub const RAW = 255;
    pub const MPTCP = 262;
    pub const MAX = 263;
    pub usingnamespace extra.IPPROTO;
};
pub const IPPORT = struct {
    pub const ECHO = 7;
    pub const DISCARD = 9;
    pub const SYSTAT = 11;
    pub const DAYTIME = 13;
    pub const NETSTAT = 15;
    pub const FTP = 21;
    pub const TELNET = 23;
    pub const SMTP = 25;
    pub const TIMESERVER = 37;
    pub const NAMESERVER = 42;
    pub const WHOIS = 43;
    pub const MTP = 57;
    pub const TFTP = 69;
    pub const RJE = 77;
    pub const FINGER = 79;
    pub const TTYLINK = 87;
    pub const SUPDUP = 95;
    pub const EXECSERVER = 512;
    pub const LOGINSERVER = 513;
    pub const CMDSERVER = 514;
    pub const EFSSERVER = 520;
    pub const USERRESERVED = 5000;
    pub const RESERVED = 1024;
    pub usingnamespace extra.IPPORT;
};
pub const SignalAction = struct {
    pub const NOCLDSTOP = 1;
    pub const NOCLDWAIT = 2;
    pub const SIGINFO = 4;
    pub const UNSUPPORTED = 1024;
    pub const EXPOSE_TAGBITS = 2048;
    pub const RESTORER = 67108864;
    pub const ONSTACK = 134217728;
    pub const RESTART = 268435456;
    pub const NODEFER = 1073741824;
    pub const RESETHAND = 2147483648;
    pub usingnamespace extra.SignalAction;
};
pub const SIG = struct {
    pub const DFL = 0;
    pub const HUP = 1;
    pub const INT = 2;
    pub const QUIT = 3;
    pub const ILL = 4;
    pub const TRAP = 5;
    pub const ABRT = 6;
    pub const BUS = 7;
    pub const FPE = 8;
    pub const KILL = 9;
    pub const USR1 = 10;
    pub const SEGV = 11;
    pub const USR2 = 12;
    pub const PIPE = 13;
    pub const ALRM = 14;
    pub const TERM = 15;
    pub const STKFLT = 16;
    pub const CHLD = 17;
    pub const CONT = 18;
    pub const STOP = 19;
    pub const TSTP = 20;
    pub const TTIN = 21;
    pub const TTOU = 22;
    pub const URG = 23;
    pub const XCPU = 24;
    pub const XFSZ = 25;
    pub const VTALRM = 26;
    pub const PROF = 27;
    pub const WINCH = 28;
    pub const IO = 29;
    pub const PWR = 30;
    pub const SYS = 31;
    pub usingnamespace extra.SIG;
};
pub const TIOC = struct {
    pub const PKT_DATA = 0;
    pub const PKT_FLUSHREAD = 1;
    pub const PKT_FLUSHWRITE = 2;
    pub const PKT_STOP = 4;
    pub const PKT_START = 8;
    pub const PKT_NOSTOP = 16;
    pub const PKT_DOSTOP = 32;
    pub const PKT_IOCTL = 64;
    pub const EXCL = 21516;
    pub const NXCL = 21517;
    pub const SCTTY = 21518;
    pub const GPGRP = 21519;
    pub const SPGRP = 21520;
    pub const OUTQ = 21521;
    pub const STI = 21522;
    pub const GWINSZ = 21523;
    pub const SWINSZ = 21524;
    pub const MGET = 21525;
    pub const MBIS = 21526;
    pub const MBIC = 21527;
    pub const MSET = 21528;
    pub const GSOFTCAR = 21529;
    pub const SSOFTCAR = 21530;
    pub const INQ = 21531;
    pub const LINUX = 21532;
    pub const CONS = 21533;
    pub const GSERIAL = 21534;
    pub const SSERIAL = 21535;
    pub const PKT = 21536;
    pub const NOTTY = 21538;
    pub const SETD = 21539;
    pub const GETD = 21540;
    pub const SBRK = 21543;
    pub const CBRK = 21544;
    pub const GSID = 21545;
    pub const GRS485 = 21550;
    pub const SRS485 = 21551;
    pub const SERCONFIG = 21587;
    pub const SERGWILD = 21588;
    pub const SERSWILD = 21589;
    pub const GLCKTRMIOS = 21590;
    pub const SLCKTRMIOS = 21591;
    pub const SERGSTRUCT = 21592;
    pub const SERGETLSR = 21593;
    pub const SERGETMULTI = 21594;
    pub const SERSETMULTI = 21595;
    pub const MIWAIT = 21596;
    pub const GICOUNT = 21597;
    pub usingnamespace extra.TIOC;
};
pub const FIO = struct {
    pub const NBIO = 21537;
    pub const NCLEX = 21584;
    pub const CLEX = 21585;
    pub const ASYNC = 21586;
    pub const QSIZE = 21600;
    pub usingnamespace extra.FIO;
};
pub const UTIME = struct {
    pub const OMIT = 1073741822;
    pub const NOW = 1073741823;
    pub usingnamespace extra.UTIME;
};
pub const Seek = struct {
    pub const SET = 0;
    pub const CUR = 1;
    pub const END = 2;
    pub const DATA = 3;
    pub const HOLE = 4;
    pub usingnamespace extra.Seek;
};
pub const STATX = struct {
    pub const TYPE = 1;
    pub const MODE = 2;
    pub const NLINK = 4;
    pub const UID = 8;
    pub const GID = 16;
    pub const ATIME = 32;
    pub const MTIME = 64;
    pub const CTIME = 128;
    pub const INO = 256;
    pub const SIZE = 512;
    pub const BLOCKS = 1024;
    pub const BTIME = 2048;
    pub const MNT_ID = 4096;
    pub usingnamespace extra.STATX;
};
pub const STATX_ATTR = struct {
    pub const COMPRESSED = 4;
    pub const IMMUTABLE = 16;
    pub const APPEND = 32;
    pub const NODUMP = 64;
    pub const ENCRYPTED = 2048;
    pub const AUTOMOUNT = 4096;
    pub const MOUNT_ROOT = 8192;
    pub const VERITY = 1048576;
    pub const DAX = 2097152;
    pub usingnamespace extra.STATX_ATTR;
};
pub const At = struct {
    pub const SYMLINK_NOFOLLOW = 256;
    pub const REMOVEDIR = 512;
    pub const SYMLINK_FOLLOW = 1024;
    pub const NO_AUTOMOUNT = 2048;
    pub const EMPTY_PATH = 4096;
    pub usingnamespace extra.At;
};
pub const AUX = struct {
    pub const EXECFD = 2;
    pub const PHDR = 3;
    pub const PHENT = 4;
    pub const PHNUM = 5;
    pub const PAGESZ = 6;
    pub const BASE = 7;
    pub const FLAGS = 8;
    pub const ENTRY = 9;
    pub const EUID = 12;
    pub const GID = 13;
    pub const EGID = 14;
    pub const PLATFORM = 15;
    pub const HWCAP = 16;
    pub const CLKTCK = 17;
    pub const FPUCW = 18;
    pub const DCACHEBSIZE = 19;
    pub const ICACHEBSIZE = 20;
    pub const UCACHEBSIZE = 21;
    pub const SECURE = 23;
    pub const BASE_PLATFORM = 24;
    pub const RANDOM = 25;
    pub const EXECFN = 31;
    pub const SYSINFO = 32;
    pub const SYSINFO_EHDR = 33;
    pub const L1I_CACHESIZE = 40;
    pub const L1I_CACHEGEOMETRY = 41;
    pub const L1D_CACHESIZE = 42;
    pub const L1D_CACHEGEOMETRY = 43;
    pub const L2_CACHESIZE = 44;
    pub const L2_CACHEGEOMETRY = 45;
    pub const L3_CACHESIZE = 46;
    pub const L3_CACHEGEOMETRY = 47;
    pub usingnamespace extra.AUX;
};
pub const FLOCK = struct {
    pub const RDLCK = 0;
    pub const WRLCK = 1;
    pub const UNLCK = 2;
    pub usingnamespace extra.FLOCK;
};
pub const F = struct {
    pub const GETFD = 1;
    pub const SETFD = 2;
    pub const GETFL = 3;
    pub const SETFL = 4;
    pub const GETLK = 5;
    pub const SETLK = 6;
    pub const SETLKW = 7;
    pub const SETOWN = 8;
    pub const GETOWN = 9;
    pub const DUPFD_CLOEXEC = 1030;
    pub usingnamespace extra.F;
};
pub const SI = struct {
    pub const USER = 0;
    pub const KERNEL = 128;
    pub const TKILL = 4294967290;
    pub const SIGIO = 4294967291;
    pub const ASYNCIO = 4294967292;
    pub const MESGQ = 4294967293;
    pub const TIMER = 4294967294;
    pub const QUEUE = 4294967295;
    pub usingnamespace extra.SI;
};
pub const ReadWrite = struct {
    pub const HIPRI = 1;
    pub const DSYNC = 2;
    pub const SYNC = 4;
    pub const NOWAIT = 8;
    pub const APPEND = 16;
    pub usingnamespace extra.ReadWrite;
};
pub const POSIX_FADV = struct {
    pub const NORMAL = 0;
    pub const RANDOM = 1;
    pub const SEQUENTIAL = 2;
    pub const WILLNEED = 3;
    pub const DONTNEED = 4;
    pub const NOREUSE = 5;
    pub usingnamespace extra.POSIX_FADV;
};
pub const ITIMER = struct {
    pub const REAL = 0;
    pub const VIRTUAL = 1;
    pub const PROF = 2;
    pub usingnamespace extra.ITIMER;
};
pub const SEGV = struct {
    pub const MAPERR = 1;
    pub const ACCERR = 2;
    pub const BNDERR = 3;
    pub const PKUERR = 4;
    pub usingnamespace extra.SEGV;
};
pub const FS = struct {
    pub const SECRM_FL = 1;
    pub const UNRM_FL = 2;
    pub const COMPR_FL = 4;
    pub const SYNC_FL = 8;
    pub const IMMUTABLE_FL = 16;
    pub const APPEND_FL = 32;
    pub const NODUMP_FL = 64;
    pub const NOATIME_FL = 128;
    pub const JOURNAL_DATA_FL = 16384;
    pub const NOTAIL_FL = 32768;
    pub const DIRSYNC_FL = 65536;
    pub const TOPDIR_FL = 131072;
    pub const NOCOW_FL = 8388608;
    pub const PROJINHERIT_FL = 536870912;
    pub usingnamespace extra.FS;
};
