const mem = @import("../mem.zig");
const preset = @import("../preset.zig");
const tasks = @import("./tasks.zig");
const types = @import("./types2.zig");
const reinterpret_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.print;
    tmp.composite.map = &.{
        .{ .in = []const types.ModuleDependency, .out = types.ModuleDependencies },
    };
    break :blk tmp;
};
