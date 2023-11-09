const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const meta = @import("../../meta.zig");
const math = @import("../../math.zig");
const debug = @import("../../debug.zig");
const decls = @import("../decls.zig");
const config = @import("config.zig");
pub const Array = mem.array.StaticString(64 * 1024 * 1024);
pub const ArrayGST = mem.array.StaticString(1024 * 1024);
const prefer_gst = false;
const GST = struct {
    array: *ArrayGST,
    max_end_bits: u16,
    max_len_bits: u16,
    max_off_bits: u16,
};
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
                array.writeFormat(fmt.ux64(pair.value >> @intCast(shr_amt)));
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
        fn formatWriteFormatWriteFunction(format: Format, array: *Array, gst: GST) void {
            const unit: usize = 1;
            var shr_amt: usize = 0;
            var shl_rem: usize = 0;
            var enum_idx: usize = 0;
            if (isEnum(format)) return;
            if (prefer_gst) {
                for (format.value.sets, 0..) |set, idx| {
                    if (set.tag == .E) {
                        continue;
                    }
                    array.writeMany("const set");
                    array.writeFormat(fmt.ud64(idx));
                    array.writeMany("=[_]u");
                    array.writeFormat(fmt.ud64(meta.unsignedRealBitSize(unit << @truncate(8 +% gst.max_end_bits +% gst.max_off_bits))));
                    array.writeMany("{");
                    for (set.pairs) |pair| {
                        if (pair.value == 0) {
                            continue;
                        }
                        shl_rem = @ctz(pair.value) -% shr_amt;
                        shr_amt +%= shl_rem;
                        const name: []const u8 = pair.field_name orelse pair.decl_name;
                        var off: usize = mem.indexOfFirstEqualMany(u8, name, gst.array.readAll()).?;
                        var end: usize = off +% name.len;
                        const shl_shl: usize = shl_rem << @truncate(gst.max_end_bits +% gst.max_off_bits);
                        const end_shl: usize = end << @truncate(gst.max_off_bits);
                        const off_shl: usize = off;
                        const com: usize = shl_shl | end_shl | off_shl;
                        end = (com >> @truncate(gst.max_off_bits)) & ((unit << @truncate(gst.max_end_bits)) -% 1);
                        off = com & ((unit << @truncate(gst.max_off_bits)) -% 1);
                        array.writeFormat(fmt.ux64(com));
                        array.writeMany(",");
                        array.writeMany("// shl=");
                        array.writeFormat(fmt.ud64(shl_rem));
                        array.writeMany(", end=");
                        array.writeFormat(fmt.ud64(end));
                        array.writeMany(", off=");
                        array.writeFormat(fmt.ud64(off));
                        array.writeMany(" => ");
                        array.writeMany(gst.array.readAll()[off..end]);
                        array.writeMany("\n");
                    }
                    array.writeMany("\n};\n");
                }
            }
            array.writeMany("pub fn formatWriteBuf(format:@This(),buf:[*]u8)usize{\n");
            array.writeMany("@setRuntimeSafety(false);\n");
            array.writeMany("var tmp:");
            array.writeMany(@typeName(backing_integer));
            array.writeMany("=@bitCast(format);\n");
            array.writeMany("if(tmp==0) return 0;");
            array.writeMany("buf[0..6].*=\"flags=\".*;\n");
            array.writeMany("var len:usize=6;\n");
            shr_amt = 0;
            shl_rem = 0;
            enum_idx = 0;
            for (format.value.sets, 0..) |set, idx| {
                if (set.tag == .E) {
                    array.writeMany("len+=fmt.strcpy(buf+len,@tagName(format.");
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
                    if (prefer_gst) {
                        array.writeMany("for(set");
                        array.writeFormat(fmt.ud64(idx));
                        array.writeMany(")|val|{\n");
                        array.writeMany("tmp>>=@truncate(val>>");
                        array.writeFormat(fmt.ud64(gst.max_end_bits +% gst.max_off_bits));
                        array.writeMany(");\n");
                        array.writeMany("if(tmp&1!=0){\n");
                        array.writeMany("buf[len]=',';\n");
                        array.writeMany("len+%=@intFromBool(len!=6);\n");
                        array.writeMany("len+%=fmt.strcpy(buf+len,gst[val&");
                        array.writeFormat(fmt.ux64((unit << @truncate(gst.max_off_bits)) -% 1));
                        array.writeMany("..(val>>");
                        array.writeFormat(fmt.ud64(gst.max_off_bits));
                        array.writeMany(")&");
                        array.writeFormat(fmt.ux64((unit << @truncate(gst.max_end_bits)) -% 1));
                        array.writeMany("]);\n");
                        array.writeMany("}\n");
                    } else {
                        array.writeMany("for([_]struct{[]const u8,u8}{\n");
                        var start: usize = array.len();
                        for (set.pairs, 0..) |pair, item| {
                            const name: []const u8 = pair.field_name orelse pair.decl_name;
                            if (pair.value == 0) {
                                continue;
                            }
                            if (item == math.sqrt(usize, set.pairs.len) +% 1 and (array.len() -% start) > 1080) {
                                array.writeMany(",\n");
                                start = array.len();
                            } else if (array.len() != start) {
                                array.writeOne(',');
                            }
                            shl_rem = @ctz(pair.value) -% shr_amt;
                            shr_amt +%= shl_rem;
                            array.writeMany(".{");
                            array.writeFormat(fmt.stringLiteral(name));
                            array.writeMany(",");
                            array.writeFormat(fmt.udsize(shl_rem));
                            array.writeMany("}");
                        }
                        array.writeMany(",})|pair|{\n");
                        array.writeMany("tmp>>=@truncate(pair[1]);\n");
                        array.writeMany("if(tmp&1!=0){\n");
                        array.writeMany("buf[len]=',';\n");
                        array.writeMany("len+=@intFromBool(len!=6);\n");
                        array.writeMany("len+=fmt.strcpy(buf+len,pair[0]);\n");
                        array.writeMany("}\n");
                    }
                    array.writeMany("}\n");
                    shr_amt +%= shl_rem +% 1;
                }
            }
            array.writeMany("return len;\n");
            array.writeMany("}\n");
        }
        fn formatWriteFormatLengthFunction(format: Format, array: *Array, gst: GST) void {
            const unit: usize = 1;
            var shr_amt: usize = 0;
            var shl_rem: usize = 0;
            if (isEnum(format)) return;
            array.writeMany("pub fn formatLength(format:@This())usize{\n");
            array.writeMany("@setRuntimeSafety(false);\n");
            array.writeMany("if(@as(" ++ @typeName(backing_integer) ++ ",@bitCast(format))==0) return 0;");
            array.writeMany("var len:usize=6;\n");
            for (format.value.sets, 0..) |set, idx| {
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
                    if (prefer_gst) {
                        array.writeMany("for(set");
                        array.writeFormat(fmt.ud64(idx));
                        array.writeMany(")|val|{\n");
                        array.writeMany("tmp>>=@truncate(val>>");
                        array.writeFormat(fmt.ud64(gst.max_end_bits +% gst.max_off_bits));
                        array.writeMany(");\n");
                        array.writeMany("if(tmp&1!=0){\n");
                        if (gst.max_end_bits == gst.max_off_bits) {
                            array.writeMany("len=");
                            array.writeMany("((val>>");
                            array.writeFormat(fmt.ud64(gst.max_off_bits));
                            array.writeMany(")-%val)&");
                            array.writeFormat(fmt.ux64((unit << @truncate(gst.max_off_bits)) -% 1));
                            array.writeMany(" + @intFromBool(len!=0);\n");
                        } else {
                            array.writeMany("len=");
                            array.writeMany("(val>>");
                            array.writeFormat(fmt.ud64(gst.max_off_bits));
                            array.writeMany(")&");
                            array.writeFormat(fmt.ux64((unit << @truncate(gst.max_end_bits)) -% 1));
                            array.writeMany(")-%(val&");
                            array.writeFormat(fmt.ux64((unit << @truncate(gst.max_off_bits)) -% 1));
                            array.writeMany(" + @intFromBool(len!=0);\n");
                        }
                        array.writeMany("}\n");
                    } else {
                        array.writeMany("for([_]struct{u8,u8}{\n");
                        var start: usize = array.len();
                        for (set.pairs, 0..) |pair, item| {
                            if (pair.value == 0) {
                                continue;
                            }
                            if (item == math.sqrt(usize, set.pairs.len) +% 1) {
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
                    }
                    shr_amt +%= shl_rem +% 1;
                    array.writeMany("}\n");
                }
            }
            array.writeMany("return len;\n");
            array.writeMany("}\n");
        }
        fn defineGlobalStringTable(format: Format, array: *ArrayGST) usize {
            var max: usize = 0;
            for (format.value.sets) |set| {
                for (set.pairs) |pair| {
                    const name: []const u8 = pair.field_name orelse pair.decl_name;
                    if (!mem.testEqualManyIn(u8, name, array.readAll())) {
                        max = @max(max, name.len);
                        array.writeMany(name);
                    }
                }
            }
            return max;
        }

        fn isEnum(format: Format) bool {
            return format.value.sets.len == 1 and
                format.value.sets[0].tag == .E;
        }
        pub fn formatWrite(format: Format, array: *Array, gst: GST) void {
            array.writeMany("pub const ");
            array.writeMany(format.value.type_name);
            if (isEnum(format)) {
                array.writeMany("=enum(" ++ @typeName(backing_integer) ++ "){\n");
                writeEnumField(array, format.value.sets[0], 0);
            } else {
                array.writeMany("=packed struct(" ++ @typeName(backing_integer) ++ "){\n");
                format.formatWriteFields(array);
            }
            format.formatWriteFormatWriteFunction(array, gst);
            format.formatWriteFormatLengthFunction(array, gst);
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
    var gst_array: *ArrayGST = allocator.create(ArrayGST);
    flags_array.define(try gen.readFile(.{ .return_type = usize }, config.flags_template_path, flags_array.referAllUndefined()));
    decls_array.define(try gen.readFile(.{ .return_type = usize }, config.decls_template_path, decls_array.referAllUndefined()));
    extra_array.define(try gen.readFile(.{ .return_type = usize }, config.extra_template_path, extra_array.referAllUndefined()));
    var max_len: usize = 0;
    inline for (@typeInfo(decls).Struct.decls) |decl| {
        const value = @field(decls, decl.name);
        const size = if (@hasDecl(value, "backing_integer")) value.backing_integer else usize;
        const Format = ContainerDeclsToBitFieldFormat(size);
        const format: Format = Format.init(value, decl.name);
        max_len = @max(max_len, format.defineGlobalStringTable(gst_array));
    }
    var gst: GST = .{
        .array = gst_array,
        .max_len_bits = meta.unsignedRealBitSize(max_len),
        .max_off_bits = meta.unsignedRealBitSize(gst_array.len()),
        .max_end_bits = meta.unsignedRealBitSize(gst_array.len() +% max_len),
    };
    inline for (@typeInfo(decls).Struct.decls) |decl| {
        const value = @field(decls, decl.name);
        const size = if (@hasDecl(value, "backing_integer")) value.backing_integer else usize;
        const Format = ContainerDeclsToBitFieldFormat(size);
        const format: Format = Format.init(value, decl.name);
        format.formatWrite(flags_array, gst);
        format.formatWriteDecls(decls_array);
        format.formatWriteExtra(extra_array);
    }
    if (prefer_gst) {
        flags_array.writeMany("const gst:[");
        flags_array.writeFormat(fmt.ud64(gst_array.len()));
        flags_array.writeMany("]u8=.{\n");
        for (gst_array.readAll(), 0..) |val, idx| {
            flags_array.writeFormat(fmt.ux64(val));
            if (idx == 15) {
                flags_array.writeMany(",\n");
            } else {
                flags_array.writeMany(",");
            }
        }
        flags_array.writeMany("};\n");
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
fn castTable(comptime T: type, gst_array: *ArrayGST) []T {
    const bytes: [*]u8 = gst_array.referAllDefined().ptr;
    const values: [*]T = @ptrCast(@alignCast(bytes));
    return values[0..@divExact(gst_array.len(), @sizeOf(T))];
}
