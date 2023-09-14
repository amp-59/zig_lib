const zl = @import("./std.zig");
const spec = @This();
pub usingnamespace sys;
pub fn add(args1: anytype, args2: anytype) @TypeOf(args1) {
    var ret: @TypeOf(args1) = args1;
    inline for (@typeInfo(@TypeOf(args2)).Struct.fields) |field| {
        @field(ret, field.name) = @field(args2, field.name);
    }
    return ret;
}
pub const address_space = struct {
    pub const regular_128 = zl.mem.GenericRegularAddressSpace(.{
        .lb_addr = 0,
        .lb_offset = 0x40000000,
        .divisions = 128,
    });
    pub const exact_8 = zl.mem.GenericDiscreteAddressSpace(.{
        .list = &[_]zl.mem.Arena{
            .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
            .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
            .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
            .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
            .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
            .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
            .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
            .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
        },
    });
    pub const logging = struct {
        pub const verbose: zl.mem.AddressSpaceLogging = .{
            .acquire = spec.logging.acquire_error_fault.verbose,
            .release = spec.logging.release_error_fault.verbose,
            .map = spec.logging.acquire_error.verbose,
            .unmap = spec.logging.release_error.verbose,
        };
        pub const silent: zl.mem.AddressSpaceLogging = zl.builtin.zero(zl.mem.AddressSpaceLogging);
    };
    pub const errors = struct {
        pub const noexcept: zl.mem.AddressSpaceErrors = .{
            .release = .ignore,
            .acquire = .ignore,
            .map = .{},
            .unmap = .{},
        };
        pub const zen: zl.mem.AddressSpaceErrors = .{
            .acquire = .{ .throw = error.UnderSupply },
            .release = .abort,
            .map = .{ .throw = sys.mmap.errors.all },
            .unmap = .{ .abort = sys.munmap.errors.all },
        };
    };
};
pub const reinterpret = struct {
    pub const flat: zl.mem.ReinterpretSpec = .{};
    pub const ptr: zl.mem.ReinterpretSpec = .{
        .reference = .{ .dereference = &.{} },
    };
    pub const fmt: zl.mem.ReinterpretSpec = reinterpretRecursively(.{
        .reference = ptr.reference,
        .aggregate = .{ .iterate = true },
        .composite = .{ .format = true },
        .symbol = .{ .tag_name = true },
    });
    pub const print: zl.mem.ReinterpretSpec = reinterpretRecursively(.{
        .reference = ptr.reference,
        .aggregate = .{ .iterate = true },
        .composite = .{ .format = true },
        .symbol = .{ .tag_name = true },
    });
    pub const follow: zl.mem.ReinterpretSpec = blk: {
        var rs_0: zl.mem.ReinterpretSpec = .{};
        var rs_1: zl.mem.ReinterpretSpec = .{ .reference = .{
            .dereference = &rs_0,
        } };
        rs_1.reference.dereference = &rs_0;
        rs_0 = .{ .reference = .{
            .dereference = &rs_1,
        } };
        break :blk rs_1;
    };
    fn reinterpretRecursively(comptime reinterpret_spec: zl.mem.ReinterpretSpec) zl.mem.ReinterpretSpec {
        var rs_0: zl.mem.ReinterpretSpec = reinterpret_spec;
        var rs_1: zl.mem.ReinterpretSpec = reinterpret_spec;
        rs_0.reference.dereference = &rs_1;
        rs_1.reference.dereference = &rs_0;
        return rs_1;
    }
};
pub const channel = struct {
    pub const errors = struct {
        pub const zen: zl.file.ChannelSpec.Errors = .{
            .pipe = .{ .throw = sys.pipe.errors.all },
            .dup3 = .{ .throw = sys.dup.errors.all },
            .close = .{ .abort = sys.close.errors.all },
        };
        pub const noexcept: zl.file.ChannelSpec.Errors = .{
            .pipe = .{},
            .dup3 = .{},
            .close = .{},
        };
    };
    pub const logging = struct {
        pub const verbose: zl.file.ChannelSpec.Logging = .{
            .dup3 = spec.logging.success_error.verbose,
            .pipe = spec.logging.acquire_error.verbose,
            .close = spec.logging.release_error.verbose,
        };
        pub const silent: zl.file.ChannelSpec.Logging = .{
            .dup3 = spec.logging.success_error.silent,
            .pipe = spec.logging.acquire_error.silent,
            .close = spec.logging.release_error.silent,
        };
    };
};
pub const builder = struct {
    pub const default = .{
        .errors = builder.errors.noexcept,
        .logging = builder.logging.default,
    };
    pub const errors = struct {
        pub const noexcept: zl.build.BuilderSpec.Errors = .{
            .fork = .{},
            .write = .{},
            .read = .{},
            .mknod = .{},
            .dup3 = .{},
            .pipe = .{},
            .execve = .{},
            .waitpid = .{},
            .path = .{},
            .map = .{},
            .unmap = .{},
            .clock = .{},
            .sleep = .{},
            .create = .{},
            .mkdir = .{},
            .open = .{},
            .close = .{},
            .poll = .{},
            .stat = .{},
            .unlink = .{},
            .link = .{},
            .seek = .{},
            .perf_event_open = .{},
        };
        pub const kill: zl.build.BuilderSpec.Errors = .{
            .write = .{ .abort = sys.write.errors.all },
            .read = .{ .abort = sys.read.errors.all },
            .mknod = .{ .abort = sys.mknod.errors.all },
            .dup3 = .{ .abort = sys.dup.errors.all },
            .pipe = .{ .abort = sys.pipe.errors.all },
            .fork = .{ .abort = sys.fork.errors.all },
            .execve = .{ .abort = sys.execve.errors.all },
            .waitpid = .{ .abort = sys.wait.errors.all },
            .path = .{ .abort = sys.open.errors.all },
            .map = .{ .abort = sys.mmap.errors.all },
            .stat = .{ .abort = sys.stat.errors.all_noent },
            .unmap = .{ .abort = sys.munmap.errors.all },
            .clock = .{ .abort = sys.clock_gettime.errors.all },
            .sleep = .{ .abort = sys.nanosleep.errors.all },
            .create = .{ .abort = sys.open.errors.all },
            .mkdir = .{ .abort = sys.mkdir.errors.noexcl },
            .poll = .{ .abort = sys.poll.errors.all },
            .open = .{ .abort = sys.open.errors.all },
            .close = .{ .abort = sys.close.errors.all },
            .unlink = .{ .abort = sys.unlink.errors.all_noent },
            .link = .{ .abort = sys.link.errors.all },
            .seek = .{ .abort = sys.seek.errors.all },
            .perf_event_open = .{ .abort = sys.perf_event_open.errors.all },
        };
        pub const zen: zl.build.BuilderSpec.Errors = .{
            .write = .{ .abort = sys.write.errors.all },
            .read = .{ .abort = sys.read.errors.all },
            .mknod = .{ .throw = sys.mknod.errors.all },
            .dup3 = .{ .throw = sys.dup.errors.all },
            .pipe = .{ .throw = sys.pipe.errors.all },
            .fork = .{ .throw = sys.fork.errors.all },
            .execve = .{ .throw = sys.execve.errors.all },
            .waitpid = .{ .throw = sys.wait.errors.all },
            .path = .{ .throw = sys.open.errors.all },
            .map = .{ .throw = sys.mmap.errors.all },
            .stat = .{ .throw = sys.stat.errors.all },
            .unmap = .{ .throw = sys.munmap.errors.all },
            .clock = .{ .throw = sys.clock_gettime.errors.all },
            .sleep = .{ .throw = sys.nanosleep.errors.all },
            .create = .{ .throw = sys.open.errors.all },
            .mkdir = .{ .throw = sys.mkdir.errors.noexcl },
            .poll = .{ .throw = sys.poll.errors.all },
            .open = .{ .throw = sys.open.errors.all },
            .seek = .{ .throw = sys.seek.errors.all },
            .close = .{ .abort = sys.close.errors.all },
            .unlink = .{ .abort = sys.unlink.errors.all },
        };
        pub const critical: zl.build.BuilderSpec.Errors = add(zen, .{
            .close = .{ .throw = sys.close.errors.all },
            .unmap = .{ .throw = sys.munmap.errors.all },
        });
    };
    pub const logging = struct {
        pub const transcript = blk: {
            var tmp = builder.logging.default;
            tmp.show_task_creation = false;
            tmp.show_task_init = false;
            tmp.show_task_update = false;
            tmp.show_user_input = false;
            tmp.show_task_prep = false;
            tmp.show_arena_index = true;
            tmp.show_base_memory_usage = true;
            tmp.show_program_size = true;
            tmp.show_waiting_tasks = true;
            tmp.hide_special = true;
            break :blk silent;
        };
        pub const default: zl.build.BuilderSpec.Logging = .{
            .write = .{},
            .read = .{},
            .mknod = .{},
            .dup3 = .{},
            .pipe = .{},
            .fork = .{},
            .execve = .{},
            .waitpid = .{},
            .path = .{},
            .map = .{},
            .stat = .{},
            .unmap = .{},
            .create = .{},
            .mkdir = .{},
            .poll = .{},
            .open = .{},
            .close = .{},
            .unlink = .{},
        };
        pub const verbose: zl.build.BuilderSpec.Logging = zl.builtin.all(zl.build.BuilderSpec.Logging);
        pub const silent: zl.build.BuilderSpec.Logging = zl.builtin.zero(zl.build.BuilderSpec.Logging);
    };
};
pub const logging = struct {
    pub const default = struct {
        pub const verbose: zl.debug.Logging.Default = .{
            .Attempt = true,
            .Success = true,
            .Acquire = true,
            .Release = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: zl.debug.Logging.Default = .{
            .Attempt = false,
            .Success = false,
            .Acquire = false,
            .Release = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const override = struct {
        pub const verbose: zl.debug.Logging.Override = .{
            .Attempt = true,
            .Success = true,
            .Acquire = true,
            .Release = true,
            .Error = true,
            .Fault = true,
        };
        pub const silent: zl.debug.Logging.Override = .{
            .Attempt = false,
            .Success = false,
            .Acquire = false,
            .Release = false,
            .Error = false,
            .Fault = false,
        };
    };
    pub const attempt_error = struct {
        pub const verbose: zl.debug.Logging.AttemptError =
            zl.builtin.all(zl.debug.Logging.AttemptError);
        pub const silent: zl.debug.Logging.AttemptError =
            zl.builtin.zero(zl.debug.Logging.AttemptError);
    };
    pub const attempt_fault = struct {
        pub const verbose: zl.debug.Logging.AttemptFault =
            zl.builtin.all(zl.debug.Logging.AttemptFault);
        pub const silent: zl.debug.Logging.AttemptFault =
            zl.builtin.zero(zl.debug.Logging.AttemptFault);
    };
    pub const attempt_success_error = struct {
        pub const verbose: zl.debug.Logging.AttemptSuccessError =
            zl.builtin.all(zl.debug.Logging.AttemptSuccessError);
        pub const silent: zl.debug.Logging.AttemptSuccessError =
            zl.builtin.zero(zl.debug.Logging.AttemptSuccessError);
    };
    pub const attempt_error_fault = struct {
        pub const verbose: zl.debug.Logging.AttemptErrorFault =
            zl.builtin.all(zl.debug.Logging.AttemptErrorFault);
        pub const silent: zl.debug.Logging.AttemptErrorFault =
            zl.builtin.zero(zl.debug.Logging.AttemptErrorFault);
    };
    pub const success_error = struct {
        pub const verbose: zl.debug.Logging.SuccessError =
            zl.builtin.all(zl.debug.Logging.SuccessError);
        pub const silent: zl.debug.Logging.SuccessError =
            zl.builtin.zero(zl.debug.Logging.SuccessError);
    };
    pub const success_fault = struct {
        pub const verbose: zl.debug.Logging.SuccessFault =
            zl.builtin.all(zl.debug.Logging.SuccessFault);
        pub const silent: zl.debug.Logging.SuccessFault =
            zl.builtin.zero(zl.debug.Logging.SuccessFault);
    };
    pub const success_error_fault = struct {
        pub const verbose: zl.debug.Logging.SuccessErrorFault =
            zl.builtin.all(zl.debug.Logging.SuccessErrorFault);
        pub const silent: zl.debug.Logging.SuccessErrorFault =
            zl.builtin.zero(zl.debug.Logging.SuccessErrorFault);
    };
    pub const acquire_error = struct {
        pub const verbose: zl.debug.Logging.AcquireError =
            zl.builtin.all(zl.debug.Logging.AcquireError);
        pub const silent: zl.debug.Logging.AcquireError =
            zl.builtin.zero(zl.debug.Logging.AcquireError);
    };
    pub const acquire_fault = struct {
        pub const verbose: zl.debug.Logging.AcquireFault =
            zl.builtin.all(zl.debug.Logging.AcquireFault);
        pub const silent: zl.debug.Logging.AcquireFault =
            zl.builtin.zero(zl.debug.Logging.AcquireFault);
    };
    pub const acquire_error_fault = struct {
        pub const verbose: zl.debug.Logging.AcquireErrorFault =
            zl.builtin.all(zl.debug.Logging.AcquireErrorFault);
        pub const silent: zl.debug.Logging.AcquireErrorFault =
            zl.builtin.zero(zl.debug.Logging.AcquireErrorFault);
    };
    pub const release_error = struct {
        pub const verbose: zl.debug.Logging.ReleaseError =
            zl.builtin.all(zl.debug.Logging.ReleaseError);
        pub const silent: zl.debug.Logging.ReleaseError =
            zl.builtin.zero(zl.debug.Logging.ReleaseError);
    };
    pub const release_fault = struct {
        pub const verbose: zl.debug.Logging.ReleaseFault =
            zl.builtin.all(zl.debug.Logging.ReleaseFault);
        pub const silent: zl.debug.Logging.ReleaseFault =
            zl.builtin.zero(zl.debug.Logging.ReleaseFault);
    };
    pub const release_error_fault = struct {
        pub const verbose: zl.debug.Logging.ReleaseErrorFault =
            zl.builtin.all(zl.debug.Logging.ReleaseErrorFault);
        pub const silent: zl.debug.Logging.ReleaseErrorFault =
            zl.builtin.zero(zl.debug.Logging.ReleaseErrorFault);
    };
};
pub const dir = struct {
    pub const options = struct {
        pub const eager: zl.file.DirStreamOptions = .{
            .init_read_all = true,
            .shrink_after_read = true,
            .make_list = true,
            .close_on_deinit = true,
        };
        pub const lazy: zl.file.DirStreamOptions = .{
            .init_read_all = false,
            .shrink_after_read = false,
            .make_list = false,
            .close_on_deinit = false,
        };
    };
    pub const logging = struct {
        pub const silent: zl.file.DirStreamLogging = .{
            .open = spec.logging.acquire_error.silent,
            .close = spec.logging.release_error.silent,
            .getdents = spec.logging.success_error.silent,
        };
        pub const verbose: zl.file.DirStreamLogging = .{
            .open = spec.logging.acquire_error.verbose,
            .close = spec.logging.release_error.verbose,
            .getdents = spec.logging.success_error.verbose,
        };
    };
    pub const errors = struct {
        pub const zen: zl.file.DirStreamErrors = .{
            .open = .{ .throw = sys.open.errors.all },
            .close = .{ .abort = sys.open.errors.all },
            .getdents = .{ .throw = sys.getdents.errors.all },
        };
        pub const noexcept: zl.file.DirStreamErrors = .{
            .open = .{},
            .close = .{},
            .getdents = .{},
        };
        pub const critical: zl.file.DirStreamErrors = .{
            .open = .{ .throw = sys.open.errors.all },
            .close = .{ .throw = sys.open.errors.all },
            .getdents = .{ .throw = sys.getdents.errors.all },
        };
    };
};
pub const allocator = struct {
    pub const options = struct {
        pub const small: zl.mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
        };
        // TODO: Describe conditions where this is better.
        pub const fast: zl.mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
        };
        pub const debug: zl.mem.ArenaAllocatorOptions = .{
            .count_branches = true,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = true,
            .trace_state = true,
            .trace_clients = true,
        };
        pub const small_composed: zl.mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
            .require_map = false,
            .require_unmap = false,
        };
        pub const fast_composed: zl.mem.ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
            .require_map = false,
            .require_unmap = false,
        };
        pub const debug_composed: zl.mem.ArenaAllocatorOptions = .{
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
    pub const logging = struct {
        pub const verbose: zl.mem.AllocatorLogging = .{
            .head = true,
            .sentinel = true,
            .metadata = true,
            .branches = true,
            .illegal = true,
            .map = spec.logging.acquire_error.verbose,
            .unmap = spec.logging.release_error.verbose,
            .remap = spec.logging.success_error.verbose,
            .advise = spec.logging.success_error.verbose,
            .allocate = true,
            .reallocate = true,
            .reinterpret = true,
            .deallocate = true,
        };
        pub const silent: zl.mem.AllocatorLogging = .{
            .head = false,
            .sentinel = false,
            .metadata = false,
            .branches = false,
            .illegal = false,
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
    pub const errors = struct {
        pub const zen: zl.mem.AllocatorErrors = .{
            .map = .{ .throw = sys.mmap.errors.mem },
            .remap = .{ .throw = sys.mremap.errors.all },
            .unmap = .{ .abort = sys.munmap.errors.all },
        };
        pub const noexcept: zl.mem.AllocatorErrors = .{
            .map = .{},
            .remap = .{},
            .unmap = .{},
        };
        pub const critical: zl.mem.AllocatorErrors = .{
            .map = .{ .throw = sys.mmap.errors.mem },
            .remap = .{ .throw = sys.mremap.errors.all },
            .unmap = .{ .throw = sys.munmap.errors.all },
        };
    };
};
pub const loader = struct {
    pub const logging = struct {
        pub const verbose = zl.builtin.all(zl.elf.LoaderSpec.Logging);
        pub const silent = zl.builtin.zero(zl.elf.LoaderSpec.Logging);
    };
    pub const errors = struct {
        pub const noexcept = .{
            .open = .{},
            .seek = .{},
            .read = .{},
            .map = .{},
            .unmap = .{},
            .close = .{},
        };
    };
};
pub const serializer = struct {
    pub const errors = struct {
        pub const noexcept: zl.serial.SerialSpec.Errors = .{
            .create = .{},
            .open = .{},
            .close = .{},
            .stat = .{},
            .read = .{},
            .write = .{},
        };
        pub const critical: zl.serial.SerialSpec.Errors = .{
            .create = .{ .throw = sys.open.errors.all },
            .open = .{ .throw = sys.open.errors.all },
            .close = .{ .throw = sys.close.errors.all },
            .stat = .{ .throw = sys.stat.errors.all },
            .read = .{ .throw = sys.read.errors.all },
            .write = .{ .throw = sys.write.errors.all },
        };
    };
    pub const logging = struct {
        pub const verbose: zl.serial.SerialSpec.Logging = .{
            .create = spec.logging.acquire_error.verbose,
            .open = spec.logging.acquire_error.verbose,
            .close = spec.logging.release_error.verbose,
            .read = spec.logging.success_error.verbose,
            .write = spec.logging.success_error.verbose,
            .stat = spec.logging.success_error_fault.verbose,
        };
        pub const silent: zl.serial.SerialSpec.Logging = .{
            .create = spec.logging.acquire_error.silent,
            .open = spec.logging.acquire_error.silent,
            .close = spec.logging.release_error.silent,
            .read = spec.logging.success_error.silent,
            .write = spec.logging.success_error.silent,
            .stat = spec.logging.success_error_fault.silent,
        };
    };
};
pub const file = struct {
    pub const map = struct {
        pub const flags = struct {
            pub const regular: zl.file.Map.Flags = .{
                .visibility = .private,
            };
            pub const executable: zl.file.Map.Flags = .{
                .populate = true,
                .executable = true,
                .visibility = .shared,
            };
        };
        pub const prot = struct {
            pub const regular: zl.file.Map.Protection = .{
                .read = true,
                .write = true,
                .exec = false,
            };
            pub const executable: zl.file.Map.Protection = .{
                .read = true,
                .write = false,
                .exec = true,
            };
        };
    };
    pub const create = struct {
        pub const truncate = .{
            .truncate = true,
            .write = true,
            .exclusive = false,
        };
    };
    pub const open = struct {
        pub const append = .{
            .write_only = true,
            .append = true,
            .exclusive = false,
        };
    };
};
const sys = struct {
    pub const generic = struct {
        pub const noexcept = .{ .errors = .{} };
    };
    pub const mmap = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .AGAIN, .BADF,     .EXIST, .INVAL,  .NFILE,
                .NODEV, .NOMEM, .OVERFLOW, .PERM,  .TXTBSY,
            };
            pub const mem = &.{
                .EXIST, .INVAL, .NOMEM,
            };
            pub const file = &.{
                .EXIST, .INVAL, .NOMEM, .NFILE, .NODEV, .TXTBSY,
            };
        };
    };
    pub const mremap = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .FAULT, .INVAL, .NOMEM,
            };
        };
    };
    pub const perf_event_open = struct {
        pub const errors = struct {
            pub const all = &.{
                .@"2BIG", .ACCES, .BADF,  .BUSY,      .FAULT,    .INTR, .INVAL, .MFILE, .NODEV,
                .NOENT,   .NOSPC, .NOSYS, .OPNOTSUPP, .OVERFLOW, .PERM, .SRCH,
            };
        };
    };
    pub const munmap = struct {
        pub const errors = struct {
            pub const all = &.{.INVAL};
        };
    };
    pub const brk = struct {
        pub const errors = struct {
            pub const all = &.{.NOMEM};
        };
    };
    pub const chdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .NAMETOOLONG, .LOOP, .ACCES, .IO, .BADF, .FAULT, .NOTDIR, .NOMEM, .NOENT,
            };
        };
    };
    pub const close = struct {
        pub const errors = struct {
            pub const all = &.{
                .INTR, .IO, .BADF, .NOSPC,
            };
        };
    };
    pub const clone3 = struct {
        pub const errors = struct {
            pub const all = &.{
                .PERM,      .AGAIN, .INVAL,   .EXIST, .USERS,
                .OPNOTSUPP, .NOMEM, .RESTART, .BUSY,  .NOSPC,
            };
        };
    };
    pub const open = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FBIG,        .NOTDIR,   .EXIST,  .OPNOTSUPP, .MFILE, .NOSPC,
                .NOENT, .NAMETOOLONG, .OVERFLOW, .TXTBSY, .AGAIN,     .BADF,  .ISDIR,
                .LOOP,  .NODEV,       .DQUOT,    .NOMEM,  .ROFS,      .NFILE, .INTR,
                .PERM,  .FAULT,       .INVAL,    .NXIO,   .BUSY,
            };
        };
    };
    pub const read = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .BADF, .FAULT, .INTR, .INVAL, .IO, .ISDIR,
            };
        };
    };
    pub const clock_gettime = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM,
            };
        };
    };
    pub const execve = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .IO,     .LIBBAD, .NOTDIR,  .MFILE, .NOENT, .NAMETOOLONG, .TXTBSY,
                .ISDIR, .LOOP,   .NOMEM,  .@"2BIG", .NFILE, .PERM,  .FAULT,       .AGAIN,
                .INVAL, .NOEXEC,
            };
        };
    };
    pub const fork = struct {
        pub const errors = struct {
            pub const all = &.{
                .NOSYS, .AGAIN, .NOMEM, .RESTART,
            };
        };
    };
    pub const getcwd = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .FAULT, .INVAL, .NAMETOOLONG, .NOENT, .NOMEM, .RANGE,
            };
        };
    };
    pub const getdents = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .FAULT, .INVAL, .NOENT, .NOTDIR,
            };
        };
    };
    pub const getrandom = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .FAULT, .INTR, .INVAL, .NOSYS,
            };
        };
    };
    pub const dup = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const dup2 = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const dup3 = struct {
        pub const errors = struct {
            pub const all = &.{
                .BADF, .BUSY, .INTR, .INVAL, .MFILE,
            };
        };
    };
    pub const poll = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INTR, .INVAL, .NOMEM,
            };
        };
    };
    pub const ioctl = struct {
        pub const errors = struct {
            pub const all = &.{
                .NOTTY, .BADF, .FAULT, .INVAL,
            };
        };
    };
    pub const madvise = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
            };
        };
    };
    pub const mkdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP, .MLINK,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
            };
            pub const noexcl = &.{
                .ACCES,       .BADF,  .DQUOT, .FAULT, .INVAL,  .LOOP, .MLINK,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM, .ROFS,
            };
        };
    };
    pub const memfd_create = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INVAL, .MFILE, .NOMEM,
            };
        };
    };
    pub const truncate = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,  .FAULT, .FBIG, .INTR,   .IO,    .ISDIR, .LOOP, .NAMETOOLONG,
                .NOTDIR, .PERM,  .ROFS, .TXTBSY, .INVAL, .BADF,
            };
        };
    };
    pub const mknod = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .DQUOT, .EXIST, .FAULT,  .INVAL, .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS,
            };
        };
    };
    pub const open_by_handle_at = struct {
        pub const errors = struct {
            pub const all = open.errors.all ++ [1]zl.sys.ErrorCode{.STALE};
        };
    };
    pub const name_to_handle_at = struct {
        pub const errors = struct {
            pub const all = open.errors.all ++ [1]zl.sys.ErrorCode{.STALE};
        };
    };
    pub const link = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BADF,  .DQUOT, .EXIST,  .FAULT, .IO,   .LOOP,  .NAMETOOLONG,
                .NOENT, .NOMEM, .NOSPC, .NOTDIR, .PERM,  .ROFS, .MLINK, .XDEV,
                .INVAL,
            };
        };
    };
    pub const nanosleep = struct {
        pub const errors = struct {
            pub const all = &.{
                .INTR, .FAULT, .INVAL, .OPNOTSUPP,
            };
        };
    };
    pub const readlink = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .FAULT, .INVAL,  .IO, .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR,
            };
        };
    };
    pub const rmdir = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BUSY,  .FAULT,  .INVAL,    .LOOP, .NAMETOOLONG,
                .NOENT, .NOMEM, .NOTDIR, .NOTEMPTY, .PERM, .ROFS,
            };
        };
    };
    pub const sigaction = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INVAL,
            };
        };
    };
    pub const seek = struct {
        pub const errors = struct {
            pub const all = &.{ .BADF, .NXIO, .OVERFLOW, .SPIPE };
        };
    };
    pub const stat = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES,       .BADF,  .FAULT, .INVAL,  .LOOP,
                .NAMETOOLONG, .NOENT, .NOMEM, .NOTDIR, .OVERFLOW,
            };
            pub const all_noent = &.{
                .ACCES,       .BADF,  .FAULT,  .INVAL,    .LOOP,
                .NAMETOOLONG, .NOMEM, .NOTDIR, .OVERFLOW,
            };
        };
    };
    pub const unlink = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .BUSY,  .FAULT,  .IO,   .ISDIR, .LOOP, .NAMETOOLONG,
                .NOENT, .NOMEM, .NOTDIR, .PERM, .ROFS,  .BADF, .INVAL,
            };
            pub const all_noent = &.{
                .ACCES, .BUSY,   .FAULT, .IO,   .ISDIR, .LOOP,  .NAMETOOLONG,
                .NOMEM, .NOTDIR, .PERM,  .ROFS, .BADF,  .INVAL,
            };
        };
    };
    pub const write = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .BADF,  .DESTADDRREQ, .DQUOT, .FAULT, .FBIG,
                .INTR,  .INVAL, .IO,          .NOSPC, .PERM,  .PIPE,
            };
        };
    };
    pub const wait = struct {
        pub const errors = struct {
            pub const all = &.{
                .SRCH, .INTR, .AGAIN, .INVAL, .CHILD,
            };
        };
    };
    pub const waitid = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .CHILD, .INTR, .INVAL, .SRCH,
            };
        };
    };
    pub const pipe = struct {
        pub const errors = struct {
            pub const all = &.{
                .FAULT, .INVAL, .MFILE, .NFILE, .NOPKG,
            };
        };
    };
};
