const zl = @import("zl");
const fmt = zl.fmt;
const types = zl.build;
const start = zl.start;
pub usingnamespace start;
pub const comptime_errors: bool = false;

pub fn main() void {}

fn formatWriteBuf(spec: *const types.BuilderSpec, buf: [*]u8) usize {
    var ptr: [*]u8 = fmt.strcpyEqu(buf, "pub const Builder=@import(\"zl\").build.GenericBuilder(");
    ptr += fmt.render(.{ .infer_type_names = true }, spec.*).formatWriteBuf(ptr);
    return fmt.strlen(fmt.strcpyEqu(ptr, ");\n"), buf);
}

export fn load(vtable: *zl.meta.Field(types.VTable, "core")) callconv(.C) void {
    vtable.formatWriteBuf = formatWriteBuf;
}
