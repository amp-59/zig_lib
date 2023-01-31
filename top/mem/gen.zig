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
        // single_packed_approximate_capacity: Dynamic,
        unstreamed_byte_address: Stream(union {
            undefined_byte_address: Resize(union {
                _: Static,
                // single_packed_approximate_capacity: Dynamic,
                // double_packed_approximate_capacity: Dynamic,
                unallocated_byte_address: Dynamic,
            }),
            unallocated_byte_address: Dynamic,
        }),
        undefined_byte_address: Resize(union {
            _: Static,
            // single_packed_approximate_capacity: Dynamic,
            // double_packed_approximate_capacity: Dynamic,
            unallocated_byte_address: Dynamic,
        }),
        unallocated_byte_address: Dynamic,
    }),
    undefined_byte_address: ReadWrite(Resize(union {
        _: Parametric,
        unstreamed_byte_address: Stream(Parametric),
    })),
};
pub const Detail = packed struct {
    index: u8 = undefined,
    kind: Kind = .{},
    layout: Layout = .{},
    modes: Modes = .{},
    fields: Fields = .{},
    techs: Techniques = .{},
};
pub const Kind = packed struct {
    automatic: bool = false,
    dynamic: bool = false,
    static: bool = false,
    parametric: bool = false,
};
pub const Layout = packed struct {
    structured: bool = false,
    unstructured: bool = false,
};
pub const Modes = packed struct {
    read_write: bool = false,
    resize: bool = false,
    stream: bool = false,
};
pub const Fields = packed struct {
    automatic_storage: bool = false,
    allocated_byte_address: bool = false,
    undefined_byte_address: bool = false,
    unallocated_byte_address: bool = false,
    unstreamed_byte_address: bool = false,
};
pub const Techniques = packed struct {
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

const Alignment = OptDrv(u64);
const default_alignment: Alignment = .{ .__optional_derived = null };

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
const common = struct {
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
    fn syscall1(sysno: u64, arg1: u64) u64 {
        return asm volatile ("syscall"
            : [_] "={rax}" (-> u64),
            : [_] "{rax}" (sysno),
              [_] "{rdi}" (arg1),
            : "rcx", "r11", "memory"
        );
    }

    // O_WRONLY|O_CREAT|O_TRUNC|O_CLOEXEC
    const create_opts: u64 = 0x80241;

    pub fn write(fd: u64, buf: []const u8) void {
        _ = syscall3(1, fd, @ptrToInt(buf.ptr), buf.len);
    }
    pub fn create(pathname: [:0]const u8) u64 {
        return syscall3(2, @ptrToInt(pathname.ptr), create_opts, 0o640);
    }
    pub fn close(fd: u64) void {
        _ = syscall1(3, fd);
    }
    pub fn exit(rc: u64) noreturn {
        _ = syscall1(60, rc);
        unreachable;
    }
};
pub usingnamespace common;
