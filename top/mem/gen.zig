const top = @import("../../zig_lib.zig");
const fmt = top.fmt;
const mem = top.mem;
const meta = top.meta;
const file = top.file;
const preset = top.preset;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace top;

const build_root = @cImport({}).build_root;
pub const ListKind = enum { Parameter, Argument };

const create_spec: file.CreateSpec = .{
    .errors = .{},
    .options = .{ .write = .truncate, .exclusive = false },
};
const close_spec: file.CloseSpec = .{
    .errors = .{},
};
const open_read_spec: file.OpenSpec = .{
    .errors = .{},
    .options = .{ .read = true, .write = null },
};
const open_append_spec: file.OpenSpec = .{
    .errors = .{},
    .options = .{ .write = .append },
};
const mkdir_spec: file.MakeDirSpec = .{
    .errors = .{},
};
const read_spec: file.ReadSpec = .{
    .errors = .{},
};
const write_spec: file.WriteSpec = .{
    .errors = .{},
};

pub const TypeSpecMap = struct {
    params: type,
    specs: []const type,
    vars: type,
};
pub const TypeDescr = union(enum) {
    type_name: []const u8,
    type_decl: Container,
    type_refer: Reference,
    const Reference = struct { []const u8, *const TypeDescr };
    const Enumeration = struct { []const u8, []const Decl };
    const Composition = struct { []const u8, []const Field };
    const Decl = struct { []const u8, u64 };
    const Field = struct { []const u8, TypeDescr };
    const Container = union(enum) {
        Enumeration: Enumeration,
        Composition: Composition,
    };
    pub fn formatWrite(type_descr: TypeDescr, array: anytype) void {
        switch (type_descr) {
            .type_name => |type_name| array.writeMany(type_name),
            .type_refer => |type_refer| {
                array.writeMany(type_refer[0]);
                type_refer[1].formatWrite(array);
            },
            .type_decl => |type_decl| {
                switch (type_decl) {
                    .Composition => |struct_defn| {
                        array.writeMany(struct_defn[0]);
                        array.writeMany(" { ");
                        for (struct_defn[1]) |field| {
                            array.writeMany(field[0]);
                            array.writeMany(": ");
                            field[1].formatWrite(array);
                            array.writeMany(", ");
                        }
                        array.writeMany("}");
                    },
                    .Enumeration => |enum_defn| {
                        array.writeMany(enum_defn[0]);
                        array.writeMany(" { ");
                        for (enum_defn[1]) |field| {
                            array.writeMany(field[0]);
                            array.writeMany(" = ");
                            array.writeFormat(fmt.ud64(field[1]));
                            array.writeMany(", ");
                        }
                        array.writeMany("}");
                    },
                }
            },
        }
    }
    pub fn formatLength(type_descr: TypeDescr) u64 {
        var len: u64 = 0;
        switch (type_descr) {
            .type_name => |type_name| len +%= type_name.len,
            .type_refer => |type_refer| {
                len +%= type_refer[0].len;
                len +%= type_refer[1].formatLength();
            },
            .type_decl => |type_decl| {
                switch (type_decl) {
                    .Composition => |struct_defn| {
                        len +%= struct_defn[0].len;
                        len +%= 3;
                        for (struct_defn[1]) |field| {
                            len +%= field[0].len;
                            len +%= 2;
                            len +%= field[1].formatLength();
                            len +%= 2;
                        }
                        len +%= 1;
                    },
                    .Enumeration => |enum_defn| {
                        len +%= enum_defn[0].len;
                        len +%= 3;
                        for (enum_defn[1]) |field| {
                            len +%= field[0].len;
                            len +%= 3;
                            len +%= fmt.ud64(field[1]).formatLength();
                            len +%= 2;
                        }
                        len +%= 1;
                    },
                }
            },
        }
        return len;
    }
    pub fn init(comptime T: type) TypeDescr {
        const type_info: builtin.Type = @typeInfo(T);
        switch (type_info) {
            else => return .{ .type_name = @typeName(T) },
            .Struct => |struct_info| {
                var type_decl: []const Field = &.{};
                inline for (struct_info.fields) |field| {
                    type_decl = type_decl ++ [1]Field{.{
                        field.name,
                        init(field.type),
                    }};
                }
                return .{ .type_decl = .{ .Composition = .{
                    builtin.fmt.typeDeclSpecifier(type_info),
                    type_decl,
                } } };
            },
            .Union => |union_info| {
                var type_decl: []const Field = &.{};
                inline for (union_info.fields) |field| {
                    type_decl = type_decl ++ [1]Field{.{
                        field.name,
                        init(field.type),
                    }};
                }
                return .{ .type_decl = .{ .Composition = .{
                    builtin.fmt.typeDeclSpecifier(type_info),
                    type_decl,
                } } };
            },
            .Enum => |enum_info| {
                var type_decl: []const Decl = &.{};
                inline for (enum_info.fields) |field| {
                    type_decl = type_decl ++ [1]Decl{.{
                        field.name,
                        field.value,
                    }};
                }
                return .{ .type_decl = .{ .Enum = .{
                    builtin.fmt.typeDeclSpecifier(type_info),
                    type_decl,
                } } };
            },
            .Optional => |optional_info| {
                return .{ .type_refer = .{
                    builtin.fmt.typeDeclSpecifier(type_info),
                    &init(optional_info.child),
                } };
            },
            .Pointer => |pointer_info| {
                return .{ .type_refer = .{
                    builtin.fmt.typeDeclSpecifier(type_info),
                    &init(pointer_info.child),
                } };
            },
        }
    }
};
pub fn writeGenerator(array: anytype, src: builtin.SourceLocation) void {
    array.writeMany("//! This file is generated by ");
    array.writeMany(src.file);
    array.writeMany("\n");
}
pub fn writeImport(array: anytype, name: []const u8, pathname: []const u8) void {
    array.writeMany("const ");
    array.writeMany(name);
    array.writeMany(" = @import(\"");
    array.writeMany(pathname);
    array.writeMany("\");\n");
}
pub fn writeSourceFile(array: anytype, comptime name: [:0]const u8) void {
    const pathname: [:0]const u8 = if (name[0] != '/') build_root ++ "/top/mem/" ++ name else name;
    const fd: u64 = file.create(create_spec, pathname);
    builtin.debug.write(" -> " ++ pathname ++ "\n");
    defer file.close(close_spec, fd);
    file.write(write_spec, fd, array.readAll());
    array.undefineAll();
}
pub fn appendSourceFile(array: anytype, comptime name: [:0]const u8) void {
    const pathname: [:0]const u8 = if (name[0] != '/') build_root ++ "/top/mem/" ++ name else name;
    builtin.debug.write(" >> " ++ pathname ++ "\n");
    const fd: u64 = file.open(open_append_spec, pathname);
    defer file.close(close_spec, fd);
    file.write(write_spec, fd, array.readAll());
    array.undefineAll();
}
pub fn copySourceFile(array: anytype, comptime pathname: [:0]const u8) void {
    const fd: u64 = file.open(open_read_spec, if (pathname[0] != '/')
        build_root ++ "/top/mem/" ++ pathname
    else
        pathname);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    defer file.close(close_spec, fd);
}
pub fn writeAuxiliarySourceFile(array: anytype, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    file.makeDir(mkdir_spec, zig_out_dir);
    file.makeDir(mkdir_spec, zig_out_src_dir);
    writeSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn appendAuxiliarySourceFile(array: anytype, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    file.makeDir(mkdir_spec, zig_out_dir);
    file.makeDir(mkdir_spec, zig_out_src_dir);
    appendSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn writeIndex(array: anytype, index: anytype) void {
    array.writeMany(builtin.fmt.dec(@TypeOf(index), index).readAll());
}
pub fn writeField(array: anytype, name: []const u8, type_descr: TypeDescr) void {
    array.writeMany(name);
    array.writeMany(": ");
    array.writeFormat(type_descr);
    array.writeMany(",\n");
}
pub fn groupImplementations(allocator: anytype, comptime Detail: type, comptime Index: type, group_key: []const Index, group: []const Detail) []const Detail {
    const buf: []Detail = allocator.allocateIrreversible(Detail, group_key.len);
    var impl_index: u16 = 0;
    while (impl_index != group_key.len) : (impl_index +%= 1) {
        buf[impl_index] = group[group_key[impl_index]];
    }
    return buf;
}
pub fn implLeader(comptime Detail: type, comptime Index: type, group_key: []const Index, group: []const Detail) Detail {
    return group[group_key[0]];
}
pub fn specIndex(comptime Detail: type, leader: Detail) u8 {
    return builtin.popcnt(u8, meta.leastRealBitCast(leader.specs));
}
pub fn writeComma(array: anytype) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, ", ", array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(", ");
    }
}
pub fn writeArgument(array: anytype, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
pub fn writeFieldOfBool(array: anytype, any: anytype) void {
    inline for (@typeInfo(@TypeOf(any)).Struct.fields) |field| {
        if (@field(any, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
}
pub fn simpleTypeName(comptime T: type) []const u8 {
    if (@typeInfo(T) == .Struct) {
        var type_name: []const u8 = "struct { ";
        for (@typeInfo(T).Struct.fields) |field_field| {
            type_name = type_name ++ field_field.name ++ ": " ++ @typeName(field_field.type) ++ ", ";
        }
        type_name = type_name[0 .. type_name.len - 2] ++ " }";
        return type_name;
    } else {
        return @typeName(T);
    }
}
pub fn writeStructOfEnum(array: anytype, comptime T: type, value: T) void {
    const Format = GenericStructOfEnum(T);
    Format.formatWrite(value, array);
}
fn GenericStructOfEnum(comptime Struct: type) type {
    return (struct {
        pub fn formatWrite(format: Struct, array: anytype) void {
            array.writeMany(".{ ");
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                if (field.type == u8) {
                    array.writeMany("." ++ field.name ++ " = ");
                    writeIndex(array, @field(format, field.name));
                    array.writeMany(", ");
                } else {
                    array.writeMany("." ++ field.name ++ " = .");
                    array.writeMany(@tagName(@field(format, field.name)));
                    array.writeMany(", ");
                }
            }
            array.overwriteManyBack(" }");
        }
    });
}
pub fn GenericKeys(comptime Key: type, comptime max_len: u64) type {
    return struct {
        auto: [max_len]Key,
        len: u64,
        const Keys = @This();
        const type_info: builtin.Type = @typeInfo(Key);
        fn writeOneUnique(keys: *Keys, value: Key) void {
            for (keys.auto[0..keys.len]) |unique| {
                if (builtin.testEqual(Key, value, unique)) return;
            }
            keys.auto[keys.len] = value;
            keys.len +%= 1;
        }
        pub fn init(comptime Record: type, records: []const Record) Keys {
            var keys: Keys = undefined;
            for (records) |record| {
                var key: Key = undefined;
                inline for (type_info.Struct.fields) |key_field| {
                    @field(key, key_field.name) = @field(record, key_field.name);
                }
                writeOneUnique(&keys, key);
            }
            return keys;
        }
    };
}
pub const ArgList = struct {
    args: [16][:0]const u8,
    len: u8,
    field: bool = false,
    pub fn writeOne(arg_list: *ArgList, symbol: [:0]const u8) void {
        arg_list.args[arg_list.len] = symbol;
        arg_list.len +%= 1;
    }
    pub fn readAll(arg_list: *const ArgList) []const [:0]const u8 {
        return arg_list.args[0..arg_list.len];
    }
};
