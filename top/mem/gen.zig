const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");
const build_root = @cImport({}).build_root;

pub usingnamespace sys;

const tok = @import("./tok.zig");

pub const String = mem.StaticString(1024 * 1024);
pub const ArgList = mem.StaticArray([:0]const u8, 16);
pub const ListKind = enum { Parameter, Argument };

pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
});
pub const Kinds = packed struct {
    automatic: bool = false,
    dynamic: bool = false,
    static: bool = false,
    parametric: bool = false,

    pub usingnamespace GenericStructOfBool(Kinds);
};
pub const Layouts = packed struct {
    structured: bool = false,
    unstructured: bool = false,

    pub usingnamespace GenericStructOfBool(Layouts);
};
pub const Modes = packed struct {
    read_write: bool = false,
    resize: bool = false,
    stream: bool = false,

    pub usingnamespace GenericStructOfBool(Modes);
};
pub const Fields = packed struct {
    automatic_storage: bool = false,
    allocated_byte_address: bool = false,
    undefined_byte_address: bool = false,
    unallocated_byte_address: bool = false,
    unstreamed_byte_address: bool = false,

    pub usingnamespace GenericStructOfBool(Fields);
};
pub const Techniques = packed struct {
    auto_alignment: bool = false,
    lazy_alignment: bool = false,
    unit_alignment: bool = false,
    disjunct_alignment: bool = false,

    single_packed_approximate_capacity: bool = false,
    double_packed_approximate_capacity: bool = false,

    arena_relative: bool = false,
    address_space_relative: bool = false,

    pub const Options = struct {
        capacity: ?enum {
            single_packed_approximate,
            double_packed_approximate,
        },
        alignment: enum {
            auto,
            unit,
            lazy,
            disjunct,
        },
        relative: enum {
            arena,
            address_space,
        },
    };
    pub usingnamespace GenericStructOfBool(Techniques);
};
pub const Option = struct {
    kind: Option.Kind,
    info: Info,

    pub const Kind = enum {
        standalone,
        mutually_exclusive_optional,
        mutually_exclusive_mandatory,
    };
    pub const Usage = enum {
        eliminate_boolean_false,
        eliminate_boolean_true,
        test_boolean,
        compare_enumeration,
        compare_optional_enumeration,
    };
    pub const Info = struct {
        field_name: []const u8,
        field_field_names: []const []const u8,
    };
    pub fn len(comptime option: Option) usize {
        return option.info.field_field_names.len;
    }
    pub fn count(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) usize {
        var ret: usize = 0;
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        inline for (option.info.field_field_names) |field_name| {
            ret +%= @boolToInt(@field(techs, field_name));
        }
        return ret;
    }
    pub fn names(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) mem.StaticArray([]const u8, option.len()) {
        var ret: mem.StaticArray([]const u8, option.len()) = undefined;
        ret.undefineAll();
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        inline for (option.info.field_field_names) |field_name| {
            if (@field(techs, field_name)) {
                ret.writeOne(field_name);
            }
        }
        return ret;
    }
    pub fn usage(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) Usage {
        const value: usize = option.count(Detail, toplevel_impl_group);
        switch (option.kind) {
            .standalone => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => unreachable,
            },
            .mutually_exclusive_optional => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => return .compare_optional_enumeration,
            },
            .mutually_exclusive_mandatory => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .eliminate_boolean_true,
                else => return .compare_enumeration,
            },
        }
    }
    pub fn fieldName(comptime option: Option, comptime index: usize) []const u8 {
        return option.info.field_field_names[index];
    }
    pub fn tagName(comptime option: Option, comptime index: usize) []const u8 {
        return option.fieldName(index)[0 .. option.fieldName(index).len - (option.info.field_name.len + 1)];
    }
};
pub const Import = struct {
    name: []const u8,
    path: []const u8,
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
    const Decl = struct { []const u8, usize };
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
            else => {
                return .{ .type_name = @typeName(T) };
            },
        }
    }
};

