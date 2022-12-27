const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
pub const allocator = opaque {
    pub const options = opaque {
        pub const small: mem.AllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric_binding = false,
        };
    };
    pub const logging = opaque {
        pub const verbose: mem.AllocatorLogging = .{
            .arena = builtin.Logging.verbose,
            .head = true,
            .sentinel = true,
            .metadata = true,
            .branches = true,
            .map = builtin.Logging.verbose,
            .unmap = builtin.Logging.verbose,
            .remap = builtin.Logging.verbose,
            .advise = builtin.Logging.verbose,
            .allocate = true,
            .reallocate = true,
            .reinterpret = true,
            .deallocate = true,
        };
        pub const silent: mem.AllocatorLogging = .{
            .arena = builtin.Logging.silent,
            .head = false,
            .sentinel = false,
            .metadata = false,
            .branches = false,
            .map = builtin.Logging.silent,
            .unmap = builtin.Logging.silent,
            .remap = builtin.Logging.silent,
            .advise = builtin.Logging.silent,
            .allocate = false,
            .reallocate = false,
            .reinterpret = false,
            .deallocate = false,
        };
    };
    pub const errors = opaque {
        pub const noexcept: mem.AllocatorErrors = .{
            // This should not be allowed, but no consistency within library to
            // enforce yet.
            .acquire = null,
            .release = null,
            .map = null,
            .remap = null,
            .unmap = null,
        };
        pub const uniform: mem.AllocatorErrors = .{
            .acquire = error{OpaqueSystemError},
            .release = null,
            .map = &.{},
            .remap = &.{},
            .unmap = null,
        };
        pub const critical: mem.AllocatorErrors = .{
            .map = mmap.errors.mem,
            .remap = mremap.errors.all,
            .release = error{OverSupply},
            .acquire = error{UnderSupply},
            .unmap = munmap.errors.all,
        };
    };
};
pub const mmap = opaque {
    pub const function = opaque {
        pub const default: sys.Config = .{
            .tag = .mmap,
            .args = 6,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .mmap,
            .args = 6,
            .errors = null,
            .return_type = void,
        };
    };
    pub const options = opaque {
        pub const object: file.MapSpec.Options = .{
            .visibility = .private,
            .anonymous = false,
            .read = true,
            .write = false,
            .exec = true,
            .populate = true,
            .grows_down = false,
            .sync = false,
        };
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,    .AGAIN,
            .BADF,     .EXIST,
            .INVAL,    .NFILE,
            .NODEV,    .NOMEM,
            .OVERFLOW, .PERM,
            .TXTBSY,
        });
        pub const mem: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .EXIST,
            .INVAL,
            .NOMEM,
        });
        pub const file: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .EXIST,
            .INVAL,
            .NOMEM,
            .NFILE,
            .NODEV,
            .TXTBSY,
        });
    };
};
pub const mremap = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .mremap,
            .args = 5,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .mremap,
            .args = 5,
            .errors = null,
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{ .AGAIN, .FAULT, .INVAL, .NOMEM });
    };
};
pub const munmap = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .munmap,
            .args = 2,
            .errors = errors.all,
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .munmap,
            .args = 2,
            .errors = null,
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{.INVAL});
    };
};
pub const brk = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .brk,
            .args = 1,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .brk,
            .args = 1,
            .errors = null,
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{.NOMEM});
    };
};
pub const chdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .chdir,
            .args = 1,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .chdir,
            .args = 1,
            .errors = null,
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
        });
    };
};
pub const close = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .close,
            .args = 1,
            .errors = errors.all,
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .close,
            .args = 1,
            .errors = null,
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{ .INTR, .IO, .BADF, .NOSPC });
    };
};
pub const clone3 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .clone3,
            .args = 2,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
        pub const discard_noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .PERM, .AGAIN, .INVAL, .EXIST, .USERS, .OPNOTSUPP, .NOMEM, .RESTART,
            .BUSY, .NOSPC,
        });
    };
};
pub const open = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .open,
            .args = 3,
            .errors = errors.all,
            .return_type = usize,
        };
        const dir: sys.Config = .{
            .tag = .openat,
            .args = 3,
            .errors = open.errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
        pub const discard_noexcept: sys.Config = default.reconfigure(null, void);

        pub const dir_noexcept: sys.Config = default.reconfigure(null, isize);
        pub const dir_discard_noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        const default = config.default.function();
        const noexcept = config.noexcept.function();
        const discard_noexcept = config.noexcept.function();

        const dir_default = config.dir_default.function();
        const dir_noexcept = config.dir_noexcept.function();
        const dir_discard_noexcept = config.dir_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .FBIG,        .NOTDIR,   .EXIST,  .OPNOTSUPP, .MFILE, .NOSPC,
            .NOENT, .NAMETOOLONG, .OVERFLOW, .TXTBSY, .AGAIN,     .BADF,  .ISDIR,
            .LOOP,  .NODEV,       .DQUOT,    .NOMEM,  .ROFS,      .NFILE, .INTR,
            .PERM,  .FAULT,       .INVAL,    .NXIO,   .BUSY,
        });
    };
};
pub const read = opaque {
    pub const function = opaque {
        pub const default: sys.Config = .{
            .tag = .read,
            .args = 3,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .read,
            .args = 3,
            .errors = null,
            .return_type = void,
        };
        pub const noexcept_nodiscard: sys.Config = .{
            .tag = .read,
            .args = 3,
            .errors = null,
            .return_type = isize,
        };
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
        });
    };
};
pub const clock_get = opaque {
    pub const config = opaque {};
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
        });
    };
};
pub const execve = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .execve,
            .args = 3,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const dir_default: sys.Config = .{
            .tag = .execveat,
            .args = 5,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();

        pub const dir_default = config.dir_default.function();
        pub const dir_noexcept = config.dir_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
            .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
            .INVAL, .NOEXEC,
        });
    };
};
pub const fork = opaque {
    pub const config = opaque {};
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NOSYS, .AGAIN, .NOMEM, .RESTART,
        });
    };
};
pub const getcwd = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .getcwd, .args = 1, .errors = errors.all, .return_type = usize };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
        });
    };
};
pub const getdents = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .getdents64, .args = 3, .errors = errors.all, .return_type = usize };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
        });
    };
};
pub const getrandom = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .getrandom, .args = 3, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
        });
    };
};
pub const dup = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .dup, .args = 1, .errors = errors.all, .return_type = usize };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};
pub const dup2 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .dup2, .args = 2, .errors = errors.all, .return_type = usize };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};
pub const dup3 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .dup3, .args = 3, .errors = errors.all, .return_type = usize };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};

