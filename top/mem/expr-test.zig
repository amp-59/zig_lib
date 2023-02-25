const gen = @import("./gen.zig");
const fmt = gen.fmt;
const mem = gen.mem;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;
const testing = gen.testing;

const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
const out = struct {
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
};

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = mem.GenericDiscreteAddressSpace(.{
        .list = &.{.{
            .lb_addr = 0x40000000,
            .up_addr = 0x50000000,
        }},
        .logging = preset.address_space.logging.silent,
        .errors = preset.address_space.errors.noexcept,
    }),
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const Array = mem.StaticString(1024 * 1024);

pub fn main() !void {
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    var array: Array = undefined;
    array.undefineAll();
    {
        const parametric_example: out.DetailMore = .{
            .index = 3,
            .kinds = .{ .parametric = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .convertible = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const out.DetailMore = &parametric_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.unstreamed_byte_count));
            array.writeFormat(fmt.any(call));
            builtin.debug.write(array.readAll());
            array.undefineAll();

            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "unstreamed_byte_count(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "allocated_byte_address(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "writable_byte_count(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".unstreamed_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".allocated_byte_address(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".writable_byte_count(" ++ tok.allocator_name ++ ")");
        }
    }
    {
        const dynamic_example: out.DetailMore = .{
            .index = 3,
            .kinds = .{ .dynamic = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .convertible = true, .movable = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const out.DetailMore = &dynamic_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.construct));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.source_impl_type_name ++ ".construct(" ++ tok.source_aligned_byte_address_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.reconstruct));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".reconstruct(" ++ tok.target_aligned_byte_address_name ++ ")");
        }
    }
    {
        const parametric_example: out.DetailMore = .{
            .index = 3,
            .kinds = .{ .static = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .movable = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const out.DetailMore = &parametric_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "unstreamed_byte_count(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "allocated_byte_address(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, impl_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "writable_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".unstreamed_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".allocated_byte_address()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), impl_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".writable_byte_count()");
        }
    }
}
