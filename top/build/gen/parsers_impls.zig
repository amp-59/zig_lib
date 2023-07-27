const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const mach = @import("../../mach.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace @import("../../start.zig");

pub const runtime_assertions: bool = false;
pub const logging_default: debug.Logging.Default = spec.logging.default.silent;

const Array = mem.StaticString(64 * 1024 * 1024);
const open_spec: file.OpenSpec = .{
    .errors = .{},
    .logging = .{},
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
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    const fd: u64 = file.open(open_spec, config.parsers_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    for (@as([]const types.Attributes, &.{
        attr.zig_build_command_attributes,
        attr.zig_format_command_attributes,
        attr.zig_ar_command_attributes,
        attr.zig_objcopy_command_attributes,
        attr.llvm_tblgen_command_attributes,
        attr.harec_attributes,
    })) |attributes| {
        array.writeMany("pub export fn ");
        array.writeMany(attributes.fn_name);
        array.writeMany("FormatParseArgs(allocator:*types.Allocator,");
        array.writeMany(attributes.fn_name);
        array.writeMany("_cmd: *types.");
        array.writeMany(attributes.type_name);
        array.writeMany(",args:[*][*:0]u8,args_len:usize)void{\n");
        array.writeMany(attributes.fn_name);
        array.writeMany("_cmd.formatParseArgs(allocator,args[0..args_len]);");
        array.writeMany("}");
    }
    try gen.truncateFile(.{ .return_type = void }, config.parsers_path, array.readAll());
}
