const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub const discard_errors: bool = true;

// pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub fn main() !void {
    //try @import("./crypto/aead-test.zig").aeadTestMain();
    //try @import("./crypto/core-test.zig").coreTestMain();
    //try @import("./crypto/hash-test.zig").hashTestMain();
    //try @import("./crypto/pcurve-test.zig").pcurveTestMain();
    //try @import("./crypto/ecdsa-test.zig").ecdsaTestMain();
    //try @import("./crypto/auth-test.zig").authTestMain();
    //try @import("./crypto/utils-test.zig").utilsTestMain();
    //try @import("./crypto/kyber-test.zig").kyberTestMain();
    //try @import("./crypto/dh-test.zig").dhTestMain();
    //try @import("./crypto/tls-test.zig").main();
}
