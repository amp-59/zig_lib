const gen = @import("./gen.zig");
const fmt = gen.fmt;
const meta = gen.meta;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");

// zig fmt: off
pub const abstract_specs: [32]types.AbstractSpecification = [_]types.AbstractSpecification{
    .{ .kind = .automatic,  .fields = au,           .layout = .structured,      .modes = rw,            .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ss,        .layout = .structured,      .modes = rw_str,        .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ub,        .layout = .structured,      .modes = rw_rsz,        .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .automatic,  .fields = au_ss_ub,     .layout = .structured,      .modes = rw_str_rsz,    .v_specs = auto_specs, .v_techs = auto_techs },
    .{ .kind = .dynamic,    .fields = lb_up,        .layout = .structured,      .modes = rw,            .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_up,     .layout = .structured,      .modes = rw_str,        .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ub_up,     .layout = .structured,      .modes = rw_rsz,        .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub_up,  .layout = .structured,      .modes = rw_str_rsz,    .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb,           .layout = .structured,      .modes = rw,            .v_specs = s_dyn_specs, .v_techs = dyn_techs_1 },
    .{ .kind = .dynamic,    .fields = lb_ss,        .layout = .structured,      .modes = rw_str,        .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ub,        .layout = .structured,      .modes = rw_rsz,        .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ss_ub,     .layout = .structured,      .modes = rw_str_rsz,    .v_specs = s_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_up,        .layout = .unstructured,    .modes = rw,            .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_up,     .layout = .unstructured,    .modes = rw_str,        .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ub_up,     .layout = .unstructured,    .modes = rw_rsz,        .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb_ss_ub_up,  .layout = .unstructured,    .modes = rw_str_rsz,    .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .dynamic,    .fields = lb,           .layout = .unstructured,    .modes = rw,            .v_specs = u_dyn_specs, .v_techs = dyn_techs_1 },
    .{ .kind = .dynamic,    .fields = lb_ss,        .layout = .unstructured,    .modes = rw_str,        .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ub,        .layout = .unstructured,    .modes = rw_rsz,        .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .dynamic,    .fields = lb_ss_ub,     .layout = .unstructured,    .modes = rw_str_rsz,    .v_specs = u_dyn_specs, .v_techs = dyn_techs_2 },
    .{ .kind = .static,     .fields = lb,           .layout = .structured,      .modes = rw,            .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ss,        .layout = .structured,      .modes = rw_str,        .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ub,        .layout = .structured,      .modes = rw_rsz,        .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ss_ub,     .layout = .structured,      .modes = rw_str_rsz,    .v_specs = s_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb,           .layout = .unstructured,    .modes = rw,            .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ss,        .layout = .unstructured,    .modes = rw_str,        .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ub,        .layout = .unstructured,    .modes = rw_rsz,        .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .static,     .fields = lb_ss_ub,     .layout = .unstructured,    .modes = rw_str_rsz,    .v_specs = u_dyn_specs, .v_techs = dyn_techs },
    .{ .kind = .parametric, .fields = ub,           .layout = .structured,      .modes = rw_rsz,        .v_specs = s_param_specs, .v_techs = param_techs },
    .{ .kind = .parametric, .fields = ub_ss,        .layout = .structured,      .modes = rw_str_rsz,    .v_specs = s_param_specs, .v_techs = param_techs },
    .{ .kind = .parametric, .fields = ub,           .layout = .unstructured,    .modes = rw_rsz,        .v_specs = u_param_specs, .v_techs = param_techs },
    .{ .kind = .parametric, .fields = ub_ss,        .layout = .unstructured,    .modes = rw_str_rsz,    .v_specs = u_param_specs, .v_techs = param_techs },
};
// zig fmt: on
pub const ctn_details: []const types.Container = blk: {
    var res: []const meta.Child(types.Container) = &.{};
    for (abstract_specs) |abstract_spec| {
        const ctn_detail: meta.Child(types.Container) = meta.leastBitCast(types.Container.init(abstract_spec));
        for (res) |unique_ctn_detail| {
            if (ctn_detail == unique_ctn_detail) {
                break;
            }
        } else {
            res = res ++ .{ctn_detail};
        }
    }
    break :blk @ptrCast([]const types.Container, res);
};
pub const ctn_groups: []const []const types.AbstractSpecification = blk: {
    @setEvalBranchQuota(4000);
    var buf: [abstract_specs.len][]const types.AbstractSpecification = .{&.{}} ** abstract_specs.len;
    var len: u64 = 0;
    var idx: u64 = 0;
    var taken: [abstract_specs.len]bool = [1]bool{false} ** abstract_specs.len;
    for (@ptrCast([]const meta.Child(types.Container), ctn_details)) |ctn_detail| {
        for (abstract_specs, 0..) |abstract_spec, spec_index| {
            if (taken[spec_index]) {
                continue;
            }
            if (ctn_detail == meta.leastBitCast(types.Container.init(abstract_spec))) {
                taken[spec_index] = true;
                buf[idx] = buf[idx] ++ .{abstract_spec};
            }
        }
        if (buf[idx].len != 0) {
            len +%= 1;
        }
    }
    break :blk buf[0..len];
};
fn default(comptime tag: types.Specifiers.Tag, comptime @"type": type) types.Specifier {
    return .{ .default = .{ .tag = tag, .type = types.ProtoTypeDescr.init(@"type") } };
}
fn derived(
    comptime tag: types.Specifiers.Tag,
    comptime @"type": type,
    comptime fn_name: [:0]const u8,
) types.Specifier {
    return .{ .derived = .{ .tag = tag, .type = types.ProtoTypeDescr.init(@"type"), .fn_name = fn_name } };
}
fn stripped(comptime tag: types.Specifiers.Tag, comptime @"type": type) types.Specifier {
    return .{ .stripped = .{ .tag = tag, .type = types.ProtoTypeDescr.init(@"type") } };
}
fn optional_derived(
    comptime tag: types.Specifiers.Tag,
    comptime @"type": type,
    comptime fn_name: [:0]const u8,
) types.Specifier {
    return .{ .optional_derived = .{ .tag = tag, .type = types.ProtoTypeDescr.init(@"type"), .fn_name = fn_name } };
}
fn optional_variant(comptime tag: types.Specifiers.Tag, comptime @"type": type) types.Specifier {
    return .{ .optional_variant = .{ .tag = tag, .type = types.ProtoTypeDescr.init(@"type") } };
}
fn decl_optional_derived(
    comptime ctn_tag: types.Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: types.Specifiers.Tag,
    comptime decl_type: type,
    comptime fn_name: [:0]const u8,
) types.Specifier {
    return .{ .decl_optional_derived = .{
        .ctn_tag = ctn_tag,
        .decl_tag = decl_tag,
        .ctn_type = types.ProtoTypeDescr.init(ctn_type),
        .decl_type = types.ProtoTypeDescr.init(decl_type),
        .fn_name = fn_name,
    } };
}
fn decl_optional_variant(
    comptime ctn_tag: types.Specifiers.Tag,
    comptime ctn_type: type,
    comptime decl_tag: types.Specifiers.Tag,
    comptime decl_type: type,
) types.Specifier {
    return .{ .decl_optional_variant = .{
        .ctn_tag = ctn_tag,
        .decl_tag = decl_tag,
        .ctn_type = types.ProtoTypeDescr.init(ctn_type),
        .decl_type = types.ProtoTypeDescr.init(decl_type),
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
fn standalone(comptime tech: types.Techniques.Tag) types.Technique {
    return .{ .standalone = tech };
}
fn mutually_exclusive_optional(comptime opt_tag: types.Techniques.Options.Tag, comptime tech_tags: []const types.Techniques.Tag) types.Technique {
    return .{ .mutually_exclusive = .{ .kind = .optional, .opt_tag = opt_tag, .tech_tags = tech_tags } };
}
fn mutually_exclusive_mandatory(comptime opt_tag: types.Techniques.Options.Tag, comptime tech_tags: []const types.Techniques.Tag) types.Technique {
    return .{ .mutually_exclusive = .{ .kind = .mandatory, .opt_tag = opt_tag, .tech_tags = tech_tags } };
}
pub fn mutually_exclusive_resolved_optional(comptime opt_info: types.Technique.Info, comptime tech_tag: types.Techniques.Tag) types.Technique {
    return .{ .mutually_exclusive = .{
        .kind = .optional,
        .opt_tag = opt_info.mutually_exclusive.opt_tag,
        .tech_tag = tech_tag,
        .tech_tags = opt_info.tech_tags,
    } };
}
pub fn mutually_exclusive_resolved_mandatory(comptime opt_info: types.Technique.Info, comptime tech_tag: types.Techniques.Tag) types.Technique {
    return .{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = opt_info.opt_tag,
        .tech_tag = tech_tag,
        .tech_tags = opt_info.tech_tags,
    } };
}
const auto_alignment_opt: types.Technique = standalone(.auto_alignment);
const capacity_opt: types.Technique = standalone(.single_packed_approximate_capacity);
const alignment_opts: types.Technique = mutually_exclusive_mandatory(.alignment, &.{
    .lazy_alignment,
    .unit_alignment,
    .disjunct_alignment,
});
const param_alignment_opts: types.Technique = mutually_exclusive_mandatory(.alignment, &.{
    .lazy_alignment,
    .unit_alignment,
});
const capacity_opts: types.Technique = mutually_exclusive_optional(.capacity, &.{
    .single_packed_approximate_capacity,
    .double_packed_approximate_capacity,
});
const auto_techs: []const types.Technique = &.{};
const dyn_techs: []const types.Technique = &.{
    alignment_opts,
};
const dyn_techs_1: []const types.Technique = &.{
    capacity_opt,
    alignment_opts,
};
const dyn_techs_2: []const types.Technique = &.{
    alignment_opts,
    capacity_opts,
};
const param_techs: []const types.Technique = &.{
    param_alignment_opts,
};
const rw: []const types.Modes.Tag = &.{
    .read_write,
};
const rw_str: []const types.Modes.Tag = &.{
    .read_write,
    .stream,
};
const rw_rsz: []const types.Modes.Tag = &.{
    .read_write,
    .resize,
};
const rw_str_rsz: []const types.Modes.Tag = &.{
    .read_write,
    .stream,
    .resize,
};
const au: []const types.Fields.Tag = &.{
    .automatic_storage,
};
const au_ss: []const types.Fields.Tag = &.{
    .automatic_storage,
    .unstreamed_byte_address,
};
const au_ub: []const types.Fields.Tag = &.{
    .automatic_storage,
    .undefined_byte_address,
};
const au_ss_ub: []const types.Fields.Tag = &.{
    .automatic_storage,
    .unstreamed_byte_address,
    .undefined_byte_address,
};
const lb: []const types.Fields.Tag = &.{
    .allocated_byte_address,
};
const lb_ss: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
};
const lb_ub: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .undefined_byte_address,
};
const lb_ss_ub: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .undefined_byte_address,
};
const lb_up: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .unallocated_byte_address,
};
const lb_ss_up: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .unallocated_byte_address,
};
const lb_ub_up: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .undefined_byte_address,
    .unallocated_byte_address,
};
const lb_ss_ub_up: []const types.Fields.Tag = &.{
    .allocated_byte_address,
    .unstreamed_byte_address,
    .undefined_byte_address,
    .unallocated_byte_address,
};
const ub: []const types.Fields.Tag = &.{
    .undefined_byte_address,
};
const ub_ss: []const types.Fields.Tag = &.{
    .undefined_byte_address,
    .unstreamed_byte_address,
};

