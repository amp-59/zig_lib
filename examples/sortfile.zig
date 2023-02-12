const srg = @import("zig_lib");
const mem = srg.mem;
const fmt = srg.fmt;
const meta = srg.meta;
const file = srg.file;
const proc = srg.proc;
const algo = srg.algo;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const start: u64 = 0x40000000;

const map_spec: file.MapSpec = .{
    .options = .{ .visibility = .shared, .read = true, .write = true },
};
const close_spec: file.CloseSpec = .{
    .errors = null,
};
const unmap_spec: mem.UnmapSpec = .{
    .errors = null,
};
const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = .append },
};

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

    const finish: u64 = try file.map(map_spec, start, fd);
    defer mem.unmap(unmap_spec, start, finish - start);

    const buf: []u64 = mem.pointerMany(u64, start, (finish - start) / 8);

    if (mem.testEqualMany(u8, "sort", command)) {
        return algo.layeredShellSortAsc(u64, buf);
    }
    if (mem.testEqualMany(u8, "show", command)) {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        for (buf) |value| {
            if (array.avail() < 128) {
                builtin.debug.write(array.readAll());
                array.undefineAll();
            }
            array.writeFormat(fmt.ux64(value));
            array.writeOne('\n');
        }
    }
}
