const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = meta.empty;
    return &ptrs;
}
const all_types = slices(type);

const create_spec: file.CreateSpec = .{ .options = .{ .exclusive = false } };
const close_spec: file.CloseSpec = .{ .errors = null };
const fmt_spec = .{
    .omit_default_fields = true,
    .infer_type_names = true,
    .omit_trailing_comma = true,
};

const Context = struct {
    modes: AbstractSpec.Modes = .{},
    fields: AbstractSpec.Fields = .{},
    techniques: AbstractSpec.Techniques = .{},
};
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

    pub const Modes = struct {
        read_write: bool = false,
        resize: bool = false,
        stream: bool = false,
    };
    pub const Fields = struct {
        automatic_storage: bool = false,
        allocated_byte_address: bool = false,
        undefined_byte_address: bool = false,
        unallocated_byte_address: bool = false,
        unstreamed_byte_address: bool = false,
    };
    pub const Techniques = struct {
        automatic: bool = false,
        dynamic: bool = false,
        static: bool = false,
        parametric: bool = false,

        structured_layout: bool = false,
        unstructured_layout: bool = false,

        lazy_alignment: bool = false,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,

        single_packed_approximate_capacity: bool = false,
        double_packed_approximate_capacity: bool = false,

        pub const mutex = .{
            .kind = .{
                .automatic,
                .dynamic,
                .static,
                .parametric,
            },
            .capacity = .{
                .single_packed_approximate,
                .double_packed_approximate,
            },
            .alignment = .{
                .unit,
                .lazy,
                .disjunct,
            },
            .layout = .{
                .structured,
                .unstructured,
            },
        };
    };

    fn NoSuperAlignment(comptime S: type) type {
        return (union(enum) {
            unit_alignment: S,
            lazy_alignment: S,
            disjunct_alignment: S,
        });
    }
    fn AutoAlignment(comptime S: type) type {
        return (union(enum) {
            auto_alignment: S,
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
        structured_layout: AutomaticStuctured,
    } };
    const Static = union { static: union {
        structured_layout: NoSuperAlignment(StructuredStatic),
        unstructured_layout: NoSuperAlignment(UnstructuredStatic),
    } };
    const Dynamic = union { dynamic: union {
        structured_layout: NoSuperAlignment(Structured),
        unstructured_layout: NoSuperAlignment(Unstructured),
    } };
    const Parametric = union { parametric: union {
        structured_layout: NoPackedAlignment(StructuredParametric),
        unstructured_layout: NoPackedAlignment(UnstructuredParametric),
    } };

    const AutomaticStuctured = struct {
        child: type,
        sentinel: in_out(*const anyopaque) = null,
        count: u64,
        low_alignment: in(u64) = null,
    };
    const Structured = struct {
        child: type,
        sentinel: in_out(*const anyopaque) = null,
        low_alignment: in(u64) = null,
        Allocator: _Allocator,
    };
    const Unstructured = struct {
        high_alignment: u64,
        low_alignment: in(u64) = null,
        Allocator: _Allocator,
    };
    const StructuredStatic = struct {
        child: type,
        sentinel: in_out(*const anyopaque) = null,
        count: u64,
        low_alignment: in(u64) = null,
        Allocator: _Allocator,
    };
    const UnstructuredStatic = struct {
        bytes: u64,
        low_alignment: in(u64) = null,
        Allocator: _Allocator,
    };
    const StructuredParametric = struct {
        Allocator: type,
        child: type,
        sentinel: in_out(*const anyopaque) = null,
        low_alignment: in(u64) = null,
    };
    const UnstructuredParametric = struct {
        Allocator: type,
        high_alignment: u64,
        low_alignment: in(u64) = null,
    };

    /// Require the field be optional in the input parameters
    fn in(comptime T: type) type {
        return ?T;
    }
    /// Require the field be a variance point in the output specification
    fn out(comptime T: type) type {
        return ??T;
    }
    /// Require the field be static in the output specification
    fn in_out(comptime T: type) type {
        return ???T;
    }
    /// Remove the field from the output specification--only used by the input.
    fn strip(comptime T: type) type {
        return ????T;
    }
    /// Having this type in one of the specification structs below means that
    /// the container configurator struct will have a field 'Allocator: type',
    /// and by a function named 'arenaIndex'--a member function--may obtain the
    /// optional parameter 'arena_index'.
    const AllocatorStripped = strip(type);
    const AllocatorWithArenaIndex = union {
        Allocator: type,
        arena_index: in_out(u64),
    };
    const _Allocator = AllocatorWithArenaIndex;
};

