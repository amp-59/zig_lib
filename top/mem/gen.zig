const fmt = @import("./../fmt.zig");
const mem = @import("./../mem.zig");
const meta = @import("./../meta.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");
const testing = @import("./../testing.zig");
const build_root = @cImport({}).build_root;

pub usingnamespace sys;

pub const String = mem.StaticString(1024 * 1024);
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
});

pub const AbstractSpec = union(enum) {
    automatic_storage: ReadWrite(union {
        _: Automatic,
        unstreamed_byte_address: Stream(union {
            _: Automatic,
            undefined_byte_address: Resize(Automatic),
        }),
        undefined_byte_address: Resize(Automatic),
    }),
    allocated_byte_address: ReadWrite(union {
        _: Static,
        single_packed_approximate_capacity: Dynamic,
        unstreamed_byte_address: Stream(union {
            undefined_byte_address: Resize(union {
                _: Static,
                single_packed_approximate_capacity: Dynamic,
                double_packed_approximate_capacity: Dynamic,
                unallocated_byte_address: Dynamic,
            }),
            unallocated_byte_address: Dynamic,
        }),
        undefined_byte_address: Resize(union {
            _: Static,
            single_packed_approximate_capacity: Dynamic,
            double_packed_approximate_capacity: Dynamic,
            unallocated_byte_address: Dynamic,
        }),
        unallocated_byte_address: Dynamic,
    }),
    undefined_byte_address: ReadWrite(Resize(union {
        _: Parametric,
        unstreamed_byte_address: Stream(Parametric),
    })),
};
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

    pub fn count(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const *const Detail) usize {
        var len: usize = 0;
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        inline for (option.info.field_field_names) |field_name| {
            len +%= @boolToInt(@field(techs, field_name));
        }
        return len;
    }
    pub fn usage(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const *const Detail) Usage {
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
pub const Variant = enum {
    stripped,
    derived,
    optional_derived,
    optional_variant,
    decl_optional_derived,
    decl_optional_variant,
};
pub fn Stripped(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory in interface, removed from specification.
        stripped: T,
    };
}
pub fn Derived(comptime T: type) type {
    return union(enum) {
        /// Input is undefined in interface, invariant in specification
        derived: T,
    };
}
pub fn OptDrv(comptime T: type) type {
    return union(enum) {
        /// Input is optional in interface, invariant in specification:
        /// alignment values.
        optional_derived: ?T,
    };
}
pub fn OptVar(comptime T: type) type {
    return union(enum) {
        /// Input is optional in interface, variant in specification:
        /// sentinel and guard page values.
        optional_variant: ?T,
    };
}
pub fn DeclOptDrv(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory container in interface, with optional
        /// declarations, invariant in specification.
        decl_optional_derived: T,
    };
}
pub fn DeclOptVar(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory container in interface, with optional
        /// declarations, variant in specification: arena offsets.
        decl_optional_variant: T,
    };
}
fn ReadWrite(comptime T: type) type {
    return (union(enum) { read_write: T });
}
fn Stream(comptime T: type) type {
    return (union(enum) { stream: T });
}
fn Resize(comptime T: type) type {
    return (union(enum) { resize: T });
}
const Automatic = union { automatic: union {
    structured: AutoAlignment(AutomaticStuctured),
} };
const Static = union { static: union {
    structured: NoSuperAlignment(StructuredStatic),
    unstructured: NoSuperAlignment(UnstructuredStatic),
} };
const Dynamic = union { dynamic: union {
    structured: NoSuperAlignment(Structured),
    unstructured: NoSuperAlignment(Unstructured),
} };
const Parametric = union { parametric: union {
    structured: NoPackedAlignment(StructuredParametric),
    unstructured: NoPackedAlignment(UnstructuredParametric),
} };
fn AutoAlignment(comptime S: type) type {
    return (union(enum) {
        auto_alignment: S,
    });
}
fn NoSuperAlignment(comptime S: type) type {
    return (union(enum) {
        unit_alignment: S,
        lazy_alignment: S,
        disjunct_alignment: S,
    });
}
fn NoPackedAlignment(comptime S: type) type {
    return (union(enum) {
        unit_alignment: S,
        lazy_alignment: S,
    });
}
fn StrictAlignment(comptime S: type) type {
    return (union(enum) {
        unit_alignment: S,
        disjunct_alignment: S,
    });
}
fn AnyAlignment(comptime S: type) type {
    return (union(enum) {
        unit_alignment: S,
        lazy_alignment: S,
        super_alignment: S,
        disjunct_alignment: S,
    });
}
const Sentinel = OptVar(*const anyopaque);
const default_sentinel: Sentinel = .{ .optional_variant = null };

