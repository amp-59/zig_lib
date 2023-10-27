const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const debug = @import("../../debug.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
const testing = @import("../../testing.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const context = .Exe;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    const array: *common.Array = allocator.create(common.Array);
    const len: usize = try gen.readFile(.{ .return_type = usize }, config.tasks_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.scope) |decl| {
        array.writeFormat(types.ProtoTypeDescr{ .type_decl = decl });
    }
    types.ProtoTypeDescr.scope = attr.scope;
    for (attr.all) |attributes| {
        array.writeMany("pub const ");
        array.writeMany(attributes.type_name);
        array.writeMany("=struct{\n");
        common.writeFields(array, attributes);
        common.writeDeclarations(array, attributes);
        common.writeWriterFunctions(array, attributes);
        common.writeParserFunction(array, .Zig, attributes);
        array.writeMany("};\n");
    }
    for (attr.all) |attributes| {
        common.writeParserFunctionHelp(array, attributes);
    }
    array.writeMany("pub const Command=struct{\n");
    for (attr.all) |attributes| {
        array.writeMany(attributes.fn_name);
        array.writeMany(":*");
        array.writeMany(attributes.type_name);
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll());
    } else {
        debug.write(array.readAll());
    }
    for (attr.llvm_llc_command_attributes.params) |param| {
        testing.renderBufN(.{ .infer_type_names = true, .omit_trailing_comma = true, .decls = .{ .forward_formatter = true } }, 4096, param);
    }
}
