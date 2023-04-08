const Sentinel = OptVar(*const anyopaque);
const default_sentinel: Sentinel = .{ .optional_variant = null };

const Alignment = OptDrv(u64);
const default_alignment: Alignment = .{ .optional_derived = null };

const Automatic = union { automatic: union {
    structured: AutoAlignment(AutomaticStuctured),
} };
const Static = StaticInterface(union { static: union {
    structured: NoSuperAlignment(StructuredStatic),
    unstructured: NoSuperAlignment(UnstructuredStatic),
} });
const Dynamic = DynamicInterface(union { dynamic: union {
    structured: NoSuperAlignment(Structured),
    unstructured: NoSuperAlignment(Unstructured),
} });
const Parametric = ParametricInterface(union { parametric: union {
    structured: NoPackedAlignment(StructuredParametric),
    unstructured: NoPackedAlignment(UnstructuredParametric),
} });

pub const AbstractSpec = union {
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
        /// declarations, variant in specification.
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
fn DynamicInterface(comptime S: type) type {
    return Allocatable(Reallocatable(Resizable(Movable(Convertible(S)))));
}
fn ParametricInterface(comptime S: type) type {
    return Allocatable(Resizable(Convertible(S)));
}
fn StaticInterface(comptime S: type) type {
    return Allocatable(Movable(Convertible(S)));
}
pub fn Allocatable(comptime S: type) type {
    return union { allocatable: S };
}
pub fn Reallocatable(comptime S: type) type {
    return union { reallocatable: S };
}
pub fn Resizable(comptime S: type) type {
    return union { resizable: S };
}
pub fn Movable(comptime S: type) type {
    return union { movable: S };
}
pub fn Convertible(comptime S: type) type {
    return union { convertible: S };
}
