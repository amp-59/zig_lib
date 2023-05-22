const gen = @import("./gen.zig");
const fmt = gen.fmt;
const mem = gen.mem;
const proc = gen.proc;
const spec = gen.spec;
const builtin = gen.builtin;
const testing = gen.testing;

const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const ctn_fn = @import("./ctn_fn.zig");
const ptr_fn = @import("./ptr_fn.zig");
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
        .logging = spec.address_space.logging.silent,
        .errors = spec.address_space.errors.noexcept,
    }),
    .options = spec.allocator.options.small,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
});
const Array = mem.StaticString(1024 * 1024);

pub fn main() !void {
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    var array: Array = undefined;
    array.undefineAll();
    {
        const parametric_example: detail.More = .{
            .index = 3,
            .kinds = .{ .parametric = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .convertible = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const detail.More = &parametric_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.unstreamed_byte_count));
            array.writeFormat(fmt.any(call));
            builtin.debug.write(array.readAll());
            array.undefineAll();

            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "unstreamed_byte_count(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "allocated_byte_address(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "writable_byte_count(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".unstreamed_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".allocated_byte_address(" ++ tok.allocator_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".writable_byte_count(" ++ tok.allocator_name ++ ")");
        }
    }
    {
        const dynamic_example: detail.More = .{
            .index = 3,
            .kinds = .{ .dynamic = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .convertible = true, .movable = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const detail.More = &dynamic_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.construct));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.source_impl_type_name ++ ".construct(" ++ tok.source_aligned_byte_address_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.reconstruct));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".reconstruct(" ++ tok.target_aligned_byte_address_name ++ ")");
        }
    }
    {
        const parametric_example: detail.More = .{
            .index = 3,
            .kinds = .{ .static = true },
            .layouts = .{ .structured = true },
            .managers = .{ .allocatable = true, .movable = true },
            .modes = .{ .read_write = true, .resize = true },
            .fields = .{ .undefined_byte_address = true },
            .techs = .{ .disjunct_alignment = true },
        };
        const impl_detail: *const detail.More = &parametric_example;
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "unstreamed_byte_count(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "allocated_byte_address(" ++ tok.impl_name ++ ")");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail, ptr_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), "writable_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.unstreamed_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".unstreamed_byte_count()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.allocated_byte_address));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".allocated_byte_address()");
        }
        {
            defer array.undefineAll();
            const call: expr.Expr = expr.impl(&allocator, impl_detail.less(), ptr_fn.get(.writable_byte_count));
            array.writeFormat(call);
            try testing.expectEqualMany(u8, array.readAll(), tok.impl_name ++ ".writable_byte_count()");
        }
    }
}
