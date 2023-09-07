const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const proc = zl.proc;
const file = zl.file;
const mach = zl.mach;
const meta = zl.meta;

pub usingnamespace zl.start;

pub fn main(args_in: [][*:0]u8) !void {
    if (args_in.len == 1) {
        return;
    }
    const addr: u64 = 0x40000000;
    for (args_in[1..]) |arg_in| {
        const arg: [:0]const u8 = meta.manyToSlice(arg_in);
        const fd: usize = file.open(.{ .options = .{ .no_follow = false } }, arg) catch {
            continue;
        };
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = file.status(.{}, fd) catch {
            continue;
        };
        if (st.mode.kind == .regular) {
            const len: u64 = mach.alignA64(st.size, 4096);
            file.map(.{}, .{}, .{ .visibility = .private }, fd, addr, len, 0) catch {
                continue;
            };
            defer mem.unmap(.{ .errors = .{} }, addr, len);
            file.write(.{ .errors = .{} }, 1, mem.pointerMany(u8, addr)[0..st.size]);
        }
    }
}
