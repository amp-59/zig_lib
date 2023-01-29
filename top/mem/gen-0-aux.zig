pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const proc = @import("./../proc.zig");

const gen = @import("./gen-0.zig");

pub usingnamespace proc.start;

pub fn main() void {
    gen.generateImplementationSummary();
}
