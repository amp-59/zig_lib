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
const attr = @import("./attr.zig");
const detail = @import("./detail.zig");
const config = @import("./config.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/options.zig");
    usingnamespace @import("./zig-out/src/type_descrs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
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

const String = Allocator.StructuredVector(u8);
const StringArray = Allocator.StructuredVector([]const u8);

const Array = struct {
    options: String,
    params: String,
    indices: StringArray,
};
fn writeOptionsInternal(array: *Array, field_name: []const u8, usage: attr.Option.Usage, field_names: []const []const u8) void {
    switch (usage) {
        .test_boolean => {
            array.options.writeMany(field_names[0]);
            array.options.writeMany(":bool,\n");
        },
        .compare_optional_enumeration => {
            array.options.writeMany(field_name);
            array.options.writeMany(":?enum{\n");
            for (field_names) |name| {
                array.options.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                array.options.writeMany(",\n");
            }
            array.options.undefine(1);
            array.options.overwriteManyBack("}");
            array.options.writeMany(",\n");
        },
        .compare_enumeration => {
            array.options.writeMany(field_name);
            array.options.writeMany(":enum{\n");
            for (field_names) |name| {
                array.options.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                array.options.writeMany(",\n");
            }
            array.options.undefine(1);
            array.options.overwriteManyBack("}");
            array.options.writeMany(",\n");
        },
        .eliminate_boolean_false => {
            if (config.show_eliminated_options) {
                array.options.writeMany("comptime ");
                array.options.writeMany(field_name);
                array.options.writeMany(":bool=true,\n");
            }
        },
        .eliminate_boolean_true => {
            if (config.show_eliminated_options) {
                array.options.writeMany("comptime ");
                array.options.writeMany(field_name);
                array.options.writeMany(":bool=false,\n");
            }
        },
    }
}
fn writeOptions(array: *Array, toplevel_impl_group: []const detail.More) ?u64 {
    const no_decl_len: u64 = array.options.len();
    array.options.writeMany("const Options");
    array.options.writeFormat(fmt.ud64(array.indices.len()));
    array.options.writeMany("=struct{");
    const no_fields_len: u64 = array.options.len();
    inline for (out.options) |option| {
        var buf: [option.len()][]const u8 = undefined;
        writeOptionsInternal(
            array,
            option.info.field_name,
            option.usage(detail.More, toplevel_impl_group),
            option.names(detail.More, toplevel_impl_group, &buf),
        );
    }
    const fields_len: u64 = array.options.len() - no_fields_len;
    if (fields_len == 0) {
        array.options.undefine(array.options.len() - no_decl_len);
        return null;
    }
    if (writeOneUniqueOptionsStruct(array, array.options.readManyAt(no_fields_len)[0..fields_len])) |dupe_index| {
        array.options.undefine(array.options.len() - no_decl_len);
        return dupe_index;
    }
    array.options.writeMany("};\n");
    return array.indices.len() - 1;
}
fn writeOneUniqueOptionsStruct(array: *Array, new: []const u8) ?u64 {
    for (array.indices.readAll(), 0..) |unique, index| {
        if (mem.testEqualMany(u8, unique, new)) {
            return index;
        }
    } else {
        array.indices.writeOne(new);
    }
    return null;
}
fn writeContainerGroup(allocator: *Allocator, array: *Array, ctn_group: []const out.Index) void {
    array.params.writeMany("pub const ");
    out.impl_variants[ctn_group[0]].writeContainerName(&array.params);
    array.params.writeMany("Spec=struct{\n");
    for (out.type_descrs[out.impl_variants[ctn_group[0]].index].params.type_decl.Composition[1]) |field| {
        gen.writeField(&array.params, field[0], field[1]);
    }
    const buf: []detail.More = allocator.allocateIrreversible(detail.More, ctn_group.len);
    var impl_index: u16 = 0;
    while (impl_index != ctn_group.len) : (impl_index +%= 1) {
        buf[impl_index] = out.impl_variants[ctn_group[impl_index]];
    }
    if (writeOptions(array, buf)) |decl_idx| {
        array.params.writeMany("options:Options");
        array.params.writeFormat(fmt.ud64(decl_idx));
        array.params.writeMany(",");
    }
    array.params.writeMany("const Specification=@This();\n");
    array.params.writeMany("};\n");
}
fn generateParameters() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = .{
        .options = String.init(&allocator, 1024 * 1024),
        .params = String.init(&allocator, 1024 * 1024),
        .indices = StringArray.init(&allocator, 512),
    };
    array.options.undefineAll();
    array.params.undefineAll();
    gen.writeImport(&array.options, "mach", "../mach.zig");
    gen.writeImport(&array.options, "meta", "../meta.zig");
    gen.writeImport(&array.options, "builtin", "../builtin.zig");
    gen.writeImport(&array.options, "reference", "references.zig");
    gen.copySourceFile(&array.params, "container-template.zig");
    array.options.writeMany(gen.subTemplate(array.params.readAllWithSentinel(0), "container-template.zig").?);
    array.params.undefineAll();
    var ctn_index: u64 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);
        const ctn_group: []const out.Index = out.containers[ctn_index];
        writeContainerGroup(&allocator, &array, ctn_group);
    }
    gen.writeSourceFile(&array.options, "containers.zig");
    gen.appendSourceFile(&array.params, "containers.zig");
}
pub const main = generateParameters;
