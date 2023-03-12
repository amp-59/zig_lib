//! Group variants by container to generate parameter variants.
const gen = @import("./gen.zig");
const fmt = gen.fmt;
const mem = gen.mem;
const proc = gen.proc;
const meta = gen.meta;
const preset = gen.preset;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const attr = @import("./attr.zig");
const detail = @import("./detail.zig");
const config = @import("./config.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/config.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/options.zig");
    usingnamespace @import("./zig-out/src/type_descrs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
    usingnamespace @import("./zig-out/src/specifications.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};
pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 128,
    .errors = .{},
    .logging = preset.address_space.logging.silent,
});

const Expr = expr.Expr;
const String = Allocator.StructuredVector(u8);
const StringArray = Allocator.StructuredVector([]const u8);

fn writeOptionsInternal(options: *String, field_name: []const u8, usage: attr.Option.Usage, field_names: []const []const u8) void {
    switch (usage) {
        .test_boolean => {
            options.writeMany(field_names[0]);
            options.writeMany(":bool,\n");
        },
        .compare_optional_enumeration => {
            options.writeMany(field_name);
            options.writeMany(":?enum{\n");
            for (field_names) |name| {
                options.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                options.writeMany(",\n");
            }
            options.undefine(1);
            options.overwriteManyBack("}");
            options.writeMany(",\n");
        },
        .compare_enumeration => {
            options.writeMany(field_name);
            options.writeMany(":enum{\n");
            for (field_names) |name| {
                options.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                options.writeMany(",\n");
            }
            options.undefine(1);
            options.overwriteManyBack("}");
            options.writeMany(",\n");
        },
        .eliminate_boolean_false => {
            if (config.show_eliminated_options) {
                options.writeMany("comptime ");
                options.writeMany(field_name);
                options.writeMany(":bool=true,\n");
            }
        },
        .eliminate_boolean_true => {
            if (config.show_eliminated_options) {
                options.writeMany("comptime ");
                options.writeMany(field_name);
                options.writeMany(":bool=false,\n");
            }
        },
    }
}
fn writeOptions(options: *String, indices: *StringArray, toplevel_impl_group: []const detail.More) ?u64 {
    const no_decl_len: u64 = options.len();
    options.writeMany("const Options");
    options.writeFormat(fmt.ud64(indices.len()));
    options.writeMany("=struct{");
    const no_fields_len: u64 = options.len();
    inline for (out.options) |option| {
        var buf: [option.len()][]const u8 = undefined;
        writeOptionsInternal(
            options,
            option.info.field_name,
            option.usage(detail.More, toplevel_impl_group),
            option.names(detail.More, toplevel_impl_group, &buf),
        );
    }
    const fields_len: u64 = options.len() - no_fields_len;
    if (fields_len == 0) {
        options.undefine(options.len() - no_decl_len);
        return null;
    }
    if (writeOneUniqueOptionsStruct(indices, options.readManyAt(no_fields_len)[0..fields_len])) |dupe_index| {
        options.undefine(options.len() - no_decl_len);
        return dupe_index;
    }
    options.writeMany("};\n");
    return indices.len() - 1;
}
fn writeOneUniqueOptionsStruct(indices: *StringArray, new: []const u8) ?u64 {
    for (indices.readAll(), 0..) |unique, index| {
        if (mem.testEqualMany(u8, unique, new)) {
            return index;
        }
    } else {
        indices.writeOne(new);
    }
    return null;
}
// fn Implementation(spec: Specification) type {
//     const child: type = spec.child;
//     const count: u64 = spec.count;
//     const low_alignment: u64 = lowAlignment(spec);
//     const options: Options0 = spec.options;
//     if (spec.sentinel) |sentinel| {
//         reference.Specification5.Implementation(.{
//             .child = child,
//             .sentinel = sentinel,
//             .count = count,
//             .low_alignment = low_alignment,
//         }, options);
//     } else {
//         reference.Specification4.Implementation(.{
//             .child = child,
//             .count = count,
//             .low_alignment = low_alignment,
//         }, options);
//     }
// }

fn writeContainerGroup(allocator: *Allocator, options: *String, params: *String, indices: *StringArray, ctn_index: u64, spec_index: *u64) void {
    const ctn_group: []const out.Index = out.containers[ctn_index];
    const impl_variant: detail.More = out.impl_variants[ctn_group[0]];
    const params_index: u8 = impl_variant.index;

    params.writeMany("pub const ");
    out.impl_variants[ctn_group[0]].writeContainerName(params);
    params.writeMany("Spec=struct{\n");

    for (out.type_descrs[params_index].params.fields()) |field| {
        field.formatWrite(params);
    }

    const buf: []detail.More = allocator.allocateIrreversible(detail.More, ctn_group.len);
    var impl_index: u16 = 0;
    while (impl_index != ctn_group.len) : (impl_index +%= 1) {
        buf[impl_index] = out.impl_variants[ctn_group[impl_index]];
    }
    if (writeOptions(options, indices, buf)) |decl_idx| {
        params.writeMany("options:Options");
        params.writeFormat(fmt.ud64(decl_idx));
        params.writeMany(",");
    }
    params.writeMany("const Specification=@This();\nfn Implementation(spec:Specification)type{\n");
    for (out.specifications[ctn_index]) |spec_group| {
        if (spec_group.len != 0) {
            params.writeMany("reference.Specification");
            params.writeFormat(fmt.ud64(spec_index.*));
            params.writeMany(".Implementation(spec, spec.options);\n");
        }
        spec_index.* +%= 1;
    }
    params.writeMany("}\n");
    params.writeMany("};\n");
}
fn generateParameters() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var options: String = String.init(&allocator, 1024 * 1024);
    var params: String = String.init(&allocator, 1024 * 1024);
    var indices: StringArray = StringArray.init(&allocator, 512);
    options.undefineAll();
    params.undefineAll();
    gen.writeImport(&options, "mach", "../mach.zig");
    gen.writeImport(&options, "meta", "../meta.zig");
    gen.writeImport(&options, "builtin", "../builtin.zig");
    gen.writeImport(&options, "reference", "references.zig");
    gen.copySourceFile(&params, "container-template.zig");
    options.writeMany(gen.subTemplate(params.readAllWithSentinel(0), "container-template.zig").?);
    params.undefineAll();
    var spec_index: u64 = 0;
    var ctn_index: u64 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);
        writeContainerGroup(&allocator, &options, &params, &indices, ctn_index, &spec_index);
    }
    gen.writeSourceFile(&options, "containers.zig");
    gen.appendSourceFile(&params, "containers.zig");
}
pub const main = generateParameters;