pub const AddressSpace = preset.address_space.exact_8;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
});
pub const Array = Allocator.StructuredHolder(u8);
fn BinaryFilter(comptime T: type) type {
    return (struct { []const T, []const T });
}

fn typeIndex(comptime types: []const type, comptime T: type) ?comptime_int {
    for (types) |U, index| {
        if (U == T) return index;
    }
    return null;
}

noinline fn summariseAbstractSpec(array: *Array, comptime T: type, ctx: Context) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            var next: Context = ctx;
            if (@hasField(AbstractSpec.Modes, field.name)) {
                @field(next.modes, field.name) = true;
            }
            if (@hasField(AbstractSpec.Fields, field.name)) {
                @field(next.fields, field.name) = true;
            }
            if (@hasField(AbstractSpec.Techniques, field.name)) {
                @field(next.techniques, field.name) = true;
            }
            if (builtin.testEqual(Context, next, ctx)) {
                unreachable;
            }
            summariseAbstractSpec(array, field.type, next);
        }
    } else if (type_info == .Struct) {
        array.writeMany(".{ .mode = ");
        array.writeFormat(fmt.render(fmt_spec, ctx.modes));
        array.writeMany(", .fields = ");
        array.writeFormat(fmt.render(fmt_spec, ctx.fields));
        array.writeMany(", .techniques = ");
        array.writeFormat(fmt.render(fmt_spec, ctx.techniques));
        array.writeMany(", .params = ");
        array.writeFormat(comptime fmt.any(T));
        array.writeMany(" },\n");
    }
}

fn gatherContainerTypesInternal(comptime types: []const type, comptime T: type) []const type {
    var ret: []const type = types;
    if (!comptime meta.isContainer(T)) {
        return ret;
    }
    if (typeIndex(ret, T) == null and @typeInfo(T) == .Struct) {
        ret = meta.concat(type, ret, T);
    }
    const type_info = meta.resolve(@typeInfo(T));
    inline for (type_info.fields) |field| {
        const Field = @TypeOf(field);
        if (@hasField(Field, "type")) {
            if (typeIndex(types, field.type) == null) {
                ret = gatherContainerTypesInternal(ret, field.type);
            }
        }
    }
    return ret;
}
fn gatherContainerTypes(comptime T: type) []const type {
    return gatherContainerTypesInternal(meta.empty, T);
}

