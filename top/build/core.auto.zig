const zl = @import("zl");
const fmt = zl.fmt;
const build = zl.build;
const start = zl.start;
pub usingnamespace start;

fn formatWriteBuf(any: *const anyopaque, buf: [*]u8) usize {
    const spec: *const zl.build.BuilderSpec = @ptrCast(@alignCast(any));
    var ptr: [*]u8 = fmt.strcpyEqu(buf, "@import(\"zl\").build.GenericBuilder(");
    ptr += fmt.render(.{ .infer_type_names = true }, spec.*).formatWriteBuf(ptr);
    return fmt.strlen(fmt.strcpyEqu(ptr, ")"), buf);
}
fn load(vtable: *extern struct {
    core: extern struct {
        formatWriteBuf: *const @TypeOf(formatWriteBuf),
    },
}) callconv(.C) void {
    vtable.core.formatWriteBuf = formatWriteBuf;
}

comptime {
    @export(load, .{ .name = "load", .linkage = .Weak });
}
