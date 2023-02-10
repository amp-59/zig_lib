const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const is_verbose: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const exec_zig: bool = false;
const errors: ?[]const sys.ErrorCode = meta.empty;

const getcwd_spec: file.GetWorkingDirectorySpec = .{
    .errors = errors,
};
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
fn testFileOperationsRound1() !void {
    try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
    try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
    const fd: u64 = try file.create(create_spec, "/run/user/1000/file_test");
    try file.close(close_spec, fd);
    try file.unlink(unlink_spec, "/run/user/1000/file_test");
}
fn testFileOperationsRound2() !void {
    var buf: [4096]u8 = undefined;
    _ = try file.getCwd(getcwd_spec, &buf);
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
fn testPathOperations() !void {
    try testing.expectEqualMany(u8, "file_test", file.basename("/run/user/1000/file_test"));
    try testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test"));
    try testing.expectEqualMany(u8, "file", file.basename("file"));
    try testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test"));
    try testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///"));
}
pub fn main() !void {
    try meta.wrap(testFileOperationsRound1());
    try meta.wrap(testFileOperationsRound2());
    try meta.wrap(testPathOperations());
}
