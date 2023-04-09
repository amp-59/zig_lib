const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const meta = gen.meta;
const file = gen.file;
const spec = gen.spec;
const serial = gen.serial;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;

const Allocator = config.Allocator;
const AddressSpace = Allocator.AddressSpace;
const Array = mem.StaticString(1024 * 1024);
const ImplementationDetails = Allocator.StructuredVector(types.Implementation);

const validate_all_serial: bool = false;

pub fn limits(
    spec_sets: []const []const []const types.Specifier,
    tech_sets: []const []const []const types.Technique,
) types.Implementation.Indices {
    var ret: types.Implementation.Indices = .{};
    var i: u64 = 0;
    while (i != attr.abstract_specs.len) : (i +%= 1) {
        var j: u64 = 0;
        while (j != spec_sets[i].len) : (j +%= 1) {
            var k: u64 = 0;
            while (k != tech_sets[i].len) : (k +%= 1) {
                ret.impl +%= 1;
            }
            ret.ctn +%= 1;
        }
        ret.spec +%= 1;
    }
    return ret;
}
fn populateUniqueTechniqueKeys(comptime tech_set: []const []const types.Technique) []const types.Technique {
    var ret: []const types.Technique = &.{};
    for (tech_set) |v_i_info| {
        for (v_i_info) |v_i_field| {
            if (v_i_field == .standalone) {
                for (ret) |u_field| {
                    if (u_field == .standalone and
                        v_i_field.standalone == u_field.standalone)
                    {
                        break;
                    }
                } else {
                    ret = ret ++ [1]types.Technique{v_i_field};
                }
            } else {
                for (ret) |u_field| {
                    if (u_field == .mutually_exclusive and
                        v_i_field.mutually_exclusive.opt_tag == u_field.mutually_exclusive.opt_tag)
                    {
                        break;
                    }
                } else {
                    ret = ret ++ [1]types.Technique{v_i_field};
                }
            }
        }
    }
    return ret;
}
fn populateParameters(comptime abstract_spec: types.AbstractSpecification) [3][]const types.Specifier {
    var params: []const types.Specifier = &.{};
    var static: []const types.Specifier = &.{};
    var variant: []const types.Specifier = &.{};
    for (abstract_spec.v_specs) |v_spec| {
        switch (v_spec) {
            .derived => {
                static = static ++ [1]types.Specifier{v_spec};
            },
            .stripped => {
                params = params ++ [1]types.Specifier{v_spec};
            },
            .default, .optional_derived, .decl_optional_derived => {
                params = params ++ [1]types.Specifier{v_spec};
                static = static ++ [1]types.Specifier{v_spec};
            },
            .optional_variant, .decl_optional_variant => {
                params = params ++ [1]types.Specifier{v_spec};
                variant = variant ++ [1]types.Specifier{v_spec};
            },
        }
    }
    return .{ params, static, variant };
}
fn populateTechniques(comptime abstract_spec: types.AbstractSpecification) []const []const types.Technique {
    var tech_set: []const []const types.Technique = &.{&.{}};
    for (abstract_spec.v_techs) |v_tech| {
        switch (v_tech) {
            .standalone => {
                for (tech_set) |i_info| {
                    tech_set = tech_set ++
                        [1][]const types.Technique{i_info ++
                        [1]types.Technique{v_tech}};
                }
            },
            .mutually_exclusive => |mutually_exclusive| {
                switch (mutually_exclusive.kind) {
                    .optional => {
                        for (tech_set) |i_info| {
                            for (mutually_exclusive.tech_tags) |j_info| {
                                tech_set = tech_set ++
                                    [1][]const types.Technique{i_info ++
                                    [1]types.Technique{v_tech.resolve(j_info)}};
                            }
                        }
                    },
                    .mandatory => {
                        var j_infos: []const []const types.Technique = &.{};
                        for (tech_set) |i_info| {
                            for (mutually_exclusive.tech_tags) |j_info| {
                                j_infos = j_infos ++
                                    [1][]const types.Technique{i_info ++
                                    [1]types.Technique{v_tech.resolve(j_info)}};
                            }
                        }
                        tech_set = j_infos;
                    },
                }
            },
        }
    }
    return tech_set;
}
fn populateSpecifiers(
    comptime s_info: []const types.Specifier,
    comptime v_info: []const types.Specifier,
) []const []const types.Specifier {
    var spec_set: []const []const types.Specifier = &.{};
    spec_set = spec_set ++ [1][]const types.Specifier{s_info};
    for (v_info) |v_field| {
        for (spec_set) |p_info| {
            spec_set = spec_set ++
                [1][]const types.Specifier{p_info ++
                [1]types.Specifier{v_field}};
        }
    }
    return spec_set;
}
fn populateDetails(
    comptime abstract_spec: types.AbstractSpecification,
    comptime p_idx: u8,
    comptime spec_set: []const []const types.Specifier,
    comptime tech_set: []const []const types.Technique,
) []const types.Implementation {
    var details: []const types.Implementation = &.{};
    var detail: types.Implementation = types.Implementation.init(abstract_spec, p_idx);
    for (spec_set, 0..) |p_info, s_idx| {
        detail.specs = types.Specifiers.detail(types.specifiersTags(p_info));
        detail.spec_idx = s_idx;
        for (tech_set, 0..) |v_i_info, i_idx| {
            detail.impl_idx = i_idx;
            detail.techs = types.Techniques.detail(types.techniqueTags(v_i_info));
            details = details ++ [1]types.Technique{detail};
        }
    }
    return details;
}
fn BinaryFilter(comptime T: type) type {
    return Allocator.allocate_payload(BinaryFilterPayload(T));
}
fn BinaryFilterPayload(comptime T: type) type {
    return struct { []const T, []const T };
}
fn haveSpec(allocator: *Allocator, spec_set: []const []const types.Specifier, p_field: types.Specifier) BinaryFilter([]const types.Specifier) {
    var t: [][]const types.Specifier = try meta.wrap(
        allocator.allocateIrreversible([]const types.Specifier, spec_set.len),
    );
    var t_len: u64 = 0;
    var f: [][]const types.Specifier = try meta.wrap(
        allocator.allocateIrreversible([]const types.Specifier, spec_set.len),
    );
    var f_len: u64 = 0;
    for (spec_set) |p_info| {
        for (p_info) |s_v_field| {
            if (builtin.testEqual(types.Specifier, p_field, s_v_field)) {
                t[t_len] = p_info;
                t_len +%= 1;
                break;
            }
        } else {
            f[f_len] = p_info;
            f_len +%= 1;
        }
    }
    return .{ f[0..f_len], t[0..t_len] };
}
fn haveTechA(allocator: *Allocator, tech_set: []const []const types.Technique, u_field: types.Technique) BinaryFilter([]const types.Technique) {
    var t: [][]const types.Technique = try meta.wrap(
        allocator.allocateIrreversible([]const types.Technique, tech_set.len),
    );
    var t_len: u64 = 0;
    var f: [][]const types.Technique = try meta.wrap(
        allocator.allocateIrreversible([]const types.Technique, tech_set.len),
    );
    var f_len: u64 = 0;
    for (tech_set) |v_i_info| {
        for (v_i_info) |v_i_field| {
            if (v_i_field == .standalone) {
                if (u_field.standalone == v_i_field.standalone) {
                    t[t_len] = v_i_info;
                    t_len +%= 1;
                    break;
                }
            }
        } else {
            f[f_len] = v_i_info;
            f_len +%= 1;
        }
    }
    return .{ f[0..f_len], t[0..t_len] };
}
fn haveTechB(allocator: *Allocator, tech_set: []const []const types.Technique, u_tech: types.Techniques.Tag) BinaryFilter([]const types.Technique) {
    var t: [][]const types.Technique = try meta.wrap(
        allocator.allocateIrreversible([]const types.Technique, tech_set.len),
    );
    var t_len: u64 = 0;
    var f: [][]const types.Technique = try meta.wrap(
        allocator.allocateIrreversible([]const types.Technique, tech_set.len),
    );
    var f_len: u64 = 0;
    for (tech_set) |v_i_info| {
        for (v_i_info) |v_i_field| {
            if (v_i_field == .mutually_exclusive) {
                if (u_tech == v_i_field.mutually_exclusive.tech_tag.?) {
                    t[t_len] = v_i_info;
                    t_len +%= 1;
                    break;
                }
            }
        } else {
            f[f_len] = v_i_info;
            f_len +%= 1;
        }
    }
    return .{ f[0..f_len], t[0..t_len] };
}
fn writeParametersFields(array: *Array, p_info: []const types.Specifier) void {
    for (p_info) |p_field| {
        writeParametersFieldName(array, p_field);
        array.writeMany(":");
        writeParametersTypeName(array, p_field);
        array.writeMany(",");
    }
}
fn writeSpecificationFields(array: *Array, p_info: []const types.Specifier) void {
    for (p_info) |p_field| {
        writeSpecificationFieldName(array, p_field);
        array.writeMany(":");
        writeSpecificationTypeName(array, p_field);
        array.writeMany(",");
    }
}
fn writeParametersFieldName(array: *Array, p_field: types.Specifier) void {
    switch (p_field) {
        .default => |default| array.writeMany(@tagName(default.tag)),
        .stripped => |stripped| array.writeMany(@tagName(stripped.tag)),
        .optional_derived => |optional_derived| array.writeMany(@tagName(optional_derived.tag)),
        .optional_variant => |optional_variant| array.writeMany(@tagName(optional_variant.tag)),
        .decl_optional_derived => |decl_optional_derived| array.writeMany(@tagName(decl_optional_derived.ctn_tag)),
        .decl_optional_variant => |decl_optional_variant| array.writeMany(@tagName(decl_optional_variant.ctn_tag)),
        .derived => unreachable,
    }
}
fn writeSpecificationFieldName(array: *Array, s_v_field: types.Specifier) void {
    switch (s_v_field) {
        .default => |default| array.writeMany(@tagName(default.tag)),
        .derived => |derived| array.writeMany(@tagName(derived.tag)),
        .optional_derived => |optional_derived| array.writeMany(@tagName(optional_derived.tag)),
        .optional_variant => |optional_variant| array.writeMany(@tagName(optional_variant.tag)),
        .decl_optional_derived => |decl_optional_derived| array.writeMany(@tagName(decl_optional_derived.decl_tag)),
        .decl_optional_variant => |decl_optional_variant| array.writeMany(@tagName(decl_optional_variant.decl_tag)),
        .stripped => unreachable,
    }
}
fn writeSpecificationFieldValue(array: *Array, s_v_field: types.Specifier) void {
    switch (s_v_field) {
        .default => |default| {
            array.writeMany("spec.");
            array.writeMany(@tagName(default.tag));
        },
        .derived => |derived| array.writeMany(@tagName(derived.tag)),
        .optional_derived => |optional_derived| {
            const tag_name: []const u8 = @tagName(optional_derived.tag);
            array.writeMany("spec.");
            array.writeMany(tag_name);
            array.writeMany(" orelse ");
            array.writeMany(optional_derived.fn_name);
            array.writeMany("(spec)");
        },
        .optional_variant => |optional_variant| array.writeMany(@tagName(optional_variant.tag)),
        .decl_optional_derived => |decl_optional_derived| {
            const ctn_name: []const u8 = @tagName(decl_optional_derived.ctn_tag);
            const decl_name: []const u8 = @tagName(decl_optional_derived.decl_tag);
            const fn_name: []const u8 = decl_optional_derived.fn_name;
            array.writeMany("@hasDecl(");
            array.writeMany(ctn_name);
            array.writeMany(",\"");
            array.writeMany(decl_name);
            array.writeMany("\")");
            array.writeMany(ctn_name);
            array.writeMany(".");
            array.writeMany(decl_name);
            array.writeMany(" else ");
            array.writeMany(fn_name);
            array.writeMany("(spec)");
        },
        .decl_optional_variant => |decl_optional_variant| {
            array.writeMany("spec.");
            array.writeMany(@tagName(decl_optional_variant.ctn_tag));
            array.writeMany(".");
            array.writeMany(@tagName(decl_optional_variant.decl_tag));
        },
        .stripped => unreachable,
    }
}
fn writeParametersTypeName(array: *Array, p_field: types.Specifier) void {
    switch (p_field) {
        .default => |default| array.writeFormat(default.type),
        .stripped => |stripped| array.writeFormat(stripped.type),
        .optional_derived => |optional_derived| {
            array.writeMany("?");
            array.writeFormat(optional_derived.type);
        },
        .optional_variant => |optional_variant| {
            array.writeMany("?");
            array.writeFormat(optional_variant.type);
        },
        .decl_optional_derived => |decl_optional_derived| array.writeFormat(decl_optional_derived.ctn_type),
        .decl_optional_variant => |decl_optional_variant| array.writeFormat(decl_optional_variant.ctn_type),
        .derived => undefined,
    }
}
fn writeSpecificationTypeName(array: *Array, s_v_field: types.Specifier) void {
    switch (s_v_field) {
        .default => |default| array.writeFormat(default.type),
        .derived => |derived| array.writeFormat(derived.type),
        .optional_derived => |optional_derived| array.writeFormat(optional_derived.type),
        .optional_variant => |optional_variant| array.writeFormat(optional_variant.type),
        .decl_optional_derived => |decl_optional_derived| array.writeFormat(decl_optional_derived.decl_type),
        .decl_optional_variant => |decl_optional_variant| array.writeFormat(decl_optional_variant.decl_type),
        .stripped => undefined,
    }
}
fn writeDeclExpr(array: *Array, p_field: types.Specifier) void {
    switch (p_field) {
        .default => {},
        .derived => |derived| {
            const tag_name: []const u8 = @tagName(derived.tag);
            array.writeMany("const ");
            array.writeMany(tag_name);
            array.writeMany(":");
            array.writeFormat(derived.type);
            array.writeMany(tag_name);
            array.writeMany(":");
            array.writeFormat(derived.type);
            array.writeMany("=");
            array.writeMany(derived.fn_name);
            array.writeMany("(spec);\n");
        },
        .stripped => {},
        .optional_derived => {},
        .optional_variant => |optional_variant| {
            const tag_name: []const u8 = @tagName(optional_variant.tag);
            array.writeMany("if(spec.");
            array.writeMany(tag_name);
            array.writeMany(")|");
            array.writeMany(tag_name);
            array.writeMany("|{\n");
        },
        .decl_optional_derived => |decl_optional_derived| {
            const ctn_name: []const u8 = @tagName(decl_optional_derived.ctn_tag);
            const decl_name: []const u8 = @tagName(decl_optional_derived.decl_tag);
            const fn_name: []const u8 = decl_optional_derived.fn_name;
            array.writeMany("const ");
            array.writeMany(decl_name);
            array.writeMany(":");
            array.writeFormat(decl_optional_derived.decl_type);
            array.writeMany("hasDecl(spec.");
            array.writeMany(ctn_name);
            array.writeMany("\"");
            array.writeMany(decl_name);
            array.writeMany("\")orelse(");
            array.writeMany(fn_name);
            array.writeMany("(spec));\n");
        },
        .decl_optional_variant => |decl_optional_variant| {
            const ctn_name: []const u8 = @tagName(decl_optional_variant.ctn_tag);
            const decl_name: []const u8 = @tagName(decl_optional_variant.decl_tag);
            array.writeMany("if(@hasDecl(spec.");
            array.writeMany(ctn_name);
            array.writeMany(",\"");
            array.writeMany(decl_name);
            array.writeMany("\")){\n");
        },
    }
}
fn writeInitExpr(array: *Array, p_info: []const types.Specifier) void {
    array.writeMany(".{");
    for (p_info) |s_v_field| {
        array.writeMany(".");
        writeSpecificationFieldName(array, s_v_field);
        array.writeMany("=");
        writeSpecificationFieldValue(array, s_v_field);
        array.writeMany(",");
    }
    array.writeMany("}");
}
fn writeSwitchProngOpen(array: *Array, tag_name: []const u8) void {
    array.writeMany(".");
    array.writeMany(tag_name);
    array.writeMany("=>{");
}
fn writeSwitchOpen(array: *Array, tag_name: []const u8) void {
    array.writeMany("switch(spec.");
    array.writeMany(tag_name);
    array.writeMany("){\n");
}
fn writeOptionalSwitchOpen(array: *Array, tag_name: []const u8) void {
    array.writeMany("if(spec.");
    array.writeMany(tag_name);
    array.writeMany(")|");
    array.writeMany(tag_name);
    array.writeMany("|{\nswitch(");
    array.writeMany(tag_name);
    array.writeMany("){\n");
}
fn writeReturnImplementation(array: *Array, detail: types.Implementation, specs: []const types.Specifier) void {
    array.writeMany("return reference.");
    array.writeFormat(detail);
    array.writeMany("(");
    writeInitExpr(array, specs);
    array.writeMany(");\n");
}
fn writeDeductionTestBoolean(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    tech_set_top: []const []const types.Technique,
    p_info: []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    const filtered: BinaryFilterPayload([]const types.Technique) = try meta.wrap(
        haveTechA(allocator, tech_set, q_info[0]),
    );
    array.writeMany("if(spec.");
    array.writeMany(q_info[0].techTagName());
    array.writeMany("){");
    if (filtered[1].len != 0) {
        if (filtered[1].len == 1) {
            writeReturnImplementation(array, types.Implementation.init(abstract_spec, p_info, filtered[1][0], indices.*), p_info);
            indices.impl +%= 1;
        } else {
            try meta.wrap(
                writeImplementationDeduction(allocator, array, abstract_spec, tech_set_top, p_info, filtered[1], q_info[1..], indices),
            );
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("}else{\n");
        }
        if (filtered[0].len == 1) {
            writeReturnImplementation(array, types.Implementation.init(abstract_spec, p_info, filtered[0][0], indices.*), p_info);
            indices.impl +%= 1;
        } else {
            try meta.wrap(
                writeImplementationDeduction(allocator, array, abstract_spec, tech_set_top, p_info, filtered[0], q_info[1..], indices),
            );
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeDeductionCompareEnumerationInternal(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    tech_set_top: []const []const types.Technique,
    p_info: []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
    tag_index: u64,
) Allocator.allocate_void {
    if (q_info[0].mutually_exclusive.tech_tags.len == tag_index) return;
    const tech: types.Techniques.Tag = q_info[0].mutually_exclusive.tech_tags[tag_index];
    const tech_tag_name: []const u8 = @tagName(tech);
    const filtered: BinaryFilterPayload([]const types.Technique) = try meta.wrap(
        haveTechB(allocator, tech_set, tech),
    );
    writeSwitchProngOpen(array, tech_tag_name);
    try meta.wrap(
        writeImplementationDeduction(allocator, array, abstract_spec, tech_set_top, p_info, filtered[1], q_info[1..], indices),
    );
    array.writeMany("},\n");
    try meta.wrap(
        writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, tech_set_top, p_info, filtered[0], q_info, indices, tag_index + 1),
    );
}
fn writeDeductionCompareEnumeration(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    tech_set_top: []const []const types.Technique,
    p_info: []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    writeSwitchOpen(array, q_info[0].optTagName());
    try meta.wrap(
        writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, tech_set_top, p_info, tech_set, q_info, indices, 0),
    );
    array.writeMany("}\n");
}
inline fn writeDeductionCompareOptionalEnumeration(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    tech_set_top: []const []const types.Technique,
    p_info: []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    writeOptionalSwitchOpen(array, q_info[0].optTagName());
    try meta.wrap(
        writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, tech_set_top, p_info, tech_set, q_info, indices, 0),
    );
    array.writeMany("}\n}\n");
}
fn writeImplementationDeduction(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    tech_set_top: []const []const types.Technique,
    p_info: []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    if (q_info.len == 0 or tech_set.len == 1) {
        writeReturnImplementation(array, types.Implementation.init(abstract_spec, p_info, tech_set[0], indices.*), p_info);
        indices.impl +%= 1;
    } else switch (q_info[0].usage(tech_set_top)) {
        .test_boolean => {
            try meta.wrap(
                writeDeductionTestBoolean(allocator, array, abstract_spec, tech_set_top, p_info, tech_set, q_info, indices),
            );
        },
        .compare_enumeration => {
            try meta.wrap(
                writeDeductionCompareEnumeration(allocator, array, abstract_spec, tech_set_top, p_info, tech_set, q_info, indices),
            );
        },
        .compare_optional_enumeration => {
            try meta.wrap(
                writeDeductionCompareOptionalEnumeration(allocator, array, abstract_spec, tech_set_top, p_info, tech_set, q_info, indices),
            );
        },
        else => return,
    }
}
fn writeSpecificationDeductionInternal(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    p_info: []const types.Specifier,
    spec_set: []const []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    const filtered: BinaryFilterPayload([]const types.Specifier) = try meta.wrap(
        haveSpec(allocator, spec_set, p_info[0]),
    );
    if (filtered[1].len != 0) {
        writeDeclExpr(array, p_info[0]);
        if (filtered[1].len == 1) {
            try meta.wrap(
                writeImplementationDeduction(allocator, array, abstract_spec, tech_set, filtered[1][0], tech_set, q_info, indices),
            );
            indices.ctn +%= 1;
        } else {
            try meta.wrap(
                writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info[1..], filtered[1], tech_set, q_info, indices),
            );
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
            try meta.wrap(
                writeImplementationDeduction(allocator, array, abstract_spec, tech_set, filtered[0][0], tech_set, q_info, indices),
            );
            indices.ctn +%= 1;
        } else {
            try meta.wrap(
                writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info[1..], filtered[0], tech_set, q_info, indices),
            );
        }
    }
    if (filtered[1].len != 0 and
        p_info[0] == .decl_optional_variant or
        p_info[0] == .optional_variant)
    {
        array.writeMany("}\n");
    }
}
fn writeSpecificationDeduction(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: types.AbstractSpecification,
    p_info: []const types.Specifier,
    spec_set: []const []const types.Specifier,
    tech_set: []const []const types.Technique,
    q_info: []const types.Technique,
    indices: *types.Implementation.Indices,
) Allocator.allocate_void {
    array.writeMany("const Specification");
    array.writeFormat(fmt.ud64(indices.spec));
    array.writeMany("=struct{\n");
    writeParametersFields(array, p_info);
    array.writeMany("const Specification=@This();\nfn Implementation(spec:Specification)type{\n");
    try meta.wrap(
        writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info, spec_set, tech_set, q_info, indices),
    );
    array.writeMany("}\n};\n");
}
fn writeSpecifications(
    allocator: *Allocator,
    array: *Array,
) Allocator.allocate_void {
    var indices: types.Implementation.Indices = .{};

    for (types.Kind.list) |kind| {
        for (attr.abstract_specs, data.x_p_infos, data.spec_sets, data.tech_sets, data.x_q_infos) |abstract_spec, p_info, spec_set, tech_set, q_info| {
            if (abstract_spec.kind == kind) {
                const save: Allocator.Save = allocator.save();
                defer allocator.restore(save);
                try meta.wrap(
                    writeSpecificationDeduction(allocator, array, abstract_spec, p_info, spec_set, tech_set, q_info, &indices),
                );
                indices.spec +%= 1;
            }
        }
        switch (kind) {
            .automatic => gen.writeSourceFile(config.automatic_container_path, u8, array.readAll()),
            .static => gen.writeSourceFile(config.static_container_path, u8, array.readAll()),
            .dynamic => gen.writeSourceFile(config.dynamic_container_path, u8, array.readAll()),
            .parametric => gen.writeSourceFile(config.parametric_container_path, u8, array.readAll()),
        }
        array.undefineAll();
    }
}
fn nonEqualIndices(name: []const u8, any: anytype) void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    array.writeMany(name);
    switch (any.len) {
        else => {
            array.writeMany(": non-equal indices: ");
            array.writeFormat(fmt.ud64(any[0]));
            array.writeOne('\n');
        },
        2 => {
            array.writeMany(": non-equal indices: ");
            array.writeFormat(fmt.ud64(any[0]));
            array.writeOne(' ');
            array.writeFormat(fmt.ud64(any[1]));
        },
        3 => {
            array.writeMany(": non-equal indices: ");
            array.writeFormat(fmt.ud64(any[0]));
            array.writeOne(' ');
            array.writeFormat(fmt.ud64(any[1]));
            array.writeOne(' ');
            array.writeFormat(fmt.ud64(any[2]));
        },
    }
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn validateAllSerial(
    allocator: *Allocator,
    x_p_infos: []const []const types.Specifier,
    x_q_infos: []const []const types.Technique,
    spec_sets: []const []const []const types.Specifier,
    tech_sets: []const []const []const types.Technique,
    impl_details: ImplementationDetails,
) !void {
    if (!validate_all_serial) {
        return;
    }
    var f_x_p_infos: []const []const types.Specifier = attr.getParams(allocator);
    var f_x_q_infos: []const []const types.Technique = attr.getOptions(allocator);
    var f_impl_details: []const types.Implementation = attr.getImplDetails(allocator);
    for (f_x_p_infos, x_p_infos, 0..) |xx, yy, idx_0| {
        for (xx, yy, 0..) |x, y, idx_1| {
            if (!builtin.testEqualMemory(@TypeOf(x), x, y)) {
                nonEqualIndices("params", .{ idx_0, idx_1 });
            }
        }
    }
    for (f_x_q_infos, x_q_infos, 0..) |xx, yy, idx_0| {
        for (xx, yy, 0..) |x, y, idx_1| {
            if (!builtin.testEqualMemory(@TypeOf(x), x, y)) {
                nonEqualIndices("options", .{ idx_0, idx_1 });
            }
        }
    }
    for (f_impl_details, impl_details.readAll(), 0..) |x, y, idx_0| {
        if (!builtin.testEqualMemory(@TypeOf(x), x, y)) {
            nonEqualIndices("details", .{idx_0});
        }
    }
    var f_spec_sets: []const []const []const types.Specifier = attr.getSpecs(allocator);
    var f_tech_sets: []const []const []const types.Technique = attr.getTechs(allocator);
    var i: u64 = 0;
    while (i != spec_sets.len) : (i +%= 1) {
        var j: u64 = 0;
        while (j != spec_sets[i].len) : (j +%= 1) {
            var k: u64 = 0;
            while (k != spec_sets[i][j].len) : (k +%= 1) {
                if (!builtin.testEqualMemory(
                    @TypeOf(f_spec_sets[i][j][k]),
                    f_spec_sets[i][j][k],
                    spec_sets[i][j][k],
                )) {
                    nonEqualIndices("specs", .{ i, j, k });
                }
            }
        }
    }
    i = 0;
    while (i != tech_sets.len) : (i +%= 1) {
        var j: u64 = 0;
        while (j != tech_sets[i].len) : (j +%= 1) {
            var k: u64 = 0;
            while (k != tech_sets[i][j].len) : (k +%= 1) {
                if (!builtin.testEqualMemory(
                    @TypeOf(f_tech_sets[i][j][k]),
                    f_tech_sets[i][j][k],
                    tech_sets[i][j][k],
                )) {
                    nonEqualIndices("techs", .{ i, j, k });
                }
            }
        }
    }
}
const data = blk: {
    var x_p_infos: []const []const types.Specifier = &.{};
    var x_q_infos: []const []const types.Technique = &.{};
    var spec_sets: []const []const []const types.Specifier = &.{};
    var tech_sets: []const []const []const types.Technique = &.{};
    inline for (attr.ctn_groups) |abstract_specs| {
        inline for (abstract_specs) |abstract_spec| {
            const x_info: [3][]const types.Specifier = populateParameters(abstract_spec);
            const spec_set: []const []const types.Specifier = populateSpecifiers(x_info[1], x_info[2]);
            const tech_set: []const []const types.Technique = populateTechniques(abstract_spec);
            const q_info: []const types.Technique = populateUniqueTechniqueKeys(tech_set);
            x_p_infos = x_p_infos ++ [1][]const types.Specifier{x_info[0]};
            x_q_infos = x_q_infos ++ [1][]const types.Technique{q_info};
            spec_sets = spec_sets ++ [1][]const []const types.Specifier{spec_set};
            tech_sets = tech_sets ++ [1][]const []const types.Technique{tech_set};
        }
    }
    break :blk .{
        .x_p_infos = x_p_infos,
        .x_q_infos = x_q_infos,
        .spec_sets = spec_sets,
        .tech_sets = tech_sets,
    };
};

