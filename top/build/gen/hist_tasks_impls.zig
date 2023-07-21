const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const mach = @import("../../mach.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const tasks = @import("../tasks.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");
pub usingnamespace @import("../../start.zig");
pub const runtime_assertions: bool = false;
pub const logging_override: debug.Logging.Override = spec.logging.override.silent;
const max_len: u64 = attr.format_command_options.len + attr.build_command_options.len;
const Array = mem.StaticString(1024 *% 1024);
const Arrays = mem.StaticArray([]const u8, max_len);
const Indices = mem.StaticArray(u64, max_len);
const prefer_ptrcast: bool = true;
const prefer_builtin_memcpy: bool = true;
const combine_char: bool = true;
const open_spec: file.OpenSpec = .{
    .errors = .{},
    .logging = .{},
};
const stat_spec: file.StatusSpec = .{
    .errors = .{},
    .logging = .{},
};
const send_spec: file.SendSpec = .{
    .errors = .{},
    .logging = .{},
    .return_type = void,
};
const create_spec: file.CreateSpec = .{
    .errors = .{},
    .logging = .{},
    .options = .{ .exclusive = false },
};
const write_spec: file.WriteSpec = .{
    .errors = .{},
    .logging = .{},
};
const read_spec: file.ReadSpec = .{
    .errors = .{},
    .logging = .{},
};
const close_spec: file.CloseSpec = .{
    .errors = .{},
    .logging = .{},
};
pub const InlineTypeDescr = fmt.GenericTypeDescrFormat(.{
    .options = .{
        .default_field_values = true,
        .identifier_name = true,
    },
    .tokens = .{
        .lbrace = "{",
        .equal = "=",
        .rbrace = "}",
        .next = ",",
        .colon = ":",
        .indent = "",
    },
});
fn writeField(comptime field_type: type, field_name: []const u8, key_array: *Array, val_array: *Array, conv_array: *Array) void {
    const type_info: builtin.Type = @typeInfo(field_type);
    if (type_info == .Optional) {
        const child_type: type = type_info.Optional.child;
        const child_type_info: builtin.Type = @typeInfo(child_type);
        if (child_type_info == .Bool or
            child_type_info == .Enum)
        {
            key_array.writeMany(field_name);
            key_array.writeMany(":bool=false,\n");
            val_array.writeMany(field_name);
            val_array.writeMany(":");
            if (child_type_info == .Bool) {
                val_array.writeMany("bool");
            } else {
                val_array.writeMany("@typeInfo(@TypeOf(@field(undef,\"");
                val_array.writeMany(field_name);
                val_array.writeMany("\"))).Optional.child");
            }
            val_array.writeMany("=undefined,\n");
            conv_array.writeMany("ret.key.");
            conv_array.writeMany(field_name);
            conv_array.writeMany("=cmd.");
            conv_array.writeMany(field_name);
            conv_array.writeMany(" != null;\n");
            conv_array.writeMany("ret.val.");
            conv_array.writeMany(field_name);
            conv_array.writeMany("=cmd.");
            conv_array.writeMany(field_name);
            conv_array.writeMany(".?;\n");
        }
    }
}
fn writeDecl(decl_name: []const u8, key_array: *Array, val_array: *Array, conv_array: *Array) void {
    key_array.writeMany("pub const ");
    key_array.writeMany(decl_name);
    key_array.writeMany("=packed struct{\n");
    key_array.writeMany("key:Key,\n");
    key_array.writeMany("val:Val,\n");
    key_array.writeMany("const undef:tasks.");
    key_array.writeMany(decl_name);
    key_array.writeMany(" = undefined;");
    key_array.writeMany("const Key=packed struct{\n");
    val_array.writeMany("const Val=packed struct{\n");
    conv_array.writeMany("pub fn convert(cmd:*tasks.");
    conv_array.writeMany(decl_name);
    conv_array.writeMany(")");
    conv_array.writeMany(decl_name);
    conv_array.writeMany("{\n");
    conv_array.writeMany("@setRuntimeSafety(false);\n");
    conv_array.writeMany("var ret:");
    conv_array.writeMany(decl_name);
    conv_array.writeMany("=undefined;\n");
}
fn writeClose(array: *Array, key_array: *Array, val_array: *Array, conv_array: *Array) void {
    if (mem.indexOfFirstEqualMany(u8, ":bool", key_array.readAll()) != null) {
        array.writeMany(key_array.readAll());
        array.writeMany("};\n");
        array.writeMany(val_array.readAll());
        array.writeMany("};\n");
        array.writeMany(conv_array.readAll());
        array.writeMany("return ret;\n");
        array.writeMany("}\n};\n");
    }
    key_array.undefineAll();
    val_array.undefineAll();
    conv_array.undefineAll();
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    var array: *Array = allocator.create(Array);
    array.undefineAll();
    const src_fd: u64 = file.open(open_spec, config.hist_tasks_template_path);
    const src_st: file.Status = file.status(stat_spec, src_fd);
    const dest_fd: u64 = file.create(create_spec, config.hist_tasks_path, file.mode.regular);
    file.send(send_spec, dest_fd, src_fd, null, src_st.size);
    var key_array: *Array = allocator.create(Array);
    key_array.undefineAll();
    var val_array: *Array = allocator.create(Array);
    val_array.undefineAll();
    var conv_array: *Array = allocator.create(Array);
    conv_array.undefineAll();
    inline for (@typeInfo(tasks).Struct.decls) |decl| {
        if (decl.is_pub) {
            const Command = @field(tasks, decl.name);
            writeDecl(decl.name, key_array, val_array, conv_array);
            inline for (@typeInfo(Command).Struct.fields) |field| {
                writeField(field.type, field.name, key_array, val_array, conv_array);
            }
            writeClose(array, key_array, val_array, conv_array);
        }
    }
    try gen.appendFile(.{ .return_type = void }, config.hist_tasks_path, array.readAll());
}
