const mach = @import("../mach.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");

const build = @import("./../build.zig");
const types = @import("./types.zig");

const Node = build.GenericNode(.{
    .errors = spec.builder.errors.noexcept,
    .logging = builtin.zero(build.BuilderSpec.Logging),
});
export fn forwardToExecuteCloneThreadedDirty(
    address_space: *Node.AddressSpace,
    thread_space: *Node.ThreadSpace,
    builder: *Node,
    node: *Node,
    task: build.Task,
    arena_index: Node.AddressSpace.Index,
    stack_addr: u64,
    stack_len: u64,
) void {
    proc.callClone(.{ .errors = .{}, .return_type = void }, stack_addr, stack_len, {}, Node.impl.executeCommandThreaded, .{
        address_space, thread_space, builder, node, task, arena_index,
    });
}
