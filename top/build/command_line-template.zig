const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks3.zig");
const reinterpret_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = spec.reinterpret.print;
    tmp.composite.map = &.{
        .{ .in = []const types.ModuleDependency, .out = types.ModuleDependencies },
        .{ .in = []const types.Path, .out = types.Files },
    };
    break :blk tmp;
};
fn FormatMap(comptime T: type) type {
    switch (T) {
        []const types.ModuleDependency => return types.ModuleDependencies,
        []const types.Path => return types.Files,
        []const types.Macro => return types.Macros,
        []const types.Module => return types.Modules,
        else => @compileError(@typeName(T)),
    }
}
fn formatMap(any: anytype) FormatMap(@TypeOf(any)) {
    return .{ .value = any };
}
