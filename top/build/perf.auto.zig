const source = @import("perf.zig");
pub const Fds = extern struct {
    hw: [5]u64,
    sw: [3]u64,
};
perfEventsOpen: *const fn () Fds = @ptrFromInt(8),
perfEventsClose: *const fn (
    p_0: *Fds,
) void = @ptrFromInt(8),
fn load(ptrs: *@This()) callconv(.C) void {
    ptrs.perfEventsOpen = @ptrCast(&source.perfEventsOpen);
    ptrs.perfEventsClose = @ptrCast(&source.perfEventsClose);
}
comptime {
    if (@import("builtin").output_mode != .Exe) {
        @export(load, .{ .name = "load", .linkage = .Strong });
    }
}
