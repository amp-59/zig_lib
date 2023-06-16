const top = @import("../zig_lib.zig");
const sys = top.sys;
const builtin = top.builtin;
const meta = top.meta;
const proc = top.proc;

pub usingnamespace proc.start;

pub const logging_default: builtin.Logging.Default = .{
    .Attempt = true,
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
pub const runtime_assertions: bool = true;

fn basicTests() !void {
    try builtin.expectEqual(i1, -1, meta.extrema(i1).min);
    try builtin.expectEqual(u1, 1, meta.extrema(u1).max);
    try builtin.expect(8 == meta.alignAW(7));
    try builtin.expect(16 == meta.alignAW(9));
    try builtin.expect(32 == meta.alignAW(25));
    try builtin.expect(64 == meta.alignAW(48));
    try builtin.expect(0 == meta.alignBW(7));
    try builtin.expect(8 == meta.alignBW(9));
    try builtin.expect(16 == meta.alignBW(25));
    try builtin.expect(32 == meta.alignBW(48));
    try builtin.expect(meta.isEnum(enum { e }));
    try builtin.expect(meta.isContainer(struct {}));
    try builtin.expect(meta.isContainer(packed struct {}));
    try builtin.expect(meta.isContainer(packed struct(u32) { _: u32 }));
    try builtin.expect(meta.isContainer(extern struct {}));
    try builtin.expect(meta.isContainer(union {}));
    try builtin.expect(meta.isContainer(extern union {}));
    try builtin.expect(meta.isContainer(packed union {}));
    try builtin.expect(meta.isTag(@TypeOf(.LiterallyATag)));
    try builtin.expect(meta.isTag(@TypeOf(enum { ASymbolicKindOfTag }.ASymbolicKindOfTag)));
    try builtin.expect(meta.isTag(@TypeOf(struct {})));
    try builtin.expect(meta.isFunction(@TypeOf(main)));
    try builtin.expect(meta.isFunction(@TypeOf(struct {
        fn other(_: *@This()) void {}
    }.other)));
    try builtin.expect(0 == meta.sentinel([:0]u8).?);
    const E = meta.tagNamesEnum(&.{ "one", "two", "three" });
    try builtin.expect(@hasField(E, "one"));
    try builtin.expect(@hasField(E, "two"));
    try builtin.expect(@hasField(E, "three"));
}
fn alignTests() !void {
    try builtin.expect(32 == comptime meta.alignCX(-964392));
    try builtin.expect(8 == comptime meta.alignCX(-128));
    try builtin.expect(16 == comptime meta.alignCX(-129));
    try builtin.expect(8 == meta.alignSizeBW(u9));
    try builtin.expect(8 == meta.alignSizeAW(u7));
    try builtin.expect(u8 == meta.AlignSizeBW(u9));
    try builtin.expect(u8 == meta.AlignSizeAW(u7));
}
fn bitCastTests() !void {
    const S = packed struct {
        x: u3,
        y: u6,
    };
    var s: S = .{ .x = 1, .y = 25 };
    try builtin.expect(u9 == @TypeOf(meta.leastBitCast(s)));
    try builtin.expect(u16 == @TypeOf(meta.leastRealBitCast(s)));
}
fn memoryTests() !void {
    {
        const Element = u3;
        const T = [16:0]Element;
        const E = meta.Element(T);
        const U = meta.ArrayPointerToSlice(*T);
        try builtin.expect([:0]Element == U);
        builtin.assertEqual(type, *T, meta.SliceToArrayPointer(U, @typeInfo(T).Array.len));
        comptime var t: T = T{ 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 7, 0 };
        comptime var u: U = &t;
        builtin.assertEqual(type, meta.Element(T), E);
        builtin.assertEqual(type, meta.Element(*T), E);
        for (meta.arrayPointerToSlice(&t), 0..) |e, i| builtin.assertEqual(E, e, u[i]);
        for (meta.sliceToArrayPointer(u), 0..) |e, i| builtin.assertEqual(E, e, t[i]);
        const m: [:0]Element = meta.manyToSlice(u.ptr);
        builtin.assertEqual(u64, 4, m.len);
    }
    const T = struct {
        x: u64 = 0,
        y: u32 = 0,
        z: u16 = 0,
    };
    const c: []const meta.Initializer = &meta.initializers(T, .{ .x = 25, .y = 14 });
    var t: T = meta.initialize(T, c);

    try builtin.expectEqual(T, t, .{ .x = 25, .y = 14 });
    builtin.expectEqual(T, t, .{ .x = 25, .y = 15 }) catch |err| {
        builtin.assertEqual(anyerror, error.UnexpectedValue, err);
    };
}
fn testToBitFieldPairs() !void {
    const sa_pairs = comptime meta.sliceToArrayPointer(meta.ToBitFieldPairs(sys.CLONE));
    for (sa_pairs) |pair| {
        top.testing.print(.{ pair.name, ": ", top.fmt.render(.{ .infer_type_names = true }, @bitCast(meta.Bits64, pair.value)), '\n' });
    }
}

pub fn main(_: anytype, _: [][*:0]u8) !void {
    try testToBitFieldPairs();
    try basicTests();
    try bitCastTests();
    try alignTests();
    try memoryTests();
}
