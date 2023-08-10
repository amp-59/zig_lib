const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *common.Array = allocator.create(common.Array);
    const len: usize = try gen.readFile(.{ .return_type = usize }, config.parsers_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.all) |attributes| {
        common.writeParserFunction(array, attributes);
    }
    for (attr.all) |attributes| {
        common.writeParserFunctionHelp(array, attributes);
    }
    try gen.truncateFile(.{ .return_type = void }, config.parsers_path, array.readAll());
}
