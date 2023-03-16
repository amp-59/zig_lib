const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const Array = mem.StaticString(0);
pub fn main() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeSourceFile(&array, "containers.zig");
    gen.writeSourceFile(&array, "references.zig");
    gen.writeAuxiliarySourceFile(&array, "container_kinds.zig");
    gen.writeAuxiliarySourceFile(&array, "reference_kinds.zig");
}
