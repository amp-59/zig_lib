const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const max_len: u64 = attr.format_command_options.len + attr.build_command_options.len;
const Array = mem.StaticStream(u8, 1024 * 1024);
const Arrays = mem.StaticArray([]const u8, max_len);
const Indices = mem.StaticArray(u64, max_len);
const open_spec: file.OpenSpec = .{ .errors = .{}, .logging = .{} };
const creat_spec: file.CreateSpec = .{ .errors = .{}, .logging = .{}, .options = .{ .exclusive = false } };
const write_spec: file.WriteSpec = .{ .errors = .{}, .logging = .{} };
const read_spec: file.ReadSpec = .{ .errors = .{}, .logging = .{} };
const close_spec: file.CloseSpec = .{ .errors = .{}, .logging = .{} };
fn writeType(array: *Array, opt_spec: types.OptionSpec) void {
    if (opt_spec.and_no) |no_opt_spec| {
        const yes_bool: bool = opt_spec.arg_info.tag == .boolean;
        const no_bool: bool = no_opt_spec.arg_info.tag == .boolean;
        if (yes_bool != no_bool) {
            const tmp: types.ProtoTypeDescr = .{ .type_decl = .{ .Composition = .{
                .spec = "union(enum)",
                .fields = &.{
                    .{ .name = "yes", .type = if (yes_bool) null else opt_spec.arg_info.type },
                    .{ .name = "no", .type = if (no_bool) null else no_opt_spec.arg_info.type },
                },
            } } };
            array.writeFormat(types.ArgInfo.optional(&tmp));
        } else {
            array.writeFormat(types.ArgInfo.optional(&types.ProtoTypeDescr.init(bool)));
        }
    } else {
        array.writeFormat(opt_spec.arg_info.type);
    }
}
fn writeFields(array: *Array, opt_specs: []const types.OptionSpec) void {
    for (opt_specs) |opt_spec| {
        if (opt_spec.descr) |field_descr| {
            for (field_descr) |line| {
                array.writeMany("/// ");
                array.writeMany(line);
                array.writeMany("\n");
            }
        }
        array.writeMany(opt_spec.name);
        array.writeMany(":");
        writeType(array, opt_spec);
        if (opt_spec.and_no == null and
            opt_spec.arg_info.tag == .boolean)
        {
            array.writeMany("=false,\n");
        } else if (opt_spec.arg_info.tag != .tag) {
            array.writeMany("=null,\n");
        } else {
            array.writeMany(",\n");
        }
    }
}
fn writeTaskStruct(array: *Array, name: []const u8, attributes: []const types.OptionSpec) void {
    array.writeMany("pub const ");
    array.writeMany(name);
    array.writeMany("=struct{\n");
    writeFields(array, attributes);
    array.writeMany("};\n");
}

pub fn main() !void {
    var array: Array = undefined;
    array.undefineAll();
    const fd: u64 = file.open(open_spec, config.tasks_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    writeTaskStruct(&array, "BuildCommand", attr.build_command_options);
    writeTaskStruct(&array, "FormatCommand", attr.format_command_options);
    writeTaskStruct(&array, "ArchiveCommand", attr.archive_command_options);
    writeTaskStruct(&array, "TableGenCommand", attr.tblgen_command_options);
    gen.truncateFile(write_spec, config.tasks_path, array.readAll());
    array.undefineAll();
}
