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
const commit: bool = true;
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
const BuildCommands = build.GenericCommand(build.BuildCommand);
const FormatCommands = build.GenericCommand(build.FormatCommand);
const ObjcopyCommands = build.GenericCommand(build.ObjcopyCommand);
const ArchiveCommands = build.GenericCommand(build.ArchiveCommand);
fn writeImportBuild(array: *Array) void {
    array.writeMany("const build = @import(\"./types.zig\");\n");
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
    array.writeMany("const source = build.GenericCommand(");
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
fn writeBuildCommandLibrary(array: *Array, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.BuildCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.BuildCommand", build.BuildCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, BuildCommands);
    try writeOut(array, mv, "build");
    array.undefineAll();
}
fn writeFormatCommandLibrary(array: *Array, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.FormatCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.FormatCommand", build.FormatCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, FormatCommands);
    try writeOut(array, mv, "format");
    array.undefineAll();
}
fn writeArchiveCommandLibrary(array: *Array, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.ArchiveCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.ArchiveCommand", build.ArchiveCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, ArchiveCommands);
    try writeOut(array, mv, "archive");
    array.undefineAll();
}
fn writeObjcopyCommandLibrary(array: *Array, comptime mv: MajorVariant) !void {
    writeImportBuild(array);
    writeGenericCommand(array, "build.ObjcopyCommand");
    types.ProtoTypeDescr.scope = &.{
        comptime types.ProtoTypeDescr.declare("build.Path", build.Path).type_decl,
        comptime types.ProtoTypeDescr.declare("build.ObjcopyCommand", build.ObjcopyCommand).type_decl,
        comptime types.ProtoTypeDescr.declare("build.Allocator", build.Allocator).type_decl,
    };
    writeInternal(array, mv, ObjcopyCommands);
    try writeOut(array, mv, "objcopy");
    array.undefineAll();
}
fn writePerfEventsLibrary(array: *Array, comptime mv: MajorVariant) !void {
    const perf = @import("../perf.zig");
    array.writeMany("const source=@import(\"perf.zig\");\n");
    const fds_fmt = comptime types.ProtoTypeDescr.declare("Fds", perf.Fds);
    array.writeFormat(fds_fmt);
    types.ProtoTypeDescr.scope = &.{fds_fmt.type_decl};
    writeInternal(array, mv, perf);
    try writeOut(array, mv, "perf");
    array.undefineAll();
}
fn writeOut(array: *Array, comptime mv: MajorVariant, comptime name: [:0]const u8) !void {
    if (commit) {
        try gen.truncateFile(.{ .return_type = void }, config.primarySourceFile(name ++ switch (mv) {
            .hybrid => ".hyld.zig",
            .autoloader => ".auto.zig",
            .library => ".dl.zig",
        }), array.readAll());
    } else {
        debug.write(array.readAll());
    }
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *common.Array = allocator.create(common.Array);
    switch (MajorVariant.autoloader) {
        inline else => |variant| {
            try writeBuildCommandLibrary(array, variant);
            try writeFormatCommandLibrary(array, variant);
            try writeArchiveCommandLibrary(array, variant);
            try writeObjcopyCommandLibrary(array, variant);
            try writePerfEventsLibrary(array, variant);
        },
    }
}
