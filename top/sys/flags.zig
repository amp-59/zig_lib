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
            .{ 5, 4 },  .{ 9, 1 }, .{ 9, 3 }, .{ 9, 3 },
            .{ 10, 1 }, .{ 6, 1 }, .{ 9, 1 }, .{ 8, 1 },
            .{ 8, 1 },  .{ 5, 1 }, .{ 7, 1 }, .{ 4, 1 },
            .{ 15, 1 },
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
            .{ 5, 4 },  .{ 9, 1 }, .{ 9, 3 }, .{ 9, 3 },
            .{ 10, 1 }, .{ 6, 1 }, .{ 9, 1 }, .{ 8, 1 },
            .{ 8, 1 },  .{ 5, 1 }, .{ 7, 1 }, .{ 4, 1 },
            .{ 15, 1 },
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
    close_on_exec: bool = false,
    allow_sealing: bool = false,
    hugetlb: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "CLOEXEC", 0 }, .{ "ALLOW_SEALING", 1 },
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
            .{ 7, 0 }, .{ 13, 1 },
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
pub const MemSync = packed struct(usize) {
    @"async": bool = false,
    invalidate: bool = false,
    sync: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "ASYNC", 0 }, .{ "INVALIDATE", 1 },
            .{ "SYNC", 1 },
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
            .{ 5, 0 }, .{ 10, 1 },
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
pub const MemProt = packed struct(usize) {
    read: bool = true,
    write: bool = true,
    exec: bool = false,
    zb3: u21 = 0,
    grows_down: bool = false,
    grows_up: bool = false,
    zb26: u38 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "READ", 0 },    .{ "WRITE", 1 },
            .{ "EXEC", 1 },    .{ "GROWSDOWN", 22 },
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
            .{ 4, 0 }, .{ 5, 1 },
            .{ 4, 1 }, .{ 9, 22 },
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
pub const Remap = packed struct(usize) {
    may_move: bool = false,
    fixed: bool = false,
    no_unmap: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "MAYMOVE", 0 },   .{ "FIXED", 1 },
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
            .{ 7, 0 }, .{ 5, 1 },
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
pub const MAdvise = packed struct(usize) {
    e0: enum(u7) {
        random = 1,
        sequential = 2,
        do_need = 3,
        do_not_need = 4,
        free = 8,
        remove = 9,
        do_not_fork = 10,
        do_fork = 11,
        mergeable = 12,
        unmergeable = 13,
        hugepage = 14,
        no_hugepage = 15,
        do_not_dump = 16,
        do_dump = 17,
        wipe_on_fork = 18,
        keep_on_fork = 19,
        cold = 20,
        pageout = 21,
        hw_poison = 100,
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
    current: bool = false,
    future: bool = false,
    on_fault: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "CURRENT", 0 }, .{ "FUTURE", 1 },
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
            .{ 7, 0 }, .{ 6, 1 },
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
    write_only: bool = false,
    read_write: bool = false,
    zb2: u4 = 0,
    create: bool = false,
    exclusive: bool = false,
    no_ctty: bool = false,
    truncate: bool = false,
    append: bool = false,
    non_block: bool = false,
    data_sync: bool = false,
    @"async": bool = false,
    direct: bool = false,
    zb15: u1 = 0,
    directory: bool = false,
    no_follow: bool = false,
    no_atime: bool = false,
    close_on_exec: bool = false,
    zb20: u1 = 0,
    path: bool = false,
    tmpfile: bool = false,
    zb23: u41 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "WRONLY", 0 },   .{ "RDWR", 1 },     .{ "CREAT", 5 },
            .{ "EXCL", 1 },     .{ "NOCTTY", 1 },   .{ "TRUNC", 1 },
            .{ "APPEND", 1 },   .{ "NONBLOCK", 1 }, .{ "DSYNC", 1 },
            .{ "ASYNC", 1 },    .{ "DIRECT", 1 },   .{ "DIRECTORY", 2 },
            .{ "NOFOLLOW", 1 }, .{ "NOATIME", 1 },  .{ "CLOEXEC", 1 },
            .{ "PATH", 2 },     .{ "TMPFILE", 1 },
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
            .{ 6, 0 }, .{ 4, 1 }, .{ 5, 5 },
            .{ 4, 1 }, .{ 6, 1 }, .{ 5, 1 },
            .{ 6, 1 }, .{ 8, 1 }, .{ 5, 1 },
            .{ 5, 1 }, .{ 6, 1 }, .{ 9, 2 },
            .{ 8, 1 }, .{ 7, 1 }, .{ 7, 1 },
            .{ 4, 2 }, .{ 7, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Lock = packed struct(usize) {
    SH: bool = false,
    EX: bool = false,
    NB: bool = false,
    UN: bool = false,
    zb4: u60 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "SH", 0 }, .{ "EX", 1 }, .{ "NB", 1 },
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
            .{ 2, 0 }, .{ 2, 1 }, .{ 2, 1 },
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
    trace_child: bool = false,
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
            .{ "NEWTIME", 7 },       .{ "VM", 1 },             .{ "FS", 1 },       .{ "FILES", 1 },
            .{ "SIGHAND", 1 },       .{ "PIDFD", 1 },          .{ "PTRACE", 1 },   .{ "VFORK", 1 },
            .{ "THREAD", 2 },        .{ "NEWNS", 1 },          .{ "SYSVSEM", 1 },  .{ "SETTLS", 1 },
            .{ "PARENT_SETTID", 1 }, .{ "CHILD_CLEARTID", 1 }, .{ "DETACHED", 1 }, .{ "UNTRACED", 1 },
            .{ "CHILD_SETTID", 1 },  .{ "NEWCGROUP", 1 },      .{ "NEWUTS", 1 },   .{ "NEWIPC", 1 },
            .{ "NEWUSER", 1 },       .{ "NEWPID", 1 },         .{ "NEWNET", 1 },   .{ "IO", 1 },
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
            .{ 7, 7 },  .{ 2, 1 },  .{ 2, 1 }, .{ 5, 1 },
            .{ 7, 1 },  .{ 5, 1 },  .{ 6, 1 }, .{ 5, 1 },
            .{ 6, 2 },  .{ 5, 1 },  .{ 7, 1 }, .{ 6, 1 },
            .{ 13, 1 }, .{ 14, 1 }, .{ 8, 1 }, .{ 8, 1 },
            .{ 12, 1 }, .{ 9, 1 },  .{ 6, 1 }, .{ 6, 1 },
            .{ 7, 1 },  .{ 6, 1 },  .{ 6, 1 }, .{ 2, 1 },
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
        pid = 1,
        pgid = 2,
        pidfd = 3,
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
    no_hang: bool = false,
    untraced: bool = false,
    stopped: bool = false,
    exited: bool = false,
    continued: bool = false,
    zb4: u20 = 0,
    no_wait: bool = false,
    zb25: u4 = 0,
    no_thread: bool = false,
    all: bool = false,
    clone: bool = false,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "NOHANG", 0 },    .{ "UNTRACED", 1 }, .{ "STOPPED", 0 },  .{ "EXITED", 1 },
            .{ "CONTINUED", 1 }, .{ "NOWAIT", 21 },  .{ "NOTHREAD", 5 }, .{ "ALL", 1 },
            .{ "CLONE", 1 },
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
            .{ 6, 0 }, .{ 8, 1 },  .{ 7, 0 }, .{ 6, 1 },
            .{ 9, 1 }, .{ 6, 21 }, .{ 8, 5 }, .{ 3, 1 },
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
    write: bool = false,
    read_write: bool = false,
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
    read_only: bool = false,
    no_suid: bool = false,
    no_dev: bool = false,
    no_exec: bool = false,
    no_atime: bool = false,
    strict_atime: bool = false,
    _atime: bool = false,
    no_dir_atime: bool = false,
    zb8: u12 = 0,
    id_map: bool = false,
    zb21: u43 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "RDONLY", 0 },                    .{ "NOSUID", 1 },     .{ "NODEV", 1 },
            .{ "NOEXEC", 1 },                    .{ "NOATIME", 1 },    .{ "STRICTATIME", 1 },
            .{ "_ATIME", 18446744073709551615 }, .{ "NODIRATIME", 3 }, .{ "IDMAP", 13 },
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
            .{ 6, 0 },                    .{ 6, 1 },  .{ 5, 1 },
            .{ 6, 1 },                    .{ 7, 1 },  .{ 11, 1 },
            .{ 6, 18446744073709551615 }, .{ 10, 3 }, .{ 5, 13 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const PTrace = enum(usize) {
    get_regset = 16900,
    set_regset = 16901,
    seize = 16902,
    interrupt = 16903,
    listen = 16904,
    peek_siginfo = 16905,
    get_sigmask = 16906,
    set_sigmask = 16907,
    seccomp_get_filter = 16908,
    get_syscall_info = 16910,
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
pub const SO = enum(usize) {
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
            .{ "UNIX", 0 },    .{ "INET", 1 }, .{ "INET6", 0 },
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
            .{ 4, 0 }, .{ 4, 1 }, .{ 5, 0 },
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
pub const IPPORT = enum(usize) {
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
            .{ 9, 0 },  .{ 9, 1 },  .{ 7, 1 }, .{ 11, 8 },
            .{ 14, 1 }, .{ 8, 15 }, .{ 7, 1 }, .{ 7, 1 },
            .{ 7, 2 },  .{ 9, 1 },
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
pub const FIO = enum(usize) {
    NBIO = 21537,
    NCLEX = 21584,
    CLEX = 21585,
    ASYNC = 21586,
    QSIZE = 21600,
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
pub const UTIME = enum(usize) {
    OMIT = 1073741822,
    NOW = 1073741823,
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
pub const SEEK = packed struct(usize) {
    e0: enum(u2) {
        CUR = 1,
        END = 2,
        DATA = 3,
    },
    HOLE: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, @tagName(format.e0));
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "HOLE", 2 },
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
            .{ 4, 2 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const STATX = packed struct(usize) {
    type: bool = false,
    mode: bool = false,
    nlink: bool = false,
    uid: bool = false,
    gid: bool = false,
    atime: bool = false,
    mtime: bool = false,
    ctime: bool = false,
    ino: bool = false,
    size: bool = false,
    blocks: bool = false,
    btime: bool = false,
    mount_id: bool = false,
    zb13: u51 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "TYPE", 0 },   .{ "MODE", 1 },  .{ "NLINK", 1 },  .{ "UID", 1 },
            .{ "GID", 1 },    .{ "ATIME", 1 }, .{ "MTIME", 1 },  .{ "CTIME", 1 },
            .{ "INO", 1 },    .{ "SIZE", 1 },  .{ "BLOCKS", 1 }, .{ "BTIME", 1 },
            .{ "MNT_ID", 1 },
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
            .{ 4, 0 }, .{ 4, 1 }, .{ 5, 1 }, .{ 3, 1 },
            .{ 3, 1 }, .{ 5, 1 }, .{ 5, 1 }, .{ 5, 1 },
            .{ 3, 1 }, .{ 4, 1 }, .{ 6, 1 }, .{ 5, 1 },
            .{ 6, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const STATX_ATTR = packed struct(usize) {
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
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "COMPRESSED", 2 }, .{ "IMMUTABLE", 2 }, .{ "APPEND", 1 },     .{ "NODUMP", 1 },
            .{ "ENCRYPTED", 5 },  .{ "AUTOMOUNT", 1 }, .{ "MOUNT_ROOT", 1 }, .{ "VERITY", 7 },
            .{ "DAX", 1 },
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
            .{ 10, 2 }, .{ 9, 2 }, .{ 6, 1 },  .{ 6, 1 },
            .{ 9, 5 },  .{ 9, 1 }, .{ 10, 1 }, .{ 6, 7 },
            .{ 3, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const AT = packed struct(usize) {
    zb0: u8 = 0,
    SYMLINK_NOFOLLOW: bool = false,
    REMOVEDIR: bool = false,
    SYMLINK_FOLLOW: bool = false,
    NO_AUTOMOUNT: bool = false,
    EMPTY_PATH: bool = false,
    zb13: u51 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "SYMLINK_NOFOLLOW", 8 }, .{ "REMOVEDIR", 1 },  .{ "SYMLINK_FOLLOW", 1 },
            .{ "NO_AUTOMOUNT", 1 },     .{ "EMPTY_PATH", 1 },
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
            .{ 16, 8 }, .{ 9, 1 },  .{ 14, 1 },
            .{ 12, 1 }, .{ 10, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const AUX = enum(usize) {
    EXECFD = 2,
    PHDR = 3,
    PHENT = 4,
    PHNUM = 5,
    PAGESZ = 6,
    BASE = 7,
    FLAGS = 8,
    ENTRY = 9,
    EUID = 12,
    GID = 13,
    EGID = 14,
    PLATFORM = 15,
    HWCAP = 16,
    CLKTCK = 17,
    FPUCW = 18,
    DCACHEBSIZE = 19,
    ICACHEBSIZE = 20,
    UCACHEBSIZE = 21,
    SECURE = 23,
    BASE_PLATFORM = 24,
    RANDOM = 25,
    EXECFN = 31,
    SYSINFO = 32,
    SYSINFO_EHDR = 33,
    L1I_CACHESIZE = 40,
    L1I_CACHEGEOMETRY = 41,
    L1D_CACHESIZE = 42,
    L1D_CACHEGEOMETRY = 43,
    L2_CACHESIZE = 44,
    L2_CACHEGEOMETRY = 45,
    L3_CACHESIZE = 46,
    L3_CACHEGEOMETRY = 47,
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
pub const F = packed struct(usize) {
    e0: enum(u11) {
        WRLCK = 1,
        GETFD = 1,
        SETFD = 2,
        UNLCK = 2,
        GETFL = 3,
        SETFL = 4,
        GETLK = 5,
        SETLK = 6,
        SETLKW = 7,
        SETOWN = 8,
        GETOWN = 9,
        DUPFD_CLOEXEC = 1030,
    },
    zb11: u53 = 0,
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
pub const SI = packed struct(usize) {
    e0: enum(u32) {
        KERNEL = 128,
        TKILL = 4294967290,
        SIGIO = 4294967291,
        ASYNCIO = 4294967292,
        MESGQ = 4294967293,
        TIMER = 4294967294,
        QUEUE = 4294967295,
    },
    zb32: u32 = 0,
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
pub const RWF = packed struct(usize) {
    HIPRI: bool = false,
    DSYNC: bool = false,
    SYNC: bool = false,
    NOWAIT: bool = false,
    APPEND: bool = false,
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "HIPRI", 0 },  .{ "DSYNC", 1 },  .{ "SYNC", 1 },
            .{ "NOWAIT", 1 }, .{ "APPEND", 1 },
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
            .{ 5, 0 }, .{ 5, 1 }, .{ 4, 1 },
            .{ 6, 1 }, .{ 6, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const DT = packed struct(usize) {
    FIFO: bool = false,
    CHR: bool = false,
    DIR: bool = false,
    REG: bool = false,
    LNK: bool = false,
    SOCK: bool = false,
    zb4: u60 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "FIFO", 0 },                   .{ "CHR", 1 },
            .{ "DIR", 1 },                    .{ "REG", 1 },
            .{ "LNK", 18446744073709551614 }, .{ "SOCK", 1 },
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
            .{ 4, 0 },                    .{ 3, 1 },
            .{ 3, 1 },                    .{ 3, 1 },
            .{ 3, 18446744073709551614 }, .{ 4, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const POSIX_FADV = packed struct(usize) {
    e0: enum(u3) {
        RANDOM = 1,
        SEQUENTIAL = 2,
        WILLNEED = 3,
        DONTNEED = 4,
        NOREUSE = 5,
    },
    zb3: u61 = 0,
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
pub const ITIMER = packed struct(usize) {
    VIRTUAL: bool = false,
    PROF: bool = false,
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "VIRTUAL", 0 },
            .{ "PROF", 1 },
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
pub const SEGV = enum(usize) {
    MAPERR = 1,
    ACCERR = 2,
    BNDERR = 3,
    PKUERR = 4,
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
pub const FS = packed struct(usize) {
    SECRM_FL: bool = false,
    UNRM_FL: bool = false,
    COMPR_FL: bool = false,
    SYNC_FL: bool = false,
    IMMUTABLE_FL: bool = false,
    APPEND_FL: bool = false,
    NODUMP_FL: bool = false,
    NOATIME_FL: bool = false,
    zb8: u6 = 0,
    JOURNAL_DATA_FL: bool = false,
    NOTAIL_FL: bool = false,
    DIRSYNC_FL: bool = false,
    TOPDIR_FL: bool = false,
    zb18: u5 = 0,
    NOCOW_FL: bool = false,
    zb24: u5 = 0,
    PROJINHERIT_FL: bool = false,
    zb30: u34 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u8 }{
            .{ "SECRM_FL", 0 },        .{ "UNRM_FL", 1 },        .{ "COMPR_FL", 1 },   .{ "SYNC_FL", 1 },
            .{ "IMMUTABLE_FL", 1 },    .{ "APPEND_FL", 1 },      .{ "NODUMP_FL", 1 },  .{ "NOATIME_FL", 1 },
            .{ "JOURNAL_DATA_FL", 7 }, .{ "NOTAIL_FL", 1 },      .{ "DIRSYNC_FL", 1 }, .{ "TOPDIR_FL", 1 },
            .{ "NOCOW_FL", 6 },        .{ "PROJINHERIT_FL", 6 },
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
            .{ 8, 0 },  .{ 7, 1 },  .{ 8, 1 },  .{ 7, 1 },
            .{ 12, 1 }, .{ 9, 1 },  .{ 9, 1 },  .{ 10, 1 },
            .{ 15, 7 }, .{ 9, 1 },  .{ 10, 1 }, .{ 9, 1 },
            .{ 8, 6 },  .{ 14, 6 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
