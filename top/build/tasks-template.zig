const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types2.zig");

pub const OutputMode = enum {
    exe,
    lib,
    obj,
};
pub const AuxOutputMode = enum {
    @"asm",
    llvm_ir,
    llvm_bc,
    h,
    docs,
    analysis,
    implib,
};
pub const RunCommand = struct {
    args: types.Args,
    pub fn addRunArgument(run_cmd: *RunCommand, allocator: *types.Allocator, any: anytype) void {
        run_cmd.args.appendAny(spec.reinterpret.fmt, allocator, any);
        run_cmd.args.appendOne(allocator, 0);
    }
};
