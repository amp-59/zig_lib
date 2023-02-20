const gen = @import("./gen.zig");

pub const Detail = packed struct {
    index: u8 = undefined,
    kinds: gen.Kinds = .{},
    layouts: gen.Layouts = .{},
    modes: gen.Modes = .{},
    management: gen.Management = .{},
    fields: gen.Fields = .{},
    techs: gen.Techniques = .{},

    pub fn formatWrite(detail: Detail, array: anytype) void {
        array.writeMany(".{ .index = ");
        gen.writeIndex(array, detail.index);
        array.writeMany(", .kinds = ");
        array.writeFormat(detail.kinds);
        array.writeMany(", .layouts = ");
        array.writeFormat(detail.layouts);
        array.writeMany(", .modes = ");
        array.writeFormat(detail.modes);
        array.writeMany(", .management = ");
        array.writeFormat(detail.management);
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
            .management = detail.management,
            .techs = detail.techs,
            .fields = detail.fields,
            .specs = specs,
        };
    }
};
