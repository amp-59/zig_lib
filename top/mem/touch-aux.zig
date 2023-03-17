const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticString(0);

pub fn main() void {
    gen.writeSourceFile("containers.zig", u8, &.{});
    gen.writeSourceFile("references.zig", u8, &.{});
    gen.writeAuxiliarySourceFile("container_kinds.zig", u8, &.{});
    gen.writeAuxiliarySourceFile("reference_kinds.zig", u8, &.{});
}
