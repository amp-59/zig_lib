const top = @import("../zig_lib.zig");
const sys = top.sys;
const mem = top.mem;
const fmt = top.fmt;
const file = top.file;
const meta = top.meta;
const mach = top.mach;
const time = top.time;
const proc = top.proc;
const spec = top.spec;
const build = top.build;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const logging_default: builtin.Logging.Default = spec.logging.default.verbose;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const getcwd_spec: file.GetWorkingDirectorySpec = .{};
const make_dir_spec: file.MakeDirSpec = .{};
const make_node_spec: file.MakeNodeSpec = .{};
const seek_spec: file.SeekSpec = .{};
const create_spec: file.CreateSpec = .{
    .options = .{ .read = true, .write = true, .append = false },
};
const path_spec: file.PathSpec = .{};
const file_path_spec: file.PathSpec = .{ .options = .{ .directory = false } };
const link_spec: file.LinkSpec = .{};
const copy_spec: file.CopySpec = .{};
const send_spec: file.SendSpec = .{};
const open_spec: file.OpenSpec = .{
    .options = .{ .write = true, .append = true },
};
const open_dir_spec: file.OpenSpec = .{
    .options = .{ .read = true, .directory = true },
};
const remove_dir_spec: file.RemoveDirSpec = .{};
const unlink_spec: file.UnlinkSpec = .{};
const close_spec: file.CloseSpec = .{};
const stat_spec: file.StatusSpec = .{};
const statx_spec: file.StatusExtendedSpec = .{
    .options = .{ .fields = .{} },
};
const ftruncate_spec: file.TruncateSpec = .{};
const truncate_spec: file.TruncateSpec = .{};
const make_path_spec: file.MakePathSpec = .{
    .errors = .{},
    .logging = .{},
};
const read_spec: file.ReadSpec = .{};
const write_spec: file.WriteSpec = .{};
const pipe_spec: file.MakePipeSpec = .{
    .options = .{ .close_on_exec = false },
};
const poll_spec: file.PollSpec = .{
    .errors = .{ .throw = sys.poll_errors },
};
fn testPoll() !void {
    var pollfds: [3]file.PollFd = .{
        .{ .fd = 0, .expect = .{ .input = true } },
        .{ .fd = 1, .expect = .{ .output = true } },
        .{ .fd = 2, .expect = .{ .output = true } },
    };
    try file.poll(poll_spec, &pollfds, 100);
}

const file_name: [:0]const u8 = "file_test";
const test_dir: [:0]const u8 = @import("env").build_root ++ "/test/";
const pathname1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname2: [:0]const u8 = test_dir ++ file_name ++ "2";
const pathname_link1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname_link2: [:0]const u8 = test_dir ++ file_name ++ "2";

