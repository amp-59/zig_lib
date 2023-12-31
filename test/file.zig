const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

pub const AbsoluteState = struct {
    home: [:0]u8,
    cwd: [:0]u8,
    proj: [:0]u8,
    pid: u16,
};

pub const runtime_assertions: bool = true;
pub const logging_default: zl.debug.Logging.Default = zl.debug.spec.logging.default.verbose;
const getcwd_spec: zl.file.GetWorkingDirectorySpec = .{};
const make_dir_spec: zl.file.MakeDirSpec = .{};
const make_node_spec: zl.file.MakeNodeSpec = .{};
const seek_spec: zl.file.SeekSpec = .{};
const create_spec: zl.file.CreateSpec = .{};
const path_spec: zl.file.PathSpec = .{};
const file_path_spec: zl.file.PathSpec = .{};
const link_spec: zl.file.LinkSpec = .{};
const copy_spec: zl.file.CopySpec = .{};
const send_spec: zl.file.SendSpec = .{};
const open_spec: zl.file.OpenSpec = .{};
const open_dir_spec: zl.file.OpenSpec = .{};
const remove_dir_spec: zl.file.RemoveDirSpec = .{};
const unlink_spec: zl.file.UnlinkSpec = .{};
const close_spec: zl.file.CloseSpec = .{};
const stat_spec: zl.file.StatusSpec = .{};
const statx_spec: zl.file.StatusExtendedSpec = .{
    .options = .{ .fields = .{} },
};
const ftruncate_spec: zl.file.TruncateSpec = .{};
const truncate_spec: zl.file.TruncateSpec = .{};
const make_path_spec: zl.file.MakePathSpec = .{
    .errors = .{},
    .logging = .{},
};
const read_spec: zl.file.ReadSpec = .{};
const read2_spec: zl.file.Read2Spec = .{};
const write_spec: zl.file.WriteSpec = .{};
const pipe_spec: zl.file.MakePipeSpec = .{
    .options = .{ .close_on_exec = false },
};

const poll_spec: zl.file.PollSpec = .{
    .errors = .{ .throw = zl.file.spec.poll.errors.all },
};

const create_options = .{ .read_write = true, .append = false };
const path_options = .{ .directory = true, .path = true };

fn testPoll() !void {
    var pollfds: [3]zl.file.PollFd = .{
        .{ .fd = 0, .expect = .{ .input = true } },
        .{ .fd = 1, .expect = .{ .output = true } },
        .{ .fd = 2, .expect = .{ .output = true } },
    };
    try zl.file.poll(poll_spec, &pollfds, 100);
}

const file_name: [:0]const u8 = "file_test";
const test_dir: [:0]const u8 = @import("root").build_root ++ "/test/";
const pathname1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname2: [:0]const u8 = test_dir ++ file_name ++ "2";
const pathname_link1: [:0]const u8 = test_dir ++ file_name ++ "1";
const pathname_link2: [:0]const u8 = test_dir ++ file_name ++ "2";

