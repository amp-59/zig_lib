const gen = @import("./gen.zig");
const out = @import("./zig-out/src/memgen_type_spec.zig");

pub const DetailMore = packed struct {
    index: u8 = undefined,
    kinds: gen.Kinds,
    layouts: gen.Layouts,
    modes: gen.Modes,
    fields: gen.Fields,
    techs: gen.Techniques,
    specs: out.Specifiers,
    pub fn less(detail: *const DetailMore) .Detail {
        return .{
            .index = detail.index,
            .kinds = detail.kinds,
            .layouts = detail.layouts,
            .modes = detail.modes,
            .techs = detail.techs,
            .fields = detail.fields,
        };
    }
    pub fn formatWrite(detail: *const DetailMore, array: anytype) void {
        array.writeMany(".{ .index = ");
        gen.writeIndex(array, detail.index);
        array.writeMany(", .kinds = ");
        array.writeFormat(detail.kinds);
        array.writeMany(", .layouts = ");
        array.writeFormat(detail.layouts);
        array.writeMany(", .modes = ");
        array.writeFormat(detail.modes);
        array.writeMany(", .fields = ");
        array.writeFormat(detail.fields);
        array.writeMany(", .techs = ");
        array.writeFormat(detail.techs);
        array.writeMany(", .specs = ");
        gen.writeStructOfBool(array, out.Specifiers, detail.specs);
        array.writeMany(" }");
    }
};
