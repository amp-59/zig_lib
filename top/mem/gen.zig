const top = @import("../../zig_lib.zig");
const fmt = top.fmt;
const mem = top.mem;
const meta = top.meta;
const file = top.file;
const serial = top.serial;
const spec = top.spec;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace top;

const tok = @import("./tok.zig");

const open_read_spec: file.OpenSpec = .{
    .errors = .{},
    .options = .{ .read = true, .write = null },
};
const stat_spec: file.StatusSpec = .{
    .errors = .{},
};

const close_spec: file.CloseSpec = .{
    .errors = .{},
};
const read_spec: file.ReadSpec = .{
    .errors = .{},
};
const write_spec: file.WriteSpec = .{
    .logging = .{},
    .errors = .{},
};

pub const ProtoTypeDescrFormat = fmt.GenericTypeDescrFormat(.{
    .options = .{ .default_field_values = true },
});

pub fn writeGenerator(array: anytype, src: builtin.SourceLocation) void {
    array.writeMany("//! This file is generated by ");
    array.writeMany(src.file);
    array.writeMany("\n");
}
pub fn readFile(array: anytype, pathname: [:0]const u8) !void {
    const fd: u64 = try file.open(.{}, pathname);
    array.define(try file.readSlice(.{}, fd, array.referAllUndefined()));
}
pub fn writeFieldOfBool(array: anytype, any: anytype) void {
    inline for (@typeInfo(@TypeOf(any)).Struct.fields) |field| {
        if (@field(any, field.name)) {
            array.writeMany(comptime fmt.static.toTitlecase(field.name));
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
                    fmt.ud64(@field(format, field.name)).formatWrite(array);
                    array.writeMany(tok.end_elem);
                } else {
                    array.writeMany("." ++ field.name ++ "=.");
                    array.writeMany(@tagName(@field(format, field.name)));
                    array.writeMany(tok.end_elem);
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
