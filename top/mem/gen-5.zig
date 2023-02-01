const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
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
    usingnamespace @import("./impl_variants.zig");
};

const Array = mem.StaticString(1024 * 1024);

fn fieldNames(comptime T: type) []const []const u8 {
    var field_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        field_names = field_names ++ [1][]const u8{field.name};
    }
    return field_names;
}
fn fieldTypeNames(comptime T: type) []const []const u8 {
    var field_type_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        if (@typeInfo(field.type) == .Struct) {
            var type_name: []const u8 = "struct { ";
            for (@typeInfo(field.type).Struct.fields) |field_field| {
                type_name = type_name ++ field_field.name ++ ": " ++ @typeName(field_field.type) ++ ", ";
            }
            type_name = type_name[0 .. type_name.len - 2] ++ " }";
            field_type_names = field_type_names ++ [1][]const u8{type_name};
        } else {
            field_type_names = field_type_names ++ [1][]const u8{@typeName(field.type)};
        }
    }
    return field_type_names;
}
inline fn subSpecLengths(comptime type_specs: []const gen.TypeSpecMap) []const usize {
    var sub_spec_lens: []const usize = &.{};
    for (type_specs) |type_spec| {
        sub_spec_lens = sub_spec_lens ++ [1]usize{type_spec.specs.len};
    }
    return sub_spec_lens;
}
inline fn writeSpecificationStruct(array: *Array, comptime T: type) void {
    const field_names: []const []const u8 = comptime fieldNames(T);
    const field_type_names: []const []const u8 = comptime fieldTypeNames(T);
    for (field_names) |field_name, field_index| {
        array.writeMany(field_name);
        array.writeMany(": ");
        array.writeMany(field_type_names[field_index]);
        array.writeMany(",\n");
    }
}

fn writeSpec(array: *Array, spec: anytype) void {
    array.writeAny(preset.reinterpret.fmt, .{
        fmt.render(.{ .enable_comptime_iterator = true }, spec),
        '\n',
    });
}

const specs_len: usize = blk: {
    var len: usize = 0;
    inline for (gen.type_specs) |type_spec| {
        len += type_spec.specs.len;
    }
    break :blk len;
};
const field_names_sets: [specs_len][]const []const u8 = blk: {
    var tmp: [specs_len][]const []const u8 = undefined;
    var index: usize = 0;
    for (gen.type_specs) |type_spec| {
        for (type_spec.specs) |spec| {
            tmp[index] = fieldNames(spec);
            index += 1;
        }
    }
    break :blk tmp;
};
const field_type_names_sets: [specs_len][]const []const u8 = blk: {
    var tmp: [specs_len][]const []const u8 = undefined;
    var index: usize = 0;
    for (gen.type_specs) |type_spec| {
        for (type_spec.specs) |spec| {
            tmp[index] = fieldTypeNames(spec);
            index += 1;
        }
    }
    break :blk tmp;
};
const FieldTokens = struct {
    name: []const u8,
    type_name: []const u8,
};
const spec_tokens: [specs_len][]const FieldTokens = blk: {
    var set: [specs_len][]const FieldTokens = undefined;
    var index: usize = 0;
    while (index != specs_len) : (index +%= 1) {
        var sub_set: []const FieldTokens = &.{};
        var sub_index: usize = 0;
        while (sub_index != field_names_sets[index].len) : (sub_index +%= 1) {
            sub_set = sub_set ++ [1]FieldTokens{.{
                .name = field_names_sets[index][sub_index],
                .type_name = field_type_names_sets[index][sub_index],
            }};
        }
        set[index] = sub_set;
    }
    break :blk set;
};

const work_upfront: bool = false;

pub fn generateSpecificationStructs() void {
    var array: Array = undefined;
    array.undefineAll();

    if (work_upfront) {
        for (gen.impl_variants) |_, spec_index| {
            const tokens: []const FieldTokens = spec_tokens[spec_index];
            for (tokens) |field| {
                builtin.debug.logAlways(field.name);
                builtin.debug.logAlways(": ");
                builtin.debug.logAlways(field.type_name);
                builtin.debug.logAlways("\n");
            }
        }
    } else {
        inline for (gen.type_specs) |type_spec| {
            inline for (type_spec.specs) |spec| {
                inline for (@typeInfo(spec).Struct.fields) |field| {
                    builtin.debug.logAlways(field.name);
                    builtin.debug.logAlways(": ");
                    builtin.debug.logAlways(@typeName(field.type));
                    builtin.debug.logAlways("\n");
                }
            }
        }
    }
}
