const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const debug = @import("../../debug.zig");
const attr = @import("attr.zig");
const types = @import("types.zig");
const config = @import("config.zig");
const common = @import("common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const context = .Lib;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    const array: *types.Array = allocator.create(types.Array);
    const extra: *types.Extra = allocator.create(types.Extra);
    extra.* = .{ .language = .C };
    const len: usize = try gen.readFile(.{ .return_type = usize }, config.parsers_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.all) |attributes| {
        common.writeParserFunction(array, attributes, extra);
    }
    for (attr.all) |attributes| {
        common.writeParserFunctionHelp(array, attributes);
    }
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.parsers_path, array.readAll());
    } else {
        debug.write(array.readAll());
    }
}
