//! Linux x86_64
const builtin = @import("./builtin.zig");
const meta = @import("./meta.zig");
pub const MAP = struct {
    pub const FILE = 0x0;
    pub const SHARED = 0x1;
    pub const PRIVATE = 0x2;
    pub const SHARED_VALIDATE = 0x3;
    pub const TYPE = 0xf;
    pub const FIXED = 0x10;
    pub const ANONYMOUS = 0x20;
    pub const HUGE_SHIFT = 0x1a;
    pub const HUGE_MASK = 0x3f;
    pub const @"32BIT" = 0x40;
    pub const GROWSDOWN = 0x100;
    pub const DENYWRITE = 0x800;
    pub const EXECUTABLE = 0x1000;
    pub const LOCKED = 0x2000;
    pub const NORESERVE = 0x4000;
    pub const POPULATE = 0x8000;
    pub const NONBLOCK = 0x10000;
    pub const STACK = 0x20000;
    pub const HUGETLB = 0x40000;
    pub const SYNC = 0x80000;
    pub const FIXED_NOREPLACE = 0x100000;
};
pub const MFD = struct {
    pub const CLOEXEC = 0x1;
    pub const ALLOW_SEALING = 0x2;
    pub const HUGETLB = 0x4;
};
pub const PROT = struct {
    pub const NONE = 0x0;
    pub const READ = 0x1;
    pub const WRITE = 0x2;
    pub const EXEC = 0x4;
    pub const GROWSDOWN = 0x1000000;
    pub const GROWSUP = 0x2000000;
};
pub const REMAP = struct {
    pub const RESIZE = 0x0;
    pub const MAYMOVE = 0x1;
    pub const FIXED = 0x2;
    pub const DONTUNMAP = 0x4;
};
pub const MADV = struct {
    pub const NORMAL = 0x0;
    pub const RANDOM = 0x1;
    pub const SEQUENTIAL = 0x2;
    pub const WILLNEED = 0x3;
    pub const DONTNEED = 0x4;
    pub const FREE = 0x8;
    pub const REMOVE = 0x9;
    pub const DONTFORK = 0xa;
    pub const DOFORK = 0xb;
    pub const MERGEABLE = 0xc;
    pub const UNMERGEABLE = 0xd;
    pub const HUGEPAGE = 0xe;
    pub const NOHUGEPAGE = 0xf;
    pub const DONTDUMP = 0x10;
    pub const DODUMP = 0x11;
    pub const WIPEONFORK = 0x12;
    pub const KEEPONFORK = 0x13;
    pub const COLD = 0x14;
    pub const PAGEOUT = 0x15;
    pub const HWPOISON = 0x64;
};
pub const MCL = struct {
    pub const CURRENT = 0x1;
    pub const FUTURE = 0x2;
    pub const ONFAULT = 0x4;
};
pub const O = struct {
    pub const LARGEFILE = 0x0;
    pub const RDONLY = 0x0;
    pub const WRONLY = 0x1;
    pub const RDWR = 0x2;
    pub const CREAT = 0x40;
    pub const EXCL = 0x80;
    //pub const ACCMODE = 0x3;
    pub const NOCTTY = 0x100;
    pub const TRUNC = 0x200;
    pub const APPEND = 0x400;
    pub const NONBLOCK = 0x800;
    pub const SYNC = 0x101000;
    pub const ASYNC = 0x2000;
    pub const DIRECTORY = 0x10000;
    pub const NOFOLLOW = 0x20000;
    pub const CLOEXEC = 0x80000;
    pub const DIRECT = 0x4000;
    pub const NOATIME = 0x40000;
    pub const PATH = 0x200000;
    pub const DSYNC = 0x1000;
    pub const TMPFILE = 0x400000;
};
pub const LOCK = struct {
    pub const SH = 0x1;
    pub const EX = 0x2;
    pub const NB = 0x4;
    pub const UN = 0x8;
};
pub const POSIX = struct {
    pub const MADV = struct {
        pub const NORMAL = 0x0;
        pub const RANDOM = 0x1;
        pub const SEQUENTIAL = 0x2;
        pub const WILLNEED = 0x3;
        pub const DONTNEED = 0x4;
    };
    pub const FADV = struct {
        pub const NORMAL = 0x0;
        pub const RANDOM = 0x1;
        pub const SEQUENTIAL = 0x2;
        pub const WILLNEED = 0x3;
        pub const DONTNEED = 0x4;
        pub const NOREUSE = 0x5;
    };
};
// zig fmt: off
pub const S = struct {
    pub const IFMT = 0b1111000000000000;
    pub const IFLNK = 0b1010000000000000;
    pub const IFREG = 0b1000000000000000;
    pub const IFSOCK = 0b1100000000000000;
    pub const IFDIR = 0b0100000000000000;
    pub const IFBLK = 0b0110000000000000;
    pub const IFCHR = 0b0010000000000000;
    pub const IFIFO = 0b0001000000000000;
    pub const IFLNKR = 0b0000000000001010;
    pub const IFREGR = 0b0000000000001000;
    pub const IFSOCKR = 0b0000000000001100;
    pub const IFDIRR = 0b0000000000000100;
    pub const IFBLKR = 0b0000000000000110;
    pub const IFCHRR = 0b0000000000000010;
    pub const IFIFOR = 0b0000000000000001;
    pub const ISUID = 0b0000100000000000;
    pub const ISGID = 0b0000010000000000;
    pub const ISVTX = 0b0000001000000000;
    pub const IREAD = 0b0000000100000000;
    pub const IWRITE = 0b0000000010000000;
    pub const IEXEC = 0b0000000001000000;
    pub const IRUSR = 0b0000000100000000;
    pub const IWUSR = 0b0000000010000000;
    pub const IXUSR = 0b0000000001000000;
    pub const IRWXU = 0b0000000111000000;
    pub const IRGRP = 0b0000000000100000;
    pub const IWGRP = 0b0000000000010000;
    pub const IXGRP = 0b0000000000001000;
    pub const IRWXG = 0b0000000000111000;
    pub const IROTH = 0b0000000000000100;
    pub const IWOTH = 0b0000000000000010;
    pub const IXOTH = 0b0000000000000001;
    pub const IRWXO = 0b0000000000000111;
};
// zig fmt: on
pub const UTIME = struct {
    pub const NOW = 0x3fffffff;
    pub const OMIT = 0x3ffffffe;
};
pub const R_OK = 0x4;
pub const W_OK = 0x2;
pub const X_OK = 0x1;
pub const F_OK = 0x0;
pub const SEEK = struct {
    pub const END = 0x2;
    pub const HOLE = 0x4;
    pub const DATA = 0x3;
    pub const SET = 0x0;
    pub const CUR = 0x1;
};
pub const STATX = struct {
    pub const TYPE = 0x1;
    pub const MODE = 0x2;
    pub const NLINK = 0x4;
    pub const UID = 0x8;
    pub const GID = 0x10;
    pub const ATIME = 0x20;
    pub const MTIME = 0x40;
    pub const CTIME = 0x80;
    pub const INO = 0x100;
    pub const SIZE = 0x200;
    pub const BLOCKS = 0x400;
    pub const BASIC_STATS = 0x7ff;
    pub const BTIME = 0x800;
    pub const MNT_ID = 0x1000;
    pub const ALL = 0xfff;
    pub const ATTR = struct {
        pub const COMPRESSED = 0x4;
        pub const IMMUTABLE = 0x10;
        pub const APPEND = 0x20;
        pub const NODUMP = 0x40;
        pub const ENCRYPTED = 0x800;
        pub const AUTOMOUNT = 0x1000;
        pub const MOUNT_ROOT = 0x2000;
        pub const VERITY = 0x100000;
        pub const DAX = 0x200000;
    };
};
pub const GRND = struct {
    pub const NONBLOCK = 0x1;
    pub const RANDOM = 0x2;
    pub const INSECURE = 0x4;
};
pub const CLOCK = struct {
    pub const REALTIME = 0x0;
    pub const REALTIME_ALARM = 0x8;
    pub const REALTIME_COARSE = 0x5;
    pub const TAI = 0xb;
    pub const MONOTONIC = 0x1;
    pub const MONOTONIC_COARSE = 0x6;
    pub const MONOTONIC_RAW = 0x4;
    pub const BOOTTIME = 0x7;
    pub const BOOTTIME_ALARM = 0x9;
    pub const PROCESS_CPUTIME_ID = 0x2;
    pub const THREAD_CPUTIME_ID = 0x3;
};
pub const IPC = struct {
    pub const EXCL = 0x400;
    pub const INFO = 0x3;
    pub const RMID = 0x0;
    pub const SET = 0x1;
    pub const NOWAIT = 0x800;
    pub const CREAT = 0x200;
    pub const STAT = 0x2;
};
pub const SCHED = struct {
    pub const RR = 0x2;
    pub const BATCH = 0x3;
    pub const IDLE = 0x5;
    pub const FLAG = struct {
        pub const RECLAIM = 0x2;
        pub const RESET_ON = struct {
            pub const FORK = 0x1;
        };
        pub const DL_OVERRUN = 0x4;
    };
};
pub const SA = struct {
    pub const ONSTACK = 0x8000000;
    pub const SIGINFO = 0x4;
    pub const NODEFER = 0x40000000;
    pub const RESETHAND = 0x80000000;
    pub const EXPOSE_TAGBITS = 0x800;
    pub const RESTART = 0x10000000;
    pub const NOCLDWAIT = 0x2;
    pub const RESTORER = 0x4000000;
    pub const NOCLDSTOP = 0x1;
    pub const UNSUPPORTED = 0x400;
};
pub const SIG = struct {
    pub const DFL = 0x0;
    pub const IGN = 0x1;
    pub const INT = 0x2;
    pub const ILL = 0x4;
    pub const ABRT = 0x6;
    pub const FPE = 0x8;
    pub const SEGV = 0xb;
    pub const TERM = 0xf;
    pub const HUP = 0x1;
    pub const QUIT = 0x3;
    pub const TRAP = 0x5;
    pub const KILL = 0x9;
    pub const PIPE = 0xd;
    pub const ALRM = 0xe;
    pub const IO = 0x1d;
    pub const IOT = 0x6;
    pub const CLD = 0x11;
    pub const STKFLT = 0x10;
    pub const PWR = 0x1e;
    pub const BUS = 0x7;
    pub const SYS = 0x1f;
    pub const URG = 0x17;
    pub const STOP = 0x13;
    pub const TSTP = 0x14;
    pub const CONT = 0x12;
    pub const CHLD = 0x11;
    pub const TTIN = 0x15;
    pub const TTOU = 0x16;
    pub const POLL = 0x1d;
    pub const XFSZ = 0x19;
    pub const XCPU = 0x18;
    pub const VTALRM = 0x1a;
    pub const PROF = 0x1b;
    pub const USR1 = 0xa;
    pub const USR2 = 0xc;
    pub const WINCH = 0x1c;
    pub const UNBLOCK = 0x1;
    pub const SETMASK = 0x2;
    pub const BLOCK = 0x0;
};
pub const TIOC = struct {
    pub const EXCL = 0x540C;
    pub const NXCL = 0x540D;
    pub const SCTTY = 0x540E;
    pub const GPGRP = 0x540F;
    pub const SPGRP = 0x5410;
    pub const OUTQ = 0x5411;
    pub const STI = 0x5412;
    pub const GWINSZ = 0x5413;
    pub const SWINSZ = 0x5414;
    pub const MGET = 0x5415;
    pub const MBIS = 0x5416;
    pub const MBIC = 0x5417;
    pub const MSET = 0x5418;
    pub const GSOFTCAR = 0x5419;
    pub const SSOFTCAR = 0x541A;
    pub const INQ = 0x541B;
    pub const LINUX = 0x541C;
    pub const CONS = 0x541D;
    pub const GSERIAL = 0x541E;
    pub const SSERIAL = 0x541F;
    pub const PKT = 0x5420;
    pub const NOTTY = 0x5422;
    pub const SETD = 0x5423;
    pub const GETD = 0x5424;
    pub const SBRK = 0x5427;
    pub const CBRK = 0x5428;
    pub const GSID = 0x5429;
    pub const GRS485 = 0x542E;
    pub const SRS485 = 0x542F;
    pub const SERCONFIG = 0x5453;
    pub const SERGWILD = 0x5454;
    pub const SERSWILD = 0x5455;
    pub const GLCKTRMIOS = 0x5456;
    pub const SLCKTRMIOS = 0x5457;
    pub const SERGSTRUCT = 0x5458;
    pub const SERGETLSR = 0x5459;
    pub const SERGETMULTI = 0x545A;
    pub const SERSETMULTI = 0x545B;
    pub const MIWAIT = 0x545C;
    pub const GICOUNT = 0x545D;
    pub const PKT_DATA = 0;
    pub const PKT_FLUSHREAD = 1;
    pub const PKT_FLUSHWRITE = 2;
    pub const PKT_STOP = 4;
    pub const PKT_START = 8;
    pub const PKT_NOSTOP = 16;
    pub const PKT_DOSTOP = 32;
    pub const PKT_IOCTL = 64;
    pub const SER_TEMT = 0x01;
};
pub const FIO = struct {
    pub const NBIO = 0x5421;
    pub const NCLEX = 0x5450;
    pub const CLEX = 0x5451;
    pub const ASYNC = 0x5452;
    pub const QSIZE = 0x5460;
};
pub const TC = struct {
    pub const GETS = 0x5401;
    pub const SETS = 0x5402;
    pub const SETSW = 0x5403;
    pub const SETSF = 0x5404;
    pub const GETA = 0x5405;
    pub const SETA = 0x5406;
    pub const SETAW = 0x5407;
    pub const SETAF = 0x5408;
    pub const SBRK = 0x5409;
    pub const XONC = 0x540A;
    pub const FLSH = 0x540B;
    pub const SBRKP = 0x5425;
    pub const GETX = 0x5432;
    pub const SETX = 0x5433;
    pub const SETXF = 0x5434;
    pub const SETXW = 0x5435;
    pub const I = struct {
        pub const IGNBRK = 0x1;
        pub const BRKINT = 0x2;
        pub const IGNPAR = 0x4;
        pub const PARMRK = 0x8;
        pub const INPCK = 0x10;
        pub const STRIP = 0x20;
        pub const NLCR = 0x40;
        pub const IGNCR = 0x80;
        pub const CRNL = 0x100;
        pub const UCLC = 0x200;
        pub const XON = 0x400;
        pub const XANY = 0x800;
        pub const XOFF = 0x1000;
        pub const MAXBEL = 0x2000;
        pub const UTF8 = 0;
    };
    pub const O = struct {
        pub const POST = 0x1;
        pub const LCUC = 0x2;
        pub const NLCR = 0x4;
        pub const CRNL = 0x8;
        pub const NOCR = 0x10;
        pub const NLRET = 0x20;
        pub const FILL = 0x40;
        pub const FDEL = 0x80;
        pub const NLDLY = 0x100;
        pub const CRDLY = 0x600;
        pub const TABDLY = 0x1800;
        pub const BSDLY = 0x2000;
        pub const VTDLY = 0x4000;
        pub const FFDLY = 0x8000;
    };
    pub const C = struct {
        pub const BAUD = 0x100f;
        pub const BAUDEX = 0x1000;
        pub const SIZE = 0x30;
        pub const STOPB = 0x40;
        pub const READ = 0x80;
        pub const PARENB = 0x100;
        pub const PARODD = 0x200;
        pub const HUPCL = 0x400;
        pub const LOCAL = 0x800;
        pub const IBAUD = 0x100f0000;
        pub const MSPAR = 0x40000000;
        pub const RTSCTS = 0x80000000;
    };
    pub const L = struct {
        pub const ISIG = 0x1;
        pub const ICANON = 0x2;
        pub const XCASE = 0x4;
        pub const ECHO = 0x8;
        pub const ECHOE = 0x10;
        pub const ECHOK = 0x20;
        pub const ECHONL = 0x40;
        pub const ECHOCTL = 0x200;
        pub const ECHOPRT = 0x400;
        pub const ECHOKE = 0x800;
        pub const FLUSHO = 0x1000;
        pub const NOFLSH = 0x80;
        pub const TOSTOP = 0x100;
        pub const PENDIN = 0x4000;
        pub const IEXTEN = 0x8000;
    };
    pub const V = struct {
        pub const DISCARD = 0xd;
        pub const EOF = 0x4;
        pub const EOL = 0xb;
        pub const ERASE = 0x2;
        pub const INTR = 0x0;
        pub const KILL = 0x3;
        pub const LNEXT = 0xf;
        pub const MIN = 0x6;
        pub const QUIT = 0x1;
        pub const REPRINT = 0xc;
        pub const START = 0x8;
        pub const STOP = 0x9;
        pub const SUSP = 0xa;
        pub const TIME = 0x5;
        pub const WERASE = 0xe;
    };
    pub const SANOW = 0x0;
    pub const SADRAIN = 0x1;
    pub const SAFLUSH = 0x2;
    pub const IFLUSH = 0x0;
    pub const IOFLUSH = 0x2;
    pub const OFLUSH = 0x1;
    pub const OOFF = 0x0;
    pub const OON = 0x1;
    pub const IOFF = 0x2;
    pub const ION = 0x3;
};
pub const ARCH = struct {
    pub const SET = struct {
        pub const CPUID = 0x1012;
        pub const GS = 0x1001;
        pub const FS = 0x1002;
    };
    pub const GET = struct {
        pub const CPUID = 0x1011;
        pub const GS = 0x1004;
        pub const FS = 0x1003;
    };
};
pub const UFFD = struct {
    pub const EVENT = struct {
        pub const UNMAP = 0x16;
        pub const FORK = 0x13;
        pub const REMOVE = 0x15;
        pub const REMAP = 0x14;
        pub const PAGEFAULT = 0x12;
    };
    pub const FEATURE = struct {
        pub const EVENT = struct {
            pub const UNMAP = 0x40;
            pub const FORK = 0x2;
            pub const REMOVE = 0x8;
            pub const REMAP = 0x4;
        };
        pub const THREAD_ID = 0x100;
        pub const SIGBUS = 0x80;
        pub const MISSING = struct {
            pub const SHMEM = 0x20;
            pub const HUGETLBFS = 0x10;
        };
    };
    pub const PAGEFAULT_FLAG = struct {
        pub const WP = 0x2;
        pub const WRITE = 0x1;
    };
};
pub const POLL = struct {
    pub const IN = 0b0000000001;
    pub const PRI = 0b0000000010;
    pub const OUT = 0b0000000100;
    pub const ERR = 0b0000001000;
    pub const HUP = 0b0000010000;
    pub const NVAL = 0b0000100000;
    pub const RDNORM = 0b0001000000;
    pub const RDBAND = 0b0010000000;
    pub const WRNORM = 0b0100000000;
    pub const WRBAND = 0b1000000000;
};
pub const PERF = struct {
    pub const SAMPLE_BRANCH = struct {
        pub const PLM_ALL = 0x7;
    };
    pub const EVENT_IOC = struct {
        pub const QUERY_BPF = 0xc008240a;
        pub const REFRESH = 0x2402;
        pub const PERIOD = 0x40082404;
        pub const DISABLE = 0x2401;
        pub const ENABLE = 0x2400;
        pub const SET = struct {
            pub const FILTER = 0x40082406;
            pub const BPF = 0x40042408;
            pub const OUTPUT = 0x2405;
        };
        pub const RESET = 0x2403;
        pub const PAUSE_OUTPUT = 0x40042409;
        pub const ID = 0x80082407;
    };
    pub const AUX_FLAG = struct {
        pub const TRUNCATED = 0x1;
        pub const OVERWRITE = 0x2;
    };
    pub const MEM = struct {
        pub const LVL = struct {
            pub const L1 = 0x8;
            pub const IO = 0x1000;
            pub const MISS = 0x4;
            pub const L2 = 0x20;
            pub const HIT = 0x2;
            pub const L3 = 0x40;
            pub const UNC = 0x2000;
            pub const REM = struct {
                pub const CCE2 = 0x800;
                pub const RAM1 = 0x100;
                pub const RAM2 = 0x200;
                pub const CCE1 = 0x400;
            };
            pub const LOC_RAM = 0x80;
            pub const LFB = 0x10;
        };
        pub const TLB = struct {
            pub const L1 = 0x8;
            pub const L2 = 0x10;
            pub const MISS = 0x4;
            pub const OS = 0x40;
            pub const WK = 0x20;
            pub const HIT = 0x2;
        };
        pub const SNOOP = struct {
            pub const HITM = 0x10;
            pub const MISS = 0x8;
            pub const NONE = 0x2;
            pub const HIT = 0x4;
        };
        pub const OP = struct {
            pub const LOAD = 0x2;
            pub const PFETCH = 0x8;
            pub const EXEC = 0x10;
            pub const STORE = 0x4;
        };
        pub const LOCK_LOCKED = 0x2;
    };
    pub const FLAG = struct {
        pub const FD = struct {
            pub const NO_GROUP = 0x1;
            pub const OUTPUT = 0x2;
            pub const CLOEXEC = 0x8;
        };
        pub const PID_CGROUP = 0x4;
    };
    pub const RECORD_MISC = struct {
        pub const KERNEL = 0x1;
        pub const MMAP_DATA = 0x2000;
        pub const HYPERVISOR = 0x3;
        pub const PROC_MAP_PARSE_TIMEOUT = 0x1000;
        pub const GUEST = struct {
            pub const KERNEL = 0x4;
            pub const USER = 0x5;
        };
        pub const EXACT_IP = 0x4000;
        pub const SWITCH_OUT = 0x2000;
        pub const EXT_RESERVED = 0x8000;
        pub const USER = 0x2;
        pub const COMM_EXEC = 0x2000;
        pub const CPUMODE_UNKNOWN = 0x0;
    };
};
pub const RESOLVE = struct {
    pub const BENEATH = 0x8;
    pub const NO = struct {
        pub const SYMLINKS = 0x4;
        pub const XDEV = 0x1;
        pub const MAGICLINKS = 0x2;
    };
    pub const CACHED = 0x20;
    pub const IN_ROOT = 0x10;
};
pub const SYS_SECCOMP = 0x1;
pub const KEYCTL = struct {
    pub const UPDATE = 0x2;
    pub const GET = struct {
        pub const SECURITY = 0x11;
        pub const KEYRING_ID = 0x0;
        pub const PERSISTENT = 0x16;
    };
    pub const NEGATE = 0xd;
    pub const INVALIDATE = 0x15;
    pub const SEARCH = 0xa;
    pub const CLEAR = 0x7;
    pub const REJECT = 0x13;
    pub const REVOKE = 0x3;
    pub const RESTRICT_KEYRING = 0x1d;
    pub const ASSUME_AUTHORITY = 0x10;
    pub const JOIN_SESSION_KEYRING = 0x1;
    pub const SET = struct {
        pub const REQKEY_KEYRING = 0xe;
        pub const TIMEOUT = 0xf;
    };
    pub const LINK = 0x8;
    pub const DH_COMPUTE = 0x17;
    pub const CHOWN = 0x4;
    pub const UNLINK = 0x9;
    pub const SESSION_TO_PARENT = 0x12;
    pub const SETPERM = 0x5;
    pub const INSTANTIATE_IOV = 0x14;
    pub const DESCRIBE = 0x6;
    pub const READ = 0xb;
};
pub const KEY = struct {
    pub const SPEC = struct {
        pub const THREAD_KEYRING = 0xffffffff;
        pub const REQUESTOR_KEYRING = 0xfffffff8;
        pub const USER = struct {
            pub const KEYRING = 0xfffffffc;
            pub const SESSION_KEYRING = 0xfffffffb;
        };
        pub const REQKEY_AUTH = struct {
            pub const KEY = 0xfffffff9;
        };
        pub const PROCESS_KEYRING = 0xfffffffe;
        pub const SESSION_KEYRING = 0xfffffffd;
    };
    pub const REQKEY_DEFL = struct {
        pub const THREAD_KEYRING = 0x1;
        pub const REQUESTOR_KEYRING = 0x7;
        pub const USER = struct {
            pub const KEYRING = 0x4;
            pub const SESSION_KEYRING = 0x5;
        };
        pub const DEFAULT = 0x0;
        pub const NO_CHANGE = 0xffffffff;
        pub const PROCESS_KEYRING = 0x2;
        pub const SESSION_KEYRING = 0x3;
    };
};
pub const SYNC_FILE = struct {
    pub const RANGE = struct {
        pub const WAIT = struct {
            pub const AFTER = 0x4;
            pub const BEFORE = 0x1;
        };
        pub const WRITE = 0x2;
    };
};
pub const SIGEV = struct {
    pub const NONE = 0x1;
    pub const SIGNAL = 0x0;
    pub const THREAD_ID = 0x4;
};
pub const MS = struct {
    pub const ASYNC = 0x1;
    pub const INVALIDATE = 0x2;
    pub const SYNC = 0x4;
};
pub const ATTR = struct {
    pub const HIDDEN = 0x2;
    pub const RO = 0x1;
    pub const VOLUME = 0x8;
    pub const DIR = 0x10;
    pub const ARCH = 0x20;
    pub const SYS = 0x4;
};
pub const ILL = struct {
    pub const COPROC = 0x7;
    pub const ILLOPN = 0x2;
    pub const PRVREG = 0x6;
    pub const ILLOPC = 0x1;
    pub const ILLTRP = 0x4;
    pub const ILLADR = 0x3;
    pub const PRVOPC = 0x5;
    pub const BADSTK = 0x8;
};
pub const RENAME = struct {
    pub const NOREPLACE = 0x1;
    pub const WHITEOUT = 0x4;
    pub const EXCHANGE = 0x2;
};
pub const SS = struct {
    pub const ONSTACK = 0x1;
    pub const DISABLE = 0x2;
    pub const AUTODISARM = 0x80000000;
};
pub const FPE = struct {
    pub const FLTINV = 0x7;
    pub const FLTDIV = 0x3;
    pub const FLTSUB = 0x8;
    pub const FLTUND = 0x5;
    pub const INTOVF = 0x2;
    pub const FLTRES = 0x6;
    pub const INTDIV = 0x1;
    pub const FLTOVF = 0x4;
};
pub const CLD = struct {
    pub const TRAPPED = 0x4;
    pub const STOPPED = 0x5;
    pub const KILLED = 0x2;
    pub const CONTINUED = 0x6;
    pub const DUMPED = 0x3;
    pub const EXITED = 0x1;
};
pub const AT = struct {
    pub const EACCESS = 0x200;
    pub const SYMLINK = struct {
        pub const FOLLOW = 0x400;
        pub const NOFOLLOW = 0x100;
    };
    pub const NO_AUTOMOUNT = 0x800;
    pub const FDCWD = 0xffffffffffffff9c;
    pub const REMOVEDIR = 0x200;
    pub const EMPTY_PATH = 0x1000;
    pub const EXECFD = 0x2;
    pub const PHDR = 0x3;
    pub const PHENT = 0x4;
    pub const PHNUM = 0x5;
    pub const PAGESZ = 0x6;
    pub const BASE = 0x7;
    pub const FLAGS = 0x8;
    pub const ENTRY = 0x9;
    pub const EUID = 0xc;
    pub const GID = 0xd;
    pub const EGID = 0xe;
    pub const PLATFORM = 0xf;
    pub const HWCAP = 0x10;
    pub const CLKTCK = 0x11;
    pub const FPUCW = 0x12;
    pub const DCACHEBSIZE = 0x13;
    pub const ICACHEBSIZE = 0x14;
    pub const UCACHEBSIZE = 0x15;
    pub const SECURE = 0x17;
    pub const BASE_PLATFORM = 0x18;
    pub const RANDOM = 0x19;
    pub const EXECFN = 0x1f;
    pub const SYSINFO = 0x20;
    pub const SYSINFO_EHDR = 0x21;
    pub const L1I_CACHESIZE = 0x28;
    pub const L1I_CACHEGEOMETRY = 0x29;
    pub const L1D_CACHESIZE = 0x2a;
    pub const L1D_CACHEGEOMETRY = 0x2b;
    pub const L2_CACHESIZE = 0x2c;
    pub const L2_CACHEGEOMETRY = 0x2d;
    pub const L3_CACHESIZE = 0x2e;
    pub const L3_CACHEGEOMETRY = 0x2f;
};
pub const FMR = struct {
    pub const OF = struct {
        pub const EXTENT_MAP = 0x4;
        pub const SHARED = 0x8;
        pub const SPECIAL_OWNER = 0x10;
        pub const ATTR_FORK = 0x2;
        pub const LAST = 0x20;
        pub const PREALLOC = 0x1;
    };
    pub const OWN = struct {
        pub const UNKNOWN = 0x2;
        pub const FREE = 0x1;
        pub const METADATA = 0x3;
    };
};
pub const F = struct {
    pub const SETOWN = 0x8;
    pub const SETLK = 0x6;
    pub const SETFD = 0x2;
    pub const SETLKW = 0x7;
    pub const GETLK = 0x5;
    pub const WRLCK = 0x1;
    pub const RDLCK = 0x0;
    pub const DUPFD_CLOEXEC = 0x406;
    pub const GETFD = 0x1;
    pub const GETFL = 0x3;
    pub const UNLCK = 0x2;
    pub const GETOWN = 0x9;
    pub const SETFL = 0x4;
};
pub const SI = struct {
    pub const TKILL = 0xfffffffa;
    pub const ASYNCIO = 0xfffffffc;
    pub const KERNEL = 0x80;
    pub const QUEUE = 0xffffffff;
    pub const TIMER = 0xfffffffe;
    pub const USER = 0x0;
    pub const SIGIO = 0xfffffffb;
    pub const MESGQ = 0xfffffffd;
};
pub const RWF = struct {
    pub const DSYNC = 0x2;
    pub const HIPRI = 0x1;
    pub const SYNC = 0x4;
    pub const NOWAIT = 0x8;
    pub const APPEND = 0x10;
};
pub const DT = struct {
    pub const SOCK = 0xc;
    pub const UNKNOWN = 0x0;
    pub const LNK = 0xa;
    pub const DIR = 0x4;
    pub const CHR = 0x2;
    pub const FIFO = 0x1;
    pub const REG = 0x8;
};
pub const LINUX_REBOOT_CMD = struct {
    pub const RESTART = 0x1234567;
    pub const HALT = 0xcdef0123;
    pub const SW_SUSPEND = 0xd000fce2;
    pub const RESTART2 = 0xa1b2c3d4;
    pub const POWER_OFF = 0x4321fedc;
    pub const KEXEC = 0x45584543;
    pub const CAD = struct {
        pub const ON = 0x89abcdef;
        pub const OFF = 0x0;
    };
};
pub const BUS = struct {
    pub const ADRALN = 0x1;
    pub const ADRERR = 0x2;
    pub const OBJERR = 0x3;
    pub const MCEERR = struct {
        pub const AO = 0x5;
        pub const AR = 0x4;
    };
};
pub const POSIX_FADV = struct {
    pub const NOREUSE = 0x5;
    pub const NORMAL = 0x0;
    pub const RANDOM = 0x1;
    pub const DONTNEED = 0x4;
    pub const SEQUENTIAL = 0x2;
    pub const WILLNEED = 0x3;
};
pub const ITIMER = struct {
    pub const VIRTUAL = 0x1;
    pub const REAL = 0x0;
    pub const PROF = 0x2;
};
pub const SEGV = struct {
    pub const ACCERR = 0x2;
    pub const PKUERR = 0x4;
    pub const BNDERR = 0x3;
    pub const MAPERR = 0x1;
};
pub const SECCOMP = struct {
    pub const RET = struct {
        pub const KILL = struct {
            pub const PROCESS = 0x80000000;
            pub const THREAD = 0x0;
        };
        pub const ALLOW = 0x7fff0000;
        pub const ERRNO = 0x50000;
        pub const LOG = 0x7ffc0000;
        pub const TRACE = 0x7ff00000;
        pub const TRAP = 0x30000;
        pub const USER_NOTIF = 0x7fc00000;
    };
    pub const GET = struct {
        pub const NOTIF_SIZES = 0x3;
        pub const ACTION_AVAIL = 0x2;
    };
    pub const FILTER_FLAG = struct {
        pub const NEW_LISTENER = 0x8;
        pub const SPEC_ALLOW = 0x4;
        pub const TSYNC = 0x1;
        pub const LOG = 0x2;
    };
    pub const SET_MODE = struct {
        pub const STRICT = 0x0;
        pub const FILTER = 0x1;
    };
};
pub const UFFDIO = struct {
    pub const ZEROPAGE_MODE = struct {
        pub const DONTWAKE = 0x1;
    };
    pub const WRITEPROTECT_MODE = struct {
        pub const DONTWAKE = 0x2;
        pub const WP = 0x1;
    };
    pub const REGISTER_MODE = struct {
        pub const WP = 0x2;
        pub const MISSING = 0x1;
    };
    pub const COPY_MODE = struct {
        pub const DONTWAKE = 0x1;
        pub const WP = 0x2;
    };
};
pub const MODULE_INIT = struct {
    pub const IGNORE = struct {
        pub const MODVERSIONS = 0x1;
        pub const VERMAGIC = 0x2;
    };
};
pub const KEXEC = struct {
    pub const FILE = struct {
        pub const UNLOAD = 0x1;
        pub const NO_INITRAMFS = 0x4;
        pub const ON_CRASH = 0x2;
    };
    pub const PRESERVE_CONTEXT = 0x2;
    pub const ON_CRASH = 0x1;
};
pub const FS = struct {
    pub const APPEND_FL = 0x20;
    pub const NODUMP_FL = 0x40;
    pub const SECRM_FL = 0x1;
    pub const PROJINHERIT_FL = 0x20000000;
    pub const SYNC_FL = 0x8;
    pub const JOURNAL_DATA_FL = 0x4000;
    pub const NOATIME_FL = 0x80;
    pub const UNRM_FL = 0x2;
    pub const DIRSYNC_FL = 0x10000;
    pub const NOTAIL_FL = 0x8000;
    pub const TOPDIR_FL = 0x20000;
    pub const IMMUTABLE_FL = 0x10;
    pub const COMPR_FL = 0x4;
    pub const NOCOW_FL = 0x800000;
};
pub const CLONE = struct {
    pub const IO = 0x80000000;
    pub const NEWTIME = 0x80;
    pub const PIDFD = 0x1000;
    pub const NEWUTS = 0x4000000;
    pub const CHILD_SETTID = 0x1000000;
    pub const CHILD_CLEARTID = 0x200000;
    pub const NEWNS = 0x20000;
    pub const UNTRACED = 0x800000;
    pub const PARENT_SETTID = 0x100000;
    pub const CLEAR_SIGHAND = 0x0;
    pub const NEWPID = 0x20000000;
    pub const SIGHAND = 0x800;
    pub const SETTLS = 0x80000;
    pub const THREAD = 0x10000;
    pub const NEWIPC = 0x8000000;
    pub const NEWCGROUP = 0x2000000;
    pub const SYSVSEM = 0x40000;
    pub const DETACHED = 0x400000;
    pub const NEWUSER = 0x10000000;
    pub const VFORK = 0x4000;
    pub const VM = 0x100;
    pub const FS = 0x200;
    pub const FILES = 0x400;
    pub const NEWNET = 0x40000000;
    pub const PTRACE = 0x2000;
    pub const INTO_CGROUP = 0x0;
};
pub const ID = struct {
    pub const PID = 0x1;
    pub const ALL = 0x0;
    pub const PGID = 0x2;
    pub const PIDFD = 0x3;
};
pub const WAIT = struct {
    pub const NOHANG = 0x1;
    pub const UNTRACED = 0x2;
    pub const CONTINUED = 0x8;
    pub const EXITED = 0x4;
    pub const STOPPED = 0x2;
    pub const NOWAIT = 0x1000000;
    pub const CLONE = 0x80000000;
    pub const NOTHREAD = 0x20000000;
    pub const ALL = 0x40000000;
};
pub const SHUT = struct {
    pub const RD = 0;
    pub const WR = 1;
    pub const RDWR = 2;
};
pub const MOUNT_ATTR = struct {
    pub const RELATIME = 0x0;
    pub const RDONLY = 0x1;
    pub const _ATIME = 0x70;
    pub const NOATIME = 0x10;
    pub const NODIRATIME = 0x80;
    pub const IDMAP = 0x100000;
    pub const NODEV = 0x4;
    pub const STRICTATIME = 0x20;
    pub const NOSUID = 0x2;
    pub const NOEXEC = 0x8;
};
pub const PTRACE = struct {
    pub const GETSIGMASK = 0x420a;
    pub const GETREGSET = 0x4204;
    pub const LISTEN = 0x4208;
    pub const GET_SYSCALL_INFO = 0x420e;
    pub const SECCOMP_GET_FILTER = 0x420c;
    pub const SETREGSET = 0x4205;
    pub const INTERRUPT = 0x4207;
    pub const PEEKSIGINFO = 0x4209;
    pub const SEIZE = 0x4206;
    pub const SETSIGMASK = 0x420b;
};
pub const IOCB_FLAG = struct {
    pub const RESFD = 0x1;
    pub const IOPRIO = 0x2;
};
pub const TRAP = struct {
    pub const BRKPT = 0x1;
    pub const TRACE = 0x2;
    pub const BRANCH = 0x3;
    pub const HWBKPT = 0x4;
};
pub const FUTEX = struct {
    pub const BITSET_MATCH_ANY = 0xffffffff;
    pub const CLOCK_REALTIME = 0x100;
    pub const CMP = struct {
        pub const REQUEUE = 0x4;
        pub const REQUEUE_PI = 0xc;
    };
    pub const FD = 0x2;
    pub const LOCK = struct {
        pub const PI = 0x6;
        pub const PI2 = 0xd;
    };
    pub const OP = struct {
        pub const ADD = 0x1;
        pub const ANDN = 0x3;
        pub const CMP = struct {
            pub const EQ = 0x0;
            pub const GE = 0x5;
            pub const GT = 0x4;
            pub const LE = 0x3;
            pub const LT = 0x2;
            pub const NE = 0x1;
        };
        pub const OR = 0x2;
        pub const SET = 0x0;
        pub const XOR = 0x4;
    };
    pub const OWNER_DIED = 0x40000000;
    pub const PRIVATE_FLAG = 0x80;
    pub const REQUEUE = 0x3;
    pub const TRYLOCK_PI = 0x8;
    pub const UNLOCK_PI = 0x7;
    pub const WAITERS = 0x80000000;
    pub const WAIT = struct {
        // pub const WAIT = 0x0;
        pub const BITSET = 0x9;
        pub const PRIVATE = 0x80;
        pub const REQUEUE_PI = 0xb;
    };
    // pub const WAKE = 0x1;
    pub const WAKE = struct {
        pub const BITSET = 0xa;
        pub const OP = 0x5;
        pub const PRIVATE = 0x81;
    };
};
pub const SO = struct {
    pub const DEBUG = 0x1;
    pub const REUSEADDR = 0x2;
    pub const TYPE = 0x3;
    pub const ERROR = 0x4;
    pub const DONTROUTE = 0x5;
    pub const BROADCAST = 0x6;
    pub const SNDBUF = 0x7;
    pub const RCVBUF = 0x8;
    pub const SNDBUFFORCE = 0x20;
    pub const RCVBUFFORCE = 0x21;
    pub const KEEPALIVE = 0x9;
    pub const OOBINLINE = 0xa;
    pub const NO_CHECK = 0xb;
    pub const PRIORITY = 0xc;
    pub const LINGER = 0xd;
    pub const BSDCOMPAT = 0xe;
    pub const REUSEPORT = 0xf;
    pub const PASSCRED = 0x10;
    pub const PEERCRED = 0x11;
    pub const RCVLOWAT = 0x12;
    pub const SNDLOWAT = 0x13;
    pub const RCVTIMEO_OLD = 0x14;
    pub const SNDTIMEO_OLD = 0x15;
    pub const SECURITY_AUTHENTICATION = 0x16;
    pub const SECURITY_ENCRYPTION_TRANSPORT = 0x17;
    pub const SECURITY_ENCRYPTION_NETWORK = 0x18;
    pub const BINDTODEVICE = 0x19;
    pub const ATTACH_FILTER = 0x1a;
    pub const DETACH_FILTER = 0x1b;
    pub const GET_FILTER = 0x1a;
    pub const PEERNAME = 0x1c;
    pub const ACCEPTCONN = 0x1e;
    pub const PEERSEC = 0x1f;
    pub const PASSSEC = 0x22;
    pub const MARK = 0x24;
    pub const PROTOCOL = 0x26;
    pub const DOMAIN = 0x27;
    pub const RXQ_OVFL = 0x28;
    pub const WIFI_STATUS = 0x29;
    pub const SCM_WIFI_STATUS = 0x29;
    pub const PEEK_OFF = 0x2a;
    pub const NOFCS = 0x2b;
    pub const LOCK_FILTER = 0x2c;
    pub const SELECT_ERR_QUEUE = 0x2d;
    pub const BUSY_POLL = 0x2e;
    pub const MAX_PACING_RATE = 0x2f;
    pub const BPF_EXTENSIONS = 0x30;
    pub const INCOMING_CPU = 0x31;
    pub const ATTACH_BPF = 0x32;
    pub const DETACH_BPF = 0x1b;
    pub const ATTACH_REUSEPORT_CBPF = 0x33;
    pub const ATTACH_REUSEPORT_EBPF = 0x34;
    pub const CNX_ADVICE = 0x35;
    pub const SCM_TIMESTAMPING_OPT_STATS = 0x36;
    pub const MEMINFO = 0x37;
    pub const INCOMING_NAPI_ID = 0x38;
    pub const COOKIE = 0x39;
    pub const SCM_TIMESTAMPING_PKTINFO = 0x3a;
    pub const PEERGROUPS = 0x3b;
    pub const ZEROCOPY = 0x3c;
    pub const TXTIME = 0x3d;
    pub const SCM_TXTIME = 0x3d;
    pub const BINDTOIFINDEX = 0x3e;
    pub const TIMESTAMP_OLD = 0x1d;
    pub const TIMESTAMPNS_OLD = 0x23;
    pub const TIMESTAMPING_OLD = 0x25;
    pub const TIMESTAMP_NEW = 0x3f;
    pub const TIMESTAMPNS_NEW = 0x40;
    pub const TIMESTAMPING_NEW = 0x41;
    pub const RCVTIMEO_NEW = 0x42;
    pub const SNDTIMEO_NEW = 0x43;
    pub const DETACH_REUSEPORT_BPF = 0x44;
    pub const PREFER_BUSY_POLL = 0x45;
    pub const BUSY_POLL_BUDGET = 0x46;
    pub const NETNS_COOKIE = 0x47;
    pub const BUF_LOCK = 0x48;
    pub const RESERVE_MEM = 0x49;
    pub const TXREHASH = 0x4a;
    pub const TIMESTAMP = 0x1d;
    pub const TIMESTAMPNS = 0x23;
    pub const TIMESTAMPING = 0x25;
    pub const RCVTIMEO = 0x14;
    pub const SNDTIMEO = 0x15;
};
pub const AF = struct {
    pub const UNIX = 0x1;
    pub const INET = 0x2;
    pub const INET6 = 0xa;
    pub const NETLINK = 0x10;
};
pub const SOCK = struct {
    pub const STREAM = 0x1;
    pub const DGRAM = 0x2;
    pub const RAW = 0x3;
    pub const NONBLOCK = 0x800;
    pub const CLOEXEC = 0x80000;
};
pub const INADDR = struct {
    pub const ANY = 0x0;
};
pub const IPPROTO = struct {
    pub const IP = 0;
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
    pub const RSVP = 46;
    pub const GRE = 47;
    pub const ESP = 50;
    pub const AH = 51;
    pub const MTP = 92;
    pub const BEETPH = 94;
    pub const ENCAP = 98;
    pub const PIM = 103;
    pub const COMP = 108;
    pub const L2TP = 115;
    pub const SCTP = 132;
    pub const UDPLITE = 136;
    pub const MPLS = 137;
    pub const ETHERNET = 143;
    pub const RAW = 255;
    pub const MPTCP = 262;
    pub const MAX = 263;
    pub const HOPOPTS = 0;
    pub const ROUTING = 43;
    pub const FRAGMENT = 44;
    pub const ICMPV6 = 58;
    pub const NONE = 59;
    pub const DSTOPTS = 60;
    pub const MH = 135;
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
    pub const BIFFUDP = 512;
    pub const WHOSERVER = 513;
    pub const ROUTESERVER = 520;
    pub const RESERVED = 1024;
    pub const USERRESERVED = 5000;
};
pub const ErrorCode = enum(isize) {
    NULL = 0, // No error
    PERM = -1, // Operation not permitted
    NOENT = -2, // No such file or directory
    SRCH = -3, // No such process
    INTR = -4, // Interrupted system call
    IO = -5, // Input/output error
    NXIO = -6, // No such device or address
    @"2BIG" = -7, // Argument list too long
    NOEXEC = -8, // Exec format error
    BADF = -9, // Bad file descriptor
    CHILD = -10, // No child processes
    AGAIN = -11, // Resource temporarily unavailable
    NOMEM = -12, // Cannot allocate memory
    ACCES = -13, // Permission denied
    FAULT = -14, // Bad address
    NOTBLK = -15, // Block device required
    BUSY = -16, // Device or resource busy
    EXIST = -17, // File exists
    XDEV = -18, // Invalid cross-device link
    NODEV = -19, // No such device
    NOTDIR = -20, // Not a directory
    ISDIR = -21, // Is a directory
    INVAL = -22, // Invalid argument
    NFILE = -23, // Too many open files in system
    MFILE = -24, // Too many open files
    NOTTY = -25, // Inappropriate ioctl for device
    TXTBSY = -26, // Text file busy
    FBIG = -27, // File too large
    NOSPC = -28, // No space left on device
    SPIPE = -29, // Illegal seek
    ROFS = -30, // Read-only file system
    MLINK = -31, // Too many links
    PIPE = -32, // Broken pipe
    DOM = -33, // Numerical argument out of domain
    RANGE = -34, // Numerical result out of range
    DEADLK = -35, // Resource deadlock avoided
    NAMETOOLONG = -36, // File name too long
    NOLCK = -37, // No locks available
    NOSYS = -38, // Function not implemented
    NOTEMPTY = -39, // Directory not empty
    LOOP = -40, // Too many levels of symbolic links
    NOMSG = -42, // No message of desired type
    IDRM = -43, // Identifier removed
    CHRNG = -44, // Channel number out of range
    L2NSYNC = -45, // Level 2 not synchronized
    L3HLT = -46, // Level 3 halted
    L3RST = -47, // Level 3 reset
    LNRNG = -48, // Link number out of range
    UNATCH = -49, // Protocol driver not attached
    NOCSI = -50, // No CSI structure available
    L2HLT = -51, // Level 2 halted
    BADE = -52, // Invalid exchange
    BADR = -53, // Invalid request descriptor
    XFULL = -54, // Exchange full
    NOANO = -55, // No anode
    BADRQC = -56, // Invalid request code
    BADSLT = -57, // Invalid slot
    BFONT = -59, // Bad font file format
    NOSTR = -60, // Device not a stream
    NODATA = -61, // No data available
    TIME = -62, // Timer expired
    NOSR = -63, // Out of streams resources
    NONET = -64, // Machine is not on the network
    NOPKG = -65, // Package not installed
    REMOTE = -66, // Object is remote
    NOLINK = -67, // Link has been severed
    ADV = -68, // Advertise error
    SRMNT = -69, // Srmount error
    COMM = -70, // Communication error on send
    PROTO = -71, // Protocol error
    MULTIHOP = -72, // Multihop attempted
    DOTDOT = -73, // RFS specific error
    BADMSG = -74, // Bad message
    OVERFLOW = -75, // Value too large for defined data type
    NOTUNIQ = -76, // Name not unique on network
    BADFD = -77, // File descriptor in bad state
    REMCHG = -78, // Remote address changed
    LIBACC = -79, // Can not access a needed shared library
    LIBBAD = -80, // Accessing a corrupted shared library
    LIBSCN = -81, // .lib section in a.out corrupted
    LIBMAX = -82, // Attempting to link in too many shared libraries
    LIBEXEC = -83, // Cannot exec a shared library directly
    ILSEQ = -84, // Invalid or incomplete multibyte or wide character
    RESTART = -85, // Interrupted system call should be restarted
    STRPIPE = -86, // Streams pipe error
    USERS = -87, // Too many users
    NOTSOCK = -88, // Socket operation on non-socket
    DESTADDRREQ = -89, // Destination address required
    MSGSIZE = -90, // Message too long
    PROTOTYPE = -91, // Protocol wrong type for socket
    NOPROTOOPT = -92, // Protocol not available
    PROTONOSUPPORT = -93, // Protocol not supported
    SOCKTNOSUPPORT = -94, // Socket type not supported
    OPNOTSUPP = -95, // Operation not supported
    PFNOSUPPORT = -96, // Protocol family not supported
    AFNOSUPPORT = -97, // Address family not supported by protocol
    ADDRINUSE = -98, // Address already in use
    ADDRNOTAVAIL = -99, // Cannot assign requested address
    NETDOWN = -100, // Network is down
    NETUNREACH = -101, // Network is unreachable
    NETRESET = -102, // Network dropped connection on reset
    CONNABORTED = -103, // Software caused connection abort
    CONNRESET = -104, // Connection reset by peer
    NOBUFS = -105, // No buffer space available
    ISCONN = -106, // Transport endpoint is already connected
    NOTCONN = -107, // Transport endpoint is not connected
    SHUTDOWN = -108, // Cannot send after transport endpoint shutdown
    TOOMANYREFS = -109, // Too many references: cannot splice
    TIMEDOUT = -110, // Connection timed out
    CONNREFUSED = -111, // Connection refused
    HOSTDOWN = -112, // Host is down
    HOSTUNREACH = -113, // No route to host
    ALREADY = -114, // Operation already in progress
    INPROGRESS = -115, // Operation now in progress
    STALE = -116, // Stale file handle
    UCLEAN = -117, // Structure needs cleaning
    NOTNAM = -118, // Not a XENIX named type file
    NAVAIL = -119, // No XENIX semaphores available
    ISNAM = -120, // Is a named type file
    REMOTEIO = -121, // Remote I/O error
    DQUOT = -122, // Disk quota exceeded
    NOMEDIUM = -123, // No medium found
    MEDIUMTYPE = -124, // Wrong medium type
    CANCELED = -125, // Operation canceled
    NOKEY = -126, // Required key not available
    KEYEXPIRED = -127, // Key has expired
    KEYREVOKED = -128, // Key has been revoked
    KEYREJECTED = -129, // Key was rejected by service
    OWNERDEAD = -130, // Owner died
    NOTRECOVERABLE = -131, // State not recoverable
    RFKILL = -132, // Operation not possible due to RF-kill
    HWPOISON = -133, // Memory page has hardware error
    OPAQUE = -256, // Opaque error
    // WOULDBLOCK = -11, // Resource temporarily unavailable
    // DEADLOCK = -35, // Resource deadlock avoided
    // NOTSUP = -95, // Operation not supported
    pub inline fn errorName(comptime error_code: ErrorCode) []const u8 {
        switch (error_code) {
            .NULL => return "NotAnError",
            .PERM => return "OperationNotPermitted",
            .NOENT => return "NoSuchFileOrDirectory",
            .SRCH => return "NoSuchProcess",
            .INTR => return "InterruptedSystemCall",
            .IO => return "InputOutputError",
            .NXIO => return "NoSuchDeviceOrAddress",
            .@"2BIG" => return "ArgumentListTooLong",
            .NOEXEC => return "ExecFormatError",
            .BADF => return "BadFileDescriptor",
            .CHILD => return "NoChildProcesses",
            .AGAIN => return "ResourceTemporarilyUnavailable",
            .NOMEM => return "CannotAllocateMemory",
            .ACCES => return "PermissionDenied",
            .FAULT => return "BadAddress",
            .NOTBLK => return "BlockDeviceRequired",
            .BUSY => return "DeviceOrResourceBusy",
            .EXIST => return "FileExists",
            .XDEV => return "InvalidCrossDeviceLink",
            .NODEV => return "NoSuchDevice",
            .NOTDIR => return "NotADirectory",
            .ISDIR => return "IsADirectory",
            .INVAL => return "InvalidArgument",
            .NFILE => return "TooManyOpenFilesInSystem",
            .MFILE => return "TooManyOpenFiles",
            .NOTTY => return "InappropriateIoctlForDevice",
            .TXTBSY => return "TextFileBusy",
            .FBIG => return "FileTooLarge",
            .NOSPC => return "NoSpaceLeftOnDevice",
            .SPIPE => return "IllegalSeek",
            .ROFS => return "ReadOnlyFileSystem",
            .MLINK => return "TooManyLinks",
            .PIPE => return "BrokenPipe",
            .DOM => return "NumericalArgumentOutOfDomain",
            .RANGE => return "NumericalResultOutOfRange",
            .DEADLK => return "ResourceDeadlockAvoided",
            .NAMETOOLONG => return "FileNameTooLong",
            .NOLCK => return "NoLocksAvailable",
            .NOSYS => return "FunctionNotImplemented",
            .NOTEMPTY => return "DirectoryNotEmpty",
            .LOOP => return "TooManyLevelsOfSymbolicLinks",
            .NOMSG => return "NoMessageOfDesiredType",
            .IDRM => return "IdentifierRemoved",
            .CHRNG => return "ChannelNumberOutOfRange",
            .L2NSYNC => return "Level2NotSynchronized",
            .L3HLT => return "Level3Halted",
            .L3RST => return "Level3Reset",
            .LNRNG => return "LinkNumberOutOfRange",
            .UNATCH => return "ProtocolDriverNotAttached",
            .NOCSI => return "NoCSIStructureAvailable",
            .L2HLT => return "Level2Halted",
            .BADE => return "InvalidExchange",
            .BADR => return "InvalidRequestDescriptor",
            .XFULL => return "ExchangeFull",
            .NOANO => return "NoAnode",
            .BADRQC => return "InvalidRequestCode",
            .BADSLT => return "InvalidSlot",
            .BFONT => return "BadFontFileFormat",
            .NOSTR => return "DeviceNotAStream",
            .NODATA => return "NoDataAvailable",
            .TIME => return "TimerExpired",
            .NOSR => return "OutOfStreamsResources",
            .NONET => return "MachineNotOnTheNetwork",
            .NOPKG => return "PackageNotInstalled",
            .REMOTE => return "ObjectIsRemote",
            .NOLINK => return "LinkHasBeenSevered",
            .ADV => return "AdvertiseError",
            .SRMNT => return "SrmountError",
            .COMM => return "CommunicationErrorOnSend",
            .PROTO => return "ProtocolError",
            .MULTIHOP => return "MultihopAttempted",
            .DOTDOT => return "RFSSpecificError",
            .BADMSG => return "BadMessage",
            .OVERFLOW => return "ValueTooLargeForDefinedDataType",
            .NOTUNIQ => return "NameNotUniqueOnNetwork",
            .BADFD => return "FileDescriptorInBadState",
            .REMCHG => return "RemoteAddressChanged",
            .LIBACC => return "CanNotAccessANeededSharedLibrary",
            .LIBBAD => return "AccessingACorruptedSharedLibrary",
            .LIBSCN => return "LibSectionInAOutCorrupted",
            .LIBMAX => return "AttemptingToLinkInTooManySharedLibraries",
            .LIBEXEC => return "CannotExecASharedLibraryDirectly",
            .ILSEQ => return "InvalidOrIncompleteMultibyteOrWideCharacter",
            .RESTART => return "InterruptedSystemCallShouldBeRestarted",
            .STRPIPE => return "StreamsPipeError",
            .USERS => return "TooManyUsers",
            .NOTSOCK => return "SocketOperationOnNonSocket",
            .DESTADDRREQ => return "DestinationAddressRequired",
            .MSGSIZE => return "MessageTooLong",
            .PROTOTYPE => return "ProtocolWrongTypeForSocket",
            .NOPROTOOPT => return "ProtocolNotAvailable",
            .PROTONOSUPPORT => return "ProtocolNotSupported",
            .SOCKTNOSUPPORT => return "SocketTypeNotSupported",
            .OPNOTSUPP => return "OperationNotSupported",
            .PFNOSUPPORT => return "ProtocolFamilyNotSupported",
            .AFNOSUPPORT => return "AddressFamilyNotSupportedByProtocol",
            .ADDRINUSE => return "AddressAlreadyInUse",
            .ADDRNOTAVAIL => return "CannotAssignRequestedAddress",
            .NETDOWN => return "NetworkDown",
            .NETUNREACH => return "NetworkUnreachable",
            .NETRESET => return "NetworkDroppedConnectionOnReset",
            .CONNABORTED => return "SoftwareCausedConnectionAbort",
            .CONNRESET => return "ConnectionResetByPeer",
            .NOBUFS => return "NoBufferSpaceAvailable",
            .ISCONN => return "TransportEndpointAlreadyConnected",
            .NOTCONN => return "TransportEndpointNotConnected",
            .SHUTDOWN => return "CannotSendAfterTransportEndpointShutdown",
            .TOOMANYREFS => return "TooManyReferencesCannotSplice",
            .TIMEDOUT => return "ConnectionTimedOut",
            .CONNREFUSED => return "ConnectionRefused",
            .HOSTDOWN => return "HostDown",
            .HOSTUNREACH => return "NoRouteToHost",
            .ALREADY => return "OperationAlreadyInProgress",
            .INPROGRESS => return "OperationNowInProgress",
            .STALE => return "StaleFileHandle",
            .UCLEAN => return "StructureNeedsCleaning",
            .NOTNAM => return "NotAXENIXNamedTypeFile",
            .NAVAIL => return "NoXENIXSemaphoresAvailable",
            .ISNAM => return "IsNamedTypeFile",
            .REMOTEIO => return "RemoteIOError",
            .DQUOT => return "DiskQuotaExceeded",
            .NOMEDIUM => return "NoMediumFound",
            .MEDIUMTYPE => return "WrongMediumType",
            .CANCELED => return "OperationCanceled",
            .NOKEY => return "RequiredKeyNotAvailable",
            .KEYEXPIRED => return "KeyHasExpired",
            .KEYREVOKED => return "KeyHasBeenRevoked",
            .KEYREJECTED => return "KeyWasRejectedByService",
            .OWNERDEAD => return "OwnerDied",
            .NOTRECOVERABLE => return "StateNotRecoverable",
            .RFKILL => return "OperationNotPossibleDueToRFKill",
            .HWPOISON => return "MemoryPageHasHardwareError",
            .OPAQUE => return "SystemError",
        }
    }
};
pub const ErrorPolicy = builtin.ExternalError(ErrorCode);
pub const SignalCode = enum(u32) {
    HUP = 1,
    INT = 2,
    QUIT = 3,
    ILL = 4,
    TRAP = 5,
    ABRT = 6,
    BUS = 7,
    FPE = 8,
    KILL = 9,
    SEGV = 11,
    PIPE = 13,
    ALRM = 14,
    TERM = 15,
    STKFLT = 16,
    CHLD = 17,
    CONT = 18,
    STOP = 19,
    TSTP = 20,
    TTIN = 21,
    TTOU = 22,
    URG = 23,
    XCPU = 24,
    XFSZ = 25,
    VTALRM = 26,
    PROF = 27,
    WINCH = 28,
    IO = 29,
    PWR = 30,
    SYS = 31,
    pub inline fn errorName(comptime error_code: SignalCode) []const u8 {
        switch (error_code) {
            .HUP => return "Hangup",
            .INT => return "Interrupt",
            .QUIT => return "Quit",
            .ILL => return "IllegalInstruction",
            .TRAP => return "Trap",
            .ABRT => return "Abort",
            .BUS => return "BusError",
            .FPE => return "FloatingPointError",
            .KILL => return "Kill",
            .SEGV => return "SegmentationFault",
            .PIPE => return "BrokenPipe",
            .ALRM => return "Alarm",
            .TERM => return "Terminate",
            .CHILD => return "Child",
            .CONT => return "Continue",
            .STOP => return "Stop",
            .TSTP => return "TerminalStop",
            .TTIN => return "TerminalInput",
            .TTOU => return "TerminalOutput",
            .XCPU => return "CPUTimeExceeded",
            .XFSZ => return "FileSizeExceeded",
            .VTALRM => return "VirtualAlarm",
            .PROF => return "TimerExpired",
            .WINCH => return "WindowChanged",
            .IO => return "IO",
            .PWR => return "PowerFailure",
            .SYS => return "BadSystemCall",
            .URG => return "Urgent",
            .STKFLT => return "StackFault",
        }
    }
};
pub const SignalPolicy = builtin.ExternalError(SignalCode);
pub const Fn = enum(usize) {
    read = 0,
    write = 1,
    open = 2,
    close = 3,
    stat = 4,
    fstat = 5,
    lstat = 6,
    poll = 7,
    lseek = 8,
    mmap = 9,
    mprotect = 10,
    munmap = 11,
    brk = 12,
    rt_sigaction = 13,
    rt_sigprocmask = 14,
    rt_sigreturn = 15,
    ioctl = 16,
    pread = 17,
    pwrite = 18,
    readv = 19,
    writev = 20,
    access = 21,
    pipe = 22,
    select = 23,
    sched_yield = 24,
    mremap = 25,
    msync = 26,
    mincore = 27,
    madvise = 28,
    shmget = 29,
    shmat = 30,
    shmctl = 31,
    dup = 32,
    dup2 = 33,
    pause = 34,
    nanosleep = 35,
    getitimer = 36,
    alarm = 37,
    setitimer = 38,
    getpid = 39,
    sendfile = 40,
    socket = 41,
    connect = 42,
    accept = 43,
    sendto = 44,
    recvfrom = 45,
    sendmsg = 46,
    recvmsg = 47,
    shutdown = 48,
    bind = 49,
    listen = 50,
    getsockname = 51,
    getpeername = 52,
    socketpair = 53,
    setsockopt = 54,
    getsockopt = 55,
    clone = 56,
    fork = 57,
    vfork = 58,
    execve = 59,
    exit = 60,
    wait4 = 61,
    kill = 62,
    uname = 63,
    semget = 64,
    semop = 65,
    semctl = 66,
    shmdt = 67,
    msgget = 68,
    msgsnd = 69,
    msgrcv = 70,
    msgctl = 71,
    fcntl = 72,
    flock = 73,
    fsync = 74,
    fdatasync = 75,
    truncate = 76,
    ftruncate = 77,
    getdents = 78,
    getcwd = 79,
    chdir = 80,
    fchdir = 81,
    rename = 82,
    mkdir = 83,
    rmdir = 84,
    creat = 85,
    link = 86,
    unlink = 87,
    symlink = 88,
    readlink = 89,
    chmod = 90,
    fchmod = 91,
    chown = 92,
    fchown = 93,
    lchown = 94,
    umask = 95,
    gettimeofday = 96,
    getrlimit = 97,
    getrusage = 98,
    sysinfo = 99,
    times = 100,
    ptrace = 101,
    getuid = 102,
    syslog = 103,
    getgid = 104,
    setuid = 105,
    setgid = 106,
    geteuid = 107,
    getegid = 108,
    setpgid = 109,
    getppid = 110,
    getpgrp = 111,
    setsid = 112,
    setreuid = 113,
    setregid = 114,
    getgroups = 115,
    setgroups = 116,
    setresuid = 117,
    getresuid = 118,
    setresgid = 119,
    getresgid = 120,
    getpgid = 121,
    setfsuid = 122,
    setfsgid = 123,
    getsid = 124,
    capget = 125,
    capset = 126,
    rt_sigpending = 127,
    rt_sigtimedwait = 128,
    rt_sigqueueinfo = 129,
    rt_sigsuspend = 130,
    sigaltstack = 131,
    utime = 132,
    mknod = 133,
    uselib = 134,
    personality = 135,
    ustat = 136,
    statfs = 137,
    fstatfs = 138,
    sysfs = 139,
    getpriority = 140,
    setpriority = 141,
    sched_setparam = 142,
    sched_getparam = 143,
    sched_setscheduler = 144,
    sched_getscheduler = 145,
    sched_get_priority_max = 146,
    sched_get_priority_min = 147,
    sched_rr_get_interval = 148,
    mlock = 149,
    munlock = 150,
    mlockall = 151,
    munlockall = 152,
    vhangup = 153,
    modify_ldt = 154,
    pivot_root = 155,
    _sysctl = 156,
    prctl = 157,
    arch_prctl = 158,
    adjtimex = 159,
    setrlimit = 160,
    chroot = 161,
    sync = 162,
    acct = 163,
    settimeofday = 164,
    mount = 165,
    umount2 = 166,
    swapon = 167,
    swapoff = 168,
    reboot = 169,
    sethostname = 170,
    setdomainname = 171,
    iopl = 172,
    ioperm = 173,
    create_module = 174,
    init_module = 175,
    delete_module = 176,
    get_kernel_syms = 177,
    query_module = 178,
    quotactl = 179,
    nfsservctl = 180,
    getpmsg = 181,
    putpmsg = 182,
    afs_syscall = 183,
    tuxcall = 184,
    security = 185,
    gettid = 186,
    readahead = 187,
    setxattr = 188,
    lsetxattr = 189,
    fsetxattr = 190,
    getxattr = 191,
    lgetxattr = 192,
    fgetxattr = 193,
    listxattr = 194,
    llistxattr = 195,
    flistxattr = 196,
    removexattr = 197,
    lremovexattr = 198,
    fremovexattr = 199,
    tkill = 200,
    time = 201,
    futex = 202,
    sched_setaffinity = 203,
    sched_getaffinity = 204,
    set_thread_area = 205,
    io_setup = 206,
    io_destroy = 207,
    io_getevents = 208,
    io_submit = 209,
    io_cancel = 210,
    get_thread_area = 211,
    lookup_dcookie = 212,
    epoll_create = 213,
    epoll_ctl_old = 214,
    epoll_wait_old = 215,
    remap_file_pages = 216,
    getdents64 = 217,
    set_tid_address = 218,
    restart_syscall = 219,
    semtimedop = 220,
    fadvise64 = 221,
    timer_create = 222,
    timer_settime = 223,
    timer_gettime = 224,
    timer_getoverrun = 225,
    timer_delete = 226,
    clock_settime = 227,
    clock_gettime = 228,
    clock_getres = 229,
    clock_nanosleep = 230,
    exit_group = 231,
    epoll_wait = 232,
    epoll_ctl = 233,
    tgkill = 234,
    utimes = 235,
    vserver = 236,
    mbind = 237,
    set_mempolicy = 238,
    get_mempolicy = 239,
    mq_open = 240,
    mq_unlink = 241,
    mq_timedsend = 242,
    mq_timedreceive = 243,
    mq_notify = 244,
    mq_getsetattr = 245,
    kexec_load = 246,
    waitid = 247,
    add_key = 248,
    request_key = 249,
    keyctl = 250,
    ioprio_set = 251,
    ioprio_get = 252,
    inotify_init = 253,
    inotify_add_watch = 254,
    inotify_rm_watch = 255,
    migrate_pages = 256,
    openat = 257,
    mkdirat = 258,
    mknodat = 259,
    fchownat = 260,
    futimesat = 261,
    newfstatat = 262,
    unlinkat = 263,
    renameat = 264,
    linkat = 265,
    symlinkat = 266,
    readlinkat = 267,
    fchmodat = 268,
    faccessat = 269,
    pselect6 = 270,
    ppoll = 271,
    unshare = 272,
    set_robust_list = 273,
    get_robust_list = 274,
    splice = 275,
    tee = 276,
    sync_file_range = 277,
    vmsplice = 278,
    move_pages = 279,
    utimensat = 280,
    epoll_pwait = 281,
    signalfd = 282,
    timerfd_create = 283,
    eventfd = 284,
    fallocate = 285,
    timerfd_settime = 286,
    timerfd_gettime = 287,
    accept4 = 288,
    signalfd4 = 289,
    eventfd2 = 290,
    epoll_create1 = 291,
    dup3 = 292,
    pipe2 = 293,
    inotify_init1 = 294,
    preadv = 295,
    pwritev = 296,
    rt_tgsigqueueinfo = 297,
    perf_event_open = 298,
    recvmmsg = 299,
    fanotify_init = 300,
    fanotify_mark = 301,
    prlimit64 = 302,
    name_to_handle_at = 303,
    open_by_handle_at = 304,
    clock_adjtime = 305,
    syncfs = 306,
    sendmmsg = 307,
    setns = 308,
    getcpu = 309,
    process_vm_readv = 310,
    process_vm_writev = 311,
    kcmp = 312,
    finit_module = 313,
    sched_setattr = 314,
    sched_getattr = 315,
    renameat2 = 316,
    seccomp = 317,
    getrandom = 318,
    memfd_create = 319,
    kexec_file_load = 320,
    bpf = 321,
    execveat = 322,
    userfaultfd = 323,
    membarrier = 324,
    mlock2 = 325,
    copy_file_range = 326,
    preadv2 = 327,
    pwritev2 = 328,
    pkey_mprotect = 329,
    pkey_alloc = 330,
    pkey_free = 331,
    statx = 332,
    io_pgetevents = 333,
    rseq = 334,
    pidfd_send_signal = 424,
    io_uring_setup = 425,
    io_uring_enter = 426,
    io_uring_register = 427,
    open_tree = 428,
    move_mount = 429,
    fsopen = 430,
    fsconfig = 431,
    fsmount = 432,
    fspick = 433,
    pidfd_open = 434,
    clone3 = 435,
    close_range = 436,
    openat2 = 437,
    pidfd_getfd = 438,
    faccessat2 = 439,
    process_madvise = 440,
    epoll_pwait2 = 441,
    mount_setattr = 442,
    quotactl_fd = 443,
    landlock_create_ruleset = 444,
    landlock_add_rule = 445,
    landlock_restrict_self = 446,
    memfd_secret = 447,
    fn args(comptime function: Fn) comptime_int {
        return switch (function) {
            .fork,
            .getuid,
            .getgid,
            .geteuid,
            .getegid,
            .sync,
            => 0,
            .rmdir,
            .dup,
            .close,
            .brk,
            .unlink,
            .exit,
            .chdir,
            .syncfs,
            .fsync,
            .fdatasync,
            => 1,
            .memfd_create,
            .stat,
            .fstat,
            .lstat,
            .munmap,
            .getcwd,
            .truncate,
            .ftruncate,
            .mkdir,
            .clock_gettime,
            .nanosleep,
            .dup2,
            .clone3,
            .pipe2,
            .listen,
            .symlink,
            .link,
            => 2,
            .dup3,
            .read,
            .write,
            .open,
            .socket,
            .ioctl,
            .madvise,
            .mprotect,
            .mknod,
            .execve,
            .getdents64,
            .readlink,
            .getrandom,
            .unlinkat,
            .mkdirat,
            .open_by_handle_at,
            .poll,
            .bind,
            .lseek,
            .connect,
            .symlinkat,
            => 3,
            .newfstatat,
            .mknodat,
            .readlinkat,
            .openat,
            .rt_sigaction,
            .sendfile,
            => 4,
            .mremap,
            .statx,
            .wait4,
            .waitid,
            .clone,
            .execveat,
            .name_to_handle_at,
            .linkat,
            => 5,
            .copy_file_range,
            .futex,
            .mmap,
            .recvfrom,
            .sendto,
            => 6,
            else => @compileError(@tagName(function)),
        };
    }
};
pub const vFn = enum(u9) {
    clock_gettime,
    getcpu,
    gettimeofday,
    time,
};
pub const brk_errors = &[_]ErrorCode{.NOMEM};
pub const chdir_errors = &[_]ErrorCode{
    .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
};
pub const copy_file_range_errors = &[_]ErrorCode{
    .BADF,  .FBIG,      .INVAL,    .IO,   .ISDIR,  .NOMEM,
    .NOSPC, .OPNOTSUPP, .OVERFLOW, .PERM, .TXTBSY, .XDEV,
};
pub const sendfile_errors = &[_]ErrorCode{
    .AGAIN, .FAULT,    .INVAL, .IO,
    .NOMEM, .OVERFLOW, .SPIPE,
};
pub const link_errors = &[_]ErrorCode{
    .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .IO,   .LOOP,  .NAMETOOLONG,
    .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS, .MLINK, .XDEV,
    .INVAL,
};
pub const sync_errors = &[_]ErrorCode{ .BADF, .IO };
pub const sync_file_range_errors = &[_]ErrorCode{};
pub const close_errors = &[_]ErrorCode{
    .INTR, .IO, .BADF, .NOSPC,
};
pub const clone_errors = &[_]ErrorCode{
    .PERM, .AGAIN, .INVAL, .EXIST, .USERS, .OPNOTSUPP, .NOMEM, .RESTART,
    .BUSY, .NOSPC,
};
pub const clock_get_errors = &[_]ErrorCode{
    .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
};
pub const execve_errors = &[_]ErrorCode{
    .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
    .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
    .INVAL, .NOEXEC,
};
pub const execveat_errors = &[_]ErrorCode{
    .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
    .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
    .INVAL, .NOEXEC,
};
pub const fork_errors = &[_]ErrorCode{
    .NOSYS, .AGAIN, .NOMEM, .RESTART,
};
pub const command_errors = execve_errors ++ fork_errors ++ wait_errors;
pub const getcwd_errors = &[_]ErrorCode{
    .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
};
pub const getdents_errors = &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
};
pub const getrandom_errors = &[_]ErrorCode{
    .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
};
pub const dup_errors = &[_]ErrorCode{
    .BADF, .BUSY, .INTR, .INVAL, .MFILE,
};
pub const pipe_errors = &[_]ErrorCode{
    .FAULT, .INVAL, .MFILE, .NFILE, .NOPKG,
};
pub const poll_errors = &[_]ErrorCode{
    .FAULT, .INTR, .INVAL, .NOMEM,
};
pub const ioctl_errors = &[_]ErrorCode{
    .NOTTY, .BADF, .FAULT, .INVAL,
};
pub const socket_errors = &[_]ErrorCode{
    .ACCES, .AFNOSUPPORT, .INVAL, .MFILE,
    .NFILE, .NOBUFS,      .NOMEM, .PROTONOSUPPORT,
};
pub const bind_errors = &[_]ErrorCode{
    .ACCES,        .ADDRINUSE, .BADF, .INVAL,       .NOTSOCK, .ACCES,
    .ADDRNOTAVAIL, .FAULT,     .LOOP, .NAMETOOLONG, .NOENT,   .NOMEM,
    .NOTDIR,       .ROFS,
};
pub const accept_errors = &[_]ErrorCode{
    .AGAIN, .BADF,  .CONNABORTED, .FAULT, .INTR,    .INVAL,
    .MFILE, .NFILE, .NOBUFS,      .NOMEM, .NOTSOCK, .OPNOTSUPP,
    .PERM,  .PROTO,
};
pub const listen_errors = &[_]ErrorCode{
    .INVAL, .ADDRINUSE, .BADF, .NOTSOCK, .OPNOTSUPP,
};
pub const connect_errors = &[_]ErrorCode{
    .ACCES,    .PERM,    .ADDRINUSE,  .ADDRNOTAVAIL, .AFNOSUPPORT,
    .AGAIN,    .ALREADY, .BADF,       .CONNREFUSED,  .FAULT,
    .INTR,     .ISCONN,  .NETUNREACH, .NOTSOCK,      .PROTOTYPE,
    .TIMEDOUT,
};
pub const getsockname_errors = &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .NOBUFS, .NOTSOCK,
};
pub const getpeername_errors = &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .NOBUFS, .NOTCONN, .NOTSOCK,
};
pub const send_errors = &[_]ErrorCode{
    .ACCES,       .AGAIN,  .ALREADY, .BADF,    .CONNRESET,
    .DESTADDRREQ, .FAULT,  .INTR,    .INVAL,   .ISCONN,
    .MSGSIZE,     .NOBUFS, .NOMEM,   .NOTCONN, .NOTSOCK,
    .OPNOTSUPP,   .PIPE,
};
pub const recv_errors = &[_]ErrorCode{
    .AGAIN, .BADF,    .CONNREFUSED, .FAULT, .INTR, .INVAL,
    .NOMEM, .NOTCONN, .NOTSOCK,
};
pub const sockopt_errors = &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .NOPROTOOPT, .NOTSOCK,
};
pub const shutdown_errors = &[_]ErrorCode{
    .BADF, .INVAL, .NOTCONN, .NOTSOCK,
};
pub const madvise_errors = &[_]ErrorCode{
    .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
};
pub const mprotect_errors = &[_]ErrorCode{ .ACCES, .INVAL, .NOMEM };
pub const mkdir_noexcl_errors = &[_]ErrorCode{
    .ACCES,       .BADF,  .DQUOT, .FAULT, .INVAL,  .LOOP, .MLINK,
    .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM, .ROFS,
};
pub const mkdir_errors = &[_]ErrorCode{
    .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
    .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
};
pub const mmap_errors = &[_]ErrorCode{
    .ACCES, .AGAIN,  .BADF, .EXIST, .INVAL, .NFILE, .NODEV, .NOMEM, .OVERFLOW,
    .PERM,  .TXTBSY,
};
pub const msync_errors = &[_]ErrorCode{ .BUSY, .INVAL, .NOMEM };
pub const memfd_create_errors = &[_]ErrorCode{ .FAULT, .INVAL, .MFILE, .NOMEM };
pub const seek_errors = &[_]ErrorCode{ .BADF, .NXIO, .OVERFLOW, .SPIPE };
pub const truncate_errors = &[_]ErrorCode{
    .ACCES,  .FAULT, .FBIG, .INTR,   .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
    .NOTDIR, .PERM,  .ROFS, .TXTBSY, .BADF, .INVAL,
};
pub const munmap_errors = &[_]ErrorCode{.INVAL};
pub const mknod_errors = &[_]ErrorCode{
    .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .INVAL, .LOOP, .NAMETOOLONG,
    .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
};
pub const mremap_errors = &[_]ErrorCode{
    .AGAIN, .FAULT, .INVAL, .NOMEM,
};
pub const open_errors = &[_]ErrorCode{
    .ACCES, .FBIG,        .NOTDIR,   .EXIST,  .OPNOTSUPP, .MFILE, .NOSPC,
    .NOENT, .NAMETOOLONG, .OVERFLOW, .TXTBSY, .AGAIN,     .BADF,  .ISDIR,
    .LOOP,  .NODEV,       .DQUOT,    .NOMEM,  .ROFS,      .NFILE, .INTR,
    .PERM,  .FAULT,       .INVAL,    .NXIO,   .BUSY,
};
pub const open_by_handle_at_errors = open_errors ++ &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .LOOP, .PERM, .STALE,
};
pub const name_to_handle_at_errors = open_errors ++ &[_]ErrorCode{
    .OVERFLOW, .LOOP, .PERM, .BADF, .FAULT, .INVAL, .NOTDIR, .STALE,
};
pub const nanosleep_errors = &[_]ErrorCode{
    .INTR, .FAULT, .INVAL, .OPNOTSUPP,
};
pub const readlink_errors = &[_]ErrorCode{
    .ACCES,  .BADF, .FAULT, .INVAL, .IO, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR,
};
pub const read_errors = &[_]ErrorCode{
    .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
};
pub const rmdir_errors = &[_]ErrorCode{
    .ACCES,  .BUSY,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .NOTEMPTY, .PERM,  .ROFS,
};
pub const sigaction_errors = &[_]ErrorCode{
    .FAULT, .INVAL,
};
pub const stat_errors = &[_]ErrorCode{
    .ACCES,  .BADF,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .OVERFLOW,
};
pub const statx_errors = &[_]ErrorCode{
    .ACCES,  .BADF,        .FAULT, .INVAL,
    .LOOP,   .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR,
};
pub const unlink_errors = &[_]ErrorCode{
    .ACCES,  .BUSY, .FAULT, .IO,   .ISDIR, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
};
pub const wait_errors = &[_]ErrorCode{
    .SRCH, .INTR, .AGAIN, .INVAL, .CHILD,
};
pub const waitid_errors = &[_]ErrorCode{
    .AGAIN, .CHILD, .INTR, .INVAL, .SRCH,
};
pub const write_errors = &[_]ErrorCode{
    .AGAIN, .BADF, .DESTADDRREQ, .DQUOT, .FAULT, .FBIG, .INTR, .INVAL, .IO,
    .NOSPC, .PERM, .PIPE,
};
pub const futex_errors = &.{
    .ACCES, .AGAIN, .DEADLK, .FAULT, .INTR, .INVAL,    .NFILE,
    .NOMEM, .NOSYS, .PERM,   .PERM,  .SRCH, .TIMEDOUT,
};
pub const no_errors = &[_]ErrorCode{};
//    Arch/ABI      arg1  arg2  arg3  arg4  arg5  arg6  arg7  Notes
//    ──────────────────────────────────────────────────────────────
//    alpha         a0    a1    a2    a3    a4    a5    -
//    arc           r0    r1    r2    r3    r4    r5    -
//    arm/OABI      r0    r1    r2    r3    r4    r5    r6
//    arm/EABI      r0    r1    r2    r3    r4    r5    r6
//    arm64         x0    x1    x2    x3    x4    x5    -
//    blackfin      R0    R1    R2    R3    R4    R5    -
//    i386          ebx   ecx   edx   esi   edi   ebp   -
//    ia64          out0  out1  out2  out3  out4  out5  -
//    m68k          d1    d2    d3    d4    d5    a0    -
//    microblaze    r5    r6    r7    r8    r9    r10   -
//    mips/o32      a0    a1    a2    a3    -     -     -     1
//    mips/n32,64   a0    a1    a2    a3    a4    a5    -
//    nios2         r4    r5    r6    r7    r8    r9    -
//    parisc        r26   r25   r24   r23   r22   r21   -
//    powerpc       r3    r4    r5    r6    r7    r8    r9
//    powerpc64     r3    r4    r5    r6    r7    r8    -
//    riscv         a0    a1    a2    a3    a4    a5    -
//    s390          r2    r3    r4    r5    r6    r7    -
//    s390x         r2    r3    r4    r5    r6    r7    -
//    superh        r4    r5    r6    r7    r0    r1    r2
//    sparc/32      o0    o1    o2    o3    o4    o5    -
//    sparc/64      o0    o1    o2    o3    o4    o5    -
//    tile          R00   R01   R02   R03   R04   R05   -
//    x86-64        rdi   rsi   rdx   r10   r8    r9    -     X
//    x32           rdi   rsi   rdx   r10   r8    r9    -
//    xtensa        a6    a3    a4    a5    a8    a9    -
inline fn syscall0(comptime sys_fn_info: Fn, _: [0]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
        : "rax", "rcx", "r11", "memory"
    );
}
inline fn syscall1(comptime sys_fn_info: Fn, args: [1]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall2(comptime sys_fn_info: Fn, args: [2]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
          [_] "{rsi}" (args[1]),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall3(comptime sys_fn_info: Fn, args: [3]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
          [_] "{rsi}" (args[1]),
          [_] "{rdx}" (args[2]),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall4(comptime sys_fn_info: Fn, args: [4]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
          [_] "{rsi}" (args[1]),
          [_] "{rdx}" (args[2]),
          [_] "{r10}" (args[3]),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall5(comptime sys_fn_info: Fn, args: [5]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
          [_] "{rsi}" (args[1]),
          [_] "{rdx}" (args[2]),
          [_] "{r10}" (args[3]),
          [_] "{r8}" (args[4]),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall6(comptime sys_fn_info: Fn, args: [6]usize) isize {
    return asm volatile ("syscall # " ++ @tagName(sys_fn_info)
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sys_fn_info),
          [_] "{rdi}" (args[0]),
          [_] "{rsi}" (args[1]),
          [_] "{rdx}" (args[2]),
          [_] "{r10}" (args[3]),
          [_] "{r8}" (args[4]),
          [_] "{r9}" (args[5]),
        : "rcx", "r11", "memory"
    );
}
pub fn ErrorUnion(comptime error_policy: ErrorPolicy, comptime return_type: type) type {
    if (error_policy.throw.len != 0) {
        if (@typeInfo(return_type) == .ErrorUnion) {
            return (builtin.ZigError(ErrorCode, error_policy.throw) ||
                @typeInfo(return_type).ErrorUnion.error_set)!@typeInfo(return_type).ErrorUnion.payload;
        } else {
            return builtin.ZigError(ErrorCode, error_policy.throw)!return_type;
        }
    }
    return return_type;
}
pub fn Error(comptime errors: []const ErrorCode) type {
    return builtin.ZigError(ErrorCode, errors);
}

inline fn cast(args: anytype) [args.len]usize {
    switch (args.len) {
        0 => return .{},
        1 => return .{
            meta.bitCast(usize, args[0]),
        },
        2 => return .{
            meta.bitCast(usize, args[0]),
            meta.bitCast(usize, args[1]),
        },
        3 => return .{
            meta.bitCast(usize, args[0]),
            meta.bitCast(usize, args[1]),
            meta.bitCast(usize, args[2]),
        },
        4 => return .{
            meta.bitCast(usize, args[0]),
            meta.bitCast(usize, args[1]),
            meta.bitCast(usize, args[2]),
            meta.bitCast(usize, args[3]),
        },
        5 => return .{
            meta.bitCast(usize, args[0]),
            meta.bitCast(usize, args[1]),
            meta.bitCast(usize, args[2]),
            meta.bitCast(usize, args[3]),
            meta.bitCast(usize, args[4]),
            meta.bitCast(usize, args[5]),
        },
        6 => return .{
            meta.bitCast(usize, args[0]),
            meta.bitCast(usize, args[1]),
            meta.bitCast(usize, args[2]),
            meta.bitCast(usize, args[3]),
            meta.bitCast(usize, args[4]),
            meta.bitCast(usize, args[5]),
        },
        else => unreachable,
    }
}
const syscalls = .{
    syscall0, syscall1,
    syscall2, syscall3,
    syscall4, syscall5,
    syscall6,
};
pub fn call(comptime tag: Fn, comptime errors: ErrorPolicy, comptime return_type: type, args: [tag.args()]usize) ErrorUnion(errors, return_type) {
    const ret: isize = (comptime syscalls[tag.args()])(tag, args);
    if (return_type == noreturn) {
        unreachable;
    }
    if (errors.throw.len != 0) {
        try builtin.zigErrorThrow(ErrorCode, errors.throw, ret);
    }
    if (errors.abort.len != 0) {
        builtin.zigErrorAbort(ErrorCode, errors.abort, ret);
    }
    if (@sizeOf(return_type) == @sizeOf(usize)) {
        return @bitCast(return_type, ret);
    }
    if (return_type != void) {
        return @intCast(return_type, ret);
    }
}
pub fn call_noexcept(comptime tag: Fn, comptime return_type: type, args: anytype) return_type {
    const ret: isize = (comptime syscalls[tag.args()])(tag, cast(args));
    if (return_type == noreturn) {
        unreachable;
    }
    if (@sizeOf(return_type) == @sizeOf(usize)) {
        return @bitCast(return_type, ret);
    }
    if (return_type != void) {
        return @intCast(return_type, ret);
    }
}
