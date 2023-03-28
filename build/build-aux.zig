const std = @import("std");
const build = std.build;
const util = @import("./util.zig");

pub fn main(builder: *build.Builder) !void {
    util.Context.init(builder);
    try util.writeEnv(builder);
    _ = util.addProjectExecutable(builder, "generate_build", "top/build/generate_build.zig", .{ .build_mode = .ReleaseSmall });
}
