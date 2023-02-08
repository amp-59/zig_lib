//! This stage summarises the abstract specification.
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const gen = @import("./gen.zig");

const out = @import("./detail.zig");

fn ptr(comptime T: type) *T {
    var ret: T = undefined;
    return &ret;
}
const type_id: *comptime_int = ptr(comptime_int);
comptime {
    type_id.* = 0;
}
fn typeId(comptime _: type) comptime_int {
    const ret: comptime_int = type_id.*;
    type_id.* += 1;
    return ret;
}
fn writeUnspecifiedDetailsInternal(array: *gen.String, comptime T: type, detail: *out.Detail) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            const tmp = detail.*;
            defer detail.* = tmp;
            if (@hasField(gen.Kinds, field.name)) {
                @field(detail.kinds, field.name) = true;
            }
            if (@hasField(gen.Layouts, field.name)) {
                @field(detail.layouts, field.name) = true;
            }
            if (@hasField(gen.Modes, field.name)) {
                @field(detail.modes, field.name) = true;
            }
            if (@hasField(gen.Fields, field.name)) {
                @field(detail.fields, field.name) = true;
            }
            if (@hasField(gen.Techniques, field.name)) {
                @field(detail.techs, field.name) = true;
            }
            writeUnspecifiedDetailsInternal(array, field.type, detail);
        }
    } else if (type_info == .Struct) {
        detail.index = typeId(T);
        writeDetailStruct(array, detail.*);
    }
}
fn writeDetailStruct(array: *gen.String, detail: out.Detail) void {
    array.writeMany("    ");
    array.writeFormat(detail);
    array.writeMany(",\n");
}
fn writeUnspecifiedDetails(array: *gen.String) void {
    var detail: out.Detail = .{};
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "../../detail.zig" }});
    array.writeMany("pub const details: []const out.Detail = &[_]out.Detail{");
    writeUnspecifiedDetailsInternal(array, gen.AbstractSpec, &detail);
    array.writeMany("};\n");
}
pub fn specToDetail(array: *gen.String) void {
    writeUnspecifiedDetails(array);
    gen.writeFile(array, "memgen_detail.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    array.undefineAll();
    specToDetail(&array);
    gen.exit(0);
}
