const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
pub fn _start() void {}
comptime {
    _ = @import("../mach.zig");
}
const render_spec: fmt.RenderSpec = .{ .infer_type_names = true, .forward = true };
export fn formatWriteBufBuilderSpecOptions(builder_spec: *const build.BuilderSpec.Options, buf: [*]u8) usize {
    return fmt.render(render_spec, builder_spec.*).formatWriteBuf(buf);
}
