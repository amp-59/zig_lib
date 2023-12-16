const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const debug = @import("../../debug.zig");
const attr = @import("attr.zig");
const types = @import("types.zig");
const config = @import("config.zig");
const common = @import("common_impls.zig");
const safety = @import("../../safety.zig");
const testing = @import("../../testing.zig");

pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
const wip_llc: bool = true;
pub const context = .Exe;

fn writeTasks(array: *common.Array, language: common.Variant.Language) !void {
    var len: usize = try gen.readFile(.{ .return_type = usize }, switch (language) {
        .Zig => config.tasks_template_path,
        .C => config.tasks_c_template_path,
    }, array.referAllUndefined());
    array.define(len);
    for (attr.scope) |decl| {
        array.writeFormat(types.BGTypeDescr{ .type_decl = decl });
    }
    types.BGTypeDescr.scope = attr.scope;
    for (attr.all) |attributes| {
        common.writeOpenStruct(array, language, attributes);
        common.writeFields(array, language, attributes);
        common.writeDeclarations(array, language, attributes);
        common.writeWriterFunctions(array, attributes);
        common.writeParserFunction(array, language, attributes);
        common.writeCloseContainer(array);
    }
    for (attr.all) |attributes| {
        common.writeParserFunctionHelp(array, attributes);
    }
    common.writeCommandStruct(array, language, attr.all);
    if (config.commit) {
        switch (language) {
            .C => try gen.truncateFile(.{ .return_type = void }, config.tasks_c_path, array.readAll()),
            .Zig => try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll()),
        }
    } else {
        debug.write(array.readAll());
    }
    types.BGTypeDescr.scope = &.{};
    array.undefineAll();
    if (wip_llc) {
        len = try gen.readFile(.{ .return_type = usize }, switch (language) {
            .Zig => config.tasks_template_path,
            .C => config.tasks_c_template_path,
        }, array.referAllUndefined());
        array.define(len);
        for (attr.scope) |decl| {
            array.writeFormat(types.BGTypeDescr{ .type_decl = decl });
        }
        types.BGTypeDescr.scope = attr.scope;
        common.writeOpenStruct(array, language, attr.llvm_llc_command_attributes);
        common.writeFields(array, language, attr.llvm_llc_command_attributes);
        common.writeDeclarations(array, language, attr.llvm_llc_command_attributes);
        common.writeWriterFunctions(array, attr.llvm_llc_command_attributes);
        common.writeParserFunction(array, language, attr.llvm_llc_command_attributes);
        common.writeCloseContainer(array);
        common.writeParserFunctionHelp(array, attr.llvm_llc_command_attributes);
        if (config.commit) {
            switch (language) {
                .C => try gen.truncateFile(.{ .return_type = void }, config.llc_tasks_c_path, array.readAll()),
                .Zig => try gen.truncateFile(.{ .return_type = void }, config.llc_tasks_path, array.readAll()),
            }
        } else {
            debug.write(array.readAll());
        }
    }
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    const array: *common.Array = allocator.create(common.Array);
    try writeTasks(array, .Zig);
}
