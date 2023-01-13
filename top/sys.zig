//! Linux x86_64
pub const MAP = opaque {
    pub const FILE: usize = 0x0;
    pub const SHARED: usize = 0x1;
    pub const PRIVATE: usize = 0x2;
    pub const SHARED_VALIDATE: usize = 0x3;
    pub const TYPE: usize = 0xf;
    pub const FIXED: usize = 0x10;
    pub const ANONYMOUS: usize = 0x20;
    pub const HUGE_SHIFT: usize = 0x1a;
    pub const HUGE_MASK: usize = 0x3f;
    pub const @"32BIT": usize = 0x40;
    pub const GROWSDOWN: usize = 0x100;
    pub const DENYWRITE: usize = 0x800;
    pub const EXECUTABLE: usize = 0x1000;
    pub const LOCKED: usize = 0x2000;
    pub const NORESERVE: usize = 0x4000;
    pub const POPULATE: usize = 0x8000;
    pub const NONBLOCK: usize = 0x10000;
    pub const STACK: usize = 0x20000;
    pub const HUGETLB: usize = 0x40000;
    pub const SYNC: usize = 0x80000;
    pub const FIXED_NOREPLACE: usize = 0x100000;
};
pub const MFD = opaque {
    pub const CLOEXEC: usize = 0x1;
    pub const ALLOW_SEALING: usize = 0x2;
    pub const HUGETLB: usize = 0x4;
};
pub const PROT = opaque {
    pub const NONE: usize = 0x0;
    pub const READ: usize = 0x1;
    pub const WRITE: usize = 0x2;
    pub const EXEC: usize = 0x4;
    pub const GROWSDOWN: usize = 0x1000000;
    pub const GROWSUP: usize = 0x2000000;
};
pub const REMAP = opaque {
    pub const RESIZE: usize = 0x0;
    pub const MAYMOVE: usize = 0x1;
    pub const FIXED: usize = 0x2;
    pub const DONTUNMAP: usize = 0x4;
};
pub const MADV = opaque {
    pub const NORMAL: usize = 0x0;
    pub const RANDOM: usize = 0x1;
    pub const SEQUENTIAL: usize = 0x2;
    pub const WILLNEED: usize = 0x3;
    pub const DONTNEED: usize = 0x4;
    pub const FREE: usize = 0x8;
    pub const REMOVE: usize = 0x9;
    pub const DONTFORK: usize = 0xa;
    pub const DOFORK: usize = 0xb;
    pub const MERGEABLE: usize = 0xc;
    pub const UNMERGEABLE: usize = 0xd;
    pub const HUGEPAGE: usize = 0xe;
    pub const NOHUGEPAGE: usize = 0xf;
    pub const DONTDUMP: usize = 0x10;
    pub const DODUMP: usize = 0x11;
    pub const WIPEONFORK: usize = 0x12;
    pub const KEEPONFORK: usize = 0x13;
    pub const COLD: usize = 0x14;
    pub const PAGEOUT: usize = 0x15;
    pub const HWPOISON: usize = 0x64;
};
pub const MCL = opaque {
    pub const CURRENT: usize = 0x1;
    pub const FUTURE: usize = 0x2;
    pub const ONFAULT: usize = 0x4;
};
pub const O = opaque {
    pub const LARGEFILE: usize = 0x0;
    pub const RDONLY: usize = 0x0;
    pub const WRONLY: usize = 0x1;
    pub const RDWR: usize = 0x2;
    pub const CREAT: usize = 0x40;
    pub const EXCL: usize = 0x80;
    pub const ACCMODE: usize = 0x3;
    pub const NOCTTY: usize = 0x100;
    pub const TRUNC: usize = 0x200;
    pub const APPEND: usize = 0x400;
    pub const NONBLOCK: usize = 0x800;
    pub const SYNC: usize = 0x101000;
    pub const ASYNC: usize = 0x2000;
    pub const DIRECTORY: usize = 0x10000;
    pub const NOFOLLOW: usize = 0x20000;
    pub const CLOEXEC: usize = 0x80000;
    pub const DIRECT: usize = 0x4000;
    pub const NOATIME: usize = 0x40000;
    pub const PATH: usize = 0x200000;
    pub const DSYNC: usize = 0x1000;
    pub const TMPFILE: usize = 0x400000;
};
pub const LOCK = opaque {
    pub const SH: usize = 0x1;
    pub const EX: usize = 0x2;
    pub const NB: usize = 0x4;
    pub const UN: usize = 0x8;
};
pub const POSIX = opaque {
    pub const MADV = opaque {
        pub const NORMAL: usize = 0x0;
        pub const RANDOM: usize = 0x1;
        pub const SEQUENTIAL: usize = 0x2;
        pub const WILLNEED: usize = 0x3;
        pub const DONTNEED: usize = 0x4;
    };
    pub const FADV = opaque {
        pub const NORMAL: usize = 0x0;
        pub const RANDOM: usize = 0x1;
        pub const SEQUENTIAL: usize = 0x2;
        pub const WILLNEED: usize = 0x3;
        pub const DONTNEED: usize = 0x4;
        pub const NOREUSE: usize = 0x5;
    };
};
pub const S = opaque {
    pub const IFMT: usize = 0xf000;
    pub const IFDIR: usize = 0x4000;
    pub const IFCHR: usize = 0x2000;
    pub const IFBLK: usize = 0x6000;
    pub const IFREG: usize = 0x8000;
    pub const IFIFO: usize = 0x1000;
    pub const IFLNK: usize = 0xa000;
    pub const IFSOCK: usize = 0xc000;
    pub const ISUID: usize = 0x800;
    pub const ISGID: usize = 0x400;
    pub const ISVTX: usize = 0x200;
    pub const IREAD: usize = 0x100;
    pub const IWRITE: usize = 0x80;
    pub const IEXEC: usize = 0x40;
    pub const IRUSR: usize = 0x100;
    pub const IWUSR: usize = 0x80;
    pub const IXUSR: usize = 0x40;
    pub const IRWXU: usize = 0x1c0;
    pub const IRGRP: usize = 0x20;
    pub const IWGRP: usize = 0x10;
    pub const IXGRP: usize = 0x8;
    pub const IRWXG: usize = 0x38;
    pub const IROTH: usize = 0x4;
    pub const IWOTH: usize = 0x2;
    pub const IXOTH: usize = 0x1;
    pub const IRWXO: usize = 0x7;
    pub const AT_FDCWD: usize = 0xffffffffffffff9c;
};
pub const UTIME = opaque {
    pub const NOW: usize = 0x3fffffff;
    pub const OMIT: usize = 0x3ffffffe;
};
pub const R_OK: usize = 0x4;
pub const W_OK: usize = 0x2;
pub const X_OK: usize = 0x1;
pub const F_OK: usize = 0x0;
pub const SEEK = opaque {
    pub const END: usize = 0x2;
    pub const HOLE: usize = 0x4;
    pub const DATA: usize = 0x3;
    pub const SET: usize = 0x0;
    pub const CUR: usize = 0x1;
};
pub const STATX = opaque {
    pub const TYPE: usize = 0x1;
    pub const MODE: usize = 0x2;
    pub const NLINK: usize = 0x4;
    pub const UID: usize = 0x8;
    pub const GID: usize = 0x10;
    pub const ATIME: usize = 0x20;
    pub const MTIME: usize = 0x40;
    pub const CTIME: usize = 0x80;
    pub const INO: usize = 0x100;
    pub const SIZE: usize = 0x200;
    pub const BLOCKS: usize = 0x400;
    pub const BASIC_STATS: usize = 0x7ff;
    pub const BTIME: usize = 0x800;
    pub const MNT_ID: usize = 0x1000;
    pub const ALL: usize = 0xfff;
    pub const ATTR = opaque {
        pub const COMPRESSED: usize = 0x4;
        pub const IMMUTABLE: usize = 0x10;
        pub const APPEND: usize = 0x20;
        pub const NODUMP: usize = 0x40;
        pub const ENCRYPTED: usize = 0x800;
        pub const AUTOMOUNT: usize = 0x1000;
        pub const MOUNT_ROOT: usize = 0x2000;
        pub const VERITY: usize = 0x100000;
        pub const DAX: usize = 0x200000;
    };
};
pub const GRND = opaque {
    pub const NONBLOCK: usize = 0x1;
    pub const RANDOM: usize = 0x2;
    pub const INSECURE: usize = 0x4;
};
pub const CLOCK = opaque {
    pub const REALTIME: usize = 0x0;
    pub const REALTIME_ALARM: usize = 0x8;
    pub const REALTIME_COARSE: usize = 0x5;
    pub const TAI: usize = 0xb;
    pub const MONOTONIC: usize = 0x1;
    pub const MONOTONIC_COARSE: usize = 0x6;
    pub const MONOTONIC_RAW: usize = 0x4;
    pub const BOOTTIME: usize = 0x7;
    pub const BOOTTIME_ALARM: usize = 0x9;
    pub const PROCESS_CPUTIME_ID: usize = 0x2;
    pub const THREAD_CPUTIME_ID: usize = 0x3;
};
pub const IPC = opaque {
    pub const EXCL: usize = 0x400;
    pub const INFO: usize = 0x3;
    pub const RMID: usize = 0x0;
    pub const SET: usize = 0x1;
    pub const NOWAIT: usize = 0x800;
    pub const CREAT: usize = 0x200;
    pub const STAT: usize = 0x2;
};
pub const SCHED = opaque {
    pub const RR: usize = 0x2;
    pub const BATCH: usize = 0x3;
    pub const IDLE: usize = 0x5;
    pub const FLAG = opaque {
        pub const RECLAIM: usize = 0x2;
        pub const RESET_ON = opaque {
            pub const FORK: usize = 0x1;
        };
        pub const DL_OVERRUN: usize = 0x4;
    };
};
pub const SA = opaque {
    pub const ONSTACK: usize = 0x8000000;
    pub const SIGINFO: usize = 0x4;
    pub const NODEFER: usize = 0x40000000;
    pub const RESETHAND: usize = 0x80000000;
    pub const EXPOSE_TAGBITS: usize = 0x800;
    pub const RESTART: usize = 0x10000000;
    pub const NOCLDWAIT: usize = 0x2;
    pub const RESTORER: usize = 0x4000000;
    pub const NOCLDSTOP: usize = 0x1;
    pub const UNSUPPORTED: usize = 0x400;
};
pub const SIG = opaque {
    pub const DFL: usize = 0x0;
    pub const IGN: usize = 0x1;
    pub const INT: usize = 0x2;
    pub const ILL: usize = 0x4;
    pub const ABRT: usize = 0x6;
    pub const FPE: usize = 0x8;
    pub const SEGV: usize = 0xb;
    pub const TERM: usize = 0xf;
    pub const HUP: usize = 0x1;
    pub const QUIT: usize = 0x3;
    pub const TRAP: usize = 0x5;
    pub const KILL: usize = 0x9;
    pub const PIPE: usize = 0xd;
    pub const ALRM: usize = 0xe;
    pub const IO: usize = 0x1d;
    pub const IOT: usize = 0x6;
    pub const CLD: usize = 0x11;
    pub const STKFLT: usize = 0x10;
    pub const PWR: usize = 0x1e;
    pub const BUS: usize = 0x7;
    pub const SYS: usize = 0x1f;
    pub const URG: usize = 0x17;
    pub const STOP: usize = 0x13;
    pub const TSTP: usize = 0x14;
    pub const CONT: usize = 0x12;
    pub const CHLD: usize = 0x11;
    pub const TTIN: usize = 0x15;
    pub const TTOU: usize = 0x16;
    pub const POLL: usize = 0x1d;
    pub const XFSZ: usize = 0x19;
    pub const XCPU: usize = 0x18;
    pub const VTALRM: usize = 0x1a;
    pub const PROF: usize = 0x1b;
    pub const USR1: usize = 0xa;
    pub const USR2: usize = 0xc;
    pub const WINCH: usize = 0x1c;
    pub const UNBLOCK: usize = 0x1;
    pub const SETMASK: usize = 0x2;
    pub const BLOCK: usize = 0x0;
};
pub const TIOC = opaque {
    pub const EXCL: usize = 0x540C;
    pub const NXCL: usize = 0x540D;
    pub const SCTTY: usize = 0x540E;
    pub const GPGRP: usize = 0x540F;
    pub const SPGRP: usize = 0x5410;
    pub const OUTQ: usize = 0x5411;
    pub const STI: usize = 0x5412;
    pub const GWINSZ: usize = 0x5413;
    pub const SWINSZ: usize = 0x5414;
    pub const MGET: usize = 0x5415;
    pub const MBIS: usize = 0x5416;
    pub const MBIC: usize = 0x5417;
    pub const MSET: usize = 0x5418;
    pub const GSOFTCAR: usize = 0x5419;
    pub const SSOFTCAR: usize = 0x541A;
    pub const INQ: usize = 0x541B;
    pub const LINUX: usize = 0x541C;
    pub const CONS: usize = 0x541D;
    pub const GSERIAL: usize = 0x541E;
    pub const SSERIAL: usize = 0x541F;
    pub const PKT: usize = 0x5420;
    pub const NOTTY: usize = 0x5422;
    pub const SETD: usize = 0x5423;
    pub const GETD: usize = 0x5424;
    pub const SBRK: usize = 0x5427;
    pub const CBRK: usize = 0x5428;
    pub const GSID: usize = 0x5429;
    pub const GRS485: usize = 0x542E;
    pub const SRS485: usize = 0x542F;
    pub const SERCONFIG: usize = 0x5453;
    pub const SERGWILD: usize = 0x5454;
    pub const SERSWILD: usize = 0x5455;
    pub const GLCKTRMIOS: usize = 0x5456;
    pub const SLCKTRMIOS: usize = 0x5457;
    pub const SERGSTRUCT: usize = 0x5458;
    pub const SERGETLSR: usize = 0x5459;
    pub const SERGETMULTI: usize = 0x545A;
    pub const SERSETMULTI: usize = 0x545B;
    pub const MIWAIT: usize = 0x545C;
    pub const GICOUNT: usize = 0x545D;
    pub const PKT_DATA: usize = 0;
    pub const PKT_FLUSHREAD: usize = 1;
    pub const PKT_FLUSHWRITE: usize = 2;
    pub const PKT_STOP: usize = 4;
    pub const PKT_START: usize = 8;
    pub const PKT_NOSTOP: usize = 16;
    pub const PKT_DOSTOP: usize = 32;
    pub const PKT_IOCTL: usize = 64;
    pub const SER_TEMT: usize = 0x01;
};
pub const FIO = opaque {
    pub const NBIO: usize = 0x5421;
    pub const NCLEX: usize = 0x5450;
    pub const CLEX: usize = 0x5451;
    pub const ASYNC: usize = 0x5452;
    pub const QSIZE: usize = 0x5460;
};
pub const TC = opaque {
    pub const GETS: usize = 0x5401;
    pub const SETS: usize = 0x5402;
    pub const SETSW: usize = 0x5403;
    pub const SETSF: usize = 0x5404;
    pub const GETA: usize = 0x5405;
    pub const SETA: usize = 0x5406;
    pub const SETAW: usize = 0x5407;
    pub const SETAF: usize = 0x5408;
    pub const SBRK: usize = 0x5409;
    pub const XONC: usize = 0x540A;
    pub const FLSH: usize = 0x540B;
    pub const SBRKP: usize = 0x5425;
    pub const GETX: usize = 0x5432;
    pub const SETX: usize = 0x5433;
    pub const SETXF: usize = 0x5434;
    pub const SETXW: usize = 0x5435;
    pub const I = opaque {
        pub const IGNBRK: u32 = 0x1;
        pub const BRKINT: u32 = 0x2;
        pub const IGNPAR: u32 = 0x4;
        pub const PARMRK: u32 = 0x8;
        pub const INPCK: u32 = 0x10;
        pub const STRIP: u32 = 0x20;
        pub const NLCR: u32 = 0x40;
        pub const IGNCR: u32 = 0x80;
        pub const CRNL: u32 = 0x100;
        pub const UCLC: u32 = 0x200;
        pub const XON: u32 = 0x400;
        pub const XANY: u32 = 0x800;
        pub const XOFF: u32 = 0x1000;
        pub const MAXBEL: u32 = 0x2000;
        pub const UTF8: u32 = undefined;
    };
    pub const O = opaque {
        pub const POST: u32 = 0x1;
        pub const LCUC: u32 = 0x2;
        pub const NLCR: u32 = 0x4;
        pub const CRNL: u32 = 0x8;
        pub const NOCR: u32 = 0x10;
        pub const NLRET: u32 = 0x20;
        pub const FILL: u32 = 0x40;
        pub const FDEL: u32 = 0x80;
        pub const NLDLY: u32 = 0x100;
        pub const CRDLY: u32 = 0x600;
        pub const TABDLY: u32 = 0x1800;
        pub const BSDLY: u32 = 0x2000;
        pub const VTDLY: u32 = 0x4000;
        pub const FFDLY: u32 = 0x8000;
    };
    pub const C = opaque {
        pub const BAUD: u32 = 0x100f;
        pub const BAUDEX: u32 = 0x1000;
        pub const SIZE: u32 = 0x30;
        pub const STOPB: u32 = 0x40;
        pub const READ: u32 = 0x80;
        pub const PARENB: u32 = 0x100;
        pub const PARODD: u32 = 0x200;
        pub const HUPCL: u32 = 0x400;
        pub const LOCAL: u32 = 0x800;
        pub const IBAUD: u32 = 0x100f0000;
        pub const MSPAR: u32 = 0x40000000;
        pub const RTSCTS: u32 = 0x80000000;
    };
    pub const L = opaque {
        pub const ISIG: u32 = 0x1;
        pub const ICANON: u32 = 0x2;
        pub const XCASE: u32 = 0x4;
        pub const ECHO: u32 = 0x8;
        pub const ECHOE: u32 = 0x10;
        pub const ECHOK: u32 = 0x20;
        pub const ECHONL: u32 = 0x40;
        pub const ECHOCTL: u32 = 0x200;
        pub const ECHOPRT: u32 = 0x400;
        pub const ECHOKE: u32 = 0x800;
        pub const FLUSHO: u32 = 0x1000;
        pub const NOFLSH: u32 = 0x80;
        pub const TOSTOP: u32 = 0x100;
        pub const PENDIN: u32 = 0x4000;
        pub const IEXTEN: u32 = 0x8000;
    };
    pub const V = opaque {
        pub const DISCARD: u8 = 0xd;
        pub const EOF: u8 = 0x4;
        pub const EOL: u8 = 0xb;
        pub const ERASE: u8 = 0x2;
        pub const INTR: u8 = 0x0;
        pub const KILL: u8 = 0x3;
        pub const LNEXT: u8 = 0xf;
        pub const MIN: u8 = 0x6;
        pub const QUIT: u8 = 0x1;
        pub const REPRINT: u8 = 0xc;
        pub const START: u8 = 0x8;
        pub const STOP: u8 = 0x9;
        pub const SUSP: u8 = 0xa;
        pub const TIME: u8 = 0x5;
        pub const WERASE: u8 = 0xe;
    };
    pub const SANOW: usize = 0x0;
    pub const SADRAIN: usize = 0x1;
    pub const SAFLUSH: usize = 0x2;
    pub const IFLUSH: usize = 0x0;
    pub const IOFLUSH: usize = 0x2;
    pub const OFLUSH: usize = 0x1;
    pub const OOFF: usize = 0x0;
    pub const OON: usize = 0x1;
    pub const IOFF: usize = 0x2;
    pub const ION: usize = 0x3;
};
pub const ARCH = opaque {
    pub const SET = opaque {
        pub const CPUID: usize = 0x1012;
        pub const GS: usize = 0x1001;
        pub const FS: usize = 0x1002;
    };
    pub const GET = opaque {
        pub const CPUID: usize = 0x1011;
        pub const GS: usize = 0x1004;
        pub const FS: usize = 0x1003;
    };
};
pub const UFFD = opaque {
    pub const EVENT = opaque {
        pub const UNMAP: usize = 0x16;
        pub const FORK: usize = 0x13;
        pub const REMOVE: usize = 0x15;
        pub const REMAP: usize = 0x14;
        pub const PAGEFAULT: usize = 0x12;
    };
    pub const FEATURE = opaque {
        pub const EVENT = opaque {
            pub const UNMAP: usize = 0x40;
            pub const FORK: usize = 0x2;
            pub const REMOVE: usize = 0x8;
            pub const REMAP: usize = 0x4;
        };
        pub const THREAD_ID: usize = 0x100;
        pub const SIGBUS: usize = 0x80;
        pub const MISSING = opaque {
            pub const SHMEM: usize = 0x20;
            pub const HUGETLBFS: usize = 0x10;
        };
    };
    pub const PAGEFAULT_FLAG = opaque {
        pub const WP: usize = 0x2;
        pub const WRITE: usize = 0x1;
    };
};
pub const POLL = opaque {
    pub const HUP: usize = 0x6;
    pub const ERR: usize = 0x4;
    pub const IN: usize = 0x1;
    pub const OUT: usize = 0x2;
    pub const MSG: usize = 0x3;
    pub const PRI: usize = 0x5;
};
pub const PERF = opaque {
    pub const SAMPLE_BRANCH = opaque {
        pub const PLM_ALL: usize = 0x7;
    };
    pub const EVENT_IOC = opaque {
        pub const QUERY_BPF: usize = 0xc008240a;
        pub const REFRESH: usize = 0x2402;
        pub const PERIOD: usize = 0x40082404;
        pub const DISABLE: usize = 0x2401;
        pub const ENABLE: usize = 0x2400;
        pub const SET = opaque {
            pub const FILTER: usize = 0x40082406;
            pub const BPF: usize = 0x40042408;
            pub const OUTPUT: usize = 0x2405;
        };
        pub const RESET: usize = 0x2403;
        pub const PAUSE_OUTPUT: usize = 0x40042409;
        pub const ID: usize = 0x80082407;
    };
    pub const AUX_FLAG = opaque {
        pub const TRUNCATED: usize = 0x1;
        pub const OVERWRITE: usize = 0x2;
    };
    pub const MEM = opaque {
        pub const LVL = opaque {
            pub const L1: usize = 0x8;
            pub const IO: usize = 0x1000;
            pub const MISS: usize = 0x4;
            pub const L2: usize = 0x20;
            pub const HIT: usize = 0x2;
            pub const L3: usize = 0x40;
            pub const UNC: usize = 0x2000;
            pub const REM = opaque {
                pub const CCE2: usize = 0x800;
                pub const RAM1: usize = 0x100;
                pub const RAM2: usize = 0x200;
                pub const CCE1: usize = 0x400;
            };
            pub const LOC_RAM: usize = 0x80;
            pub const LFB: usize = 0x10;
        };
        pub const TLB = opaque {
            pub const L1: usize = 0x8;
            pub const L2: usize = 0x10;
            pub const MISS: usize = 0x4;
            pub const OS: usize = 0x40;
            pub const WK: usize = 0x20;
            pub const HIT: usize = 0x2;
        };
        pub const SNOOP = opaque {
            pub const HITM: usize = 0x10;
            pub const MISS: usize = 0x8;
            pub const NONE: usize = 0x2;
            pub const HIT: usize = 0x4;
        };
        pub const OP = opaque {
            pub const LOAD: usize = 0x2;
            pub const PFETCH: usize = 0x8;
            pub const EXEC: usize = 0x10;
            pub const STORE: usize = 0x4;
        };
        pub const LOCK_LOCKED: usize = 0x2;
    };
    pub const FLAG = opaque {
        pub const FD = opaque {
            pub const NO_GROUP: usize = 0x1;
            pub const OUTPUT: usize = 0x2;
            pub const CLOEXEC: usize = 0x8;
        };
        pub const PID_CGROUP: usize = 0x4;
    };
    pub const RECORD_MISC = opaque {
        pub const KERNEL: usize = 0x1;
        pub const MMAP_DATA: usize = 0x2000;
        pub const HYPERVISOR: usize = 0x3;
        pub const PROC_MAP_PARSE_TIMEOUT: usize = 0x1000;
        pub const GUEST = opaque {
            pub const KERNEL: usize = 0x4;
            pub const USER: usize = 0x5;
        };
        pub const EXACT_IP: usize = 0x4000;
        pub const SWITCH_OUT: usize = 0x2000;
        pub const EXT_RESERVED: usize = 0x8000;
        pub const USER: usize = 0x2;
        pub const COMM_EXEC: usize = 0x2000;
        pub const CPUMODE_UNKNOWN: usize = 0x0;
    };
};
pub const RESOLVE = opaque {
    pub const BENEATH: usize = 0x8;
    pub const NO = opaque {
        pub const SYMLINKS: usize = 0x4;
        pub const XDEV: usize = 0x1;
        pub const MAGICLINKS: usize = 0x2;
    };
    pub const CACHED: usize = 0x20;
    pub const IN_ROOT: usize = 0x10;
};
pub const SYS_SECCOMP: usize = 0x1;
pub const KEYCTL = opaque {
    pub const UPDATE: usize = 0x2;
    pub const GET = opaque {
        pub const SECURITY: usize = 0x11;
        pub const KEYRING_ID: usize = 0x0;
        pub const PERSISTENT: usize = 0x16;
    };
    pub const NEGATE: usize = 0xd;
    pub const INVALIDATE: usize = 0x15;
    pub const SEARCH: usize = 0xa;
    pub const CLEAR: usize = 0x7;
    pub const REJECT: usize = 0x13;
    pub const REVOKE: usize = 0x3;
    pub const RESTRICT_KEYRING: usize = 0x1d;
    pub const ASSUME_AUTHORITY: usize = 0x10;
    pub const JOIN_SESSION_KEYRING: usize = 0x1;
    pub const SET = opaque {
        pub const REQKEY_KEYRING: usize = 0xe;
        pub const TIMEOUT: usize = 0xf;
    };
    pub const LINK: usize = 0x8;
    pub const DH_COMPUTE: usize = 0x17;
    pub const CHOWN: usize = 0x4;
    pub const UNLINK: usize = 0x9;
    pub const SESSION_TO_PARENT: usize = 0x12;
    pub const SETPERM: usize = 0x5;
    pub const INSTANTIATE_IOV: usize = 0x14;
    pub const DESCRIBE: usize = 0x6;
    pub const READ: usize = 0xb;
};
pub const KEY = opaque {
    pub const SPEC = opaque {
        pub const THREAD_KEYRING: usize = 0xffffffff;
        pub const REQUESTOR_KEYRING: usize = 0xfffffff8;
        pub const USER = opaque {
            pub const KEYRING: usize = 0xfffffffc;
            pub const SESSION_KEYRING: usize = 0xfffffffb;
        };
        pub const REQKEY_AUTH = opaque {
            pub const KEY: usize = 0xfffffff9;
        };
        pub const PROCESS_KEYRING: usize = 0xfffffffe;
        pub const SESSION_KEYRING: usize = 0xfffffffd;
    };
    pub const REQKEY_DEFL = opaque {
        pub const THREAD_KEYRING: usize = 0x1;
        pub const REQUESTOR_KEYRING: usize = 0x7;
        pub const USER = opaque {
            pub const KEYRING: usize = 0x4;
            pub const SESSION_KEYRING: usize = 0x5;
        };
        pub const DEFAULT: usize = 0x0;
        pub const NO_CHANGE: usize = 0xffffffff;
        pub const PROCESS_KEYRING: usize = 0x2;
        pub const SESSION_KEYRING: usize = 0x3;
    };
};
pub const SYNC_FILE = opaque {
    pub const RANGE = opaque {
        pub const WAIT = opaque {
            pub const AFTER: usize = 0x4;
            pub const BEFORE: usize = 0x1;
        };
        pub const WRITE: usize = 0x2;
    };
};
pub const SIGEV = opaque {
    pub const NONE: usize = 0x1;
    pub const SIGNAL: usize = 0x0;
    pub const THREAD_ID: usize = 0x4;
};
pub const MS = opaque {
    pub const MANDLOCK: usize = 0x40;
    pub const LAZYTIME: usize = 0x2000000;
    pub const REC: usize = 0x4000;
    pub const RELATIME: usize = 0x200000;
    pub const RDONLY: usize = 0x1;
    pub const SILENT: usize = 0x8000;
    pub const INVALIDATE: usize = 0x2;
    pub const DIRSYNC: usize = 0x80;
    pub const SLAVE: usize = 0x80000;
    pub const NOATIME: usize = 0x400;
    pub const PRIVATE: usize = 0x40000;
    pub const NODIRATIME: usize = 0x800;
    pub const NOSYMFOLLOW: usize = 0x100;
    pub const UNBINDABLE: usize = 0x20000;
    pub const NODEV: usize = 0x4;
    pub const SHARED: usize = 0x100000;
    pub const SYNC: usize = 0x4;
    pub const STRICTATIME: usize = 0x1000000;
    pub const SYNCHRONOUS: usize = 0x10;
    pub const ASYNC: usize = 0x1;
    pub const NOSUID: usize = 0x2;
    pub const NOEXEC: usize = 0x8;
};
pub const ATTR = opaque {
    pub const HIDDEN: usize = 0x2;
    pub const RO: usize = 0x1;
    pub const VOLUME: usize = 0x8;
    pub const DIR: usize = 0x10;
    pub const ARCH: usize = 0x20;
    pub const SYS: usize = 0x4;
};
pub const ILL = opaque {
    pub const COPROC: usize = 0x7;
    pub const ILLOPN: usize = 0x2;
    pub const PRVREG: usize = 0x6;
    pub const ILLOPC: usize = 0x1;
    pub const ILLTRP: usize = 0x4;
    pub const ILLADR: usize = 0x3;
    pub const PRVOPC: usize = 0x5;
    pub const BADSTK: usize = 0x8;
};
pub const RENAME = opaque {
    pub const NOREPLACE: usize = 0x1;
    pub const WHITEOUT: usize = 0x4;
    pub const EXCHANGE: usize = 0x2;
};
pub const SS = opaque {
    pub const ONSTACK: usize = 0x1;
    pub const DISABLE: usize = 0x2;
    pub const AUTODISARM: usize = 0x80000000;
};
pub const FPE = opaque {
    pub const FLTINV: usize = 0x7;
    pub const FLTDIV: usize = 0x3;
    pub const FLTSUB: usize = 0x8;
    pub const FLTUND: usize = 0x5;
    pub const INTOVF: usize = 0x2;
    pub const FLTRES: usize = 0x6;
    pub const INTDIV: usize = 0x1;
    pub const FLTOVF: usize = 0x4;
};
pub const CLD = opaque {
    pub const TRAPPED: usize = 0x4;
    pub const STOPPED: usize = 0x5;
    pub const KILLED: usize = 0x2;
    pub const CONTINUED: usize = 0x6;
    pub const DUMPED: usize = 0x3;
    pub const EXITED: usize = 0x1;
};
pub const AT = opaque {
    pub const EACCESS: usize = 0x200;
    pub const SYMLINK = opaque {
        pub const FOLLOW: usize = 0x400;
        pub const NOFOLLOW: usize = 0x100;
    };
    pub const REMOVEDIR: usize = 0x200;
    pub const EMPTY_PATH: usize = 0x1000;
    pub const EXECFD: usize = 0x2;
    pub const PHDR: usize = 0x3;
    pub const PHENT: usize = 0x4;
    pub const PHNUM: usize = 0x5;
    pub const PAGESZ: usize = 0x6;
    pub const BASE: usize = 0x7;
    pub const FLAGS: usize = 0x8;
    pub const ENTRY: usize = 0x9;
    pub const EUID: usize = 0xc;
    pub const GID: usize = 0xd;
    pub const EGID: usize = 0xe;
    pub const PLATFORM: usize = 0xf;
    pub const HWCAP: usize = 0x10;
    pub const CLKTCK: usize = 0x11;
    pub const FPUCW: usize = 0x12;
    pub const DCACHEBSIZE: usize = 0x13;
    pub const ICACHEBSIZE: usize = 0x14;
    pub const UCACHEBSIZE: usize = 0x15;
    pub const SECURE: usize = 0x17;
    pub const BASE_PLATFORM: usize = 0x18;
    pub const RANDOM: usize = 0x19;
    pub const EXECFN: usize = 0x1f;
    pub const SYSINFO: usize = 0x20;
    pub const SYSINFO_EHDR: usize = 0x21;
    pub const L1I_CACHESIZE: usize = 0x28;
    pub const L1I_CACHEGEOMETRY: usize = 0x29;
    pub const L1D_CACHESIZE: usize = 0x2a;
    pub const L1D_CACHEGEOMETRY: usize = 0x2b;
    pub const L2_CACHESIZE: usize = 0x2c;
    pub const L2_CACHEGEOMETRY: usize = 0x2d;
    pub const L3_CACHESIZE: usize = 0x2e;
    pub const L3_CACHEGEOMETRY: usize = 0x2f;
};
pub const FMR = opaque {
    pub const OF = opaque {
        pub const EXTENT_MAP: usize = 0x4;
        pub const SHARED: usize = 0x8;
        pub const SPECIAL_OWNER: usize = 0x10;
        pub const ATTR_FORK: usize = 0x2;
        pub const LAST: usize = 0x20;
        pub const PREALLOC: usize = 0x1;
    };
    pub const OWN = opaque {
        pub const UNKNOWN: usize = 0x2;
        pub const FREE: usize = 0x1;
        pub const METADATA: usize = 0x3;
    };
};
pub const F = opaque {
    pub const SETOWN: usize = 0x8;
    pub const SETLK: usize = 0x6;
    pub const SETFD: usize = 0x2;
    pub const SETLKW: usize = 0x7;
    pub const GETLK: usize = 0x5;
    pub const WRLCK: usize = 0x1;
    pub const RDLCK: usize = 0x0;
    pub const DUPFD_CLOEXEC: usize = 0x406;
    pub const GETFD: usize = 0x1;
    pub const GETFL: usize = 0x3;
    pub const UNLCK: usize = 0x2;
    pub const GETOWN: usize = 0x9;
    pub const SETFL: usize = 0x4;
};
pub const SI = opaque {
    pub const TKILL: usize = 0xfffffffa;
    pub const ASYNCIO: usize = 0xfffffffc;
    pub const KERNEL: usize = 0x80;
    pub const QUEUE: usize = 0xffffffff;
    pub const TIMER: usize = 0xfffffffe;
    pub const USER: usize = 0x0;
    pub const SIGIO: usize = 0xfffffffb;
    pub const MESGQ: usize = 0xfffffffd;
};
pub const RWF = opaque {
    pub const DSYNC: usize = 0x2;
    pub const HIPRI: usize = 0x1;
    pub const SYNC: usize = 0x4;
    pub const NOWAIT: usize = 0x8;
    pub const APPEND: usize = 0x10;
};
pub const DT = opaque {
    pub const SOCK: usize = 0xc;
    pub const UNKNOWN: usize = 0x0;
    pub const LNK: usize = 0xa;
    pub const DIR: usize = 0x4;
    pub const CHR: usize = 0x2;
    pub const FIFO: usize = 0x1;
    pub const REG: usize = 0x8;
};
pub const LINUX_REBOOT_CMD = opaque {
    pub const RESTART: usize = 0x1234567;
    pub const HALT: usize = 0xcdef0123;
    pub const SW_SUSPEND: usize = 0xd000fce2;
    pub const RESTART2: usize = 0xa1b2c3d4;
    pub const POWER_OFF: usize = 0x4321fedc;
    pub const KEXEC: usize = 0x45584543;
    pub const CAD = opaque {
        pub const ON: usize = 0x89abcdef;
        pub const OFF: usize = 0x0;
    };
};
pub const BUS = opaque {
    pub const ADRALN: usize = 0x1;
    pub const ADRERR: usize = 0x2;
    pub const OBJERR: usize = 0x3;
    pub const MCEERR = opaque {
        pub const AO: usize = 0x5;
        pub const AR: usize = 0x4;
    };
};
pub const POSIX_FADV = opaque {
    pub const NOREUSE: usize = 0x5;
    pub const NORMAL: usize = 0x0;
    pub const RANDOM: usize = 0x1;
    pub const DONTNEED: usize = 0x4;
    pub const SEQUENTIAL: usize = 0x2;
    pub const WILLNEED: usize = 0x3;
};
pub const ITIMER = opaque {
    pub const VIRTUAL: usize = 0x1;
    pub const REAL: usize = 0x0;
    pub const PROF: usize = 0x2;
};
pub const SEGV = opaque {
    pub const ACCERR: usize = 0x2;
    pub const PKUERR: usize = 0x4;
    pub const BNDERR: usize = 0x3;
    pub const MAPERR: usize = 0x1;
};
pub const SECCOMP = opaque {
    pub const RET = opaque {
        pub const KILL = opaque {
            pub const PROCESS: usize = 0x80000000;
            pub const THREAD: usize = 0x0;
        };
        pub const ALLOW: usize = 0x7fff0000;
        pub const ERRNO: usize = 0x50000;
        pub const LOG: usize = 0x7ffc0000;
        pub const TRACE: usize = 0x7ff00000;
        pub const TRAP: usize = 0x30000;
        pub const USER_NOTIF: usize = 0x7fc00000;
    };
    pub const GET = opaque {
        pub const NOTIF_SIZES: usize = 0x3;
        pub const ACTION_AVAIL: usize = 0x2;
    };
    pub const FILTER_FLAG = opaque {
        pub const NEW_LISTENER: usize = 0x8;
        pub const SPEC_ALLOW: usize = 0x4;
        pub const TSYNC: usize = 0x1;
        pub const LOG: usize = 0x2;
    };
    pub const SET_MODE = opaque {
        pub const STRICT: usize = 0x0;
        pub const FILTER: usize = 0x1;
    };
};
pub const UFFDIO = opaque {
    pub const ZEROPAGE_MODE = opaque {
        pub const DONTWAKE: usize = 0x1;
    };
    pub const WRITEPROTECT_MODE = opaque {
        pub const DONTWAKE: usize = 0x2;
        pub const WP: usize = 0x1;
    };
    pub const REGISTER_MODE = opaque {
        pub const WP: usize = 0x2;
        pub const MISSING: usize = 0x1;
    };
    pub const COPY_MODE = opaque {
        pub const DONTWAKE: usize = 0x1;
        pub const WP: usize = 0x2;
    };
};
pub const MODULE_INIT = opaque {
    pub const IGNORE = opaque {
        pub const MODVERSIONS: usize = 0x1;
        pub const VERMAGIC: usize = 0x2;
    };
};
pub const KEXEC = opaque {
    pub const FILE = opaque {
        pub const UNLOAD: usize = 0x1;
        pub const NO_INITRAMFS: usize = 0x4;
        pub const ON_CRASH: usize = 0x2;
    };
    pub const PRESERVE_CONTEXT: usize = 0x2;
    pub const ON_CRASH: usize = 0x1;
};
pub const FS = opaque {
    pub const APPEND_FL: usize = 0x20;
    pub const NODUMP_FL: usize = 0x40;
    pub const SECRM_FL: usize = 0x1;
    pub const PROJINHERIT_FL: usize = 0x20000000;
    pub const SYNC_FL: usize = 0x8;
    pub const JOURNAL_DATA_FL: usize = 0x4000;
    pub const NOATIME_FL: usize = 0x80;
    pub const UNRM_FL: usize = 0x2;
    pub const DIRSYNC_FL: usize = 0x10000;
    pub const NOTAIL_FL: usize = 0x8000;
    pub const TOPDIR_FL: usize = 0x20000;
    pub const IMMUTABLE_FL: usize = 0x10;
    pub const COMPR_FL: usize = 0x4;
    pub const NOCOW_FL: usize = 0x800000;
};
pub const CLONE = opaque {
    pub const IO: usize = 0x80000000;
    pub const NEWTIME: usize = 0x80;
    pub const PIDFD: usize = 0x1000;
    pub const NEWUTS: usize = 0x4000000;
    pub const CHILD_SETTID: usize = 0x1000000;
    pub const CHILD_CLEARTID: usize = 0x200000;
    pub const NEWNS: usize = 0x20000;
    pub const UNTRACED: usize = 0x800000;
    pub const PARENT_SETTID: usize = 0x100000;
    pub const CLEAR_SIGHAND: usize = 0x0;
    pub const NEWPID: usize = 0x20000000;
    pub const SIGHAND: usize = 0x800;
    pub const SETTLS: usize = 0x80000;
    pub const THREAD: usize = 0x10000;
    pub const NEWIPC: usize = 0x8000000;
    pub const NEWCGROUP: usize = 0x2000000;
    pub const SYSVSEM: usize = 0x40000;
    pub const DETACHED: usize = 0x400000;
    pub const NEWUSER: usize = 0x10000000;
    pub const VFORK: usize = 0x4000;
    pub const VM: usize = 0x100;
    pub const FS: usize = 0x200;
    pub const FILES: usize = 0x400;
    pub const NEWNET: usize = 0x40000000;
    pub const PTRACE: usize = 0x2000;
    pub const INTO_CGROUP: usize = 0x0;
};
pub const ID = opaque {
    pub const PID: usize = 0x1;
    pub const ALL: usize = 0x0;
    pub const PGID: usize = 0x2;
    pub const PIDFD: usize = 0x3;
};
pub const WAIT = opaque {
    pub const NOHANG: usize = 0x1;
    pub const UNTRACED: usize = 0x2;
    pub const CONTINUED: usize = 0x8;
    pub const EXITED: usize = 0x4;
    pub const STOPPED: usize = 0x2;
    pub const NOWAIT: usize = 0x1000000;
    pub const CLONE: usize = 0x80000000;
    pub const NOTHREAD: usize = 0x20000000;
    pub const ALL: usize = 0x40000000;
};
pub const MOUNT_ATTR = opaque {
    pub const RELATIME: usize = 0x0;
    pub const RDONLY: usize = 0x1;
    pub const _ATIME: usize = 0x70;
    pub const NOATIME: usize = 0x10;
    pub const NODIRATIME: usize = 0x80;
    pub const IDMAP: usize = 0x100000;
    pub const NODEV: usize = 0x4;
    pub const STRICTATIME: usize = 0x20;
    pub const NOSUID: usize = 0x2;
    pub const NOEXEC: usize = 0x8;
};
pub const PTRACE = opaque {
    pub const GETSIGMASK: usize = 0x420a;
    pub const GETREGSET: usize = 0x4204;
    pub const LISTEN: usize = 0x4208;
    pub const GET_SYSCALL_INFO: usize = 0x420e;
    pub const SECCOMP_GET_FILTER: usize = 0x420c;
    pub const SETREGSET: usize = 0x4205;
    pub const INTERRUPT: usize = 0x4207;
    pub const PEEKSIGINFO: usize = 0x4209;
    pub const SEIZE: usize = 0x4206;
    pub const SETSIGMASK: usize = 0x420b;
};
pub const IOCB_FLAG = opaque {
    pub const RESFD: usize = 0x1;
    pub const IOPRIO: usize = 0x2;
};
pub const TRAP = opaque {
    pub const BRKPT: usize = 0x1;
    pub const TRACE: usize = 0x2;
    pub const BRANCH: usize = 0x3;
    pub const HWBKPT: usize = 0x4;
};
pub const FUTEX = opaque {
    pub const FD: usize = 0x2;
    pub const UNLOCK_PI: usize = 0x7;
    pub const TRYLOCK_PI: usize = 0x8;
    pub const WAIT = opaque {
        pub const REQUEUE_PI: usize = 0xb;
        pub const BITSET: usize = 0x9;
    };
    pub const CMP_REQUEUE_PI: usize = 0xc;
    pub const REQUEUE: usize = 0x3;
    pub const CLOCK_REALTIME: usize = 0x100;
    pub const WAKE = opaque {
        pub const BITSET: usize = 0xa;
        pub const OP: usize = 0x5;
    };
    pub const PRIVATE_FLAG: usize = 0x80;
    pub const LOCK_PI: usize = 0x6;
};
pub const ErrorCode = enum(i9) {
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

    fn errorName(error_code: ErrorCode) []const u8 {
        return switch (error_code) {
            .PERM => "OperationNotPermitted",
            .NOENT => "NoSuchFileOrDirectory",
            .SRCH => "NoSuchProcess",
            .INTR => "InterruptedSystemCall",
            .IO => "InputOutputError",
            .NXIO => "NoSuchDeviceOrAddress",
            .@"2BIG" => "ArgumentListTooLong",
            .NOEXEC => "ExecFormatError",
            .BADF => "BadFileDescriptor",
            .CHILD => "NoChildProcesses",
            .AGAIN => "ResourceTemporarilyUnavailable",
            .NOMEM => "CannotAllocateMemory",
            .ACCES => "PermissionDenied",
            .FAULT => "BadAddress",
            .NOTBLK => "BlockDeviceRequired",
            .BUSY => "DeviceOrResourceBusy",
            .EXIST => "FileExists",
            .XDEV => "InvalidCrossDeviceLink",
            .NODEV => "NoSuchDevice",
            .NOTDIR => "NotADirectory",
            .ISDIR => "IsADirectory",
            .INVAL => "InvalidArgument",
            .NFILE => "TooManyOpenFilesInSystem",
            .MFILE => "TooManyOpenFiles",
            .NOTTY => "InappropriateIoctlForDevice",
            .TXTBSY => "TextFileBusy",
            .FBIG => "FileTooLarge",
            .NOSPC => "NoSpaceLeftOnDevice",
            .SPIPE => "IllegalSeek",
            .ROFS => "ReadOnlyFileSystem",
            .MLINK => "TooManyLinks",
            .PIPE => "BrokenPipe",
            .DOM => "NumericalArgumentOutOfDomain",
            .RANGE => "NumericalResultOutOfRange",
            .DEADLK => "ResourceDeadlockAvoided",
            .NAMETOOLONG => "FileNameTooLong",
            .NOLCK => "NoLocksAvailable",
            .NOSYS => "FunctionNotImplemented",
            .NOTEMPTY => "DirectoryNotEmpty",
            .LOOP => "TooManyLevelsOfSymbolicLinks",
            .NOMSG => "NoMessageOfDesiredType",
            .IDRM => "IdentifierRemoved",
            .CHRNG => "ChannelNumberOutOfRange",
            .L2NSYNC => "Level2NotSynchronized",
            .L3HLT => "Level3Halted",
            .L3RST => "Level3Reset",
            .LNRNG => "LinkNumberOutOfRange",
            .UNATCH => "ProtocolDriverNotAttached",
            .NOCSI => "NoCSIStructureAvailable",
            .L2HLT => "Level2Halted",
            .BADE => "InvalidExchange",
            .BADR => "InvalidRequestDescriptor",
            .XFULL => "ExchangeFull",
            .NOANO => "NoAnode",
            .BADRQC => "InvalidRequestCode",
            .BADSLT => "InvalidSlot",
            .BFONT => "BadFontFileFormat",
            .NOSTR => "DeviceNotAStream",
            .NODATA => "NoDataAvailable",
            .TIME => "TimerExpired",
            .NOSR => "OutOfStreamsResources",
            .NONET => "MachineNotOnTheNetwork",
            .NOPKG => "PackageNotInstalled",
            .REMOTE => "ObjectIsRemote",
            .NOLINK => "LinkHasBeenSevered",
            .ADV => "AdvertiseError",
            .SRMNT => "SrmountError",
            .COMM => "CommunicationErrorOnSend",
            .PROTO => "ProtocolError",
            .MULTIHOP => "MultihopAttempted",
            .DOTDOT => "RFSSpecificError",
            .BADMSG => "BadMessage",
            .OVERFLOW => "ValueTooLargeForDefinedDataType",
            .NOTUNIQ => "NameNotUniqueOnNetwork",
            .BADFD => "FileDescriptorInBadState",
            .REMCHG => "RemoteAddressChanged",
            .LIBACC => "CanNotAccessANeededSharedLibrary",
            .LIBBAD => "AccessingACorruptedSharedLibrary",
            .LIBSCN => "LibSectionInAOutCorrupted",
            .LIBMAX => "AttemptingToLinkInTooManySharedLibraries",
            .LIBEXEC => "CannotExecASharedLibraryDirectly",
            .ILSEQ => "InvalidOrIncompleteMultibyteOrWideCharacter",
            .RESTART => "InterruptedSystemCallShouldBeRestarted",
            .STRPIPE => "StreamsPipeError",
            .USERS => "TooManyUsers",
            .NOTSOCK => "SocketOperationOnNonSocket",
            .DESTADDRREQ => "DestinationAddressRequired",
            .MSGSIZE => "MessageTooLong",
            .PROTOTYPE => "ProtocolWrongTypeForSocket",
            .NOPROTOOPT => "ProtocolNotAvailable",
            .PROTONOSUPPORT => "ProtocolNotSupported",
            .SOCKTNOSUPPORT => "SocketTypeNotSupported",
            .OPNOTSUPP => "OperationNotSupported",
            .PFNOSUPPORT => "ProtocolFamilyNotSupported",
            .AFNOSUPPORT => "AddressFamilyNotSupportedByProtocol",
            .ADDRINUSE => "AddressAlreadyInUse",
            .ADDRNOTAVAIL => "CannotAssignRequestedAddress",
            .NETDOWN => "NetworkDown",
            .NETUNREACH => "NetworkUnreachable",
            .NETRESET => "NetworkDroppedConnectionOnReset",
            .CONNABORTED => "SoftwareCausedConnectionAbort",
            .CONNRESET => "ConnectionResetByPeer",
            .NOBUFS => "NoBufferSpaceAvailable",
            .ISCONN => "TransportEndpointAlreadyConnected",
            .NOTCONN => "TransportEndpointNotConnected",
            .SHUTDOWN => "CannotSendAfterTransportEndpointShutdown",
            .TOOMANYREFS => "TooManyReferencesCannotSplice",
            .TIMEDOUT => "ConnectionTimedOut",
            .CONNREFUSED => "ConnectionRefused",
            .HOSTDOWN => "HostDown",
            .HOSTUNREACH => "NoRouteToHost",
            .ALREADY => "OperationAlreadyInProgress",
            .INPROGRESS => "OperationNowInProgress",
            .STALE => "StaleFileHandle",
            .UCLEAN => "StructureNeedsCleaning",
            .NOTNAM => "NotAXENIXNamedTypeFile",
            .NAVAIL => "NoXENIXSemaphoresAvailable",
            .ISNAM => "IsNamedTypeFile",
            .REMOTEIO => "RemoteIOError",
            .DQUOT => "DiskQuotaExceeded",
            .NOMEDIUM => "NoMediumFound",
            .MEDIUMTYPE => "WrongMediumType",
            .CANCELED => "OperationCanceled",
            .NOKEY => "RequiredKeyNotAvailable",
            .KEYEXPIRED => "KeyHasExpired",
            .KEYREVOKED => "KeyHasBeenRevoked",
            .KEYREJECTED => "KeyWasRejectedByService",
            .OWNERDEAD => "OwnerDied",
            .NOTRECOVERABLE => "StateNotRecoverable",
            .RFKILL => "OperationNotPossibleDueToRFKill",
            .HWPOISON => "MemoryPageHasHardwareError",
            .OPAQUE => "OpaqueSystemError",
        };
    }
};
pub const Function = enum(u9) {
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

    fn args(comptime function: Function) comptime_int {
        return switch (function) {
            .read => 3,
            .write => 3,
            .open => 3,
            .openat => 3,
            .close => 1,
            .ioctl => 3,
            .brk => 1,
            .mmap => 6,
            .munmap => 2,
            .mremap => 5,
            .madvise => 3,
            .memfd_create => 2,
            .stat => 2,
            .fstat => 2,
            .lstat => 2,
            .statx => 5,
            .newfstatat => 4,
            .mknod => 3,
            .mknodat => 4,
            .getcwd => 1,
            .getdents64 => 3,
            .readlink => 3,
            .readlinkat => 4,
            .getuid => 0,
            .getgid => 0,
            .geteuid => 0,
            .getegid => 0,
            .getrandom => 3,
            .unlink => 1,
            .unlinkat => 3,
            .truncate => 2,
            .ftruncate => 2,
            .mkdir => 2,
            .mkdirat => 3,
            .rmdir => 1,
            .clock_gettime => 2,
            .nanosleep => 2,
            .dup => 1,
            .dup2 => 2,
            .dup3 => 3,
            .fork => 0,
            .wait4 => 5,
            .waitid => 5,
            .clone => 5,
            .clone3 => 2,
            .execve => 3,
            .execveat => 5,
            .rt_sigaction => 4,
            .name_to_handle_at => 5,
            .open_by_handle_at => 3,
            .exit => 1,
            .chdir => 1,
            else => @compileError(@tagName(function)),
        };
    }
};

