const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");

pub const Array = mem.StaticString(1024 * 1024);
pub const TypeDescr = fmt.GenericTypeDescrFormat(.{
    .options = .{
        //.default_field_values = true,
        .identifier_name = true,
    },
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