pub const ioctl = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .ioctl, .args = 3, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NOTTY, .BADF, .FAULT, .INVAL,
        });
    };
};
pub const madvise = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .madvise, .args = 3, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
        });
    };
};
pub const mkdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .mkdir, .args = 2, .errors = errors.all, .return_type = void };
        pub const dir_default: sys.Config = .{ .tag = .mkdirat, .args = 3, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
            .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
        });
    };
};
pub const memfd_create = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .memfd_create,
            .args = 2,
            .errors = errors.all,
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{ .FAULT, .INVAL, .MFILE, .NOMEM });
    };
};
pub const truncate = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .truncate, .args = 2, .errors = errors.all, .return_type = void };
        pub const file_default: sys.Config = .{ .tag = .ftruncate, .args = 2, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .FAULT, .FBIG, .INTR,   .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
            .NOTDIR, .PERM,  .ROFS, .TXTBSY, .BADF, .INVAL, .BADF,
        });
    };
};
pub const mknod = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .mknod,
            .args = 3,
            .errors = errors.all,
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .mknodat,
            .args = 4,
            .errors = errors.all,
            .return_type = void,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
        pub const dir_noexcept: sys.Config = dir_default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
        pub const dir_default = config.dir_default.function();
        pub const dir_noexcept = config.dir_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .INVAL, .LOOP, .NAMETOOLONG,
            .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
        });
    };
};
pub const open_by_handle_at = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .open_by_handle_at, .args = 3, .errors = errors.all, .return_type = usize };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = open.all ++ meta.slice(sys.ErrorCode, .{
            .BADF, .FAULT, .INVAL, .LOOP, .PERM, .STALE,
        });
    };
};
pub const name_to_handle_at = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .name_to_handle_at, .args = 5, .errors = errors.all, .return_type = usize };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = open.all ++ meta.slice(sys.ErrorCode, .{
            .OVERFLOW, .LOOP, .PERM, .BADF, .FAULT, .INVAL, .NOTDIR, .STALE,
        });
    };
};
pub const nanosleep = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .nanosleep, .args = 2, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .INTR, .FAULT, .INVAL, .OPNOTSUPP,
        });
    };
};
pub const readlink = opaque {
    pub const function = opaque {
        pub const default: sys.Config = .{
            .tag = .readlink,
            .args = 3,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const dir_default: sys.Config = .{
            .tag = .readlinkat,
            .args = 4,
            .errors = errors.all,
            .return_type = usize,
        };
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .BADF, .FAULT, .INVAL, .IO, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
            .NOTDIR,
        });
    };
};
pub const rmdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .rmdir, .args = 1, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .BUSY,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
            .NOTDIR, .NOTEMPTY, .PERM,  .ROFS,
        });
    };
};
pub const sigaction = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .rt_sigaction, .args = 4, .errors = errors.all, .return_type = void };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .FAULT, .INVAL,
        });
    };
};
pub const stat = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .stat,
            .args = 2,
            .errors = errors.all,
            .return_type = void,
        };
        pub const file_default: sys.Config = .{
            .tag = .fstat,
            .args = 2,
            .errors = errors.all,
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .newfstatat,
            .args = 4,
            .errors = errors.all,
            .return_type = void,
        };
        pub const link_default: sys.Config = .{
            .tag = .lstat,
            .args = 2,
            .errors = errors.all,
            .return_type = void,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
        pub const file_noexcept: sys.Config = file_default.reconfigure(null, void);
        pub const dir_noexcept: sys.Config = dir_default.reconfigure(null, void);
        pub const link_noexcept: sys.Config = link_default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
        pub const file_default = config.file_default.function();
        pub const file_noexcept = config.file_noexcept.function();
        pub const dir_default = config.dir_default.function();
        pub const dir_noexcept = config.dir_noexcept.function();
        pub const link_default = config.link_default.function();
        pub const link_noexcept = config.link_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .BADF,     .FAULT, .INVAL, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
            .NOTDIR, .OVERFLOW,
        });
    };
};
pub const unlink = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .unlink,
            .args = 1,
            .errors = errors.all,
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .unlinkat,
            .args = 3,
            .errors = errors.all,
            .return_type = void,
        };
        pub const noexcept = default.reconfigure(null, void);
        pub const dir_noexcept = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .BUSY, .FAULT, .IO,   .ISDIR, .LOOP, .NAMETOOLONG, .NOENT, .NOMEM,
            .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
        });
    };
};
pub const write = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .write,
            .args = 3,
            .errors = errors.all,
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
        pub const discard_noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
        pub const discard_noexcept = config.discard_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .BADF, .DESTADDRREQ, .DQUOT, .FAULT, .FBIG, .INTR, .INVAL, .IO,
            .NOSPC, .PERM, .PIPE,
        });
    };
};
pub const getid = opaque {
    pub const config = opaque {
        pub const user: sys.Config = .{ .tag = .getuid, .args = 0, .errors = null, .return_type = u16 };
        pub const group: sys.Config = .{ .tag = .getgid, .args = 0, .errors = null, .return_type = u16 };
        pub const effective_user: sys.Config = .{ .tag = .geteuid, .args = 0, .errors = null, .return_type = u16 };
        pub const effective_group: sys.Config = .{ .tag = .getegid, .args = 0, .errors = null, .return_type = u16 };
    };
    pub const function = opaque {
        pub const user = config.user.function();
        pub const group = config.group.function();
        pub const effective_user = config.effective_user.function();
        pub const effective_group = config.effective_group.function();
    };
};
pub const wait = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .wait4, .args = 5, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .SRCH, .INTR, .AGAIN, .INVAL, .CHILD,
        });
    };
};
pub const waitid = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .waitid, .args = 5, .errors = errors.all, .return_type = void };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .CHILD, .INTR, .INVAL, .SRCH,
        });
    };
};
pub const no = opaque {
    pub const config = opaque {};
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []sys.ErrorCode = meta.slice(sys.ErrorCode, .{});
    };
};
