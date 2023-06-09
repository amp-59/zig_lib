const mem = @import("../../mem.zig");
const spec = @import("../../spec.zig");
const file = @import("../../file.zig");
const proc = @import("../../proc.zig");
const builtin = @import("../../builtin.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const Array = mem.StaticString(0);
const mkdir_spec: file.MakeDirSpec = .{ .errors = .{} };
const create_spec: file.CreateSpec = .{ .errors = .{}, .options = .{ .exclusive = false, .truncate = true } };
const close_spec: file.CloseSpec = .{ .errors = .{} };
pub fn main() void {}