extern fn serializeSpecs(allocator: *config.Allocator, val: *const []const []const []const types.Specifier) void;
extern fn serializeTechs(allocator: *config.Allocator, val: *const []const []const []const types.Technique) void;
extern fn serializeOptions(allocator: *config.Allocator, val: *const []const []const types.Technique) void;
extern fn serializeParams(allocator: *config.Allocator, val: *const []const []const types.Specifier) void;
extern fn serializeAbstractSpecs(allocator: *config.Allocator, val: *const []const types.AbstractSpecification) void;
extern fn serializeImplDetail(allocator: *config.Allocator, val: *const []const types.Implementation) void;
extern fn serializeCtnDetail(allocator: *config.Allocator, val: *const []const types.Container) void;

extern fn deserializeSpecs(allocator: *config.Allocator, ptr: *[][][]types.Specifier) void;
extern fn deserializeTechs(allocator: *config.Allocator, ptr: *[][][]types.Technique) void;
extern fn deserializeOptions(allocator: *config.Allocator, ptr: *[][]types.Technique) void;
extern fn deserializeParams(allocator: *config.Allocator, ptr: *[][]types.Specifier) void;
extern fn deserializeAbstractSpecs(allocator: *config.Allocator, ptr: *[]types.AbstractSpecification) void;
extern fn deserializeImplDetail(allocator: *config.Allocator, ptr: *[]types.Implementation) void;
extern fn deserializeCtnDetail(allocator: *config.Allocator, ptr: *[]types.Container) void;

