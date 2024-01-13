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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.visibility));
        for ([_]struct { []const u8, u8, bool }{
            .{ "fixed", 4, false },
            .{ "anonymous", 1, true },
            .{ "grows_down", 3, false },
            .{ "deny_write", 3, false },
            .{ "executable", 1, false },
            .{ "locked", 1, false },
            .{ "no_reserve", 1, false },
            .{ "populate", 1, false },
            .{ "non_block", 1, false },
            .{ "stack", 1, false },
            .{ "hugetlb", 1, false },
            .{ "sync", 1, false },
            .{ "fixed_noreplace", 1, true },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.visibility).len;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 5, 4, false },  .{ 9, 1, true },  .{ 9, 3, false }, .{ 9, 3, false },
            .{ 10, 1, false }, .{ 6, 1, false }, .{ 9, 1, false }, .{ 8, 1, false },
            .{ 8, 1, false },  .{ 5, 1, false }, .{ 7, 1, false }, .{ 4, 1, false },
            .{ 15, 1, true },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.visibility));
        for ([_]struct { []const u8, u8, bool }{
            .{ "fixed", 4, true },
            .{ "anonymous", 1, false },
            .{ "grows_down", 3, false },
            .{ "deny_write", 3, false },
            .{ "executable", 1, false },
            .{ "locked", 1, false },
            .{ "no_reserve", 1, false },
            .{ "populate", 1, false },
            .{ "non_block", 1, false },
            .{ "stack", 1, false },
            .{ "hugetlb", 1, false },
            .{ "sync", 1, false },
            .{ "fixed_noreplace", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.visibility).len;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 5, 4, true },   .{ 9, 1, false }, .{ 9, 3, false }, .{ 9, 3, false },
            .{ 10, 1, false }, .{ 6, 1, false }, .{ 9, 1, false }, .{ 8, 1, false },
            .{ 8, 1, false },  .{ 5, 1, false }, .{ 7, 1, false }, .{ 4, 1, false },
            .{ 15, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "close_on_exec", 0, false },
            .{ "allow_sealing", 1, false },
            .{ "hugetlb", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 0, false }, .{ 13, 1, false },
            .{ 7, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "async", 0, false },
            .{ "invalidate", 1, false },
            .{ "sync", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 5, 0, false }, .{ 10, 1, false },
            .{ 4, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "read", 0, true },
            .{ "write", 1, true },
            .{ "exec", 1, false },
            .{ "grows_down", 22, false },
            .{ "grows_up", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 4, 0, true },  .{ 5, 1, true },
            .{ 4, 1, false }, .{ 9, 22, false },
            .{ 7, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "read", 0, true },
            .{ "write", 1, true },
            .{ "exec", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 4, 0, true },  .{ 5, 1, true },
            .{ 4, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "may_move", 0, false },
            .{ "fixed", 1, false },
            .{ "no_unmap", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 0, false }, .{ 5, 1, false },
            .{ 9, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
        return len;
    }
};
pub const MCL = packed struct(usize) {
    current: bool = false,
    future: bool = false,
    on_fault: bool = false,
    zb3: u61 = 0,
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "current", 0, false },
            .{ "future", 1, false },
            .{ "on_fault", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 0, false }, .{ 6, 1, false },
            .{ 7, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "write_only", 0, false },
            .{ "read_write", 1, false },
            .{ "create", 5, false },
            .{ "exclusive", 1, false },
            .{ "no_ctty", 1, false },
            .{ "truncate", 1, false },
            .{ "append", 1, false },
            .{ "non_block", 1, false },
            .{ "data_sync", 1, false },
            .{ "async", 1, false },
            .{ "direct", 1, false },
            .{ "directory", 2, false },
            .{ "no_follow", 1, false },
            .{ "no_atime", 1, false },
            .{ "close_on_exec", 1, false },
            .{ "path", 2, false },
            .{ "tmpfile", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 6, 0, false }, .{ 4, 1, false }, .{ 5, 5, false }, .{ 4, 1, false },
            .{ 6, 1, false }, .{ 5, 1, false }, .{ 6, 1, false }, .{ 8, 1, false },
            .{ 5, 1, false }, .{ 5, 1, false }, .{ 6, 1, false }, .{ 9, 2, false },
            .{ 8, 1, false }, .{ 7, 1, false }, .{ 7, 1, false }, .{ 4, 2, false },
            .{ 7, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "write_only", 0, false },
            .{ "read_write", 1, true },
            .{ "create", 5, true },
            .{ "exclusive", 1, false },
            .{ "no_ctty", 1, false },
            .{ "truncate", 1, true },
            .{ "append", 1, false },
            .{ "non_block", 1, false },
            .{ "data_sync", 1, false },
            .{ "async", 1, false },
            .{ "direct", 1, false },
            .{ "no_follow", 3, false },
            .{ "no_atime", 1, false },
            .{ "close_on_exec", 1, false },
            .{ "path", 2, false },
            .{ "tmpfile", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 6, 0, false }, .{ 4, 1, true },  .{ 5, 5, true },  .{ 4, 1, false },
            .{ 6, 1, false }, .{ 5, 1, true },  .{ 6, 1, false }, .{ 8, 1, false },
            .{ 5, 1, false }, .{ 5, 1, false }, .{ 6, 1, false }, .{ 8, 3, false },
            .{ 7, 1, false }, .{ 7, 1, false }, .{ 4, 2, false }, .{ 7, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "SH", 0, false },
            .{ "EX", 1, false },
            .{ "NB", 1, false },
            .{ "UN", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 2, 0, false }, .{ 2, 1, false }, .{ 2, 1, false },
            .{ 2, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "new_time", 7, false },
            .{ "vm", 1, true },
            .{ "fs", 1, true },
            .{ "files", 1, true },
            .{ "signal_handlers", 1, true },
            .{ "pid_fd", 1, false },
            .{ "trace_child", 1, false },
            .{ "vfork", 1, false },
            .{ "thread", 2, true },
            .{ "new_namespace", 1, false },
            .{ "sysvsem", 1, true },
            .{ "set_thread_local_storage", 1, false },
            .{ "set_parent_thread_id", 1, true },
            .{ "clear_child_thread_id", 1, true },
            .{ "detached", 1, false },
            .{ "untraced", 1, false },
            .{ "set_child_thread_id", 1, true },
            .{ "new_cgroup", 1, false },
            .{ "new_uts", 1, false },
            .{ "new_ipc", 1, false },
            .{ "new_user", 1, false },
            .{ "new_pid", 1, false },
            .{ "new_net", 1, false },
            .{ "io", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 7, false }, .{ 2, 1, true },  .{ 2, 1, true },  .{ 5, 1, true },
            .{ 7, 1, true },  .{ 5, 1, false }, .{ 6, 1, false }, .{ 5, 1, false },
            .{ 6, 2, true },  .{ 5, 1, false }, .{ 7, 1, true },  .{ 6, 1, false },
            .{ 13, 1, true }, .{ 14, 1, true }, .{ 8, 1, false }, .{ 8, 1, false },
            .{ 12, 1, true }, .{ 9, 1, false }, .{ 6, 1, false }, .{ 6, 1, false },
            .{ 7, 1, false }, .{ 6, 1, false }, .{ 6, 1, false }, .{ 2, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "no_hang", 0, false },
            .{ "stopped", 1, false },
            .{ "exited", 1, false },
            .{ "continued", 1, false },
            .{ "no_wait", 21, false },
            .{ "no_thread", 5, false },
            .{ "all", 1, false },
            .{ "clone", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 6, 0, false }, .{ 7, 1, false },  .{ 6, 1, false },
            .{ 9, 1, false }, .{ 6, 21, false }, .{ 8, 5, false },
            .{ 3, 1, false }, .{ 5, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "write", 0, false },
            .{ "read_write", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 2, 0, false },
            .{ 4, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "read_only", 0, false },
            .{ "no_suid", 1, false },
            .{ "no_dev", 1, false },
            .{ "no_exec", 1, false },
            .{ "no_atime", 1, false },
            .{ "strict_atime", 1, false },
            .{ "no_dir_atime", 2, false },
            .{ "id_map", 13, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 6, 0, false },  .{ 6, 1, false },  .{ 5, 1, false },
            .{ 6, 1, false },  .{ 7, 1, false },  .{ 11, 1, false },
            .{ 10, 2, false }, .{ 5, 13, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "UNIX", 0, false },
            .{ "INET", 1, false },
            .{ "INET6", 0, false },
            .{ "NETLINK", 3, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 4, 0, false }, .{ 4, 1, false }, .{ 5, 0, false },
            .{ 7, 3, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        for ([_]struct { []const u8, u8, bool }{
            .{ "NONBLOCK", 11, false },
            .{ "CLOEXEC", 8, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 8, 11, false },
            .{ 7, 8, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "no_child_stop", 0, false },
            .{ "no_child_wait", 1, false },
            .{ "siginfo", 1, true },
            .{ "unsupported", 8, false },
            .{ "expose_tagbits", 1, false },
            .{ "restorer", 15, true },
            .{ "on_stack", 1, false },
            .{ "restart", 1, true },
            .{ "no_defer", 2, false },
            .{ "reset_handler", 1, true },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 9, 0, false },  .{ 9, 1, false }, .{ 7, 1, true },  .{ 11, 8, false },
            .{ 14, 1, false }, .{ 8, 15, true }, .{ 7, 1, false }, .{ 7, 1, true },
            .{ 7, 2, false },  .{ 9, 1, true },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: u32 = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "on_stack", 0, false },
            .{ "disable", 1, false },
            .{ "auto_disarm", 30, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(u32, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: u32 = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 0, false },   .{ 7, 1, false },
            .{ 10, 30, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        for ([_]struct { []const u8, u8, bool }{
            .{ "hole", 2, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 4, 2, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "type", 0, false },
            .{ "mode", 1, false },
            .{ "nlink", 1, false },
            .{ "uid", 1, false },
            .{ "gid", 1, false },
            .{ "atime", 1, false },
            .{ "mtime", 1, false },
            .{ "ctime", 1, false },
            .{ "ino", 1, false },
            .{ "size", 1, false },
            .{ "blocks", 1, false },
            .{ "btime", 1, false },
            .{ "mount_id", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 4, 0, false }, .{ 4, 1, false }, .{ 5, 1, false }, .{ 3, 1, false },
            .{ 3, 1, false }, .{ 5, 1, false }, .{ 5, 1, false }, .{ 5, 1, false },
            .{ 3, 1, false }, .{ 4, 1, false }, .{ 6, 1, false }, .{ 5, 1, false },
            .{ 6, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "compressed", 2, false },
            .{ "immutable", 2, false },
            .{ "append", 1, false },
            .{ "nodump", 1, false },
            .{ "encrypted", 5, false },
            .{ "automount", 1, false },
            .{ "mount_root", 1, false },
            .{ "verity", 7, false },
            .{ "dax", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 10, 2, false }, .{ 9, 2, false }, .{ 6, 1, false },  .{ 6, 1, false },
            .{ 9, 5, false },  .{ 9, 1, false }, .{ 10, 1, false }, .{ 6, 7, false },
            .{ 3, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "symlink_no_follow", 8, false },
            .{ "remove_dir", 1, false },
            .{ "symlink_follow", 1, false },
            .{ "no_automount", 1, false },
            .{ "empty_path", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 16, 8, false }, .{ 9, 1, false },  .{ 14, 1, false },
            .{ 12, 1, false }, .{ 10, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "symlink_no_follow", 8, false },
            .{ "no_automount", 3, false },
            .{ "empty_path", 1, false },
            .{ "FORCE_SYNC", 1, false },
            .{ "DONT_SYNC", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 16, 8, false }, .{ 12, 3, false },
            .{ 10, 1, false }, .{ 10, 1, false },
            .{ 9, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "symlink_no_follow", 8, false },
            .{ "effective_access", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 19, 8, false },
            .{ 10, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "ACCESS", 0, false },
            .{ "MODIFY", 1, false },
            .{ "CREATE", 1, false },
            .{ "DELETE", 1, false },
            .{ "RENAME", 1, false },
            .{ "ATTRIB", 1, false },
            .{ "MULTISHOT", 26, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 6, 0, false },  .{ 6, 1, false }, .{ 6, 1, false },
            .{ 6, 1, false },  .{ 6, 1, false }, .{ 6, 1, false },
            .{ 9, 26, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "WRLCK", 0, false },
            .{ "UNLCK", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 5, 0, false },
            .{ 5, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "high_priority", 0, false },
            .{ "data_sync", 1, false },
            .{ "file_sync", 1, false },
            .{ "no_wait", 1, false },
            .{ "append", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 5, 0, false }, .{ 5, 1, false }, .{ 4, 1, false },
            .{ 6, 1, false }, .{ 6, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        ptr = fmt.strcpyEqu(ptr, @tagName(flags.e0));
        _ = &tmp;
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        len +%= @tagName(flags.e0).len;
        return len;
    }
};
pub const ITIMER = packed struct(usize) {
    VIRTUAL: bool = false,
    PROF: bool = false,
    zb2: u62 = 0,
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "VIRTUAL", 0, false },
            .{ "PROF", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 7, 0, false },
            .{ 4, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
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
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "SECRM_FL", 0, false },
            .{ "UNRM_FL", 1, false },
            .{ "COMPR_FL", 1, false },
            .{ "SYNC_FL", 1, false },
            .{ "IMMUTABLE_FL", 1, false },
            .{ "APPEND_FL", 1, false },
            .{ "NODUMP_FL", 1, false },
            .{ "NOATIME_FL", 1, false },
            .{ "JOURNAL_DATA_FL", 7, false },
            .{ "NOTAIL_FL", 1, false },
            .{ "DIRSYNC_FL", 1, false },
            .{ "TOPDIR_FL", 1, false },
            .{ "NOCOW_FL", 6, false },
            .{ "PROJINHERIT_FL", 6, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 8, 0, false },  .{ 7, 1, false },  .{ 8, 1, false },  .{ 7, 1, false },
            .{ 12, 1, false }, .{ 9, 1, false },  .{ 9, 1, false },  .{ 10, 1, false },
            .{ 15, 7, false }, .{ 9, 1, false },  .{ 10, 1, false }, .{ 9, 1, false },
            .{ 8, 6, false },  .{ 14, 6, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Rename2 = packed struct(usize) {
    NOREPLACE: bool = false,
    EXCHANGE: bool = false,
    WHITEOUT: bool = false,
    zb3: u61 = 0,
    pub fn write(buf: [*]u8, flags: @This()) [*]u8 {
        @setRuntimeSafety(false);
        var tmp: usize = @bitCast(flags);
        if (tmp == 0) return buf;
        buf[0..6].* = "flags=".*;
        var ptr: [*]u8 = buf[6..];
        for ([_]struct { []const u8, u8, bool }{
            .{ "NOREPLACE", 0, false },
            .{ "EXCHANGE", 1, false },
            .{ "WHITEOUT", 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), pair[0]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8 }{
            .{ 9, 0, false }, .{ 8, 1, false },
            .{ 8, 1, false },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 != @intFromBool(if (builtin.show_default_flags) true else pair[2])) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
