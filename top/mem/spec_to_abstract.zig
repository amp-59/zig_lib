//! This stage summarises the abstract specification.
const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const abstract_spec = @import("./abstract_spec.zig");

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = &.{};
    return &ptrs;
}
pub fn typeIndex(comptime types: []const type, comptime T: type) bool {
    for (types) |U| if (U == T) return false;
    return true;
}
fn writeAbstractParametersStruct(array: *Array, comptime T: type) void {
    array.writeMany("    ");
    array.writeFormat(comptime fmt.TypeFormat(.{ .omit_trailing_comma = true }){ .value = T });
    array.writeMany(",\n");
}
inline fn writeAbstractParametersInternal(
    array: *Array,
    comptime types: *[]const type,
    comptime T: type,
) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            writeAbstractParametersInternal(array, types, field.type);
        }
    } else {
        if (comptime typeIndex(types.*, T)) {
            writeAbstractParametersStruct(array, T);
            types.* = types.* ++ [1]type{T};
        }
    }
}
fn writeAbstractParameters(array: *Array, comptime types: *[]const type) void {
    array.writeMany("pub const abstract_params = [_]type{\n");
    writeAbstractParametersInternal(array, types, abstract_spec.AbstractSpec);
    array.writeMany("};\n");
}
pub fn specToAbstract() void {
    const types: *[]const type = comptime slices(type);
    var array: Array = .{};
    gen.writeGenerator(&array, @src());
    gen.writeImport(&array, "gen", "../../gen.zig");
    writeAbstractParameters(&array, types);
    gen.writeAuxiliarySourceFile(&array, "abstract_params.zig");
}
pub const main = specToAbstract;
