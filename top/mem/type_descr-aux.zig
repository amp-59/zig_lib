const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");
const gen = @import("./gen.zig");
const out = @import("./zig-out/src/type_specs.zig");
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

const TypeDescrFormat = fmt.GenericTypeDescrFormat(.{});

const fmt_spec = .{
    .infer_type_names = true,
    .ignore_formatter_decls = true,
};
fn mapContainersToParameters() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "gen", "../../gen.zig");
    array.writeMany("pub const type_descrs=");
    array.writeMany(
        \\&[_]struct {
        \\    params: gen.fmt.GenericTypeDescrFormat(.{}),
        \\    specs: []const gen.fmt.GenericTypeDescrFormat(.{}),
        \\    vars: gen.fmt.GenericTypeDescrFormat(.{}),
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
