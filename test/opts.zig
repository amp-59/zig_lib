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
            generic: fn (*Options, comptime [:0]const u8, [:0]const u8) void,
        },
        descr: ?[]const u8 = null,
        clobber: bool = true,

        const Option = @This();
        fn getOptInternal(comptime flag: Option, options: *Options, args: *[][*:0]u8, index: u64, offset: u64) void {
            switch (flag.assign) {
                .boolean => |value| {
                    proc.shift(args, index);
                    @field(options, @tagName(flag.decl)) = value;
                },
                .argument => {
                    if (offset == 0) {
                        proc.shift(args, index);
                    }
                    @field(options, @tagName(flag.decl)) = meta.manyToSlice(args.*[index])[offset..];
                    proc.shift(args, index);
                },
                .convert => |convert| {
                    if (offset == 0) {
                        proc.shift(args, index);
                    }
                    convert(options, meta.manyToSlice(args.*[index])[offset..]);
                    proc.shift(args, index);
                },
                .generic => |generic| {
                    if (offset == 0) {
                        proc.shift(args, index);
                    }
                    generic(options, @tagName(flag.decl), meta.manyToSlice(args.*[index])[offset..]);
                    proc.shift(args, index);
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
    var index: u64 = 1;
    lo: while (index != args.len) {
        inline for (all_options) |option| {
            if (index == args.len) {
                break :lo;
            }
            const arg1: [:0]const u8 = meta.manyToSlice(args.*[index]);
            if (option.long) |long_switch| {
                if (mem.testEqualMany(u8, long_switch, arg1)) {
                    option.getOptInternal(&options, args, index, 0);
                    continue :lo;
                }
                const assign_long_switch: []const u8 = long_switch ++ "=";
                if (mem.testEqualManyFront(u8, assign_long_switch, arg1)) {
                    option.getOptInternal(&options, args, index, assign_long_switch.len);
                    continue :lo;
                }
            }
            if (option.short) |short_switch| {
                if (mem.testEqualMany(u8, short_switch, arg1)) {
                    option.getOptInternal(&options, args, index, 0);
                    continue :lo;
                }
                if (mem.testEqualManyFront(u8, short_switch, arg1)) {
                    option.getOptInternal(&options, args, index, short_switch.len);
                    continue :lo;
                }
            }
        }
        const arg1: [:0]const u8 = meta.manyToSlice(args.*[index]);
        if (mem.testEqualMany(u8, "--", arg1)) {
            proc.shift(args, index);
            break :lo;
        }
        if (mem.testEqualManyFront(u8, "--", arg1)) {
            debug.badLongSwitchHelp(Options, all_options, arg1);
        }
        index += 1;
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
        array.writeMany("'\n");
        inline for (all_options) |options| {
            if (options.long) |long_switch| {
                const mats: u64 = mem.orderedMatches(u8, bad_arg, long_switch);
                const opt_len: u64 = long_switch.len;
                if (math.absoluteDifference(mats, opt_len) < 3) {
                    array.writeMany(about_opt_0_s);
                    array.writeMany(long_switch);
                    array.writeMany("'\n");
                }
            }
        }
        array.writeMany("\nstop parsing options with '--'\n");
        file.noexcept.write(2, array.readAll());
        sys.exit(2);
    }
};
