const zl = @import("zl");
const fmt = zl.fmt;
const build = zl.build;
const start = zl.start;
pub usingnamespace start;

fn formatWriteBuf(spec: *const build.BuilderSpec, buf: [*]u8) usize {
    var ptr: [*]u8 = fmt.strcpyEqu(buf, "pub const Builder=@import(\"zl\").build.GenericBuilder(");
    ptr += fmt.render(.{ .infer_type_names = true }, spec.*).formatWriteBuf(ptr);
    return fmt.strlen(fmt.strcpyEqu(ptr, ");\n"), buf);
}
export fn load(vtable: *extern struct {
    core: extern struct {
        formatWriteBuf: *const @TypeOf(formatWriteBuf),
    },
}) void {
    vtable.core.formatWriteBuf = formatWriteBuf;
}
