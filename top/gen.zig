const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
pub const ListKind = enum {
    Parameter,
    Argument,
};
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
};
pub const DeclList = struct {
    decls: [24][:0]const u8,
    len: u8,
    pub fn writeOne(decl_list: *DeclList, symbol: [:0]const u8) void {
        decl_list.decls[decl_list.len] = symbol;
        decl_list.len +%= 1;
    }
    pub fn readAll(decl_list: *const DeclList) []const [:0]const u8 {
        return decl_list.decls[0..decl_list.len];
    }
    pub fn have(decl_list: *const DeclList, symbol: [:0]const u8) bool {
        for (decl_list.readAll()) |decl| {
            if (decl.ptr == symbol.ptr) {
                return true;
            }
        }
        return false;
    }
};
pub fn truncateFile(comptime write_spec: file.WriteSpec, pathname: [:0]const u8, buf: []const write_spec.child) void {
    const fd: u64 = file.create(spec.create.truncate_noexcept, pathname, file.mode.regular);
    defer file.close(spec.generic.noexcept, fd);
    file.write(write_spec, fd, buf);
}
pub fn appendFile(comptime write_spec: file.WriteSpec, pathname: [:0]const u8, buf: []const write_spec.child) void {
    const fd: u64 = file.open(spec.open.append_noexcept, pathname);
    defer file.close(spec.generic.noexcept, fd);
    file.write(write_spec, fd, buf);
}
pub fn readFile(comptime read_spec: file.ReadSpec, pathname: [:0]const u8, buf: []read_spec.child) u64 {
    const fd: u64 = file.open(spec.open.append_noexcept, pathname);
    defer file.close(spec.generic.noexcept, fd);
    return file.read(read_spec, fd, buf);
}
pub fn containerDeclsToBitField(comptime Container: type, comptime backing_integer: type, type_name: []const u8) void {
    const ShiftAmount = builtin.ShiftAmount(backing_integer);
    const bit_field_sets: []const meta.GenericBitFieldSet(backing_integer) =
        comptime meta.containerDeclsToBitFieldSets(Container, backing_integer);
    const size_name: []const u8 = @typeName(backing_integer);
    var array: mem.StaticString(1024 *% 1024) = undefined;
    array.undefineAll();
    var bits: u16 = 0;
    var diff: u16 = 0;
    var enum_count: u16 = 0;
    array.writeMany("const ");
    array.writeMany(type_name);
    array.writeMany("=packed struct(" ++ size_name ++ "){\n");
    for (bit_field_sets) |set| {
        if (set.tag == .E) {
            var value: backing_integer = 0;
            for (set.pairs) |pair| {
                value |= pair.value;
            }
            const bit_size_of_enum: u16 = @bitSizeOf(backing_integer) -% (@clz(value) +% @ctz(value));
            const shift_amt: ShiftAmount = meta.bitCast(ShiftAmount, bits);
            array.writeOne('e');
            array.writeFormat(fmt.ud16(enum_count));
            array.writeMany(":enum(u");
            array.writeFormat(fmt.id64(bit_size_of_enum));
            array.writeMany("){\n");
            for (set.pairs) |pair| {
                array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                array.writeMany("=");
                array.writeFormat(fmt.ud64(pair.value >> shift_amt));
                array.writeMany(",\n");
            }
            array.writeMany("},\n");
            bits +%= bit_size_of_enum;
            enum_count +%= 1;
        } else {
            for (set.pairs) |pair| {
                if (pair.value != 0) {
                    diff = ((@bitSizeOf(backing_integer) -% @clz(pair.value)) -% 1) -% bits;
                    if (diff >= 1) {
                        array.writeMany("zb");
                        array.writeFormat(fmt.ud16(bits));
                        array.writeMany(":u");
                        array.writeFormat(fmt.ud16(diff));
                        array.writeMany("=0,\n");
                    }
                    array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                    array.writeMany(":bool=false,\n");
                    bits +%= diff +% 1;
                }
            }
        }
    }
    diff = @bitSizeOf(backing_integer) -% bits;
    if (diff >= 1) {
        array.writeMany("zb");
        array.writeFormat(fmt.ud16(bits));
        array.writeMany(":u");
        array.writeFormat(fmt.ud16(diff));
        array.writeMany("=0,\n");
    }
    array.writeMany("fn assert(flags:@This(),val:" ++ size_name ++ ")void{\nbuiltin.assertEqual(" ++ size_name ++ ", @bitCast(" ++ size_name ++ ",flags)==val);\n}\n");
    array.writeMany("comptime{\n");
    enum_count = 0;
    for (bit_field_sets) |set| {
        if (set.tag == .E) {
            var value: backing_integer = 0;
            for (set.pairs) |pair| {
                value |= pair.value;
            }
            for (set.pairs) |pair| {
                array.writeMany("assert(.{.");
                array.writeOne('e');
                array.writeFormat(fmt.ud16(enum_count));
                array.writeMany("=.");
                array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                array.writeMany("},");
                array.writeFormat(fmt.uxsize(pair.value));
                array.writeMany(");\n");
            }
            enum_count +%= 1;
        } else {
            for (set.pairs) |pair| {
                if (pair.value != 0) {
                    array.writeMany("assert(.{.");
                    array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                    array.writeMany("=true},");
                    array.writeFormat(fmt.uxsize(pair.value));
                    array.writeMany(");\n");
                }
            }
        }
    }
    array.writeMany("}\n");
    array.writeMany("};\n");
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
