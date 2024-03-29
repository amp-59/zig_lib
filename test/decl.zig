const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const logging_override: zl.debug.Logging.Override = zl.debug.spec.logging.override.verbose;
pub const AddressSpace = zl.mem.spec.address_space.exact_8;
const Allocator0 = zl.mem.dynamic.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = zl.mem.spec.address_space.regular_128,
});
const Allocator1 = zl.mem.dynamic.GenericArenaAllocator(.{
    .arena_index = 1,
    .AddressSpace = zl.mem.spec.address_space.exact_8,
});
pub const Builder = zl.builder.GenericBuilder(.{});
const List = zl.mem.list.GenericLinkedList(.{
    .child = u8,
    .low_alignment = 1,
    .Allocator = Allocator0,
});
const ListView = zl.mem.list.GenericLinkedListView(.{
    .child = u8,
    .low_alignment = 1,
});
const other = struct {
    pub const UnionFormat = zl.fmt.UnionFormat(.{}, union { one: u64, two: struct { u32, u32 } });
    pub const StructForm = zl.fmt.UnionFormat(.{}, struct { one: u64, two: *u64, three: []u8 });
    pub const EnumFormat = zl.fmt.UnionFormat(.{}, enum { one, two, three });
    pub const AnyFormatAbi = zl.fmt.AnyFormat(.{}, @TypeOf(@import("builtin").abi));
    pub const AnyFormatTarget = zl.fmt.AnyFormat(.{}, @TypeOf(@import("builtin").target));
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
    _ = zl.meta.refAllDecls(other, null);
    _ = zl.meta.refAllDecls(List, null);
    _ = zl.meta.refAllDecls(ListView, null);
    _ = zl.meta.refAllDecls(Builder, null);
    _ = zl.meta.refAllDecls(Allocator0, null);
    _ = zl.meta.refAllDecls(Allocator1, null);
}
const std = if (@hasDecl(zl.builtin.root, "is_zig_lib") and zl.builtin.root.is_zig_lib) zl else @import("std");
