const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const mem = zl.mem;
const fmt = zl.fmt;
const file = zl.file;
const meta = zl.meta;
const mach = zl.mach;
const time = zl.time;
const proc = zl.proc;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

pub const runtime_assertions: bool = true;
pub const logging_default: debug.Logging.Default = spec.logging.default.verbose;

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
    .options = .{ .read_write = true, .append = true },
};
const open_dir_spec: file.OpenSpec = .{};
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
const test_dir: [:0]const u8 = @import("root").build_root ++ "/test/";
const pathname1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname2: [:0]const u8 = test_dir ++ file_name ++ "2";
const pathname_link1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname_link2: [:0]const u8 = test_dir ++ file_name ++ "2";

pub fn testStatusExtended() !void {
    const Fields = @TypeOf(statx_spec.options.fields);
    const nilx_spec: file.StatusExtendedSpec = comptime spec.add(statx_spec, .{ .options = .{ .fields = builtin.zero(Fields) } });
    var st: file.StatusExtended = try meta.wrap(file.getStatusExtended(nilx_spec, 0, "/home"));
    _ = st;
}
pub fn testCopyFileRange() !void {
    testing.announce(@src());
    const src_fd: usize = try meta.wrap(file.create(create_spec, pathname1, file.mode.regular));
    const dest_fd: usize = try meta.wrap(file.create(create_spec, pathname2, file.mode.regular));
    var rng: file.DeviceRandomBytes(65536) = .{};
    try meta.wrap(file.write(write_spec, src_fd, &rng.readCount(u8, 65536)));
    debug.assertEqual(u64, 0, try meta.wrap(file.seek(seek_spec, src_fd, 0, .set)));
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
pub fn testFileOperationsRound1() !void {
    testing.announce(@src());
    var buf: [4096]u8 = undefined;
    _ = try file.getCwd(.{}, &buf);
    try meta.wrap(file.makeDir(make_dir_spec, test_dir ++ "file_test", file.mode.directory));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    const src_fd: usize = try meta.wrap(file.create(create_spec, test_dir ++ "file_test1", file.mode.regular));
    const dest_fd: usize = try meta.wrap(file.create(create_spec, test_dir ++ "file_test2", file.mode.regular));
    try meta.wrap(file.close(close_spec, dest_fd));
    try meta.wrap(file.close(close_spec, src_fd));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test1"));
    try meta.wrap(file.unlink(unlink_spec, test_dir ++ "file_test2"));
}
pub fn testSocketOpenAndClose() !void {
    testing.announce(@src());
    const unix_tcp_fd: usize = try file.socket(.{}, .unix, .tcp, .ip);
    const unix_udp_fd: usize = try file.socket(.{}, .unix, .udp, .ip);
    const ipv6_udp_fd: usize = try file.socket(.{}, .ipv6, .udp, .ip);
    const ipv6_tcp_fd: usize = try file.socket(.{}, .ipv6, .tcp, .ip);
    const ipv4_udp_fd: usize = try file.socket(.{}, .ipv4, .udp, .ip);
    const ipv4_tcp_fd: usize = try file.socket(.{}, .ipv4, .tcp, .ip);
    try file.close(.{}, ipv4_tcp_fd);
    try file.close(.{}, ipv4_udp_fd);
    try file.close(.{}, ipv6_tcp_fd);
    try file.close(.{}, ipv6_udp_fd);
    try file.close(.{}, unix_udp_fd);
    try file.close(.{}, unix_tcp_fd);
}
pub fn testClientIPv4(args: [][*:0]u8) !void {
    testing.announce(@src());
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: usize = try file.socket(.{ .options = .{ .non_block = false } }, .ipv4, .udp, .ip);
    try file.connect(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    try file.write(.{}, fd, meta.manyToSlice(args[0]));
    const len: u64 = try file.read(.{ .return_type = u64 }, fd, &buf);
    debug.write(comptime fmt.about("ipv4") ++ "server responds: ");
    debug.write(buf[0..len]);
    debug.write("\n");
}
pub fn testServerIPv4() !void {
    testing.announce(@src());
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: usize = try file.socket(.{ .options = .{ .non_block = false } }, .ipv4, .udp, .udp);
    try file.bind(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: file.Socket.Address = undefined;
    var sender_addrlen: u32 = 16;
    const len: u64 = try file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
pub fn testClientIPv6(args: [][*:0]u8) !void {
    testing.announce(@src());
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: usize = try file.socket(.{ .options = .{ .non_block = false } }, .ipv6, .udp, .ip);
    try file.connect(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    try file.write(.{}, fd, meta.manyToSlice(args[0]));
    const len: u64 = try file.read(.{ .return_type = u64 }, fd, &buf);
    debug.write(comptime fmt.about("ipv6") ++ "server responds: ");
    debug.write(buf[0..len]);
    debug.write("\n");
}
pub fn testServerIPv6() !void {
    testing.announce(@src());
    var addrinfo: file.Socket.Address = file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: usize = try file.socket(.{ .options = .{ .non_block = false } }, .ipv6, .udp, .udp);
    try file.bind(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: file.Socket.Address = undefined;
    var sender_addrlen: u32 = 28;
    const len: u64 = try file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
pub fn testClientAndServerIPv4(args: [][*:0]u8) !void {
    testing.announce(@src());
    if (try proc.fork(.{}) == 0) {
        try testServerIPv4();
        proc.exit(0);
    }
    try time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv4(args);
}
pub fn testClientAndServerIPv6(args: [][*:0]u8) !void {
    testing.announce(@src());
    if (try proc.fork(.{}) == 0) {
        try testServerIPv6();
        proc.exit(0);
    }
    try time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv6(args);
}
fn testPathAssert(path: [:0]const u8) !void {
    testing.announce(@src());
    try file.pathAssert(stat_spec, path, .directory);
}
fn testPathIs(path: [:0]const u8) !void {
    testing.announce(@src());
    try debug.expect(try file.pathIs(stat_spec, path, .directory));
}
fn testPathIsNot(path: [:0]const u8) !void {
    testing.announce(@src());
    try debug.expect(try file.pathIsNot(stat_spec, path, .regular));
    try debug.expect(try file.pathIsNot(stat_spec, path, .block_special));
    try debug.expect(try file.pathIsNot(stat_spec, path, .named_pipe));
    try debug.expect(try file.pathIsNot(stat_spec, path, .socket));
    try debug.expect(try file.pathIsNot(stat_spec, path, .symbolic_link));
}
fn testFileIs(fd: usize) !void {
    testing.announce(@src());
    try debug.expect(try file.is(stat_spec, fd, .directory));
}
fn testFileIsNot(fd: usize) !void {
    testing.announce(@src());
    try debug.expect(try file.isNot(stat_spec, .regular, fd));
    try debug.expect(try file.isNot(stat_spec, .block_special, fd));
    try debug.expect(try file.isNot(stat_spec, .named_pipe, fd));
    try debug.expect(try file.isNot(stat_spec, .socket, fd));
    try debug.expect(try file.isNot(stat_spec, .symbolic_link, fd));
}
pub fn testFileTests() !void {
    const path: [:0]const u8 = test_dir ++ "file_test";
    testing.announce(@src());
    try file.makeDir(make_dir_spec, path, file.mode.directory);
    try testPathAssert(path);
    try testPathIs(path);
    try testPathIsNot(path);
    const fd: usize = try file.open(open_dir_spec, .{}, path);
    try testFileIs(fd);
    try testFileIsNot(fd);
    try file.close(close_spec, fd);
    try file.removeDir(remove_dir_spec, path);
}
fn testMakeDir() !void {
    testing.announce(@src());
    try meta.wrap(file.makeDir(make_dir_spec, test_dir ++ "file_test", file.mode.directory));
}
fn testMakeDirAt(dir_fd: usize) !void {
    testing.announce(@src());
    try file.makeDirAt(make_dir_spec, dir_fd, "file_test", file.mode.directory);
}
fn testPath() !void {
    testing.announce(@src());
    var path_dir_fd: usize = try file.path(path_spec, test_dir ++ "file_test/file_test");
    try file.close(close_spec, path_dir_fd);
}
fn testPathAt(dir_fd: usize) !u64 {
    testing.announce(@src());
    return file.pathAt(path_spec, dir_fd, "file_test");
}
fn testCreate() !void {
    testing.announce(@src());
    const fd: usize = try file.create(create_spec, test_dir ++ "file_test/file_test/file_test", file.mode.regular);
    try file.close(close_spec, fd);
}
fn testPathRegular() !void {
    testing.announce(@src());
    const path_reg_fd: usize = try meta.wrap(file.path(file_path_spec, test_dir ++ "file_test/file_test/file_test"));
    try file.assertNot(stat_spec, path_reg_fd, .unknown);
    try file.assert(stat_spec, path_reg_fd, .regular);
    try meta.wrap(file.close(close_spec, path_reg_fd));
}
fn testMakeNode() !void {
    testing.announce(@src());
    try file.makeNode(make_node_spec, test_dir ++ "file_test/regular", .{}, .{});
    try file.unlink(unlink_spec, test_dir ++ "file_test/regular");
    try file.makeNode(make_node_spec, test_dir ++ "file_test/fifo", .{ .kind = .named_pipe }, .{});
    try file.unlink(unlink_spec, test_dir ++ "file_test/fifo");
}
fn testFileOperationsRound2() !void {
    testing.announce(@src());
    try testMakeDir();
    const dir_fd: usize = try file.open(open_dir_spec, .{ .directory = true }, test_dir ++ "file_test");
    try testMakeDirAt(dir_fd);
    try testPath();
    var path_dir_fd: usize = try testPathAt(dir_fd);
    try testCreate();
    try testPathRegular();
    try testMakeNode();
    const new_in_fd: usize = try file.duplicate(.{}, 0);
    try file.duplicateTo(.{}, new_in_fd, new_in_fd +% 1);
    try meta.wrap(file.unlinkAt(unlink_spec, path_dir_fd, "file_test"));
    try meta.wrap(file.close(close_spec, path_dir_fd));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test"));
    try meta.wrap(file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    try meta.wrap(file.close(close_spec, dir_fd));
    const mem_fd: usize = try meta.wrap(mem.fd(.{}, "buffer"));
    try meta.wrap(file.truncate(ftruncate_spec, mem_fd, 4096));
}
fn testPathOperations() !void {
    testing.announce(@src());
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename(test_dir ++ "file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file_test", file.basename("1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "file", file.basename("file")));
    try meta.wrap(testing.expectEqualMany(u8, "/run/user/1000", file.dirname("/run/user/1000/file_test")));
    try meta.wrap(testing.expectEqualMany(u8, "////run/user/1000//", file.dirname("////run/user/1000///file_test///")));
    try file.makePath(make_path_spec, @import("root").build_root ++ "/zig-out/bin/something/here", file.mode.directory);
    try file.removeDir(remove_dir_spec, @import("root").build_root ++ "/zig-out/bin/something/here");
    try file.removeDir(remove_dir_spec, @import("root").build_root ++ "/zig-out/bin/something");

    try debug.expectEqual(usize, file.RealPath.countPathElements("///run/user//../.1000"), 2);
    try debug.expectEqual(usize, file.RealPath.countPathElements("/run//user/.././1000"), 2);
    try debug.expectEqual(usize, file.RealPath.countPathElements("./1234"), 1);

    var buf: [4096]u8 = undefined;
    try meta.wrap(testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("/run///user/..//./1000", &buf)], "/run/1000"));
    try meta.wrap(testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("/1000", &buf)], "/1000"));
    try meta.wrap(testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("./1000", &buf)], "1000"));
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
    var fd: usize = try meta.wrap(file.create(create_spec, "./0123456789", mode));
    try file.close(close_spec, fd);
    fd = try file.open(open_spec, "./0123456789");
    const st: file.Status = try file.getStatus(stat_spec, fd);
    try file.unlink(unlink_spec, "./0123456789");
    try debug.expectEqual(u16, int, @as(u16, @bitCast(st.mode)));
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
        proc.exit(0);
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
    testing.announce(@src());
    const fd: usize = try file.create(create_spec, test_dir ++ "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.link(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try file.unlink(unlink_spec, test_dir ++ "file_test");
    try file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testSymbolicLink() !void {
    testing.announce(@src());
    const fd: usize = try file.create(create_spec, test_dir ++ "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.symbolicLink(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try file.unlink(unlink_spec, test_dir ++ "file_test");
    try file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testLinkAt() !void {
    testing.announce(@src());
    const dir_fd: usize = try file.path(path_spec, test_dir);
    const fd: usize = try file.createAt(create_spec, dir_fd, "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.linkAt(link_spec, dir_fd, "file_test", dir_fd, "file_test_link");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try file.close(close_spec, dir_fd);
}
fn testSymbolicLinkAt() !void {
    testing.announce(@src());
    const dir_fd: usize = try file.path(path_spec, test_dir);
    const fd: usize = try file.createAt(create_spec, dir_fd, "file_test", file.mode.regular);
    try file.close(close_spec, fd);
    try file.symbolicLinkAt(link_spec, test_dir ++ "file_test", dir_fd, "file_test_link");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try file.close(close_spec, dir_fd);
}
fn testPreClean() !void {
    testing.announce(@src());
    file.unlink(unlink_spec, test_dir ++ "file_test1") catch {};
    file.unlink(unlink_spec, test_dir ++ "file_test2") catch {};
    file.unlink(unlink_spec, test_dir ++ "file_test/file_test/file_test") catch {};
    file.unlink(unlink_spec, test_dir ++ "file_test") catch {};
    file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test") catch {};
    file.removeDir(remove_dir_spec, test_dir ++ "file_test") catch {};
}
fn testBasicDirectoryIterator() !void {
    const AddressSpace = spec.address_space.exact_8;
    const Allocator = mem.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    const DirStream = file.GenericDirStream(.{
        .Allocator = Allocator,
    });
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var dir: DirStream = try DirStream.initAt(&allocator, null, ".");
    var list: DirStream.ListView = dir.list();
    while (list.next()) |next| : (list = next) {
        _ = list.this();
    }
}
fn testSampleReports() void {
    testing.announce(@src());
    file.about.sampleAllReports();
}
pub fn main(args: [][*:0]u8) !void {
    try meta.wrap(testPreClean());
    try meta.wrap(testBasicDirectoryIterator());
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
    try meta.wrap(testSampleReports());
}
