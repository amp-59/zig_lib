const mem = @import("../mem.zig");
const proc = @import("../proc.zig");
const file = @import("../file.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
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
fn writeFile(array: Array, pathname: [:0]const u8) void {
    const build_fd: u64 = file.create(creat_spec, pathname, file.file_mode);
    file.writeSlice(write_spec, build_fd, array.readAll());
    file.close(close_spec, build_fd);
}

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
        // Documentation:
        if (opt_spec.descr) |field_descr| {
            for (field_descr) |line| {
                array.writeMany("/// ");
                array.writeMany(line);
                array.writeMany("\n");
            }
        }
        // Field name:
        array.writeMany(opt_spec.name);
        array.writeMany(":");
        // Field type:
        writeType(array, opt_spec);
        // Default value
        if (opt_spec.arg_info.tag == .boolean) {
            array.writeMany("=false");
        } else {
            array.writeMany("=null");
        }
        array.writeMany(",\n");
    }
}
pub fn main() !void {
    var array: Array = undefined;
    array.undefineAll();

    const fd: u64 = file.open(open_spec, config.tasks_template_path);
    array.define(file.readSlice(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    array.writeMany("pub const BuildCommand=struct{\nkind:types.OutputMode,\n");
    writeFields(&array, attr.build_command_options);
    array.writeMany("};\npub const FormatCommand=struct{\n");
    writeFields(&array, attr.format_command_options);
    array.writeMany("};\n");
    writeFile(array, config.tasks_path);
    array.undefineAll();
}
