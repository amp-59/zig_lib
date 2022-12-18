const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const fmt = srg.fmt;
const proc = srg.proc;
const math = srg.math;
const file = srg.file;
const meta = srg.meta;
const builtin = srg.builtin;

pub fn GenericOptions(comptime Options: type) type {
    return struct {
        decl: builtin.DeclLiteral,
        short: ?[]const u8 = null,
        // short_prefix: []const u8 = "-",
        // short_anti_prefix: []const u8 = "+",
        long: ?[]const u8 = null,
        // long_prefix: []const u8 = "--",
        // long_anti_prefix: []const u8 = "--no-",
        assign: union(enum) {
            boolean: bool,
            argument,
            convert: fn (*Options, [:0]const u8) void,
        },
        descr: ?[]const u8 = null,

        const Option = @This();
        fn getOptInternal(comptime flag: Option, options: *Options, args: *[][*:0]u8, idx: u64, off: u64) void {
            switch (flag.assign) {
                .boolean => |value| {
                    proc.shift(args, idx);
                    @field(options, @tagName(flag.decl)) = value;
                },
                .argument => {
                    if (off == 0) {
                        proc.shift(args, idx);
                    }
                    @field(options, @tagName(flag.decl)) = meta.manyToSlice(args.*[idx])[off..];
                    proc.shift(args, idx);
                },
                .convert => |convert| {
                    if (off == 0) {
                        proc.shift(args, idx);
                    }
                    convert(options, meta.manyToSlice(args.*[idx])[off..]);
                    proc.shift(args, idx);
                },
            }
        }
    };
}
pub fn getOpts(comptime Options: type, args: *[][*:0]u8, all_options: []const GenericOptions(Options)) Options {
    var options: Options = .{};
    if (args.len == 0) {
        return options;
    }
    var idx: u64 = 1;
    lo: while (idx != args.len) {
        inline for (all_options) |option| {
            if (idx == args.len) {
                break :lo;
            }
            const arg1: [:0]const u8 = meta.manyToSlice(args.*[idx]);
            if (option.long) |long_switch| {
                if (mem.testEqualMany(u8, long_switch, arg1)) {
                    option.getOptInternal(&options, args, idx, 0);
                    continue :lo;
                }
                const assign_long_switch: []const u8 = long_switch ++ "=";
                if (mem.testEqualManyFront(u8, assign_long_switch, arg1)) {
                    option.getOptInternal(&options, args, idx, assign_long_switch.len);
                    continue :lo;
                }
            }
            if (option.short) |short_switch| {
                if (mem.testEqualMany(u8, short_switch, arg1)) {
                    option.getOptInternal(&options, args, idx, 0);
                    continue :lo;
                }
                if (mem.testEqualManyFront(u8, short_switch, arg1)) {
                    option.getOptInternal(&options, args, idx, short_switch.len);
                    continue :lo;
                }
            }
        }
        const arg1: [:0]const u8 = meta.manyToSlice(args.*[idx]);
        if (mem.testEqualMany(u8, "--", arg1)) {
            proc.shift(args, idx);
            break :lo;
        }
        if (mem.testEqualManyFront(u8, "--", arg1)) {
            debug.badLongSwitchHelp(Options, all_options, arg1);
        }
        idx += 1;
    }
    return options;
}

const debug = opaque {
    const about_opt_0_s: []const u8 = "opt:            '";
    const about_opt_1_s: []const u8 = "opt-error:      '";

    fn badLongSwitchHelp(comptime Options: type, comptime all_options: []const GenericOptions(Options), arg: [:0]const u8) void {
        var array: mem.StaticString(4096) = .{};
        const bad_arg: []const u8 = mem.readBeforeFirstEqualManyOrElse(u8, "=", arg);
        array.writeMany(about_opt_1_s);
        array.writeMany(bad_arg);
        array.writeMany("\n");
        inline for (all_options) |options| {
            if (options.long) |long_switch| {
                const mats: u64 = mem.orderedMatches(u8, bad_arg, long_switch);
                const opt_len: u64 = long_switch.len;
                if (math.absoluteDifference(mats, opt_len) < 3) {
                    array.writeMany(about_opt_0_s);
                    array.writeMany(long_switch);
                    array.writeMany("\n");
                }
            }
        }
        array.writeMany("\nstop parsing options with '--'\n");
        file.noexcept.write(2, array.readAll());
        sys.exit(2);
    }
};
