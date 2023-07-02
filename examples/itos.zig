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
pub const logging_override: builtin.Logging.Override = .{
    .Error = true,
};
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
};
fn outputChar() []const u8 {
    return "'char' output not yet implemented";
}
const opt_map: []const Options.Map = &.{
    .{ .field_name = "output", .short = "-c", .long = "--char", .assign = .{ .any = &(.char) }, .descr = "Not yet implemented" },
    .{ .field_name = "output", .short = "-x", .long = "--hex", .assign = .{ .any = &(.hex) }, .descr = "Output as hexadecimal" },
    .{ .field_name = "output", .short = "-d", .long = "--dec", .assign = .{ .any = &(.dec) }, .descr = "Output as decimal" },
    .{ .field_name = "output", .short = "-o", .long = "--oct", .assign = .{ .any = &(.oct) }, .descr = "Output as octal" },
    .{ .field_name = "output", .short = "-b", .long = "--bin", .assign = .{ .any = &(.bin) }, .descr = "Output as binary" },
    .{ .field_name = "output", .long = "auto", .assign = .{ .any = &(.auto) }, .descr = "Smallest width for value" },
    .{ .field_name = "output", .long = "u8", .assign = .{ .any = &(.u8) }, .descr = "Output raw 8 bit integer" },
    .{ .field_name = "output", .long = "u16", .assign = .{ .any = &(.u16) }, .descr = "Output raw 16 bit integer" },
    .{ .field_name = "output", .long = "u32", .assign = .{ .any = &(.u32) }, .descr = "Output raw 32 bit integer" },
    .{ .field_name = "output", .long = "u64", .assign = .{ .any = &(.u64) }, .descr = "Output raw 64 bit integer" },
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
                break :blk @as(*const [1]u8, @ptrCast(&@as(u8, @intCast(val))));
            } else if (val <= ~@as(u16, 0)) {
                break :blk @as(*const [2]u8, @ptrCast(&@as(u16, @intCast(val))));
            } else if (val <= ~@as(u32, 0)) {
                break :blk @as(*const [4]u8, @ptrCast(&@as(u32, @intCast(val))));
            } else {
                break :blk @as(*const [8]u8, @ptrCast(&val));
            }
        },
        .u8 => @as(*const [1]u8, @ptrCast(&@as(u8, @intCast(val)))),
        .u16 => @as(*const [2]u8, @ptrCast(&@as(u16, @intCast(val)))),
        .u32 => @as(*const [4]u8, @ptrCast(&@as(u32, @intCast(val)))),
        .u64 => @as(*const [8]u8, @ptrCast(&val)),
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
