const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const Radix = enum(u5) {
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16,
};
const Options = struct {
    output: Radix,
};
fn getOutputWith(opt_arg: []const u8) Radix {
    if (mem.testEqualMany(u8, "hex", opt_arg) or
        mem.testEqualMany(u8, "x", opt_arg))
    {
        return .hex;
    } else if (mem.testEqualMany(u8, "bin", opt_arg) or
        mem.testEqualMany(u8, "b", opt_arg))
    {
        return .bin;
    } else if (mem.testEqualMany(u8, "dec", opt_arg) or
        mem.testEqualMany(u8, "d", opt_arg))
    {
        return .dec;
    } else if (mem.testEqualMany(u8, "oct", opt_arg) or
        mem.testEqualMany(u8, "o", opt_arg))
    {
        return .oct;
    }
    file.noexcept.write(2, "unrecognised output mode: '");
    file.noexcept.write(2, opt_arg);
    file.noexcept.write(2, "'\n");
    file.noexcept.write(2,
        \\-o, --output=     x,d,o,b
        \\
    );
    sys.exit(1);
}
inline fn getOpts(args: *[][*:0]u8) Options {
    var opts: Options = .{ .output = .hex };
    var i: u64 = 1;
    while (i != args.len) {
        if (mem.readAfterFirstEqualMany(u8, "--output=", meta.manyToSlice(args.*[i]))) |assigned| {
            opts.output = getOutputWith(assigned);
            proc.shift(args, i);
            continue;
        }
        if (mem.readAfterFirstEqualMany(u8, "-o", meta.manyToSlice(args.*[i]))) |squished| {
            opts.output = getOutputWith(squished);
            proc.shift(args, i);
            continue;
        }
        if (mem.testEqualMany(u8, "-o", meta.manyToSlice(args.*[i]))) {
            proc.shift(args, i);
            opts.output = getOutputWith(meta.manyToSlice(args.*[i]));
            proc.shift(args, i);
            continue;
        }
        if (mem.testEqualMany(u8, "-h", meta.manyToSlice(args.*[i])) or
            mem.testEqualMany(u8, "--help", meta.manyToSlice(args.*[i])))
        {
            file.noexcept.write(2,
                \\-o, --output=     x,d,o,b
                \\
            );
            sys.exit(0);
        }
        if (mem.testEqualMany(u8, "--", meta.manyToSlice(args.*[i]))) {
            break;
        }
        i += 1;
    }
    return opts;
}
pub fn main(args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;
    const options: Options = getOpts(&args);
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
