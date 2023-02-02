const preset = @import("../preset.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

pub const AddressSpace = preset.address_space.exact_8;

const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-a.zig");
};
pub export fn _start() noreturn {
    @setAlignStack(16);
    gen.generateTechniqueOptions();
    gen.exit(0);
}
