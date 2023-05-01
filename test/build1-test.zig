const zig_lib = @import("../zig_lib.zig");

const proc = zig_lib.proc;
const spec = zig_lib.spec;
const build = zig_lib.build;

pub usingnamespace proc.start;

const Builder = build.GenericBuilder(spec.builder.default);

pub fn main() void {}
