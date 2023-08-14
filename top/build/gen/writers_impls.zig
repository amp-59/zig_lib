const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const context = .Lib;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *common.Array = allocator.create(common.Array);
    const len: usize = try gen.readFile(.{ .return_type = usize }, config.writers_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.all) |attributes| {
        common.writeWriterFunctions(array, attributes);
    }
    try gen.truncateFile(.{ .return_type = void }, config.writers_path, array.readAll());
}
