const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const build = @import("./build2.zig");
const spec = @This();
const serial = @import("./serial.zig");
const builtin = @import("./builtin.zig");

pub fn add(args1: anytype, args2: anytype) @TypeOf(args1) {
    var ret: @TypeOf(args1) = args1;
    inline for (@typeInfo(@TypeOf(args2)).Struct.fields) |field| {
        @field(ret, field.name) = @field(args2, field.name);
    }
    return ret;
}
pub const address_space = opaque {
    pub const regular_128 = mem.GenericRegularAddressSpace(.{
        .lb_addr = 0,
        .lb_offset = 0x40000000,
        .divisions = 128,
    });
    pub const exact_8 = mem.GenericDiscreteAddressSpace(.{
        .list = meta.slice(mem.Arena, .{
            .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
            .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
            .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
            .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
            .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
            .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
            .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
            .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
        }),
    });
    pub const logging = opaque {
        pub const verbose: mem.AddressSpaceLogging = .{
            .acquire = spec.logging.acquire_error_fault.verbose,
            .release = spec.logging.release_error_fault.verbose,
            .map = spec.logging.acquire_error_fault.verbose,
            .unmap = spec.logging.release_error_fault.verbose,
        };
        pub const silent: mem.AddressSpaceLogging = builtin.zero(mem.AddressSpaceLogging);
    };
    pub const errors = opaque {
        pub const noexcept: mem.AddressSpaceErrors = .{
            .release = .ignore,
            .acquire = .ignore,
            .map = .{},
            .unmap = .{},
        };
        pub const zen: mem.AddressSpaceErrors = .{
            .acquire = .{ .throw = error.UnderSupply },
            .release = .abort,
            .map = .{ .throw = sys.mmap_errors },
            .unmap = .{ .abort = sys.munmap_errors },
        };
    };
};
pub const reinterpret = opaque {
    pub const flat: mem.ReinterpretSpec = .{};
    pub const ptr: mem.ReinterpretSpec = .{
        .reference = .{ .dereference = &.{} },
    };
    pub const fmt: mem.ReinterpretSpec = reinterpretRecursively(.{
        .reference = ptr.reference,
        .aggregate = .{ .iterate = true },
        .composite = .{ .format = true },
        .symbol = .{ .tag_name = true },
    });
    pub const print: mem.ReinterpretSpec = reinterpretRecursively(.{
        .reference = ptr.reference,
        .aggregate = .{ .iterate = true },
        .composite = .{ .format = true },
        .symbol = .{ .tag_name = true },
        .integral = .{ .format = .dec },
    });
    pub const follow: mem.ReinterpretSpec = blk: {
        var rs_0: mem.ReinterpretSpec = .{};
        var rs_1: mem.ReinterpretSpec = .{ .reference = .{
            .dereference = &rs_0,
        } };
        rs_1.reference.dereference = &rs_0;
        rs_0 = .{ .reference = .{
            .dereference = &rs_1,
        } };
        break :blk rs_1;
    };
    fn reinterpretRecursively(comptime reinterpret_spec: mem.ReinterpretSpec) mem.ReinterpretSpec {
        var rs_0: mem.ReinterpretSpec = reinterpret_spec;
        var rs_1: mem.ReinterpretSpec = reinterpret_spec;
        rs_0.reference.dereference = &rs_1;
        rs_1.reference.dereference = &rs_0;
        return rs_1;
    }
};
pub const builder = opaque {
    pub const default: build.BuilderSpec = .{
        .errors = builder.errors.noexcept,
        .logging = builder.logging.silent,
    };
    pub const errors = opaque {
        pub const noexcept: build.BuilderSpec.Errors = .{
            .fork = .{},
            .write = .{},
            .mknod = .{},
            .dup3 = .{},
            .execve = .{},
            .waitpid = .{},
            .path = .{},
            .map = .{},
            .unmap = .{},
            .clock = .{},
            .sleep = .{},
            .create = .{},
            .mkdir = .{},
            .close = .{},
            .stat = .{},
        };
        pub const zen: build.BuilderSpec.Errors = .{
            .fork = .{ .throw = sys.fork_errors },
            .execve = .{ .throw = sys.execve_errors },
            .waitpid = .{ .throw = sys.wait_errors },
            .path = .{ .throw = sys.open_errors },
            .map = .{ .throw = sys.mmap_errors },
            .stat = .{ .throw = sys.stat_errors },
            .unmap = .{ .throw = sys.munmap_errors },
            .clock = .{ .throw = sys.clock_get_errors },
            .sleep = .{ .throw = sys.nanosleep_errors },
            .create = .{ .throw = sys.open_errors },
            .mkdir = .{ .throw = sys.mkdir_noexcl_errors },
            .close = .{ .abort = sys.close_errors },
        };
        pub const critical: build.BuilderSpec.Errors = add(zen, .{
            .close = .{ .throw = sys.close_errors },
            .unmap = .{ .throw = sys.munmap_errors },
        });
    };
    pub const logging = opaque {
        pub const verbose: build.BuilderSpec.Logging = .{
            .fork = spec.logging.success_error_fault.verbose,
            .execve = spec.logging.success_error_fault.verbose,
            .waitpid = spec.logging.success_error_fault.verbose,
            .path = spec.logging.acquire_error_fault.verbose,
            .stat = spec.logging.success_error_fault.verbose,
            .create = spec.logging.acquire_error_fault.verbose,
            .close = spec.logging.release_error_fault.verbose,
            .mkdir = spec.logging.success_error_fault.verbose,
        };
        pub const silent: build.BuilderSpec.Logging = builtin.zero(build.BuilderSpec.Logging);
    };
};
pub const logging = opaque {
    pub const default = opaque {
        pub const verbose: builtin.Logging.Default = .{
            .Success = true,
            .Acquire = true,
            .Release = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.Default = .{
            .Success = false,
            .Acquire = false,
            .Release = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const override = opaque {
        pub const verbose: builtin.Logging.Override = .{
            .Attempt = true,
            .Success = true,
            .Acquire = true,
            .Release = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.Override = .{
            .Attempt = false,
            .Success = false,
            .Acquire = false,
            .Release = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const success_error = opaque {
        pub const verbose: builtin.Logging.SuccessError = .{
            .Success = true,
            .Error = true,
        };
        pub const silent: builtin.Logging.SuccessError = .{
            .Success = false,
            .Error = false,
        };
    };
    pub const success_fault = opaque {
        pub const verbose: builtin.Logging.SuccessFault = .{
            .Success = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.SuccessFault = .{
            .Success = false,
            .Fault = false,
        };
    };
    pub const attempt_error = opaque {
        pub const verbose: builtin.Logging.AttemptError = .{
            .Attempt = true,
            .Error = true,
        };
        pub const silent: builtin.Logging.AttemptError = .{
            .Attempt = false,
            .Error = false,
        };
    };
    pub const attempt_fault = opaque {
        pub const verbose: builtin.Logging.AttemptFault = .{
            .Attempt = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.AttemptFault = .{
            .Attempt = false,
            .Fault = false,
        };
    };
    pub const acquire_error = opaque {
        pub const verbose: builtin.Logging.AcquireError = .{
            .Acquire = true,
            .Error = true,
        };
        pub const silent: builtin.Logging.AcquireError = .{
            .Acquire = false,
            .Error = false,
        };
    };
    pub const acquire_fault = opaque {
        pub const verbose: builtin.Loggin.AcquireFaultg = .{
            .Acquire = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.AcquireFault = .{
            .Acquire = false,
            .Fault = false,
        };
    };
    pub const release_error = opaque {
        pub const verbose: builtin.Logging.ReleaseError = .{
            .Release = true,
            .Error = true,
        };
        pub const silent: builtin.Logging.ReleaseError = .{
            .Release = false,
            .Error = false,
        };
    };
    pub const release_fault = opaque {
        pub const verbose: builtin.Logging.ReleaseFault = .{
            .Release = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.ReleaseFault = .{
            .Release = false,
            .Fault = false,
        };
    };
    pub const attempt_error_fault = opaque {
        pub const verbose: builtin.Logging.AttemptErrorFault = .{
            .Attempt = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.AttemptErrorFault = .{
            .Attempt = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const success_error_fault = opaque {
        pub const verbose: builtin.Logging.SuccessErrorFault = .{
            .Success = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.SuccessErrorFault = .{
            .Success = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const acquire_error_fault = opaque {
        pub const verbose: builtin.Logging.AcquireErrorFault = .{
            .Acquire = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.AcquireErrorFault = .{
            .Acquire = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const release_error_fault = opaque {
        pub const verbose: builtin.Logging.ReleaseErrorFault = .{
            .Release = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: builtin.Logging.ReleaseErrorFault = .{
            .Release = false,
            .Error = false,
            .Fault = false,
        };
    };
};
pub const dir = opaque {
    pub const options = opaque {
        pub const eager: file.DirStreamOptions = .{
            .init_read_all = true,
            .shrink_after_read = true,
            .make_list = true,
            .close_on_deinit = true,
        };
        pub const lazy: file.DirStreamOptions = .{
            .init_read_all = false,
            .shrink_after_read = false,
            .make_list = false,
            .close_on_deinit = false,
        };
    };
    pub const logging = opaque {
        pub const silent: file.DirStreamLogging = .{
            .open = spec.logging.acquire_error.silent,
            .close = spec.logging.release_error.silent,
            .getdents = spec.logging.success_error.silent,
        };
        pub const verbose: file.DirStreamLogging = .{
            .open = spec.logging.acquire_error.verbose,
            .close = spec.logging.release_error.verbose,
            .getdents = spec.logging.success_error.verbose,
        };
    };
    pub const errors = opaque {
        pub const zen: file.DirStreamErrors = .{
            .open = .{ .throw = open.errors.all },
            .close = .{ .abort = open.errors.all },
            .getdents = .{ .throw = getdents.errors.all },
        };
        pub const noexcept: file.DirStreamErrors = .{
            .open = .{},
            .close = .{},
            .getdents = .{},
        };
    };
};
pub const allocator = opaque {
    pub const options = opaque {
        pub const small: mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
        };
        // TODO: Describe conditions where this is better.
        pub const fast: mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
        };
        pub const debug: mem.ArenaAllocatorOptions = .{
            .count_branches = true,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = true,
            .trace_state = true,
            .trace_clients = true,
        };
        pub const small_composed: mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
            .require_map = false,
            .require_unmap = false,
        };
        pub const fast_composed: mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
            .require_map = false,
            .require_unmap = false,
        };
        pub const debug_composed: mem.ArenaAllocatorOptions = .{
            .count_branches = true,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = true,
            .trace_state = true,
            .trace_clients = true,
            .require_map = false,
            .require_unmap = false,
        };
    };
    pub const logging = opaque {
        pub const verbose: mem.AllocatorLogging = .{
            .head = true,
            .sentinel = true,
            .metadata = true,
            .branches = true,
            .map = spec.logging.acquire_error.verbose,
            .unmap = spec.logging.release_error.verbose,
            .remap = spec.logging.success_error.verbose,
            .advise = spec.logging.success_error.verbose,
            .allocate = true,
            .reallocate = true,
            .reinterpret = true,
            .deallocate = true,
        };
        pub const silent: mem.AllocatorLogging = .{
            .head = false,
            .sentinel = false,
            .metadata = false,
            .branches = false,
            .map = spec.logging.acquire_error.silent,
            .unmap = spec.logging.release_error.silent,
            .remap = spec.logging.success_error.silent,
            .advise = spec.logging.success_error.silent,
            .allocate = false,
            .reallocate = false,
            .reinterpret = false,
            .deallocate = false,
        };
    };
    pub const errors = opaque {
        pub const zen: mem.AllocatorErrors = .{
            .map = .{ .throw = mmap.errors.mem },
            .remap = .{ .throw = mremap.errors.all },
            .unmap = .{ .abort = munmap.errors.all },
        };
        pub const noexcept: mem.AllocatorErrors = .{
            .map = .{},
            .remap = .{},
            .unmap = .{},
        };
        pub const critical: mem.AllocatorErrors = .{
            .map = .{ .throw = mmap.errors.mem },
            .remap = .{ .throw = mremap.errors.all },
            .unmap = .{ .throw = munmap.errors.all },
        };
    };
};
pub const serializer = opaque {
    pub const errors = opaque {
        pub const noexcept: serial.SerialSpec.Errors = .{
            .create = .{},
            .open = .{},
            .close = .{},
            .stat = .{},
            .read = .{},
            .write = .{},
        };
        pub const critical: serial.SerialSpec.Errors = .{
            .create = open.errors.all,
            .open = open.errors.all,
            .close = close.errors.all,
            .stat = stat.errors.all,
            .read = read.errors.all,
            .write = write.errors.all,
        };
    };
    pub const logging = opaque {
        pub const verbose: serial.SerialSpec.Logging = .{
            .create = spec.logging.acquire_error.verbose,
            .open = spec.logging.acquire_error.verbose,
            .close = spec.logging.release_error.verbose,
            .read = spec.logging.success_error.verbose,
            .write = spec.logging.success_error.verbose,
            .stat = spec.logging.success_error_fault.verbose,
        };
        pub const silent: serial.SerialSpec.Logging = .{
            .create = spec.logging.acquire_error.silent,
            .open = spec.logging.acquire_error.silent,
            .close = spec.logging.release_error.silent,
            .read = spec.logging.success_error.silent,
            .write = spec.logging.success_error.silent,
            .stat = spec.logging.success_error_fault.silent,
        };
    };
};
pub const mmap = opaque {
    pub const function = opaque {
        pub const default: sys.Config = .{
            .tag = .mmap,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .mmap,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const options = opaque {
        pub const object: spec.file.MapSpec.Options = .{
            .visibility = .private,
            .anonymous = false,
            .read = true,
            .write = false,
            .exec = true,
            .populate = true,
            .grows_down = false,
            .sync = false,
        };
        pub const file: spec.file.MapSpec.Options = .{
            .anonymous = false,
            .visibility = .shared,
            .read = true,
            .write = true,
            .exec = false,
            .populate = false,
            .grows_down = false,
            .sync = false,
        };
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .AGAIN, .BADF,     .EXIST, .INVAL,  .NFILE,
            .NODEV, .NOMEM, .OVERFLOW, .PERM,  .TXTBSY,
        });
        pub const mem: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .EXIST, .INVAL, .NOMEM,
        });
        pub const file: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .EXIST, .INVAL, .NOMEM, .NFILE, .NODEV, .TXTBSY,
        });
    };
};
pub const mremap = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .mremap,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .mremap,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .FAULT, .INVAL, .NOMEM,
        });
    };
};
pub const munmap = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .munmap,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .munmap,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{.INVAL});
    };
};
pub const brk = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .brk,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .brk,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{.NOMEM});
    };
};
pub const chdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .chdir,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .chdir,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
        });
    };
};
pub const close = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .close,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .close,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .INTR, .IO, .BADF, .NOSPC,
        });
    };
};
pub const clone3 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .clone3,
            .errors = .{ .throw = errors.all },
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .PERM,      .AGAIN, .INVAL,   .EXIST, .USERS,
            .OPNOTSUPP, .NOMEM, .RESTART, .BUSY,  .NOSPC,
        });
    };
};
pub const open = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .open,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        const dir: sys.Config = .{
            .tag = .openat,
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

        const dir_default = config.dir_default.function();
        const dir_noexcept = config.dir_noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
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
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = .{
            .tag = .read,
            .errors = .{},
            .return_type = void,
        };
        pub const noexcept_nodiscard: sys.Config = .{
            .tag = .read,
            .errors = .{},
            .return_type = isize,
        };
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
        });
    };
};
pub const clock_gettime = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{ .tag = .clock_gettime, .errors = .{ .throw = errors.all }, .return_type = void };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
        });
    };
};
pub const execve = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .execve,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const dir_default: sys.Config = .{
            .tag = .execveat,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
            .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
            .INVAL, .NOEXEC,
        });
    };
};
pub const fork = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .fork,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NOSYS, .AGAIN, .NOMEM, .RESTART,
        });
    };
};
pub const getcwd = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .getcwd,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
        });
    };
};
pub const getdents = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .getdents64,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
        });
    };
};
pub const getrandom = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .getrandom,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
        });
    };
};
pub const dup = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .dup,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};
pub const dup2 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .dup2,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};
pub const dup3 = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .dup3,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, isize);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .BADF, .BUSY, .INTR, .INVAL, .MFILE,
        });
    };
};

