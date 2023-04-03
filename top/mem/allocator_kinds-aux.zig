const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const algo = gen.algo;
const spec = gen.spec;
const builtin = gen.builtin;
const attr = @import("./attr.zig");
const alloc_fn = @import("./alloc_fn.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

const Array = mem.StaticString(1024 * 1024);
pub fn main() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "alloc_fn", "../../alloc_fn.zig");
    const writeKind = attr.Fn.static.writeKindSwitch;

    const Pair = attr.Fn.static.Pair(alloc_fn.Fn);
    const allocate: Pair = attr.Fn.static.prefixSubTagNew(alloc_fn.Fn, .allocate);
    const deallocate: Pair = attr.Fn.static.prefixSubTag(alloc_fn.Fn, allocate[0], .deallocate);
    const resize: Pair = attr.Fn.static.prefixSubTag(alloc_fn.Fn, deallocate[0], .resize);
    const reallocate: Pair = attr.Fn.static.prefixSubTag(alloc_fn.Fn, resize[0], .reallocate);

    writeKind(alloc_fn.Fn, &array, .allocate, allocate[1]);
    writeKind(alloc_fn.Fn, &array, .deallocate, deallocate[1]);
    writeKind(alloc_fn.Fn, &array, .reallocate, reallocate[1]);
    writeKind(alloc_fn.Fn, &array, .resize, resize[1]);

    gen.writeAuxiliarySourceFile(&array, "allocator_kinds.zig");
}
