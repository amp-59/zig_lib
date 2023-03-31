const mem = @import("../mem.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types2.zig");

pub const OutputMode = enum {
    exe,
    lib,
    obj,
};
pub const RunCommand = struct {
    args: types.Args,
    pub fn addRunArgument(run_cmd: *RunCommand, allocator: *types.Allocator, any: anytype) void {
        run_cmd.args.appendAny(preset.reinterpret.fmt, allocator, any);
    }
};
