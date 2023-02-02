//! The purpose of this stage is to interpret available techniques and deduce
//! a minimal input type.

// Deduction responsibilities:
// Memory (Kind/Structure/Mode):
//  The user is responsible for selecting which general variety of container
//  they are after.
//
// Specification (Specifiers):
//  The container is responsible for deducing implementation specification based
//  on which optional parameters are defined.
//
// Implementation (Technique):
//  The implementation specification is responsible for deducing implementation
//  based on which techniques are selected.

const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-2.zig");

    usingnamespace @import("./abstract_params.zig");
    usingnamespace @import("./type_specs.zig");
    usingnamespace @import("./impl_details.zig");
};

pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
});
const Selection = Allocator.StructuredVector([]const u8);

const Array = mem.StaticString(1024 * 1024);

const OptKind = union(enum) {
    standalone_mandatory: []const []const u8,
    standalone_optional: []const []const u8,
    mutually_exclusive_optional: []const []const u8,
    mutually_exclusive_mandatory: []const []const u8,
};

fn fieldOptKind(comptime field: builtin.Type.StructField) OptKind {
    comptime var field_names: []const []const u8 = &.{};
    const field_type_info: builtin.Type = @typeInfo(field.type);
    if (field_type_info == .Optional) {
        const field_type_child_info: builtin.Type = @typeInfo(field_type_info.Optional.child);
        if (field_type_child_info == .Enum) {
            inline for (field_type_child_info.Enum.fields) |field_field| {
                const field_name: []const u8 = field_field.name ++ "_" ++ field.name;
                builtin.static.assert(@hasField(gen.Techniques, field_name));
                field_names = field_names ++ [1][]const u8{field_name};
            }
            return .{ .mutually_exclusive_optional = field_names };
        }
    } else if (field_type_info == .Enum) {
        inline for (field_type_info.Enum.fields) |field_field| {
            const field_name: []const u8 = field_field.name ++ "_" ++ field.name;
            builtin.static.assert(@hasField(gen.Techniques, field_name));
            field_names = field_names ++ [1][]const u8{field_name};
        }
        return .{ .mutually_exclusive_mandatory = field_names };
    }
}

fn selectFieldNames(
    allocator: *Allocator,
    bits: meta.Child(gen.Techniques),
    field_names: []const []const u8,
) Selection {
    const techs: gen.Techniques = @bitCast(gen.Techniques, bits);
    var ret: Selection = Selection.init(allocator, field_names.len);
    inline for (@typeInfo(gen.Techniques).Struct.fields) |field| {
        for (field_names) |field_name| {
            if (builtin.testEqual([]const u8, field.name, field_name)) {
                if (@field(techs, field.name)) {
                    ret.writeOne(field.name);
                }
            }
        }
    }
    ret.shrink(allocator, ret.len());
    return ret;
}
pub fn generateTechniqueOptionsInternal(
    array: *Array,
    allocator: *Allocator,
    impl_group: []const gen.Detail,
    field_name: []const u8,
    kind: OptKind,
) void {
    const backing_int: type = meta.Child(gen.Techniques);
    var bits: backing_int = 0;
    for (impl_group) |impl_variant| bits |= meta.leastBitCast(impl_variant.techs);
    var suffix: mem.StaticString(512) = .{};
    suffix.writeOne('_');
    suffix.writeMany(field_name);
    switch (kind) {
        .standalone_optional => {},
        .standalone_mandatory => {},
        .mutually_exclusive_optional => |field_names| {
            var selection: Selection = selectFieldNames(allocator, bits, field_names);
            defer selection.deinit(allocator);
            switch (selection.len()) {
                0 => {},
                1 => {
                    array.writeMany("    ");
                    array.writeMany(selection.readOneAt(0));
                    array.writeMany(": bool,\n");
                },
                else => {
                    array.writeMany("    ");
                    array.writeMany(field_name);
                    array.writeMany(": ?enum { ");
                    for (selection.readAll()) |field_field_name| {
                        array.writeMany(mem.readBeforeFirstEqualMany(u8, suffix.readAll(), field_field_name).?);
                        array.writeMany(", ");
                    }
                    array.overwriteManyBack(" }");
                    array.writeMany(",\n");
                },
            }
        },
        .mutually_exclusive_mandatory => |field_names| {
            var selection: Selection = selectFieldNames(allocator, bits, field_names);
            defer selection.deinit(allocator);
            switch (selection.len()) {
                0 => {},
                1 => {
                    array.writeMany("    comptime ");
                    array.writeMany(selection.readOneAt(0));
                    array.writeMany(": bool = true,\n");
                },
                else => {
                    array.writeMany("    ");
                    array.writeMany(field_name);
                    array.writeMany(": enum { ");
                    for (selection.readAll()) |field_field_name| {
                        array.writeMany(mem.readBeforeFirstEqualMany(u8, suffix.readAll(), field_field_name).?);
                        array.writeMany(", ");
                    }
                    array.overwriteManyBack(" }");
                    array.writeMany(",\n");
                },
            }
        },
    }
}
pub fn generateTechniqueOptions() void {
    const fields: []const builtin.Type.StructField = @typeInfo(gen.Techniques.Options).Struct.fields;
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = .{};
    for (gen.param_impl_groups) |impl_group, param_index| {
        array.writeMany("pub const Options");
        array.writeFormat(fmt.ud64(param_index));
        array.writeMany(" = struct {\n");
        var opt_kinds: [fields.len]OptKind = undefined;
        var field_names: [fields.len][]const u8 = undefined;
        inline for (@typeInfo(gen.Techniques.Options).Struct.fields) |field, field_index| {
            opt_kinds[field_index] = fieldOptKind(field);
            field_names[field_index] = field.name;
        }
        for (opt_kinds) |field_opt_kind, field_index| {
            generateTechniqueOptionsInternal(&array, &allocator, impl_group, field_names[field_index], field_opt_kind);
        }
        array.writeMany("};\n");
    }
    builtin.debug.write(array.readAll());
}
