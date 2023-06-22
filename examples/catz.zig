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
    const addr: u64 = 0x40000000;
    for (args_in[1..]) |arg_in| {
        const arg: [:0]const u8 = meta.manyToSlice(arg_in);
        const fd: u64 = file.open(.{ .options = .{ .no_follow = false } }, arg) catch {
            continue;
        };
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = file.status(.{}, fd) catch {
            continue;
        };
        if (st.mode.kind == .regular) {
            const len: u64 = mach.alignA64(st.size, 4096);
            file.map(.{ .options = .{ .visibility = .private } }, fd, addr, len) catch {
                continue;
            };
            defer mem.unmap(.{ .errors = .{} }, addr, len);
            file.write(.{ .errors = .{} }, 1, mem.pointerMany(u8, addr)[0..st.size]);
        }
    }
}
