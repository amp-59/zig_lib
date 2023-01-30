pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const proc = @import("./../proc.zig");

const gen = @import("./gen-4.zig");

pub usingnamespace proc.start;

pub const main = gen.generateContainerFunctions;
