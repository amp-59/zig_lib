const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const types = @import("./types.zig");
const reinterpret_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = spec.reinterpret.print;
    tmp.composite.map = &.{
        .{
            .in = []const types.ModuleDependency,
            .out = types.ModuleDependencies,
        },
        .{
            .in = []const types.Path,
            .out = types.Files,
        },
    };
    break :blk tmp;
};
