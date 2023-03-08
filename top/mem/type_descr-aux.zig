const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const out = struct {
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/abstract_params.zig");
};
pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

const TypeDescrFormat = fmt.GenericTypeDescrFormat(.{ .options = .{ .default_fields = true } });
const fmt_spec: fmt.RenderSpec = .{ .infer_type_names = true, .ignore_formatter_decls = true };

fn mapContainersToParameters() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "gen", "../../gen.zig");
    array.writeMany("const TypeDescrFormat=gen.fmt.GenericTypeDescrFormat(.{.options=.{.default_fields=true}});\n");
    array.writeMany(
        \\pub const type_descrs=&[_]struct {
        \\    params: TypeDescrFormat,
        \\    specs: []const TypeDescrFormat,
        \\    vars: TypeDescrFormat,
        \\}{
    );
    inline for (out.type_specs) |type_spec| {
        array.writeMany(".{.params=");
        array.writeFormat(fmt.render(fmt_spec, comptime TypeDescrFormat.init(type_spec.params)));
        array.writeMany(",\n");
        array.writeMany(".specs=&.{\n");
        inline for (type_spec.specs) |spec| {
            array.writeFormat(fmt.render(fmt_spec, comptime TypeDescrFormat.init(spec)));
            array.writeMany(",\n");
        }
        array.writeMany("},\n");
        array.writeMany(".vars=");
        array.writeFormat(fmt.render(fmt_spec, comptime TypeDescrFormat.init(type_spec.vars)));
        array.writeMany("},\n");
    }
    array.overwriteManyBack("};");
    array.writeMany("\n");
    gen.writeAuxiliarySourceFile(&array, "type_descrs.zig");
}
pub const main = mapContainersToParameters;
