//! This stage summarises the abstract specification.
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const proc = @import("./../proc.zig");
const meta = @import("./../meta.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./abstract_spec.zig");
};

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

fn writeUnspecifiedDetailInternal(array: *gen.String, comptime T: type, impl_detail: *out.Detail) void {
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
        impl_detail.index = typeId(T);
        writeimpl_detailStruct(array, impl_detail.*);
    }
}
fn writeimpl_detailStruct(array: *gen.String, impl_detail: detail.Detail) void {
    array.writeMany("    ");
    array.writeFormat(impl_detail);
    array.writeMany(",\n");
}
fn writeUnspecifiedDetails(array: *gen.String) void {
    var impl_detail: detail.Detail = .{};
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "../../detail.zig" }});
    array.writeMany("pub const impl_details: []const out.Detail = &[_]out.Detail{");
    writeUnspecifiedDetailInternal(array, abstract_spec.AbstractSpec, &impl_detail);
    array.writeMany("};\n");
}
pub fn specToDetail(array: *gen.String) void {
    writeUnspecifiedDetails(array);
    gen.writeAuxiliarySourceFile(array, "impl_details.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var array: gen.String = undefined;
    array.undefineAll();
    array.undefineAll();
    specToDetail(&array);
    gen.exit(0);
}