fn getMutuallyExclusiveOptions(comptime any: anytype) []const []const u8 {
    switch (@typeInfo(@TypeOf(any))) {
        .Struct => |struct_info| {
            var names: []const []const u8 = meta.empty;
            inline for (struct_info.fields) |field| {
                for (getMutuallyExclusiveOptions(@field(any, field.name))) |name| {
                    if (struct_info.is_tuple) {
                        names = meta.concat([]const u8, names, name);
                    } else {
                        names = meta.concat([]const u8, names, name ++ "_" ++ field.name);
                    }
                }
            }
            return names;
        },
        .EnumLiteral => {
            return meta.parcel([]const u8, @tagName(any));
        },
        else => @compileError(@typeName(@TypeOf(any))),
    }
}
fn typeNames(comptime types: []const type) []const u8 {
    var ret: []const u8 = ".{ ";
    for (types) |T| {
        ret = ret ++ @typeName(T) ++ ", ";
    }
    return ret ++ "}";
}
fn fieldNamesSuperSet(comptime types: []const type) []const []const u8 {
    var all_field_names: []const []const u8 = meta.empty;
    var all_field_types: []const type = meta.empty;
    for (types) |T| {
        lo: for (meta.resolve(@typeInfo(T)).fields) |field| {
            for (all_field_names) |field_name, type_index| {
                if (mem.testEqualMany(u8, field.name, field_name)) {
                    builtin.static.assertEqual(type, all_field_types[type_index], field.type);
                    continue :lo;
                }
            }
            all_field_names = meta.concat([]const u8, all_field_names, field.name);
            all_field_types = meta.concat(type, all_field_types, field.type);
        }
    }
    return all_field_names;
}
fn declNamesSuperSet(comptime types: []const type) []const []const u8 {
    var all_decl_names: []const []const u8 = meta.empty;
    var all_decl_types: []const type = meta.empty;
    for (types) |T| {
        lo: for (meta.resolve(@typeInfo(T)).decls) |decl| {
            for (all_decl_names) |decl_name, type_index| {
                if (mem.testEqualMany(u8, decl.name, decl_name)) {
                    builtin.static.assertEqual(type, all_decl_types[type_index], decl.type);
                    continue :lo;
                }
            }
            all_decl_names = meta.concat([]const u8, all_decl_names, decl.name);
            all_decl_types = meta.concat(type, all_decl_types, decl.type);
        }
    }
    return all_decl_names;
}

fn haveField(comptime types: []const type, comptime field_name: []const u8) BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasField(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}
fn haveDecl(comptime types: []const type, comptime field_name: []const u8) BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasDecl(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}
fn writeHasFieldDeductionInternal(array: *Array, comptime types: []const type, comptime field_names: []const []const u8) void {
    if (field_names.len == 0) {
        return array.writeMany("return " ++ comptime typeNames(types) ++ ";\n");
    }
    const filtered: BinaryFilter(type) = comptime haveField(types, field_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (@hasField(T, \"" ++ field_names[0] ++ "\")) {\n");
        writeDeclaration(array, field_names[0], meta.Field(filtered[1][0], field_names[0]));
        if (filtered[1].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasFieldDeductionInternal(array, filtered[1], field_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[0][0]) ++ ";\n");
        } else {
            writeHasFieldDeductionInternal(array, filtered[0], field_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeHasDeclDeductionInternal(array: *Array, comptime types: []const type, comptime decl_names: []const []const u8) void {
    if (decl_names.len == 0) {
        return array.writeMany("return " ++ comptime typeNames(types) ++ ";\n");
    }
    const filtered: BinaryFilter(type) = comptime haveDecl(types, decl_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (@hasDecl(T, \"" ++ decl_names[0] ++ "\")) {\n");
        if (filtered[1].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasDeclDeductionInternal(filtered[1], decl_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[0][0]) ++ ";\n");
        } else {
            writeHasDeclDeductionInternal(filtered[0], decl_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeHasFieldDeduction(array: *Array, comptime types: []const type) void {
    array.writeMany("comptime {");
    @setEvalBranchQuota(~@as(u32, 0));
    writeHasFieldDeductionInternal(array, types, comptime fieldNamesSuperSet(types));
    array.writeMany("}");
}
fn writeHasDeclDeduction(array: *Array, comptime types: []const type) void {
    array.writeMany("comptime {");
    @setEvalBranchQuota(~@as(u32, 0));
    writeHasDeclDeductionInternal(array, types, comptime declNamesSuperSet(types));
    array.writeMany("}");
}
fn writeDeclaration(array: *Array, comptime decl_name: []const u8, comptime decl_type: type) void {
    array.writeMany("const " ++ decl_name ++ ": " ++ @typeName(decl_type) ++ " = undefined;\n");
}
pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = Array.init(&allocator);
    array.increment(&allocator, 1024 * 1024 * 4);
    array.writeMany("const summary = [_]Context{");
    summariseAbstractSpec(&array, AbstractSpec, .{});
    array.writeMany("};");

    const fd: u64 = try file.create(create_spec, builtin.build_root.? ++ "/top/mem/mem-template.zig");
    defer file.close(close_spec, fd);
    try file.write(fd, array.readAll(allocator));
}
