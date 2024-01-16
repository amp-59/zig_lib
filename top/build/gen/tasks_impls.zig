const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const debug = @import("../../debug.zig");
const attr = @import("attr.zig");
const types = @import("types.zig");
const config = @import("config.zig");
const common = @import("common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
const wip_llc: bool = false;
pub const context = .Exe;
pub const logging_override = debug.spec.logging.override.silent;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    const array: *types.Array = allocator.create(types.Array);
    const extra: *types.Extra = allocator.create(types.Extra);
    extra.* = .{ .language = .Zig };
    var len: usize = try gen.readFile(.{ .return_type = usize }, config.tasks_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.scope) |decl| {
        array.writeFormat(types.BGTypeDescr{ .type_decl = decl });
    }
    types.BGTypeDescr.scope = attr.scope;
    for (attr.all) |attributes| {
        common.writeOpenStruct(array, .Zig, attributes);
        common.writeFields(array, attributes);
        common.writeDeclarations(array, .Zig, attributes);
        extra.* = .{
            .function = .write,
            .notation = .slice,
        };
        common.writeWriterFunction(array, attributes, extra);
        extra.* = .{
            .function = .length,
            .notation = .slice,
        };
        common.writeWriterFunction(array, attributes, extra);
        extra.* = .{
            .notation = .slice,
        };
        common.writeParserFunction(array, attributes, extra);
        common.writeCloseContainer(array);
    }
    for (attr.all) |attributes| {
        common.writeParserFunctionHelp(array, attributes);
    }
    common.writeCommandStruct(array, .Zig, attr.all);
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll());
    } else {
        debug.write(array.readAll());
    }
    types.BGTypeDescr.scope = &.{};
    array.undefineAll();
    if (!wip_llc) {
        return;
    }
    len = try gen.readFile(.{ .return_type = usize }, config.tasks_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.scope) |decl| {
        array.writeFormat(types.BGTypeDescr{ .type_decl = decl });
    }
    types.BGTypeDescr.scope = attr.scope;
    common.writeOpenStruct(array, .Zig, attr.llvm_llc_command_attributes);
    common.writeFields(array, attr.llvm_llc_command_attributes);
    common.writeDeclarations(array, .Zig, attr.llvm_llc_command_attributes);
    extra.* = .{
        .function = .write,
        .notation = .slice,
    };
    common.writeWriterFunction(array, attr.llvm_llc_command_attributes, extra);
    extra.* = .{
        .function = .length,
        .notation = .slice,
    };
    common.writeWriterFunction(array, attr.llvm_llc_command_attributes, extra);
    extra.* = .{
        .notation = .slice,
    };
    common.writeParserFunction(array, attr.llvm_llc_command_attributes, extra);
    common.writeCloseContainer(array);
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.llc_tasks_path, array.readAll());
    } else {
        debug.write(array.readAll());
    }
}
