const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const builtin = @import("../../builtin.zig");

const tok = @import("./tok.zig");

pub const ProtoTypeDescr = fmt.GenericTypeDescrFormat(.{
    .default_field_values = .fast,
});
pub const TypeDescr = fmt.GenericTypeDescrFormat(.{
    .token = [:0]const u8,
    .default_field_values = .fast,
});
pub const AbstractSpecification = struct {
    kind: Kind,
    layout: Layout,
    fields: []const Fields.Tag,
    modes: []const Modes.Tag,
    v_techs: []const Technique,
    v_specs: []const Specifier,
};
pub const Kind = enum(u2) {
    automatic,
    dynamic,
    static,
    parametric,
    pub const list: []const Kind = meta.tagList(Kind);
};
pub const Layout = enum(u1) {
    structured,
    unstructured,
};
pub const Modes = packed struct(u3) {
    read_write: bool = false,
    resize: bool = false,
    stream: bool = false,
    pub usingnamespace meta.GenericStructOfBool(Modes);
};
pub const Fields = packed struct(u5) {
    automatic_storage: bool = false,
    allocated_byte_address: bool = false,
    undefined_byte_address: bool = false,
    unallocated_byte_address: bool = false,
    unstreamed_byte_address: bool = false,
    pub usingnamespace meta.GenericStructOfBool(Fields);
};
pub const Managers = packed struct(u5) {
    allocatable: bool = false,
    reallocatable: bool = false,
    resizable: bool = false,
    movable: bool = false,
    convertible: bool = false,
    pub usingnamespace meta.GenericStructOfBool(Managers);
};
pub const Specifiers = packed struct(u7) {
    child: bool = false,
    count: bool = false,
    sentinel: bool = false,
    low_alignment: bool = false,
    high_alignment: bool = false,
    Allocator: bool = false,
    arena: bool = false,
    pub usingnamespace meta.GenericStructOfBool(Specifiers);
};
pub const Techniques = packed struct(u8) {
    auto_alignment: bool = false,
    lazy_alignment: bool = false,
    unit_alignment: bool = false,
    disjunct_alignment: bool = false,
    single_packed_approximate_capacity: bool = false,
    double_packed_approximate_capacity: bool = false,
    arena_relative: bool = false,
    address_space_relative: bool = false,
    pub usingnamespace meta.GenericStructOfBool(Techniques);
    pub const Options = packed struct(u3) {
        alignment: bool = false,
        capacity: bool = false,
        relative: bool = false,
        pub usingnamespace meta.GenericStructOfBool(Techniques.Options);
    };
};
pub const Specifier = union(enum) {
    default: Simple,
    derived: Derived,
    stripped: Simple,
    optional_derived: SimpleDerived,
    optional_variant: Simple,
    decl_optional_derived: CompoundDerived,
    decl_optional_variant: Compound,
    const Simple = struct {
        tag: Specifiers.Tag,
        type: ProtoTypeDescr,
    };
    const Derived = struct {
        tag: Specifiers.Tag,
        fn_name: []const u8,
        type: ProtoTypeDescr,
    };
    const SimpleDerived = struct {
        tag: Specifiers.Tag,
        type: ProtoTypeDescr,
        fn_name: []const u8,
    };
    const Compound = struct {
        ctn_tag: Specifiers.Tag,
        decl_tag: Specifiers.Tag,
        ctn_type: ProtoTypeDescr,
        decl_type: ProtoTypeDescr,
    };
    const CompoundDerived = struct {
        ctn_tag: Specifiers.Tag,
        decl_tag: Specifiers.Tag,
        ctn_type: ProtoTypeDescr,
        decl_type: ProtoTypeDescr,
        fn_name: []const u8,
    };
    pub fn paramFormatter(spec: Specifier) ProtoTypeDescr {
        switch (spec) {
            .default => return spec.default.type,
            .derived => return spec.derived.type,
            .optional_derived => return spec.optional_derived.type,
            .optional_variant => return spec.optional_variant.type,
            .decl_optional_derived => return spec.decl_optional_derived.ctn_type,
            .decl_optional_variant => return spec.decl_optional_variant.ctn_type,
            .stripped => return undefined,
        }
    }
    pub fn specFormatter(spec: Specifier) ProtoTypeDescr {
        switch (spec) {
            .default => return spec.default.type,
            .derived => return spec.derived.type,
            .optional_derived => return spec.optional_derived.type,
            .optional_variant => return spec.optional_variant.type,
            .decl_optional_derived => return spec.decl_optional_derived.decl_type,
            .decl_optional_variant => return spec.decl_optional_variant.decl_type,
            .stripped => return undefined,
        }
    }
    pub fn isVariant(comptime spec: Specifier) bool {
        switch (spec) {
            .optional_variant,
            .decl_optional_variant,
            => {
                return true;
            },
            else => {
                return false;
            },
        }
    }
    pub fn isDerived(comptime spec: Specifier) bool {
        switch (spec) {
            .derived,
            .decl_optional_derived,
            .optional_derived,
            => {
                return true;
            },
            else => {
                return false;
            },
        }
    }
};
pub fn specifierTags(variants: []const Specifier) Specifiers {
    var int: Specifiers.tag_type = 0;
    for (variants) |variant| {
        switch (variant) {
            .derived => {
                int |= @intFromEnum(variant.derived.tag);
            },
            .stripped => {
                int |= @intFromEnum(variant.stripped.tag);
            },
            .default => {
                int |= @intFromEnum(variant.default.tag);
            },
            .optional_derived => {
                int |= @intFromEnum(variant.optional_derived.tag);
            },
            .optional_variant => {
                int |= @intFromEnum(variant.optional_variant.tag);
            },
            .decl_optional_derived => {
                int |= @intFromEnum(variant.decl_optional_derived.decl_tag);
            },
            .decl_optional_variant => {
                int |= @intFromEnum(variant.decl_optional_variant.decl_tag);
            },
        }
    }
    return @as(Specifiers, @bitCast(int));
}
pub const Container = packed struct {
    kind: Kind,
    layout: Layout,
    modes: Modes,
    const Format = @This();
    pub fn init(abstract_spec: AbstractSpecification) Container {
        return .{
            .kind = abstract_spec.kind,
            .layout = abstract_spec.layout,
            .modes = Modes.detail(abstract_spec.modes),
        };
    }
    pub fn impl(ctn: Container) Implementation {
        var ret: Implementation = undefined;
        ret.kind = ctn.kind;
        ret.layout = ctn.layout;
        ret.modes = ctn.modes;
        return ret;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format.kind) {
            .parametric => {
                array.writeMany(tok.parametric_type_name);
            },
            .dynamic => {
                array.writeMany(tok.dynamic_type_name);
            },
            .static => {
                array.writeMany(tok.static_type_name);
            },
            .automatic => {
                array.writeMany(tok.automatic_type_name);
            },
        }
        switch (format.layout) {
            .structured => {
                array.writeMany(tok.structured_type_name);
            },
            .unstructured => {
                array.writeMany(tok.unstructured_type_name);
            },
        }
        if (format.modes.read_write) {
            array.writeMany(tok.read_write_type_name);
        }
        if (format.modes.stream) {
            array.writeMany(tok.stream_type_name);
        }
        if (format.modes.resize) {
            array.writeMany(tok.resize_type_name);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        switch (format.kind) {
            .parametric => {
                len +%= tok.parametric_type_name.len;
            },
            .dynamic => {
                len +%= tok.dynamic_type_name.len;
            },
            .static => {
                len +%= tok.static_type_name.len;
            },
            .automatic => {
                len +%= tok.automatic_type_name.len;
            },
        }
        switch (format.layout) {
            .structured => {
                len +%= tok.structured_type_name.len;
            },
            .unstructured => {
                len +%= tok.unstructured_type_name.len;
            },
        }
        if (format.modes.read_write) {
            len +%= tok.read_write_type_name.len;
        }
        if (format.modes.stream) {
            len +%= tok.stream_type_name.len;
        }
        if (format.modes.resize) {
            len +%= tok.resize_type_name.len;
        }
        return len;
    }
};
pub const Implementation = packed struct {
    params: u16,
    ctn: u16,
    ptr: u16,
    kind: Kind,
    layout: Layout,
    modes: Modes,
    fields: Fields,
    techs: Techniques,
    specs: Specifiers,
    const Format = @This();
    pub const Indices = struct {
        params: u16 = 0,
        ctn: u16 = 0,
        ptr: u16 = 0,
    };
    pub fn init(
        abstract_spec: AbstractSpecification,
        specs: []const Specifier,
        techs: []const Technique,
        indices: Indices,
    ) Implementation {
        return .{
            .params = indices.params,
            .ctn = indices.ctn,
            .ptr = indices.ptr,
            .kind = abstract_spec.kind,
            .layout = abstract_spec.layout,
            .modes = Modes.detail(abstract_spec.modes),
            .fields = Fields.detail(abstract_spec.fields),
            .specs = specifierTags(specs),
            .techs = techniqueTags(techs),
        };
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format.kind) {
            .parametric => {
                array.writeMany(tok.parametric_type_name);
            },
            .dynamic => {
                array.writeMany(tok.dynamic_type_name);
            },
            .static => {
                array.writeMany(tok.static_type_name);
            },
            .automatic => {
                array.writeMany(tok.automatic_type_name);
            },
        }
        switch (format.layout) {
            .structured => {
                array.writeMany(tok.structured_type_name);
            },
            .unstructured => {
                array.writeMany(tok.unstructured_type_name);
            },
        }
        if (format.modes.read_write) {
            array.writeMany(tok.read_write_type_name);
        }
        if (format.modes.stream) {
            array.writeMany(tok.stream_type_name);
        }
        if (format.modes.resize) {
            array.writeMany(tok.resize_type_name);
        }
        if (format.specs.arena) {
            array.writeMany(tok.arena_type_name);
        }
        if (format.specs.sentinel) {
            array.writeMany(tok.sentinel_type_name);
        }
        if (format.techs.lazy_alignment) {
            array.writeMany(tok.lazy_alignment_type_name);
        }
        if (format.techs.unit_alignment) {
            array.writeMany(tok.unit_alignment_type_name);
        }
        if (format.techs.disjunct_alignment) {
            array.writeMany(tok.disjunct_alignment_type_name);
        }
        if (format.techs.double_packed_approximate_capacity) {
            array.writeMany(tok.double_packed_approximate_capacity_type_name);
        }
        if (format.techs.single_packed_approximate_capacity) {
            array.writeMany(tok.single_packed_approximate_capacity_type_name);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        switch (format.kind) {
            .parametric => {
                len +%= tok.parametric_type_name.len;
            },
            .dynamic => {
                len +%= tok.dynamic_type_name.len;
            },
            .static => {
                len +%= tok.static_type_name.len;
            },
            .automatic => {
                len +%= tok.automatic_type_name.len;
            },
        }
        switch (format.layout) {
            .structured => {
                len +%= tok.structured_type_name.len;
            },
            .unstructured => {
                len +%= tok.unstructured_type_name.len;
            },
        }
        if (format.modes.read_write) {
            len +%= tok.read_write_type_name.len;
        }
        if (format.modes.stream) {
            len +%= tok.stream_type_name.len;
        }
        if (format.modes.resize) {
            len +%= tok.resize_type_name.len;
        }
        if (format.specs.arena) {
            len +%= tok.arena_type_name.len;
        }
        if (format.specs.sentinel) {
            len +%= tok.sentinel_type_name.len;
        }
        if (format.techs.lazy_alignment) {
            len +%= tok.lazy_alignment_type_name.len;
        }
        if (format.techs.unit_alignment) {
            len +%= tok.unit_alignment_type_name.len;
        }
        if (format.techs.disjunct_alignment) {
            len +%= tok.disjunct_alignment_type_name.len;
        }
        if (format.techs.double_packed_approximate_capacity) {
            len +%= tok.double_packed_approximate_capacity_type_name.len;
        }
        if (format.techs.single_packed_approximate_capacity) {
            len +%= tok.single_packed_approximate_capacity_type_name.len;
        }
        return len;
    }
};

