//! Group variants by container to generate parameter variants.
const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");
const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/options.zig");
    usingnamespace @import("./zig-out/src/type_descrs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
const config = @import("./config.zig");

pub usingnamespace proc.start;

pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 8,
    .errors = .{
        .acquire = .abort,
        .release = .abort,
    },
});
const Array = Allocator.StructuredStaticVector(u8, 1024 * 4096);

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

fn writeOptionsInternal(
    array: *Array,
    field_name: []const u8,
    usage: gen.Option.Usage,
    field_names: []const []const u8,
) u1 {
    switch (usage) {
        .test_boolean => {
            array.writeMany(field_names[0]);
            array.writeMany(": bool,\n");
        },
        .compare_optional_enumeration => {
            array.writeMany(field_name);
            array.writeMany(": ?enum {\n");
            for (field_names) |name| {
                array.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                array.writeMany(",\n");
            }
            array.overwriteManyBack(" }");
            array.writeMany(",\n");
        },
        .compare_enumeration => {
            array.writeMany(field_name);
            array.writeMany(": enum {\n");
            for (field_names) |name| {
                array.writeMany(name[0 .. name.len - (field_name.len + 1)]);
                array.writeMany(",\n");
            }
            array.overwriteManyBack(" }");
            array.writeMany(",\n");
        },
        .eliminate_boolean_false => {
            if (config.show_eliminated_options) {
                array.writeMany("comptime ");
                array.writeMany(field_name);
                array.writeMany(": bool = true,\n");
            } else {
                return 0;
            }
        },
        .eliminate_boolean_true => {
            if (config.show_eliminated_options) {
                array.writeMany("comptime ");
                array.writeMany(field_name);
                array.writeMany(": bool = false,\n");
            } else {
                return 0;
            }
        },
    }
    return 1;
}
fn writeOptions(array: *Array, toplevel_impl_group: []const out.DetailMore) void {
    array.writeMany("const Options = struct {");
    var write: u1 = 0;
    inline for (out.options) |option| {
        write |= writeOptionsInternal(
            array,
            option.info.field_name,
            option.usage(out.DetailMore, toplevel_impl_group),
            option.names(out.DetailMore, toplevel_impl_group).readAll(),
        );
    }
    if (write == 0) {
        array.undefine(24);
    } else {
        array.writeMany("};\n");
    }
    array.writeMany("};\n");
}
fn generateParameters() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = Array.init(&allocator, 1);
    array.undefineAll();
    gen.writeImports(&array, @src(), &.{});
    gen.copySourceFile(&array, "container-template.zig");
    var ctn_index: u16 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);
        const ctn_group: []const u16 = out.containers[ctn_index];
        array.writeMany("pub const ");
        out.impl_variants[ctn_group[0]].writeContainerName(&array);
        array.writeMany("Spec = struct {\n");
        for (out.type_descrs[out.impl_variants[ctn_group[0]].index].params.type_decl.Composition[1]) |field| {
            gen.writeField(&array, field[0], field[1]);
        }
        const buf: []out.DetailMore = allocator.allocateIrreversible(out.DetailMore, ctn_group.len);
        var impl_index: u16 = 0;
        while (impl_index != ctn_group.len) : (impl_index +%= 1) {
            buf[impl_index] = out.impl_variants[ctn_group[impl_index]];
        }
        writeOptions(&array, buf);
    }
    gen.writeSourceFile(&array, "container.zig");
}
pub const main = generateParameters;
