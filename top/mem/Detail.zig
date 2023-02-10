const gen = @import("./gen.zig");

pub const Detail = packed struct {
    index: u8 = undefined,
    kinds: gen.Kinds = .{},
    layouts: gen.Layouts = .{},
    modes: gen.Modes = .{},
    fields: gen.Fields = .{},
    techs: gen.Techniques = .{},

    pub fn less(detail: *const Detail, comptime DetailLess: type) DetailLess {
        return .{
            .index = detail.index,
            .kinds = detail.kinds,
            .layouts = detail.layouts,
            .modes = detail.modes,
        };
    }
    pub fn more(detail: *const Detail, comptime DetailMore: type, specs: anytype) DetailMore {
        return .{
            .index = detail.index,
            .kinds = detail.kinds,
            .layouts = detail.layouts,
            .modes = detail.modes,
            .techs = detail.techs,
            .fields = detail.fields,
            .specs = specs,
        };
    }
    pub fn formatWrite(detail: Detail, array: anytype) void {
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
        array.writeMany(" }");
    }
};
