const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const build = @import("../../build.zig");
const config = @import("./config.zig");
const common = @import("./common_impls.zig");
pub usingnamespace @import("../../start.zig");
pub usingnamespace config;
pub const Array = mem.StaticString(64 * 1024 * 1024);
const MajorVariant = enum {
    library,
    autoloader,
    hybrid,
};
const MinorVariant = enum {
    externs,
    exports,
    wrappers,
    var_decls,
    ptr_fields_source,
    load_assign_source,
    ptr_vars_export,
    load_assign_export,
};
const Names = struct {
    info: builtin.Type,
    forward: bool,
    decl_name: []const u8,
    export_name: []const u8,
    param_names: []const []const u8 = &.{},
};
fn typeRequiresWrappers(comptime T: type) bool {
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
        if (typeRequiresWrappers(param.type.?)) {
            return true;
        }
    }
    return typeRequiresWrappers(fn_info.return_type.?);
}
fn writeParameter(array: *Array, v: MinorVariant, comptime param_type: type, comptime prefix: []const u8) void {
    if (v == .wrappers or v == .ptr_fields_source) {
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
                        writeParameter(array, v, field.type, prefix ++ "_" ++ field.name);
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
fn writeArgument(array: *Array, v: MinorVariant, comptime param_type: type, comptime prefix: []const u8) void {
    if (v == .wrappers) {
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
                        writeArgument(array, v, field.type, prefix ++ "." ++ field.name);
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
                        writeArgument(array, v, field.type, prefix ++ "_" ++ field.name);
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
fn writeSymbol(array: *common.Array, comptime T: type, v: MinorVariant) void {
    @setEvalBranchQuota(~@as(u32, 0));
    const export_name_sets: []const Names = getNameSets(T);
    if (v == .exports) {
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
        switch (v) {
            .var_decls => {
                array.writeMany("var ");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany(":*fn(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")callconv(.C)");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("=@ptrFromInt(8);\n");
            },
            .exports => if (names.forward) {
                array.writeMany("fn ");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")callconv(.C)");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("{\n");
                array.writeMany("return source." ++ names.decl_name ++ "(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeArgument(array, v, param.type.?, names.param_names[idx]);
                }
                if (field_type_info.Fn.params.len != 0) {
                    array.undefine(1);
                }
                array.writeMany(");\n");
                array.writeMany("}\n");
            },
            .externs => {
                array.writeMany("extern fn ");
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany(";");
            },
            .wrappers => {
                array.writeMany("pub fn " ++ names.decl_name ++ "(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("{\n");
                array.writeMany("return ");
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany("(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeArgument(array, v, param.type.?, names.param_names[idx]);
                }
                if (field_type_info.Fn.params.len != 0) {
                    array.undefine(1);
                }
                array.writeMany(");\n");
                array.writeMany("}\n");
            },
            .ptr_fields_source => {
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany(":*const fn(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("=@ptrFromInt(8),\n");
            },
            .load_assign_source => {
                array.writeMany("ptrs.");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany("=@ptrCast(&source.");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany(");\n");
            },
            .ptr_vars_export => {
                array.writeMany("var ");
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany(":*const fn(");
                inline for (field_type_info.Fn.params, 0..) |param, idx| {
                    writeParameter(array, v, param.type.?, names.param_names[idx]);
                }
                array.writeMany(")");
                array.writeFormat(comptime types.ProtoTypeDescr.init(field_type_info.Fn.return_type.?));
                array.writeMany("=@ptrFromInt(8);\n");
            },
            .load_assign_export => {
                array.writeFormat(fmt.identifier(names.export_name));
                array.writeMany("=&source.");
                array.writeFormat(fmt.identifier(names.decl_name));
                array.writeMany(";\n");
            },
            //else => {},
        }
    }
}
fn writeImportBuild(array: *Array) void {
    array.writeMany("const types = @import(\"./types.zig\");\n");
}
fn writeImportMach(array: *Array) void {
    array.writeMany("pub usingnamespace @import(\"../start.zig\");\n");
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
fn writeIfClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeGenericCommand(array: *Array, type_name: []const u8) void {
    array.writeMany("const source = types.GenericCommand(");
    array.writeMany(type_name);
    array.writeMany(");\n");
}
fn writeGenericExtraCommand(array: *Array, type_name: []const u8) void {
    array.writeMany("const source = types.GenericExtraCommand(");
    array.writeMany(type_name);
    array.writeMany(");\n");
}
fn writeExportLoad(array: *Array) void {
    array.writeMany("comptime {\n");
    array.writeMany("if (@import(\"builtin\").output_mode!=.Exe){\n");
    array.writeMany("@export(load,.{.name=\"load\",.linkage=.Strong});\n");
    array.writeMany("}\n");
    array.writeMany("}\n");
}
fn writeLoadSignature(array: *Array) void {
    array.writeMany("fn load(ptrs:*@This())callconv(.C)void{\n");
}
fn writeInternal(array: *Array, comptime mv: MajorVariant, comptime T: type) void {
    switch (mv) {
        .library => {
            writePubUsingnamespace(array);
            writeSymbol(array, T, .externs);
            writeSymbol(array, T, .wrappers);
            writeElseStruct(array);
            writeSymbol(array, T, .exports);
            writeStructClose(array);
        },
        .hybrid => {
            writeSymbol(array, T, .wrappers);
            writeSymbol(array, T, .ptr_vars_export);
            writeLoadSignature(array);
            writeSymbol(array, T, .load_assign_export);
            writeIfClose(array);
            writeExportLoad(array);
        },
        .autoloader => {
            writeSymbol(array, T, .ptr_fields_source);
            writeLoadSignature(array);
            writeSymbol(array, T, .load_assign_source);
            writeIfClose(array);
            writeExportLoad(array);
        },
    }
}
fn writeCommandCoreLibrary(array: *Array, comptime Command: type, comptime type_name: []const u8, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeImportMach(array);
    writeGenericCommand(array, type_name);
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("types.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare(type_name, Command).type_decl,
        comptime types.ProtoTypeDescr.declare("types.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, build.GenericCommand(Command));
}
fn writeCommandExtraLibrary(array: *Array, comptime Command: type, comptime type_name: []const u8, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeImportMach(array);
    writeGenericExtraCommand(array, type_name);
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("types.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare(type_name, Command).type_decl,
        comptime types.ProtoTypeDescr.declare("types.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, build.GenericExtraCommand(Command));
}
fn writeOutCommandCoreLibrary(
    array: *Array,
    comptime mv: MajorVariant,
    comptime name: [:0]const u8,
    comptime Command: type,
    comptime type_name: []const u8,
) !void {
    try writeCommandCoreLibrary(array, Command, type_name, mv);
    try writeOut(array, mv, name);
    array.undefineAll();
}
fn writeOutCommandExtraLibrary(
    array: *Array,
    comptime mv: MajorVariant,
    comptime name: [:0]const u8,
    comptime Command: type,
    comptime type_name: []const u8,
) !void {
    try writeCommandExtraLibrary(array, Command, type_name, mv);
    try writeOut(array, mv, name);
    array.undefineAll();
}
fn writeCoreLibraries(array: *Array, comptime mv: MajorVariant) !void {
    try writeOutCommandCoreLibrary(array, mv, "build_core", build.BuildCommand, "types.BuildCommand");
    try writeOutCommandCoreLibrary(array, mv, "format_core", build.FormatCommand, "types.FormatCommand");
    try writeOutCommandCoreLibrary(array, mv, "objcopy_core", build.ObjcopyCommand, "types.ObjcopyCommand");
    try writeOutCommandCoreLibrary(array, mv, "archive_core", build.ArchiveCommand, "types.ArchiveCommand");
    try writeOutCommandCoreLibrary(array, mv, "tblgen_core", build.TableGenCommand, "types.TableGenCommand");
    try writeOutCommandCoreLibrary(array, mv, "harec_core", build.HarecCommand, "types.HarecCommand");
}
fn writeExtraLibraries(array: *Array, comptime mv: MajorVariant) !void {
    try writeOutCommandExtraLibrary(array, mv, "build_extra", build.BuildCommand, "types.BuildCommand");
    try writeOutCommandExtraLibrary(array, mv, "format_extra", build.FormatCommand, "types.FormatCommand");
    try writeOutCommandExtraLibrary(array, mv, "objcopy_extra", build.ObjcopyCommand, "types.ObjcopyCommand");
    try writeOutCommandExtraLibrary(array, mv, "archive_extra", build.ArchiveCommand, "types.ArchiveCommand");
}
fn writeOut(array: *Array, comptime mv: MajorVariant, comptime name: [:0]const u8) !void {
    if (true or config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile(name ++ switch (mv) {
            .hybrid => ".hyld.zig",
            .autoloader => ".auto.zig",
            .library => ".dl.zig",
        }), array.readAll());
        array.undefineAll();
    } else {
        debug.write(array.readAll());
    }
}
fn writeLoadFromSourcesInternal(
    array: *Array,
    comptime ST: type,
    comptime field_name: []const u8,
    comptime field_source_names: Fields(meta.Field(ST, field_name)),
) void {
    const MF = meta.Field(ST, field_name);
    switch (@typeInfo(MF)) {
        else => {
            array.writeMany(" = ");
            array.writeMany(field_name);
        },
        .Struct => |struct_info| {
            array.writeMany("=.{\n");
            inline for (struct_info.fields) |field| {
                array.writeMany("." ++ field.name);
                if (@typeInfo(Fields(MF)) == .Struct) {
                    writeLoadFromSourcesInternal(array, MF, field.name, @field(field_source_names, field.name));
                } else {
                    array.writeMany("=" ++ field_source_names ++ "." ++ field.name);
                }
                array.writeMany(",\n");
            }
            array.writeMany("}");
        },
    }
}
fn Fields(comptime FunctionPointers: type) type {
    var struct_fields: []const builtin.Type.StructField = &.{};
    inline for (@typeInfo(FunctionPointers).Struct.fields) |field| {
        if (@typeInfo(field.type) == .Struct) {
            struct_fields = struct_fields ++ .{meta.structField(Fields(field.type), field.name, null)};
        } else {
            return []const u8;
        }
    }
    return @Type(meta.structInfo(.Auto, struct_fields));
}
fn writeLoadFromSources(
    array: *Array,
    comptime ST: type,
    comptime field_name: [:0]const u8,
    comptime field_source_names: Fields(meta.Field(ST, field_name)),
) !void {
    array.writeMany("const zl= @import(\"zl\");\n");
    array.writeMany("pub usingnamespace zl.start;\n");
    array.writeMany("export fn load(fp: *");
    array.writeMany("zl.builtin.root.Builder.FunctionPointers");
    array.writeMany(")void{\n");
    array.writeMany("fp." ++ field_name);
    writeLoadFromSourcesInternal(array, ST, field_name, field_source_names);
    array.writeMany(";\n");
    array.writeMany("}\n");
    try writeOut(array, MajorVariant.autoloader, field_name);
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    const array: *common.Array = allocator.create(common.Array);
    const FunctionPointers = build.GenericBuilder(.{}).FunctionPointers;
    try writeLoadFromSources(array, FunctionPointers, "about", .{
        .elf = "zl.builtin.root.Builder.DynamicLoader.about",
        .perf = "zl.builtin.root.Builder.PerfEvents",
        .generic = "zl.builtin.root.Builder.about",
    });
    try writeLoadFromSources(array, FunctionPointers, "build", "zl.build.GenericCommand(zl.build.BuildCommand)");
    try writeLoadFromSources(array, FunctionPointers, "format", "zl.build.GenericCommand(zl.build.FormatCommand)");
    try writeLoadFromSources(array, FunctionPointers, "archive", "zl.build.GenericCommand(zl.build.ArchiveCommand)");
    try writeLoadFromSources(array, FunctionPointers, "objcopy", "zl.build.GenericCommand(zl.build.ObjcopyCommand)");
}
