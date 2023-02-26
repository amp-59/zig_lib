const gen = @import("./gen.zig");
const attr = @import("./attr.zig");
const mem = gen.mem;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

pub usingnamespace proc.start;

const abstract_spec = @import("./abstract_spec.zig");

const expr = @import("./expr.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");

const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
};

pub const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .errors = preset.address_space.errors.noexcept,
    .logging = preset.address_space.logging.silent,
    .options = .{},
});
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
});
const Array = Allocator.StructuredVector(u8);

noinline fn writeField(array: *Array, impl_variant: out.DetailMore) void {
    impl_variant.writeImplementationName(array);
    array.writeMany(",\n");
}

fn specToAllocatorFunctions() void {
    var address_space: AddressSpace = .{};

    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    var array: Array = Array.init(&allocator, 1024 * 1024);
    defer array.deinit(&allocator);

    inline for (@typeInfo(attr.Managers).Struct.fields) |m_field| {
        inline for (@typeInfo(attr.Kinds).Struct.fields) |k_field| {
            var unique_arg_lists: mem.StaticArray(gen.ArgList, 64) = undefined;
            unique_arg_lists.undefineAll();

            const impl_fn_info: *const impl_fn.Fn = blk: {
                if (comptime mem.testEqualMany(u8, m_field.name, "allocatable")) {
                    break :blk impl_fn.get(.construct);
                } else if (comptime mem.testEqualMany(u8, m_field.name, "reallocatable")) {
                    break :blk impl_fn.get(.reconstruct);
                } else if (comptime mem.testEqualMany(u8, m_field.name, "movable")) {
                    break :blk impl_fn.get(.translate);
                } else {
                    continue;
                }
            };
            for (out.impl_variants) |*impl_variant| {
                if (@field(impl_variant.managers, m_field.name) and
                    @field(impl_variant.kinds, k_field.name))
                {
                    var arg_list: gen.ArgList = impl_fn_info.argList(impl_variant, .Argument);
                    for (unique_arg_lists.readAll()) |unique_arg_list| {
                        if (builtin.testEqual(gen.ArgList, arg_list, unique_arg_list)) {
                            break;
                        }
                    } else {
                        unique_arg_lists.writeOne(arg_list);
                    }
                }
            }
            if (unique_arg_lists.len() != 0) {
                array.writeMany(m_field.name ++ k_field.name ++ ": \n");
                for (unique_arg_lists.readAll()) |*arg_list| {
                    array.writeFormat(expr.impl1(&allocator, impl_fn_info, arg_list, .{}));
                    array.writeMany("\n");
                }
            }
        }
    }
    builtin.debug.write(array.readAll());
}

pub const main = specToAllocatorFunctions;
