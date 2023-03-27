extern fn hello_what(s: [*:0]const u8) void;
pub fn main() void {
    hello_what("world!");
}
