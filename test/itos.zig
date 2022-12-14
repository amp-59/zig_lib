const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const mach = srg.mach;
const meta = srg.meta;
const file = srg.file;
const preset = srg.preset;
const builtin = srg.builtin;

const opts = @import("./opts.zig");

pub usingnamespace proc.start;

const Radix = enum(u5) {
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16,
};
fn noSuchOption(opt_arg: []const u8) void {
    var print_array: mem.StaticString(4096) = undefined;
    print_array.impl.ub_word = 0;
    print_array.writeAny(preset.reinterpret.ptr, [3][]const u8{ "unrecognised output mode: '", opt_arg, "'\n-o, --output=     x,d,o,b\n" });
    file.noexcept.write(2, print_array.readAll());
}
const Options = struct {
    output: Radix = .hex,
    input: ?[:0]const u8 = null,
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
        noSuchOption(opt_arg);
        sys.exit(2);
    }
}
fn loopInner(options: Options, arg: []const u8) !void {
    file.noexcept.write(1, switch (options.output) {
        .hex => builtin.fmt.ux64(try builtin.parse.any(u64, arg)).readAll(),
        .dec => builtin.fmt.ud64(try builtin.parse.any(u64, arg)).readAll(),
        .oct => builtin.fmt.uo64(try builtin.parse.any(u64, arg)).readAll(),
        .bin => builtin.fmt.ub64(try builtin.parse.any(u64, arg)).readAll(),
    });
    file.noexcept.write(1, "\n");
}
pub fn main(args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;
    const options: Options = opts.getOpts(Options, &args, &[_]opts.GenericOptions(Options){
        .{ .decl = .output, .short = "-o", .long = "--output", .assign = .{ .convert = validateOutputMode } },
    });
    var i: u64 = 1;
    while (i != args.len) {
        try loopInner(options, meta.manyToSlice(args[i]));
        i += 1;
    }
}
