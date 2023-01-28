//! This stage summarises the abstract specification.
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

pub const Array = mem.StaticString(65536);

fn slices(comptime T: type) *[]const T {
    var ptrs: []const T = meta.empty;
    return &ptrs;
}
const close_spec: file.CloseSpec = .{ .errors = null };
const create_spec: file.CreateSpec = .{
    .errors = null,
    .options = .{ .exclusive = false },
};
const fmt_spec = .{
    .omit_default_fields = true,
    .infer_type_names = true,
    .omit_trailing_comma = true,
};
pub const Detail = struct {
    index: u8 = undefined,
    kind: Kind = .{},
    layout: Layout = .{},
    modes: Modes = .{},
    fields: Fields = .{},
    techs: Techniques = .{},
};
pub const Kind = struct {
    automatic: bool = false,
    dynamic: bool = false,
    static: bool = false,
    parametric: bool = false,
};
pub const Layout = struct {
    structured: bool = false,
    unstructured: bool = false,
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
    lazy_alignment: bool = false,
    unit_alignment: bool = false,
    disjunct_alignment: bool = false,
    single_packed_approximate_capacity: bool = false,
    double_packed_approximate_capacity: bool = false,
    pub const mutex = .{
        .capacity = .{
            .single_packed_approximate,
            .double_packed_approximate,
        },
        .alignment = .{
            .unit,
            .lazy,
            .disjunct,
        },
    };
};
pub const Variant = enum {
    __stripped,
    __derived,
    __optional_derived,
    __optional_variant,
    __decl_optional_derived,
    __decl_optional_variant,
};
pub fn Stripped(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory in interface, removed from specification.
        __stripped: T,
    };
}
pub fn Derived(comptime T: type) type {
    return union(enum) {
        /// Input is undefined in interface, invariant in specification
        __derived: T,
    };
}
pub fn OptDrv(comptime T: type) type {
    return union(enum) {
        /// Input is optional in interface, invariant in specification:
        /// alignment values.
        __optional_derived: ?T,
    };
}
pub fn OptVar(comptime T: type) type {
    return union(enum) {
        /// Input is optional in interface, variant in specification:
        /// sentinel and guard page values.
        __optional_variant: ?T,
    };
}
pub fn DeclOptDrv(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory container in interface, with optional
        /// declarations, invariant in specification.
        __decl_optional_derived: T,
    };
}
pub fn DeclOptVar(comptime T: type) type {
    return union(enum) {
        /// Input is mandatory container in interface, with optional
        /// declarations, variant in specification: arena offsets.
        __decl_optional_variant: T,
    };
}
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
        structured: AutomaticStuctured,
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
    const default_sentinel: Sentinel = .{ .__optional_variant = null };

    const Alignment = OptDrv(usize);
    const default_alignment: Alignment = .{ .__optional_derived = null };

    const BoundAllocator = DeclOptVar(struct {
        Allocator: type,
        arena: struct { lb_addr: usize, up_addr: usize },
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
fn writeBoilerplate(array: *Array) void {
    array.writeMany(
        \\//! This file is generated by `memgen` stage 0
        \\const gen = @import("./gen-0.zig");
        \\pub const summary = [_]gen.Detail{
    );
}
inline fn writeDetailStructs(array: *Array, comptime types: *[]const type, comptime T: type, detail: *Detail) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            const tmp = detail.*;
            defer detail.* = tmp;
            if (@hasField(Kind, field.name)) {
                @field(detail.kind, field.name) = true;
            } else if (@hasField(Layout, field.name)) {
                @field(detail.layout, field.name) = true;
            } else if (@hasField(Modes, field.name)) {
                @field(detail.modes, field.name) = true;
            } else if (@hasField(Fields, field.name)) {
                @field(detail.fields, field.name) = true;
            } else if (@hasField(Techniques, field.name)) {
                @field(detail.techs, field.name) = true;
            } else if (field.name.len != 1 or field.name[0] != '_') {
                @compileError(field.name);
            }
            writeDetailStructs(array, types, field.type, detail);
        }
    } else if (type_info == .Struct) {
        detail.index = comptime blk: {
            if (typeIndex(types.*, T)) |index| {
                break :blk index;
            } else {
                meta.concatEqu(type, types, T);
                break :blk types.len - 1;
            }
        };
        writeDetailStruct(array, detail.*);
    }
}
fn writeDetailStruct(array: *Array, detail: Detail) void {
    array.writeMany(".{ .kind = ");
    array.writeFormat(fmt.render(fmt_spec, detail.kind));
    array.writeMany(", .layout = ");
    array.writeFormat(fmt.render(fmt_spec, detail.layout));
    array.writeMany(", .modes = ");
    array.writeFormat(fmt.render(fmt_spec, detail.modes));
    array.writeMany(", .fields = ");
    array.writeFormat(fmt.render(fmt_spec, detail.fields));
    array.writeMany(", .techs = ");
    array.writeFormat(fmt.render(fmt_spec, detail.techs));
    array.writeMany(", .index = ");
    array.writeFormat(fmt.ud64(detail.index));
    array.writeMany(", },\n");
}
fn writeAbstractParams(array: *Array, comptime types: *[]const type) void {
    array.writeMany("};\n");
    array.writeMany("pub const abstract_params = [_]type{\n");
    inline for (types.*) |U| {
        array.writeFormat(comptime fmt.any(U));
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
}
fn writeFile(array: *Array) void {
    const fd: u64 = file.create(create_spec, builtin.build_root.? ++ "/top/mem/summary.zig");
    defer file.close(close_spec, fd);
    file.noexcept.write(fd, array.readAll());
}
pub fn main() !void {
    var detail: Detail = .{};
    var array: Array = .{};
    const types: *[]const type = comptime slices(type);
    writeBoilerplate(&array);
    writeDetailStructs(&array, types, AbstractSpec, &detail);
    writeAbstractParams(&array, types);
    writeFile(&array);
}