pub fn newNewTypeSpecs() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try meta.wrap(Allocator.init(&address_space));
    defer allocator.deinit(&address_space);
    @setEvalBranchQuota(1500);
    var array: Array = undefined;
    array.undefineAll();

    try gen.readFile(&array, config.container_template_path);
    gen.writeSourceFile(config.container_common_path, u8, array.readAll());
    array.undefineAll();

    try meta.wrap(writeSpecifications(&allocator, &array));
    var impl_details: ImplementationDetails = try meta.wrap(ImplementationDetails.init(&allocator, 0x400));

    var spec_idx: u16 = 0;
    var ctn_idx: u16 = 0;
    var impl_idx: u16 = 0;

    inline for (attr.ctn_groups) |abstract_specs| {
        inline for (abstract_specs) |abstract_spec| {
            for (data.spec_sets[spec_idx]) |specs| {
                for (data.tech_sets[spec_idx]) |techs| {
                    impl_details.writeOne(types.Implementation.init(abstract_spec, specs, techs, .{
                        .spec = spec_idx,
                        .ctn = ctn_idx,
                        .impl = impl_idx,
                    }));
                    impl_idx +%= 1;
                }
                ctn_idx +%= 1;
            }
            spec_idx +%= 1;
        }
    }
    gen.writeSourceFile(config.impl_detail_path, types.Implementation, impl_details.readAll());
    gen.writeSourceFile(config.ctn_detail_path, types.Container, attr.ctn_details);

    try validateAllSerial(&allocator, data.x_p_infos, data.x_q_infos, data.spec_sets, data.tech_sets, impl_details);
}
pub const main = newNewTypeSpecs;
