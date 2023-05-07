const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const mach = srg.mach;
const meta = srg.meta;
const file = srg.file;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const Radix = enum(u5) {
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16,
    char,
};

const single_switch: bool = false;

fn noOption(opt_arg: []const u8) void {
    var print_array: mem.StaticString(4096) = undefined;
    print_array.undefineAll();
    print_array.writeAny(spec.reinterpret.ptr, [3][]const u8{
        "unrecognised output mode: '",
        opt_arg,
        "'\n-o, --output=     x,d,o,b\n",
    });
    builtin.proc.exitFault(print_array.readAll());
}
const Options = struct {
    output: Radix = .hex,
    pub const Map = proc.GenericOptions(Options);
    fn setOutputHex(options: *Options) void {
        options.output = .hex;
    }
    fn setOutputDec(options: *Options) void {
        options.output = .dec;
    }
    fn setOutputOct(options: *Options) void {
        options.output = .oct;
    }
    fn setOutputBin(options: *Options) void {
        options.output = .bin;
    }
    fn setOutput(options: *Options, opt_arg: [:0]const u8) void {
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
            noOption(opt_arg);
        }
    }
};
fn outputChar() []const u8 {
    return "";
}
const opt_map: []const Options.Map = meta.slice(Options.Map, if (single_switch) .{
    .{ .field_name = "output", .short = "-o", .long = "--output", .assign = .{ .action = Options.setOutput } },
} else .{
    .{ .field_name = "output", .short = "-c", .long = "--char", .assign = .{ .any = &(.char) } },
    .{ .field_name = "output", .short = "-x", .long = "--hex", .assign = .{ .any = &(.hex) } },
    .{ .field_name = "output", .short = "-d", .long = "--dec", .assign = .{ .any = &(.dec) } },
    .{ .field_name = "output", .short = "-o", .long = "--oct", .assign = .{ .any = &(.oct) } },
    .{ .field_name = "output", .short = "-b", .long = "--bin", .assign = .{ .any = &(.bin) } },
});
fn loopInner(options: Options, arg: []const u8) !void {
    file.writeSlice(.{ .errors = .{} }, 1, switch (options.output) {
        .hex => builtin.fmt.ux64(try builtin.parse.any(u64, arg)).readAll(),
        .dec => builtin.fmt.ud64(try builtin.parse.any(u64, arg)).readAll(),
        .oct => builtin.fmt.uo64(try builtin.parse.any(u64, arg)).readAll(),
        .bin => builtin.fmt.ub64(try builtin.parse.any(u64, arg)).readAll(),
        .char => outputChar(),
    });
    file.writeSlice(.{ .errors = .{} }, 1, "\n");
}
pub fn main(args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;

    const options: Options = Options.Map.getOpts(&args, opt_map);

    var i: u64 = 1;
    while (i != args.len) {
        try loopInner(options, meta.manyToSlice(args[i]));
        i += 1;
    }
}
