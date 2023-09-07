const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
const @"test" = struct {
    const algo = @import("algo.zig");
    const builtin = @import("builtin.zig");
    const cmdline = @import("cmdline-writer.zig");
    const container = @import("container.zig");
    const crypto = @import("crypto.zig");
    const file = @import("file.zig");
    const fmt = @import("fmt.zig");
    const impl = @import("impl.zig");
    const junk = @import("junk.zig");
    const list = @import("list.zig");
    const math = @import("math.zig");
    const mem2 = @import("mem2.zig");
    const mem = @import("mem.zig");
    const meta = @import("meta.zig");
    const parse = @import("parse.zig");
    const proc = @import("proc.zig");
    const render = @import("render.zig");
    const rng = @import("rng.zig");
    const serial = @import("serial.zig");
    const thread = @import("thread.zig");
    const time = @import("time.zig");
    const virtual = @import("virtual.zig");
};
pub const logging_override: zl.debug.Logging.Override = zl.spec.logging.override.verbose;
pub const AddressSpace = zl.spec.address_space.exact_8;
const Allocator0 = zl.mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = zl.spec.address_space.regular_128,
});
const Allocator1 = zl.mem.GenericArenaAllocator(.{
    .arena_index = 1,
    .AddressSpace = zl.spec.address_space.exact_8,
});
pub const Builder = zl.build.GenericBuilder(.{});
const List = zl.mem.GenericLinkedList(.{
    .child = u8,
    .low_alignment = 1,
    .Allocator = Allocator0,
});
const ListView = zl.mem.GenericLinkedListView(.{
    .child = u8,
    .low_alignment = 1,
});
const other = struct {
    pub const UnionFormat = zl.fmt.UnionFormat(.{}, union { one: u64, two: struct { u32, u32 } });
    pub const StructForm = zl.fmt.UnionFormat(.{}, struct { one: u64, two: *u64, three: []u8 });
    pub const EnumFormat = zl.fmt.UnionFormat(.{}, enum { one, two, three });
    pub const object_format = std.Target.ObjectFormat.elf;
    pub const mode = std.builtin.Mode.Debug;
    pub const link_libc = false;
    pub const link_libcpp = false;
    pub const have_error_return_tracing = true;
    pub const valgrind_support = true;
    pub const sanitize_thread = false;
    pub const position_independent_code = false;
    pub const position_independent_executable = false;
    pub const strip_debug_info = false;
    pub const code_model = std.builtin.CodeModel.default;
};
pub fn main() !void {
    _ = zl.meta.refAllDecls(zl, &.{ "FnArg", "tls" });
    _ = zl.meta.refAllDecls(@"test", &.{"FnArg"});
    _ = zl.meta.refAllDecls(List, null);
    _ = zl.meta.refAllDecls(ListView, null);
    _ = zl.meta.refAllDecls(other, null);
    _ = zl.meta.refAllDecls(Builder, null);
    _ = zl.meta.refAllDecls(Allocator0, null);
    _ = zl.meta.refAllDecls(Allocator1, null);
}
const std = if (@hasDecl(zl.builtin.root, "is_zig_lib") and zl.builtin.root.is_zig_lib) zl else @import("std");
