const srg = @import("zig_lib");
const mem = srg.mem;
const fmt = srg.fmt;
const meta = srg.meta;
const file = srg.file;
const proc = srg.proc;
const algo = srg.algo;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const fbuf_start: u64 = 0x40000000;
const mbuf_start: u64 = 0x10000000000;

const map_spec: file.MapSpec = .{ .options = .{ .visibility = .shared, .read = true, .write = true } };
const close_spec: file.CloseSpec = .{ .errors = .{} };
const unmap_spec: mem.UnmapSpec = .{ .errors = .{} };
const open_spec: file.OpenSpec = .{ .options = .{ .read = true, .write = .append } };

fn sortBuf(buf: []u64) void {
    const S = struct {
        fn asc(x: u64, y: u64) bool {
            return x > y;
        }
    };
    if (!algo.isSorted(u64, S.asc, buf)) {
        algo.shellSort(u64, S.asc, algo.approx, buf);
        algo.shellSort(u64, S.asc, algo.approxDouble, buf);
        algo.shellSort(u64, S.asc, builtin.identity, buf);
        mem.copy(fbuf_start, mbuf_start, @sizeOf(u64) * buf.len, 8);
    }
}
fn showFile(buf: []u64) void {
    var array: mem.StaticString(1024 * 1024) = undefined;
    var line: u64 = 0;
    array.undefineAll();
    for (buf) |value| {
        if (array.avail() < 128) {
            builtin.debug.write(array.readAll());
            array.undefineAll();
        }
        const len: u64 = array.len();
        array.writeFormat(fmt.ux64(value));
        array.writeMany(", \t");
        line +%= array.len() -% len;
        if (line >= 104) {
            array.writeOne('\n');
            line = 0;
        }
    }
}
// TODO: Add an option or command to sort in place, as the previous behaviour

pub fn main(args: [][*:0]u8) !void {
    if (args.len != 3) {
        builtin.debug.logFault(
            \\sortfile (sort|show) <pathname>
            \\
        );
    }
    const command: [:0]const u8 = meta.manyToSlice(args[1]);
    const target: [:0]const u8 = meta.manyToSlice(args[2]);

    const fd: u64 = try file.open(open_spec, target);
    defer file.close(close_spec, fd);

    const fbuf_finish: u64 = try file.map(map_spec, fbuf_start, fd);
    const bytes: u64 = fbuf_finish - fbuf_start;
    defer mem.unmap(unmap_spec, fbuf_start, bytes);
    try mem.map(.{ .options = .{} }, mbuf_start, bytes);
    mem.copy(mbuf_start, fbuf_start, bytes, 8);

    if (mem.testEqualMany(u8, "sort", command)) {
        return sortBuf(mem.pointerSlice(u64, mbuf_start, bytes / 8));
    }
    if (mem.testEqualMany(u8, "show", command)) {
        return showFile(mem.pointerSlice(u64, fbuf_start, bytes / 8));
    }
}
