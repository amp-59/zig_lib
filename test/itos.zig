const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const builtin = srg.builtin;

const opts = @import("./opts.zig");

pub usingnamespace proc.start;

const Radix = enum(u5) {
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16,
};
const Options = struct {
    output: Radix = .hex,
};
fn validateOutputMode(options: *Options, opt_arg: [:0]const u8) void {
    if (mem.testEqualMany(u8, "hex", opt_arg) or
        mem.testEqualMany(u8, "x", opt_arg))
    {
        options.output = .hex;
    } else if (mem.testEqualMany(u8, "bin", opt_arg) or
        mem.testEqualMany(u8, "b", opt_arg))
    {
        options.output = .bin;
    } else if (mem.testEqualMany(u8, "dec", opt_arg) or
        mem.testEqualMany(u8, "d", opt_arg))
    {
        options.output = .dec;
    } else if (mem.testEqualMany(u8, "oct", opt_arg) or
        mem.testEqualMany(u8, "o", opt_arg))
    {
        options.output = .oct;
    } else {
        file.noexcept.write(2, "unrecognised output mode: '");
        file.noexcept.write(2, opt_arg);
        file.noexcept.write(2, "'\n");
        file.noexcept.write(2,
            \\-o, --output=     x,d,o,b
            \\
        );
        sys.exit(2);
    }
}
pub fn main(args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;

    const options: Options = opts.getOpts(Options, &args, &[_]opts.GenericOptions(Options){
        .{ .decl = .output, .short = "-o", .long = "--output", .assign = .{ .convert = validateOutputMode } },
    });
    var i: u64 = 1;
    while (i != args.len) {
        file.noexcept.write(1, switch (options.output) {
            .hex => builtin.fmt.ux64(try builtin.parse.any(u64, meta.manyToSlice(args[i]))).readAll(),
            .dec => builtin.fmt.ud64(try builtin.parse.any(u64, meta.manyToSlice(args[i]))).readAll(),
            .oct => builtin.fmt.uo64(try builtin.parse.any(u64, meta.manyToSlice(args[i]))).readAll(),
            .bin => builtin.fmt.ub64(try builtin.parse.any(u64, meta.manyToSlice(args[i]))).readAll(),
        });
        file.noexcept.write(1, "\n");
        i += 1;
    }
}
