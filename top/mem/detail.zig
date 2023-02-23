const gen = @import("./gen.zig");
const attr = @import("./attr.zig");

pub const Detail = packed struct {
    index: u8 = undefined,
    kinds: attr.Kinds = .{},
    layouts: attr.Layouts = .{},
    modes: attr.Modes = .{},
    managers: attr.Managers = .{},
    fields: attr.Fields = .{},
    techs: attr.Techniques = .{},

    pub fn formatWrite(detail: Detail, array: anytype) void {
        array.writeMany(".{ .index = ");
        gen.writeIndex(array, detail.index);
        array.writeMany(", .kinds = ");
        array.writeFormat(detail.kinds);
        array.writeMany(", .layouts = ");
        array.writeFormat(detail.layouts);
        array.writeMany(", .modes = ");
        array.writeFormat(detail.modes);
        array.writeMany(", .managers = ");
        array.writeFormat(detail.managers);
        array.writeMany(", .fields = ");
        array.writeFormat(detail.fields);
        array.writeMany(", .techs = ");
        array.writeFormat(detail.techs);
        array.writeMany(" }");
    }
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
            .managers = detail.managers,
            .techs = detail.techs,
            .fields = detail.fields,
            .specs = specs,
        };
    }
};
