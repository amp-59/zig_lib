const gen = @import("./gen.zig");
const out = @import("./detail_more.zig");

pub const DetailLess = packed struct {
    index: u8 = undefined,
    kinds: gen.Kinds = .{},
    layouts: gen.Layouts = .{},
    modes: gen.Modes = .{},

    pub fn formatWrite(detail: *const DetailLess, array: anytype) void {
        array.writeMany(".{ .index = ");
        gen.writeIndex(array, detail.index);
        array.writeMany(", .kinds = ");
        array.writeFormat(detail.kinds);
        array.writeMany(", .layouts = ");
        array.writeFormat(detail.layouts);
        array.writeMany(", .modes = ");
        array.writeFormat(detail.modes);
        array.writeMany(" }");
    }
    pub fn writeContainerName(detail: *const DetailLess, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
    }
    pub fn more(detail: *const DetailLess) *const out.DetailMore {
        return @ptrCast(*const out.DetailMore, detail);
    }
};
