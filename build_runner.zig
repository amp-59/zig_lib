const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
pub usingnamespace root;
pub usingnamespace srg.proc.start;

const Builder = if (@hasDecl(root, "Builder")) root.Builder else srg.build.GenericBuilder(srg.spec.builder.default);

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    defer allocator.deinit(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const build_fn = root.buildMain;
    var builder: Builder = try srg.meta.wrap(Builder.init(args, vars));
    try build_fn(&allocator, &builder);
    builder.processCommands(&address_space, &thread_space, &allocator);
}
