const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;
pub const is_verbose: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const exec_zig: bool = false;
const errors: ?[]const sys.ErrorCode = &.{};

const make_dir_spec: file.MakeDirSpec = .{
    .errors = errors,
};
const create_spec: file.CreateSpec = .{
    .options = .{},
    .errors = errors,
};
const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null },
    .errors = errors,
};
const open_dir_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null, .directory = true },
    .errors = errors,
};
const exec_spec: proc.ExecuteSpec = .{
    .options = .{},
    .errors = errors,
};
const remove_dir_spec: file.RemoveDirSpec = .{
    .errors = errors,
};
const unlink_spec: file.UnlinkSpec = .{
    .errors = errors,
};
const close_spec: file.CloseSpec = .{
    .errors = errors,
};
const stat_spec: file.StatSpec = .{
    .errors = errors,
};
const ftruncate_spec: file.TruncateSpec = .{
    .errors = errors,
};
const truncate_spec: file.TruncateSpec = .{
    .errors = errors,
};

fn makeArgs(buf: [:0]u8, any: anytype) [@typeInfo(@TypeOf(any)).Struct.fields.len][*:0]u8 {
    var args: [@typeInfo(@TypeOf(any)).Struct.fields.len][*:0]u8 = undefined;
    var off: u64 = 0;
    var dst_arg: [:0]u8 = buf;
    inline for (any) |src_arg, i| {
        @memcpy(dst_arg.ptr, @as([]const u8, src_arg).ptr, src_arg.len);
        off = src_arg.len;
        args[i] = dst_arg.ptr;
        dst_arg = dst_arg[off..];
    }
    return args;
}
pub fn main(_: anytype, vars: anytype) !void {
    {
        try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
        const fd: u64 = try file.create(create_spec, "/run/user/1000/file_test");
        try file.close(close_spec, fd);
        try file.unlink(unlink_spec, "/run/user/1000/file_test");
    }
    {
        try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
        var st: file.Stat = try file.stat(stat_spec, "/run/user/1000/file_test");
        builtin.assert(st.isDirectory());
        const dir_fd: u64 = try file.open(open_dir_spec, "/run/user/1000/file_test");
        try file.makeDirAt(make_dir_spec, dir_fd, "file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test/file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
        try file.close(close_spec, dir_fd);

        const mem_fd: u64 = try mem.fd(.{}, "buffer");
        try file.ftruncate(ftruncate_spec, mem_fd, 4096);
    }
    {
        const dir_fd: u64 = try file.find(vars, "zig");
        var args_buf: [4096:0]u8 = .{0} ** 4096;
        var args: [1][*:0]u8 = makeArgs(&args_buf, .{"zen"});
        try proc.execAt(exec_spec, dir_fd, "zig", &args, vars);
    }
    {
        try testing.expectEqualMany(u8, "file_test", file.basename("/run/user/1000/file_test"));
        try testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test"));
        try testing.expectEqualMany(u8, "file", file.basename("file"));
        try testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test"));
        try testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///"));
    }
}
