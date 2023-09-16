const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const TypeDescr = fmt.GenericTypeDescrFormat(.{});
pub const ListKind = enum {
    Parameter,
    Argument,
};
pub const ArgList = struct {
    args: [16][:0]const u8,
    args_len: u8,
    kind: ListKind,
    ret: [:0]const u8,
    pub fn writeOne(arg_list: *ArgList, symbol: [:0]const u8) void {
        arg_list.args[arg_list.args_len] = symbol;
        arg_list.args_len +%= 1;
    }
    pub fn readAll(arg_list: *const ArgList) []const [:0]const u8 {
        return arg_list.args[0..arg_list.args_len];
    }
};
pub const DeclList = struct {
    decls: [24][:0]const u8,
    decls_len: u8,
    pub fn writeOne(decl_list: *DeclList, symbol: [:0]const u8) void {
        decl_list.decls[decl_list.decls_len] = symbol;
        decl_list.decls_len +%= 1;
    }
    pub fn readAll(decl_list: *const DeclList) []const [:0]const u8 {
        return decl_list.decls[0..decl_list.decls_len];
    }
    pub fn haveElse(
        decl_list: *const DeclList,
        symbol1: [:0]const u8,
        symbol2: [:0]const u8,
    ) [:0]const u8 {
        if (decl_list.have(symbol1)) {
            return symbol1;
        } else {
            return symbol2;
        }
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
pub const FnExport = struct {
    prefix: ?[]const u8 = null,
    name: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    param_names: ?[]const []const u8 = null,
};
pub fn StructEditor(comptime render_spec: fmt.RenderSpec, comptime Value: type) type {
    const fields: []const builtin.Type.StructField = @typeInfo(Value).Struct.fields;
    const T = struct {
        pub fn indexOfCommonLeastDifference(allocator: *mem.SimpleAllocator, buf: []*Value) usize {
            var counts: []usize = allocator.allocate(usize, buf.len);
            var l_idx: usize = 0;
            while (l_idx != buf.len) : (l_idx +%= 1) {
                var r_idx: usize = 0;
                while (r_idx != buf.len) : (r_idx +%= 1) {
                    if (l_idx != r_idx) {
                        counts[l_idx] +%= fieldEditDistance(buf[l_idx], buf[r_idx]);
                    }
                }
            }
            var min: usize = ~@as(usize, 0);
            var ret: usize = 0;
            for (counts, 0..) |count, idx| {
                if (count < min) {
                    min = count;
                    ret = idx;
                }
            }
            return ret;
        }
        pub fn fieldEditDistance(s_val: *Value, t_val: *Value) callconv(.C) usize {
            var len: usize = 0;
            inline for (fields) |field| {
                if (!mem.testEqualMemory(
                    field.type,
                    @field(s_val, field.name),
                    @field(t_val, field.name),
                )) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn writeFieldEditDistance(buf: [*]u8, name: []const u8, s_val: *Value, t_val: *Value, commit: bool) usize {
            var ptr: [*]u8 = buf;
            inline for (fields) |field| {
                if (!mem.testEqualMemory(
                    field.type,
                    @field(s_val, field.name),
                    @field(t_val, field.name),
                )) {
                    ptr += fmt.identifier(name).formatWriteBuf(ptr);
                    ptr[0] = '.';
                    ptr += 1;
                    ptr[0..field.name.len].* = field.name[0..field.name.len].*;
                    ptr += field.name.len;
                    ptr[0] = '=';
                    ptr += 1;
                    ptr += fmt.render(render_spec, @field(t_val, field.name)).formatWriteBuf(ptr);
                    ptr[0..2].* = ";\n".*;
                    ptr += 2;
                    if (commit) {
                        @field(s_val, field.name) = @field(t_val, field.name);
                    }
                }
            }
            return @intFromPtr(ptr - @intFromPtr(buf));
        }
    };
    return T;
}
pub const TruncateSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: Errors = .{},
    logging: Logging = .{},
    const Errors = struct {
        create: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        write: sys.ErrorPolicy = .{ .throw = sys.write_errors },
        close: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    };
    const Logging = struct {
        create: debug.Logging.AcquireError = .{},
        write: debug.Logging.SuccessError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    const create_options = .{
        .truncate = true,
        .write_only = true,
        .exclusive = false,
    };
    fn errors(comptime truncate_spec: TruncateSpec) sys.ErrorPolicy {
        return .{
            .throw = truncate_spec.errors.open.throw ++ truncate_spec.errors.read.throw ++
                truncate_spec.errors.close.throw,
            .abort = truncate_spec.errors.open.abort ++ truncate_spec.errors.read.abort ++
                truncate_spec.errors.close.abort,
        };
    }
    fn create(comptime truncate_spec: TruncateSpec) file.CreateSpec {
        return .{
            .logging = truncate_spec.logging.create,
            .errors = truncate_spec.errors.create,
        };
    }
    fn write(comptime truncate_spec: TruncateSpec) file.WriteSpec {
        return .{
            .child = truncate_spec.child,
            .return_type = truncate_spec.return_type,
            .logging = truncate_spec.logging.write,
            .errors = truncate_spec.errors.write,
        };
    }
    fn close(comptime truncate_spec: TruncateSpec) file.CloseSpec {
        return .{
            .logging = truncate_spec.logging.close,
            .errors = truncate_spec.errors.close,
        };
    }
    pub const noexcept: TruncateSpec = .{
        .return_type = u64,
        .errors = .{
            .create = .{},
            .write = .{},
            .close = .{},
        },
    };
    pub const discard_noexcept: TruncateSpec = .{
        .errors = .{
            .create = .{},
            .write = .{},
            .close = .{},
        },
    };
};
pub const AppendSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: Errors = .{},
    logging: Logging = .{},

    const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        write: sys.ErrorPolicy = .{ .throw = sys.write_errors },
        close: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    };
    const Logging = struct {
        open: debug.Logging.AcquireError = .{},
        write: debug.Logging.SuccessError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    fn open(comptime append_spec: AppendSpec) file.OpenSpec {
        return .{
            .logging = append_spec.logging.open,
            .errors = append_spec.errors.open,
        };
    }
    fn write(comptime append_spec: AppendSpec) file.WriteSpec {
        return .{
            .child = append_spec.child,
            .return_type = append_spec.return_type,
            .logging = append_spec.logging.write,
            .errors = append_spec.errors.write,
        };
    }
    fn close(comptime append_spec: AppendSpec) file.CloseSpec {
        return .{
            .logging = append_spec.logging.close,
            .errors = append_spec.errors.close,
        };
    }
    pub const noexcept: AppendSpec = .{
        .return_type = u64,
        .errors = .{
            .open = .{},
            .write = .{},
            .close = .{},
        },
    };
    pub const discard_noexcept: AppendSpec = .{
        .errors = .{
            .open = .{},
            .write = .{},
            .close = .{},
        },
    };
};
pub const ReadSpec = struct {
    child: type = u8,
    return_type: type = void,
    errors: Errors = .{},
    logging: Logging = .{},
    const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        read: sys.ErrorPolicy = .{ .throw = sys.read_errors },
        close: sys.ErrorPolicy = .{ .throw = sys.close_errors },
    };
    const Logging = struct {
        open: debug.Logging.AcquireError = .{},
        read: debug.Logging.SuccessError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    fn open(comptime read_spec: ReadSpec) file.OpenSpec {
        return .{
            .logging = read_spec.logging.open,
            .errors = read_spec.errors.open,
        };
    }
    fn read(comptime read_spec: ReadSpec) file.ReadSpec {
        return .{
            .child = read_spec.child,
            .return_type = read_spec.return_type,
            .logging = read_spec.logging.read,
            .errors = read_spec.errors.read,
        };
    }
    fn close(comptime read_spec: ReadSpec) file.CloseSpec {
        return .{
            .logging = read_spec.logging.close,
            .errors = read_spec.errors.close,
        };
    }
    pub const discard_noexcept: ReadSpec = .{
        .errors = .{
            .open = .{},
            .read = .{},
            .close = .{},
        },
    };
    pub const noexcept: ReadSpec = .{
        .return_type = u64,
        .errors = .{
            .open = .{},
            .read = .{},
            .close = .{},
        },
    };
};
pub fn truncateFile(comptime truncate_spec: TruncateSpec, pathname: [:0]const u8, buf: []const truncate_spec.child) sys.ErrorUnion(.{
    .throw = truncate_spec.errors.create.throw ++ truncate_spec.errors.write.throw ++
        truncate_spec.errors.close.throw,
    .abort = truncate_spec.errors.create.abort ++ truncate_spec.errors.write.abort ++
        truncate_spec.errors.close.abort,
}, truncate_spec.return_type) {
    const fd: usize = try meta.wrap(file.create(truncate_spec.create(), TruncateSpec.create_options, pathname, file.mode.regular));
    const ret: truncate_spec.return_type = try meta.wrap(file.write(truncate_spec.write(), fd, buf));
    try meta.wrap(file.close(truncate_spec.close(), fd));
    return ret;
}
pub fn appendFile(comptime append_spec: AppendSpec, pathname: [:0]const u8, buf: []const append_spec.child) sys.ErrorUnion(.{
    .throw = append_spec.errors.open.throw ++ append_spec.errors.write.throw ++
        append_spec.errors.close.throw,
    .abort = append_spec.errors.open.abort ++ append_spec.errors.write.abort ++
        append_spec.errors.close.abort,
}, void) {
    const fd: usize = try meta.wrap(file.open(append_spec.open(), .{ .append = true, .write_only = true }, pathname));
    const ret: append_spec.return_type = try meta.wrap(file.write(append_spec.write(), fd, buf));
    try meta.wrap(file.close(append_spec.close(), fd));
    return ret;
}
pub fn readFile(comptime read_spec: ReadSpec, pathname: [:0]const u8, buf: []read_spec.child) sys.ErrorUnion(.{
    .throw = read_spec.errors.open.throw ++ read_spec.errors.read.throw ++
        read_spec.errors.close.throw,
    .abort = read_spec.errors.open.abort ++ read_spec.errors.read.abort ++
        read_spec.errors.close.abort,
}, read_spec.return_type) {
    const fd: usize = try meta.wrap(file.open(read_spec.open(), .{ .create = true }, pathname));
    const ret: read_spec.return_type = try meta.wrap(file.read(read_spec.read(), fd, buf));
    try meta.wrap(file.close(read_spec.close(), fd));
    return ret;
}
pub fn truncateFileAt(comptime truncate_spec: TruncateSpec, dir_fd: usize, name: [:0]const u8, buf: []const truncate_spec.child) sys.ErrorUnion(.{
    .throw = truncate_spec.errors.create.throw ++ truncate_spec.errors.write.throw ++
        truncate_spec.errors.close.throw,
    .abort = truncate_spec.errors.create.abort ++ truncate_spec.errors.write.abort ++
        truncate_spec.errors.close.abort,
}, truncate_spec.return_type) {
    const fd: usize = try meta.wrap(file.createAt(truncate_spec.create(), dir_fd, name, file.mode.regular));
    const ret: truncate_spec.return_type = try meta.wrap(file.write(truncate_spec.write(), fd, buf));
    try meta.wrap(file.close(truncate_spec.close(), fd));
    return ret;
}
pub fn appendFileAt(comptime append_spec: AppendSpec, dir_fd: usize, name: [:0]const u8, buf: []const append_spec.child) sys.ErrorUnion(.{
    .throw = append_spec.errors.open.throw ++ append_spec.errors.write.throw ++
        append_spec.errors.close.throw,
    .abort = append_spec.errors.open.abort ++ append_spec.errors.write.abort ++
        append_spec.errors.close.abort,
}, void) {
    const fd: usize = try meta.wrap(file.openAt(append_spec.open(), dir_fd, name));
    const ret: append_spec.return_type = try meta.wrap(file.write(append_spec.write(), fd, buf));
    try meta.wrap(file.close(append_spec.close(), fd));
    return ret;
}
pub fn readFileAt(comptime read_spec: ReadSpec, dir_fd: usize, name: [:0]const u8, buf: []read_spec.child) sys.ErrorUnion(.{
    .throw = read_spec.errors.open.throw ++ read_spec.errors.read.throw ++
        read_spec.errors.close.throw,
    .abort = read_spec.errors.open.abort ++ read_spec.errors.read.abort ++
        read_spec.errors.close.abort,
}, read_spec.return_type) {
    const fd: usize = try meta.wrap(file.openAt(read_spec.open(), dir_fd, name));
    const ret: read_spec.return_type = try meta.wrap(file.read(read_spec.read(), fd, buf));
    try meta.wrap(file.close(read_spec.close(), fd));
    return ret;
}
pub fn containerDeclsToBitField(comptime Container: type, comptime backing_integer: type, type_name: []const u8) void {
    const Fns = struct {
        const Array = mem.StaticString(1024 *% 1024);
        const BitFieldSet = meta.GenericBitFieldSet(backing_integer);
        fn bitSizeOfEnum(set: BitFieldSet) u16 {
            var value: backing_integer = 0;
            for (set.pairs) |pair| {
                value |= pair.value;
            }
            return @bitSizeOf(backing_integer) -% (@clz(value) +% @ctz(value));
        }
        fn bitSizeOfFields(set: BitFieldSet, bit_offset: u16) u16 {
            var diff: u16 = 0;
            for (set.pairs) |pair| {
                if (pair.value != 0) {
                    diff = ((@bitSizeOf(backing_integer) -% @clz(pair.value)) -% 1) -% bit_offset;
                }
            }
            return diff +% 1;
        }
        fn writeFields(array: *Array, bit_field_sets: []const BitFieldSet) void {
            var bits: u16 = 0;
            var diff: u16 = 0;
            var enum_count: u16 = 0;
            for (bit_field_sets) |set| {
                if (set.tag == .E) {
                    const bit_size_of_enum: u16 = bitSizeOfEnum(set);
                    array.writeOne('e');
                    array.writeFormat(fmt.ud16(enum_count));
                    array.writeMany(":enum(u");
                    array.writeFormat(fmt.id64(bit_size_of_enum));
                    array.writeMany("){\n");
                    for (set.pairs) |pair| {
                        array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                        array.writeMany("=");
                        array.writeFormat(fmt.ud64(pair.value >> @intCast(bits)));
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
                diff = @bitSizeOf(backing_integer) -% bits;
                if (diff >= 1) {
                    array.writeMany("zb");
                    array.writeFormat(fmt.ud16(bits));
                    array.writeMany(":u");
                    array.writeFormat(fmt.ud16(diff));
                    array.writeMany("=0,\n");
                }
            }
        }
        fn writeAssertFunction(array: *Array, size_type_name: []const u8) void {
            array.writeMany("fn assert(flags:@This(),val:");
            array.writeMany(size_type_name);
            array.writeMany(")void{\ndebug.assertEqual(");
            array.writeMany(size_type_name);
            array.writeMany(", @as(");
            array.writeMany(size_type_name);
            array.writeMany(",@bitCast(flags)),val);\n}\n");
        }
        fn writeAssertions(array: *Array, bit_field_sets: []const BitFieldSet) void {
            var enum_count: u16 = 0;
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
        }
        fn writeFormatWriteFunction(array: *Array, bit_field_sets: []const BitFieldSet) void {
            array.writeMany("pub fn formatWriteBuf(format:@This(),buf:[*]u8)usize{\n");
            array.writeMany("var ptr: [*]u8 = buf;\n");
            for (bit_field_sets) |set| {
                var string: fmt.StringLiteralFormat = undefined;
                for (set.pairs, 0..) |pair, idx| {
                    string.value = pair.name;
                    array.writeMany("if(format.");
                    array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                    array.writeMany("){\n");
                    if (idx != 0) {
                        array.writeMany("if(ptr!=buf){\n");
                        array.writeMany("ptr[0]='|';\n");
                        array.writeMany("ptr+=1;\n");
                        array.writeMany("}\n");
                    }
                    if (set.tag == .E) {
                        array.writeMany("ptr+=fmt.strcpyEqu(ptr,@tagName(format.");
                        array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                        array.writeMany("));\n");
                        array.writeMany("}\n");
                    } else {
                        array.writeMany("ptr+=fmt.strcpyEqu(ptr,");
                        array.writeFormat(string);
                        array.writeMany(");\n");
                        array.writeMany("}\n");
                    }
                }
            }
            array.writeMany("}\n");
        }
        fn writeFormatLengthFunction(array: *Array, bit_field_sets: []const BitFieldSet) void {
            array.writeMany("pub fn formatLength(format:@This())usize{\n");
            array.writeMany("var len: usize = 0;\n");
            for (bit_field_sets, 0..) |set, idx| {
                var string: fmt.StringLiteralFormat = undefined;
                for (set.pairs) |pair| {
                    string.value = pair.name;
                    array.writeMany("if(format.");
                    array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                    array.writeMany("){\n");
                    if (idx != 0) {
                        array.writeMany("len+%=@intFromBool(len!=0);\n");
                    }
                    if (set.tag == .E) {
                        array.writeMany("len+=@tagName(format.");
                        array.writeFormat(fmt.IdentifierFormat{ .value = pair.name });
                        array.writeMany(").len;\n");
                    } else {
                        array.writeMany("len+=");
                        array.writeFormat(fmt.ud64(string.value.len));
                        array.writeMany(";\n");
                    }
                    array.writeMany("}\n");
                }
            }
            array.writeMany("}\n");
        }
        fn writeFieldValuePairs(array: *Array, bit_field_sets: []const BitFieldSet) void {
            array.writeMany("const x: [");
            array.writeFormat(fmt.ud64(bit_field_sets.len));
            array.writeMany("]struct{[:0]const u8,");
            array.writeMany(@typeName(backing_integer));
            array.writeMany("}=.{");
            var bits: u16 = 0;
            for (bit_field_sets) |set| {
                array.writeMany("// ");
                if (set.tag == .E) {
                    const bit_size_of: u16 = bitSizeOfEnum(set);
                    array.writeFormat(fmt.ud64(bit_size_of));
                    bits +%= bit_size_of;
                } else {
                    const bit_size_of: u16 = bitSizeOfFields(set, bits);
                    array.writeFormat(fmt.ud64(bit_size_of));
                    bits +%= bit_size_of;
                }
                array.writeMany("\n");
                for (set.pairs) |pair| {
                    array.writeMany(".{");
                    array.writeFormat(fmt.StringLiteralFormat{ .value = pair.name });
                    array.writeMany(",");
                    array.writeFormat(fmt.ud64(pair.value));
                    array.writeMany("},\n");
                }
            }
            array.writeMany("};\n");
        }
    };
    var array: Fns.Array = undefined;
    array.undefineAll();
    const bit_field_sets: []const meta.GenericBitFieldSet(backing_integer) = comptime meta.containerDeclsToBitFieldSets(Container, backing_integer);
    array.writeMany("const ");
    array.writeMany(type_name);
    array.writeMany("=packed struct(" ++ @typeName(backing_integer) ++ "){\n");
    Fns.writeFields(&array, bit_field_sets);
    Fns.writeAssertFunction(&array, @typeName(backing_integer));
    Fns.writeFormatWriteFunction(&array, bit_field_sets);
    Fns.writeFormatLengthFunction(&array, bit_field_sets);
    array.writeMany("comptime{");
    Fns.writeAssertions(&array, bit_field_sets);
    array.writeMany("}\n");
    Fns.writeFieldValuePairs(&array, bit_field_sets);
    array.writeMany("};\n");
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
pub fn allLoggingTypes() !void {
    @setEvalBranchQuota(~@as(u32, 0));
    var array: mem.StaticString(1024 *% 1024) = undefined;
    array.undefineAll();
    inline for (builtin.loggingTypes()) |T| {
        var type_name: []const u8 = &.{};
        inline for (@typeInfo(T).Struct.fields) |field| {
            type_name = type_name ++ field.name;
        }
        const type_descr: TypeDescr = comptime TypeDescr.init(T);
        array.writeMany("pub const ");
        array.writeMany(type_name);
        array.writeMany(" = ");
        array.writeMany(type_descr.type_decl.Composition.spec);
        array.writeMany(" {\n");
        for (type_descr.type_decl.Composition.fields) |f| {
            array.writeMany("    ");
            array.writeMany(f.name);
            array.writeMany(": ");
            if (f.type) |f_type_descr| {
                array.writeMany(f_type_descr.type_name);
            }
            array.writeMany(" = ");
            array.writeMany("logging_default.");
            array.writeMany(f.name);
            array.writeMany(",\n");
        }
        array.writeMany("    pub fn invert(comptime logging: ");
        array.writeMany(type_name);
        array.writeMany(") ");
        array.writeMany(type_name);
        array.writeMany(" {\n");
        array.writeMany("        const tmp: u");
        array.writeFormat(fmt.ud64(type_descr.type_decl.defn.?.fields.len));
        array.writeMany(" = @bitCast(logging);\n");
        array.writeMany("        return @bitCast(~tmp);\n");
        array.writeMany("    }\n");
        array.writeMany("    pub fn override(comptime logging: ");
        array.writeMany(type_name);
        array.writeMany(") ");
        array.writeMany(type_name);
        array.writeMany(" {\n");
        array.writeMany("        return .{\n");
        for (type_descr.type_decl.Composition.fields) |f| {
            array.writeMany("            .");
            array.writeMany(f.name);
            array.writeMany(" = ");
            array.writeMany("logging_override.");
            array.writeMany(f.name);
            array.writeMany(" orelse logging.");
            array.writeMany(f.name);
            array.writeMany(",\n");
        }
        array.writeMany("        };\n");
        array.writeMany("    }\n");
        array.writeMany("};\n");
    }
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
pub fn allPanicDeclarations() void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    const names: []const []const u8 = &.{
        "panic",
        "panicInactiveUnionField",
        "panicOutOfBounds",
        "panicSentinelMismatch",
        "panicStartGreaterThanEnd",
        "panicUnwrapError",
    };
    inline for (names) |name| {
        array.writeMany(
            \\/// This function type is used by the Zig language code generation and
            \\/// therefore must be kept in sync with the compiler implementation.
            \\
        );
        array.writeMany("const " ++ fmt.static.toTitlecase(name) ++ "Fn = @TypeOf(default." ++ name ++ ");\n");
        array.writeMany(
            \\/// This function is used by the Zig language code generation and
            \\/// therefore must be kept in sync with the compiler implementation.
            \\
        );
        array.writeMany("pub const " ++ name ++ " = if (@hasDecl(root, \"" ++ name ++ "\"))\n");
        array.writeMany("    root." ++ name ++ "\n");
        array.writeMany("else if (@hasDecl(root, \"os\") and @hasDecl(root.os, \"" ++ name ++ "\"))\n");
        array.writeMany("    root.os." ++ name ++ "\n");
        array.writeMany("else\n");
        array.writeMany("    default." ++ name ++ ";\n\n");
    }
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
