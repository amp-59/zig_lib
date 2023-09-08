const zl = @import("zl");
const proc = zl.proc;
const build = zl.build;
const start = zl.start;
const Builder = @import("root").Builder;
pub usingnamespace start;
pub const comptime_errors: bool = false;

executeCommandClone: *const fn (
    *Builder.AddressSpace,
    *Builder.ThreadSpace,
    *build.Node,
    build.Task,
    Builder.AddressSpace.Index,
    executeCommandThreaded: *const fn (
        *Builder.AddressSpace,
        *Builder.ThreadSpace,
        *build.Node,
        build.Task,
        Builder.AddressSpace.Index,
    ) void,
    addr: usize,
    len: usize,
) void = @ptrFromInt(8),

fn executeCommandClone(
    address_space: *Builder.AddressSpace,
    thread_space: *Builder.ThreadSpace,
    node: *build.Node,
    task: build.Task,
    arena_index: Builder.AddressSpace.Index,
    executeCommandThreaded: *const fn (
        *Builder.AddressSpace,
        *Builder.ThreadSpace,
        *build.Node,
        build.Task,
        Builder.AddressSpace.Index,
    ) void,
    addr: usize,
    len: usize,
) void {
    proc.clone(.{ .errors = .{}, .return_type = void }, addr, len, {}, executeCommandThreaded, .{
        address_space, thread_space, node, task, arena_index,
    });
}
fn load(ptrs: *@This()) callconv(.C) void {
    ptrs.executeCommandClone = &executeCommandClone;
}
comptime {
    if (@import("builtin").output_mode != .Exe) {
        @export(load, .{ .name = "load", .linkage = .Strong });
    }
}
