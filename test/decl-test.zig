const zig_lib = @import("../zig_lib.zig");

pub usingnamespace zig_lib.proc.start;

const @"test" = struct {
    const algo = @import("algo-test.zig");
    const builtin = @import("builtin-test.zig");
    const cmdline = @import("cmdline-test.zig");
    const container = @import("container-test.zig");
    const crypto = @import("crypto-test.zig");
    const debug = @import("debug-test.zig");
    const file = @import("file-test.zig");
    const fmt = @import("fmt-test.zig");
    const impl = @import("impl-test.zig");
    const junk = @import("junk-test.zig");
    const list = @import("list-test.zig");
    const math = @import("math-test.zig");
    const mem2 = @import("mem2-test.zig");
    const mem = @import("mem-test.zig");
    const meta = @import("meta-test.zig");
    const parse = @import("parse-test.zig");
    const proc = @import("proc-test.zig");
    const render = @import("render-test.zig");
    const rng = @import("rng-test.zig");
    const serial = @import("serial-test.zig");
    const thread = @import("thread-test.zig");
    const time = @import("time-test.zig");
    const virtual = @import("virtual-test.zig");
};
pub const logging_override: zig_lib.builtin.Logging.Override = zig_lib.spec.logging.override.verbose;
pub const AddressSpace = zig_lib.spec.address_space.exact_8;
const Allocator0 = zig_lib.mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = zig_lib.spec.address_space.regular_128,
});
const Allocator1 = zig_lib.mem.GenericArenaAllocator(.{
    .arena_index = 1,
    .AddressSpace = zig_lib.spec.address_space.exact_8,
});
const Builder = zig_lib.build.GenericNode(.{});
const List = zig_lib.mem.GenericLinkedList(.{
    .child = u8,
    .low_alignment = 1,
    .Allocator = Allocator0,
});
const ListView = zig_lib.mem.GenericLinkedListView(.{
    .child = u8,
    .low_alignment = 1,
});
const render = struct {
    pub const UnionFormat = zig_lib.fmt.UnionFormat(.{}, union { one: u64, two: struct { u32, u32 } });
    pub const StructForm = zig_lib.fmt.UnionFormat(.{}, struct { one: u64, two: *u64, three: []u8 });
    pub const EnumFormat = zig_lib.fmt.UnionFormat(.{}, enum { one, two, three });
};
pub fn main() void {
    _ = zig_lib.meta.refAllDecls(zig_lib, &.{ "FnArg", "tls" });
    _ = zig_lib.meta.refAllDecls(@"test", &.{"FnArg"});
    _ = zig_lib.meta.refAllDecls(List, null);
    _ = zig_lib.meta.refAllDecls(ListView, null);
    _ = zig_lib.meta.refAllDecls(render.UnionFormat, null);
    _ = zig_lib.meta.refAllDecls(render.StructForm, null);
    _ = zig_lib.meta.refAllDecls(render.EnumFormat, null);
    _ = zig_lib.meta.refAllDecls(Builder, null);
    _ = zig_lib.meta.refAllDecls(Allocator0, null);
    _ = zig_lib.meta.refAllDecls(Allocator1, null);
}
