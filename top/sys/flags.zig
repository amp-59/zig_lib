pub const fmt = @import("../fmt.zig");
pub const debug = @import("../debug.zig");
pub const builtin = @import("../builtin.zig");
pub const extra = @import("extra.zig");
pub const MemMap = packed struct(usize) {
    visibility: enum(u2) {
        shared = 0x1,
        private = 0x2,
        shared_validate = 0x3,
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.visibility));
        for ([_]struct { []const u8, u8 }{
            .{ "fixed", 4 },
            .{ "anonymous", 1 },
            .{ "grows_down", 3 },
            .{ "deny_write", 3 },
            .{ "executable", 1 },
            .{ "locked", 1 },
            .{ "no_reserve", 1 },
            .{ "populate", 1 },
            .{ "non_block", 1 },
            .{ "stack", 1 },
            .{ "hugetlb", 1 },
            .{ "sync", 1 },
            .{ "fixed_noreplace", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        shared = 0x1,
        private = 0x2,
        shared_validate = 0x3,
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.visibility));
        for ([_]struct { []const u8, u8 }{
            .{ "fixed", 4 },
            .{ "anonymous", 1 },
            .{ "grows_down", 3 },
            .{ "deny_write", 3 },
            .{ "executable", 1 },
            .{ "locked", 1 },
            .{ "no_reserve", 1 },
            .{ "populate", 1 },
            .{ "non_block", 1 },
            .{ "stack", 1 },
            .{ "hugetlb", 1 },
            .{ "sync", 1 },
            .{ "fixed_noreplace", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "close_on_exec", 0 },
            .{ "allow_sealing", 1 },
            .{ "hugetlb", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "async", 0 },
            .{ "invalidate", 1 },
            .{ "sync", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "read", 0 },
            .{ "write", 1 },
            .{ "exec", 1 },
            .{ "grows_down", 22 },
            .{ "grows_up", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const FileProt = packed struct(usize) {
    read: bool = true,
    write: bool = true,
    exec: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "read", 0 },
            .{ "write", 1 },
            .{ "exec", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 4, 0 }, .{ 5, 1 },
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
pub const Remap = packed struct(usize) {
    may_move: bool = false,
    fixed: bool = false,
    no_unmap: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "may_move", 0 },
            .{ "fixed", 1 },
            .{ "no_unmap", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        random = 0x1,
        sequential = 0x2,
        do_need = 0x3,
        do_not_need = 0x4,
        free = 0x8,
        remove = 0x9,
        do_not_fork = 0xa,
        do_fork = 0xb,
        mergeable = 0xc,
        unmergeable = 0xd,
        hugepage = 0xe,
        no_hugepage = 0xf,
        do_not_dump = 0x10,
        do_dump = 0x11,
        wipe_on_fork = 0x12,
        keep_on_fork = 0x13,
        cold = 0x14,
        pageout = 0x15,
        hw_poison = 0x64,
    },
    zb7: u57 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "current", 0 },
            .{ "future", 1 },
            .{ "on_fault", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "write_only", 0 },
            .{ "read_write", 1 },
            .{ "create", 5 },
            .{ "exclusive", 1 },
            .{ "no_ctty", 1 },
            .{ "truncate", 1 },
            .{ "append", 1 },
            .{ "non_block", 1 },
            .{ "data_sync", 1 },
            .{ "async", 1 },
            .{ "direct", 1 },
            .{ "directory", 2 },
            .{ "no_follow", 1 },
            .{ "no_atime", 1 },
            .{ "close_on_exec", 1 },
            .{ "path", 2 },
            .{ "tmpfile", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 }, .{ 4, 1 }, .{ 5, 5 }, .{ 4, 1 },
            .{ 6, 1 }, .{ 5, 1 }, .{ 6, 1 }, .{ 8, 1 },
            .{ 5, 1 }, .{ 5, 1 }, .{ 6, 1 }, .{ 9, 2 },
            .{ 8, 1 }, .{ 7, 1 }, .{ 7, 1 }, .{ 4, 2 },
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
pub const Create = packed struct(usize) {
    write_only: bool = false,
    read_write: bool = true,
    zb2: u4 = 0,
    create: bool = true,
    exclusive: bool = false,
    no_ctty: bool = false,
    truncate: bool = true,
    append: bool = false,
    non_block: bool = false,
    data_sync: bool = false,
    @"async": bool = false,
    direct: bool = false,
    zb15: u2 = 0,
    no_follow: bool = false,
    no_atime: bool = false,
    close_on_exec: bool = false,
    zb20: u1 = 0,
    path: bool = false,
    tmpfile: bool = false,
    zb23: u41 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "write_only", 0 },
            .{ "read_write", 1 },
            .{ "create", 5 },
            .{ "exclusive", 1 },
            .{ "no_ctty", 1 },
            .{ "truncate", 1 },
            .{ "append", 1 },
            .{ "non_block", 1 },
            .{ "data_sync", 1 },
            .{ "async", 1 },
            .{ "direct", 1 },
            .{ "no_follow", 3 },
            .{ "no_atime", 1 },
            .{ "close_on_exec", 1 },
            .{ "path", 2 },
            .{ "tmpfile", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 }, .{ 4, 1 }, .{ 5, 5 }, .{ 4, 1 },
            .{ 6, 1 }, .{ 5, 1 }, .{ 6, 1 }, .{ 8, 1 },
            .{ 5, 1 }, .{ 5, 1 }, .{ 6, 1 }, .{ 8, 3 },
            .{ 7, 1 }, .{ 7, 1 }, .{ 4, 2 }, .{ 7, 1 },
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "SH", 0 },
            .{ "EX", 1 },
            .{ "NB", 1 },
            .{ "UN", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const Clone = packed struct(usize) {
    zb0: u7 = 0,
    new_time: bool = false,
    vm: bool = true,
    fs: bool = true,
    files: bool = true,
    signal_handlers: bool = true,
    pid_fd: bool = false,
    trace_child: bool = false,
    vfork: bool = false,
    zb15: u1 = 0,
    thread: bool = true,
    new_namespace: bool = false,
    sysvsem: bool = true,
    set_thread_local_storage: bool = false,
    set_parent_thread_id: bool = true,
    clear_child_thread_id: bool = true,
    detached: bool = false,
    untraced: bool = false,
    set_child_thread_id: bool = true,
    new_cgroup: bool = false,
    new_uts: bool = false,
    new_ipc: bool = false,
    new_user: bool = false,
    new_pid: bool = false,
    new_net: bool = false,
    io: bool = false,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "new_time", 7 },
            .{ "vm", 1 },
            .{ "fs", 1 },
            .{ "files", 1 },
            .{ "signal_handlers", 1 },
            .{ "pid_fd", 1 },
            .{ "trace_child", 1 },
            .{ "vfork", 1 },
            .{ "thread", 2 },
            .{ "new_namespace", 1 },
            .{ "sysvsem", 1 },
            .{ "set_thread_local_storage", 1 },
            .{ "set_parent_thread_id", 1 },
            .{ "clear_child_thread_id", 1 },
            .{ "detached", 1 },
            .{ "untraced", 1 },
            .{ "set_child_thread_id", 1 },
            .{ "new_cgroup", 1 },
            .{ "new_uts", 1 },
            .{ "new_ipc", 1 },
            .{ "new_user", 1 },
            .{ "new_pid", 1 },
            .{ "new_net", 1 },
            .{ "io", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
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
        pid = 0x1,
        pgid = 0x2,
        pidfd = 0x3,
    },
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const Wait = packed struct(usize) {
    no_hang: bool = false,
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "no_hang", 0 },
            .{ "stopped", 1 },
            .{ "exited", 1 },
            .{ "continued", 1 },
            .{ "no_wait", 21 },
            .{ "no_thread", 5 },
            .{ "all", 1 },
            .{ "clone", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 }, .{ 7, 1 },  .{ 6, 1 },
            .{ 9, 1 }, .{ 6, 21 }, .{ 8, 5 },
            .{ 3, 1 }, .{ 5, 1 },
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "write", 0 },
            .{ "read_write", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
    zb6: u1 = 0,
    no_dir_atime: bool = false,
    zb8: u12 = 0,
    id_map: bool = false,
    zb21: u43 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "read_only", 0 },
            .{ "no_suid", 1 },
            .{ "no_dev", 1 },
            .{ "no_exec", 1 },
            .{ "no_atime", 1 },
            .{ "strict_atime", 1 },
            .{ "no_dir_atime", 2 },
            .{ "id_map", 13 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 },  .{ 6, 1 },  .{ 5, 1 },
            .{ 6, 1 },  .{ 7, 1 },  .{ 11, 1 },
            .{ 10, 2 }, .{ 5, 13 },
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
    get_regset = 0x4204,
    set_regset = 0x4205,
    seize = 0x4206,
    interrupt = 0x4207,
    listen = 0x4208,
    peek_siginfo = 0x4209,
    get_sigmask = 0x420a,
    set_sigmask = 0x420b,
    seccomp_get_filter = 0x420c,
    get_syscall_info = 0x420e,
};
pub const AF = packed struct(usize) {
    UNIX: bool = false,
    INET: bool = false,
    zb2: u1 = 0,
    INET6: bool = false,
    NETLINK: bool = false,
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "UNIX", 0 },
            .{ "INET", 1 },
            .{ "INET6", 0 },
            .{ "NETLINK", 3 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        STREAM = 0x1,
        DGRAM = 0x2,
        RAW = 0x3,
    },
    zb2: u9 = 0,
    NONBLOCK: bool = false,
    zb12: u7 = 0,
    CLOEXEC: bool = false,
    zb20: u44 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        for ([_]struct { []const u8, u8 }{
            .{ "NONBLOCK", 11 },
            .{ "CLOEXEC", 8 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        ICMP = 0x1,
        IGMP = 0x2,
        IPIP = 0x4,
        TCP = 0x6,
        EGP = 0x8,
        PUP = 0xc,
        UDP = 0x11,
        IDP = 0x16,
        TP = 0x1d,
        DCCP = 0x21,
        IPV6 = 0x29,
        ROUTING = 0x2b,
        FRAGMENT = 0x2c,
        RSVP = 0x2e,
        GRE = 0x2f,
        ESP = 0x32,
        AH = 0x33,
        ICMPV6 = 0x3a,
        NONE = 0x3b,
        DSTOPTS = 0x3c,
        MTP = 0x5c,
        BEETPH = 0x5e,
        ENCAP = 0x62,
        PIM = 0x67,
        COMP = 0x6c,
        L2TP = 0x73,
        SCTP = 0x84,
        MH = 0x87,
        UDPLITE = 0x88,
        MPLS = 0x89,
        ETHERNET = 0x8f,
        RAW = 0xff,
        MPTCP = 0x106,
        MAX = 0x107,
    },
    zb9: u55 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const IPPORT = enum(usize) {
    ECHO = 0x7,
    DISCARD = 0x9,
    SYSTAT = 0xb,
    DAYTIME = 0xd,
    NETSTAT = 0xf,
    FTP = 0x15,
    TELNET = 0x17,
    SMTP = 0x19,
    TIMESERVER = 0x25,
    NAMESERVER = 0x2a,
    WHOIS = 0x2b,
    MTP = 0x39,
    TFTP = 0x45,
    RJE = 0x4d,
    FINGER = 0x4f,
    TTYLINK = 0x57,
    SUPDUP = 0x5f,
    EXECSERVER = 0x200,
    LOGINSERVER = 0x201,
    CMDSERVER = 0x202,
    EFSSERVER = 0x208,
    USERRESERVED = 0x1388,
    RESERVED = 0x400,
};
pub const SignalAction = packed struct(usize) {
    no_child_stop: bool = false,
    no_child_wait: bool = false,
    siginfo: bool = true,
    zb3: u7 = 0,
    unsupported: bool = false,
    expose_tagbits: bool = false,
    zb12: u14 = 0,
    restorer: bool = true,
    on_stack: bool = false,
    restart: bool = true,
    zb29: u1 = 0,
    no_defer: bool = false,
    reset_handler: bool = true,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "no_child_stop", 0 },
            .{ "no_child_wait", 1 },
            .{ "siginfo", 1 },
            .{ "unsupported", 8 },
            .{ "expose_tagbits", 1 },
            .{ "restorer", 15 },
            .{ "on_stack", 1 },
            .{ "restart", 1 },
            .{ "no_defer", 2 },
            .{ "reset_handler", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const SignalStack = packed struct(u32) {
    on_stack: bool = false,
    disable: bool = false,
    zb2: u29 = 0,
    auto_disarm: bool = false,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: u32 = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "on_stack", 0 },
            .{ "disable", 1 },
            .{ "auto_disarm", 30 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(u32, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: u32 = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 7, 0 },   .{ 7, 1 },
            .{ 10, 30 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Signal = packed struct(usize) {
    e0: enum(u5) {
        HUP = 0x1,
        INT = 0x2,
        QUIT = 0x3,
        ILL = 0x4,
        TRAP = 0x5,
        ABRT = 0x6,
        BUS = 0x7,
        FPE = 0x8,
        KILL = 0x9,
        USR1 = 0xa,
        SEGV = 0xb,
        USR2 = 0xc,
        PIPE = 0xd,
        ALRM = 0xe,
        TERM = 0xf,
        STKFLT = 0x10,
        CHLD = 0x11,
        CONT = 0x12,
        STOP = 0x13,
        TSTP = 0x14,
        TTIN = 0x15,
        TTOU = 0x16,
        URG = 0x17,
        XCPU = 0x18,
        XFSZ = 0x19,
        VTALRM = 0x1a,
        PROF = 0x1b,
        WINCH = 0x1c,
        IO = 0x1d,
        PWR = 0x1e,
        SYS = 0x1f,
    },
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const TIOC = packed struct(usize) {
    e0: enum(u15) {
        PKT_FLUSHREAD = 0x1,
        PKT_FLUSHWRITE = 0x2,
        PKT_STOP = 0x4,
        PKT_START = 0x8,
        PKT_NOSTOP = 0x10,
        PKT_DOSTOP = 0x20,
        PKT_IOCTL = 0x40,
        EXCL = 0x540c,
        NXCL = 0x540d,
        SCTTY = 0x540e,
        GPGRP = 0x540f,
        SPGRP = 0x5410,
        OUTQ = 0x5411,
        STI = 0x5412,
        GWINSZ = 0x5413,
        SWINSZ = 0x5414,
        MGET = 0x5415,
        MBIS = 0x5416,
        MBIC = 0x5417,
        MSET = 0x5418,
        GSOFTCAR = 0x5419,
        SSOFTCAR = 0x541a,
        INQ = 0x541b,
        LINUX = 0x541c,
        CONS = 0x541d,
        GSERIAL = 0x541e,
        SSERIAL = 0x541f,
        PKT = 0x5420,
        NOTTY = 0x5422,
        SETD = 0x5423,
        GETD = 0x5424,
        SBRK = 0x5427,
        CBRK = 0x5428,
        GSID = 0x5429,
        GRS485 = 0x542e,
        SRS485 = 0x542f,
        SERCONFIG = 0x5453,
        SERGWILD = 0x5454,
        SERSWILD = 0x5455,
        GLCKTRMIOS = 0x5456,
        SLCKTRMIOS = 0x5457,
        SERGSTRUCT = 0x5458,
        SERGETLSR = 0x5459,
        SERGETMULTI = 0x545a,
        SERSETMULTI = 0x545b,
        MIWAIT = 0x545c,
        GICOUNT = 0x545d,
    },
    zb15: u49 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const FIO = enum(usize) {
    NBIO = 0x5421,
    NCLEX = 0x5450,
    CLEX = 0x5451,
    ASYNC = 0x5452,
    QSIZE = 0x5460,
};
pub const UTIME = enum(usize) {
    OMIT = 0x3ffffffe,
    NOW = 0x3fffffff,
};
pub const Seek = packed struct(usize) {
    e0: enum(u2) {
        cur = 0x1,
        end = 0x2,
        data = 0x3,
    },
    hole: bool = false,
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        for ([_]struct { []const u8, u8 }{
            .{ "hole", 2 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const StatX = packed struct(usize) {
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "type", 0 },
            .{ "mode", 1 },
            .{ "nlink", 1 },
            .{ "uid", 1 },
            .{ "gid", 1 },
            .{ "atime", 1 },
            .{ "mtime", 1 },
            .{ "ctime", 1 },
            .{ "ino", 1 },
            .{ "size", 1 },
            .{ "blocks", 1 },
            .{ "btime", 1 },
            .{ "mount_id", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "compressed", 2 },
            .{ "immutable", 2 },
            .{ "append", 1 },
            .{ "nodump", 1 },
            .{ "encrypted", 5 },
            .{ "automount", 1 },
            .{ "mount_root", 1 },
            .{ "verity", 7 },
            .{ "dax", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const At = packed struct(usize) {
    zb0: u8 = 0,
    symlink_no_follow: bool = false,
    remove_dir: bool = false,
    symlink_follow: bool = false,
    no_automount: bool = false,
    empty_path: bool = false,
    zb13: u51 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "symlink_no_follow", 8 },
            .{ "remove_dir", 1 },
            .{ "symlink_follow", 1 },
            .{ "no_automount", 1 },
            .{ "empty_path", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const AtStatX = packed struct(usize) {
    zb0: u8 = 0,
    symlink_no_follow: bool = false,
    zb9: u2 = 0,
    no_automount: bool = false,
    empty_path: bool = false,
    FORCE_SYNC: bool = false,
    DONT_SYNC: bool = false,
    zb15: u49 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "symlink_no_follow", 8 },
            .{ "no_automount", 3 },
            .{ "empty_path", 1 },
            .{ "FORCE_SYNC", 1 },
            .{ "DONT_SYNC", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 16, 8 }, .{ 12, 3 },
            .{ 10, 1 }, .{ 10, 1 },
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
pub const AtAccess = packed struct(usize) {
    zb0: u8 = 0,
    symlink_no_follow: bool = false,
    effective_access: bool = false,
    zb10: u54 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "symlink_no_follow", 8 },
            .{ "effective_access", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 19, 8 },
            .{ 10, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const DN = packed struct(usize) {
    ACCESS: bool = false,
    MODIFY: bool = false,
    CREATE: bool = false,
    DELETE: bool = false,
    RENAME: bool = false,
    ATTRIB: bool = false,
    zb6: u25 = 0,
    MULTISHOT: bool = false,
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "ACCESS", 0 },
            .{ "MODIFY", 1 },
            .{ "CREATE", 1 },
            .{ "DELETE", 1 },
            .{ "RENAME", 1 },
            .{ "ATTRIB", 1 },
            .{ "MULTISHOT", 26 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 6, 0 },  .{ 6, 1 }, .{ 6, 1 },
            .{ 6, 1 },  .{ 6, 1 }, .{ 6, 1 },
            .{ 9, 26 },
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
    EXECFD = 0x2,
    PHDR = 0x3,
    PHENT = 0x4,
    PHNUM = 0x5,
    PAGESZ = 0x6,
    BASE = 0x7,
    FLAGS = 0x8,
    ENTRY = 0x9,
    EUID = 0xc,
    GID = 0xd,
    EGID = 0xe,
    PLATFORM = 0xf,
    HWCAP = 0x10,
    CLKTCK = 0x11,
    FPUCW = 0x12,
    DCACHEBSIZE = 0x13,
    ICACHEBSIZE = 0x14,
    UCACHEBSIZE = 0x15,
    SECURE = 0x17,
    BASE_PLATFORM = 0x18,
    RANDOM = 0x19,
    EXECFN = 0x1f,
    SYSINFO = 0x20,
    SYSINFO_EHDR = 0x21,
    L1I_CACHESIZE = 0x28,
    L1I_CACHEGEOMETRY = 0x29,
    L1D_CACHESIZE = 0x2a,
    L1D_CACHEGEOMETRY = 0x2b,
    L2_CACHESIZE = 0x2c,
    L2_CACHEGEOMETRY = 0x2d,
    L3_CACHESIZE = 0x2e,
    L3_CACHEGEOMETRY = 0x2f,
};
pub const FLOCK = packed struct(usize) {
    WRLCK: bool = false,
    UNLCK: bool = false,
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "WRLCK", 0 },
            .{ "UNLCK", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(format);
        for ([_]struct { u8, u8 }{
            .{ 5, 0 },
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
pub const F = enum(usize) {
    GETFD = 0x1,
    SETFD = 0x2,
    GETFL = 0x3,
    SETFL = 0x4,
    GETLK = 0x5,
    SETLK = 0x6,
    SETLKW = 0x7,
    SETOWN = 0x8,
    GETOWN = 0x9,
    DUPFD_CLOEXEC = 0x406,
};
pub const SI = packed struct(usize) {
    e0: enum(u32) {
        KERNEL = 0x80,
        TKILL = 0xfffffffa,
        SIGIO = 0xfffffffb,
        ASYNCIO = 0xfffffffc,
        MESGQ = 0xfffffffd,
        TIMER = 0xfffffffe,
        QUEUE = 0xffffffff,
    },
    zb32: u32 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const ReadWrite = packed struct(usize) {
    high_priority: bool = false,
    data_sync: bool = false,
    file_sync: bool = false,
    no_wait: bool = false,
    append: bool = false,
    zb5: u59 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "high_priority", 0 },
            .{ "data_sync", 1 },
            .{ "file_sync", 1 },
            .{ "no_wait", 1 },
            .{ "append", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
pub const RWH_WRITE_LIFE = packed struct(usize) {
    e0: enum(u3) {
        NONE = 0x1,
        SHORT = 0x2,
        MEDIUM = 0x3,
        LONG = 0x4,
        EXTREME = 0x5,
    },
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const POSIX_FADV = packed struct(usize) {
    e0: enum(u3) {
        RANDOM = 0x1,
        SEQUENTIAL = 0x2,
        WILLNEED = 0x3,
        DONTNEED = 0x4,
        NOREUSE = 0x5,
    },
    zb3: u61 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        len += fmt.strcpy(buf + len, @tagName(format.e0));
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(format.e0).len;
        return len;
    }
};
pub const ITIMER = packed struct(usize) {
    VIRTUAL: bool = false,
    PROF: bool = false,
    zb2: u62 = 0,
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "VIRTUAL", 0 },
            .{ "PROF", 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
    MAPERR = 0x1,
    ACCERR = 0x2,
    BNDERR = 0x3,
    PKUERR = 0x4,
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
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(format);
        if (tmp == 0) return 0;
        buf[0..6].* = "flags=".*;
        var len: usize = 6;
        for ([_]struct { []const u8, u8 }{
            .{ "SECRM_FL", 0 },
            .{ "UNRM_FL", 1 },
            .{ "COMPR_FL", 1 },
            .{ "SYNC_FL", 1 },
            .{ "IMMUTABLE_FL", 1 },
            .{ "APPEND_FL", 1 },
            .{ "NODUMP_FL", 1 },
            .{ "NOATIME_FL", 1 },
            .{ "JOURNAL_DATA_FL", 7 },
            .{ "NOTAIL_FL", 1 },
            .{ "DIRSYNC_FL", 1 },
            .{ "TOPDIR_FL", 1 },
            .{ "NOCOW_FL", 6 },
            .{ "PROJINHERIT_FL", 6 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != 0) {
                buf[len] = ',';
                len += @intFromBool(len != 6);
                len += fmt.strcpy(buf + len, pair[0]);
            }
        }
        return len;
    }
    pub fn formatLength(format: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(format)) == 0) return 0;
        var len: usize = 6;
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
