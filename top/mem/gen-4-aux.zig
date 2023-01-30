pub const is_verbose: bool = false;
pub const is_silent: bool = true;
const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-4.zig");
};
pub export fn _start() noreturn {
    @setAlignStack(16);
    gen.generateContainerFunctions();
    gen.exit(0);
}
