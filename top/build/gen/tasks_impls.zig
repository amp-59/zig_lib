const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const context = .Exe;
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
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
    array.writeMany("pub const Fns=struct{\n");
    for (attr.all) |attributes| {
        common.writeFunctionExternSignatures(array, attributes);
    }
    array.writeMany("};\n");
    try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll());
}
