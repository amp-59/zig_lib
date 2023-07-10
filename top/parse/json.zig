const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const parse = @import("../parse/float.zig");
const builtin = @import("../builtin.zig");
pub const Value = union(enum) {
    null,
    bool: bool,
    integer: i64,
    float: f64,
    number_string: []const u8,
    string: []const u8,
    array: ValueArray,
    object: ObjectMap,
};
pub const String = mem.GenericSimpleArray(u8);
pub const ValueArray = mem.GenericSimpleArray(Value);
pub const ObjectMap = mem.GenericSimpleMap([]const u8, Value);
pub const Allocator = mem.SimpleAllocator;
