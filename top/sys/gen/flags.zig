const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const meta = @import("../../meta.zig");
const debug = @import("../../debug.zig");
const decls = @import("../decls.zig");
const config = @import("./config.zig");

pub const Array = mem.StaticString(64 * 1024 * 1024);

pub usingnamespace @import("../../start.zig");

pub fn ContainerDeclsToBitFieldFormat(comptime backing_integer: type) type {
    const T = struct {
        value: Value,
        const Format = @This();
        const Value = struct { type_name: []const u8, sets: []const BitFieldSet };
        const BitFieldSet = meta.GenericBitFieldSet(backing_integer);
        const bit_size_of: comptime_int = @bitSizeOf(backing_integer);

        fn bitSizeOfEnum(set: BitFieldSet) u16 {
            var value: backing_integer = 0;
            for (set.pairs) |pair| {
                value |= pair.value;
            }
            return bit_size_of -% (@clz(value) +% @ctz(value));
        }
        fn bitSizeOfFields(set: BitFieldSet, bit_offset: u16) u16 {
            var diff: u16 = 0;
            for (set.pairs) |pair| {
                if (pair.value != 0) {
                    diff = ((bit_size_of -% @clz(pair.value)) -% 1) -% bit_offset;
                }
            }
            return diff +% 1;
        }
        fn writeEnumField(array: *Array, set: BitFieldSet, shr_amt: usize) void {
            for (set.pairs) |pair| {
                array.writeFormat(fmt.lazyIdentifier(pair.field_name orelse pair.decl_name));
                array.writeMany("=");
                array.writeFormat(fmt.ud64(pair.value >> @intCast(shr_amt)));
                array.writeMany(",\n");
            }
        }
        fn writeEnumFields(array: *Array, set: BitFieldSet, shr_amt: usize) usize {
            const bit_size_of_enum: u16 = bitSizeOfEnum(set);
            array.writeFormat(fmt.lazyIdentifier(set.name.?));
            array.writeMany(":enum(u");
            array.writeFormat(fmt.id64(bit_size_of_enum));
            array.writeMany("){\n");
            writeEnumField(array, set, shr_amt);
            array.writeMany("}");
            for (set.pairs) |pair| {
                if (pair.default_value) {
                    array.writeMany("=.");
                    array.writeFormat(fmt.lazyIdentifier(pair.field_name orelse pair.decl_name));
                    break array.writeOne(',');
                }
            } else {
                array.writeMany(",\n");
            }
            return bit_size_of_enum;
        }
        fn formatWriteFields(format: Format, array: *Array) void {
            var shr_amt: usize = 0;
            var shl_rem: usize = 0;
            for (format.value.sets) |set| {
                if (set.tag == .E) {
                    shr_amt +%= writeEnumFields(array, set, shr_amt);
                } else {
                    for (set.pairs) |pair| {
                        if (pair.value != 0) {
                            shl_rem = (bit_size_of -% 1) -% (@clz(pair.value) +% shr_amt);
                            writeZeroBits(array, shr_amt, shl_rem);
                            array.writeFormat(fmt.lazyIdentifier(pair.field_name orelse pair.decl_name));
                            array.writeMany(":bool=");
                            array.writeFormat(fmt.any(pair.default_value));
                            array.writeMany(",\n");
                            shr_amt +%= shl_rem +% 1;
                        }
                    }
                }
            }
            writeZeroBits(array, shr_amt, bit_size_of -% shr_amt);
        }
        fn writeZeroBits(array: *Array, shr_amt: usize, shl_rem: usize) void {
            if (shl_rem >= 1 and
                shl_rem < bit_size_of)
            {
                array.writeMany("zb");
                array.writeFormat(fmt.udsize(shr_amt));
                array.writeMany(":u");
                array.writeFormat(fmt.udsize(shl_rem));
                array.writeMany("=0,\n");
            }
        }
        fn formatWriteDefaultValues(format: Format, array: *Array) void {
            const save: usize = array.len();
            array.writeMany("pub const default_values=struct{\n");
            const start: usize = array.len();
            for (format.value.sets) |set| {
                for (set.pairs) |pair| {
                    array.writeMany("pub const ");
                    array.writeFormat(fmt.lazyIdentifier(pair.decl_name));
                    array.writeMany("=");
                    array.writeFormat(fmt.any(pair.default_value));
                    array.writeMany(";\n");
                }
            }
            if (array.len() == start) {
                array.undefine(start -% save);
            } else {
                array.writeMany("};\n");
            }
        }
        fn formatWriteSetNames(format: Format, array: *Array) void {
            const save: usize = array.len();
            array.writeMany("pub const set_names=.{\n");
            const start: usize = array.len();
            for (format.value.sets) |set| {
                if (set.name) |name| {
                    array.writeFormat(fmt.stringLiteral(name));
                    array.writeMany(",");
                }
            }
            if (array.len() == start) {
                array.undefine(start -% save);
            } else {
                array.writeMany("};\n");
            }
        }
        fn formatWriteDestNames(format: Format, array: *Array) void {
            const save: usize = array.len();
            array.writeMany("pub const field_names=struct{\n");
            const start: usize = array.len();
            for (format.value.sets) |set| {
                for (set.pairs) |pair| {
                    if (pair.field_name) |name| {
                        array.writeMany("pub const ");
                        array.writeFormat(fmt.lazyIdentifier(pair.decl_name));
                        array.writeMany("=");
                        array.writeFormat(fmt.any(name));
                        array.writeMany(";\n");
                    }
                }
            }
            if (array.len() == start) {
                array.undefine(start -% save);
                array.writeMany("const _field_names=struct{\n");
                for (format.value.sets) |set| {
                    for (set.pairs) |pair| {
                        array.writeMany("pub const ");
                        array.writeFormat(fmt.lazyIdentifier(pair.decl_name));
                        array.writeMany("=\\\\");
                        array.writeFormat(fmt.lowerCase(pair.decl_name));
                        array.writeMany("\n;\n");
                    }
                }
            }
            array.writeMany("};\n");
        }
        fn formatWriteValues(format: Format, array: *Array) void {
            for (format.value.sets) |set| {
                for (set.pairs) |pair| {
                    array.writeMany("pub const ");
                    array.writeFormat(fmt.lazyIdentifier(pair.decl_name));
                    array.writeMany("=");
                    array.writeFormat(fmt.any(pair.value));
                    array.writeMany(";\n");
                }
            }
        }
        pub fn formatWriteDecls(format: Format, array: *Array) void {
            array.writeMany("pub const ");
            array.writeFormat(fmt.lazyIdentifier(format.value.type_name));
            array.writeMany("=struct{\n");
            format.formatWriteValues(array);
            array.writeMany("pub usingnamespace extra.");
            array.writeFormat(fmt.lazyIdentifier(format.value.type_name));
            array.writeMany(";\n");
            array.writeMany("};\n");
        }
        pub fn formatWriteExtra(format: Format, array: *Array) void {
            array.writeMany("pub const ");
            array.writeFormat(fmt.lazyIdentifier(format.value.type_name));
            array.writeMany("=struct{\n");
            format.formatWriteDefaultValues(array);
            format.formatWriteDestNames(array);
            format.formatWriteSetNames(array);
            array.writeMany("pub const backing_integer = " ++ @typeName(backing_integer) ++ ";\n");
            array.writeMany("};\n");
        }
        fn formatWriteAssertions(format: Format, array: *Array) void {
            array.writeMany("fn assert(flags:@This(),val:");
            array.writeMany(@typeName(backing_integer));
            array.writeMany(")void{\ndebug.assertEqual(");
            array.writeMany(@typeName(backing_integer));
            array.writeMany(",@as(");
            array.writeMany(@typeName(backing_integer));
            array.writeMany(",@bitCast(flags)),val);\n}\n");
            array.writeMany("comptime{if(builtin.comptime_assertions){\n");
            var enum_idx: usize = 0;
            for (format.value.sets) |set| {
                if (set.tag == .E) {
                    var value: backing_integer = 0;
                    for (set.pairs) |pair| {
                        value |= pair.value;
                    }
                    for (set.pairs) |pair| {
                        array.writeMany("assert(.{.");
                        if (set.name) |name| {
                            array.writeFormat(fmt.lazyIdentifier(name));
                        } else {
                            array.writeOne('e');
                            array.writeFormat(fmt.udsize(enum_idx));
                        }
                        array.writeMany("=.");
                        array.writeFormat(fmt.lazyIdentifier(pair.field_name orelse pair.decl_name));
                        array.writeMany("},");
                        array.writeFormat(fmt.uxsize(pair.value));
                        array.writeMany(");\n");
                    }
                    enum_idx +%= 1;
                } else {
                    for (set.pairs) |pair| {
                        if (pair.value != 0) {
                            array.writeMany("assert(.{.");
                            array.writeFormat(fmt.lazyIdentifier(pair.field_name orelse pair.decl_name));
                            array.writeMany("=true},");
                            array.writeFormat(fmt.uxsize(pair.value));
                            array.writeMany(");\n");
                        }
                    }
                }
            }
            array.writeMany("}\n}\n");
        }
        fn formatWriteFormatWriteFunction(format: Format, array: *Array) void {
            array.writeMany("pub fn formatWriteBuf(format:@This(),buf:[*]u8)usize{\n");
            array.writeMany("var ptr:[*]u8=buf;\n");
            var shr_amt: usize = 0;
            var shl_rem: usize = 0;
            var enum_idx: usize = 0;
            for (format.value.sets) |set| {
                if (set.tag == .E) {
                    array.writeMany("ptr=fmt.strcpyEqu(ptr,@tagName(format.");
                    if (set.name) |name| {
                        array.writeFormat(fmt.lazyIdentifier(name));
                    } else {
                        array.writeOne('e');
                        array.writeFormat(fmt.udsize(enum_idx));
                    }
                    array.writeMany("));\n");
                    enum_idx +%= 1;
                } else {
                    for (set.pairs) |pair| {
                        if (pair.value != 0) break;
                    } else {
                        continue;
                    }
                    if (shr_amt == 0) {
                        array.writeMany("var tmp:");
                        array.writeMany(@typeName(backing_integer));
                        array.writeMany("=@bitCast(format);\n");
                    }
                    array.writeMany("for([_]struct{[]const u8,u8}{\n");
                    var start: usize = array.len();
                    for (set.pairs) |pair| {
                        if (pair.value == 0) {
                            continue;
                        }
                        if (array.len() -% start > 60) {
                            array.writeMany(",\n");
                            start = array.len();
                        } else if (array.len() != start) {
                            array.writeOne(',');
                        }
                        shl_rem = @ctz(pair.value) -% shr_amt;
                        shr_amt +%= shl_rem;
                        array.writeMany(".{");
                        array.writeFormat(fmt.stringLiteral(pair.decl_name));
                        array.writeMany(",");
                        array.writeFormat(fmt.udsize(shl_rem));
                        array.writeMany("}");
                    }
                    array.writeMany(",})|pair|{\n");
                    array.writeMany("tmp>>=@truncate(pair[1]);\n");
                    array.writeMany("if(tmp&1!=0){\n");
                    array.writeMany("ptr[0]='|';\n");
                    array.writeMany("ptr=fmt.strcpyEqu(ptr+@intFromBool(ptr!=buf),pair[0]);\n");
                    array.writeMany("}\n");
                    shr_amt +%= shl_rem +% 1;
                    array.writeMany("}\n");
                }
            }
            array.writeMany("return fmt.strlen(ptr,buf);\n");
            array.writeMany("}\n");
        }
        fn formatWriteFormatLengthFunction(format: Format, array: *Array) void {
            array.writeMany("pub fn formatLength(format:@This())usize{\n");
            array.writeMany("var len:usize=0;\n");
            var shr_amt: usize = 0;
            var shl_rem: usize = 0;
            for (format.value.sets) |set| {
                if (set.tag == .E) {
                    array.writeMany("len+%=@tagName(format.");
                    array.writeFormat(fmt.lazyIdentifier(set.name.?));
                    array.writeMany(").len;\n");
                } else {
                    for (set.pairs) |pair| {
                        if (pair.value != 0) break;
                    } else {
                        continue;
                    }
                    if (shr_amt == 0) {
                        array.writeMany("var tmp:");
                        array.writeMany(@typeName(backing_integer));
                        array.writeMany("=@bitCast(format);\n");
                    }
                    array.writeMany("for([_]struct{u8,u8}{\n");
                    var start: usize = array.len();
                    for (set.pairs) |pair| {
                        if (pair.value == 0) {
                            continue;
                        }
                        if (array.len() -% start > 60) {
                            array.writeMany(",\n");
                            start = array.len();
                        } else if (array.len() != start) {
                            array.writeOne(',');
                        }
                        shl_rem = @ctz(pair.value) -% shr_amt;
                        shr_amt +%= shl_rem;
                        array.writeMany(".{");
                        array.writeFormat(fmt.ud64(pair.decl_name.len));
                        array.writeMany(",");
                        array.writeFormat(fmt.ud64(shl_rem));
                        array.writeMany("}");
                    }
                    array.writeMany(",})|pair|{\n");
                    array.writeMany("tmp>>=@truncate(pair[1]);\n");
                    array.writeMany("if(tmp&1!=0){\n");
                    array.writeMany("len+%=@intFromBool(len!=0)+%pair[0];\n");
                    array.writeMany("}\n");
                    array.writeMany("}\n");
                    shr_amt +%= shl_rem +% 1;
                }
            }
            array.writeMany("return len;\n");
            array.writeMany("}\n");
        }
        pub fn formatWrite(format: Format, array: *Array) void {
            array.writeMany("pub const ");
            array.writeMany(format.value.type_name);

            if (format.value.sets.len == 1 and
                format.value.sets[0].tag == .E)
            {
                array.writeMany("=enum(" ++ @typeName(backing_integer) ++ "){\n");
                writeEnumField(array, format.value.sets[0], 0);
            } else {
                array.writeMany("=packed struct(" ++ @typeName(backing_integer) ++ "){\n");
                format.formatWriteFields(array);
            }
            format.formatWriteFormatWriteFunction(array);
            format.formatWriteFormatLengthFunction(array);
            array.writeMany("};\n");
        }
        pub fn init(comptime Container: type, type_name: []const u8) Format {
            return .{ .value = .{
                .type_name = type_name,
                .sets = comptime meta.containerDeclsToBitFieldSets(Container, backing_integer),
            } };
        }
    };
    return T;
}

pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    var flags_array: *Array = allocator.create(Array);
    var decls_array: *Array = allocator.create(Array);
    var extra_array: *Array = allocator.create(Array);
    flags_array.define(try gen.readFile(.{ .return_type = usize }, config.flags_template_path, flags_array.referAllUndefined()));
    decls_array.define(try gen.readFile(.{ .return_type = usize }, config.decls_template_path, decls_array.referAllUndefined()));
    extra_array.define(try gen.readFile(.{ .return_type = usize }, config.extra_template_path, extra_array.referAllUndefined()));
    inline for (@typeInfo(decls).Struct.decls) |decl| {
        const value = @field(decls, decl.name);
        const size = if (@hasDecl(value, "backing_integer")) value.backing_integer else usize;
        const Format = ContainerDeclsToBitFieldFormat(size);
        const format: Format = Format.init(value, decl.name);
        format.formatWrite(flags_array);
        format.formatWriteExtra(extra_array);
        format.formatWriteDecls(decls_array);
    }
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.flags_path, flags_array.readAll());
        try gen.truncateFile(.{ .return_type = void }, config.extra_path, extra_array.readAll());
        try gen.truncateFile(.{ .return_type = void }, config.decls_path, decls_array.readAll());
    } else {
        debug.write(flags_array.readAll());
        debug.write(extra_array.readAll());
    }
}
