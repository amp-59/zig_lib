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

    const index_init: [:0]const u8 = ".index=";
    const kinds_init: [:0]const u8 = ",.kinds=";
    const layouts_init: [:0]const u8 = ",.layouts=";
    const modes_init: [:0]const u8 = ",.modes=";
    const managers_init: [:0]const u8 = ",.managers=";
    const fields_init: [:0]const u8 = ",.fields=";
    const techs_init: [:0]const u8 = ",.techs=";

    pub fn formatWrite(detail: *const Detail, array: anytype) void {
        array.writeMany(".{");
        array.writeMany(index_init);
        array.writeFormat(gen.fmt.ud8(detail.index));
        array.writeMany(kinds_init);
        array.writeFormat(detail.kinds);
        array.writeMany(layouts_init);
        array.writeFormat(detail.layouts);
        array.writeMany(modes_init);
        array.writeFormat(detail.modes);
        array.writeMany(managers_init);
        array.writeFormat(detail.managers);
        array.writeMany(fields_init);
        array.writeFormat(detail.fields);
        array.writeMany(techs_init);
        array.writeFormat(detail.techs);
        array.writeMany("}");
    }
    pub fn formatLength(detail: *const Detail) u64 {
        var len: u64 = 0;
        len +%= 2 +% index_init.len;
        len +%= gen.fmt.ud8(detail.index).formatLength();
        len +%= kinds_init.len;
        len +%= detail.kinds.formatLength();
        len +%= layouts_init.len;
        len +%= detail.layouts.formatLength();
        len +%= modes_init.len;
        len +%= detail.modes.formatLength();
        len +%= managers_init.len;
        len +%= detail.managers.formatLength();
        len +%= fields_init.len;
        len +%= detail.fields.formatLength();
        len +%= techs_init.len;
        len +%= detail.techs.formatLength();
        len +%= 1;
        return len;
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