pub const brk_errors: []const ErrorCode = &[_]ErrorCode{.NOMEM};
pub const chdir_errors: []const ErrorCode = &[_]ErrorCode{
    .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
};
pub const close_errors: []const ErrorCode = &[_]ErrorCode{
    .INTR, .IO, .BADF, .NOSPC,
};
pub const clone_errors: []const ErrorCode = &[_]ErrorCode{
    .PERM, .AGAIN, .INVAL, .EXIST, .USERS, .OPNOTSUPP, .NOMEM, .RESTART,
    .BUSY, .NOSPC,
};
pub const clock_get_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
};
pub const execve_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
    .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
    .INVAL, .NOEXEC,
};
pub const execveat_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
    .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
    .INVAL, .NOEXEC,
};
pub const fork_errors: []const ErrorCode = &[_]ErrorCode{
    .NOSYS, .AGAIN, .NOMEM, .RESTART,
};
pub const getcwd_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
};
pub const getdents_errors: []const ErrorCode = &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
};
pub const getrandom_errors: []const ErrorCode = &[_]ErrorCode{
    .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
};
pub const dup_errors: []const ErrorCode = &[_]ErrorCode{
    .BADF, .BUSY, .INTR, .INVAL, .MFILE,
};
pub const ioctl_errors: []const ErrorCode = &[_]ErrorCode{
    .NOTTY, .BADF, .FAULT, .INVAL,
};
pub const madvise_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
};
pub const mkdir_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
    .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
};
pub const mmap_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .AGAIN,  .BADF, .EXIST, .INVAL, .NFILE, .NODEV, .NOMEM, .OVERFLOW,
    .PERM,  .TXTBSY,
};
pub const memfd_create_errors: []const ErrorCode = &[_]ErrorCode{ .FAULT, .INVAL, .MFILE, .NOMEM };
pub const truncate_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,  .FAULT, .FBIG, .INTR,   .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
    .NOTDIR, .PERM,  .ROFS, .TXTBSY, .BADF, .INVAL,
};
pub const munmap_errors: []const ErrorCode = &[_]ErrorCode{.INVAL};
pub const mknod_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .INVAL, .LOOP, .NAMETOOLONG,
    .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
};
pub const mremap_errors: []const ErrorCode = &[_]ErrorCode{
    .AGAIN, .FAULT, .INVAL, .NOMEM,
};
pub const open_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES, .FBIG,        .NOTDIR,   .EXIST,  .OPNOTSUPP, .MFILE, .NOSPC,
    .NOENT, .NAMETOOLONG, .OVERFLOW, .TXTBSY, .AGAIN,     .BADF,  .ISDIR,
    .LOOP,  .NODEV,       .DQUOT,    .NOMEM,  .ROFS,      .NFILE, .INTR,
    .PERM,  .FAULT,       .INVAL,    .NXIO,   .BUSY,
};
pub const open_by_handle_at_errors: []const ErrorCode = open_errors ++ &[_]ErrorCode{
    .BADF, .FAULT, .INVAL, .LOOP, .PERM, .STALE,
};
pub const name_to_handle_at_errors: []const ErrorCode = open_errors ++ &[_]ErrorCode{
    .OVERFLOW, .LOOP, .PERM, .BADF, .FAULT, .INVAL, .NOTDIR, .STALE,
};
pub const nanosleep_errors: []const ErrorCode = &[_]ErrorCode{
    .INTR, .FAULT, .INVAL, .OPNOTSUPP,
};
pub const readlink_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,  .BADF, .FAULT, .INVAL, .IO, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR,
};
pub const read_errors: []const ErrorCode = &[_]ErrorCode{
    .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
};
pub const rmdir_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,  .BUSY,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .NOTEMPTY, .PERM,  .ROFS,
};
pub const sigaction_errors: []const ErrorCode = &[_]ErrorCode{
    .FAULT, .INVAL,
};
pub const stat_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,  .BADF,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .OVERFLOW,
};
pub const unlink_errors: []const ErrorCode = &[_]ErrorCode{
    .ACCES,  .BUSY, .FAULT, .IO,   .ISDIR, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
    .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
};
pub const wait_errors: []const ErrorCode = &[_]ErrorCode{
    .SRCH, .INTR, .AGAIN, .INVAL, .CHILD,
};
pub const waitid_errors: []const ErrorCode = &[_]ErrorCode{
    .AGAIN, .CHILD, .INTR, .INVAL, .SRCH,
};
pub const write_errors: []const ErrorCode = &[_]ErrorCode{
    .AGAIN, .BADF, .DESTADDRREQ, .DQUOT, .FAULT, .FBIG, .INTR, .INVAL, .IO,
    .NOSPC, .PERM, .PIPE,
};
pub const no_errors: []const ErrorCode = &[_]ErrorCode{};

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

