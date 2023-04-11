const mach = @import("../mach.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");

const build = @import("./../build2.zig");
const types = @import("./types.zig");

const Builder = build.GenericBuilder(.{
    .errors = spec.builder.errors.noexcept,
    .logging = spec.builder.logging.silent,
});
export fn forwardToExecuteCloneThreaded(
    builder: *Builder,
    address_space: *Builder.AddressSpace,
    thread_space: *Builder.ThreadSpace,
    target: *Builder.Target,
    task: build.Task,
    arena_index: Builder.AddressSpace.Index,
    depth: u64,
    stack_address: u64,
) void {
    _ = proc.callClone(.{ .errors = .{} }, stack_address, Builder.stack_aligned_bytes, {}, Builder.executeCommandThreaded, .{
        builder, address_space, thread_space, target, task, arena_index, depth,
    });
}

const debug = struct {
    const about_target_0_s: [:0]const u8 = builtin.debug.about("target");
    const about_target_1_s: [:0]const u8 = builtin.debug.about("target-error");
};
