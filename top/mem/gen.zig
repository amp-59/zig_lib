const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const builtin = @import("./../builtin.zig");
const testing = @import("./../testing.zig");
const build_root = @cImport({}).build_root;

pub usingnamespace sys;

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

fn alignAbove(value: u64, comptime alignment: u64) u64 {
    return (value + (alignment - 1)) & ~(alignment - 1);
}
fn alignBelow(value: u64, comptime alignment: u64) u64 {
    return value & ~(alignment - 1);
}
fn GenericArray(comptime T: type) type {
    return (struct {
        start: u64,
        finish: u64,
        const Array = @This();
        pub fn init(any: []T) Array {
            return .{ .start = @ptrToInt(any.ptr), .finish = @ptrToInt(any.ptr) };
        }
        pub fn define(array: *Array, count: usize) void {
            array.finish +%= count;
        }
        pub fn undefine(array: *Array, count: usize) void {
            array.finish -%= count;
        }
        pub fn referOneUndefined(array: Array) *T {
            return @intToPtr(*T, array.finish);
        }
        pub fn writeCount(array: *Array, comptime count: usize, values: [count]T) void {
            for (values) |value, index| {
                @intToPtr(*T, array.finish + index).* = value;
            }
            array.finish +%= count;
        }
        pub fn writeMany(array: *Array, values: []const T) void {
            for (values) |value, index| {
                @intToPtr(*T, array.finish + index).* = value;
            }
            array.finish +%= values.len;
        }
        pub fn writeOne(array: *Array, value: T) void {
            @intToPtr(*T, array.finish).* = value;
            array.finish +%= 1;
        }
        pub fn writeOneBackwards(array: *Array, value: T) void {
            array.finish -%= 1;
            @intToPtr(*T, array.finish).* = value;
        }
        pub fn overwriteCountBack(array: Array, comptime count: usize, values: [count]T) void {
            const next: u64 = array.finish - count;
            for (values) |value, index| @intToPtr(*T, next + index).* = value;
        }
        pub fn overwriteManyBack(array: Array, values: []const T) void {
            const next: u64 = array.finish - values.len;
            for (values) |value, index| @intToPtr(*T, next + index).* = value;
        }
        pub fn overwriteOneBack(array: Array, value: T) void {
            array.overwriteCountBack(1, [1]T{value});
        }
        pub fn readAll(array: Array) []const T {
            return @intToPtr([*]const T, array.start)[0..array.len()];
        }
        pub fn undefineAll(array: *Array) void {
            array.finish = array.start;
        }
        pub fn len(array: Array) usize {
            return array.finish - array.start;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            format.formatWrite(array);
        }
    });
}
pub const String = GenericArray(u8);

pub const Allocator = struct {
    start: u64,
    next: u64,
    finish: u64,
    const start_addr: u64 = 0x40000000;
    const page_size: u64 = 0x1000;

    const unit_alignment: u64 = 1;
    const len_alignment: u64 = 1;
    pub const Save = struct { next: u64 };

    pub fn capacity(allocator: *const Allocator) u64 {
        return allocator.finish - allocator.start;
    }
    pub fn length(allocator: *const Allocator) u64 {
        return allocator.next - allocator.start;
    }
    pub fn save(allocator: *const Allocator) Save {
        return .{ .next = allocator.next };
    }
    pub fn restore(allocator: *Allocator, state: Save) void {
        allocator.next = state.next;
    }
    pub fn grow(allocator: *Allocator, finish: u64) void {
        const least: u64 = alignAbove(finish - allocator.finish, page_size);
        const len: u64 = @max(least, allocator.capacity() * 2);
        builtin.assert(sys.map(allocator.finish, len) == allocator.finish);
        allocator.finish += len;
    }
    pub fn reallocate(allocator: *Allocator, comptime T: type, count: u64, buf: []T) []T {
        const bytes: u64 = @sizeOf(T) * buf.len;
        if (allocator.next == @ptrToInt(buf.ptr) + bytes) {
            allocator.next += @sizeOf(T) * count - bytes;
            return buf.ptr[0..count];
        }
        const ret: []T = allocate(T, count);
        for (ret) |*ptr, i| ptr.* = buf[i];
        return ret;
    }
    pub fn create(allocator: *Allocator, comptime T: type) *T {
        const alignment: u64 = @alignOf(T);
        const bytes: u64 = @sizeOf(T);
        const start: u64 = alignAbove(allocator.next, alignment);
        const finish: u64 = start + bytes;
        if (finish > allocator.finish) allocator.grow(finish);
        allocator.next = finish;
        return @intToPtr(*T, start);
    }
    pub fn allocate(allocator: *Allocator, comptime T: type, count: u64) []T {
        const alignment: u64 = @alignOf(T);
        const size: u64 = @sizeOf(T);
        const bytes: u64 = size * count;
        const start: u64 = alignAbove(allocator.next, alignment);
        const finish: u64 = start + bytes;
        if (finish > allocator.finish) allocator.grow(finish);
        allocator.next = finish;
        return @intToPtr([*]T, start)[0..count];
    }
    pub fn reinit(allocator: *Allocator) void {
        allocator.next = start_addr;
    }
    pub fn init() Allocator {
        _ = sys.map(start_addr, page_size);
        return .{
            .start = start_addr,
            .next = start_addr,
            .finish = start_addr + page_size,
        };
    }
    pub fn deinit(allocator: *Allocator) void {
        sys.unmap(allocator.start, allocator.capacity());
        allocator.next = allocator.start;
        allocator.finish = allocator.start;
    }
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
pub fn fieldNames(comptime T: type) []const []const u8 {
    var field_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        field_names = field_names ++ [1][]const u8{field.name};
    }
    return field_names;
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
pub fn fieldTypeNames(comptime T: type) []const []const u8 {
    var field_type_names: []const []const u8 = &.{};
    for (@typeInfo(T).Struct.fields) |field| {
        field_type_names = field_type_names ++ [1][]const u8{simpleTypeName(field.type)};
    }
    return field_type_names;
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
