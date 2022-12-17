const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const render = @import("./render.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

const PrintArray = mem.StaticString(1024 * 1024);
const is_correct: bool = true;

fn hasDecls(comptime T: type) bool {
    const type_info: builtin.Type = @typeInfo(T);
    return type_info == .Struct or type_info == .Opaque or
        type_info == .Union or type_info == .Enum;
}

// This could be used to test the value renderer in bulk, but currently crashing
// compiler.
fn printDeclsRecursively(comptime T: type, array: *mem.StaticString(1024 * 1024)) void {
    if (comptime !hasDecls(T)) {
        if (@typeInfo(T) != .Fn) {
            array.writeFormat(render.AnyFormat(T){ .value = T });
        }
    }
    const type_info: builtin.Type = @typeInfo(T);
    inline for (@field(type_info, @tagName(type_info)).decls) |decl| {
        if (comptime !decl.is_pub) {
            continue;
        }
        const field_type: type = @TypeOf(@field(T, decl.name));
        const field: field_type = @field(T, decl.name);
        const field_type_info: builtin.Type = @typeInfo(field_type);
        const decl_kind: []const u8 = if (decl.is_pub) "pub const " else "const ";
        if (field_type_info == .Type) {
            array.writeMany(decl_kind ++ decl.name ++ " = " ++ @typeName(field_type));
            array.writeMany(" {\n");
            printDeclsRecursively(field, array);
            array.writeMany("};\n");
        } else {
            if (field_type_info != .Fn) {
                array.writeMany(decl_kind ++ decl.name ++ ": " ++ comptime fmt.typeName(field_type) ++ " = ");
                array.writeFormat(render.AnyFormat(field_type){ .value = @field(T, decl.name) });
                array.writeMany(";\n");
            }
        }
    }
}

fn testSpecificCases() !void {
    var array: PrintArray = .{};
    array.writeFormat(render.TypeFormat{ .value = packed struct(u128) { a: u64, b: u64 } });
    try testing.expectEqualMany(u8, array.readAll(), "packed struct(u128) { a: u64, b: u64, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = packed union { a: u64, b: u64 } });
    try testing.expectEqualMany(u8, array.readAll(), "packed union { a: u64, b: u64, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = enum { a, b } });
    try testing.expectEqualMany(u8, array.readAll(), "enum(u1) { a, b, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = u64 });
    try testing.expectEqualMany(u8, array.readAll(), "u64");
    array.undefineAll();
    array.writeFormat(render.IntFormat(u64){ .value = 111111111 });
    try testing.expectEqualMany(u8, array.readAll(), "111111111");
    array.undefineAll();
    array.writeFormat(render.ComptimeIntFormat{ .value = 111111111 });
    try testing.expectEqualMany(u8, array.readAll(), "111111111");
    array.undefineAll();
    array.writeFormat(render.IntFormat(i64){ .value = -111111111 });
    try testing.expectEqualMany(u8, array.readAll(), "-111111111");
    array.undefineAll();
    array.writeFormat(render.ComptimeIntFormat{ .value = -111111111 });
    try testing.expectEqualMany(u8, array.readAll(), "-111111111");
    array.undefineAll();
    array.writeFormat(render.PointerSliceFormat([]const u64){ .value = &.{ 1, 2, 3, 4, 5, 6 } });
    try testing.expectEqualMany(u8, array.readAll(), "[]const u64{ 1, 2, 3, 4, 5, 6 }");
    array.undefineAll();
    array.writeFormat(render.NullFormat{});
    try testing.expectEqualMany(u8, array.readAll(), "null");
    array.undefineAll();
}
pub fn main() !void {
    try meta.wrap(testSpecificCases());
}
