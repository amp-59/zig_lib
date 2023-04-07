//! This stage summarises the abstract specification.
const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const builtin = gen.builtin;

const attr = @import("./attr.zig");
const detail = @import("./detail.zig");

const out = struct {
    usingnamespace @import("./abstract_spec.zig");
};
pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};

const Array = mem.StaticArray(u8, 1024 * 1024);

fn setAttribute(impl_detail: *detail.Base, comptime attribute_name: []const u8) void {
    if (@hasField(attr.Kinds, attribute_name)) {
        @field(impl_detail.kinds, attribute_name) = true;
        return;
    }
    if (@hasField(attr.Layouts, attribute_name)) {
        @field(impl_detail.layouts, attribute_name) = true;
        return;
    }
    if (@hasField(attr.Modes, attribute_name)) {
        @field(impl_detail.modes, attribute_name) = true;
        return;
    }
    if (@hasField(attr.Managers, attribute_name)) {
        @field(impl_detail.managers, attribute_name) = true;
        return;
    }
    if (@hasField(attr.Fields, attribute_name)) {
        @field(impl_detail.fields, attribute_name) = true;
        return;
    }
    if (@hasField(attr.Techniques, attribute_name)) {
        @field(impl_detail.techs, attribute_name) = true;
        return;
    }
    if (attribute_name[0] == '_') {
        return;
    }
    @compileError("unknown attribute: " ++ attribute_name);
}
inline fn writeUnspecifiedDetailInternal(array: *Array, comptime T: type, impl_detail: *detail.Base) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            const save: detail.Base = impl_detail.*;
            defer impl_detail.* = save;
            setAttribute(impl_detail, field.name);
            writeUnspecifiedDetailInternal(array, field.type, impl_detail);
        }
    } else if (type_info == .Struct) {
        impl_detail.index = builtin.typeId(T);
        writeDetailStruct(array, impl_detail);
    }
}
fn writeDetailStruct(array: *Array, impl_detail: *const detail.Base) void {
    array.writeMany("    ");
    array.writeFormat(impl_detail.*);
    array.writeMany(",\n");
}
fn specToDetail() void {
    var array: Array = undefined;
    array.undefineAll();
    var impl_detail: detail.Base = .{};
    gen.writeImport(&array, "detail", "../../detail.zig");
    array.writeMany("pub const impl_details: []const detail.Base = &[_]detail.Base{");
    writeUnspecifiedDetailInternal(&array, out.AbstractSpec, &impl_detail);
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "impl_details.zig");
}
pub const main = specToDetail;
