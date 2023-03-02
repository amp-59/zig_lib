const gen = @import("./gen.zig");
const attr = @import("./attr.zig");

pub const Base = packed struct {
    index: u8 = undefined,
    kinds: attr.Kinds = .{},
    layouts: attr.Layouts = .{},
    modes: attr.Modes = .{},
    managers: attr.Managers = .{},
    fields: attr.Fields = .{},
    techs: attr.Techniques = .{},
    pub fn formatWrite(detail: *const Base, array: anytype) void {
        array.writeMany(".{");
        array.writeMany(tok.index_init);
        array.writeFormat(gen.fmt.ud8(detail.index));
        array.writeMany(tok.kinds_init);
        array.writeFormat(detail.kinds);
        array.writeMany(tok.layouts_init);
        array.writeFormat(detail.layouts);
        array.writeMany(tok.modes_init);
        array.writeFormat(detail.modes);
        array.writeMany(tok.managers_init);
        array.writeFormat(detail.managers);
        array.writeMany(tok.fields_init);
        array.writeFormat(detail.fields);
        array.writeMany(tok.techs_init);
        array.writeFormat(detail.techs);
        array.writeMany("}");
    }
    pub fn formatLength(detail: *const Base) u64 {
        var len: u64 = 0;
        len +%= 2 +% tok.index_init.len;
        len +%= gen.fmt.ud8(detail.index).formatLength();
        len +%= tok.kinds_init.len;
        len +%= detail.kinds.formatLength();
        len +%= tok.layouts_init.len;
        len +%= detail.layouts.formatLength();
        len +%= tok.modes_init.len;
        len +%= detail.modes.formatLength();
        len +%= tok.managers_init.len;
        len +%= detail.managers.formatLength();
        len +%= tok.fields_init.len;
        len +%= detail.fields.formatLength();
        len +%= tok.techs_init.len;
        len +%= detail.techs.formatLength();
        len +%= 1;
        return len;
    }

    pub fn less(detail: *const Base) Less {
        return .{
            .index = detail.index,
            .kinds = detail.kinds,
            .layouts = detail.layouts,
            .modes = detail.modes,
        };
    }
    pub fn more(detail: *const Base, specs: anytype) More {
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

pub const More = packed struct {
    index: u8 = undefined,
    kinds: attr.Kinds = .{},
    layouts: attr.Layouts = .{},
    managers: attr.Managers = .{},
    modes: attr.Modes = .{},
    fields: attr.Fields = .{},
    techs: attr.Techniques = .{},
    specs: Specifiers = .{},

    const Specifiers = @import("./zig-out/src/specifiers.zig").Specifiers;

    pub fn formatWrite(detail: *const More, array: anytype) void {
        array.writeMany(".{");
        array.writeMany(tok.index_init);
        array.writeFormat(gen.fmt.ud8(detail.index));
        array.writeMany(tok.kinds_init);
        array.writeFormat(detail.kinds);
        array.writeMany(tok.layouts_init);
        array.writeFormat(detail.layouts);
        array.writeMany(tok.modes_init);
        array.writeFormat(detail.modes);
        array.writeMany(tok.managers_init);
        array.writeFormat(detail.managers);
        array.writeMany(tok.fields_init);
        array.writeFormat(detail.fields);
        array.writeMany(tok.techs_init);
        array.writeFormat(detail.techs);
        array.writeMany(tok.specs_init);
        attr.GenericStructOfBool(Specifiers).formatWrite(detail.specs, array);
        array.writeMany("}");
    }
    pub fn formatLength(detail: *const More) u64 {
        var len: u64 = 0;
        len +%= 2 +% tok.index_init.len;
        len +%= gen.fmt.ud8(detail.index).formatLength();
        len +%= tok.kinds_init.len;
        len +%= detail.kinds.formatLength();
        len +%= tok.layouts_init.len;
        len +%= detail.layouts.formatLength();
        len +%= tok.modes_init.len;
        len +%= detail.modes.formatLength();
        len +%= tok.managers_init.len;
        len +%= detail.managers.formatLength();
        len +%= tok.fields_init.len;
        len +%= detail.fields.formatLength();
        len +%= tok.techs_init.len;
        len +%= detail.techs.formatLength();
        len +%= tok.specs_init.len;
        len +%= attr.GenericStructOfBool(Specifiers).formatLength(detail.specs);
        len +%= 1;
        return len;
    }
    pub fn writeImplementationName(detail: *const More, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
        gen.writeFieldOfBool(array, detail.techs);
        gen.writeFieldOfBool(array, detail.specs);
    }
    pub fn writeContainerName(detail: *const More, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
    }
    pub fn less(detail: *const More) *const Less {
        return @ptrCast(*const Less, detail);
    }
};

const Canonical = struct {
    const out = More.out;
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
};

pub const Less = packed struct {
    index: u8 = undefined,
    kinds: attr.Kinds = .{},
    layouts: attr.Layouts = .{},
    managers: attr.Managers = .{},
    modes: attr.Modes = .{},
    pub fn formatWrite(detail: *const Less, array: anytype) void {
        array.writeMany(".{");
        array.writeMany(tok.index_init);
        gen.writeIndex(array, detail.index);
        array.writeMany(tok.kinds_init);
        array.writeFormat(detail.kinds);
        array.writeMany(tok.layouts_init);
        array.writeFormat(detail.layouts);
        array.writeMany(tok.modes_init);
        array.writeFormat(detail.modes);
        array.writeMany("}");
    }
    pub fn writeContainerName(detail: *const Less, array: anytype) void {
        gen.writeFieldOfBool(array, detail.layouts);
        gen.writeFieldOfBool(array, detail.modes);
        gen.writeFieldOfBool(array, detail.kinds);
    }
    pub fn more(detail: *const Less) *const More {
        return @ptrCast(*const More, @alignCast(@alignOf(More), detail));
    }
};

const tok = struct {
    const index_init: [:0]const u8 = ".index=";
    const kinds_init: [:0]const u8 = ",.kinds=";
    const layouts_init: [:0]const u8 = ",.layouts=";
    const modes_init: [:0]const u8 = ",.modes=";
    const managers_init: [:0]const u8 = ",.managers=";
    const fields_init: [:0]const u8 = ",.fields=";
    const techs_init: [:0]const u8 = ",.techs=";
    const specs_init: [:0]const u8 = ",.specs=";
};
