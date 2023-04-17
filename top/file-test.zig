const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const getcwd_spec: file.GetWorkingDirectorySpec = .{
    .errors = .{ .throw = sys.getcwd_errors },
};
const make_dir_spec: file.MakeDirSpec = .{
    .errors = .{ .throw = sys.mkdir_errors },
};
const make_node_spec: file.MakeNodeSpec = .{
    .errors = .{ .throw = sys.mknod_errors },
};
const create_spec: file.CreateSpec = .{
    .options = .{},
    .errors = .{ .throw = sys.open_errors },
};
const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = .append },
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
const stat_spec: file.StatusSpec = .{
    .errors = .{ .throw = sys.stat_errors },
};
const ftruncate_spec: file.TruncateSpec = .{
    .errors = .{ .throw = sys.truncate_errors },
};
const truncate_spec: file.TruncateSpec = .{
    .errors = .{ .throw = sys.truncate_errors },
};
const make_path_spec: file.MakePathSpec = .{
    .errors = .{},
    .logging = .{},
};

fn testFileOperationsRound1() !void {
    try meta.wrap(file.makeDir(make_dir_spec, "/run/user/1000/file_test", file.dir_mode));
    try meta.wrap(file.removeDir(remove_dir_spec, "/run/user/1000/file_test"));
    const fd: u64 = try meta.wrap(file.create(create_spec, "/run/user/1000/file_test", file.file_mode));
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
pub fn testFileTests() !void {
    try file.makeDir(make_dir_spec, "/run/user/1000/file_test", file.dir_mode);
    try file.pathAssert(stat_spec, "/run/user/1000/file_test", .directory);
    const fd: u64 = try file.open(open_dir_spec, "/run/user/1000/file_test");
    try builtin.expect(try file.pathIs(stat_spec, "/run/user/1000/file_test", .directory));
    try builtin.expect(try file.pathIsNot(stat_spec, "/run/user/1000/file_test", .regular));
    try builtin.expect(try file.pathIsNot(stat_spec, "/run/user/1000/file_test", .block_special));
    try builtin.expect(try file.is(stat_spec, fd, .directory));
    try file.close(close_spec, fd);
    try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
}
fn testFileOperationsRound2() !void {
    var buf: [4096]u8 = undefined;
    _ = try meta.wrap(file.getCwd(getcwd_spec, &buf));
    try meta.wrap(file.makeDir(make_dir_spec, "/run/user/1000/file_test", file.dir_mode));
    const dir_fd: u64 = try meta.wrap(file.open(open_dir_spec, "/run/user/1000/file_test"));
    try meta.wrap(file.makeDirAt(make_dir_spec, dir_fd, "file_test", file.dir_mode));
    const path_dir_fd: u64 = try meta.wrap(file.path(.{}, "/run/user/1000/file_test/file_test"));
    try meta.wrap(file.close(close_spec, try meta.wrap(file.create(create_spec, "/run/user/1000/file_test/file_test/file_test", file.file_mode))));
    const path_reg_fd: u64 = try meta.wrap(file.path(.{ .options = .{ .directory = false } }, "/run/user/1000/file_test/file_test/file_test"));
    try file.assertNot(stat_spec, path_reg_fd, .unknown);
    try file.assert(stat_spec, path_reg_fd, .regular);

    try file.makeNode(make_node_spec, "/run/user/1000/file_test/regular", .{}, .{});
    try file.unlink(unlink_spec, "/run/user/1000/file_test/regular");
    try file.makeNode(make_node_spec, "/run/user/1000/file_test/fifo", .{ .kind = .named_pipe }, .{});
    try file.unlink(unlink_spec, "/run/user/1000/file_test/fifo");

    const new_in_fd: u64 = try file.duplicate(.{}, 0);
    try file.write(.{}, new_in_fd, builtin.fmt.ud64(new_in_fd).readAll());
    const new_new_in_fd: u64 = try file.duplicateTo(.{}, 7, 8);
    try file.write(.{}, new_new_in_fd, builtin.fmt.ud64(new_new_in_fd).readAll());

    try meta.wrap(file.close(close_spec, path_reg_fd));
    try meta.wrap(file.unlinkAt(unlink_spec, path_dir_fd, "file_test"));
    try meta.wrap(file.close(close_spec, path_dir_fd));
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

    try file.makePath(make_path_spec, comptime builtin.buildRoot() ++ "/zig-out/bin/something/here", file.dir_mode);
    try file.removeDir(remove_dir_spec, comptime builtin.buildRoot() ++ "/zig-out/bin/something/here");
    try file.removeDir(remove_dir_spec, comptime builtin.buildRoot() ++ "/zig-out/bin/something");
}
fn testPackedModeStruct() !void {
    const mode: file.Mode = .{
        .owner = .{ .read = true, .write = true, .execute = false },
        .group = .{ .read = true, .write = true, .execute = false },
        .other = .{ .read = true, .write = true, .execute = false },
        .set_uid = false,
        .set_gid = false,
        .sticky = false,
        .kind = .regular,
    };
    comptime var int: u16 = meta.leastBitCast(mode);
    var fd: u64 = try meta.wrap(file.create(create_spec, "./0123456789", mode));
    try file.close(close_spec, fd);
    fd = try file.open(open_spec, "./0123456789");
    const st: file.Status = try file.status(stat_spec, fd);
    try file.unlink(unlink_spec, "./0123456789");
    try builtin.expectEqual(u16, int, @bitCast(u16, st.mode));
}
pub fn main(_: anytype, vars: anytype) !void {
    const path_fd: u64 = try file.find(vars, "zig");

    _ = path_fd;

    try meta.wrap(testFileOperationsRound1());
    try meta.wrap(testFileOperationsRound2());
    try meta.wrap(testSocketOpenAndClose());
    try meta.wrap(testPathOperations());
    try meta.wrap(testFileTests());
    // try meta.wrap(testPackedModeStruct());
}
