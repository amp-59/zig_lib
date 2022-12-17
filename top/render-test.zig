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
pub const is_correct: bool = true;

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

fn runTest(array: *PrintArray, format: anytype, expected: []const u8) !void {
    array.writeFormat(format);
    try testing.expectEqualMany(u8, array.readAll(), expected);
    array.undefineAll();
}

fn testSpecificCases() !void {
    var array: PrintArray = .{};
    try runTest(&array, render.TypeFormat{ .value = packed struct(u128) { a: u64, b: u64 } }, "packed struct(u128) { a: u64, b: u64, }");
    try runTest(&array, render.TypeFormat{ .value = packed union { a: u64, b: u64 } }, "packed union { a: u64, b: u64, }");
    try runTest(&array, render.TypeFormat{ .value = enum { a, b } }, "enum(u1) { a, b, }");
    try runTest(&array, render.TypeFormat{ .value = u64 }, "u64");
    try runTest(&array, render.ComptimeIntFormat{ .value = 111111111 }, "111111111");
    try runTest(&array, render.ComptimeIntFormat{ .value = -111111111 }, "-111111111");
    try runTest(&array, render.PointerSliceFormat([]const u64){ .value = &.{ 1, 2, 3, 4, 5, 6 } }, "[]const u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&array, render.PointerSliceFormat([]const u64){ .value = &.{} }, "[]const u64{}");
    try runTest(&array, render.ArrayFormat([6]u64){ .value = .{ 1, 2, 3, 4, 5, 6 } }, "[6]u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&array, render.ArrayFormat([0]u64){ .value = .{} }, "[0]u64{}");
    try runTest(
        &array,
        render.PointerManyFormat([*:0]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr },
        "[:0]const u64{ 1, 2, 3, 4, 5, 6 }",
    );
    try runTest(
        &array,
        render.PointerManyFormat([*]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr },
        "[*]const u64{ ... }",
    );
    try runTest(&array, render.EnumLiteralFormat{ .value = .EnumLiteral }, ".EnumLiteral");
    try runTest(&array, render.NullFormat{}, "null");
    try runTest(&array, render.VoidFormat{}, "{}");
}
pub fn main() !void {
    try meta.wrap(testSpecificCases());
}
