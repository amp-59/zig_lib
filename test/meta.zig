const zl = @import("../zig_lib.zig");
const gen = zl.gen;
const sys = zl.sys;
const meta = zl.meta;
const proc = zl.proc;
const debug = zl.debug;
const testing = zl.testing;
const builtin = zl.builtin;
pub usingnamespace zl.start;
pub const logging_default: debug.Logging.Default = .{
    .Attempt = true,
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
pub const runtime_assertions: bool = true;

fn testBasicMetaFunctions() !void {
    try debug.expect(meta.isEnum(enum { e }));
    try debug.expect(meta.isContainer(struct {}));
    try debug.expect(meta.isContainer(packed struct {}));
    try debug.expect(meta.isContainer(packed struct(u32) { _: u32 }));
    try debug.expect(meta.isContainer(extern struct {}));
    try debug.expect(meta.isContainer(union {}));
    try debug.expect(meta.isContainer(extern union {}));
    try debug.expect(meta.isContainer(packed union {}));
    try debug.expect(meta.isTag(@TypeOf(.LiterallyATag)));
    try debug.expect(meta.isTag(@TypeOf(enum { ASymbolicKindOfTag }.ASymbolicKindOfTag)));
    try debug.expect(meta.isTag(@TypeOf(struct {})));
    try debug.expect(meta.isFunction(@TypeOf(main)));
    try debug.expect(meta.isFunction(@TypeOf(struct {
        fn other(_: *@This()) void {}
    }.other)));
    try debug.expect(0 == meta.sentinel([:0]u8).?);
    const E = meta.tagNamesEnum(&.{ "one", "two", "three" });
    try debug.expect(@hasField(E, "one"));
    try debug.expect(@hasField(E, "two"));
    try debug.expect(@hasField(E, "three"));
}
fn testAlignmentMetaFunctions() !void {
    try debug.expect(32 == comptime meta.realBitSizeOf(-964392));
    try debug.expect(8 == comptime meta.realBitSizeOf(-128));
    try debug.expect(16 == comptime meta.realBitSizeOf(-129));
    try debug.expect(8 == meta.alignBitSizeOfBelow(u9));
    try debug.expect(8 == meta.alignBitSizeOfAbove(u7));
    try debug.expect(u8 == meta.AlignBitSizeBelow(u9));
    try debug.expect(u8 == meta.AlignBitSizeAbove(u7));
}
fn testBitCastMetaFunctions() !void {
    const S = packed struct {
        x: u3,
        y: u6,
    };
    var s: S = .{ .x = 1, .y = 25 };
    try debug.expect(u9 == @TypeOf(meta.leastBitCast(s)));
    try debug.expect(u16 == @TypeOf(meta.leastRealBitCast(s)));
}
fn testMemoryMetaFunctions() !void {
    const Element = u3;
    const T = [16:0]Element;
    const E = meta.Element(T);
    const U = meta.ArrayPointerToSlice(*T);
    try debug.expect([:0]Element == U);
    debug.assertEqual(type, *T, meta.SliceToArrayPointer(U, @typeInfo(T).Array.len));
    comptime var t: T = T{ 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 7, 0 };
    comptime var u: U = &t;
    debug.assertEqual(type, meta.Element(T), E);
    debug.assertEqual(type, meta.Element(*T), E);
    for (meta.arrayPointerToSlice(&t), 0..) |e, i| debug.assertEqual(E, e, u[i]);
    for (meta.sliceToArrayPointer(u), 0..) |e, i| debug.assertEqual(E, e, t[i]);
    const m: [:0]Element = meta.manyToSlice(u.ptr);
    debug.assertEqual(u64, 4, m.len);
    try testInitializer();
}
fn testInitializer() !void {
    const T = struct {
        x: u64 = 0,
        y: u32 = 0,
        z: u16 = 0,
    };
    const c: []const meta.Initializer = &meta.initializers(T, .{ .x = 25, .y = 15 });
    var t: T = meta.initialize(T, c);
    try debug.expectEqual(T, t, .{ .x = 25, .y = 15 });
    debug.expectEqual(T, t, .{ .x = 25, .y = 15 }) catch |err| {
        debug.assertEqual(anyerror, error.UnexpectedValue, err);
    };
}
pub fn main(_: anytype, _: [][*:0]u8) !void {
    try testBasicMetaFunctions();
    try testBitCastMetaFunctions();
    try testAlignmentMetaFunctions();
    try testMemoryMetaFunctions();
}
