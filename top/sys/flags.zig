pub const fmt = @import("../fmt.zig");
pub const debug = @import("../debug.zig");
pub const builtin = @import("../builtin.zig");
pub const extra = @import("./extra.zig");
pub const MemMap = packed struct(usize) {
    visibility: enum(u2) {
        shared = 1,
        private = 2,
        shared_validate = 3,
    } = .private,
    zb2: u2 = 0,
    fixed: bool = false,
    anonymous: bool = true,
    zb6: u2 = 0,
    grows_down: bool = false,
    zb9: u2 = 0,
    deny_write: bool = false,
    executable: bool = false,
    locked: bool = false,
    no_reserve: bool = false,
    populate: bool = false,
    non_block: bool = false,
    stack: bool = false,
    hugetlb: bool = false,
    sync: bool = false,
    fixed_noreplace: bool = true,
    zb21: u43 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.visibility));
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "FIXED", 4 },           .{ "ANONYMOUS", 1 }, .{ "GROWSDOWN", 3 }, .{ "DENYWRITE", 3 },
            .{ "EXECUTABLE", 1 },      .{ "LOCKED", 1 },    .{ "NORESERVE", 1 }, .{ "POPULATE", 1 },
            .{ "NONBLOCK", 1 },        .{ "STACK", 1 },     .{ "HUGETLB", 1 },   .{ "SYNC", 1 },
            .{ "FIXED_NOREPLACE", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.visibility).len;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 5, 4 }, .{ 9, 1 }, .{ 9, 3 }, .{ 9, 3 },  .{ 10, 1 }, .{ 6, 1 }, .{ 9, 1 }, .{ 8, 1 }, .{ 8, 1 },
            .{ 5, 1 }, .{ 7, 1 }, .{ 4, 1 }, .{ 15, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const FileMap = packed struct(usize) {
    visibility: enum(u2) {
        shared = 1,
        private = 2,
        shared_validate = 3,
    } = .private,
    zb2: u2 = 0,
    fixed: bool = true,
    anonymous: bool = false,
    zb6: u2 = 0,
    grows_down: bool = false,
    zb9: u2 = 0,
    deny_write: bool = false,
    executable: bool = false,
    locked: bool = false,
    no_reserve: bool = false,
    populate: bool = false,
    non_block: bool = false,
    stack: bool = false,
    hugetlb: bool = false,
    sync: bool = false,
    fixed_noreplace: bool = false,
    zb21: u43 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.visibility));
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "FIXED", 4 },           .{ "ANONYMOUS", 1 }, .{ "GROWSDOWN", 3 }, .{ "DENYWRITE", 3 },
            .{ "EXECUTABLE", 1 },      .{ "LOCKED", 1 },    .{ "NORESERVE", 1 }, .{ "POPULATE", 1 },
            .{ "NONBLOCK", 1 },        .{ "STACK", 1 },     .{ "HUGETLB", 1 },   .{ "SYNC", 1 },
            .{ "FIXED_NOREPLACE", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.visibility).len;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 5, 4 }, .{ 9, 1 }, .{ 9, 3 }, .{ 9, 3 },  .{ 10, 1 }, .{ 6, 1 }, .{ 9, 1 }, .{ 8, 1 }, .{ 8, 1 },
            .{ 5, 1 }, .{ 7, 1 }, .{ 4, 1 }, .{ 15, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const MemFd = packed struct(usize) {
    CLOEXEC: bool = false,
    ALLOW_SEALING: bool = false,
    HUGETLB: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "CLOEXEC", 0 },
            .{ "ALLOW_SEALING", 1 },
            .{ "HUGETLB", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 7, 0 },
            .{ 13, 1 },
            .{ 7, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const PROT = packed struct(usize) {
    READ: bool = false,
    WRITE: bool = false,
    EXEC: bool = false,
    zb3: u21 = 0,
    GROWSDOWN: bool = false,
    GROWSUP: bool = false,
    zb26: u38 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "READ", 0 },
            .{ "WRITE", 1 },
            .{ "EXEC", 1 },
            .{ "GROWSDOWN", 22 },
            .{ "GROWSUP", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 4, 0 },
            .{ 5, 1 },
            .{ 4, 1 },
            .{ 9, 22 },
            .{ 7, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const REMAP = packed struct(usize) {
    MAYMOVE: bool = false,
    FIXED: bool = false,
    DONTUNMAP: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "MAYMOVE", 0 },
            .{ "FIXED", 1 },
            .{ "DONTUNMAP", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 7, 0 },
            .{ 5, 1 },
            .{ 9, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const MADV = packed struct(usize) {
    e0: enum(u7) {
        RANDOM = 1,
        SEQUENTIAL = 2,
        WILLNEED = 3,
        DONTNEED = 4,
        FREE = 8,
        REMOVE = 9,
        DONTFORK = 10,
        DOFORK = 11,
        MERGEABLE = 12,
        UNMERGEABLE = 13,
        HUGEPAGE = 14,
        NOHUGEPAGE = 15,
        DONTDUMP = 16,
        DODUMP = 17,
        WIPEONFORK = 18,
        KEEPONFORK = 19,
        COLD = 20,
        PAGEOUT = 21,
        HWPOISON = 100,
    },
    zb7: u57 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const MCL = packed struct(usize) {
    CURRENT: bool = false,
    FUTURE: bool = false,
    ONFAULT: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "CURRENT", 0 },
            .{ "FUTURE", 1 },
            .{ "ONFAULT", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 7, 0 },
            .{ 6, 1 },
            .{ 7, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Open = packed struct(usize) {
    WRONLY: bool = false,
    RDWR: bool = false,
    zb2: u4 = 0,
    CREAT: bool = false,
    EXCL: bool = false,
    NOCTTY: bool = false,
    TRUNC: bool = false,
    APPEND: bool = false,
    NONBLOCK: bool = false,
    DSYNC: bool = false,
    ASYNC: bool = false,
    DIRECT: bool = false,
    zb15: u1 = 0,
    DIRECTORY: bool = false,
    NOFOLLOW: bool = false,
    NOATIME: bool = false,
    CLOEXEC: bool = false,
    zb20: u1 = 0,
    PATH: bool = false,
    TMPFILE: bool = false,
    zb23: u41 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "WRONLY", 0 }, .{ "RDWR", 1 },      .{ "CREAT", 5 },    .{ "EXCL", 1 },    .{ "NOCTTY", 1 },
            .{ "TRUNC", 1 },  .{ "APPEND", 1 },    .{ "NONBLOCK", 1 }, .{ "DSYNC", 1 },   .{ "ASYNC", 1 },
            .{ "DIRECT", 1 }, .{ "DIRECTORY", 2 }, .{ "NOFOLLOW", 1 }, .{ "NOATIME", 1 }, .{ "CLOEXEC", 1 },
            .{ "PATH", 2 },   .{ "TMPFILE", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 }, .{ 4, 1 }, .{ 5, 5 }, .{ 4, 1 }, .{ 6, 1 }, .{ 5, 1 }, .{ 6, 1 }, .{ 8, 1 }, .{ 5, 1 },
            .{ 5, 1 }, .{ 6, 1 }, .{ 9, 2 }, .{ 8, 1 }, .{ 7, 1 }, .{ 7, 1 }, .{ 4, 2 }, .{ 7, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const LOCK = packed struct(usize) {
    SH: bool = false,
    EX: bool = false,
    NB: bool = false,
    UN: bool = false,
    zb4: u60 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "SH", 0 },
            .{ "EX", 1 },
            .{ "NB", 1 },
            .{ "UN", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 2, 0 },
            .{ 2, 1 },
            .{ 2, 1 },
            .{ 2, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Clone = packed struct(u32) {
    zb0: u7 = 0,
    new_time: bool = false,
    vm: bool = false,
    fs: bool = false,
    files: bool = false,
    signal_handlers: bool = false,
    pid_fd: bool = false,
    PTRACE: bool = false,
    vfork: bool = false,
    zb15: u1 = 0,
    thread: bool = false,
    new_namespace: bool = false,
    sysvsem: bool = false,
    set_thread_local_storage: bool = false,
    set_parent_thread_id: bool = false,
    clear_child_thread_id: bool = false,
    detached: bool = false,
    untraced: bool = false,
    set_child_thread_id: bool = false,
    new_cgroup: bool = false,
    new_uts: bool = false,
    new_ipc: bool = false,
    new_user: bool = false,
    new_pid: bool = false,
    new_net: bool = false,
    io: bool = false,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: u32 = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "NEWTIME", 7 },  .{ "VM", 1 },           .{ "FS", 1 },            .{ "FILES", 1 },          .{ "SIGHAND", 1 },
            .{ "PIDFD", 1 },    .{ "PTRACE", 1 },       .{ "VFORK", 1 },         .{ "THREAD", 2 },         .{ "NEWNS", 1 },
            .{ "SYSVSEM", 1 },  .{ "SETTLS", 1 },       .{ "PARENT_SETTID", 1 }, .{ "CHILD_CLEARTID", 1 }, .{ "DETACHED", 1 },
            .{ "UNTRACED", 1 }, .{ "CHILD_SETTID", 1 }, .{ "NEWCGROUP", 1 },     .{ "NEWUTS", 1 },         .{ "NEWIPC", 1 },
            .{ "NEWUSER", 1 },  .{ "NEWPID", 1 },       .{ "NEWNET", 1 },        .{ "IO", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: u32 = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 7, 7 }, .{ 2, 1 }, .{ 2, 1 }, .{ 5, 1 },  .{ 7, 1 },  .{ 5, 1 }, .{ 6, 1 }, .{ 5, 1 },  .{ 6, 2 },
            .{ 5, 1 }, .{ 7, 1 }, .{ 6, 1 }, .{ 13, 1 }, .{ 14, 1 }, .{ 8, 1 }, .{ 8, 1 }, .{ 12, 1 }, .{ 9, 1 },
            .{ 6, 1 }, .{ 6, 1 }, .{ 7, 1 }, .{ 6, 1 },  .{ 6, 1 },  .{ 2, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Id = packed struct(usize) {
    e0: enum(u2) {
        PID = 1,
        PGID = 2,
        PIDFD = 3,
    },
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const Wait = packed struct(usize) {
    NOHANG: bool = false,
    UNTRACED: bool = false,
    STOPPED: bool = false,
    EXITED: bool = false,
    CONTINUED: bool = false,
    zb4: u20 = 0,
    NOWAIT: bool = false,
    zb25: u4 = 0,
    NOTHREAD: bool = false,
    ALL: bool = false,
    CLONE: bool = false,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "NOHANG", 0 },  .{ "UNTRACED", 1 }, .{ "STOPPED", 0 }, .{ "EXITED", 1 }, .{ "CONTINUED", 1 },
            .{ "NOWAIT", 21 }, .{ "NOTHREAD", 5 }, .{ "ALL", 1 },     .{ "CLONE", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 },
            .{ 8, 1 },
            .{ 7, 0 },
            .{ 6, 1 },
            .{ 9, 1 },
            .{ 6, 21 },
            .{ 8, 5 },
            .{ 3, 1 },
            .{ 5, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Shut = packed struct(usize) {
    WR: bool = false,
    RDWR: bool = false,
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "WR", 0 },
            .{ "RDWR", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 2, 0 },
            .{ 4, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const MountAttr = packed struct(usize) {
    RDONLY: bool = false,
    NOSUID: bool = false,
    NODEV: bool = false,
    NOEXEC: bool = false,
    NOATIME: bool = false,
    STRICTATIME: bool = false,
    _ATIME: bool = false,
    NODIRATIME: bool = false,
    zb8: u12 = 0,
    IDMAP: bool = false,
    zb21: u43 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "RDONLY", 0 },      .{ "NOSUID", 1 },                    .{ "NODEV", 1 },      .{ "NOEXEC", 1 }, .{ "NOATIME", 1 },
            .{ "STRICTATIME", 1 }, .{ "_ATIME", 18446744073709551615 }, .{ "NODIRATIME", 3 }, .{ "IDMAP", 13 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 },  .{ 6, 1 },  .{ 5, 1 }, .{ 6, 1 }, .{ 7, 1 }, .{ 11, 1 }, .{ 6, 18446744073709551615 },
            .{ 10, 3 }, .{ 5, 13 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const PTrace = packed struct(usize) {
    e0: enum(u15) {
        GETREGSET = 16900,
        SETREGSET = 16901,
        SEIZE = 16902,
        INTERRUPT = 16903,
        LISTEN = 16904,
        PEEKSIGINFO = 16905,
        GETSIGMASK = 16906,
        SETSIGMASK = 16907,
        SECCOMP_GET_FILTER = 16908,
        GET_SYSCALL_INFO = 16910,
    },
    zb15: u49 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const SO = packed struct(usize) {
    e0: enum(u7) {
        DEBUG = 1,
        REUSEADDR = 2,
        TYPE = 3,
        ERROR = 4,
        DONTROUTE = 5,
        BROADCAST = 6,
        SNDBUF = 7,
        RCVBUF = 8,
        KEEPALIVE = 9,
        OOBINLINE = 10,
        NO_CHECK = 11,
        PRIORITY = 12,
        LINGER = 13,
        BSDCOMPAT = 14,
        REUSEPORT = 15,
        PASSCRED = 16,
        PEERCRED = 17,
        RCVLOWAT = 18,
        SNDLOWAT = 19,
        RCVTIMEO_OLD = 20,
        RCVTIMEO = 20,
        SNDTIMEO_OLD = 21,
        SNDTIMEO = 21,
        SECURITY_AUTHENTICATION = 22,
        SECURITY_ENCRYPTION_TRANSPORT = 23,
        SECURITY_ENCRYPTION_NETWORK = 24,
        BINDTODEVICE = 25,
        ATTACH_FILTER = 26,
        GET_FILTER = 26,
        DETACH_FILTER = 27,
        DETACH_BPF = 27,
        PEERNAME = 28,
        TIMESTAMP_OLD = 29,
        TIMESTAMP = 29,
        ACCEPTCONN = 30,
        PEERSEC = 31,
        SNDBUFFORCE = 32,
        RCVBUFFORCE = 33,
        PASSSEC = 34,
        TIMESTAMPNS_OLD = 35,
        TIMESTAMPNS = 35,
        MARK = 36,
        TIMESTAMPING_OLD = 37,
        TIMESTAMPING = 37,
        PROTOCOL = 38,
        DOMAIN = 39,
        RXQ_OVFL = 40,
        WIFI_STATUS = 41,
        SCM_WIFI_STATUS = 41,
        PEEK_OFF = 42,
        NOFCS = 43,
        LOCK_FILTER = 44,
        SELECT_ERR_QUEUE = 45,
        BUSY_POLL = 46,
        MAX_PACING_RATE = 47,
        BPF_EXTENSIONS = 48,
        INCOMING_CPU = 49,
        ATTACH_BPF = 50,
        ATTACH_REUSEPORT_CBPF = 51,
        ATTACH_REUSEPORT_EBPF = 52,
        CNX_ADVICE = 53,
        SCM_TIMESTAMPING_OPT_STATS = 54,
        MEMINFO = 55,
        INCOMING_NAPI_ID = 56,
        COOKIE = 57,
        SCM_TIMESTAMPING_PKTINFO = 58,
        PEERGROUPS = 59,
        ZEROCOPY = 60,
        TXTIME = 61,
        SCM_TXTIME = 61,
        BINDTOIFINDEX = 62,
        TIMESTAMP_NEW = 63,
        TIMESTAMPNS_NEW = 64,
        TIMESTAMPING_NEW = 65,
        RCVTIMEO_NEW = 66,
        SNDTIMEO_NEW = 67,
        DETACH_REUSEPORT_BPF = 68,
        PREFER_BUSY_POLL = 69,
        BUSY_POLL_BUDGET = 70,
        NETNS_COOKIE = 71,
        BUF_LOCK = 72,
        RESERVE_MEM = 73,
        TXREHASH = 74,
    },
    zb7: u57 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const AF = packed struct(usize) {
    UNIX: bool = false,
    INET: bool = false,
    zb2: u1 = 0,
    INET6: bool = false,
    NETLINK: bool = false,
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "UNIX", 0 },
            .{ "INET", 1 },
            .{ "INET6", 0 },
            .{ "NETLINK", 3 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 4, 0 },
            .{ 4, 1 },
            .{ 5, 0 },
            .{ 7, 3 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const SOCK = packed struct(usize) {
    e0: enum(u2) {
        STREAM = 1,
        DGRAM = 2,
        RAW = 3,
    },
    zb2: u9 = 0,
    NONBLOCK: bool = false,
    zb12: u7 = 0,
    CLOEXEC: bool = false,
    zb20: u44 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "NONBLOCK", 11 },
            .{ "CLOEXEC", 8 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 8, 11 },
            .{ 7, 8 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const IPPROTO = packed struct(usize) {
    e0: enum(u9) {
        ICMP = 1,
        IGMP = 2,
        IPIP = 4,
        TCP = 6,
        EGP = 8,
        PUP = 12,
        UDP = 17,
        IDP = 22,
        TP = 29,
        DCCP = 33,
        IPV6 = 41,
        ROUTING = 43,
        FRAGMENT = 44,
        RSVP = 46,
        GRE = 47,
        ESP = 50,
        AH = 51,
        ICMPV6 = 58,
        NONE = 59,
        DSTOPTS = 60,
        MTP = 92,
        BEETPH = 94,
        ENCAP = 98,
        PIM = 103,
        COMP = 108,
        L2TP = 115,
        SCTP = 132,
        MH = 135,
        UDPLITE = 136,
        MPLS = 137,
        ETHERNET = 143,
        RAW = 255,
        MPTCP = 262,
        MAX = 263,
    },
    zb9: u55 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const IPPORT = packed struct(usize) {
    e0: enum(u13) {
        ECHO = 7,
        DISCARD = 9,
        SYSTAT = 11,
        DAYTIME = 13,
        NETSTAT = 15,
        FTP = 21,
        TELNET = 23,
        SMTP = 25,
        TIMESERVER = 37,
        NAMESERVER = 42,
        WHOIS = 43,
        MTP = 57,
        TFTP = 69,
        RJE = 77,
        FINGER = 79,
        TTYLINK = 87,
        SUPDUP = 95,
        EXECSERVER = 512,
        BIFFUDP = 512,
        LOGINSERVER = 513,
        WHOSERVER = 513,
        CMDSERVER = 514,
        EFSSERVER = 520,
        ROUTESERVER = 520,
        USERRESERVED = 5000,
        RESERVED = 1024,
    },
    zb13: u51 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const SignalAction = packed struct(usize) {
    no_child_stop: bool = false,
    no_child_wait: bool = false,
    siginfo: bool = false,
    zb3: u7 = 0,
    unsupported: bool = false,
    expose_tagbits: bool = false,
    zb12: u14 = 0,
    restorer: bool = false,
    on_stack: bool = false,
    restart: bool = false,
    zb29: u1 = 0,
    no_defer: bool = false,
    reset_handler: bool = false,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "NOCLDSTOP", 0 },      .{ "NOCLDWAIT", 1 }, .{ "SIGINFO", 1 }, .{ "UNSUPPORTED", 8 },
            .{ "EXPOSE_TAGBITS", 1 }, .{ "RESTORER", 15 }, .{ "ONSTACK", 1 }, .{ "RESTART", 1 },
            .{ "NODEFER", 2 },        .{ "RESETHAND", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 9, 0 }, .{ 9, 1 }, .{ 7, 1 }, .{ 11, 8 }, .{ 14, 1 }, .{ 8, 15 }, .{ 7, 1 }, .{ 7, 1 }, .{ 7, 2 },
            .{ 9, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const SIG = packed struct(usize) {
    e0: enum(u5) {
        HUP = 1,
        INT = 2,
        QUIT = 3,
        ILL = 4,
        TRAP = 5,
        ABRT = 6,
        BUS = 7,
        FPE = 8,
        KILL = 9,
        USR1 = 10,
        SEGV = 11,
        USR2 = 12,
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
    },
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const TIOC = packed struct(usize) {
    e0: enum(u15) {
        PKT_FLUSHREAD = 1,
        SER_TEMT = 1,
        PKT_FLUSHWRITE = 2,
        PKT_STOP = 4,
        PKT_START = 8,
        PKT_NOSTOP = 16,
        PKT_DOSTOP = 32,
        PKT_IOCTL = 64,
        EXCL = 21516,
        NXCL = 21517,
        SCTTY = 21518,
        GPGRP = 21519,
        SPGRP = 21520,
        OUTQ = 21521,
        STI = 21522,
        GWINSZ = 21523,
        SWINSZ = 21524,
        MGET = 21525,
        MBIS = 21526,
        MBIC = 21527,
        MSET = 21528,
        GSOFTCAR = 21529,
        SSOFTCAR = 21530,
        INQ = 21531,
        LINUX = 21532,
        CONS = 21533,
        GSERIAL = 21534,
        SSERIAL = 21535,
        PKT = 21536,
        NOTTY = 21538,
        SETD = 21539,
        GETD = 21540,
        SBRK = 21543,
        CBRK = 21544,
        GSID = 21545,
        GRS485 = 21550,
        SRS485 = 21551,
        SERCONFIG = 21587,
        SERGWILD = 21588,
        SERSWILD = 21589,
        GLCKTRMIOS = 21590,
        SLCKTRMIOS = 21591,
        SERGSTRUCT = 21592,
        SERGETLSR = 21593,
        SERGETMULTI = 21594,
        SERSETMULTI = 21595,
        MIWAIT = 21596,
        GICOUNT = 21597,
    },
    zb15: u49 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const FIO = packed struct(usize) {
    e0: enum(u15) {
        NBIO = 21537,
        NCLEX = 21584,
        CLEX = 21585,
        ASYNC = 21586,
        QSIZE = 21600,
    },
    zb15: u49 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