fn testRecords() !void {
    const build_root: []const u8 = comptime builtin.buildRoot();
    const proj_stats_root: [:0]const u8 = comptime build_root ++ "/zig-stat/file_test";
    var rcd_buf: [4096]build.Record = undefined;
    const fd: u64 = try file.open(.{}, proj_stats_root);
    var buf: [4096]u8 = undefined;
    for (rcd_buf[0..try file.read(.{ .child = build.Record }, fd, &rcd_buf)]) |rcd| {
        builtin.debug.write(buf[0..mach.memcpyMulti(&buf, &.{ @tagName(rcd.detail.mode), "\n" })]);
    }
}
fn testStatusExtended() !void {
    const Fields = @TypeOf(statx_spec.options.fields);
    const nilx_spec: file.StatusExtendedSpec = comptime spec.add(statx_spec, .{ .options = .{ .fields = builtin.zero(Fields) } });
    var st: file.StatusExtended = try meta.wrap(file.statusExtended(nilx_spec, 0, "/home"));
    _ = st;
}
fn testCopyFileRange() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const src_fd: u64 = try meta.wrap(file.create(create_spec, pathname1, file.mode.regular));
    const dest_fd: u64 = try meta.wrap(file.create(create_spec, pathname2, file.mode.regular));
    var rng: file.DeviceRandomBytes(65536) = .{};
    try meta.wrap(file.write(write_spec, src_fd, &rng.readCount(u8, 65536)));
    builtin.assertEqual(u64, 0, try meta.wrap(file.seek(seek_spec, src_fd, 0, .set)));
    var src_off: u64 = 4096;
    var dest_off: u64 = 0;
    _ = try meta.wrap(file.copy(copy_spec, dest_fd, &dest_off, src_fd, &src_off, 65536));
    _ = try meta.wrap(file.send(send_spec, dest_fd, src_fd, null, 65536));
    _ = try meta.wrap(file.sync(.{}, dest_fd));
    try meta.wrap(file.close(close_spec, dest_fd));
    try meta.wrap(file.close(close_spec, src_fd));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test1"));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test2"));
}
fn testFileOperationsRound1() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    var buf: [4096]u8 = undefined;
    _ = try file.getCwd(.{}, &buf);
    try meta.wrap(file.makeDir(make_dir_spec, test_dir ++ "file_test", file.mode.directory));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    const src_fd: u64 = try meta.wrap(file.create(create_spec, test_dir ++ "file_test1", file.mode.regular));
    const dest_fd: u64 = try meta.wrap(file.create(create_spec, test_dir ++ "file_test2", file.mode.regular));
    try meta.wrap(file.close(close_spec, dest_fd));
    try meta.wrap(file.close(close_spec, src_fd));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test1"));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test2"));
}
pub fn testSocketOpenAndClose() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const unix_tcp_fd: u64 = try file.socket(.{}, .unix, .tcp, .ip);
    const unix_udp_fd: u64 = try file.socket(.{}, .unix, .udp, .ip);
    const ipv6_udp_fd: u64 = try file.socket(.{}, .ipv6, .udp, .ip);
    const ipv6_tcp_fd: u64 = try file.socket(.{}, .ipv6, .tcp, .ip);
    const ipv4_udp_fd: u64 = try file.socket(.{}, .ipv4, .udp, .ip);
    const ipv4_tcp_fd: u64 = try file.socket(.{}, .ipv4, .tcp, .ip);
    try file.close(.{}, ipv4_tcp_fd);
    try file.close(.{}, ipv4_udp_fd);
    try file.close(.{}, ipv6_tcp_fd);
    try file.close(.{}, ipv6_udp_fd);
    try file.close(.{}, unix_udp_fd);
    try file.close(.{}, unix_tcp_fd);
}
pub fn testClientIPv4(args: [][*:0]u8) !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: u64 = try file.socket(.{ .options = .{ .non_block = false } }, .ipv4, .udp, .ip);
    try file.connect(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    try file.write(.{}, fd, meta.manyToSlice(args[0]));
    const len: u64 = try file.read(.{ .return_type = u64 }, fd, &buf);
    builtin.debug.write(comptime builtin.fmt.about("ipv4") ++ "server responds: ");
    builtin.debug.write(buf[0..len]);
    builtin.debug.write("\n");
}
pub fn testServerIPv4() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: u64 = try file.socket(.{ .options = .{ .non_block = false } }, .ipv4, .udp, .udp);
    try file.bind(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: file.Socket.Address = undefined;
    var sender_addrlen: u32 = 16;
    const len: u64 = try file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
pub fn testClientIPv6(args: [][*:0]u8) !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: u64 = try file.socket(.{ .options = .{ .non_block = false } }, .ipv6, .udp, .ip);
    try file.connect(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    try file.write(.{}, fd, meta.manyToSlice(args[0]));
    const len: u64 = try file.read(.{ .return_type = u64 }, fd, &buf);
    builtin.debug.write(comptime builtin.fmt.about("ipv6") ++ "server responds: ");
    builtin.debug.write(buf[0..len]);
    builtin.debug.write("\n");
}
pub fn testServerIPv6() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: u64 = try file.socket(.{ .options = .{ .non_block = false } }, .ipv6, .udp, .udp);
    try file.bind(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: file.Socket.Address = undefined;
    var sender_addrlen: u32 = 28;
    const len: u64 = try file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
pub fn testClientAndServerIPv4(args: [][*:0]u8) !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    if (try proc.fork(.{}) == 0) {
        try testServerIPv4();
        builtin.proc.exit(0);
    }
    try time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv4(args);
}
pub fn testClientAndServerIPv6(args: [][*:0]u8) !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    if (try proc.fork(.{}) == 0) {
        try testServerIPv6();
        builtin.proc.exit(0);
    }
    try time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv6(args);
}
pub fn testFileTests() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    try file.makeDir(make_dir_spec, test_dir ++ "file_test", file.mode.directory);
    try file.pathAssert(stat_spec, test_dir ++ "file_test", .directory);
    const fd: u64 = try file.open(open_dir_spec, test_dir ++ "file_test");
    try builtin.expect(try file.pathIs(stat_spec, test_dir ++ "file_test", .directory));
    try builtin.expect(try file.pathIsNot(stat_spec, test_dir ++ "file_test", .regular));
    try builtin.expect(try file.pathIsNot(stat_spec, test_dir ++ "file_test", .block_special));
    try builtin.expect(try file.is(stat_spec, fd, .directory));
    try file.close(close_spec, fd);
    try file.removeDir(remove_dir_spec, test_dir ++ "file_test");
}
fn testFileOperationsRound2() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    try meta.wrap(file.makeDir(make_dir_spec, test_dir ++ "file_test", file.mode.directory));
    const dir_fd: u64 = try meta.wrap(file.open(open_dir_spec, test_dir ++ "file_test"));
    try meta.wrap(file.makeDirAt(make_dir_spec, dir_fd, "file_test", file.mode.directory));
    var path_dir_fd: u64 = try meta.wrap(file.path(path_spec, test_dir ++ "file_test/file_test"));
    try meta.wrap(file.close(close_spec, try meta.wrap(file.create(create_spec, test_dir ++ "file_test/file_test/file_test", file.mode.regular))));
    const path_reg_fd: u64 = try meta.wrap(file.path(file_path_spec, test_dir ++ "file_test/file_test/file_test"));
    try file.assertNot(stat_spec, path_reg_fd, .unknown);
    try file.assert(stat_spec, path_reg_fd, .regular);
    try file.makeNode(make_node_spec, test_dir ++ "file_test/regular", .{}, .{});
    try file.unlink(unlink_spec, test_dir ++ "file_test/regular");
    try file.makeNode(make_node_spec, test_dir ++ "file_test/fifo", .{ .kind = .named_pipe }, .{});
    try file.unlink(unlink_spec, test_dir ++ "file_test/fifo");
    const new_in_fd: u64 = try file.duplicate(.{}, 0);
    try file.write(.{}, new_in_fd, builtin.fmt.ud64(new_in_fd).readAll());
    try file.duplicateTo(.{}, new_in_fd, new_in_fd +% 1);
    try file.write(.{}, new_in_fd +% 1, builtin.fmt.ud64(new_in_fd +% 1).readAll());
    try meta.wrap(file.close(close_spec, path_reg_fd));
    try meta.wrap(file.unlinkAt(unlink_spec, path_dir_fd, "file_test"));
    try meta.wrap(file.close(close_spec, path_dir_fd));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test"));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    try meta.wrap(file.close(close_spec, dir_fd));
    const mem_fd: u64 = try meta.wrap(mem.fd(.{}, "buffer"));
    try meta.wrap(file.truncate(ftruncate_spec, mem_fd, 4096));
}
fn testPathOperations() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename(test_dir ++ "file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file", file.basename("file")));
    try meta.wrap(testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///")));
    try file.makePath(make_path_spec, comptime builtin.buildRoot() ++ "/zig-out/bin/something/here", file.mode.directory);
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
fn testStandardChannel() !void {
    const Channel = file.GenericChannel(.{
        .errors = spec.channel.errors.noexcept,
        .logging = spec.channel.logging.silent,
    });
    var chan: Channel = Channel.init();
    const pid: u64 = try proc.fork(.{});
    if (pid == 0) {
        try meta.wrap(file.close(Channel.decls.close_spec, chan.in.write));
        try meta.wrap(file.close(Channel.decls.close_spec, chan.out.read));
        try meta.wrap(file.close(Channel.decls.close_spec, chan.err.read));
        try meta.wrap(file.duplicateTo(Channel.decls.dup3_spec, chan.in.read, 0));
        try meta.wrap(file.duplicateTo(Channel.decls.dup3_spec, chan.out.write, 1));
        try meta.wrap(file.duplicateTo(Channel.decls.dup3_spec, chan.out.write, 2));
        var i_array: mem.StaticString(4096) = undefined;
        i_array.undefineAll();
        var o_array: mem.StaticString(4096) = undefined;
        o_array.undefineAll();
        i_array.define(try file.read(.{}, 0, i_array.referAllUndefined()));
        o_array.writeMany("msg: ");
        o_array.writeMany(i_array.readAll());
        o_array.writeMany(", len: ");
        o_array.writeFormat(fmt.ud64(i_array.len()));
        o_array.writeMany("\n");
        try file.write(.{}, chan.out.write, o_array.readAll());
        builtin.proc.exit(0);
    } else {
        try meta.wrap(file.close(Channel.decls.close_spec, chan.in.read));
        try meta.wrap(file.close(Channel.decls.close_spec, chan.out.write));
        try meta.wrap(file.close(Channel.decls.close_spec, chan.err.write));
        var i_array: mem.StaticString(4096) = undefined;
        i_array.undefineAll();
        try file.write(.{}, chan.in.write, "message");
        i_array.define(try file.read(.{}, chan.out.read, i_array.referAllUndefined()));
        try file.write(.{}, 1, i_array.readAll());
    }
}
fn testLink() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const fd: u64 = try file.create(create_spec, test_dir ++ "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.link(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try file.unlink(unlink_spec, test_dir ++ "file_test");
    try file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testSymbolicLink() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const fd: u64 = try file.create(create_spec, test_dir ++ "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.symbolicLink(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try file.unlink(unlink_spec, test_dir ++ "file_test");
    try file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testLinkAt() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const dir_fd: u64 = try file.path(path_spec, test_dir);
    const fd: u64 = try file.createAt(create_spec, dir_fd, "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.linkAt(link_spec, dir_fd, "file_test", dir_fd, "file_test_link");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try file.close(close_spec, dir_fd);
}
fn testSymbolicLinkAt() !void {
    builtin.debug.write(@src().fn_name ++ ":\n");
    const dir_fd: u64 = try file.path(path_spec, test_dir);
    const fd: u64 = try file.createAt(create_spec, dir_fd, "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.symbolicLinkAt(link_spec, test_dir ++ "file_test", dir_fd, "file_test_link");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try file.close(close_spec, dir_fd);
}
fn testPreClean() !void {
    file.unlink(unlink_spec, test_dir ++ "file_test1") catch {};
    file.unlink(unlink_spec, test_dir ++ "file_test2") catch {};
    file.unlink(unlink_spec, test_dir ++ "file_test/file_test/file_test") catch {};
    file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test") catch {};
    file.removeDir(remove_dir_spec, test_dir ++ "file_test") catch {};
}
pub fn main(args: [][*:0]u8) !void {
    try meta.wrap(testRecords());
    try meta.wrap(testPreClean());
    try meta.wrap(testFileOperationsRound1());
    try meta.wrap(testFileOperationsRound2());
    try meta.wrap(testStandardChannel());
    try meta.wrap(testStatusExtended());
    try meta.wrap(testSocketOpenAndClose());
    try meta.wrap(testPathOperations());
    try meta.wrap(testFileTests());
    try meta.wrap(testPoll());
    try meta.wrap(testClientAndServerIPv4(args));
    try meta.wrap(testClientAndServerIPv6(args));
    try meta.wrap(testCopyFileRange());
    try meta.wrap(testLink());
    try meta.wrap(testLinkAt());
    try meta.wrap(testSymbolicLink());
    try meta.wrap(testSymbolicLinkAt());
}
