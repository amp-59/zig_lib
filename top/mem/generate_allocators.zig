const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const config = @import("./config.zig");
const detail = @import("./detail.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/config.zig");
    usingnamespace @import("./zig-out/src/interfaces.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
};

pub usingnamespace proc.start;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 128,
    .errors = .{},
    .logging = preset.address_space.logging.silent,
});
const Array = Allocator.StructuredVector(u8);

const decl_names: []const []const u8 = blk: {
    var pub_names: []const []const u8 = &.{};
    for (@typeInfo(@import("./zig-out/src/interfaces.zig")).Struct.decls) |decl| {
        if (decl.is_pub) {
            pub_names = pub_names ++ [1][]const u8{decl.name};
        }
    }
    break :blk pub_names;
};

pub fn generateAllocators() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    array.undefineAll();
    for (out.interfaces, 0..) |interface_group, idx| {
        for (interface_group) |kind_group| {
            const save: Allocator.Save = allocator.save();
            defer allocator.restore(save);

            if (kind_group.len == 0) {
                continue;
            }
            testing.print(.{ decl_names[idx], out.canonicals[kind_group[0]].kind, '\n' });
        }
    }
    gen.appendSourceFile(&array, "allocator.zig");
}
pub const main = generateAllocators;
