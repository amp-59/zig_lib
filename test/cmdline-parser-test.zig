const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const build = zl.build;
const parser = @import("../top/build/parsers.zig");

pub fn main(args: anytype) void {
    var cmd: build.BuildCommand = .{};
    var allocator: mem.SimpleAllocator = .{};

    parser.buildParseArgs(cmd, &allocator, args);
}