pub inline fn setSpecs(allocator: *config.Allocator, val: []const []const []const types.Specifier) void {
    serializeSpecs(allocator, &val);
}
pub inline fn setTechs(allocator: *config.Allocator, val: []const []const []const types.Technique) void {
    serializeTechs(allocator, &val);
}
pub inline fn setOptions(allocator: *config.Allocator, val: []const []const types.Technique) void {
    serializeOptions(allocator, &val);
}
pub inline fn setParams(allocator: *config.Allocator, val: []const []const types.Specifier) void {
    serializeParams(allocator, &val);
}
pub inline fn setAbstrParams(allocator: *config.Allocator, val: []const []const types.Specifier) void {
    serializeAbstractSpecs(allocator, &val);
}
pub inline fn setImplDetails(allocator: *config.Allocator, val: []const types.Implementation) void {
    serializeImplDetail(allocator, &val);
}
pub inline fn setCtnDetails(allocator: *config.Allocator, val: []const types.Container) void {
    serializeCtnDetail(allocator, &val);
}
pub inline fn getSpecs(allocator: *config.Allocator) []const []const []const types.Specifier {
    var ret: [][][]types.Specifier = undefined;
    deserializeSpecs(allocator, &ret);
    return ret;
}
pub inline fn getTechs(allocator: *config.Allocator) []const []const []const types.Technique {
    var ret: [][][]types.Technique = undefined;
    deserializeTechs(allocator, &ret);
    return ret;
}
pub inline fn getOptions(allocator: *config.Allocator) []const []const types.Technique {
    var ret: [][]types.Technique = undefined;
    deserializeOptions(allocator, &ret);
    return ret;
}
pub inline fn getParams(allocator: *config.Allocator) []const []const types.Specifier {
    var ret: [][]types.Specifier = undefined;
    deserializeParams(allocator, &ret);
    return ret;
}
pub inline fn getAbstrSpecs(allocator: *config.Allocator) []const types.AbstractSpecification {
    var ret: []types.AbstractSpecification = undefined;
    deserializeAbstractSpecs(allocator, &ret);
    return ret;
}
pub inline fn getImplDetails(allocator: *config.Allocator) []const types.Implementation {
    var ret: []types.Implementation = undefined;
    deserializeImplDetail(allocator, &ret);
    return ret;
}
pub inline fn getCtnDetails(allocator: *config.Allocator) []const types.Container {
    var ret: []types.Container = undefined;
    deserializeCtnDetail(allocator, &ret);
    return ret;
}

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
    pub fn subTag(comptime Tag: type, allocator: anytype, sub_set: anytype, comptime sub_tag: @Type(.EnumLiteral)) Pair(@TypeOf(allocator.*), Tag) {
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
