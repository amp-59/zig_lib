const zl = @import("zl");

pub usingnamespace zl.start;

fn executeCommandClone(
    address_space: *zl.builtin.root.Builder.AddressSpace,
    thread_space: *zl.builtin.root.Builder.ThreadSpace,
    node: *zl.builtin.root.Builder.Node,
    task: zl.build.Task,
    arena_index: zl.builtin.root.Builder.AddressSpace.Index,
    executeCommandThreaded: *const fn (
        *zl.builtin.root.Builder.AddressSpace,
        *zl.builtin.root.Builder.ThreadSpace,
        *zl.builtin.root.Builder.Node,
        zl.build.Task,
        zl.builtin.root.Builder.AddressSpace.Index,
    ) void,
    addr: usize,
    len: usize,
) void {
    zl.proc.clone(.{ .errors = .{}, .return_type = void }, .{}, addr, len, {}, executeCommandThreaded, .{
        address_space, thread_space, node, task, arena_index,
    });
}
export fn load(ptrs: *zl.builtin.root.Builder.FunctionPointers) void {
    ptrs.proc.executeCommandClone = &executeCommandClone;
}
