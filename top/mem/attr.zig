const gen = @import("./gen.zig");
const fmt = gen.fmt;
const meta = gen.meta;
const builtin = gen.builtin;
const testing = gen.testing;

// zig fmt: off
pub const abstract_specs: []const AbstractSpecification = &.{
    .{ .kind = .automatic,  .fields = au,           .layout = .structured,  .modes = rw,            .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ss,        .layout = .structured,  .modes = rw_str,        .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ub,        .layout = .structured,  .modes = rw_rsz,        .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ss_ub,     .layout = .structured,  .modes = rw_str_rsz,    .v_specs = auto_specs, .v_techs = auto_techs },

    .{ .kind = .static,    .fields = lb,            .layout = .structured, .modes = rw,             .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ss,         .layout = .structured, .modes = rw_str,         .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ub,         .layout = .structured, .modes = rw_rsz,         .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ss_ub,      .layout = .structured, .modes = rw_str_rsz,     .v_specs = s_dyn_specs, .v_techs = dyn_techs },

    .{ .kind = .dynamic,    .fields = lb_up,        .layout = .structured, .modes = rw,             .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_up,     .layout = .structured, .modes = rw_str,         .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ub_up,     .layout = .structured, .modes = rw_rsz,         .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub_up,  .layout = .structured, .modes = rw_str_rsz,     .v_specs = s_dyn_specs, .v_techs = dyn_techs },

    .{ .kind = .dynamic,    .fields = lb,           .layout = .structured, .modes = rw,             .v_specs = s_dyn_specs, .v_techs = dyn_techs_1 },
    .{ .kind = .dynamic,    .fields = lb_ss,        .layout = .structured, .modes = rw_str,         .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ub,        .layout = .structured, .modes = rw_rsz,         .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ss_ub,     .layout = .structured, .modes = rw_str_rsz,     .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },

    .{ .kind = .parametric, .fields = ub,           .layout = .structured, .modes = rw_rsz,         .v_specs = s_param_specs, .v_techs = param_techs },
    .{ .kind = .parametric, .fields = ub_ss,        .layout = .structured, .modes = rw_str_rsz,     .v_specs = s_param_specs, .v_techs = param_techs },

    .{ .kind = .static,    .fields = lb,            .layout = .unstructured, .modes = rw,           .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ss,         .layout = .unstructured, .modes = rw_str,       .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ub,         .layout = .unstructured, .modes = rw_rsz,       .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,    .fields = lb_ss_ub,      .layout = .unstructured, .modes = rw_str_rsz,   .v_specs = u_dyn_specs, .v_techs = dyn_techs },

    .{ .kind = .dynamic,    .fields = lb_up,        .layout = .unstructured, .modes = rw,           .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_up,     .layout = .unstructured, .modes = rw_str,       .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ub_up,     .layout = .unstructured, .modes = rw_rsz,       .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub_up,  .layout = .unstructured, .modes = rw_str_rsz,   .v_specs = u_dyn_specs, .v_techs = dyn_techs },

    .{ .kind = .dynamic,    .fields = lb,           .layout = .unstructured, .modes = rw,           .v_specs = u_dyn_specs, .v_techs = dyn_techs_1 },
    .{ .kind = .dynamic,    .fields = lb_ss,        .layout = .unstructured, .modes = rw_str,       .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ub,        .layout = .unstructured, .modes = rw_rsz,       .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ss_ub,     .layout = .unstructured, .modes = rw_str_rsz,   .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },

    .{ .kind = .parametric, .fields = ub,           .layout = .unstructured, .modes = rw_rsz,       .v_specs = u_dyn_specs, .v_techs = param_techs },
    .{ .kind = .parametric, .fields = ub_ss,        .layout = .unstructured, .modes = rw_str_rsz,   .v_specs = u_dyn_specs, .v_techs = param_techs },
};
// zig fmt: on

