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
        for ([_][]const u8{
            "fixed\x04\x01",
            "anonymous\x01\x00",
            "grows_down\x03\x01",
            "deny_write\x03\x01",
            "executable\x01\x01",
            "locked\x01\x01",
            "no_reserve\x01\x01",
            "populate\x01\x01",
            "non_block\x01\x01",
            "stack\x01\x01",
            "hugetlb\x01\x01",
            "sync\x01\x01",
            "fixed_noreplace\x01\x00",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
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
        for ([_]struct { u8, u8, u8 }{
            .{ 5, 4, 1 },  .{ 9, 1, 0 }, .{ 10, 3, 1 }, .{ 10, 3, 1 },
            .{ 10, 1, 1 }, .{ 6, 1, 1 }, .{ 10, 1, 1 }, .{ 8, 1, 1 },
            .{ 9, 1, 1 },  .{ 5, 1, 1 }, .{ 7, 1, 1 },  .{ 4, 1, 1 },
            .{ 15, 1, 0 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "fixed\x04\x00",
            "anonymous\x01\x01",
            "grows_down\x03\x01",
            "deny_write\x03\x01",
            "executable\x01\x01",
            "locked\x01\x01",
            "no_reserve\x01\x01",
            "populate\x01\x01",
            "non_block\x01\x01",
            "stack\x01\x01",
            "hugetlb\x01\x01",
            "sync\x01\x01",
            "fixed_noreplace\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
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
        for ([_]struct { u8, u8, u8 }{
            .{ 5, 4, 0 },  .{ 9, 1, 1 }, .{ 10, 3, 1 }, .{ 10, 3, 1 },
            .{ 10, 1, 1 }, .{ 6, 1, 1 }, .{ 10, 1, 1 }, .{ 8, 1, 1 },
            .{ 9, 1, 1 },  .{ 5, 1, 1 }, .{ 7, 1, 1 },  .{ 4, 1, 1 },
            .{ 15, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "close_on_exec\x00\x01",
            "allow_sealing\x01\x01",
            "hugetlb\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 13, 0, 1 }, .{ 13, 1, 1 },
            .{ 7, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "async\x00\x01",
            "invalidate\x01\x01",
            "sync\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 5, 0, 1 }, .{ 10, 1, 1 },
            .{ 4, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "read\x00\x00",
            "write\x01\x00",
            "exec\x01\x01",
            "grows_down\x16\x01",
            "grows_up\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 4, 0, 0 }, .{ 5, 1, 0 },
            .{ 4, 1, 1 }, .{ 10, 22, 1 },
            .{ 8, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "read\x00\x00",
            "write\x01\x00",
            "exec\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 4, 0, 0 }, .{ 5, 1, 0 },
            .{ 4, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "may_move\x00\x01",
            "fixed\x01\x01",
            "no_unmap\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 8, 0, 1 }, .{ 5, 1, 1 },
            .{ 8, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const MAdvise = enum(usize) {
    normal = 0x0,
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
        for ([_][]const u8{
            "current\x00\x01",
            "future\x01\x01",
            "on_fault\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 7, 0, 1 }, .{ 6, 1, 1 },
            .{ 8, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "write_only\x00\x01",
            "read_write\x01\x01",
            "create\x05\x01",
            "exclusive\x01\x01",
            "no_ctty\x01\x01",
            "truncate\x01\x01",
            "append\x01\x01",
            "non_block\x01\x01",
            "data_sync\x01\x01",
            "async\x01\x01",
            "direct\x01\x01",
            "directory\x02\x01",
            "no_follow\x01\x01",
            "no_atime\x01\x01",
            "close_on_exec\x01\x01",
            "path\x02\x01",
            "tmpfile\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 10, 0, 1 }, .{ 10, 1, 1 }, .{ 6, 5, 1 },  .{ 9, 1, 1 },
            .{ 7, 1, 1 },  .{ 8, 1, 1 },  .{ 6, 1, 1 },  .{ 9, 1, 1 },
            .{ 9, 1, 1 },  .{ 5, 1, 1 },  .{ 6, 1, 1 },  .{ 9, 2, 1 },
            .{ 9, 1, 1 },  .{ 8, 1, 1 },  .{ 13, 1, 1 }, .{ 4, 2, 1 },
            .{ 7, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "write_only\x00\x01",
            "read_write\x01\x00",
            "create\x05\x00",
            "exclusive\x01\x01",
            "no_ctty\x01\x01",
            "truncate\x01\x00",
            "append\x01\x01",
            "non_block\x01\x01",
            "data_sync\x01\x01",
            "async\x01\x01",
            "direct\x01\x01",
            "no_follow\x03\x01",
            "no_atime\x01\x01",
            "close_on_exec\x01\x01",
            "path\x02\x01",
            "tmpfile\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 10, 0, 1 }, .{ 10, 1, 0 }, .{ 6, 5, 0 }, .{ 9, 1, 1 },
            .{ 7, 1, 1 },  .{ 8, 1, 0 },  .{ 6, 1, 1 }, .{ 9, 1, 1 },
            .{ 9, 1, 1 },  .{ 5, 1, 1 },  .{ 6, 1, 1 }, .{ 9, 3, 1 },
            .{ 8, 1, 1 },  .{ 13, 1, 1 }, .{ 4, 2, 1 }, .{ 7, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "SH\x00\x01",
            "EX\x01\x01",
            "NB\x01\x01",
            "UN\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 2, 0, 1 }, .{ 2, 1, 1 }, .{ 2, 1, 1 },
            .{ 2, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "new_time\x07\x01",
            "vm\x01\x00",
            "fs\x01\x00",
            "files\x01\x00",
            "signal_handlers\x01\x00",
            "pid_fd\x01\x01",
            "trace_child\x01\x01",
            "vfork\x01\x01",
            "thread\x02\x00",
            "new_namespace\x01\x01",
            "sysvsem\x01\x00",
            "set_thread_local_storage\x01\x01",
            "set_parent_thread_id\x01\x00",
            "clear_child_thread_id\x01\x00",
            "detached\x01\x01",
            "untraced\x01\x01",
            "set_child_thread_id\x01\x00",
            "new_cgroup\x01\x01",
            "new_uts\x01\x01",
            "new_ipc\x01\x01",
            "new_user\x01\x01",
            "new_pid\x01\x01",
            "new_net\x01\x01",
            "io\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 8, 7, 1 },  .{ 2, 1, 0 },  .{ 2, 1, 0 },  .{ 5, 1, 0 },
            .{ 15, 1, 0 }, .{ 6, 1, 1 },  .{ 11, 1, 1 }, .{ 5, 1, 1 },
            .{ 6, 2, 0 },  .{ 13, 1, 1 }, .{ 7, 1, 0 },  .{ 24, 1, 1 },
            .{ 20, 1, 0 }, .{ 21, 1, 0 }, .{ 8, 1, 1 },  .{ 8, 1, 1 },
            .{ 19, 1, 0 }, .{ 10, 1, 1 }, .{ 7, 1, 1 },  .{ 7, 1, 1 },
            .{ 8, 1, 1 },  .{ 7, 1, 1 },  .{ 7, 1, 1 },  .{ 2, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Id = enum(usize) {
    all = 0x0,
    pid = 0x1,
    pgid = 0x2,
    pidfd = 0x3,
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
        for ([_][]const u8{
            "no_hang\x00\x01",
            "stopped\x01\x01",
            "exited\x01\x01",
            "continued\x01\x01",
            "no_wait\x15\x01",
            "no_thread\x05\x01",
            "all\x01\x01",
            "clone\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 7, 0, 1 }, .{ 7, 1, 1 },  .{ 6, 1, 1 },
            .{ 9, 1, 1 }, .{ 7, 21, 1 }, .{ 9, 5, 1 },
            .{ 3, 1, 1 }, .{ 5, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "write\x00\x01",
            "read_write\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 5, 0, 1 },
            .{ 10, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "read_only\x00\x01",
            "no_suid\x01\x01",
            "no_dev\x01\x01",
            "no_exec\x01\x01",
            "no_atime\x01\x01",
            "strict_atime\x01\x01",
            "no_dir_atime\x02\x01",
            "id_map\r\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 9, 0, 1 },  .{ 7, 1, 1 },  .{ 6, 1, 1 },
            .{ 7, 1, 1 },  .{ 8, 1, 1 },  .{ 12, 1, 1 },
            .{ 12, 2, 1 }, .{ 6, 13, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "UNIX\x00\x01",
            "INET\x01\x01",
            "INET6\x00\x01",
            "NETLINK\x03\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 4, 0, 1 }, .{ 4, 1, 1 }, .{ 5, 0, 1 },
            .{ 7, 3, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Socket = packed struct(usize) {
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
        for ([_][]const u8{
            "NONBLOCK\x0b\x01",
            "CLOEXEC\x08\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
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
        for ([_]struct { u8, u8, u8 }{
            .{ 8, 11, 1 },
            .{ 7, 8, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Protocol = enum(usize) {
    IP = 0x0,
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
};
pub const Port = enum(usize) {
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
        for ([_][]const u8{
            "no_child_stop\x00\x01",
            "no_child_wait\x01\x01",
            "siginfo\x01\x00",
            "unsupported\x08\x01",
            "expose_tagbits\x01\x01",
            "restorer\x0f\x00",
            "on_stack\x01\x01",
            "restart\x01\x00",
            "no_defer\x02\x01",
            "reset_handler\x01\x00",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 13, 0, 1 }, .{ 13, 1, 1 }, .{ 7, 1, 0 }, .{ 11, 8, 1 },
            .{ 14, 1, 1 }, .{ 8, 15, 0 }, .{ 8, 1, 1 }, .{ 7, 1, 0 },
            .{ 8, 2, 1 },  .{ 13, 1, 0 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "on_stack\x00\x01",
            "disable\x01\x01",
            "auto_disarm\x1e\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(u32, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: u32 = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 8, 0, 1 },   .{ 7, 1, 1 },
            .{ 11, 30, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const Signal = enum(usize) {
    DFL = 0x0,
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
};
pub const TerminalIOCtl = enum(usize) {
    PKT_DATA = 0x0,
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
        for ([_][]const u8{
            "hole\x02\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
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
        for ([_]struct { u8, u8, u8 }{
            .{ 4, 2, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "type\x00\x01",
            "mode\x01\x01",
            "nlink\x01\x01",
            "uid\x01\x01",
            "gid\x01\x01",
            "atime\x01\x01",
            "mtime\x01\x01",
            "ctime\x01\x01",
            "ino\x01\x01",
            "size\x01\x01",
            "blocks\x01\x01",
            "btime\x01\x01",
            "mount_id\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 4, 0, 1 }, .{ 4, 1, 1 }, .{ 5, 1, 1 }, .{ 3, 1, 1 },
            .{ 3, 1, 1 }, .{ 5, 1, 1 }, .{ 5, 1, 1 }, .{ 5, 1, 1 },
            .{ 3, 1, 1 }, .{ 4, 1, 1 }, .{ 6, 1, 1 }, .{ 5, 1, 1 },
            .{ 8, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const StatXAttributes = packed struct(usize) {
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
        for ([_][]const u8{
            "compressed\x02\x01",
            "immutable\x02\x01",
            "append\x01\x01",
            "nodump\x01\x01",
            "encrypted\x05\x01",
            "automount\x01\x01",
            "mount_root\x01\x01",
            "verity\x07\x01",
            "dax\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 10, 2, 1 }, .{ 9, 2, 1 }, .{ 6, 1, 1 },  .{ 6, 1, 1 },
            .{ 9, 5, 1 },  .{ 9, 1, 1 }, .{ 10, 1, 1 }, .{ 6, 7, 1 },
            .{ 3, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "symlink_no_follow\x08\x01",
            "remove_dir\x01\x01",
            "symlink_follow\x01\x01",
            "no_automount\x01\x01",
            "empty_path\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 17, 8, 1 }, .{ 10, 1, 1 }, .{ 14, 1, 1 },
            .{ 12, 1, 1 }, .{ 10, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "symlink_no_follow\x08\x01",
            "no_automount\x03\x01",
            "empty_path\x01\x01",
            "FORCE_SYNC\x01\x01",
            "DONT_SYNC\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 17, 8, 1 }, .{ 12, 3, 1 },
            .{ 10, 1, 1 }, .{ 10, 1, 1 },
            .{ 9, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "symlink_no_follow\x08\x01",
            "effective_access\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 17, 8, 1 },
            .{ 16, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "ACCESS\x00\x01",
            "MODIFY\x01\x01",
            "CREATE\x01\x01",
            "DELETE\x01\x01",
            "RENAME\x01\x01",
            "ATTRIB\x01\x01",
            "MULTISHOT\x1a\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 6, 0, 1 },  .{ 6, 1, 1 }, .{ 6, 1, 1 },
            .{ 6, 1, 1 },  .{ 6, 1, 1 }, .{ 6, 1, 1 },
            .{ 9, 26, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const AuxiliaryVectorEntry = enum(usize) {
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
        for ([_][]const u8{
            "WRLCK\x00\x01",
            "UNLCK\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 5, 0, 1 },
            .{ 5, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
pub const SI = enum(usize) {
    USER = 0x0,
    KERNEL = 0x80,
    TKILL = 0xfffffffa,
    SIGIO = 0xfffffffb,
    ASYNCIO = 0xfffffffc,
    MESGQ = 0xfffffffd,
    TIMER = 0xfffffffe,
    QUEUE = 0xffffffff,
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
        for ([_][]const u8{
            "high_priority\x00\x01",
            "data_sync\x01\x01",
            "file_sync\x01\x01",
            "no_wait\x01\x01",
            "append\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 13, 0, 1 }, .{ 9, 1, 1 }, .{ 9, 1, 1 },
            .{ 7, 1, 1 },  .{ 6, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
pub const RWH_WRITE_LIFE = enum(usize) {
    not_set = 0x0,
    none = 0x1,
    short = 0x2,
    medium = 0x3,
    long = 0x4,
    extreme = 0x5,
};
pub const POSIX_FADV = enum(usize) {
    NORMAL = 0x0,
    RANDOM = 0x1,
    SEQUENTIAL = 0x2,
    WILLNEED = 0x3,
    DONTNEED = 0x4,
    NOREUSE = 0x5,
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
        for ([_][]const u8{
            "VIRTUAL\x00\x01",
            "PROF\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 7, 0, 1 },
            .{ 4, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "SECRM_FL\x00\x01",
            "UNRM_FL\x01\x01",
            "COMPR_FL\x01\x01",
            "SYNC_FL\x01\x01",
            "IMMUTABLE_FL\x01\x01",
            "APPEND_FL\x01\x01",
            "NODUMP_FL\x01\x01",
            "NOATIME_FL\x01\x01",
            "JOURNAL_DATA_FL\x07\x01",
            "NOTAIL_FL\x01\x01",
            "DIRSYNC_FL\x01\x01",
            "TOPDIR_FL\x01\x01",
            "NOCOW_FL\x06\x01",
            "PROJINHERIT_FL\x06\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 8, 0, 1 },  .{ 7, 1, 1 },  .{ 8, 1, 1 },  .{ 7, 1, 1 },
            .{ 12, 1, 1 }, .{ 9, 1, 1 },  .{ 9, 1, 1 },  .{ 10, 1, 1 },
            .{ 15, 7, 1 }, .{ 9, 1, 1 },  .{ 10, 1, 1 }, .{ 9, 1, 1 },
            .{ 8, 6, 1 },  .{ 14, 6, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
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
        for ([_][]const u8{
            "NOREPLACE\x00\x01",
            "EXCHANGE\x01\x01",
            "WHITEOUT\x01\x01",
        }) |field| {
            tmp >>= @truncate(field[field.len -% 2]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else field[field.len -% 1]) {
                ptr[0] = ',';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf + 6), field[0 .. field.len -% 2]);
            }
        }
        return ptr;
    }
    pub fn length(flags: @This()) usize {
        @setRuntimeSafety(false);
        if (@as(usize, @bitCast(flags)) == 0) return 0;
        var len: usize = 6;
        var tmp: usize = @bitCast(flags);
        for ([_]struct { u8, u8, u8 }{
            .{ 9, 0, 1 }, .{ 8, 1, 1 },
            .{ 8, 1, 1 },
        }) |pair| {
            tmp >>= @truncate(pair[1]);
            if (tmp & 1 == if (builtin.show_default_flags) 1 else pair[2]) {
                len +%= @intFromBool(len != 0) +% pair[0];
            }
        }
        return len;
    }
};