pub const ioctl = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .ioctl,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .NOTTY, .BADF, .FAULT, .INVAL,
        });
    };
};
pub const madvise = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .madvise,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
        });
    };
};
pub const mkdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .mkdir,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .mkdirat,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
            .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
        });
    };
};
pub const memfd_create = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .memfd_create,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .FAULT, .INVAL, .MFILE, .NOMEM,
        });
    };
};
pub const truncate = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .truncate,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const file_default: sys.Config = .{
            .tag = .ftruncate,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,  .FAULT, .FBIG, .INTR,   .IO,    .ISDIR, .LOOP, .NAMETOOLONG,
            .NOTDIR, .PERM,  .ROFS, .TXTBSY, .INVAL, .BADF,
        });
    };
};
pub const mknod = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .mknod,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .mknodat,
            .errors = .{ .throw = errors.all },
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP,
            .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
        });
    };
};
pub const open_by_handle_at = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .open_by_handle_at,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = open.errors.all ++ meta.slice(sys.ErrorCode, .{.STALE});
    };
};
pub const name_to_handle_at = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .name_to_handle_at,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = open.errors.all ++ meta.slice(sys.ErrorCode, .{.STALE});
    };
};
pub const nanosleep = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .nanosleep,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .INTR, .FAULT, .INVAL, .OPNOTSUPP,
        });
    };
};
pub const readlink = opaque {
    pub const function = opaque {
        pub const default: sys.Config = .{
            .tag = .readlink,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
        pub const dir_default: sys.Config = .{
            .tag = .readlinkat,
            .errors = .{ .throw = errors.all },
            .return_type = usize,
        };
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,       .BADF,  .FAULT, .INVAL,  .IO, .LOOP,
            .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR,
        });
    };
};
pub const rmdir = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .rmdir,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        // pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .BUSY,  .FAULT,  .INVAL,    .LOOP, .NAMETOOLONG,
            .NOENT, .NOMEM, .NOTDIR, .NOTEMPTY, .PERM, .ROFS,
        });
    };
};
pub const sigaction = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .rt_sigaction,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const noexcept: sys.Config = default.reconfigure(null, void);
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .FAULT, .INVAL,
        });
    };
};
pub const stat = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .stat,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const file_default: sys.Config = .{
            .tag = .fstat,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .newfstatat,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const link_default: sys.Config = .{
            .tag = .lstat,
            .errors = .{ .throw = errors.all },
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES,       .BADF,  .FAULT, .INVAL,  .LOOP,
            .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR, .OVERFLOW,
        });
    };
};
pub const unlink = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .unlink,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const dir_default: sys.Config = .{
            .tag = .unlinkat,
            .errors = .{ .throw = errors.all },
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .ACCES, .BUSY,  .FAULT,  .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
            .NOENT, .NOMEM, .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
        });
    };
};
pub const write = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .write,
            .errors = .{ .throw = errors.all },
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
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .BADF,  .DESTADDRREQ, .DQUOT, .FAULT, .FBIG,
            .INTR,  .INVAL, .IO,          .NOSPC, .PERM,  .PIPE,
        });
    };
};
pub const getid = opaque {
    pub const config = opaque {
        pub const user: sys.Config = .{
            .tag = .getuid,
            .errors = .{},
            .return_type = u16,
        };
        pub const group: sys.Config = .{
            .tag = .getgid,
            .errors = .{},
            .return_type = u16,
        };
        pub const effective_user: sys.Config = .{
            .tag = .geteuid,
            .errors = .{},
            .return_type = u16,
        };
        pub const effective_group: sys.Config = .{
            .tag = .getegid,
            .errors = .{},
            .return_type = u16,
        };
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
        pub const default: sys.Config = .{
            .tag = .wait4,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .wait4,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .SRCH, .INTR, .AGAIN, .INVAL, .CHILD,
        });
    };
};
pub const waitid = opaque {
    pub const config = opaque {
        pub const default: sys.Config = .{
            .tag = .waitid,
            .errors = .{ .throw = errors.all },
            .return_type = void,
        };
        pub const noexcept: sys.Config = .{
            .tag = .waitid,
            .errors = .{},
            .return_type = void,
        };
    };
    pub const function = opaque {
        pub const default = config.default.function();
        pub const noexcept = config.noexcept.function();
    };
    pub const errors = opaque {
        pub const all: []const sys.ErrorCode = meta.slice(sys.ErrorCode, .{
            .AGAIN, .CHILD, .INTR, .INVAL, .SRCH,
        });
    };
};
pub const exit = opaque {
    pub const config = struct {
        pub const default: sys.Config = .{
            .tag = .exit,
            .errors = .{},
            .return_type = noreturn,
        };
    };
};
