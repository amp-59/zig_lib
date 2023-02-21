//! This stage summarises the abstract specification.
const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = @import("./abstract_spec.zig");
pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const Array = mem.StaticArray(u8, 1024 * 1024);
const fmt_spec: fmt.RenderSpec = .{ .omit_trailing_comma = true };

inline fn writeAbstractParametersInternal(array: *Array, comptime T: type, max_id: *u64) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            writeAbstractParametersInternal(array, field.type, max_id);
        }
    } else {
        const this_id: u64 = builtin.typeId(T);
        if (this_id > max_id.*) {
            max_id.* = this_id;
            array.writeMany("    ");
            array.writeFormat(comptime fmt.TypeFormat(fmt_spec){ .value = T });
            array.writeMany(",\n");
        }
    }
}
pub fn specToAbstract() void {
    var array: Array = undefined;
    array.undefineAll();
    var id: u64 = 0;
    gen.writeGenerator(&array, @src());
    gen.writeImport(&array, "gen", "../../gen.zig");
    array.writeMany("pub const abstract_params = [_]type{\n");
    writeAbstractParametersInternal(&array, out.AbstractSpec, &id);
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "abstract_params.zig");
}
pub const main = specToAbstract;
