//! This stage summarises the abstract specification.
const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const abstract_spec = @import("./abstract_spec.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = &.{};
    return &ptrs;
}
pub fn isUniqueType(comptime types: []const type, comptime T: type) bool {
    for (types) |U| if (U == T) return false;
    return true;
}
inline fn writeAbstractParametersInternal(array: *Array, comptime types: *[]const type, comptime T: type) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            writeAbstractParametersInternal(array, types, field.type);
        }
    } else {
        if (comptime isUniqueType(types.*, T)) {
            array.writeFormat(comptime fmt.GenericTypeDescrFormat(.{ .options = .{ .depth = 1 } }).init(T));
            array.writeMany(",\n");
            types.* = types.* ++ [1]type{T};
        }
    }
}
pub fn abstractParams() void {
    const types: *[]const type = comptime slices(type);
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "gen", "../../gen.zig");
    array.writeMany("pub const abstract_params = [_]type{\n");
    writeAbstractParametersInternal(&array, types, abstract_spec.AbstractSpec);
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "abstract_params.zig");
}
pub const main = abstractParams;
