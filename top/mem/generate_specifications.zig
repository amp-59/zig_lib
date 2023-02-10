//! This stage generates reference impls
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const mach = @import("./../mach.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen.zig");
const config = @import("./config.zig");

pub const AddressSpace = preset.address_space.regular_128;
pub usingnamespace proc.start;
pub usingnamespace proc.exception;

const Details = gen.Allocator.StructuredVector(*const out.DetailMore);

const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/memgen_options.zig");
    usingnamespace @import("./zig-out/src/memgen_type_specs.zig");
    usingnamespace @import("./zig-out/src/memgen_type_descrs.zig");
    usingnamespace @import("./zig-out/src/memgen_variants.zig");
    usingnamespace @import("./zig-out/src/memgen_container_specifications.zig");
};
fn writeReturnImplementation(array: *gen.String, impl_detail: *const out.DetailMore) void {
    const endl: bool = mem.testEqualManyBack(u8, " => ", array.readAll());
    array.writeMany("return ");
    impl_detail.writeName(array);
    array.writeMany("(spec)");
    if (endl) {
        array.writeMany(",\n");
    } else {
        array.writeMany(";\n");
    }
}
const Filtered = struct {
    []const *const out.DetailMore,
    []const *const out.DetailMore,
};
fn filterTechnique(
    impl_groups: []const *const out.DetailMore,
    buf: []*const out.DetailMore,
    comptime field_name: []const u8,
) Filtered {
    if (!@hasField(gen.Techniques, field_name)) {
        builtin.debug.logFault(field_name);
    }
    var t_len: u64 = 0;
    var f_idx: u64 = buf.len;
    for (impl_groups) |impl_variant| {
        if (@field(impl_variant.techs, field_name)) {
            buf[t_len] = impl_variant;
            t_len +%= 1;
        } else {
            f_idx -%= 1;
            buf[f_idx] = impl_variant;
        }
    }
    const f: []*const out.DetailMore = buf[f_idx..];
    f_idx = 0;
    while (f_idx != f.len) : (f_idx +%= 1) {
        const a: *const out.DetailMore = f[f_idx];
        f[f_idx] = f[f.len -% (1 +% f_idx)];
        f[f.len -% (1 +% f_idx)] = a;
    }
    return .{ f, buf[0..t_len] };
}
fn writeDeductionTestBoolean(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
    comptime field_names: []const []const u8,
) void {
    if (field_names.len == 0) {
        if (impl_group.len == 1) {
            return writeReturnImplementation(array, impl_group[0]);
        } else {
            return writeDeduction(allocator, array, toplevel_impl_group, impl_group, options[1..]);
        }
    }
    var buf: []*const out.DetailMore = allocator.allocateIrreversible(*const out.DetailMore, impl_group.len);
    const filtered: Filtered = filterTechnique(impl_group, buf, field_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (options." ++ field_names[0] ++ ") {\n");
        if (filtered[1].len == 1) {
            return writeReturnImplementation(array, filtered[1][0]);
        } else {
            writeDeduction(allocator, array, toplevel_impl_group, filtered[1], options[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) array.writeMany("} else {\n");
        if (filtered[0].len == 1) {
            return writeReturnImplementation(array, filtered[0][0]);
        } else {
            writeDeductionTestBoolean(allocator, array, toplevel_impl_group, filtered[0], options, field_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeDeductionCompareEnumerationInternal(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
    comptime field_index: usize,
) ?[]const *const out.DetailMore {
    if (field_index == options[0].info.field_field_names.len and options.len != 1) {
        return impl_group;
    }
    if (field_index == options[0].info.field_field_names.len and options.len == 1) {
        for (impl_group) |impl_detail| {
            writeReturnImplementation(array, impl_detail);
        }
        return null;
    }
    var buf: []*const out.DetailMore = allocator.allocateIrreversible(*const out.DetailMore, impl_group.len);
    const filtered: Filtered = filterTechnique(impl_group, buf, options[0].info.field_field_names[field_index]);
    if (filtered[1].len != 0) {
        array.writeMany("." ++ comptime options[0].tagName(field_index) ++ " => ");
        if (filtered[1].len == 1) {
            writeReturnImplementation(array, filtered[1][0]);
        } else {
            array.writeMany("{\n");
            writeDeduction(allocator, array, toplevel_impl_group, filtered[1], options[1..]);
            array.writeMany("},\n");
        }
    }
    if (filtered[0].len != 0) {
        return writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, filtered[0], options, field_index + 1);
    }
    return null;
}
fn writeDeductionCompareEnumeration(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("switch (options." ++ options[0].info.field_name ++ ") {\n");
    const rem: ?[]const *const out.DetailMore =
        writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n");
    writeDeduction(allocator, array, toplevel_impl_group, rem orelse return, options[1..]);
}
fn writeDeductionCompareOptionalEnumeration(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("if (options." ++ options[0].info.field_name ++ ") |" ++
        options[0].info.field_name ++ "| {\nswitch (" ++
        options[0].info.field_name ++ ") {\n");
    const rem: ?[]const *const out.DetailMore =
        writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n}\n");
    writeDeduction(allocator, array, toplevel_impl_group, rem orelse return, options[1..]);
}
fn writeDeduction(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    if (options.len == 0) {
        if (impl_group.len == 1) {
            return writeReturnImplementation(array, impl_group[0]);
        }
    } else {
        const tag: gen.Option.Usage = options[0].usage(out.DetailMore, toplevel_impl_group);
        switch (tag) {
            .eliminate_boolean_false,
            .eliminate_boolean_true,
            => return writeDeduction(allocator, array, toplevel_impl_group, impl_group, options[1..]),
            .test_boolean => {
                return writeDeductionTestBoolean(allocator, array, toplevel_impl_group, impl_group, options, options[0].info.field_field_names);
            },
            .compare_enumeration => {
                return writeDeductionCompareEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
            },
            .compare_optional_enumeration => {
                return writeDeductionCompareOptionalEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
            },
        }
    }
}
pub fn generateReferences() void {
    var address_space: AddressSpace = .{};
    var allocator: gen.Allocator = try gen.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: gen.String = undefined;
    array.undefineAll();
    gen.writeImports(&array, @src(), &.{
        .{ .name = "mach", .path = "../mach.zig" },
        .{ .name = "algo", .path = "../algo.zig" },
    });
    array.writeMany(@embedFile("./reference-template.zig"));
    var accm_spec_index: u16 = 0;
    var ctn_index: u16 = 0;
    while (ctn_index != out.container_specifications.len) : (ctn_index +%= 1) {
        const ctn_group: []const []const u16 = out.container_specifications[ctn_index];
        var spec_index: u16 = 0;
        while (spec_index != ctn_group.len) : (spec_index +%= 1) {
            defer accm_spec_index +%= 1;
            const spec_group: []const u16 = ctn_group[spec_index];
            if (spec_group.len == 0) {
                continue;
            }
            const pindex: u8 = out.variants[spec_group[0]].index;
            const sindex: u8 = builtin.popcnt(u8, meta.leastRealBitCast(out.variants[spec_group[0]].specs));
            array.writeMany("pub const Specification");
            gen.writeIndex(&array, accm_spec_index);
            array.writeMany(" = struct {\n");
            for (out.type_descrs[pindex].specs[sindex].type_decl.Composition[1]) |field| {
                array.writeMany(field[0]);
                array.writeMany(": ");
                array.writeFormat(field[1]);
                array.writeMany(",\n");
            }
            array.writeMany("const Specification = @This();\n");
            if (spec_group.len == 1) {
                array.writeMany("pub fn Implementation(comptime spec: Specification) type {\n");
                writeReturnImplementation(&array, &out.variants[spec_group[0]]);
                array.writeMany("}\n" ++ "};\n");
                continue;
            }
            const save: gen.Allocator.Save = allocator.save();
            defer allocator.restore(save);
            const buf: []*const out.DetailMore = allocator.allocateIrreversible(*const out.DetailMore, spec_group.len);
            var impl_index: u16 = 0;
            while (impl_index != spec_group.len) : (impl_index +%= 1) {
                const impl_variant: *const out.DetailMore = &out.variants[spec_group[impl_index]];
                buf[impl_index] = impl_variant;
            }
            array.writeMany("pub fn Implementation(comptime spec: Specification, comptime options: anytype) type {\n");
            writeDeduction(&allocator, &array, buf, buf, &out.options);
            array.writeMany("}\n" ++ "};\n");
        }
    }
    gen.writeSourceFile(&array, "reference.zig");
}
pub const main = generateReferences;
