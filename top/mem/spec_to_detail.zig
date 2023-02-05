//! This stage summarises the abstract specification.
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const gen = @import("./gen.zig");

pub const Array = mem.StaticString(65536);

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

fn writeUnspecifiedDetailsInternal(array: *Array, comptime T: type, detail: *gen.Detail) void {
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
fn writeDetailStruct(array: *Array, detail: gen.Detail) void {
    array.writeMany("    ");
    array.writeFormat(detail);
    array.writeMany(",\n");
}
fn writeUnspecifiedDetails(array: *Array) void {
    var detail: gen.Detail = .{};
    gen.writeImports(array, @src(), &.{.{ .name = "gen", .path = "./gen.zig" }});
    array.writeMany("pub const impl_details = [_]gen.Detail{");
    writeUnspecifiedDetailsInternal(array, gen.AbstractSpec, &detail);
    array.writeMany("};\n");
}
pub fn generateImplementationSummary() void {
    var array: Array = .{};
    writeUnspecifiedDetails(&array);
    gen.writeFile(&array, "memgen_detail_0");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    generateImplementationSummary();
    gen.exit(0);
}
