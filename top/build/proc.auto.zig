const zl = @import("zl");

pub usingnamespace zl.start;

const clone_spec = .{
    .errors = .{},
    .return_type = void,
    .function_type = *const fn (
        *zl.builtin.root.Builder.AddressSpace,
        *zl.builtin.root.Builder.ThreadSpace,
        *zl.builtin.root.Builder.Node,
        zl.build.Task,
        zl.builtin.root.Builder.AddressSpace.Index,
    ) void,
};
fn executeCommandClone(
    address_space: *zl.builtin.root.Builder.AddressSpace,
    thread_space: *zl.builtin.root.Builder.ThreadSpace,
    node: *zl.builtin.root.Builder.Node,
    task: zl.build.Task,
    arena_index: zl.builtin.root.Builder.AddressSpace.Index,
    executeCommandThreaded: clone_spec.function_type,
    addr: usize,
    len: usize,
) void {
    var ret: void = {};
    zl.proc.clone(clone_spec, .{}, addr, len, &ret, executeCommandThreaded, .{
        address_space, thread_space, node, task, arena_index,
    });
}
export fn load(ptrs: *zl.builtin.root.Builder.FunctionPointers) void {
    ptrs.proc.executeCommandClone = &executeCommandClone;
}
