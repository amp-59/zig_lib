const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.formulaic_128;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
});
pub const Array = Allocator.StructuredHolder(u8);
// pub const Array = mem.StaticString(65536);

fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = meta.empty;
    return &ptrs;
}
const create_spec: file.CreateSpec = .{ .options = .{ .exclusive = false } };
const close_spec: file.CloseSpec = .{ .errors = null };
const fmt_spec = .{
    .omit_default_fields = true,
    .infer_type_names = true,
    .omit_trailing_comma = true,
};

pub const Context = struct {
    modes: Modes = .{},
    fields: Fields = .{},
    techs: Techniques = .{},
};
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

pub fn BinaryFilter(comptime T: type) type {
    return (struct { []const T, []const T });
}
pub fn typeIndex(comptime types: []const type, comptime T: type) ?comptime_int {
    for (types) |U, index| {
        if (U == T) return index;
    }
    return null;
}
noinline fn summariseAbstractSpec(array: *Array, comptime T: type, ctx: Context) void {
    const types: *[]const type = comptime slices(type);
    array.writeMany("const gen = @import(\"./gen-0.zig\");\n");
    array.writeMany("pub const summary = [_]struct { gen.Context, type }{\n");
    summariseAbstractSpecInternal(array, types, T, ctx);
    array.writeMany("};\n");
    array.writeMany("pub const AbstractParams: [" ++ comptime builtin.fmt.ci(types.len) ++ "]type = .{\n");
    inline for (types.*) |U| {
        array.writeFormat(comptime fmt.any(U));
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
}
fn summaryItem(array: *Array, ctx: Context, type_index: u64) void {
    array.writeMany(".{ .{ .modes = ");
    array.writeFormat(fmt.render(fmt_spec, ctx.modes));
    array.writeMany(", .fields = ");
    array.writeFormat(fmt.render(fmt_spec, ctx.fields));
    array.writeMany(", .techs = ");
    array.writeFormat(fmt.render(fmt_spec, ctx.techs));
    array.writeMany(" }, AbstractParams[");
    array.writeFormat(fmt.ud64(type_index));
    array.writeMany("], },\n");
}
inline fn summariseAbstractSpecInternal(array: *Array, comptime types: *[]const type, comptime T: type, ctx: Context) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            var next: Context = ctx;
            if (@hasField(Modes, field.name)) {
                @field(next.modes, field.name) = true;
            }
            if (@hasField(Fields, field.name)) {
                @field(next.fields, field.name) = true;
            }
            if (@hasField(Techniques, field.name)) {
                @field(next.techs, field.name) = true;
            }
            if (builtin.testEqual(Context, next, ctx) and
                !(field.name.len == 1 and field.name[0] == '_'))
            {
                unreachable;
            }
            summariseAbstractSpecInternal(array, types, field.type, next);
        }
    } else if (type_info == .Struct) {
        const type_index: u64 = comptime blk: {
            if (typeIndex(types.*, T)) |index| {
                break :blk index;
            } else {
                meta.concatEqu(type, types, T);
                break :blk types.len - 1;
            }
        };
        summaryItem(array, ctx, type_index);
    }
}
pub fn main() !void {
    @setEvalBranchQuota(~@as(u32, 0));
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = Array.init(&allocator);
    array.increment(&allocator, 1024 * 1024 * 4);
    // var array: Array = undefined;
    // array.undefineAll();
    summariseAbstractSpec(&array, AbstractSpec, .{});
    const fd: u64 = try file.create(create_spec, builtin.build_root.? ++ "/top/mem/mem-template.zig");
    defer file.close(close_spec, fd);
    try file.write(fd, array.readAll(allocator));
}
