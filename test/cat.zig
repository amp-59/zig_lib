const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const proc = srg.proc;
const file = srg.file;
const mach = srg.mach;
const meta = srg.meta;

pub usingnamespace proc.start;

pub fn main(args_in: [][*:0]u8) !void {
    if (args_in.len == 1) {
        return;
    }
    for (args_in) |arg_in| {
        const arg: [:0]const u8 = meta.manyToSlice(arg_in);
        const fd: u64 = try file.open(.{ .options = .{ .read = true } }, arg);
        defer file.close(.{ .errors = null }, fd);
        const lb_addr: u64 = 0x40000000;
        const up_addr: u64 = try file.map(.{ .options = .{ .visibility = .private } }, lb_addr, fd);
        const s_bytes: u64 = mach.alignA(up_addr - lb_addr, 4096);
        defer mem.unmap(.{ .errors = null }, lb_addr, s_bytes);
        file.noexcept.write(1, mem.pointerMany(u8, lb_addr, s_bytes));
    }
}
