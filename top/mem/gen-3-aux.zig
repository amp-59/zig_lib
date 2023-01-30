pub const is_verbose: bool = false;
pub const is_silent: bool = true;
const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-3.zig");
};
pub export fn _start() noreturn {
    @setAlignStack(16);
    gen.generateFnDefinitions();
    gen.exit(0);
}
