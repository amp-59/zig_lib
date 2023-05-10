const mem = @import("../mem.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const algo = @import("../algo.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");

const attr = @import("./attr.zig");
const config = @import("./config.zig");
const alloc_fn = @import("./alloc_fn.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

const Array = mem.StaticString(1024 * 1024);
pub fn main() void {
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("const alloc_fn = @import(\"../../alloc_fn.zig\");\n");

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

    const fd: u64 = file.create(spec.create.truncate_noexcept, config.allocator_kinds_path, file.file_mode);
    file.write(spec.generic.noexcept, fd, array.readAll());
    file.close(spec.generic.noexcept, fd);
}
