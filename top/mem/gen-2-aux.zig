pub const is_verbose: bool = false;
pub const is_silent: bool = true;
const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-2.zig");
};
pub export fn _start() noreturn {
    @setAlignStack(16);
    gen.generateVariantData();
    gen.exit(0);
}
