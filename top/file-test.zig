const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;
pub const is_verbose: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const exec_zig: bool = false;
const errors: ?[]const sys.ErrorCode = meta.empty;

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

fn makeArgs(buf: [:0]u8, any: anytype) [any.len + 2][*:0]u8 {
    var args: [any.len + 2][*:0]u8 = undefined;
    args[0] = buf.ptr;
    buf[0] = 0;
    var off: u64 = 1;
    inline for (any) |arg, i| {
        for (arg) |c, j| buf[off..][j] = c;
        args[i + 1] = buf[off..];
        off += arg.len;
        buf[off] = 0;
        off += 1;
    }
    @ptrCast(*u64, &args[any.len + 1]).* = 0;
    return args;
}

fn testFileOperationsRound1() !void {
    try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
    try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
    const fd: u64 = try file.create(create_spec, "/run/user/1000/file_test");
    try file.close(close_spec, fd);
    try file.unlink(unlink_spec, "/run/user/1000/file_test");
}
fn testFileOperationsRound2() !void {
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
fn testExecutable(vars: []const [*:0]u8) !void {
    var args_buf: [4096:0]u8 = undefined;
    const args: [3][*:0]u8 = makeArgs(&args_buf, .{"zen"});
    const dir_fd: u64 = try file.find(vars, "zig");
    try proc.execAt(exec_spec, dir_fd, "zig", &args, vars);
}
fn testPathOperations() !void {
    try testing.expectEqualMany(u8, "file_test", file.basename("/run/user/1000/file_test"));
    try testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test"));
    try testing.expectEqualMany(u8, "file", file.basename("file"));
    try testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test"));
    try testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///"));
}
pub fn main(_: []const [*:0]u8, vars: []const [*:0]u8) !void {
    try meta.wrap(testFileOperationsRound1());
    try meta.wrap(testFileOperationsRound2());
    try meta.wrap(testExecutable(vars));
    try meta.wrap(testPathOperations());
}
