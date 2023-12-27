const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;
pub const logging_default: zl.debug.Logging.Default = .{
    .Attempt = true,
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
pub const runtime_assertions: bool = true;

fn testBasicMetaFunctions() !void {
    try zl.debug.expect(zl.meta.isEnum(enum { e }));
    try zl.debug.expect(zl.meta.isContainer(struct {}));
    try zl.debug.expect(zl.meta.isContainer(packed struct {}));
    try zl.debug.expect(zl.meta.isContainer(packed struct(u32) { _: u32 }));
    try zl.debug.expect(zl.meta.isContainer(extern struct {}));
    try zl.debug.expect(zl.meta.isContainer(union {}));
    try zl.debug.expect(zl.meta.isContainer(extern union {}));
    try zl.debug.expect(zl.meta.isContainer(packed union {}));
    try zl.debug.expect(zl.meta.isTag(@TypeOf(.LiterallyATag)));
    try zl.debug.expect(zl.meta.isTag(@TypeOf(enum { ASymbolicKindOfTag }.ASymbolicKindOfTag)));
    try zl.debug.expect(zl.meta.isTag(@TypeOf(struct {})));
    try zl.debug.expect(zl.meta.isFunction(@TypeOf(main)));
    try zl.debug.expect(zl.meta.isFunction(@TypeOf(struct {
        fn other(_: *@This()) void {}
    }.other)));
    try zl.debug.expect(0 == zl.meta.sentinel([:0]u8).?);
    const E = zl.meta.tagNamesEnum(&.{ "one", "two", "three" });
    try zl.debug.expect(@hasField(E, "one"));
    try zl.debug.expect(@hasField(E, "two"));
    try zl.debug.expect(@hasField(E, "three"));
}
fn testAlignmentMetaFunctions() !void {
    try zl.debug.expect(32 == comptime zl.meta.signedRealBitSize(-964392));
    try zl.debug.expect(8 == comptime zl.meta.signedRealBitSize(-128));
    try zl.debug.expect(16 == comptime zl.meta.signedRealBitSize(-129));
    try zl.debug.expect(8 == zl.meta.alignBitSizeOfBelow(u9));
    try zl.debug.expect(8 == zl.meta.alignBitSizeOfAbove(u7));
    try zl.debug.expect(u8 == zl.meta.AlignBitSizeBelow(u9));
    try zl.debug.expect(u8 == zl.meta.AlignBitSizeAbove(u7));
}
fn testBitCastMetaFunctions() !void {
    const S = packed struct {
        x: u3,
        y: u6,
    };
    const s: S = .{ .x = 1, .y = 25 };
    try zl.debug.expect(u9 == @TypeOf(zl.meta.leastBitCast(s)));
    try zl.debug.expect(u16 == @TypeOf(zl.meta.leastRealBitCast(s)));
}
fn testMemoryMetaFunctions() !void {
    const Element = u3;
    const T = [16:0]Element;
    const E = zl.meta.Element(T);
    const U = zl.meta.ArrayPointerToSlice(*T);
    try zl.debug.expect([:0]Element == U);
    zl.debug.assertEqual(type, *T, zl.meta.SliceToArrayPointer(U, @typeInfo(T).Array.len));
    comptime var t: T = T{ 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 7, 0 };
    const u: U = &t;
    zl.debug.assertEqual(type, zl.meta.Element(T), E);
    zl.debug.assertEqual(type, zl.meta.Element(*T), E);
    for (zl.meta.arrayPointerToSlice(&t), 0..) |e, i| zl.debug.assertEqual(E, e, u[i]);
    for (zl.meta.sliceToArrayPointer(u), 0..) |e, i| zl.debug.assertEqual(E, e, t[i]);
    const m: [:0]Element = zl.meta.manyToSlice(u.ptr);
    zl.debug.assertEqual(u64, 4, m.len);
    try testInitializer();
}
fn testInitializer() !void {
    const T = struct { x: u64 = 0, y: u32 = 0, z: u16 = 0 };
    const c: []const zl.meta.Initializer = &zl.meta.initializers(T, .{ .x = 25, .y = 15 });
    const t: T = zl.meta.initialize(T, c);
    try zl.debug.expectEqual(T, t, .{ .x = 25, .y = 15 });
    zl.debug.expectEqual(T, t, .{ .x = 25, .y = 15 }) catch |err| {
        zl.debug.assertEqual(anyerror, error.UnexpectedValue, err);
    };
}
fn testGlobalVariables() !void {
    const gv: []const zl.meta.GlobalVariableDecl = zl.meta.globalVariables(zl.file.CompoundPath);
    try zl.debug.expectEqualMemory([]const u8, "home", gv[0].name);
    try zl.debug.expectEqualMemory([]const u8, "cwd", gv[1].name);
}
fn testIsValidEnum() !void {
    @setRuntimeSafety(false);
    const E = enum(u8) { A, B, C };
    var no: u8 = @intFromEnum(E.C);
    var tag: E = @enumFromInt(no);
    no = 8;
    try zl.debug.expect(zl.meta.isValidEnum(E, tag));
    tag = @enumFromInt(no);
    try zl.debug.expect(!zl.meta.isValidEnum(E, tag));
}
fn testIsValidError() !void {
    @setRuntimeSafety(false);
    const E = error{ A, B, C };
    var errno: u16 = @intFromError(error.A);
    var err: E = @errorCast(@errorFromInt(errno));
    errno += 4096;
    try zl.debug.expect(zl.meta.isValidErrorCode(E, err));
    err = @errorCast(@errorFromInt(errno));
    try zl.debug.expect(!zl.meta.isValidErrorCode(E, err));
}
pub fn main(_: anytype, _: [][*:0]u8) !void {
    zl.meta.refAllDecls(zl.meta, &.{});
    try testBasicMetaFunctions();
    try testBitCastMetaFunctions();
    try testAlignmentMetaFunctions();
    try testMemoryMetaFunctions();
    try testIsValidError();
    try testIsValidEnum();
}
