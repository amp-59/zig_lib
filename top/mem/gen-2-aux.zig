pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");

const gen = @import("./gen-2.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.regular_128;

pub const main = gen.generateVariantData;
