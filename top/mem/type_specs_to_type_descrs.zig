const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const builtin = @import("./../builtin.zig");
const testing = @import("./../testing.zig");

const gen = @import("./gen.zig");
const out = @import("./zig-out/src/memgen_type_specs.zig");

fn mapContainersToParameters(array: *gen.String) void {
    const fmt_spec = .{ .infer_type_names = true, .ignore_formatter_decls = true };
    gen.writeImports(array, @src(), &.{.{ .name = "gen", .path = "../../gen.zig" }});
    array.writeMany("pub const type_descrs = ");
    array.writeMany(
        \\&[_]struct {
        \\    params: gen.TypeDescr,
        \\    specs: []const gen.TypeDescr,
        \\    vars: gen.TypeDescr,
        \\}{ 
    );
    inline for (out.type_specs) |type_spec| {
        array.writeMany(".{ .params = ");
        array.writeFormat(fmt.render(fmt_spec, comptime gen.TypeDescr.init(type_spec.params)));
        array.writeMany(",\n");
        array.writeMany(".specs = &.{\n");
        inline for (type_spec.specs) |spec| {
            array.writeFormat(fmt.render(fmt_spec, comptime gen.TypeDescr.init(spec)));
            array.writeMany(",\n");
        }
        array.writeMany("},\n");
        array.writeMany(".vars = ");
        array.writeFormat(fmt.render(fmt_spec, comptime gen.TypeDescr.init(type_spec.vars)));
        array.writeMany("},\n");
    }
    array.overwriteManyBack("};");
    array.writeMany("\n");
    gen.writeAuxiliarySourceFile(array, "memgen_type_descrs.zig");
}

pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    mapContainersToParameters(&array);
    gen.exit(0);
}
