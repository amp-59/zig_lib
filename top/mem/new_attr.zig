const gen = @import("./gen.zig");
const meta = gen.meta;
const builtin = gen.builtin;

// zig fmt: off
pub const specs: []const Specification = &.{
    .{ .kind = .automatic,  .fields = au,            .layouts = S,  .modes = rw,            .techniques = auto_techs,   .specifiers = auto_specs },
    .{ .kind = .automatic,  .fields = au_ss,         .layouts = S,  .modes = rw_str,        .techniques = auto_techs,   .specifiers = auto_specs },
    .{ .kind = .automatic,  .fields = au_ub,         .layouts = S,  .modes = rw_rsz,        .techniques = auto_techs,   .specifiers = auto_specs },
    .{ .kind = .automatic,  .fields = au_ss_ub,      .layouts = S,  .modes = rw_str_rsz,    .techniques = auto_techs,   .specifiers = auto_specs },

    .{ .kind = .dynamic,    .fields = lb_up,         .layouts = SU, .modes = rw,            .techniques = dyn_techs,    .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ss_up,      .layouts = SU, .modes = rw_str,        .techniques = dyn_techs,    .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ub_up,      .layouts = SU, .modes = rw_rsz,        .techniques = dyn_techs,    .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub_up,   .layouts = SU, .modes = rw_str_rsz,    .techniques = dyn_techs,    .specifiers = dyn_specs },

    .{ .kind = .dynamic,    .fields = lb,            .layouts = SU, .modes = rw,            .techniques = dyn_techs_1,  .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ss,         .layouts = SU, .modes = rw_str,        .techniques = dyn_techs_2,  .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ub,         .layouts = SU, .modes = rw_rsz,        .techniques = dyn_techs_2,  .specifiers = dyn_specs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub,      .layouts = SU, .modes = rw_str_rsz,    .techniques = dyn_techs_2,  .specifiers = dyn_specs },
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
};
const Variant = union(enum) {
    default: Simple,
    stripped: Simple,
    derived: Simple,
    optional_derived: Simple,
    optional_variant: Simple,
    decl_optional_derived: Compound,
    decl_optional_variant: Compound,

    const Simple = struct {
        tag: Specifiers.Tag,
        type: type,
    };
    const Compound = struct {
        ctn_tag: Specifiers.Tag,
        decl_tag: Specifiers.Tag,
        ctn_type: type,
        decl_type: type,
    };
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
const Specification = struct {
    kind: Kinds.Tag,
    fields: []const Fields.Tag,
    modes: []const Modes.Tag,
    layouts: []const Layouts.Tag,
    techniques: []const Techniques.Tag,
    specifiers: []const Variant,
};

fn default(comptime tag: Specifiers.Tag, comptime @"type": type) Variant {
    return .{ .default = .{ .tag = tag, .type = @"type" } };
}
fn stripped(comptime tag: Specifiers.Tag, comptime @"type": type) Variant {
    return .{ .stripped = .{ .tag = tag, .type = @"type" } };
}
fn derived(comptime tag: Specifiers.Tag, comptime @"type": type) Variant {
    return .{ .derived = .{ .tag = tag, .type = @"type" } };
}
fn optional_derived(comptime tag: Specifiers.Tag, comptime @"type": type) Variant {
    return .{ .optional_derived = .{ .tag = tag, .type = @"type" } };
}
fn optional_variant(comptime tag: Specifiers.Tag, comptime @"type": type) Variant {
    return .{ .optional_variant = .{ .tag = tag, .type = @"type" } };
}
fn decl_optional_derived(
    comptime ctn_tag: Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: Specifiers.Tag,
    comptime decl_type: type,
) Variant {
    return .{ .decl_optional_derived = .{
        .ctn_tag = ctn_tag,
        .decl_tag = decl_tag,
        .ctn_type = ctn_type,
        .decl_type = decl_type,
    } };
}
fn decl_optional_variant(
    comptime ctn_tag: Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: Specifiers.Tag,
    comptime decl_type: type,
) Variant {
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
    optional_derived(.low_alignment, u64),
    optional_variant(.sentinel, *const anyopaque),
};
const Arena = struct { lb_addr: u64, up_addr: u64 };
const dyn_specs = &.{
    default(.child, type),
    optional_derived(.low_alignment, u64),
    optional_variant(.sentinel, *const anyopaque),
    decl_optional_variant(.Allocator, type, .arena, Arena),
};
const auto_techs = &.{
    .auto_alignment,
};
const dyn_techs = &.{
    .lazy_alignment,
    .unit_alignment,
    .disjunct_alignment,
};
const dyn_techs_1 = &.{
    .lazy_alignment,
    .unit_alignment,
    .disjunct_alignment,
    .single_packed_approximate_capacity,
};
const dyn_techs_2 = &.{
    .lazy_alignment,
    .unit_alignment,
    .disjunct_alignment,
    .single_packed_approximate_capacity,
    .double_packed_approximate_capacity,
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
const S: []const Layouts.Tag = &.{
    .structured,
};
const SU: []const Layouts.Tag = &.{
    .structured,
    .unstructured,
};
pub fn GenericStructOfBool(comptime Struct: type) type {
    return struct {
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
                .tag_type = @typeInfo(Struct).Struct.backing_integer.?,
                .decls = &.{},
                .is_exhaustive = false,
            } });
        };
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
