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
const errors: sys.ErrorPolicy = .{};

const getcwd_spec: file.GetWorkingDirectorySpec = .{
    .errors = .{ .throw = sys.getcwd_errors },
};
const make_dir_spec: file.MakeDirSpec = .{
    .errors = .{ .throw = sys.mkdir_errors },
};
const create_spec: file.CreateSpec = .{
    .options = .{},
    .errors = .{ .throw = sys.open_errors },
};
const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null },
    .errors = .{ .throw = sys.open_errors },
};
const open_dir_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null, .directory = true },
    .errors = .{ .throw = sys.open_errors },
};
const remove_dir_spec: file.RemoveDirSpec = .{
    .errors = .{ .throw = sys.rmdir_errors },
};
const unlink_spec: file.UnlinkSpec = .{
    .errors = .{ .throw = sys.unlink_errors },
};
const close_spec: file.CloseSpec = .{
    .errors = .{ .throw = sys.close_errors },
};
const stat_spec: file.StatSpec = .{
    .errors = .{ .throw = sys.stat_errors },
};
const ftruncate_spec: file.TruncateSpec = .{
    .errors = .{ .throw = sys.truncate_errors },
};
const truncate_spec: file.TruncateSpec = .{
    .errors = .{ .throw = sys.truncate_errors },
};
fn testFileOperationsRound1() !void {
    try meta.wrap(file.makeDir(make_dir_spec, "/run/user/1000/file_test"));
    try meta.wrap(file.removeDir(remove_dir_spec, "/run/user/1000/file_test"));
    const fd: u64 = try meta.wrap(file.create(create_spec, "/run/user/1000/file_test"));
    try meta.wrap(file.close(close_spec, fd));
    try meta.wrap(file.unlink(unlink_spec, "/run/user/1000/file_test"));
}
pub fn testSocketOpenAndClose() !void {
    const unix_tcp_fd: u64 = try file.socket(.{}, .unix, .tcp);
    const unix_udp_fd: u64 = try file.socket(.{}, .unix, .udp);
    const ipv6_udp_fd: u64 = try file.socket(.{}, .ipv6, .udp);
    const ipv6_tcp_fd: u64 = try file.socket(.{}, .ipv6, .tcp);
    const ipv4_udp_fd: u64 = try file.socket(.{}, .ipv4, .udp);
    const ipv4_tcp_fd: u64 = try file.socket(.{}, .ipv4, .tcp);
    try file.close(.{}, ipv4_tcp_fd);
    try file.close(.{}, ipv4_udp_fd);
    try file.close(.{}, ipv6_tcp_fd);
    try file.close(.{}, ipv6_udp_fd);
    try file.close(.{}, unix_udp_fd);
    try file.close(.{}, unix_tcp_fd);
}
fn testFileOperationsRound2() !void {
    var buf: [4096]u8 = undefined;
    _ = try meta.wrap(file.getCwd(getcwd_spec, &buf));
    try meta.wrap(file.makeDir(make_dir_spec, "/run/user/1000/file_test"));
    var st: file.Stat = try meta.wrap(file.stat(stat_spec, "/run/user/1000/file_test"));
    builtin.assert(st.isDirectory());
    const dir_fd: u64 = try meta.wrap(file.open(open_dir_spec, "/run/user/1000/file_test"));
    try meta.wrap(file.makeDirAt(make_dir_spec, dir_fd, "file_test"));
    try meta.wrap(file.removeDir(remove_dir_spec, "/run/user/1000/file_test/file_test"));
    try meta.wrap(file.removeDir(remove_dir_spec, "/run/user/1000/file_test"));
    try meta.wrap(file.close(close_spec, dir_fd));

    const mem_fd: u64 = try meta.wrap(mem.fd(.{}, "buffer"));
    try meta.wrap(file.ftruncate(ftruncate_spec, mem_fd, 4096));
}
fn testPathOperations() !void {
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename("/run/user/1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file", file.basename("file")));
    try meta.wrap(testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///")));
}
pub fn main() !void {
    try meta.wrap(testFileOperationsRound1());
    try meta.wrap(testFileOperationsRound2());
    try meta.wrap(testSocketOpenAndClose());
    try meta.wrap(testPathOperations());
}