pub const Kinds = packed struct(u4) {
    automatic: bool = false,
    dynamic: bool = false,
    static: bool = false,
    parametric: bool = false,
    pub usingnamespace GenericStructOfBool(Kinds);
};
pub const Layouts = packed struct(u2) {
    structured: bool = false,
    unstructured: bool = false,
    pub usingnamespace GenericStructOfBool(Layouts);
};
pub const Modes = packed struct(u3) {
    read_write: bool = false,
    resize: bool = false,
    stream: bool = false,
    pub usingnamespace GenericStructOfBool(Modes);
};
pub const Fields = packed struct(u5) {
    automatic_storage: bool = false,
    allocated_byte_address: bool = false,
    undefined_byte_address: bool = false,
    unallocated_byte_address: bool = false,
    unstreamed_byte_address: bool = false,
    pub usingnamespace GenericStructOfBool(Fields);
};
pub const Managers = packed struct(u5) {
    allocatable: bool = false,
    reallocatable: bool = false,
    resizable: bool = false,
    movable: bool = false,
    convertible: bool = false,
    pub usingnamespace GenericStructOfBool(Managers);
};
pub const Specifiers = packed struct(u7) {
    child: bool = false,
    count: bool = false,
    sentinel: bool = false,
    low_alignment: bool = false,
    high_alignment: bool = false,
    Allocator: bool = false,
    arena: bool = false,
    pub usingnamespace GenericStructOfBool(Specifiers);
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
    pub usingnamespace GenericStructOfBool(Techniques);
    pub const Options = packed struct(u3) {
        alignment: bool = false,
        capacity: bool = false,
        relative: bool = false,
        pub usingnamespace GenericStructOfBool(Techniques.Options);
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
        type: type,
    };
    const Derived = struct {
        tag: Specifiers.Tag,
        fn_name: []const u8,
    };
    const SimpleDerived = struct {
        tag: Specifiers.Tag,
        type: type,
        fn_name: []const u8,
    };
    const Compound = struct {
        ctn_tag: Specifiers.Tag,
        decl_tag: Specifiers.Tag,
        ctn_type: type,
        decl_type: type,
    };
    const CompoundDerived = struct {
        ctn_tag: Specifiers.Tag,
        decl_tag: Specifiers.Tag,
        ctn_type: type,
        decl_type: type,
        fn_name: []const u8,
    };
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

const Kind = Kinds.Tag;
const Layout = Layouts.Tag;

pub const More = packed struct {
    kind: Kind,
    layout: Layout,
    modes: Modes,
    fields: Fields,
    techs: Techniques = undefined,
    specs: Specifiers = undefined,

    const Format = @This();

    pub fn half(comptime abstract_spec: AbstractSpecification) More {
        return .{
            .kind = abstract_spec.kind,
            .layout = abstract_spec.layout,
            .modes = Modes.detail(abstract_spec.modes),
            .fields = Fields.detail(abstract_spec.fields),
        };
    }
    pub fn full(
        comptime abstract_spec: AbstractSpecification,
        comptime specs: []const Specifier,
        comptime techs: []const Technique,
    ) More {
        return .{
            .kind = abstract_spec.kind,
            .layout = abstract_spec.layout,
            .modes = Modes.detail(abstract_spec.modes),
            .fields = Fields.detail(abstract_spec.fields),
            .specs = Specifiers.detail(specifiersTags(specs)),
            .techs = Techniques.detail(techniqueTags(techs)),
        };
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        switch (format.kind) {
            .parametric => len +%= "Parametric".len,
            .dynamic => len +%= "Dynamic".len,
            .static => len +%= "Static".len,
            .automatic => len +%= "Automatic".len,
        }
        switch (format.layout) {
            .structured => len +%= "Structured".len,
            .unstructured => len +%= "Unstructured".len,
        }
        if (format.modes.read_write) {
            len +%= "ReadWrite".len;
        }
        if (format.modes.stream) {
            len +%= "Stream".len;
        }
        if (format.modes.resize) {
            len +%= "Resize".len;
        }
        if (format.specs.arena) {
            len +%= "Arena".len;
        }
        if (format.specs.sentinel) {
            len +%= "Sentinel".len;
        }
        return len;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format.kind) {
            .parametric => array.writeMany("Parametric"),
            .dynamic => array.writeMany("Dynamic"),
            .static => array.writeMany("Static"),
            .automatic => array.writeMany("Automatic"),
        }
        switch (format.layout) {
            .structured => array.writeMany("Structured"),
            .unstructured => array.writeMany("Unstructured"),
        }
        if (format.modes.read_write) {
            array.writeMany("ReadWrite");
        }
        if (format.modes.stream) {
            array.writeMany("Stream");
        }
        if (format.modes.resize) {
            array.writeMany("Resize");
        }
        if (format.specs.arena) {
            array.writeMany("Arena");
        }
        if (format.specs.sentinel) {
            array.writeMany("Sentinel");
        }
    }
};

