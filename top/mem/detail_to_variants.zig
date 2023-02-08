const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/memgen_detail.zig");
    usingnamespace @import("./zig-out/src/memgen_type_spec.zig");
};
fn writeVariantStructInternal(array: *gen.String, impl_detail: out.Detail, specs: out.Specifiers) void {
    array.writeMany("    ");
    array.writeFormat(impl_detail.more(out.DetailMore, specs));
    array.writeMany(",\n");
}
fn writeVariantStruct(array: *gen.String, comptime impl_detail: out.Detail) void {
    const type_spec: gen.TypeSpecMap = out.type_specs[impl_detail.index];
    var vars: u16 = 0;
    while (vars <= @truncate(meta.Child(type_spec.vars), ~@as(u64, 0))) : (vars +%= 1) {
        var specs: out.Specifiers = .{};
        inline for (@typeInfo(type_spec.vars).Struct.fields) |field| {
            if (@hasField(out.Specifiers, field.name)) {
                @field(specs, field.name) = @field(
                    @bitCast(type_spec.vars, @truncate(meta.Child(type_spec.vars), vars)),
                    field.name,
                );
            }
        }
        writeVariantStructInternal(array, impl_detail, specs);
    }
}
fn detailToVariants(array: *gen.String) void {
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "../../detail_more.zig" }});
    array.writeMany("pub const variants: []const out.DetailMore = &[_]out.DetailMore{\n");
    inline for (out.details) |impl_detail| {
        writeVariantStruct(array, impl_detail);
    }
    array.writeMany("};\n");
    gen.writeFile(array, "memgen_variants.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    detailToVariants(&array);
    gen.exit(0);
}
