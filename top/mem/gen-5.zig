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

fn fieldNames(comptime T: type) []const []const u8 {
    var field_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        field_names = field_names ++ [1][]const u8{field.name};
    }
    return field_names;
}
fn simpleTypeName(comptime T: type) []const u8 {
    if (@typeInfo(T) == .Struct) {
        var type_name: []const u8 = "struct { ";
        for (@typeInfo(T).Struct.fields) |field_field| {
            type_name = type_name ++ field_field.name ++ ": " ++ @typeName(field_field.type) ++ ", ";
        }
        type_name = type_name[0 .. type_name.len - 2] ++ " }";
        return type_name;
    } else {
        return @typeName(T);
    }
}
fn fieldTypeNames(comptime T: type) []const []const u8 {
    var field_type_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        field_type_names = field_type_names ++ [1][]const u8{simpleTypeName(field.type)};
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

fn fieldIs(any: anytype, field_name: []const u8) bool {
    inline for (@typeInfo(@TypeOf(any)).Struct) |field| {
        if (builtin.testEqual([]const u8, field.name, field_name)) {
            return @field(any, field.name);
        }
    }
    unreachable;
}

fn haveField(comptime types: []const type, comptime field_name: []const u8) gen.BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasField(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}
fn haveDecl(comptime types: []const type, comptime field_name: []const u8) gen.BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasDecl(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}

fn typeNames(comptime types: []const type) []const u8 {
    var ret: []const u8 = ".{ ";
    for (types) |T| {
        ret = ret ++ fmt.typeName(T) ++ ", ";
    }
    return ret ++ "}";
}
const specs_len: usize = blk: {
    var len: usize = 0;
    inline for (gen.type_specs) |type_spec| {
        len +%= type_spec.specs.len;
    }
    break :blk len;
};
const field_names_sets: [specs_len][]const []const u8 = blk: {
    var tmp: [specs_len][]const []const u8 = undefined;
    var index: usize = 0;
    for (gen.type_specs) |type_spec| {
        for (type_spec.specs) |spec| {
            tmp[index] = fieldNames(spec);
            index +%= 1;
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
            index +%= 1;
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
fn printX(array: *Array, field_name: []const u8, field_type_name: []const u8) void {
    array.writeMany(field_name);
    array.writeMany(": ");
    array.writeMany(field_type_name);
    array.writeMany("\n");
}

const Filter = struct {
    t: []gen.DetailExtra,
    f: []gen.DetailExtra,
};
fn filterOnBasis(
    allocator: *gen.Allocator,
    impl_variant_groups: []const gen.DetailExtra,
    test_function: *const fn (*const gen.DetailExtra) bool,
) Filter {
    var ret: Filter = .{
        .t = allocator.allocate(gen.DetailExtra, impl_variant_groups.len),
        .f = allocator.allocate(gen.DetailExtra, impl_variant_groups.len),
    };
    var t: u64 = 0;
    var f: u64 = 0;
    for (impl_variant_groups) |impl_variant| {
        if (test_function(&impl_variant)) {
            ret.t[t] = impl_variant;
            t += 1;
        } else {
            ret.f[f] = impl_variant;
            f += 1;
        }
    }
    ret.t = ret.t[0..t];
    ret.f = ret.f[0..f];
    return ret;
}

pub fn generateSpecificationStructs() void {}
