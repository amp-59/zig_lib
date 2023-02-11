//! This stage summarises the abstract specification.
const mem = @import("../mem.zig");
const sys = @import("../sys.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

fn fieldOption(comptime field: builtin.Type.StructField) gen.Option {
    comptime var field_names: []const []const u8 = &.{};
    const field_type_info: builtin.Type = @typeInfo(field.type);
    if (field_type_info == .Optional) {
        const field_type_child_info: builtin.Type = @typeInfo(field_type_info.Optional.child);
        if (field_type_child_info == .Enum) {
            inline for (field_type_child_info.Enum.fields) |field_field| {
                const field_name: []const u8 = field_field.name ++ "_" ++ field.name;
                field_names = field_names ++ [1][]const u8{field_name};
            }
            return .{
                .kind = .mutually_exclusive_optional,
                .info = .{ .field_name = field.name, .field_field_names = field_names },
            };
        }
    } else if (field_type_info == .Enum) {
        inline for (field_type_info.Enum.fields) |field_field| {
            const field_name: []const u8 = field_field.name ++ "_" ++ field.name;
            field_names = field_names ++ [1][]const u8{field_name};
        }
        return .{
            .kind = .mutually_exclusive_mandatory,
            .info = .{ .field_name = field.name, .field_field_names = field_names },
        };
    }
}
fn writeOptions(array: *gen.String) void {
    array.writeMany("pub const options = [_]gen.Option{\n");
    inline for (@typeInfo(gen.Techniques.Options).Struct.fields) |field| {
        const option: gen.Option = fieldOption(field);
        array.writeMany("    .{ .kind = .");
        array.writeMany(@tagName(option.kind));
        array.writeMany(", .info = .{ .field_name = \"");
        array.writeMany(option.info.field_name);
        array.writeMany("\", .field_field_names = &[_][]const u8{ ");
        for (option.info.field_field_names) |field_field_name| {
            array.writeMany("\"");
            array.writeMany(field_field_name);
            array.writeMany("\", ");
        }
        array.undefine(2);
        array.writeMany(" } } },\n");
    }
    array.writeMany("};\n");
}
pub fn specToOptions(array: *gen.String) void {
    gen.writeImports(array, @src(), &.{.{ .name = "gen", .path = "../../gen.zig" }});
    writeOptions(array);
    gen.writeAuxiliarySourceFile(array, "options.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var array: gen.String = undefined;
    array.undefineAll();
    specToOptions(&array);
    sys.exit(0);
}