fn testCopyFileRange() !void {
    zl.testing.announce(@src());
    const src_fd: usize = try zl.meta.wrap(zl.file.create(create_spec, create_options, pathname1, zl.file.mode.regular));
    const dest_fd: usize = try zl.meta.wrap(zl.file.create(create_spec, create_options, pathname2, zl.file.mode.regular));
    var rng: zl.file.DeviceRandomBytes(65536) = .{};
    try zl.meta.wrap(zl.file.write(write_spec, src_fd, &rng.readCount(u8, 65536)));
    zl.debug.assertEqual(u64, 0, try zl.meta.wrap(zl.file.seek(seek_spec, src_fd, 0, .set)));
    var src_off: u64 = 4096;
    var dest_off: u64 = 0;
    _ = try zl.meta.wrap(zl.file.copy(copy_spec, dest_fd, &dest_off, src_fd, &src_off, 65536));
    _ = try zl.meta.wrap(zl.file.send(send_spec, dest_fd, src_fd, null, 65536));
    _ = try zl.meta.wrap(zl.file.sync(.{}, dest_fd));
    try zl.meta.wrap(zl.file.close(close_spec, dest_fd));
    try zl.meta.wrap(zl.file.close(close_spec, src_fd));
    try zl.meta.wrap(zl.file.unlink(unlink_spec, test_dir ++ "file_test1"));
    try zl.meta.wrap(zl.file.unlink(unlink_spec, test_dir ++ "file_test2"));
}
fn testFileOperationsRound1() !void {
    zl.testing.announce(@src());
    var buf: [4096]u8 = undefined;
    _ = try zl.file.getCwd(.{}, &buf);
    try zl.meta.wrap(zl.file.makeDir(make_dir_spec, test_dir ++ "file_test", zl.file.mode.directory));
    try zl.meta.wrap(zl.file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    const src_fd: usize = try zl.meta.wrap(zl.file.create(create_spec, create_options, test_dir ++ "file_test1", zl.file.mode.regular));
    const dest_fd: usize = try zl.meta.wrap(zl.file.create(create_spec, create_options, test_dir ++ "file_test2", zl.file.mode.regular));
    try zl.meta.wrap(zl.file.close(close_spec, dest_fd));
    try zl.meta.wrap(zl.file.close(close_spec, src_fd));
    try zl.meta.wrap(zl.file.unlink(unlink_spec, test_dir ++ "file_test1"));
    try zl.meta.wrap(zl.file.unlink(unlink_spec, test_dir ++ "file_test2"));
}
fn testSocketOpenAndClose() !void {
    zl.testing.announce(@src());
    const unix_tcp_fd: usize = try zl.file.socket(.{}, .unix, .{ .conn = .tcp }, .ip);
    const unix_udp_fd: usize = try zl.file.socket(.{}, .unix, .{ .conn = .udp }, .ip);
    const ipv6_udp_fd: usize = try zl.file.socket(.{}, .ipv6, .{ .conn = .udp }, .ip);
    const ipv6_tcp_fd: usize = try zl.file.socket(.{}, .ipv6, .{ .conn = .tcp }, .ip);
    const ipv4_udp_fd: usize = try zl.file.socket(.{}, .ipv4, .{ .conn = .udp }, .ip);
    const ipv4_tcp_fd: usize = try zl.file.socket(.{}, .ipv4, .{ .conn = .tcp }, .ip);
    try zl.file.close(.{}, ipv4_tcp_fd);
    try zl.file.close(.{}, ipv4_udp_fd);
    try zl.file.close(.{}, ipv6_tcp_fd);
    try zl.file.close(.{}, ipv6_udp_fd);
    try zl.file.close(.{}, unix_udp_fd);
    try zl.file.close(.{}, unix_tcp_fd);
}
fn testClientIPv4(args: [][*:0]u8) !void {
    zl.testing.announce(@src());
    var addrinfo: zl.file.Socket.Address = zl.file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: usize = try zl.file.socket(.{}, .ipv4, .{ .conn = .udp }, .ip);
    try zl.file.connect(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    try zl.file.write(.{}, fd, zl.meta.manyToSlice(args[0]));
    const len: u64 = try zl.file.read(.{ .return_type = u64 }, fd, &buf);
    zl.debug.write(zl.fmt.about("ipv4") ++ "server responds: ");
    zl.debug.write(buf[0..len]);
    zl.debug.write("\n");
}
fn testServerIPv4() !void {
    zl.testing.announce(@src());
    var addrinfo: zl.file.Socket.Address = zl.file.Socket.AddressIPv4.create(55478, .{ 127, 0, 0, 1 });
    const fd: usize = try zl.file.socket(.{}, .ipv4, .{ .conn = .udp }, .udp);
    try zl.file.bind(.{}, fd, &addrinfo, 16);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: zl.file.Socket.Address = undefined;
    var sender_addrlen: u32 = 16;
    const len: u64 = try zl.file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try zl.file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
fn testClientIPv6(args: [][*:0]u8) !void {
    zl.testing.announce(@src());
    var addrinfo: zl.file.Socket.Address = zl.file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: usize = try zl.file.socket(.{}, .ipv6, .{ .conn = .udp }, .ip);
    try zl.file.connect(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    try zl.file.write(.{}, fd, zl.meta.manyToSlice(args[0]));
    const len: u64 = try zl.file.read(.{ .return_type = u64 }, fd, &buf);
    zl.debug.write(zl.fmt.about("ipv6") ++ "server responds: ");
    zl.debug.write(buf[0..len]);
    zl.debug.write("\n");
}
fn testServerIPv6() !void {
    zl.testing.announce(@src());
    var addrinfo: zl.file.Socket.Address = zl.file.Socket.AddressIPv6.create(55480, 0, .{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0);
    const fd: usize = try zl.file.socket(.{}, .ipv6, .{ .conn = .udp }, .udp);
    try zl.file.bind(.{}, fd, &addrinfo, 28);
    var buf: [500]u8 = undefined;
    var sender_addrinfo: zl.file.Socket.Address = undefined;
    var sender_addrlen: u32 = 28;
    const len: u64 = try zl.file.receiveFrom(.{}, fd, &buf, 0, &sender_addrinfo, &sender_addrlen);
    try zl.file.sendTo(.{ .return_type = void }, fd, buf[0..len], 0, &sender_addrinfo, sender_addrlen);
}
fn testClientAndServerIPv4(args: [][*:0]u8) !void {
    zl.testing.announce(@src());
    if (try zl.proc.fork(.{}) == 0) {
        try testServerIPv4();
        zl.proc.exit(0);
    }
    try zl.time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv4(args);
}
fn testClientAndServerIPv6(args: [][*:0]u8) !void {
    zl.testing.announce(@src());
    if (try zl.proc.fork(.{}) == 0) {
        try testServerIPv6();
        zl.proc.exit(0);
    }
    try zl.time.sleep(.{}, .{ .nsec = 50000 });
    try testClientIPv6(args);
}
fn testPathAssert(path: [:0]const u8) !void {
    zl.testing.announce(@src());
    try zl.file.pathAssert(stat_spec, path, .directory);
}
fn testPathIs(path: [:0]const u8) !void {
    zl.testing.announce(@src());
    try zl.debug.expect(try zl.file.pathIs(stat_spec, path, .directory));
}
fn testPathIsNot(path: [:0]const u8) !void {
    zl.testing.announce(@src());
    try zl.debug.expect(try zl.file.pathIsNot(stat_spec, path, .regular));
    try zl.debug.expect(try zl.file.pathIsNot(stat_spec, path, .block_special));
    try zl.debug.expect(try zl.file.pathIsNot(stat_spec, path, .named_pipe));
    try zl.debug.expect(try zl.file.pathIsNot(stat_spec, path, .socket));
    try zl.debug.expect(try zl.file.pathIsNot(stat_spec, path, .symbolic_link));
}
fn testFileIs(fd: usize) !void {
    zl.testing.announce(@src());
    try zl.debug.expect(try zl.file.is(stat_spec, fd, .directory));
}
fn testFileIsNot(fd: usize) !void {
    zl.testing.announce(@src());
    try zl.debug.expect(try zl.file.isNot(stat_spec, .regular, fd));
    try zl.debug.expect(try zl.file.isNot(stat_spec, .block_special, fd));
    try zl.debug.expect(try zl.file.isNot(stat_spec, .named_pipe, fd));
    try zl.debug.expect(try zl.file.isNot(stat_spec, .socket, fd));
    try zl.debug.expect(try zl.file.isNot(stat_spec, .symbolic_link, fd));
}
fn testFileTests() !void {
    const path: [:0]const u8 = test_dir ++ "file_test";
    zl.testing.announce(@src());
    try zl.file.makeDir(make_dir_spec, path, zl.file.mode.directory);
    try testPathAssert(path);
    try testPathIs(path);
    try testPathIsNot(path);
    const fd: usize = try zl.file.open(open_dir_spec, .{}, path);
    try testFileIs(fd);
    try testFileIsNot(fd);
    try zl.file.close(close_spec, fd);
    try zl.file.removeDir(remove_dir_spec, path);
}
fn testMakeDir() !void {
    zl.testing.announce(@src());
    try zl.meta.wrap(zl.file.makeDir(make_dir_spec, test_dir ++ "file_test", zl.file.mode.directory));
}
fn testMakeDirAt(dir_fd: usize) !void {
    zl.testing.announce(@src());
    try zl.file.makeDirAt(make_dir_spec, dir_fd, "file_test", zl.file.mode.directory);
}
fn testPath() !void {
    zl.testing.announce(@src());
    const path_dir_fd: usize = try zl.file.path(path_spec, path_options, test_dir ++ "file_test/file_test");
    try zl.file.close(close_spec, path_dir_fd);
}
fn testPathAt(dir_fd: usize) !u64 {
    zl.testing.announce(@src());
    return zl.file.pathAt(path_spec, path_options, dir_fd, "file_test");
}
fn testCreate() !void {
    zl.testing.announce(@src());
    const fd: usize = try zl.file.create(create_spec, create_options, test_dir ++ "file_test/file_test/file_test", zl.file.mode.regular);
    try zl.file.close(close_spec, fd);
}
fn testPathRegular() !void {
    zl.testing.announce(@src());
    const path_reg_fd: usize = try zl.meta.wrap(zl.file.path(file_path_spec, .{}, test_dir ++ "file_test/file_test/file_test"));
    try zl.file.assertNot(stat_spec, path_reg_fd, .unknown);
    try zl.file.assert(stat_spec, path_reg_fd, .regular);
    try zl.meta.wrap(zl.file.close(close_spec, path_reg_fd));
}
fn testMakeNode() !void {
    zl.testing.announce(@src());
    try zl.file.makeNode(make_node_spec, test_dir ++ "file_test/regular", .{}, .{});
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test/regular");
    try zl.file.makeNode(make_node_spec, test_dir ++ "file_test/fifo", .{ .kind = .named_pipe }, .{});
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test/fifo");
}
fn testFileOperationsRound2() !void {
    zl.testing.announce(@src());
    try testMakeDir();
    const dir_fd: usize = try zl.file.open(open_dir_spec, .{ .directory = true }, test_dir ++ "file_test");
    try testMakeDirAt(dir_fd);
    try testPath();
    const path_dir_fd: usize = try testPathAt(dir_fd);
    try testCreate();
    try testPathRegular();
    try testMakeNode();
    const new_in_fd: usize = try zl.file.duplicate(.{}, 0);
    try zl.file.duplicateTo(.{}, @bitCast(@as(usize, 0)), new_in_fd, new_in_fd +% 1);
    try zl.meta.wrap(zl.file.unlinkAt(unlink_spec, path_dir_fd, "file_test"));
    try zl.meta.wrap(zl.file.close(close_spec, path_dir_fd));
    try zl.meta.wrap(zl.file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test"));
    try zl.meta.wrap(zl.file.removeDir(remove_dir_spec, test_dir ++ "file_test"));
    try zl.meta.wrap(zl.file.close(close_spec, dir_fd));
    const mem_fd: usize = try zl.meta.wrap(zl.mem.fd(.{}, .{}, "buffer"));
    try zl.meta.wrap(zl.file.truncate(ftruncate_spec, mem_fd, 4096));
}
fn testPathOperations() !void {
    zl.testing.announce(@src());
    try zl.meta.wrap(zl.testing.expectEqualMany(u8, "file_test", zl.file.basename(test_dir ++ "file_test")));
    try zl.meta.wrap(zl.testing.expectEqualMany(u8, "file_test", zl.file.basename("1000/file_test")));
    try zl.meta.wrap(zl.testing.expectEqualMany(u8, "file", zl.file.basename("file")));
    try zl.meta.wrap(zl.testing.expectEqualMany(u8, "/run/user/1000", zl.file.dirname("/run/user/1000/file_test")));
    try zl.meta.wrap(zl.testing.expectEqualMany(u8, "////run/user/1000//", zl.file.dirname("////run/user/1000///file_test///")));

    try zl.file.makePath(make_path_spec, @import("root").build_root ++ "/zig-out/bin/something/here", zl.file.mode.directory);
    try zl.file.removeDir(remove_dir_spec, @import("root").build_root ++ "/zig-out/bin/something/here");
    try zl.file.removeDir(remove_dir_spec, @import("root").build_root ++ "/zig-out/bin/something");

    //try zl.debug.expectEqual(usize, zl.file.RealPath.countPathElements("///run/user//../.1000"), 2);
    //try zl.debug.expectEqual(usize, zl.file.RealPath.countPathElements("/run//user/.././1000"), 2);
    //try zl.debug.expectEqual(usize, zl.file.RealPath.countPathElements("./1234"), 1);

    //var buf: [4096]u8 = undefined;
    //try zl.meta.wrap(zl.testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("/run///user/..//./1000", &buf)], "/run/1000"));
    //try zl.meta.wrap(zl.testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("/1000", &buf)], "/1000"));
    //try zl.meta.wrap(zl.testing.expectEqualMany(u8, buf[0..file.RealPath.writePathElements("./1000", &buf)], "1000"));
}
fn testPackedModeStruct() !void {
    const mode: zl.file.Mode = .{
        .owner = .{ .read = true, .write = true, .execute = false },
        .group = .{ .read = true, .write = true, .execute = false },
        .other = .{ .read = true, .write = true, .execute = false },
        .set_uid = false,
        .set_gid = false,
        .sticky = false,
        .kind = .regular,
    };
    const int: u16 = zl.meta.leastBitCast(mode);
    var fd: usize = try zl.meta.wrap(zl.file.create(create_spec, create_options, "./0123456789", mode));
    try zl.file.close(close_spec, fd);
    fd = try zl.file.open(open_spec, "./0123456789");
    const st: zl.file.Status = try zl.file.getStatus(stat_spec, fd);
    try zl.file.unlink(unlink_spec, "./0123456789");
    try zl.debug.expectEqual(u16, int, @as(u16, @bitCast(st.mode)));
}
fn testLink() !void {
    zl.testing.announce(@src());
    const fd: usize = try zl.file.create(create_spec, create_options, test_dir ++ "file_test", zl.file.mode.regular);
    try zl.file.close(close_spec, fd);
    try zl.file.link(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test");
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testSymbolicLink() !void {
    zl.testing.announce(@src());
    const fd: usize = try zl.file.create(create_spec, create_options, test_dir ++ "file_test", zl.file.mode.regular);
    try zl.file.close(close_spec, fd);
    try zl.file.symbolicLink(link_spec, test_dir ++ "file_test", test_dir ++ "file_test_link");
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test");
    try zl.file.unlink(unlink_spec, test_dir ++ "file_test_link");
}
fn testLinkAt() !void {
    zl.testing.announce(@src());
    const dir_fd: usize = try zl.file.path(path_spec, path_options, test_dir);
    const fd: usize = try zl.file.createAt(create_spec, create_options, dir_fd, "file_test", zl.file.mode.regular);
    try zl.file.close(close_spec, fd);
    try zl.file.linkAt(link_spec, .{}, dir_fd, "file_test", dir_fd, "file_test_link");
    try zl.file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try zl.file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try zl.file.close(close_spec, dir_fd);
}
fn testSymbolicLinkAt() !void {
    zl.testing.announce(@src());
    const dir_fd: usize = try zl.file.path(path_spec, path_options, test_dir);
    const fd: usize = try zl.file.createAt(create_spec, create_options, dir_fd, "file_test", zl.file.mode.regular);
    try zl.file.close(close_spec, fd);
    try zl.file.symbolicLinkAt(link_spec, test_dir ++ "file_test", dir_fd, "file_test_link");
    try zl.file.unlinkAt(unlink_spec, dir_fd, "file_test");
    try zl.file.unlinkAt(unlink_spec, dir_fd, "file_test_link");
    try zl.file.close(close_spec, dir_fd);
}
fn testPreClean() !void {
    zl.testing.announce(@src());
    zl.file.unlink(unlink_spec, test_dir ++ "file_test1") catch {};
    zl.file.unlink(unlink_spec, test_dir ++ "file_test2") catch {};
    zl.file.unlink(unlink_spec, test_dir ++ "file_test/file_test/file_test") catch {};
    zl.file.unlink(unlink_spec, test_dir ++ "file_test") catch {};
    zl.file.removeDir(remove_dir_spec, test_dir ++ "file_test/file_test") catch {};
    zl.file.removeDir(remove_dir_spec, test_dir ++ "file_test") catch {};
}
fn testBasicDirectoryIterator() !void {
    const AddressSpace = zl.mem.spec.address_space.exact_8;
    const Allocator = zl.mem.dynamic.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    const DirStream = zl.file.GenericDirStream(.{
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
    zl.testing.announce(@src());
    zl.file.about.sampleAllReports();
}
fn testReadWrite2() !void {
    var buf1: [1]u8 = undefined;
    var buf2: [1]u8 = undefined;
    var buf3: [1]u8 = undefined;
    var buf4: [1]u8 = undefined;
    var buf5: [1]u8 = undefined;
    var buf: [5][]u8 = .{ &buf1, &buf2, &buf3, &buf4, &buf5 };
    const fd: usize = try zl.file.create(create_spec, .{ .read_write = true }, test_dir ++ "file_test1", zl.file.mode.regular);
    try zl.file.write2(write_spec, .{}, fd, @ptrCast(&[_][]const u8{ "1", "2", "3", "4", "5" }), 0);
    const len: usize = try zl.file.read2(read2_spec, .{ .high_priority = true }, fd, @ptrCast(&buf), 0);
    try zl.debug.expectEqual(usize, 5, len);
}
pub fn main() !void {
    zl.meta.refAllDecls(zl.file, &.{});
    try zl.meta.wrap(testPreClean());
    try zl.meta.wrap(testBasicDirectoryIterator());
    try zl.meta.wrap(testFileOperationsRound1());
    try zl.meta.wrap(testFileOperationsRound2());
    try zl.meta.wrap(testSocketOpenAndClose());
    try zl.meta.wrap(testFileTests());
    try zl.meta.wrap(testPoll());
    try zl.meta.wrap(testPathOperations());
    //try zl.meta.wrap(testClientAndServerIPv4(args));
    //try zl.meta.wrap(testClientAndServerIPv6(args));
    try zl.meta.wrap(testCopyFileRange());
    try zl.meta.wrap(testLink());
    try zl.meta.wrap(testLinkAt());
    try zl.meta.wrap(testSymbolicLink());
    try zl.meta.wrap(testSymbolicLinkAt());
    try zl.meta.wrap(testSampleReports());
    try zl.meta.wrap(testReadWrite2());
}