const sys = struct {
    fn syscall1(sysno: u64, arg1: u64) u64 {
        return asm volatile ("syscall"
            : [_] "={rax}" (-> u64),
            : [_] "{rax}" (sysno),
              [_] "{rdi}" (arg1),
            : "rcx", "r11", "memory"
        );
    }
    fn syscall2(sysno: u64, arg1: u64, arg2: u64) u64 {
        return asm volatile ("syscall"
            : [_] "={rax}" (-> u64),
            : [_] "{rax}" (sysno),
              [_] "{rdi}" (arg1),
              [_] "{rsi}" (arg2),
            : "rcx", "r11", "memory"
        );
    }
    fn syscall3(sysno: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
        return asm volatile ("syscall"
            : [_] "={rax}" (-> u64),
            : [_] "{rax}" (sysno),
              [_] "{rdi}" (arg1),
              [_] "{rsi}" (arg2),
              [_] "{rdx}" (arg3),
            : "rcx", "r11", "memory"
        );
    }
    fn syscall6(sysno: u64, arg1: u64, arg2: u64, arg3: u64, arg4: u64, arg5: u64, arg6: u64) u64 {
        return asm volatile ("syscall"
            : [_] "={rax}" (-> u64),
            : [_] "{rax}" (sysno),
              [_] "{rdi}" (arg1),
              [_] "{rsi}" (arg2),
              [_] "{rdx}" (arg3),
              [_] "{r10}" (arg4),
              [_] "{r8}" (arg5),
              [_] "{r9}" (arg6),
            : "rcx", "r11", "memory"
        );
    }
    pub fn read(fd: u64, buf: []u8) u64 {
        return syscall3(0, fd, @ptrToInt(buf.ptr), buf.len);
    }
    pub fn write(fd: u64, buf: []const u8) void {
        _ = syscall3(1, fd, @ptrToInt(buf.ptr), buf.len);
    }
    pub fn create(pathname: [:0]const u8) u64 {
        return syscall3(2, @ptrToInt(pathname.ptr), 0x80241, 0o640);
    }
    pub fn open(pathname: [:0]const u8) u64 {
        return syscall3(2, @ptrToInt(pathname.ptr), 0, 0);
    }
    pub fn append(pathname: [:0]const u8) u64 {
        return syscall3(2, @ptrToInt(pathname.ptr), 0x442, 0);
    }
    pub fn mkdir(pathname: [:0]const u8) void {
        _ = syscall2(83, @ptrToInt(pathname.ptr), 0o700);
    }
    pub fn close(fd: u64) void {
        _ = syscall1(3, fd);
    }
};
pub fn writeImports(array: *String, src: builtin.SourceLocation, imports: []const Import) void {
    array.writeMany("//! This file is generated by ");
    array.writeMany(src.file);
    array.writeMany("\n");
    for (imports) |import| {
        array.writeMany("const ");
        array.writeMany(import.name);
        array.writeMany(" = @import(\"");
        array.writeMany(import.path);
        array.writeMany("\");\n");
    }
}
pub fn writeSourceFile(array: *String, comptime pathname: [:0]const u8) void {
    const fd: u64 = sys.create(if (pathname[0] != '/')
        build_root ++ "/top/mem/" ++ pathname
    else
        pathname);
    defer sys.close(fd);
    sys.write(fd, array.readAll());
    array.undefineAll();
}
pub fn appendSourceFile(array: *String, comptime pathname: [:0]const u8) void {
    const fd: u64 = sys.append(if (pathname[0] != '/')
        build_root ++ "/top/mem/" ++ pathname
    else
        pathname);
    defer sys.close(fd);
    sys.write(fd, array.readAll());
    array.undefineAll();
}
pub fn writeAuxiliarySourceFile(array: *String, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    sys.mkdir(zig_out_dir);
    sys.mkdir(zig_out_src_dir);
    writeSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn appendAuxiliarySourceFile(array: *String, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    sys.mkdir(zig_out_dir);
    sys.mkdir(zig_out_src_dir);
    appendSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn writeIndex(array: *String, index: u16) void {
    array.writeMany(builtin.fmt.ud16(index).readAll());
}
pub fn writeField(array: *String, name: []const u8, type_descr: TypeDescr) void {
    array.writeMany(name);
    array.writeMany(": ");
    array.writeFormat(type_descr);
    array.writeMany(",\n");
}
pub fn groupImplementations(allocator: *Allocator, comptime Detail: type, group_key: []const u16, group: []const Detail) []const Detail {
    const buf: []Detail = allocator.allocateIrreversible(Detail, group_key.len);
    var impl_index: u16 = 0;
    while (impl_index != group_key.len) : (impl_index +%= 1) {
        buf[impl_index] = group[group_key[impl_index]];
    }
    return buf;
}
pub fn implLeader(comptime Detail: type, group_key: []const u16, group: []const Detail) Detail {
    return group[group_key[0]];
}
pub fn specIndex(comptime Detail: type, leader: Detail) u8 {
    return builtin.popcnt(u8, meta.leastRealBitCast(leader.specs));
}
pub fn writeComma(array: *String) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, tok.end_small_item, array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(tok.end_small_item);
    }
}
pub fn writeArgument(array: *String, argument_name: [:0]const u8) void {
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
pub fn writeStructOfBool(array: anytype, comptime T: type, value: T) void {
    const Format = GenericStructOfBool(T);
    Format.formatWrite(value, array);
}
fn GenericStructOfBool(comptime Struct: type) type {
    return (struct {
        pub fn formatWrite(format: Struct, array: anytype) void {
            if (countTrue(format) == 0) {
                array.writeMany(".{}");
            } else {
                array.writeMany(".{ ");
                inline for (@typeInfo(Struct).Struct.fields) |field| {
                    if (@field(format, field.name)) {
                        array.writeMany("." ++ field.name ++ " = true, ");
                    }
                }
                array.overwriteManyBack(" }");
            }
        }
        pub fn countTrue(bit_field: Struct) usize {
            var ret: usize = 0;
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                ret +%= @boolToInt(@field(bit_field, field.name));
            }
            return ret;
        }
    });
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
