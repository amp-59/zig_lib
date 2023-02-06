const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const gen = srg.memgen;
const proc = srg.proc;
const mach = srg.mach;

pub usingnamespace proc.start;

fn remapStack() void {
    var start = mach.alignA64(asm volatile (""
        : [_] "={rbp}" (-> u64),
    ), 4096);
    while (true) {
        if (gen.map(start, 4096) != start) {
            start += 4096;
            continue;
        }
        gen.unmap(start, 4096);
        break;
    }
}
pub fn main() !void {
    remapStack();

    sys.exit(0);
}
