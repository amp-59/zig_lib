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
    for (args_in[1..]) |arg_in| {
        const arg: [:0]const u8 = meta.manyToSlice(arg_in);
        const fd: u64 = file.open(.{ .options = .{ .read = true, .no_follow = false } }, arg) catch {
            continue;
        };
        defer file.close(.{ .errors = .{} }, fd);
        const lb_addr: u64 = 0x40000000;
        const up_addr: u64 = file.map(.{ .options = .{ .visibility = .private } }, lb_addr, fd) catch {
            continue;
        };
        const s_bytes: u64 = mach.alignA(up_addr - lb_addr, 4096);
        defer mem.unmap(.{ .errors = .{} }, lb_addr, s_bytes);
        file.noexcept.write(1, mem.pointerMany(u8, lb_addr, s_bytes));
    }
}
