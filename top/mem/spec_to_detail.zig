//! This stage summarises the abstract specification.
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./abstract_spec.zig");
};

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn writeUnspecifiedDetailInternal(array: *Array, comptime T: type, impl_detail: *out.Detail) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            const tmp = impl_detail.*;
            defer impl_detail.* = tmp;
            if (@hasField(gen.Kinds, field.name)) {
                @field(impl_detail.kinds, field.name) = true;
            }
            if (@hasField(gen.Layouts, field.name)) {
                @field(impl_detail.layouts, field.name) = true;
            }
            if (@hasField(gen.Modes, field.name)) {
                @field(impl_detail.modes, field.name) = true;
            }
            if (@hasField(gen.Fields, field.name)) {
                @field(impl_detail.fields, field.name) = true;
            }
            if (@hasField(gen.Techniques, field.name)) {
                @field(impl_detail.techs, field.name) = true;
            }
            writeUnspecifiedDetailInternal(array, field.type, impl_detail);
        }
    } else if (type_info == .Struct) {
        impl_detail.index = meta.typeId(T);
        writeDetailStruct(array, impl_detail.*);
    }
}
fn writeDetailStruct(array: *Array, impl_detail: out.Detail) void {
    array.writeMany("    ");
    array.writeFormat(impl_detail);
    array.writeMany(",\n");
}
fn writeUnspecifiedDetails(array: *Array) void {
    var impl_detail: out.Detail = .{};
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "../../detail.zig" }});
    array.writeMany("pub const impl_details: []const out.Detail = &[_]out.Detail{");
    writeUnspecifiedDetailInternal(array, out.AbstractSpec, &impl_detail);
    array.writeMany("};\n");
}
fn specToDetail() void {
    var array: Array = undefined;
    array.undefineAll();
    writeUnspecifiedDetails(&array);
    gen.writeAuxiliarySourceFile(&array, "impl_details.zig");
}
pub const main = specToDetail;
