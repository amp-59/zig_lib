const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const meta = @import("./../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");

const config = @import("./config.zig");
const gen = struct {
    usingnamespace @import("./gen.zig");

    usingnamespace @import("./gen-0.zig");
    usingnamespace @import("./gen-1.zig");
    usingnamespace @import("./gen-2.zig");

    usingnamespace @import("./abstract_params.zig");
    usingnamespace @import("./type_specs.zig");
    usingnamespace @import("./impl_variant_groups.zig");
};

const Array = mem.StaticString(1024 * 1024);
const Detail = *const gen.Detail;
const Filtered = struct {
    []const Detail,
    []const Detail,
};
fn filterTechnique(
    impl_groups: []const Detail,
    buf: []Detail,
    comptime field_name: []const u8,
) Filtered {
    if (!@hasField(gen.Techniques, field_name)) {
        asm volatile ("movq %rax, %[p]"
            :
            : [p] "p" (@intToPtr(*allowzero anyopaque, 0)),
        );
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
    const f: []Detail = buf[f_idx..];
    f_idx = 0;
    while (f_idx != f.len) : (f_idx +%= 1) {
        const a: Detail = f[f_idx];
        f[f_idx] = f[f.len -% (1 +% f_idx)];
        f[f.len -% (1 +% f_idx)] = a;
    }
    return .{ f, buf[0..t_len] };
}

// TODO: constant maximum largest impl group
// TODO: constant field names

fn writeReturnImplementation(array: *Array, impl_detail: Detail) void {
    array.writeMany("return ");
    array.writeFormat(impl_detail.brief());
    writeTechName(array, impl_detail.techs);
    return array.writeMany(";\n");
}
fn writeDeductionTestBoolean(
    allocator: *gen.Allocator,
    array: *Array,
    toplevel_impl_group: []const gen.Detail,
    impl_group: []const Detail,
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
    var buf: []Detail = allocator.allocate(Detail, impl_group.len);
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
fn writeTechName(array: *Array, techs: gen.Techniques) void {
    inline for (@typeInfo(gen.Techniques).Struct.fields) |field| {
        if (@field(techs, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
}
fn writeDeductionCompareEnumerationInternal(
    allocator: *gen.Allocator,
    array: *Array,
    toplevel_impl_group: []const gen.Detail,
    impl_group: []const Detail,
    comptime options: []const gen.Option,
    comptime field_index: usize,
) ?[]const Detail {
    if (field_index == options[0].info.field_field_names.len and options.len != 0) {
        return impl_group;
    }
    var buf: []Detail = allocator.allocate(Detail, impl_group.len);
    const filtered: Filtered = filterTechnique(impl_group, buf, options[0].info.field_field_names[field_index]);
    if (filtered[1].len != 0) {
        array.writeMany("." ++ comptime options[0].tagName(field_index) ++ " => ");
        if (filtered[1].len == 1) {
            array.writeMany("return ");
            array.writeFormat(filtered[1][0].brief());
            writeTechName(array, filtered[1][0].techs);
            array.writeMany(",\n");
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
    array: *Array,
    toplevel_impl_group: []const gen.Detail,
    impl_group: []const Detail,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("switch (options." ++ options[0].info.field_name ++ ") {\n");
    const rem: ?[]const Detail = writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n");
    if (rem) |rem_impl_group| {
        writeDeduction(allocator, array, toplevel_impl_group, rem_impl_group, options[1..]);
    }
}
fn writeDeductionCompareOptionalEnumeration(
    allocator: *gen.Allocator,
    array: *Array,
    toplevel_impl_group: []const gen.Detail,
    impl_group: []const Detail,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("if (options." ++ options[0].info.field_name ++ ") |" ++
        options[0].info.field_name ++ "| {\nswitch (" ++
        options[0].info.field_name ++ ") {\n");
    const rem: ?[]const Detail = writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n}\n");
    if (rem) |rem_impl_group| {
        writeDeduction(allocator, array, toplevel_impl_group, rem_impl_group, options[1..]);
    }
}
fn writeDeduction(
    allocator: *gen.Allocator,
    array: *Array,
    toplevel_impl_group: []const gen.Detail,
    impl_group: []const Detail,
    comptime options: []const gen.Option,
) void {
    if (options.len == 0) {
        if (impl_group.len == 1) {
            writeReturnImplementation(array, impl_group[0]);
        }
    } else switch (options[0].usage(toplevel_impl_group)) {
        .eliminate_boolean_false => {},
        .eliminate_boolean_true => {},
        .test_boolean => {
            writeDeductionTestBoolean(allocator, array, toplevel_impl_group, impl_group, options, options[0].info.field_field_names);
        },
        .compare_enumeration => {
            writeDeductionCompareEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
        },
        .compare_optional_enumeration => {
            writeDeductionCompareOptionalEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
        },
    }
}
fn writeFile(array: *Array) void {
    const fd: u64 = gen.create(builtin.build_root.? ++ "/top/mem/impl_deduction.zig");
    defer gen.close(fd);
    gen.write(fd, array.readAll());
}
fn generateImplementationDeductions(allocator: *gen.Allocator, array: *Array) void {
    array.writeMany("comptime {\n");
    const impl_detail_groups: []const []const gen.Detail = comptime gen.containerParamImplGroups();
    for (impl_detail_groups) |impl_detail_group| {
        var buf: []Detail = allocator.allocate(Detail, impl_detail_group.len);
        for (buf) |*impl_detail, impl_index| impl_detail.* = &impl_detail_group[impl_index];
        writeDeduction(allocator, array, impl_detail_group, buf, &gen.options);
    }
    array.writeMany("}\n");
}
pub fn generateSpecificationStructs() void {
    var allocator: gen.Allocator = gen.Allocator.init();
    const array: *Array = allocator.create(Array);
    array.undefineAll();
    generateImplementationDeductions(&allocator, array);
    writeFile(array);
}
