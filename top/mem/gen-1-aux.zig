pub const is_verbose: bool = false;
pub const is_silent: bool = true;
const gen = struct {
    usingnamespace @import("./gen.zig");
    usingnamespace @import("./gen-1.zig");
};
pub export fn _start() noreturn {
    @setAlignStack(16);
    gen.generateSpecificationTypes();
    gen.exit(0);
}
