const gen = @import("./gen.zig");
const out = @import("./detail_less.zig");

pub const DetailMore = packed struct {
    index: u8 = undefined,
    kinds: gen.Kinds = .{},
    layouts: gen.Layouts = .{},
    modes: gen.Modes = .{},
    fields: gen.Fields = .{},
    techs: gen.Techniques = .{},
    specs: Specifiers = .{},
    const Specifiers = @import("./zig-out/src/specifiers.zig").Specifiers;

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
        gen.writeStructOfBool(array, Specifiers, detail.specs);
        array.writeMany(" }");
    }
    pub fn writeImplementationName(detail: *const DetailMore, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
        gen.writeFieldOfBool(array, detail.techs);
        gen.writeFieldOfBool(array, detail.specs);
    }
    pub fn writeContainerName(detail: *const DetailMore, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
    }
    pub fn less(detail: *const DetailMore) *const out.DetailLess {
        return @ptrCast(*const out.DetailLess, detail);
    }
};
