const top = @import("../../zig_lib.zig");
const fmt = top.fmt;
const mem = top.mem;
const meta = top.meta;
const file = top.file;
const preset = top.preset;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace top;

const tok = @import("./tok.zig");

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
    .logging = .{},
    .errors = .{},
};

pub const TypeSpecMap = struct {
    params: type,
    specs: []const type,
    vars: type,
};
pub fn writeGenerator(array: anytype, src: builtin.SourceLocation) void {
    array.writeMany("//! This file is generated by ");
    array.writeMany(src.file);
    array.writeMany("\n");
}
pub fn writeImport(array: anytype, name: []const u8, pathname: []const u8) void {
    array.writeMany("const ");
    array.writeMany(name);
    array.writeMany("=@import(\"");
    array.writeMany(pathname);
    array.writeMany("\");\n");
}
pub fn writeSourceFile(array: anytype, comptime name: [:0]const u8) void {
    const pathname: [:0]const u8 = if (name[0] != '/') build_root ++ "/top/mem/" ++ name else name;
    const fd: u64 = file.create(create_spec, pathname);
    defer file.close(close_spec, fd);
    file.write(write_spec, fd, array.readAll());
    array.undefineAll();
}
pub fn appendSourceFile(array: anytype, comptime name: [:0]const u8) void {
    const pathname: [:0]const u8 = if (name[0] != '/') build_root ++ "/top/mem/" ++ name else name;
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
    array.define(file.read(read_spec, fd, array.referAllUndefined(), array.avail()));
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
pub fn writeField(array: anytype, name: []const u8, type_descr: fmt.TypeDescrFormat) void {
    array.writeMany(name);
    array.writeMany(":");
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
    const j1: bool = mem.testEqualManyBack(u8, tok.end_small_list_item, array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(tok.end_small_list_item);
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
        var type_name: []const u8 = "struct{";
        for (@typeInfo(T).Struct.fields) |field_field| {
            type_name = type_name ++ field_field.name ++ ":" ++ @typeName(field_field.type) ++ ",";
        }
        type_name = type_name[0 .. type_name.len - 2] ++ "}";
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
            array.writeMany(tok.period_open_brace_operator);
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                if (field.type == u8) {
                    array.writeMany("." ++ field.name ++ "=");
                    writeIndex(array, @field(format, field.name));
                    array.writeMany(tok.end_small_list_item);
                } else {
                    array.writeMany("." ++ field.name ++ "=.");
                    array.writeMany(@tagName(@field(format, field.name)));
                    array.writeMany(tok.end_small_list_item);
                }
            }
            array.overwriteManyBack(tok.close_brace_operator);
        }
    });
}
pub fn GenericKeys(comptime Key: type, comptime max_len: u64) type {
    return struct {
        values: [max_len]Key,
        len: u64,
        const Keys = @This();
        const type_info: builtin.Type = @typeInfo(Key);
        pub fn undefineAll(keys: *Keys) void {
            keys.len = 0;
        }
        pub fn writeOneUnique(keys: *Keys, value: Key) void {
            for (keys.values[0..keys.len]) |unique| {
                if (builtin.testEqual(Key, value, unique)) return;
            }
            keys.values[keys.len] = value;
            keys.len +%= 1;
        }
        pub fn init(comptime Record: type, records: []const Record) Keys {
            var keys: Keys = .{ .values = undefined, .len = 0 };
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
    kind: ListKind,
    ret: [:0]const u8,
    pub fn writeOne(arg_list: *ArgList, symbol: [:0]const u8) void {
        arg_list.args[arg_list.len] = symbol;
        arg_list.len +%= 1;
    }
    pub fn readAll(arg_list: *const ArgList) []const [:0]const u8 {
        return arg_list.args[0..arg_list.len];
    }
    pub fn comptimeField(arg_list: ArgList) bool {
        switch (arg_list.kind) {
            .Parameter => {
                if (arg_list.ret.ptr == tok.impl_type_name.ptr) {
                    return false;
                }
                for (arg_list.readAll()) |arg| {
                    if (arg.ptr == tok.impl_const_param.ptr) {
                        return false;
                    }
                    if (arg.ptr == tok.impl_param.ptr) {
                        return false;
                    }
                }
            },
            .Argument => {
                if (arg_list.ret.ptr == tok.impl_type_name.ptr) {
                    return false;
                }
                for (arg_list.readAll()) |arg| {
                    if (arg.ptr == tok.impl_name.ptr) {
                        return false;
                    }
                }
            },
        }
        return true;
    }
};
