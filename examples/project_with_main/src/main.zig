const zl = @import("zig_lib");
const mem = zl.mem;
const proc = zl.proc;
const meta = zl.meta;
const spec = zl.spec;
const builtin = zl.builtin;

// Use zl startup code to speed compilation and reduce binary size.
pub usingnamespace zl.start;

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    // Use undefined to avoid pulling in memset for register-sized assignments
    var array: mem.StaticString(4096) = undefined;
    // `undefineAll` sets the length of the value defined by `array` to 0.
    array.undefineAll();

    // Here the basic utilities are used to print arguments to stderr.
    debug.write("args:\n");
    var idx: u64 = 1;
    while (idx != args.len) : (idx +%= 1) {
        debug.write(fmt.old.ud64(idx).readAll());
        debug.write(": ");
        debug.write(meta.manyToSlice(args[idx]));
        debug.write("\n");
    }
    idx = 0;
    array.writeMany("vars:\n");
    while (idx != vars.len) : (idx +%= 1) {
        // This specification configures `writeAny` to dereference pointers with
        // the same child type as the container, and by default converts
        // sentinel-terminated-slices-to-many to full slices.
        array.writeAny(zl.spec.reinterpret.ptr, .{ vars[idx], '\n' });
    }
    debug.write(array.readAll());
    array.undefineAll();
}
