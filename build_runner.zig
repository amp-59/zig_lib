const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const proc = srg.proc;
const meta = srg.meta;
const spec = srg.spec;
const build = srg.build;

pub usingnamespace root;
pub usingnamespace proc.start;

const Builder = if (@hasDecl(root, "Builder"))
    root.Builder
else
    build.GenericBuilder(spec.builder.default);

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};

    var allocator: Builder.Allocator = try meta.wrap(
        Builder.Allocator.init(&address_space, Builder.max_thread_count),
    );
    defer allocator.deinit(&address_space, Builder.max_thread_count);

    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    var builder: Builder = try meta.wrap(Builder.init(args, vars));

    try meta.wrap(
        root.buildMain(&allocator, &builder),
    );
    try meta.wrap(
        builder.processCommands(&address_space, &thread_space, &allocator),
    );
}
