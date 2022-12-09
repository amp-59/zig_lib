const builtin = @import("./builtin.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = true;
pub const is_correct: bool = true;

pub fn main() !void {
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
}