pub fn techniqueTags(comptime options: []const Technique) []const Techniques.Tag {
    comptime var ret: []const Techniques.Tag = &.{};
    inline for (options) |option| {
        if (option == .standalone) {
            ret = ret ++ .{option.standalone};
        } else {
            ret = ret ++ .{option.mutually_exclusive.tech_tag.?};
        }
    }
    return ret;
}
pub fn specifiersTags(comptime variants: []const Specifier) []const Specifiers.Tag {
    comptime var ret: []const Specifiers.Tag = &.{};
    inline for (variants) |variant| {
        switch (variant) {
            else => {
                ret = ret ++ .{comptime meta.resolve(variant).tag};
            },
            .decl_optional_derived,
            .decl_optional_variant,
            => {
                ret = ret ++ .{comptime meta.resolve(variant).decl_tag};
            },
        }
    }
    return ret;
}

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
    pub fn count(comptime tech: Technique, comptime combinations: []const []const Technique) u64 {
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
    pub fn usage(comptime tech: Technique, comptime combinations: []const []const Technique) Usage {
        const value: u64 = comptime tech.count(combinations);
        switch (tech) {
            .standalone => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => unreachable,
            },
            .mutually_exclusive => |mutually_exclusive| {
                switch (mutually_exclusive.kind) {
                    .optional => switch (value) {
                        0 => return .eliminate_boolean_false,
                        1 => return .test_boolean,
                        else => return .compare_enumeration,
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
    pub fn optTagName(comptime tech: Technique) []const u8 {
        return @tagName(tech.optTag());
    }
    pub fn techTagName(comptime tech: Technique) []const u8 {
        return @tagName(tech.techTag());
    }
    pub fn optTag(comptime tech: Technique) if (tech == .standalone) Techniques.Tag else Techniques.Options.Tag {
        if (tech == .standalone) {
            return tech.standalone;
        }
        return tech.mutually_exclusive.opt_tag;
    }
    pub fn techTag(comptime tech: Technique) Techniques.Tag {
        if (tech == .standalone) {
            return tech.standalone;
        }
        return tech.mutually_exclusive.tech_tag.?;
    }
};

pub const AbstractSpecification = struct {
    kind: Kinds.Tag,
    layout: Layouts.Tag,
    fields: []const Fields.Tag,
    modes: []const Modes.Tag,
    v_techs: []const Technique,
    v_specs: []const Specifier,
};
fn default(comptime tag: Specifiers.Tag, comptime @"type": type) Specifier {
    return .{ .default = .{ .tag = tag, .type = @"type" } };
}
fn derived(
    comptime tag: Specifiers.Tag,
    comptime @"type": type,
    comptime fn_name: [:0]const u8,
) Specifier {
    return .{ .derived = .{ .tag = tag, .type = @"type", .fn_name = fn_name } };
}
fn stripped(comptime tag: Specifiers.Tag, comptime @"type": type) Specifier {
    return .{ .stripped = .{ .tag = tag, .type = @"type" } };
}
fn optional_derived(
    comptime tag: Specifiers.Tag,
    comptime @"type": type,
    comptime fn_name: [:0]const u8,
) Specifier {
    return .{ .optional_derived = .{ .tag = tag, .type = @"type", .fn_name = fn_name } };
}
fn optional_variant(comptime tag: Specifiers.Tag, comptime @"type": type) Specifier {
    return .{ .optional_variant = .{ .tag = tag, .type = @"type" } };
}
fn decl_optional_derived(
    comptime ctn_tag: Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: Specifiers.Tag,
    comptime decl_type: type,
    comptime fn_name: [:0]const u8,
) Specifier {
    return .{ .decl_optional_derived = .{
        .ctn_tag = ctn_tag,
        .decl_tag = decl_tag,
        .ctn_type = ctn_type,
        .decl_type = decl_type,
        .fn_name = fn_name,
    } };
}
fn decl_optional_variant(
    comptime ctn_tag: Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: Specifiers.Tag,
    comptime decl_type: type,
) Specifier {
    return .{ .decl_optional_variant = .{
        .ctn_tag = ctn_tag,
        .decl_tag = decl_tag,
        .ctn_type = ctn_type,
        .decl_type = decl_type,
    } };
}
const auto_specs = &.{
    default(.child, type),
    default(.count, u64),
    optional_derived(.low_alignment, u64, "lowAlignment"),
    optional_variant(.sentinel, *const anyopaque),
};
const s_dyn_specs = &.{
    default(.child, type),
    optional_derived(.low_alignment, u64, "lowAlignment"),
    optional_variant(.sentinel, *const anyopaque),
    decl_optional_variant(.Allocator, type, .arena, struct { lb_addr: u64, up_addr: u64 }),
};
const u_dyn_specs = &.{
    optional_derived(.low_alignment, u64, "lowAlignment"),
    optional_variant(.sentinel, *const anyopaque),
    decl_optional_variant(.Allocator, type, .arena, struct { lb_addr: u64, up_addr: u64 }),
};
const s_param_specs = &.{
    default(.child, type),
    optional_derived(.low_alignment, u64, "lowAlignment"),
    optional_variant(.sentinel, *const anyopaque),
    default(.Allocator, type),
};
const u_param_specs = &.{
    optional_derived(.low_alignment, u64, "lowAlignment"),
    optional_variant(.sentinel, *const anyopaque),
    default(.Allocator, type),
};

fn standalone(comptime tech: Techniques.Tag) Technique {
    return .{ .standalone = tech };
}
fn mutually_exclusive_optional(comptime opt_tag: Techniques.Options.Tag, comptime tech_tags: []const Techniques.Tag) Technique {
    return .{ .mutually_exclusive = .{ .kind = .optional, .opt_tag = opt_tag, .tech_tags = tech_tags } };
}
fn mutually_exclusive_mandatory(comptime opt_tag: Techniques.Options.Tag, comptime tech_tags: []const Techniques.Tag) Technique {
    return .{ .mutually_exclusive = .{ .kind = .mandatory, .opt_tag = opt_tag, .tech_tags = tech_tags } };
}
pub fn mutually_exclusive_resolved_optional(comptime opt_info: Technique.Info, comptime tech_tag: Techniques.Tag) Technique {
    return .{ .mutually_exclusive = .{
        .kind = .optional,
        .opt_tag = opt_info.mutually_exclusive.opt_tag,
        .tech_tag = tech_tag,
        .tech_tags = opt_info.tech_tags,
    } };
}
pub fn mutually_exclusive_resolved_mandatory(comptime opt_info: Technique.Info, comptime tech_tag: Techniques.Tag) Technique {
    return .{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = opt_info.opt_tag,
        .tech_tag = tech_tag,
        .tech_tags = opt_info.tech_tags,
    } };
}

const auto_alignment_opt: Technique = standalone(.auto_alignment);
const capacity_opt: Technique = standalone(.single_packed_approximate_capacity);
const alignment_opts: Technique = mutually_exclusive_mandatory(.alignment, &.{
    .lazy_alignment,
    .unit_alignment,
    .disjunct_alignment,
});
const param_alignment_opts: Technique = mutually_exclusive_mandatory(.alignment, &.{
    .lazy_alignment,
    .unit_alignment,
});
const capacity_opts: Technique = mutually_exclusive_optional(.capacity, &.{
    .single_packed_approximate_capacity,
    .double_packed_approximate_capacity,
});
const auto_techs: []const Technique = &.{};
const dyn_techs: []const Technique = &.{
    alignment_opts,
};
const dyn_techs_1: []const Technique = &.{
    capacity_opt,
    alignment_opts,
};
const dyn_techs_2: []const Technique = &.{
    alignment_opts,
    capacity_opts,
};
const param_techs: []const Technique = &.{
    param_alignment_opts,
};
const rw: []const Modes.Tag = &.{
    .read_write,
};
const rw_str: []const Modes.Tag = &.{
    .read_write,
    .stream,
};
const rw_rsz: []const Modes.Tag = &.{
    .read_write,
    .resize,
};
const rw_str_rsz: []const Modes.Tag = &.{
    .read_write,
    .stream,
    .resize,
};
const au: []const Fields.Tag = &.{
    .automatic_storage,
};
const au_ss: []const Fields.Tag = &.{
    .automatic_storage,
    .unstreamed_byte_address,
};
const au_ub: []const Fields.Tag = &.{
    .automatic_storage,
    .undefined_byte_address,
};
const au_ss_ub: []const Fields.Tag = &.{
    .automatic_storage,
    .unstreamed_byte_address,
    .undefined_byte_address,
};
const lb: []const Fields.Tag = &.{
    .allocated_byte_address,
};
const lb_ss: []const Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
};
const lb_ub: []const Fields.Tag = &.{
    .allocated_byte_address,
    .undefined_byte_address,
};
const lb_ss_ub: []const Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .undefined_byte_address,
};
const lb_up: []const Fields.Tag = &.{
    .allocated_byte_address,
    .unallocated_byte_address,
};
const lb_ss_up: []const Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .unallocated_byte_address,
};
const lb_ub_up: []const Fields.Tag = &.{
    .allocated_byte_address,
    .undefined_byte_address,
    .unallocated_byte_address,
};
const lb_ss_ub_up: []const Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .undefined_byte_address,
    .unallocated_byte_address,
};
const ub: []const Fields.Tag = &.{
    .undefined_byte_address,
};
const ub_ss: []const Fields.Tag = &.{
    .undefined_byte_address,
    .unstreamed_byte_address,
};

