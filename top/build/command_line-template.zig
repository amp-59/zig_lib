const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks3.zig");
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
