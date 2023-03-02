const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");

    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
};

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};

const Array = mem.StaticArray(u8, 1024 * 1024);

fn variantsToCanonical() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "out", "./canonical.zig");
    array.writeMany("pub const canonicals: []const out.Canonical = &[_]out.Canonical{\n");
    for (out.impl_variants) |variant| {
        array.writeMany("    ");
        gen.writeStructOfEnum(&array, out.Canonical, out.Canonical.convert(variant));
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "canonicals.zig");
}
pub const main = variantsToCanonical;
