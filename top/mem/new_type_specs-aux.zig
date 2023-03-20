const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const meta = gen.meta;
const file = gen.file;
const preset = gen.preset;
const serial = gen.serial;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const attr = @import("./attr.zig");

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const start: u64 = 0x40000000;
const size: u64 = 64 * 1024 * 1024;
const count: u64 = 1024 / 64;
const finish: u64 = start + (size * count);

const Allocators = mem.StaticArray(Allocator, count);

const Allocator = mem.GenericRtArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.small,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .label = "multi_addrspace",
    .lb_addr = start,
    .up_addr = finish,
    .divisions = 4,
    .logging = preset.address_space.logging.silent,
    .errors = preset.address_space.errors.noexcept,
});

const Array = mem.StaticString(1024 * 1024);
const InfoS = attr.Specifier;
const InfoT = attr.Technique;

fn BinaryFilter(comptime T: type) type {
    return struct { []const T, []const T };
}
fn haveSpec(
    allocator: *Allocator,
    s_v_infos: []const []const InfoS,
    p_field: InfoS,
) BinaryFilter([]const InfoS) {
    var t: [][]const InfoS =
        allocator.allocateIrreversible([]const InfoS, s_v_infos.len);
    var t_len: u64 = 0;
    var f: [][]const InfoS =
        allocator.allocateIrreversible([]const InfoS, s_v_infos.len);
    var f_len: u64 = 0;
    for (s_v_infos) |s_v_info| {
        for (s_v_info) |s_v_field| {
            if (builtin.testEqual(InfoS, p_field, s_v_field)) {
                t[t_len] = s_v_info;
                t_len +%= 1;
                break;
            }
        } else {
            f[f_len] = s_v_info;
            f_len +%= 1;
        }
    }
    return .{ f[0..f_len], t[0..t_len] };
}
fn haveStandAloneTech(
    allocator: *Allocator,
    v_i_infos: []const []const InfoT,
    u_field: InfoT,
) BinaryFilter([]const InfoT) {
    var t: [][]const InfoT =
        allocator.allocateIrreversible([]const InfoT, v_i_infos.len);
    var t_len: u64 = 0;
    var f: [][]const InfoT =
        allocator.allocateIrreversible([]const InfoT, v_i_infos.len);
    var f_len: u64 = 0;
    for (v_i_infos) |v_i_info| {
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
fn haveMutuallyExclusiveTech(
    allocator: *Allocator,
    v_i_infos: []const []const InfoT,
    u_tech: attr.Techniques.Tag,
) BinaryFilter([]const InfoT) {
    var t: [][]const InfoT =
        allocator.allocateIrreversible([]const InfoT, v_i_infos.len);
    var t_len: u64 = 0;
    var f: [][]const InfoT =
        allocator.allocateIrreversible([]const InfoT, v_i_infos.len);
    var f_len: u64 = 0;
    for (v_i_infos) |v_i_info| {
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

fn populateUniqueTechniqueKeys(comptime v_i_infos: []const []const InfoT) []const InfoT {
    var ret: []const InfoT = &.{};
    for (v_i_infos) |v_i_info| {
        for (v_i_info) |v_i_field| {
            if (v_i_field == .standalone) {
                for (ret) |u_field| {
                    if (u_field == .standalone and
                        v_i_field.standalone == u_field.standalone)
                    {
                        break;
                    }
                } else {
                    ret = ret ++ .{v_i_field};
                }
            } else {
                for (ret) |u_field| {
                    if (u_field == .mutually_exclusive and
                        v_i_field.mutually_exclusive.opt_tag == u_field.mutually_exclusive.opt_tag)
                    {
                        break;
                    }
                } else {
                    ret = ret ++ .{v_i_field};
                }
            }
        }
    }
    return ret;
}
fn populateParameters(comptime abstract_spec: attr.AbstractSpecification) [3][]const InfoS {
    var p_info: []const InfoS = &.{};
    var s_info: []const InfoS = &.{};
    var v_info: []const InfoS = &.{};
    for (abstract_spec.v_specs) |v_spec| {
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
fn populateTechniques(comptime abstract_spec: attr.AbstractSpecification) []const []const InfoT {
    var v_i_infos: []const []const InfoT = &.{&.{}};
    for (abstract_spec.v_techs) |v_tech| {
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
) []const attr.Implementation {
    var details: []const attr.Implementation = &.{};
    var detail: attr.Implementation = attr.Implementation.init(spec, p_idx);
    for (s_v_infos, 0..) |s_v_info, s_idx| {
        detail.specs = attr.Specifiers.detail(attr.specifiersTags(s_v_info));
        detail.spec_idx = s_idx;
        for (v_i_infos, 0..) |v_i_info, i_idx| {
            detail.impl_idx = i_idx;
            detail.techs = attr.Techniques.detail(attr.techniqueTags(v_i_info));
            details = details ++ .{detail};
        }
    }
    return details;
}
fn writeFields(array: *Array, p_info: []const InfoS) void {
    for (p_info) |p_field| {
        writeParametersFieldName(array, p_field);
        array.writeMany(":");
        writeParametersTypeName(array, p_field);
        array.writeMany(",");
    }
}
fn writeParametersFieldName(array: *Array, p_field: InfoS) void {
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
fn writeSpecificationFieldName(array: *Array, s_v_field: InfoS) void {
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
fn writeParametersTypeName(array: *Array, p_field: InfoS) void {
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
fn writeSpecificationTypeName(array: *Array, s_v_field: InfoS) void {
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
fn writeDeclExpr(array: *Array, p_field: InfoS) void {
    switch (p_field) {
        .default => |default| {
            array.writeMany("const ");
            array.writeMany(@tagName(default.tag));
            array.writeMany(":");
            array.writeFormat(default.type);
            array.writeMany("=spec.");
            array.writeMany(@tagName(default.tag));
            array.writeMany(";\n");
        },
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
        .optional_derived => |optional_derived| {
            const tag_name: []const u8 = @tagName(optional_derived.tag);
            array.writeMany("const ");
            array.writeMany(tag_name);
            array.writeMany(":");
            array.writeFormat(optional_derived.type);
            array.writeMany("=spec.");
            array.writeMany(tag_name);
            array.writeMany(" orelse ");
            array.writeMany(optional_derived.fn_name);
            array.writeMany("(spec);\n");
        },
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
            array.writeMany("if (spec.");
            array.writeMany(ctn_name);
            array.writeMany(".");
            array.writeMany(decl_name);
            array.writeMany(")|");
            array.writeMany(decl_name);
            array.writeMany("|{\n");
        },
    }
}
fn writeInitExpr(array: *Array, s_v_info: []const InfoS) void {
    array.writeMany(".{");
    for (s_v_info) |s_v_field| {
        array.writeMany(".");
        writeSpecificationFieldName(array, s_v_field);
        array.writeMany("=");
        writeSpecificationFieldName(array, s_v_field);
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
    array.writeMany("if (spec.");
    array.writeMany(tag_name);
    array.writeMany(")|");
    array.writeMany(tag_name);
    array.writeMany("|{\nswitch(");
    array.writeMany(tag_name);
    array.writeMany("){\n");
}
fn writeReturnImplementation(array: *Array, detail: attr.Implementation, specs: []const InfoS) void {
    array.writeMany("return ");
    array.writeFormat(detail);
    array.writeMany("(");
    writeInitExpr(array, specs);
    array.writeMany(");\n");
}
fn writeDeductionTestBoolean(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    v_i_infos_top: []const []const InfoT,
    s_v_info: []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    const filtered: BinaryFilter([]const InfoT) = haveStandAloneTech(allocator, v_i_infos, q_info[0]);
    array.writeMany("if(spec.");
    array.writeMany(q_info[0].techTagName());
    array.writeMany("){");
    if (filtered[1].len != 0) {
        if (filtered[1].len == 1) {
            writeReturnImplementation(array, attr.Implementation.init(abstract_spec, s_v_info, filtered[1][0], indices.*), s_v_info);
            indices.impl +%= 1;
        } else {
            writeImplementationDeduction(allocator, array, abstract_spec, v_i_infos_top, s_v_info, filtered[1], q_info[1..], indices);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("}else{\n");
        }
        if (filtered[0].len == 1) {
            writeReturnImplementation(array, attr.Implementation.init(abstract_spec, s_v_info, filtered[0][0], indices.*), s_v_info);
            indices.impl +%= 1;
        } else {
            writeImplementationDeduction(allocator, array, abstract_spec, v_i_infos_top, s_v_info, filtered[0], q_info[1..], indices);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeDeductionCompareEnumerationInternal(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    v_i_infos_top: []const []const InfoT,
    s_v_info: []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
    tag_index: u64,
) void {
    if (q_info[0].mutually_exclusive.tech_tags.len == tag_index) return;
    const tech: attr.Techniques.Tag = q_info[0].mutually_exclusive.tech_tags[tag_index];
    const tech_tag_name: []const u8 = @tagName(tech);
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    const filtered: BinaryFilter([]const InfoT) = haveMutuallyExclusiveTech(allocator, v_i_infos, tech);
    writeSwitchProngOpen(array, tech_tag_name);
    writeImplementationDeduction(allocator, array, abstract_spec, v_i_infos_top, s_v_info, filtered[1], q_info[1..], indices);
    array.writeMany("},\n");
    writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, v_i_infos_top, s_v_info, filtered[0], q_info, indices, tag_index + 1);
}
fn writeDeductionCompareEnumeration(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    v_i_infos_top: []const []const InfoT,
    s_v_info: []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    writeSwitchOpen(array, q_info[0].optTagName());
    writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, v_i_infos_top, s_v_info, v_i_infos, q_info, indices, 0);
    array.writeMany("}\n");
}
fn writeDeductionCompareOptionalEnumeration(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    v_i_infos_top: []const []const InfoT,
    s_v_infos: []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    writeOptionalSwitchOpen(array, q_info[0].optTagName());
    writeDeductionCompareEnumerationInternal(allocator, array, abstract_spec, v_i_infos_top, s_v_infos, v_i_infos, q_info, indices, 0);
    array.writeMany("}\n}\n");
}
fn writeImplementationDeduction(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    v_i_infos_top: []const []const InfoT,
    s_v_info: []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    if (q_info.len == 0 or v_i_infos.len == 1) {
        writeReturnImplementation(
            array,
            attr.Implementation.init(abstract_spec, s_v_info, v_i_infos[0], indices.*),
            s_v_info,
        );
        indices.impl +%= 1;
    } else switch (q_info[0].usage(v_i_infos_top)) {
        .test_boolean => {
            writeDeductionTestBoolean(allocator, array, abstract_spec, v_i_infos_top, s_v_info, v_i_infos, q_info, indices);
        },
        .compare_enumeration => {
            writeDeductionCompareEnumeration(allocator, array, abstract_spec, v_i_infos_top, s_v_info, v_i_infos, q_info, indices);
        },
        .compare_optional_enumeration => {
            writeDeductionCompareOptionalEnumeration(allocator, array, abstract_spec, v_i_infos_top, s_v_info, v_i_infos, q_info, indices);
        },
        else => return,
    }
}
fn writeSpecificationDeductionInternal(
    allocator: *Allocator,
    array: *Array,
    abstract_spec: attr.AbstractSpecification,
    p_info: []const InfoS,
    s_v_infos: []const []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    const filtered: BinaryFilter([]const InfoS) = haveSpec(allocator, s_v_infos, p_info[0]);
    if (filtered[1].len != 0) {
        writeDeclExpr(array, p_info[0]);
        if (filtered[1].len == 1) {
            writeImplementationDeduction(allocator, array, abstract_spec, v_i_infos, filtered[1][0], v_i_infos, q_info, indices);
            indices.ctn +%= 1;
        } else {
            writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info[1..], filtered[1], v_i_infos, q_info, indices);
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
            writeImplementationDeduction(allocator, array, abstract_spec, v_i_infos, filtered[0][0], v_i_infos, q_info, indices);
            indices.ctn +%= 1;
        } else {
            writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info[1..], filtered[0], v_i_infos, q_info, indices);
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
    abstract_spec: attr.AbstractSpecification,
    p_info: []const InfoS,
    s_v_infos: []const []const InfoS,
    v_i_infos: []const []const InfoT,
    q_info: []const InfoT,
    indices: *attr.Implementation.Indices,
) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("const Specification");
    array.writeFormat(fmt.ud64(indices.spec));
    array.writeMany("=struct{\n");
    writeFields(array, p_info);
    array.writeMany("const Specification=@This();\nfn Implementation(spec:Specification)type{\n");
    writeSpecificationDeductionInternal(allocator, array, abstract_spec, p_info, s_v_infos, v_i_infos, q_info, indices);
    array.writeMany("}\n};\n");
}
fn writeSpecifications(
    allocator: *Allocator,
    array: *Array,
    x_p_infos: []const []const InfoS,
    x_q_infos: []const []const InfoT,
    x_s_v_infos: []const []const []const InfoS,
    x_v_i_infos: []const []const []const InfoT,
) void {
    gen.copySourceFile(array, "container-template.zig");
    var indices: attr.Implementation.Indices = .{};
    for (attr.abstract_specs, x_p_infos, x_s_v_infos, x_v_i_infos, x_q_infos) |abstract_spec, p_info, s_v_infos, v_i_infos, q_info| {
        writeSpecificationDeduction(allocator, array, abstract_spec, p_info, s_v_infos, v_i_infos, q_info, &indices);
        indices.spec +%= 1;
    }
    gen.writeSourceFile(array, "containers.zig");
}
fn writeImplementationDetails(
    allocator: *Allocator,
    x_s_v_infos: []const []const []const InfoS,
    x_v_i_infos: []const []const []const InfoT,
) void {
    const Details = Allocator.StructuredVector(attr.Implementation);
    var indices: attr.Implementation.Indices = .{};
    var details: Details = Details.init(allocator, x_s_v_infos.len * x_v_i_infos.len);
    for (attr.abstract_specs, x_s_v_infos, x_v_i_infos) |abstract_spec, s_v_infos, v_i_infos| {
        for (s_v_infos) |s_v_info| {
            for (v_i_infos) |v_i_info| {
                details.appendOne(allocator, attr.Implementation.init(abstract_spec, s_v_info, v_i_info, indices));
                indices.impl +%= 1;
            }
            indices.ctn +%= 1;
        }
        indices.spec +%= 1;
    }
    gen.writeAuxiliarySourceFile(&details, "details");
}

pub fn newNewTypeSpecs() void {
    @setEvalBranchQuota(1500);
    comptime var x_p_infos: []const []const InfoS = &.{};
    comptime var x_q_infos: []const []const InfoT = &.{};
    comptime var x_s_v_infos: []const []const []const InfoS = &.{};
    comptime var x_v_i_infos: []const []const []const InfoT = &.{};
    inline for (attr.abstract_specs) |abstract_spec| {
        const x_info: [3][]const InfoS = comptime populateParameters(abstract_spec);
        const s_v_infos: []const []const InfoS = comptime populateSpecifiers(x_info[1], x_info[2]);
        const v_i_infos: []const []const InfoT = comptime populateTechniques(abstract_spec);
        const q_info: []const InfoT = comptime populateUniqueTechniqueKeys(v_i_infos);
        x_p_infos = x_p_infos ++ [1][]const InfoS{x_info[0]};
        x_q_infos = x_q_infos ++ [1][]const InfoT{q_info};
        x_s_v_infos = x_s_v_infos ++ [1][]const []const InfoS{s_v_infos};
        x_v_i_infos = x_v_i_infos ++ [1][]const []const InfoT{v_i_infos};
    }
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    var array: Array = undefined;
    array.undefineAll();
    writeSpecifications(&allocator, &array, x_p_infos, x_q_infos, x_s_v_infos, x_v_i_infos);
    writeImplementationDetails(&allocator, x_s_v_infos, x_v_i_infos);
}
pub const main = newNewTypeSpecs;
