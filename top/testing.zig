//! Before the value renderer can be used this import is a place for all
//! miscellaneous testing functions which will not be used in the long term.
//! Still more infrastructure is needed.

const file = @import("./file.zig");
const builtin = @import("./builtin.zig");

fn arrayOfCharsLength(s: []const u8) u64 {
    var len: u64 = 0;
    len += 2;
    for (s) |i| {
        len += 3;
        if (i != s.len - 1) {
            len += 2;
        }
    }
    return len + 3;
}
fn arrayOfCharsWrite(buf: []u8, s: []const u8) u64 {
    var len: u64 = 0;
    for ("{ ") |c, i| buf[len + i] = c;
    len += 2;
    for (s) |c, i| {
        if (c == 0) {
            for ("0x0") |b, j| buf[len + j] = b;
            len += 3;
        } else {
            for ([_]u8{ '\'', c, '\'' }) |b, j| buf[len + j] = b;
            len += 3;
        }
        if (i != s.len - 1) {
            for (", ") |b, j| buf[len + j] = b;
            len += 2;
        }
    }
    for (" }\n") |c, i| buf[len + i] = c;
    return len + 3;
}
pub fn showSpecialCase(comptime T: type, arg1: []const T, arg2: []const T) void {
    const arg1_xray_len: u64 = arrayOfCharsLength(arg1);
    const arg2_xray_len: u64 = arrayOfCharsLength(arg2);
    if (arg1_xray_len + arg2_xray_len > 4096) {
        return;
    }
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    len += arrayOfCharsWrite(buf[len..], arg1);
    len += arrayOfCharsWrite(buf[len..], arg2);
    file.noexcept.write(2, buf[0..len]);
}

// Q: Why not put this in builtin, according to specification?
// A: Because without a low level value renderer it can only serve special
// cases. fault-error-test requires the former two variants render the error
// value. That is not yet possible.
pub fn expectEqualMany(comptime T: type, arg1: []const T, arg2: []const T) builtin.Exception!void {
    if (arg1.len != arg2.len) {
        if (T == u8) {
            showSpecialCase(T, arg1, arg2);
        }
        return error.UnexpectedValue;
    }
    var i: u64 = 0;
    while (i != arg1.len) : (i += 1) {
        if (arg1[i] != arg2[i]) {
            if (T == u8) {
                showSpecialCase(T, arg1, arg2);
            }
            return error.UnexpectedValue;
        }
    }
}
