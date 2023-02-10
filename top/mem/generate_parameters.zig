//! Group variants by container to generate parameter variants.
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = @import("./gen.zig");
const sym = @import("./sym.zig");
const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/type_descrs.zig");
    usingnamespace @import("./zig-out/src/options.zig");
    usingnamespace @import("./zig-out/src/variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
const config = @import("./config.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.regular_128;
pub const runtime_assertions: bool = true;

fn generateParameters() void {
    var address_space: AddressSpace = .{};
    var allocator: gen.Allocator = try gen.Allocator.init(&address_space);
    var array: gen.String = undefined;
    array.undefineAll();
    var ctn_index: u16 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const save: gen.Allocator.Save = allocator.save();
        defer allocator.restore(save);
        const ctn_group: []const u16 = out.containers[ctn_index];
        array.writeMany("pub const ");
        out.variants[ctn_group[0]].writeContainerName(&array);
        array.writeMany("Spec = struct {\n");
        const pindex: u8 = out.variants[ctn_group[0]].index;
        for (out.type_descrs[pindex].params.type_decl.Composition[1]) |field| {
            array.writeMany(field[0]);
            array.writeMany(": ");
            array.writeFormat(field[1]);
            array.writeMany(",\n");
        }
        const buf: []out.DetailMore = allocator.allocateIrreversible(out.DetailMore, ctn_group.len);
        var impl_index: u16 = 0;
        while (impl_index != ctn_group.len) : (impl_index +%= 1) {
            buf[impl_index] = out.variants[ctn_group[impl_index]];
        }
        inline for (out.options) |option| {
            const usage: gen.Option.Usage = option.usage(out.DetailMore, buf);
            const names: []const []const u8 = option.names(out.DetailMore, buf).readAll();
            switch (usage) {
                .test_boolean => {
                    builtin.assertEqual(u64, names.len, 1);
                    array.writeMany(names[0]);
                    array.writeMany(": bool,\n");
                },
                .compare_optional_enumeration => {
                    builtin.assertNotEqual(u64, names.len, 1);
                    array.writeMany(option.info.field_name);
                    array.writeMany(": ?enum {\n");
                    for (names) |name| {
                        array.writeMany(name);
                        array.writeMany(",\n");
                    }
                    array.writeMany("},\n");
                },
                .compare_enumeration => {
                    builtin.assertNotEqual(u64, names.len, 1);
                    array.writeMany(option.info.field_name);
                    array.writeMany(": enum {\n");
                    for (names) |name| {
                        array.writeMany(name);
                        array.writeMany(",\n");
                    }
                    array.writeMany("},\n");
                },
                .eliminate_boolean_false => {
                    if (config.show_eliminated_options) {
                        array.writeMany("comptime ");
                        array.writeMany(option.info.field_name);
                        array.writeMany(": bool = true,\n");
                    }
                },
                .eliminate_boolean_true => {
                    if (config.show_eliminated_options) {
                        array.writeMany("comptime ");
                        array.writeMany(option.info.field_name);
                        array.writeMany(": bool = false,\n");
                    }
                },
            }
        }
        array.writeMany("};\n");
    }
    gen.writeSourceFile(&array, "container.zig");
}

pub const main = generateParameters;
