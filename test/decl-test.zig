const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

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
pub const logging_override: zl.builtin.Logging.Override = zl.spec.logging.override.verbose;
pub const AddressSpace = zl.spec.address_space.exact_8;
const Allocator0 = zl.mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = zl.spec.address_space.regular_128,
});
const Allocator1 = zl.mem.GenericArenaAllocator(.{
    .arena_index = 1,
    .AddressSpace = zl.spec.address_space.exact_8,
});
const Builder = zl.build.GenericNode(.{});
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