const S: []const Layouts.Tag = &.{
    .structured,
};
const SU: []const Layouts.Tag = &.{
    .structured,
    .unstructured,
};
pub fn GenericStructOfBool(comptime Struct: type) type {
    return struct {
        const tag_type: type = @typeInfo(Struct).Struct.backing_integer.?;
        pub const Tag = blk: {
            var fields: []const builtin.Type.EnumField = &.{};
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                fields = fields ++ [1]builtin.Type.EnumField{.{
                    .name = field.name,
                    .value = 1 << @bitOffsetOf(Struct, field.name),
                }};
            }
            break :blk @Type(.{ .Enum = .{
                .fields = fields,
                .tag_type = tag_type,
                .decls = &.{},
                .is_exhaustive = false,
            } });
        };
        pub fn detail(comptime tags: []const Tag) Struct {
            comptime var int: tag_type = 0;
            for (tags) |tag| {
                int |= @enumToInt(tag);
            }
            return @bitCast(Struct, int);
        }
        pub const tag_list: []const Tag = meta.tagList(Tag);
        pub fn countTrue(bit_field: Struct) u64 {
            var ret: u64 = 0;
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                ret +%= @boolToInt(@field(bit_field, field.name));
            }
            return ret;
        }
        pub fn formatWrite(format: Struct, array: anytype) void {
            if (countTrue(format) == 0) {
                array.writeMany(".{}");
            } else {
                array.writeMany(".{");
                inline for (@typeInfo(Struct).Struct.fields) |field| {
                    if (@field(format, field.name)) {
                        array.writeMany("." ++ field.name ++ "=true,");
                    }
                }
                array.undefine(1);
                array.writeOne('}');
            }
        }
        pub fn formatLength(format: Struct) u64 {
            var len: u64 = 3;
            if (countTrue(format) != 0) {
                len -%= 1;
                inline for (@typeInfo(Struct).Struct.fields) |field| {
                    if (@field(format, field.name)) {
                        len +%= 1 +% field.name.len +% 6;
                    }
                }
            }
            return len;
        }
    };
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
            ret +%= @boolToInt(@field(techs, field_name));
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
pub const Fn = struct {
    fn isPrefix(prefix: []const u8, values: []const u8) bool {
        if (prefix.len > values.len) {
            return false;
        }
        return streql(prefix, values[0..prefix.len]);
    }
    fn isSuffix(suffix: []const u8, values: []const u8) bool {
        if (suffix.len > values.len) {
            return false;
        }
        return streql(suffix, values[values.len - suffix.len ..]);
    }
    fn isWithin(within: []const u8, values: []const u8) bool {
        if (within.len > values.len) {
            return false;
        }
        var idx: u64 = 0;
        while (idx != values.len) : (idx +%= 1) {
            if (values.len -% idx == within.len) {
                return streql(within, values[idx..]);
            }
            if (streql(within, values[idx .. idx + within.len])) {
                return true;
            }
        }
        return false;
    }
    fn streql(arg1: []const u8, arg2: []const u8) bool {
        for (arg1, arg2) |x, y| {
            if (x != y) return false;
        }
        return true;
    }
    fn Array(comptime Allocator: type, comptime Tag: type) type {
        return Allocator.StructuredVector(Tag);
    }
    pub fn Pair(comptime Allocator: type, comptime Tag: type) type {
        return struct {
            Allocator.StructuredVector(Tag),
            Allocator.StructuredVector(Tag),
        };
    }
    pub fn prefixSubTag(comptime Tag: type, allocator: anytype, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isPrefix(@tagName(sub_tag), @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn suffixSubTag(comptime Tag: type, allocator: anytype, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isSuffix(@tagName(sub_tag), @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn subTag(comptime Tag: type, allocator: anytype, array: anytype, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        _ = array;
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isWithin(@tagName(sub_tag), @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn prefixSubTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isPrefix(@tagName(sub_tag), field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn suffixSubTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isSuffix(@tagName(sub_tag), field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn subTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isWithin(@tagName(sub_tag), field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn writeKind(comptime Tag: type, array: anytype, comptime kind_tag: @Type(.EnumLiteral), set: anytype) void {
        array.writeMany("pub fn ");
        array.writeMany(@tagName(kind_tag));
        array.writeMany("(tag:" ++ @typeName(Tag)["top.mem.".len..] ++ ")bool{\nswitch(tag){");
        for (set.readAll()) |elem| {
            array.writeMany(".");
            array.writeMany(@tagName(elem));
            array.writeMany(",");
        }
        array.writeMany("=>return true,else=>return false}\n}\n");
    }
    pub const static = struct {
        pub fn Pair(comptime Tag: type) type {
            return struct { []const Tag, []const Tag };
        }
        pub inline fn prefixSubTag(comptime Tag: type, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            @setEvalBranchQuota(~@as(u32, 0));
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (sub_set) |tag| {
                if (comptime isPrefix(@tagName(sub_tag), @tagName(tag))) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn suffixSubTag(comptime Tag: type, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            @setEvalBranchQuota(~@as(u32, 0));
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (sub_set) |tag| {
                if (comptime isSuffix(@tagName(sub_tag), @tagName(tag))) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn subTag(comptime Tag: type, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            @setEvalBranchQuota(~@as(u32, 0));
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (sub_set) |tag| {
                if (comptime isWithin(@tagName(sub_tag), @tagName(tag))) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn prefixSubTagNew(comptime Tag: type, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (@typeInfo(Tag).Enum.fields) |field| {
                const tag: Tag = @field(Tag, field.name);
                if (comptime isPrefix(@tagName(sub_tag), field.name)) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn suffixSubTagNew(comptime Tag: type, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (@typeInfo(Tag).Enum.fields) |field| {
                const tag: Tag = @field(Tag, field.name);
                if (comptime isSuffix(@tagName(sub_tag), field.name)) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn subTagNew(comptime Tag: type, comptime sub_tag: @Type(.EnumLiteral)) static.Pair(Tag) {
            comptime var ret: static.Pair(Tag) = .{ &.{}, &.{} };
            inline for (@typeInfo(Tag).Enum.fields) |field| {
                const tag: Tag = @field(Tag, field.name);
                if (comptime isWithin(@tagName(sub_tag), field.name)) {
                    ret[1] = ret[1] ++ [1]Tag{tag};
                } else {
                    ret[0] = ret[0] ++ [1]Tag{tag};
                }
            }
            return ret;
        }
        pub inline fn writeKindSwitch(comptime Tag: type, array: anytype, comptime kind_tag: @Type(.EnumLiteral), set: []const Tag) void {
            array.writeMany("pub fn ");
            array.writeMany(@tagName(kind_tag));
            array.writeMany("(tag:" ++ @typeName(Tag)["top.mem.".len..] ++ ")bool{\nswitch(tag){");
            for (set) |elem| {
                array.writeMany(".");
                array.writeMany(@tagName(elem));
                array.writeMany(",");
            }
            array.writeMany("=>return true,else=>return false}\n}\n");
        }
        pub fn writeKindBool(comptime Tag: type, array: anytype, fn_name: [:0]const u8, set: []const Tag) void {
            array.writeMany("pub fn ");
            array.writeMany(fn_name);
            array.writeMany("(tag:" ++ @typeName(Tag)["top.mem.".len..] ++ ")bool{\ninline for (.{");
            for (set) |elem| {
                array.writeMany(".");
                array.writeMany(@tagName(elem));
                array.writeMany(",");
            }
            array.writeMany("})|sub_tag|{if(tag==sub_tag)return true;}return false;}\n");
        }
    };
};
comptime {
    const attribute_types: [6]type = .{ Modes, Kinds, Layouts, Fields, Managers, Techniques };
    inline for (attribute_types, 0..) |l_struct_of_bool, index| {
        inline for (@typeInfo(l_struct_of_bool).Struct.fields) |field| {
            inline for (attribute_types[index + 1 ..]) |r_struct_of_bool| {
                if (@hasField(r_struct_of_bool, field.name)) {
                    @compileError(@typeName(l_struct_of_bool) ++ ", " ++
                        @typeName(r_struct_of_bool) ++ " share non-unique attribute name: " ++ field.name);
                }
            }
        }
    }
}
