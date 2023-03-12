//! This stage summarises the abstract specification.
const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const file = gen.file;
const meta = gen.meta;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const attr = @import("./attr.zig");
const abstract_spec = @import("./abstract_spec.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);
const Info = struct { p_idx: u64, v_spec: attr.Variant };

fn writeFields(array: *Array, comptime p_info: []const Info) void {
    inline for (p_info) |p_field| {
        array.writeMany(comptime parametersFieldName(p_field) ++ ":" ++ parametersTypeName(p_field) ++ ",");
    }
}
fn parametersFieldName(comptime p_field: Info) []const u8 {
    switch (p_field.v_spec) {
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
            return @tagName(decl_optional_derived.decl_tag);
        },
        .decl_optional_variant => |decl_optional_variant| {
            return @tagName(decl_optional_variant.decl_tag);
        },
        .derived => {
            @compileError("???");
        },
    }
}
fn specificationFieldName(comptime s_v_field: Info) []const u8 {
    switch (s_v_field.v_spec) {
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
fn parametersTypeName(comptime p_field: Info) []const u8 {
    switch (p_field.v_spec) {
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
fn specificationTypeName(s_v_field: Info) []const u8 {
    switch (s_v_field.v_spec) {
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
fn declExpr(comptime p_field: Info) []const u8 {
    switch (p_field.v_spec) {
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
fn initExpr(comptime s_v_info: []const Info) []const u8 {
    comptime var ret: []const u8 = "return.{";
    inline for (s_v_info) |s_v_field| {
        const s_field_name: []const u8 = comptime specificationFieldName(s_v_field);
        ret = ret ++ "." ++ s_field_name ++ "=" ++ s_field_name ++ ",";
    }
    return ret ++ "};\n";
}
fn BinaryFilter(comptime T: type) type {
    return (struct { []const T, []const T });
}
fn haveSpec(
    comptime s_v_infos: []const []const Info,
    comptime p_field: Info,
) BinaryFilter([]const Info) {
    comptime var t: []const []const Info = meta.empty;
    comptime var f: []const []const Info = meta.empty;
    inline for (s_v_infos) |s_v_info| {
        inline for (s_v_info) |s_v_field| {
            if (builtin.testEqual(Info, p_field, s_v_field)) {
                t = t ++ .{s_v_info};
                break;
            }
        } else {
            f = f ++ .{s_v_info};
        }
    }
    return .{ f, t };
}
fn writeSpecificationDeductionInternal(
    array: *Array,
    comptime p_info: []const Info,
    comptime s_v_infos: []const []const Info,
) void {
    if (p_info.len == 0) {
        @compileError("???");
    }
    const filtered: BinaryFilter([]const Info) = comptime haveSpec(s_v_infos, p_info[0]);
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
            p_info[0].v_spec == .decl_optional_variant or
            p_info[0].v_spec == .optional_variant)
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
        p_info[0].v_spec == .decl_optional_variant or
        p_info[0].v_spec == .optional_variant)
    {
        array.writeMany("}\n");
    }
}
const S = struct {
    var spec_no: u64 = 0;
};
fn writeSpecificationDeduction(
    array: *Array,
    comptime p_info: []const Info,
    comptime s_v_infos: []const []const Info,
) void {
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
    var array: Array = undefined;
    array.undefineAll();
    inline for (attr.specs) |specification| {
        comptime var p_info: []const Info = &.{};
        comptime var s_info: []const Info = &.{};
        comptime var v_info: []const Info = &.{};
        inline for (specification.specifiers, 0..) |v_spec, p_idx| {
            const info: Info = .{ .v_spec = v_spec, .p_idx = p_idx };
            switch (v_spec) {
                .default => {
                    p_info = p_info ++ .{info};
                    s_info = s_info ++ .{info};
                },
                .derived => {
                    s_info = s_info ++ .{info};
                },
                .stripped => {
                    p_info = p_info ++ .{info};
                },
                .optional_derived => {
                    p_info = p_info ++ .{info};
                    s_info = s_info ++ .{info};
                },
                .optional_variant => {
                    p_info = p_info ++ .{info};
                    v_info = v_info ++ .{info};
                },
                .decl_optional_derived => {
                    p_info = p_info ++ .{info};
                    s_info = s_info ++ .{info};
                },
                .decl_optional_variant => {
                    p_info = p_info ++ .{info};
                    v_info = v_info ++ .{info};
                },
            }
        }
        comptime var s_v_infos: []const []const Info = &.{s_info};
        inline for (v_info) |v_field| {
            inline for (s_v_infos) |s_v_info| {
                s_v_infos = s_v_infos ++ [1][]const Info{s_v_info ++ [1]Info{v_field}};
            }
        }
        writeSpecificationDeduction(&array, p_info, s_v_infos);
    }
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
pub const main = newNewTypeSpecs;
