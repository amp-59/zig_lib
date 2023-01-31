//! This stage generates implementations variations
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const config = @import("./config.zig");
const gen = struct {
    usingnamespace @import("./gen.zig");

    usingnamespace @import("./gen-0.zig");
    usingnamespace @import("./gen-1.zig");

    usingnamespace @import("./type_specs.zig");
    usingnamespace @import("./impl_details.zig");
};

const Array = mem.StaticString(1024 * 1024);

pub const DetailExtra = packed struct {
    index: u8 = undefined,
    kind: gen.Kind = .{},
    layout: gen.Layout = .{},
    modes: gen.Modes = .{},
    fields: gen.Fields = .{},
    techs: gen.Techniques = .{},
    specs: gen.Specifiers = .{},

    pub fn isAutomatic(impl_variant: *const DetailExtra) bool {
        return impl_variant.kind.automatic;
    }
    pub fn isParametric(impl_variant: *const DetailExtra) bool {
        return impl_variant.kind.parametric;
    }
    pub fn isDynamic(impl_variant: *const DetailExtra) bool {
        return impl_variant.kind.dynamic;
    }
    pub fn isStatic(impl_variant: *const DetailExtra) bool {
        return impl_variant.kind.static;
    }
    pub fn hasUnitAlignment(impl_variant: *const DetailExtra) bool {
        return builtin.int2v(
            bool,
            impl_variant.techs.unit_alignment,
            impl_variant.kind.automatic,
        );
    }
    pub fn hasLazyAlignment(impl_variant: *const DetailExtra) bool {
        return impl_variant.techs.lazy_alignment;
    }
    pub fn hasDisjunctAlignment(impl_variant: *const DetailExtra) bool {
        return impl_variant.techs.disjunct_alignment;
    }
    pub fn hasStaticMaximumLength(impl_variant: *const DetailExtra) bool {
        return builtin.int2v(bool, impl_variant.kind.automatic, impl_variant.kind.static);
    }
    pub fn hasPackedApproximateCapacity(impl_variant: *const DetailExtra) bool {
        return builtin.int2v(
            bool,
            impl_variant.techs.single_packed_approximate_capacity,
            impl_variant.techs.double_packed_approximate_capacity,
        );
    }
};
const boilerplate: []const u8 =
    \\//! This file is generated by `memgen` stage 2
    \\const gen = @import("./gen-2.zig");
    \\
;
const fmt_spec = .{
    .omit_default_fields = true,
    .infer_type_names = true,
    .omit_trailing_comma = true,
};
fn writeVariantStructsInternal(array: *Array, impl_detail: *const gen.Detail, specs: gen.Specifiers) void {
    array.writeMany("    .{ .index = ");
    array.writeFormat(fmt.ud64(impl_detail.index));
    array.writeMany(", .kind = ");
    array.writeFormat(fmt.render(fmt_spec, impl_detail.kind));
    array.writeMany(", .layout = ");
    array.writeFormat(fmt.render(fmt_spec, impl_detail.layout));
    array.writeMany(", .modes = ");
    array.writeFormat(fmt.render(fmt_spec, impl_detail.modes));
    array.writeMany(", .fields = ");
    array.writeFormat(fmt.render(fmt_spec, impl_detail.fields));
    array.writeMany(", .techs = ");
    array.writeFormat(fmt.render(fmt_spec, impl_detail.techs));
    array.writeMany(", .specs = ");
    array.writeFormat(fmt.render(fmt_spec, specs));
    array.writeMany(" },\n");
}
fn writeVariantStructs(array: *Array) void {
    array.writeMany("pub const impl_variants = [_]gen.DetailExtra{\n");
    inline for (gen.type_specs) |type_spec, param_index| {
        const I = meta.Child(type_spec.vars);
        for (gen.impl_details) |impl_detail| {
            if (impl_detail.index == param_index) {
                var spec_index: u8 = 0;
                while (spec_index <= ~@as(I, 0)) : (spec_index += 1) {
                    const u: type_spec.vars = @bitCast(type_spec.vars, @intCast(I, spec_index));
                    var t: gen.Specifiers = undefined;
                    inline for (@typeInfo(type_spec.vars).Struct.fields) |field| {
                        if (@hasField(gen.Specifiers, field.name)) {
                            @field(t, field.name) = @field(u, field.name);
                        }
                    }
                    writeVariantStructsInternal(array, &impl_detail, t);
                }
            }
        }
    }
    array.writeMany("};\n");
}
fn writeImplementationVariantsFile(array: *Array) void {
    const fd: u64 = gen.create(builtin.build_root.? ++ "/top/mem/impl_variants.zig");
    defer gen.close(fd);
    gen.write(fd, boilerplate);
    gen.write(fd, array.readAll());
    array.undefineAll();
}
pub fn generateVariantData() void {
    var array: Array = .{};
    writeVariantStructs(&array);
    writeImplementationVariantsFile(&array);
}