pub const Options = struct {
    capacity: ?enum {
        single_packed_approximate,
        double_packed_approximate,
    },
    alignment: enum {
        auto,
        unit,
        lazy,
        disjunct,
    },
    relative: enum {
        arena,
        address_space,
    },
};
pub const Technique = union(enum) {
    standalone: Techniques.Tag,
    mutually_exclusive: Info,
    const Info = struct {
        kind: enum { mandatory, optional },
        opt_tag: Techniques.Options.Tag,
        tech_tag: ?Techniques.Tag = null,
        tech_tags: []const Techniques.Tag,
    };
    pub fn resolve(
        comptime opt: Technique,
        comptime tech_tag: Techniques.Tag,
    ) Technique {
        var ret: Technique = opt;
        ret.mutually_exclusive.tech_tag = tech_tag;
        return ret;
    }
    pub const Usage = enum {
        eliminate_boolean_false,
        eliminate_boolean_true,
        test_boolean,
        compare_enumeration,
        compare_optional_enumeration,
    };
    pub fn len(comptime tech: Technique) u64 {
        return tech.info.field_field_names.len;
    }
    pub fn count(tech: Technique, combinations: []const []const Technique) u64 {
        var ret: u64 = 0;
        for (combinations) |set| {
            if (tech == .standalone) {
                for (set) |elem| {
                    if (elem == .standalone and
                        tech.standalone == elem.standalone)
                    {
                        ret +%= 1;
                    }
                }
            } else {
                for (set) |elem| {
                    if (elem == .mutually_exclusive and
                        tech.mutually_exclusive.opt_tag ==
                        elem.mutually_exclusive.opt_tag)
                    {
                        ret +%= 1;
                    }
                }
            }
        }
        return ret;
    }
    pub fn usage(tech: Technique, combinations: []const []const Technique) Usage {
        const value: u64 = tech.count(combinations);
        switch (tech) {
            .standalone => switch (value) {
                0 => return .eliminate_boolean_false,
                else => return .test_boolean,
            },
            .mutually_exclusive => |mutually_exclusive| {
                switch (mutually_exclusive.kind) {
                    .optional => switch (value) {
                        0 => return .eliminate_boolean_false,
                        1 => return .test_boolean,
                        else => return .compare_optional_enumeration,
                    },
                    .mandatory => switch (value) {
                        0 => return .eliminate_boolean_false,
                        1 => return .eliminate_boolean_true,
                        else => return .compare_enumeration,
                    },
                }
            },
        }
    }
    pub fn tagName(comptime tech: Technique) []const u8 {
        const opt_tag_name: []const u8 = tech.optTagName();
        const tech_tag_name: []const u8 = tech.techTagName();
        return tech_tag_name[0 .. tech_tag_name.len - (opt_tag_name.len + 1)];
    }
    pub fn optTagName(tech: Technique) []const u8 {
        if (tech == .standalone) {
            return @tagName(tech.standalone);
        }
        return @tagName(tech.mutually_exclusive.opt_tag);
    }
    pub fn techTagName(tech: Technique) []const u8 {
        if (tech == .standalone) {
            return @tagName(tech.standalone);
        }
        return @tagName(tech.mutually_exclusive.tech_tag.?);
    }
    pub fn techTag(comptime tech: Technique) Techniques.Tag {
        if (tech == .standalone) {
            return tech.standalone;
        }
        return tech.mutually_exclusive.tech_tag.?;
    }
};
pub fn techniqueTags(options: []const Technique) Techniques {
    var int: Techniques.tag_type = 0;
    for (options) |option| {
        if (option == .standalone) {
            int |= @intFromEnum(option.standalone);
        } else {
            int |= @intFromEnum(option.mutually_exclusive.tech_tag.?);
        }
    }
    return @as(Techniques, @bitCast(int));
}
pub const Option = struct {
    kind: Option.Kind,
    info: Info,
    pub const Kind = enum {
        standalone,
        mutually_exclusive_optional,
        mutually_exclusive_mandatory,
    };
    pub const Usage = enum {
        eliminate_boolean_false,
        eliminate_boolean_true,
        test_boolean,
        compare_enumeration,
        compare_optional_enumeration,
    };
    pub const Info = struct {
        field_name: []const u8,
        field_field_names: []const []const u8,
    };
    pub fn len(comptime option: Option) u64 {
        return option.info.field_field_names.len;
    }
    pub fn count(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) u64 {
        var ret: u64 = 0;
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        inline for (option.info.field_field_names) |field_name| {
            ret +%= @intFromBool(@field(techs, field_name));
        }
        return ret;
    }
    pub fn names(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail, buf: [][]const u8) []const []const u8 {
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        var idx: u64 = 0;
        inline for (option.info.field_field_names) |field_name| {
            if (@field(techs, field_name)) {
                buf[idx] = field_name;
                idx +%= 1;
            }
        }
        return buf[0..idx];
    }
    pub fn usage(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) Usage {
        const value: u64 = option.count(Detail, toplevel_impl_group);
        switch (option.kind) {
            .standalone => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => unreachable,
            },
            .mutually_exclusive_optional => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => return .compare_optional_enumeration,
            },
            .mutually_exclusive_mandatory => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .eliminate_boolean_true,
                else => return .compare_enumeration,
            },
        }
    }
    pub fn fieldName(comptime option: Option, comptime index: u64) []const u8 {
        return option.info.field_field_names[index];
    }
    pub fn tagName(comptime option: Option, comptime index: u64) []const u8 {
        return option.fieldName(index)[0 .. option.fieldName(index).len - (option.info.field_name.len + 1)];
    }
};