const Alignment = OptDrv(u64);
const default_alignment: Alignment = .{ .optional_derived = null };

const BoundAllocator = DeclOptVar(struct {
    Allocator: type,
    arena: struct { lb_addr: u64, up_addr: u64 },
});
const AutomaticStuctured = struct {
    child: type,
    sentinel: Sentinel = default_sentinel,
    count: u64,
    low_alignment: Alignment = default_alignment,
};
const Structured = struct {
    child: type,
    sentinel: Sentinel = default_sentinel,
    low_alignment: Alignment = default_alignment,
    Allocator: BoundAllocator,
};
const Unstructured = struct {
    high_alignment: u64,
    low_alignment: Alignment = default_alignment,
    Allocator: BoundAllocator,
};
const StructuredStatic = struct {
    child: type,
    sentinel: Sentinel = default_sentinel,
    count: u64,
    low_alignment: Alignment = default_alignment,
    Allocator: BoundAllocator,
};
const UnstructuredStatic = struct {
    bytes: u64,
    low_alignment: Alignment = default_alignment,
    Allocator: BoundAllocator,
};
const StructuredParametric = struct {
    Allocator: type,
    child: type,
    sentinel: Sentinel = default_sentinel,
    low_alignment: Alignment = default_alignment,
};
const UnstructuredParametric = struct {
    Allocator: type,
    high_alignment: u64,
    low_alignment: Alignment = default_alignment,
};
const UnstructuredStaticSegment = struct {
    bytes: u64,
    Allocator: BoundAllocator,
};
pub const TypeSpecMap = struct {
    params: type,
    specs: []const type,
    vars: type,
};
pub const TypeDescr = union(enum) {
    type_name: []const u8,
    type_decl: Container,
    type_refer: Pointer,

    const Pointer = struct { []const u8, *const TypeDescr };
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
                        len +%= struct_defn[0];
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
    pub fn map(addr: u64, len: u64) u64 {
        return syscall6(9, addr, len, 0x1 | 0x2, 0x20 | 0x02 | 0x100000, ~@as(u64, 0), 0);
    }
    pub fn unmap(addr: u64, len: u64) void {
        _ = syscall2(11, addr, len);
    }
    pub noinline fn exit(rc: u64) noreturn {
        _ = syscall1(60, rc);
        unreachable;
    }
};
pub const fmt_struct_init_literal = .{
    .infer_type_names = true,
    .omit_default_fields = true,
    .omit_trailing_comma = true,
};
pub fn writeImports(array: anytype, src: anytype, imports: []const struct { name: []const u8, path: []const u8 }) void {
    array.writeMany("//! this file generated by ");
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
pub fn writeSourceFile(array: anytype, comptime pathname: [:0]const u8) void {
    const fd: u64 = sys.create(if (pathname[0] != '/')
        build_root ++ "/top/mem/" ++ pathname
    else
        pathname);
    defer sys.close(fd);
    sys.write(fd, array.readAll());
    array.undefineAll();
}
pub fn appendSourceFile(array: anytype, comptime pathname: [:0]const u8) void {
    const fd: u64 = sys.append(if (pathname[0] != '/')
        build_root ++ "/top/mem/" ++ pathname
    else
        pathname);
    defer sys.close(fd);
    sys.write(fd, array.readAll());
    array.undefineAll();
}
pub fn writeAuxiliarySourceFile(array: anytype, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    sys.mkdir(zig_out_dir);
    sys.mkdir(zig_out_src_dir);
    writeSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn appendAuxiliarySourceFile(array: anytype, comptime name: [:0]const u8) void {
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
    sys.mkdir(zig_out_dir);
    sys.mkdir(zig_out_src_dir);
    appendSourceFile(array, zig_out_src_dir ++ "/" ++ name);
}
pub fn writeIndex(array: anytype, index: u16) void {
    array.writeMany(builtin.fmt.ud16(index).readAll());
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
