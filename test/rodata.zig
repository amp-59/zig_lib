//! Tests applications of global comptime pointers.
//! Experimental. This is a test file because if at some point it this
//! functionality is removed from the language these tests should fail.
const srg = @import("zig_lib");
const meta = srg.meta;
const file = srg.file;
const testing = srg.testing;

fn pointers(comptime T: type, comptime n: comptime_int) *[n]T {
    var ptrs: [n]T = undefined;
    return &ptrs;
}
fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = meta.empty;
    return &ptrs;
}
fn pointer(comptime T: type) *T {
    var val: T = 0;
    return &val;
}
const Test = struct {
    const concat_strings: *[]const []const u8 = slices([]const u8);
    const assign_strings: *[128][]const u8 = pointers([]const u8);
};
pub fn main() !void {
    comptime {
        Test.strings.* = Test.strings.* ++ [1][]const u8{"zeroth"};
        Test.strings.* = Test.strings.* ++ [1][]const u8{"first"};
    }
    comptime {
        Test.assign_strings[0] = "zeroth";
        Test.assign_strings[1] = "first";
    }
    testing.expectEqualMany(u8, Test.concat_strings, "zeroth");
    testing.expectEqualMany(u8, Test.concat_strings, "first");
    testing.expectEqualMany(u8, Test.assign_strings, "zeroth");
    testing.expectEqualMany(u8, Test.assign_strings, "first");
}
