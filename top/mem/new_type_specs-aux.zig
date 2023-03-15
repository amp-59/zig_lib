//! This stage summarises the abstract specification.
const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const file = gen.file;
const meta = gen.meta;
const proc = gen.proc;
const preset = gen.preset;
const testing = gen.testing;
const builtin = gen.builtin;

const tok = @import("./tok.zig");
const attr = @import("./attr.zig");
const abstract_spec = @import("./abstract_spec.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);
const InfoS = attr.Specifier;
const InfoT = attr.Technique;

fn BinaryFilter(comptime T: type) type {
    return struct { []const T, []const T };
}

const S = struct {
    var param_no: u64 = 0;
    var spec_no: u64 = 0;
    var impl_no: u64 = 0;
};
fn haveSpec(
    comptime s_v_infos: []const []const InfoS,
    comptime p_field: InfoS,
) BinaryFilter([]const InfoS) {
    comptime var t: []const []const InfoS = meta.empty;
    comptime var f: []const []const InfoS = meta.empty;
    inline for (s_v_infos) |s_v_info| {
        inline for (s_v_info) |s_v_field| {
            if (builtin.testEqual(InfoS, p_field, s_v_field)) {
                t = t ++ .{s_v_info};
                break;
            }
        } else {
            f = f ++ .{s_v_info};
        }
    }
    return .{ f, t };
}
fn populateParameters(comptime spec: attr.AbstractSpecification) [3][]const InfoS {
    var p_info: []const InfoS = &.{};
    var s_info: []const InfoS = &.{};
    var v_info: []const InfoS = &.{};
    for (spec.v_specs) |v_spec| {
        const info: InfoS = v_spec;
        switch (v_spec) {
            .derived => {
                s_info = s_info ++ .{info};
            },
            .stripped => {
                p_info = p_info ++ .{info};
            },
            .default, .optional_derived, .decl_optional_derived => {
                p_info = p_info ++ .{info};
                s_info = s_info ++ .{info};
            },
            .optional_variant, .decl_optional_variant => {
                p_info = p_info ++ .{info};
                v_info = v_info ++ .{info};
            },
        }
    }
    return .{ p_info, s_info, v_info };
}
fn populateTechniques(comptime spec: attr.AbstractSpecification) []const []const InfoT {
    var v_i_infos: []const []const InfoT = &.{&.{}};
    for (spec.v_techs) |v_tech| {
        switch (v_tech) {
            .standalone => {
                for (v_i_infos) |i_info| {
                    v_i_infos = v_i_infos ++ .{i_info ++ .{v_tech}};
                }
            },
            .mutually_exclusive => |mutually_exclusive| {
                switch (mutually_exclusive.kind) {
                    .optional => {
                        for (v_i_infos) |i_info| {
                            for (mutually_exclusive.tech_tags) |j_info| {
                                v_i_infos = v_i_infos ++ .{i_info ++ .{v_tech.resolve(j_info)}};
                            }
                        }
                    },
                    .mandatory => {
                        var j_infos: []const []const InfoT = &.{};
                        for (v_i_infos) |i_info| {
                            for (mutually_exclusive.tech_tags) |j_info| {
                                j_infos = j_infos ++ .{i_info ++ .{v_tech.resolve(j_info)}};
                            }
                        }
                        v_i_infos = j_infos;
                    },
                }
            },
        }
    }
    return v_i_infos;
}
fn populateSpecifiers(
    comptime s_info: []const InfoS,
    comptime v_info: []const InfoS,
) []const []const InfoS {
    var s_v_infos: []const []const InfoS = &.{};
    s_v_infos = s_v_infos ++ .{s_info};
    for (v_info) |v_field| {
        for (s_v_infos) |s_v_info| {
            s_v_infos = s_v_infos ++ .{s_v_info ++ .{v_field}};
        }
    }
    return s_v_infos;
}
fn populateDetails(
    comptime spec: attr.AbstractSpecification,
    comptime p_idx: u8,
    comptime s_v_infos: []const []const InfoS,
    comptime v_i_infos: []const []const InfoT,
) []const attr.More {
    var details: []const attr.More = &.{};
    var detail: attr.More = attr.More.init(spec, p_idx);
    for (spec.v_layouts) |v_layout| {
        detail.layout = v_layout;
        for (s_v_infos, 0..) |s_v_info, s_idx| {
            detail.specs = attr.Specifiers.detail(attr.specifiersTags(s_v_info));
            detail.spec_idx = s_idx;
            for (v_i_infos, 0..) |v_i_info, i_idx| {
                detail.impl_idx = i_idx;
                detail.techs = attr.Techniques.detail(attr.techniqueTags(v_i_info));
                details = details ++ .{detail};
            }
        }
    }
    return details;
}
fn writeFields(array: *Array, comptime p_info: []const InfoS) void {
    inline for (p_info) |p_field| {
        const field_name: []const u8 = comptime parametersFieldName(p_field);
        const field_type_name: []const u8 = comptime parametersTypeName(p_field);
        array.writeMany(field_name ++ ":" ++ field_type_name ++ ",");
    }
}
fn parametersFieldName(comptime p_field: InfoS) []const u8 {
    switch (p_field) {
        .default => |default| {
            return @tagName(default.tag);
        },
        .stripped => |stripped| {
            return @tagName(stripped.tag);
        },
        .optional_derived => |optional_derived| {
            return @tagName(optional_derived.tag);
        },
        .optional_variant => |optional_variant| {
            return @tagName(optional_variant.tag);
        },
        .decl_optional_derived => |decl_optional_derived| {
            return @tagName(decl_optional_derived.ctn_tag);
        },
        .decl_optional_variant => |decl_optional_variant| {
            return @tagName(decl_optional_variant.ctn_tag);
        },
        .derived => {
            @compileError("???");
        },
    }
}
fn specificationFieldName(comptime s_v_field: InfoS) []const u8 {
    switch (s_v_field) {
        .default => |default| {
            return @tagName(default.tag);
        },
        .derived => |derived| {
            return @tagName(derived.tag);
        },
        .optional_derived => |optional_derived| {
            return @tagName(optional_derived.tag);
        },
        .optional_variant => |optional_variant| {
            return @tagName(optional_variant.tag);
        },
        .decl_optional_derived => |decl_optional_derived| {
            return @tagName(decl_optional_derived.decl_tag);
        },
        .decl_optional_variant => |decl_optional_variant| {
            return @tagName(decl_optional_variant.decl_tag);
        },
        .stripped => {
            @compileError("???");
        },
    }
}
fn parametersTypeName(comptime p_field: InfoS) []const u8 {
    switch (p_field) {
        .default => |default| {
            return @typeName(default.type);
        },
        .stripped => |stripped| {
            return @typeName(stripped.type);
        },
        .optional_derived => |optional_derived| {
            return @typeName(optional_derived.type);
        },
        .optional_variant => |optional_variant| {
            return @typeName(optional_variant.type);
        },
        .decl_optional_derived => |decl_optional_derived| {
            return @typeName(decl_optional_derived.ctn_type);
        },
        .decl_optional_variant => |decl_optional_variant| {
            return @typeName(decl_optional_variant.ctn_type);
        },
        .derived => {
            @compileError("???");
        },
    }
}
fn specificationTypeName(s_v_field: InfoS) []const u8 {
    switch (s_v_field) {
        .default => |default| {
            return @typeName(default.type);
        },
        .derived => |derived| {
            return @typeName(derived.type);
        },
        .optional_derived => |optional_derived| {
            return @typeName(optional_derived.type);
        },
        .optional_variant => |optional_variant| {
            return @typeName(optional_variant.type);
        },
        .decl_optional_derived => |decl_optional_derived| {
            return @typeName(decl_optional_derived.decl_type);
        },
        .decl_optional_variant => |decl_optional_variant| {
            return @typeName(decl_optional_variant.decl_type);
        },
        .stripped => {
            @compileError("???");
        },
    }
}
fn declExpr(comptime p_field: InfoS) []const u8 {
    switch (p_field) {
        .default => |default| {
            const tag_name: []const u8 = @tagName(default.tag);
            const type_name: []const u8 = @typeName(default.type);
            return "const " ++ tag_name ++ ":" ++ type_name ++ "=spec." ++ tag_name ++ ";\n";
        },
        .derived => |derived| {
            const tag_name: []const u8 = @tagName(derived.tag);
            const type_name: []const u8 = @typeName(derived.type);
            const fn_name: []const u8 = derived.fn_name;
            return "const " ++ tag_name ++ ":" ++ type_name ++ "=" ++ fn_name ++ "(spec);\n";
        },
        .stripped => {},
        .optional_derived => |optional_derived| {
            const tag_name: []const u8 = @tagName(optional_derived.tag);
            const type_name: []const u8 = @typeName(optional_derived.type);
            const fn_name: []const u8 = optional_derived.fn_name;
            return "const " ++ tag_name ++ ":" ++ type_name ++ "=spec." ++ tag_name ++ " orelse " ++ fn_name ++ "(spec);\n";
        },
        .optional_variant => |optional_variant| {
            const tag_name: []const u8 = @tagName(optional_variant.tag);
            return "if(spec." ++ tag_name ++ ")|" ++ tag_name ++ "|{\n";
        },
        .decl_optional_derived => |decl_optional_derived| {
            const ctn_name: []const u8 = @tagName(decl_optional_derived.ctn_tag);
            const decl_name: []const u8 = @tagName(decl_optional_derived.decl_tag);
            const type_name: []const u8 = @typeName(decl_optional_derived.decl_type);
            const fn_name: []const u8 = decl_optional_derived.fn_name;
            return "const " ++ decl_name ++ ":" ++ type_name ++ "hasDecl(spec." ++ ctn_name ++ ", \"" ++ decl_name ++ "\")orelse(" ++ fn_name ++ "(spec));\n";
        },
        .decl_optional_variant => |decl_optional_variant| {
            const ctn_name: []const u8 = @tagName(decl_optional_variant.ctn_tag);
            const decl_name: []const u8 = @tagName(decl_optional_variant.decl_tag);
            return "if (spec." ++ ctn_name ++ "." ++ decl_name ++ ")|" ++ decl_name ++ "|{\n";
        },
    }
}
fn initExpr(comptime s_v_info: []const InfoS) []const u8 {
    comptime var ret: []const u8 = "return.{";
    inline for (s_v_info) |s_v_field| {
        const s_field_name: []const u8 = comptime specificationFieldName(s_v_field);
        ret = ret ++ "." ++ s_field_name ++ "=" ++ s_field_name ++ ",";
    }
    return ret ++ "};\n";
}
fn writeSpecificationDeductionInternal(
    array: *Array,
    comptime p_info: []const InfoS,
    comptime s_v_infos: []const []const InfoS,
) void {
    if (p_info.len == 0) {
        @compileError("???");
    }
    const filtered: BinaryFilter([]const InfoS) = comptime haveSpec(s_v_infos, p_info[0]);
    if (filtered[1].len != 0) {
        array.writeMany(declExpr(p_info[0]));
        if (filtered[1].len == 1) {
            array.writeMany(initExpr(filtered[1][0]));
        } else {
            writeSpecificationDeductionInternal(array, p_info[1..], filtered[1]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0 and
            p_info[0] == .decl_optional_variant or
            p_info[0] == .optional_variant)
        {
            array.writeMany("}else{\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany(initExpr(filtered[0][0]));
        } else {
            writeSpecificationDeductionInternal(array, p_info[1..], filtered[0]);
        }
    }
    if (filtered[1].len != 0 and
        p_info[0] == .decl_optional_variant or
        p_info[0] == .optional_variant)
    {
        array.writeMany("}\n");
    }
}
fn writeSpecificationDeduction(array: *Array, comptime p_info: []const InfoS, comptime s_v_infos: []const []const InfoS) void {
    array.writeMany("const Specification");
    array.writeFormat(fmt.ud64(S.spec_no));
    S.spec_no +%= 1;
    array.writeMany("=struct{\n");
    writeFields(array, p_info);
    array.writeMany("const Specification=@This();\n");
    array.writeMany("fn Implementation(spec:Specification)type{\n");
    writeSpecificationDeductionInternal(array, p_info, s_v_infos);
    array.writeMany("}\n");
    array.writeMany("};\n");
}
pub fn newNewTypeSpecs() void {
    @setEvalBranchQuota(3391);
    var array: Array = undefined;
    array.undefineAll();
    // All implementation variant details
    comptime var details: []const attr.More = &.{};
    // All parameter information
    comptime var p_infos: []const []const InfoS = &.{};
    // All multiple Specification and Technique information
    comptime var x_infos: []const []const []const InfoS = &.{};
    comptime {
        for (attr.abstract_specs, 0..) |spec, p_idx| {
            const x_info: [3][]const InfoS = populateParameters(spec);
            p_infos = p_infos ++ .{x_info[0]};
            const s_v_infos: []const []const InfoS = populateSpecifiers(x_info[1], x_info[2]);
            x_infos = x_infos ++ .{s_v_infos};
            details = details ++ populateDetails(spec, p_idx, s_v_infos, populateTechniques(spec));
        }
    }
    inline for (p_infos, x_infos) |p_info, s_v_infos| {
        writeSpecificationDeduction(&array, p_info, s_v_infos);
    }
    file.write(.{ .errors = .{} }, 1, array.readAll());
    array.undefineAll();
    array.writeMany(&meta.sliceToBytes(attr.More, details));
    gen.writeAuxiliarySourceFile(&array, "detail_raw");
}
pub const main = newNewTypeSpecs;
