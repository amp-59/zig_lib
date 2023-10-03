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
};
