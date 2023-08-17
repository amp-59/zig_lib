const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const build = @import("../types.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const Array = mem.StaticString(64 * 1024 * 1024);
const Variant = enum {
    externs,
    exports,
    wrappers,
};
const Names = struct {
    info: builtin.Type,
    forward: bool,
    decl_name: []const u8,
    export_name: []const u8,
    param_names: []const []const u8 = &.{},
};
fn typeRequireswrappers(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .Pointer => |pointer_info| {
            if (pointer_info.size == .Slice) {
                return true;
            }
        },
        .Struct => |struct_info| {
            if (struct_info.layout == .Auto) {
                return true;
            }
        },
        .Optional => {
            return true;
        },
        else => {
            return false;
        },
    }
    return false;
}
fn requireswrappers(comptime fn_info: builtin.Type.Fn) bool {
    inline for (fn_info.params) |param| {
        if (typeRequireswrappers(param.type.?)) {
            return true;
        }
    }
    return typeRequireswrappers(fn_info.return_type.?);
}
fn writeParameter(array: *Array, variant: Variant, comptime param_type: type, comptime prefix: []const u8) void {
    if (variant == .wrappers) {
        array.writeMany(prefix);
        array.writeMany(":");
        array.writeFormat(comptime types.ProtoTypeDescr.init(param_type));
        array.writeMany(",");
    } else {
        switch (@typeInfo(param_type)) {
            .Pointer => |pointer_info| {
                if (pointer_info.size == .Slice) {
                    comptime var many_pointer_info: builtin.Type.Pointer = pointer_info;
                    many_pointer_info.size = .Many;
                    array.writeMany(prefix);
                    array.writeMany("_ptr:");
                    array.writeFormat(comptime types.ProtoTypeDescr.init(@Type(.{ .Pointer = many_pointer_info })));
                    array.writeMany(",");
                    array.writeMany(prefix);
                    array.writeMany("_len:usize,");
                } else {
                    array.writeMany(prefix);
                    array.writeMany(":");
                    array.writeFormat(comptime types.ProtoTypeDescr.init(param_type));
                    array.writeMany(",");
                }
            },
            .Struct => |struct_info| {
                if (struct_info.layout == .Extern) {
                    array.writeMany(prefix);
                    array.writeMany(":");
                    array.writeFormat(comptime types.ProtoTypeDescr.init(param_type));
                    array.writeMany(",");
                } else {
                    inline for (struct_info.fields) |field| {
                        writeParameter(array, variant, field.type, prefix ++ "_" ++ field.name);
                    }
                }
            },
            else => {
                array.writeMany(prefix);
                array.writeMany(":");
                array.writeFormat(comptime types.ProtoTypeDescr.init(param_type));
                array.writeMany(",");
            },
        }
    }
}
fn writeArgument(array: *Array, variant: Variant, comptime param_type: type, comptime prefix: []const u8) void {
    if (variant == .wrappers) {
        switch (@typeInfo(param_type)) {
            .Pointer => |pointer_info| {
                if (pointer_info.size == .Slice) {
                    comptime var many_pointer_info: builtin.Type.Pointer = pointer_info;
                    many_pointer_info.size = .Many;
                    array.writeMany(prefix);
                    array.writeMany(".ptr,");
                    array.writeMany(prefix);
                    array.writeMany(".len,");
                } else {
                    array.writeMany(prefix);
                    array.writeMany(",");
                }
            },
            .Struct => |struct_info| {
                if (struct_info.layout == .Extern) {
                    array.writeMany(prefix);
                    array.writeMany(",");
                } else {
                    inline for (struct_info.fields) |field| {
                        writeArgument(array, variant, field.type, prefix ++ "." ++ field.name);
                    }
                }
            },
            else => {
                array.writeMany(prefix);
                array.writeMany(",");
            },
        }
    } else {
        switch (@typeInfo(param_type)) {
            .Pointer => |pointer_info| {
                if (pointer_info.size == .Slice) {
                    array.writeMany(prefix);
                    array.writeMany("_ptr[0..");
                    array.writeMany(prefix);
                    array.writeMany("_len],");
                } else {
                    array.writeMany(prefix);
                    array.writeMany(",");
                }
            },
            .Struct => |struct_info| {
                if (struct_info.layout == .Extern) {
                    array.writeMany(prefix);
                    array.writeMany(",");
                } else {
                    inline for (struct_info.fields) |field| {
                        writeArgument(array, variant, field.type, prefix ++ "_" ++ field.name);
                    }
                }
            },
            else => {
                array.writeMany(prefix ++ ",");
            },
        }
    }
}
fn getNameSets(comptime T: type) []const Names {
    const manifest = if (@hasDecl(T, "manifest")) T.manifest else .{};
    const Manifest = @TypeOf(manifest);
    var ret: []const Names = &.{};
    inline for (meta.resolve(@typeInfo(T)).decls) |decl| {
        const field = @field(T, decl.name);
        const field_type = @TypeOf(field);
        const field_type_info: builtin.Type = @typeInfo(field_type);
        if (field_type_info != .Fn) {
            continue;
        }
        if (field_type_info.Fn.is_generic) {
            continue;
        }
        const entry: gen.FnExport = if (@hasField(Manifest, decl.name)) @field(manifest, decl.name) else .{};
        const export_name: []const u8 = (entry.prefix orelse "") ++ (entry.name orelse decl.name) ++ (entry.suffix orelse "Export");
        var param_names: []const []const u8 = &.{};
        if (entry.param_names) |names| {
            debug.assert(names.len == field_type_info.Fn.params.len);
            param_names = names;
        } else {
            inline for (0..field_type_info.Fn.params.len) |idx| {
                param_names = param_names ++ [1][]const u8{"p_" ++ fmt.cx(idx)};
            }
        }
        ret = ret ++ [1]Names{.{
            .info = field_type_info,
            .forward = requireswrappers(field_type_info.Fn),
            .decl_name = decl.name,
            .export_name = export_name,
            .param_names = param_names,
        }};
    }
    return ret;
}
fn writeStringLiteral(array: *Array, string: []const u8) void {
    for (string) |byte| {
        array.writeMany(fmt.stringLiteralChar(byte));
    }
}
fn writeSymbol(array: *common.Array, comptime T: type, variant: Variant) void {
    @setEvalBranchQuota(~@as(u32, 0));
    const export_name_sets: []const Names = getNameSets(T);
    if (variant == .exports) {
        array.writeMany("comptime{\n");
        inline for (export_name_sets) |set| {
            if (set.forward) {
                array.writeMany("@export(");
                array.writeFormat(fmt.identifier(set.decl_name));
                array.writeMany(",.{.name=\"");
                writeStringLiteral(array, set.export_name);
                array.writeMany("\",.linkage=.Strong});\n");
            } else {
                array.writeMany("@export(source.");
                array.writeFormat(fmt.identifier(set.decl_name));
                array.writeMany(",.{.name=\"");
                writeStringLiteral(array, set.export_name);
                array.writeMany("\",.linkage=.Strong});\n");
            }
        }
        array.writeMany("}\n");
    }
    inline for (export_name_sets) |names| {
        const field = @field(T, names.decl_name);
        const field_type = @TypeOf(field);
        const field_type_info: builtin.Type = @typeInfo(field_type);
        switch (variant) {
            .exports => if (names.forward) {
                array.writeMany("fn ");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, variant, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")callconv(.C)");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("{\n");
                array.writeMany("return source." ++ names.decl_name ++ "(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeArgument(array, variant, param.type.?, names.param_names[idx]);
                }
                array.undefine(1);
                array.writeMany(");\n");
                array.writeMany("}\n");
            },
            .externs => {
                array.writeMany("extern fn ");
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, variant, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany(";");
            },
            .wrappers => {
                array.writeMany("pub fn " ++ names.decl_name ++ "(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, variant, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("{\n");
                array.writeMany("return ");
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeArgument(array, variant, param.type.?, names.param_names[idx]);
                }
                array.undefine(1);
                array.writeMany(");\n");
                array.writeMany("}\n");
            },
        }
    }
}
const BuildCommands = build.GenericCommand(build.BuildCommand);
const FormatCommands = build.GenericCommand(build.FormatCommand);
const ObjcopyCommands = build.GenericCommand(build.ObjcopyCommand);
const ArchiveCommands = build.GenericCommand(build.ArchiveCommand);
fn writeImportBuild(array: *Array) void {
    array.writeMany("const build = @import(\"@build\").zl.build;\n");
}
fn writePubUsingnamespace(array: *Array) void {
    array.writeMany("pub usingnamespace if(@import(\"builtin\").output_mode==.Exe)struct{\n");
}
fn writeElseStruct(array: *Array) void {
    array.writeMany("}else struct{\n");
}
fn writeStructClose(array: *Array) void {
    array.writeMany("};\n");
}
fn writeGenericCommand(array: *Array, type_name: []const u8) void {
    array.writeMany("const source = build.GenericCommand(");
    array.writeMany(type_name);
    array.writeMany(");\n");
}
fn writeBuildCommandLibrary(array: *Array) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.BuildCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.BuildCommand", build.BuildCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writePubUsingnamespace(array);
    writeSymbol(array, BuildCommands, .externs);
    writeSymbol(array, BuildCommands, .wrappers);
    writeElseStruct(array);
    writeSymbol(array, BuildCommands, .exports);
    writeStructClose(array);
    try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile("build.h.zig"), array.readAll());
    array.undefineAll();
}
fn writeFormatCommandLibrary(array: *Array) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.FormatCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.FormatCommand", build.FormatCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writePubUsingnamespace(array);
    writeSymbol(array, FormatCommands, .externs);
    writeSymbol(array, FormatCommands, .wrappers);
    writeElseStruct(array);
    writeSymbol(array, FormatCommands, .exports);
    writeStructClose(array);
    try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile("format.h.zig"), array.readAll());
    array.undefineAll();
}
fn writeArchiveCommandLibrary(array: *Array) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.ArchiveCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.ArchiveCommand", build.ArchiveCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writePubUsingnamespace(array);
    writeSymbol(array, ArchiveCommands, .externs);
    writeSymbol(array, ArchiveCommands, .wrappers);
    writeElseStruct(array);
    writeSymbol(array, ArchiveCommands, .exports);
    writeStructClose(array);
    try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile("archive.h.zig"), array.readAll());
    array.undefineAll();
}
fn writeObjcopyCommandLibrary(array: *Array) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.ObjcopyCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.ObjcopyCommand", build.ObjcopyCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writePubUsingnamespace(array);
    writeSymbol(array, ObjcopyCommands, .externs);
    writeSymbol(array, ObjcopyCommands, .wrappers);
    writeElseStruct(array);
    writeSymbol(array, ObjcopyCommands, .exports);
    writeStructClose(array);
    try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile("objcopy.h.zig"), array.readAll());
    array.undefineAll();
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *common.Array = allocator.create(common.Array);
    try writeBuildCommandLibrary(array);
    try writeFormatCommandLibrary(array);
    try writeArchiveCommandLibrary(array);
    try writeObjcopyCommandLibrary(array);
}
