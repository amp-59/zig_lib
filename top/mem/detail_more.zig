const gen = @import("./gen.zig");
const attr = @import("./attr.zig");
const out = struct {
    usingnamespace @import("./canonical.zig");
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};

pub const DetailMore = packed struct {
    index: u8 = undefined,
    kinds: attr.Kinds = .{},
    layouts: attr.Layouts = .{},
    managers: attr.Managers = .{},
    modes: attr.Modes = .{},
    fields: attr.Fields = .{},
    techs: attr.Techniques = .{},
    specs: out.Specifiers = .{},

    const index_init: [:0]const u8 = ".index=";
    const kinds_init: [:0]const u8 = ",.kinds=";
    const layouts_init: [:0]const u8 = ",.layouts=";
    const modes_init: [:0]const u8 = ",.modes=";
    const managers_init: [:0]const u8 = ",.managers=";
    const fields_init: [:0]const u8 = ",.fields=";
    const techs_init: [:0]const u8 = ",.techs=";
    const specs_init: [:0]const u8 = ",.specs=";

    pub fn formatWrite(detail: *const DetailMore, array: anytype) void {
        array.writeMany(".{");
        array.writeMany(index_init);
        array.writeFormat(gen.fmt.ub8(detail.index));
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
        array.writeMany(specs_init);
        attr.GenericStructOfBool(out.Specifiers).formatWrite(detail.specs, array);
        array.writeMany("}");
    }
    pub fn formatLength(detail: *const DetailMore) u64 {
        var len: u64 = 0;
        len +%= 2 +% index_init.len;
        len +%= gen.fmt.ub8(detail.index).formatLength();
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
        len +%= specs_init.len;
        len +%= attr.GenericStructOfBool(out.Specifiers).formatLength(detail.specs);
        len +%= 1;
        return len;
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

pub fn kinds(canonical: anytype) attr.Kinds {
    return @field(canonical, out.kinds.dst_name).revert(attr.Kinds);
}
pub fn layouts(canonical: anytype) attr.Layouts {
    return @field(canonical, out.layouts.dst_name).revert(attr.Layouts);
}
pub fn managers(canonical: anytype) attr.Managers {
    return @field(canonical, out.managers.dst_name).revert(attr.Managers);
}
pub fn modes(canonical: anytype) attr.Modes {
    return @field(canonical, out.modes.dst_name).revert(attr.Modes);
}
pub fn fields(canonical: anytype) attr.Fields {
    return @field(canonical, out.fields.dst_name).revert(attr.Fields);
}
pub fn techs(canonical: anytype) attr.Techniques {
    return @field(canonical, out.techs.dst_name).revert(attr.Techniques);
}
pub fn specs(canonical: anytype) out.Specifiers {
    return @field(canonical, out.specs.dst_name).revert(out.Specifiers);
}
