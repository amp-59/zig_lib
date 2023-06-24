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

const Output = enum(u8) {
    bin = 2,
    oct = 8,
    dec = 10,
    hex = 16,
    char = 17,
    auto = 18,
    u8 = 19,
    u16 = 20,
    u32 = 21,
    u64 = 22,
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
    output: Output = .hex,
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
const opt_map: []const Options.Map = &if (single_switch) .{
    .{ .field_name = "output", .short = "-o", .long = "--output", .assign = .{ .action = Options.setOutput } },
} else .{
    .{ .field_name = "output", .short = "-c", .long = "--char", .assign = .{ .any = &(.char) } },
    .{ .field_name = "output", .short = "-x", .long = "--hex", .assign = .{ .any = &(.hex) } },
    .{ .field_name = "output", .short = "-d", .long = "--dec", .assign = .{ .any = &(.dec) } },
    .{ .field_name = "output", .short = "-o", .long = "--oct", .assign = .{ .any = &(.oct) } },
    .{ .field_name = "output", .short = "-b", .long = "--bin", .assign = .{ .any = &(.bin) } },
    .{ .field_name = "output", .long = "--auto", .assign = .{ .any = &(.auto) } },
    .{ .field_name = "output", .long = "u8", .assign = .{ .any = &(.u8) } },
    .{ .field_name = "output", .long = "u16", .assign = .{ .any = &(.u16) } },
    .{ .field_name = "output", .long = "u32", .assign = .{ .any = &(.u32) } },
    .{ .field_name = "output", .long = "u64", .assign = .{ .any = &(.u64) } },
};
fn loopInner(options: Options, arg: []const u8) !void {
    const val: u64 = try builtin.parse.any(u64, arg);
    file.write(.{ .errors = .{} }, 1, switch (options.output) {
        .hex => builtin.fmt.ux64(val).readAll(),
        .dec => builtin.fmt.ud64(val).readAll(),
        .oct => builtin.fmt.uo64(val).readAll(),
        .bin => builtin.fmt.ub64(val).readAll(),
        .auto => blk: {
            if (val <= ~@as(u8, 0)) {
                break :blk @ptrCast(*const [1]u8, &@intCast(u8, val));
            } else if (val <= ~@as(u16, 0)) {
                break :blk @ptrCast(*const [2]u8, &@intCast(u16, val));
            } else if (val <= ~@as(u32, 0)) {
                break :blk @ptrCast(*const [4]u8, &@intCast(u32, val));
            } else {
                break :blk @ptrCast(*const [8]u8, &val);
            }
        },
        .u8 => @ptrCast(*const [1]u8, &@intCast(u8, val)),
        .u16 => @ptrCast(*const [2]u8, &@intCast(u16, val)),
        .u32 => @ptrCast(*const [4]u8, &@intCast(u32, val)),
        .u64 => @ptrCast(*const [8]u8, &val),
        .char => outputChar(),
    });
    if (@intFromEnum(options.output) < 18) {
        file.write(.{ .errors = .{} }, 1, "\n");
    }
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