inline fn syscall0(comptime sysno: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
        : "rax", "rcx", "r11", "memory"
    );
}
inline fn syscall1(comptime sysno: usize, arg1: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall2(comptime sysno: usize, arg1: usize, arg2: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
          [_] "{rsi}" (arg2),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall3(comptime sysno: usize, arg1: usize, arg2: usize, arg3: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
          [_] "{rsi}" (arg2),
          [_] "{rdx}" (arg3),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall4(comptime sysno: usize, arg1: usize, arg2: usize, arg3: usize, arg4: usize) isize {
    return asm volatile ("syscall"
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
          [_] "{rsi}" (arg2),
          [_] "{rdx}" (arg3),
          [_] "{r10}" (arg4),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall5(comptime sysno: usize, arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
          [_] "{rsi}" (arg2),
          [_] "{rdx}" (arg3),
          [_] "{r10}" (arg4),
          [_] "{r8}" (arg5),
        : "rcx", "r11", "memory"
    );
}
inline fn syscall6(comptime sysno: usize, arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize, arg6: usize) isize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (sysno),
          [_] "{rdi}" (arg1),
          [_] "{rsi}" (arg2),
          [_] "{rdx}" (arg3),
          [_] "{r10}" (arg4),
          [_] "{r8}" (arg5),
          [_] "{r9}" (arg6),
        : "rcx", "r11", "memory"
    );
}
const syscalls = .{
    syscall0, syscall1,
    syscall2, syscall3,
    syscall4, syscall5,
    syscall6,
};
fn ConfiguredSystemCall(comptime fn_conf: Config) type {
    return struct {
        const Unwrapped: type = fn_conf.Unwrapped();
        const sysno: usize = fn_conf.sysno();
        const syscallWithError = .{
            syscallWithError0, syscallWithError1,
            syscallWithError2, syscallWithError3,
            syscallWithError4, syscallWithError5,
            syscallWithError6,
        };
        inline fn syscallWithError0() Unwrapped {
            return fn_conf.wrap(syscall0(sysno));
        }
        inline fn syscallWithError1(arg1: usize) Unwrapped {
            return fn_conf.wrap(syscall1(sysno, arg1));
        }
        inline fn syscallWithError2(arg1: usize, arg2: usize) Unwrapped {
            return fn_conf.wrap(syscall2(sysno, arg1, arg2));
        }
        inline fn syscallWithError3(arg1: usize, arg2: usize, arg3: usize) Unwrapped {
            return fn_conf.wrap(syscall3(sysno, arg1, arg2, arg3));
        }
        inline fn syscallWithError4(arg1: usize, arg2: usize, arg3: usize, arg4: usize) Unwrapped {
            return fn_conf.wrap(syscall4(sysno, arg1, arg2, arg3, arg4));
        }
        inline fn syscallWithError5(arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize) Unwrapped {
            return fn_conf.wrap(syscall5(sysno, arg1, arg2, arg3, arg4, arg5));
        }
        inline fn syscallWithError6(arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize, arg6: usize) Unwrapped {
            return fn_conf.wrap(syscall6(sysno, arg1, arg2, arg3, arg4, arg5, arg6));
        }
        const function = syscallWithError[fn_conf.tag.args()];
        const Function = @TypeOf(function);
    };
}
pub fn ZigError(comptime return_codes: []const ErrorCode) type {
    var error_set: []const @TypeOf(@typeInfo(void)).Error = &.{};
    for (return_codes) |error_code| {
        error_set = error_set ++ [1]@TypeOf(@typeInfo(void)).Error{.{ .name = error_code.errorName() }};
    }
    return @Type(.{ .ErrorSet = error_set ++ [1]@TypeOf(@typeInfo(void)).Error{.{ .name = "OpaqueSystemError" }} });
}
pub fn zigError(comptime errors: []const ErrorCode, ret: isize) ZigError(errors) {
    inline for (errors) |@"error"| {
        if (ret == @enumToInt(@"error")) {
            return @field(ZigError(errors), @"error".errorName());
        }
    }
    return error.OpaqueSystemError;
}
pub const Config = struct {
    tag: Function,
    errors: ?[]const ErrorCode,
    return_type: type,

    /// Returns translation of configured system error codes--if any--to Zig
    /// error set.
    pub fn Errors(comptime fn_conf: Config) type {
        if (fn_conf.errors) |errors| {
            return ZigError(errors);
        }
        return error{};
    }
    /// Always require try.
    pub fn Wrapped(comptime fn_conf: Config) type {
        return fn_conf.Errors()!fn_conf.return_type;
    }
    /// No try if no error.
    pub fn Unwrapped(comptime fn_conf: Config) type {
        if (fn_conf.errors) |errors| {
            return ZigError(errors)!fn_conf.return_type;
        } else {
            return fn_conf.return_type;
        }
    }
    /// Replace the return value type with another type. Useful for functions
    /// which interface with system calls and use the result but discard or
    /// return something else to the user.
    pub fn Replaced(comptime fn_conf: Config, comptime T: type) type {
        if (fn_conf.errors) |errors| {
            return ZigError(errors)!T;
        } else {
            return T;
        }
    }
    pub fn function(comptime fn_conf: Config) ConfiguredSystemCall(fn_conf).Function {
        return ConfiguredSystemCall(fn_conf).function;
    }
    pub fn reconfigure(
        comptime fn_conf: Config,
        comptime errors: ?[]const ErrorCode,
        comptime return_type: ?type,
    ) Config {
        return .{
            .tag = fn_conf.tag,
            .errors = errors,
            .return_type = return_type orelse fn_conf.return_type,
        };
    }
    fn sysno(comptime fn_conf: Config) usize {
        return @enumToInt(fn_conf.tag);
    }
    fn wrap(comptime fn_conf: Config, ret: isize) Unwrapped(fn_conf) {
        if (fn_conf.errors) |errors| {
            if (ret < 0) return zigError(errors, ret);
        }
        if (fn_conf.return_type == void) {
            return;
        }
        if (fn_conf.return_type != noreturn) {
            return @intCast(fn_conf.return_type, ret);
        }
        unreachable;
    }
    pub fn call(comptime fn_conf: Config, args: anytype) Wrapped(fn_conf) {
        return fn_conf.wrap(@call(.always_inline, syscalls[fn_conf.tag.args()], .{@enumToInt(fn_conf.tag)} ++ args));
    }
};
pub fn FunctionInterfaceSpec(comptime Specification: type) type {
    return struct {
        fn default(comptime function: Function) Config {
            return @field(config, @tagName(function));
        }
        fn configure(comptime spec: Specification, comptime function: Function) Config {
            return Config.reconfigure(default(function), spec.errors, spec.return_type);
        }
        /// Returns translation of configured system error codes--if any--to Zig
        /// error set.
        pub fn Errors(comptime spec: Specification, comptime function: Function) type {
            return Config.Errors(configure(spec, function));
        }
        /// Always require try.
        pub fn Wrapped(comptime spec: Specification, comptime function: Function) type {
            return Config.Wrapped(configure(spec, function));
        }
        /// No try if no error.
        pub fn Unwrapped(comptime spec: Specification, comptime function: Function) type {
            return Config.Unwrapped(configure(spec, function));
        }
        /// Replace the return value type with another type. Useful for functions
        /// which interface with system calls and use the result but discard or
        /// return something else to the user.
        pub fn Replaced(comptime spec: Specification, comptime function: Function, comptime T: type) type {
            return Config.Replaced(configure(spec, function), T);
        }
        pub fn call(comptime spec: Specification, comptime function: Function, args: anytype) Wrapped(spec, function) {
            return Config.call(configure(spec, function), args);
        }
    };
}
/// Higher level functions give options to configure which errors are handled
/// or lumped into a catch-all, or ignored entirely. With this interface it is
/// also possible to configure to discard return values. e.g. mmap or mremap can
/// discard any non-error return value when *_FIXED_NOREPLACE is set, as any
/// non-error return value will be equal to the input address.
const config = opaque {
    const read: Config = .{ .tag = .read, .errors = read_errors, .return_type = usize };
    const write: Config = .{ .tag = .write, .errors = write_errors, .return_type = usize };
    const open: Config = .{ .tag = .open, .errors = open_errors, .return_type = usize };
    const openat: Config = .{ .tag = .openat, .errors = open_errors, .return_type = usize };
    const close: Config = .{ .tag = .close, .errors = close_errors, .return_type = void };
    const ioctl: Config = .{ .tag = .ioctl, .errors = ioctl_errors, .return_type = void };
    const brk: Config = .{ .tag = .brk, .errors = brk_errors, .return_type = usize };
    const mmap: Config = .{ .tag = .mmap, .errors = mmap_errors, .return_type = usize };
    const munmap: Config = .{ .tag = .munmap, .errors = munmap_errors, .return_type = void };
    const mremap: Config = .{ .tag = .mremap, .errors = mremap_errors, .return_type = usize };
    const madvise: Config = .{ .tag = .madvise, .errors = madvise_errors, .return_type = void };
    const memfd_create: Config = .{ .tag = .memfd_create, .errors = memfd_create_errors, .return_type = usize };
    const stat: Config = .{ .tag = .stat, .errors = stat_errors, .return_type = void };
    const fstat: Config = .{ .tag = .fstat, .errors = stat_errors, .return_type = void };
    const lstat: Config = .{ .tag = .lstat, .errors = stat_errors, .return_type = void };
    const statx: Config = .{ .tag = .statx, .errors = stat_errors, .return_type = void };
    const newfstatat: Config = .{ .tag = .newfstatat, .errors = stat_errors, .return_type = void };
    const mknod: Config = .{ .tag = .mknod, .errors = mknod_errors, .return_type = void };
    const mknodat: Config = .{ .tag = .mknodat, .errors = mknod_errors, .return_type = void };
    const getcwd: Config = .{ .tag = .getcwd, .errors = getcwd_errors, .return_type = usize };
    const getdents64: Config = .{ .tag = .getdents64, .errors = getdents_errors, .return_type = usize };
    const readlink: Config = .{ .tag = .readlink, .errors = readlink_errors, .return_type = usize };
    const readlinkat: Config = .{ .tag = .readlinkat, .errors = readlink_errors, .return_type = usize };
    const getuid: Config = .{ .tag = .getuid, .errors = null, .return_type = u16 };
    const getgid: Config = .{ .tag = .getgid, .errors = null, .return_type = u16 };
    const geteuid: Config = .{ .tag = .geteuid, .errors = null, .return_type = u16 };
    const getegid: Config = .{ .tag = .getegid, .errors = null, .return_type = u16 };
    const getrandom: Config = .{ .tag = .getrandom, .errors = getrandom_errors, .return_type = void };
    const unlink: Config = .{ .tag = .unlink, .errors = unlink_errors, .return_type = void };
    const unlinkat: Config = .{ .tag = .unlinkat, .errors = unlink_errors, .return_type = void };
    const truncate: Config = .{ .tag = .truncate, .errors = truncate_errors, .return_type = void };
    const ftruncate: Config = .{ .tag = .ftruncate, .errors = truncate_errors, .return_type = void };
    const mkdir: Config = .{ .tag = .mkdir, .errors = mkdir_errors, .return_type = void };
    const mkdirat: Config = .{ .tag = .mkdirat, .errors = mkdir_errors, .return_type = void };
    const rmdir: Config = .{ .tag = .rmdir, .errors = rmdir_errors, .return_type = void };
    const clock_gettime: Config = .{ .tag = .clock_gettime, .errors = clock_get_errors, .return_type = void };
    const nanosleep: Config = .{ .tag = .nanosleep, .errors = nanosleep_errors, .return_type = void };
    const dup: Config = .{ .tag = .dup, .errors = dup_errors, .return_type = usize };
    const dup2: Config = .{ .tag = .dup2, .errors = dup_errors, .return_type = usize };
    const dup3: Config = .{ .tag = .dup3, .errors = dup_errors, .return_type = usize };
    const fork: Config = .{ .tag = .fork, .errors = fork_errors, .return_type = usize };
    const wait4: Config = .{ .tag = .wait4, .errors = wait_errors, .return_type = void };
    const waitid: Config = .{ .tag = .waitid, .errors = wait_errors, .return_type = void };
    const clone: Config = .{ .tag = .clone, .errors = clone_errors, .return_type = usize };
    const clone3: Config = .{ .tag = .clone3, .errors = clone_errors, .return_type = usize };
    const execve: Config = .{ .tag = .execve, .errors = execve_errors, .return_type = usize };
    const execveat: Config = .{ .tag = .execveat, .errors = execveat_errors, .return_type = usize };
    const rt_sigaction: Config = .{ .tag = .rt_sigaction, .errors = sigaction_errors, .return_type = void };
    const name_to_handle_at: Config = .{ .tag = .name_to_handle_at, .errors = name_to_handle_at_errors, .return_type = usize };
    const open_by_handle_at: Config = .{ .tag = .open_by_handle_at, .errors = open_by_handle_at_errors, .return_type = usize };
    const exit: Config = .{ .tag = .exit, .errors = null, .return_type = noreturn };
    const noexcept = opaque {
        // Called before main
        pub const rt_sigaction = config.rt_sigaction.reconfigure(null, void);
        // Resource deallocation must succeed
        pub const munmap = config.munmap.reconfigure(null, void);
        pub const close = config.close.reconfigure(null, void);
        pub const unlink = config.unlink.reconfigure(null, void);
        // Testing
        pub const getrandom = config.getrandom.reconfigure(null, void);
        pub const write = config.write.reconfigure(null, void);
        // Called after main
        pub const readlink = config.readlink.reconfigure(null, i64);
        pub const read = config.read.reconfigure(null, u64);
    };
};

// Select system functions without configuration
pub const exit = config.exit.function();
pub const getuid = config.getuid.function();
pub const getgid = config.getgid.function();
pub const geteuid = config.geteuid.function();
pub const getegid = config.getegid.function();
pub const getdents = config.getdents64.function();
pub const write = config.write.function();
pub const read = config.read.function();
pub const clock_gettime = config.clock_gettime.function();
pub const readlinkat = config.readlinkat.function();
pub const noexcept = struct {
    pub const rt_sigaction = config.noexcept.rt_sigaction.function();
    pub const munmap = config.noexcept.munmap.function();
    pub const close = config.noexcept.close.function();
    pub const unlink = config.noexcept.unlink.function();
    pub const getrandom = config.noexcept.getrandom.function();
    pub const write = config.noexcept.write.function();
    pub const readlink = config.noexcept.readlink.function();
    pub const read = config.noexcept.read.function();
};
