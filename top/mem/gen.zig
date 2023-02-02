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
    auto_alignment: bool = false,
    lazy_alignment: bool = false,
    unit_alignment: bool = false,
    disjunct_alignment: bool = false,
    single_packed_approximate_capacity: bool = false,
    double_packed_approximate_capacity: bool = false,

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
            : "rcx", "r11", "memory", "rax"
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

    pub fn write(fd: u64, buf: []const u8) void {
        _ = syscall3(1, fd, @ptrToInt(buf.ptr), buf.len);
    }
    pub fn create(pathname: [:0]const u8) u64 {
        return syscall3(2, @ptrToInt(pathname.ptr), 0x80241, 0o640);
    }
    pub fn close(fd: u64) void {
        _ = syscall1(3, fd);
    }
    fn map(addr: u64, len: u64) void {
        _ = syscall6(9, addr, len, 0x1 | 0x2, 0x20 | 0x02 | 0x100000, ~@as(u64, 0), 0);
    }
    fn unmap(addr: u64, len: u64) void {
        _ = syscall2(11, addr, len);
    }
    pub noinline fn exit(rc: u64) noreturn {
        _ = syscall1(60, rc);
        unreachable;
    }
};
pub usingnamespace common;

fn alignAbove(value: u64, comptime alignment: u64) u64 {
    return (value + (alignment - 1)) & ~(alignment - 1);
}
fn alignBelow(value: u64, comptime alignment: u64) u64 {
    return value & ~(alignment - 1);
}
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
        common.map(allocator.finish, len);
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
        common.map(start_addr, page_size);
        return .{
            .start = start_addr,
            .next = start_addr,
            .finish = start_addr + page_size,
        };
    }
    pub fn deinit(allocator: *Allocator) void {
        common.unmap(allocator.start, allocator.capacity());
        allocator.next = allocator.start;
        allocator.finish = allocator.start;
    }
};
