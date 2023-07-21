const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const ChannelSpec = struct {
    errors: Errors,
    logging: Logging,
    pub const Errors = struct {
        pipe: sys.ErrorPolicy,
        dup3: sys.ErrorPolicy,
        close: sys.ErrorPolicy,
    };
    pub const Logging = struct {
        pipe: debug.Logging.AcquireError,
        dup3: debug.Logging.SuccessError,
        close: debug.Logging.ReleaseError,
    };
};
pub fn GenericChannel(comptime chan_spec: ChannelSpec) type {
    const Type = struct {
        in: file.Pipe,
        out: file.Pipe,
        err: file.Pipe,
        const Channel = @This();
        pub const decls = struct {
            pub const pipe_spec: file.MakePipeSpec = .{
                .options = .{ .close_on_exec = false },
                .errors = chan_spec.errors.pipe,
                .logging = chan_spec.logging.pipe,
            };
            pub const dup3_spec: file.DuplicateSpec = .{
                .errors = chan_spec.errors.dup3,
                .logging = chan_spec.logging.dup3,
            };
            pub const close_spec: file.CloseSpec = .{
                .errors = chan_spec.errors.close,
                .logging = chan_spec.logging.close,
            };
        };
        pub fn init() sys.ErrorUnion(chan_spec.errors.pipe, Channel) {
            return .{
                .in = try meta.wrap(file.makePipe(decls.pipe_spec)),
                .out = try meta.wrap(file.makePipe(decls.pipe_spec)),
                .err = try meta.wrap(file.makePipe(decls.pipe_spec)),
            };
        }
        pub fn init_read(chan: Channel) sys.ErrorUnion(.{
            .throw = chan_spec.errors.dup3.throw ++ chan_spec.errors.close.throw,
            .abort = chan_spec.errors.dup3.abort ++ chan_spec.errors.close.abort,
        }, void) {
            try meta.wrap(file.close(decls.close_spec, chan.in.write));
            try meta.wrap(file.close(decls.close_spec, chan.out.read));
            try meta.wrap(file.close(decls.close_spec, chan.err.read));
            try meta.wrap(file.duplicateTo(decls.dup3_spec, chan.in.read, 0));
            try meta.wrap(file.duplicateTo(decls.dup3_spec, chan.out.write, 1));
            try meta.wrap(file.duplicateTo(decls.dup3_spec, chan.out.write, 2));
        }
        pub fn init_write(chan: *Channel) sys.ErrorUnion(chan_spec.errors.close, void) {
            try meta.wrap(file.close(decls.close_spec, chan.in.read));
            try meta.wrap(file.close(decls.close_spec, chan.out.write));
            try meta.wrap(file.close(decls.close_spec, chan.err.write));
        }
    };
    return Type;
}
