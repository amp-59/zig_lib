const bits = @import("../bits.zig");
const math = @import("../math.zig");
const algo = @import("../algo.zig");
fn automatic_storage_address(impl: anytype) u64 {
    return @intFromPtr(impl) + @offsetOf(@TypeOf(impl.*), "auto");
}
pub fn pointerOne(comptime child: type, s_lb_addr: u64) *child {
    @setRuntimeSafety(false);
    return @as(*child, @ptrFromInt(s_lb_addr));
}
pub fn pointerMany(comptime child: type, s_lb_addr: u64) [*]child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(s_lb_addr));
}
pub fn pointerManyWithSentinel(
    comptime child: type,
    addr: u64,
    comptime sentinel: child,
) [*:sentinel]child {
    @setRuntimeSafety(false);
    return @as([*:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerSlice(comptime child: type, addr: u64, count: u64) []child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(addr))[0..count];
}
pub fn pointerSliceWithSentinel(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime sentinel: child,
) [:sentinel]child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(addr))[0..count :sentinel];
}
pub fn pointerCount(
    comptime child: type,
    addr: u64,
    comptime count: u64,
) *[count]child {
    @setRuntimeSafety(false);
    return @ptrFromInt(addr);
}
pub fn pointerCountWithSentinel(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
) *[count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*[count:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerOpaque(comptime child: type, any: *const anyopaque) *const child {
    @setRuntimeSafety(false);
    return @as(*align(@max(1, @alignOf(child))) const child, @ptrCast(@alignCast(any)));
}
pub fn pointerOneAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) *align(alignment) child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerManyAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) [*]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerManyWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [*:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*:sentinel]align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerSliceAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime alignment: u64,
) []align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count];
}
pub fn pointerSliceWithSentinelAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count :sentinel];
}
pub fn pointerCountAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime alignment: u64,
) *align(alignment) [count]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count]child, @ptrFromInt(addr));
}
pub fn pointerCountWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) *align(alignment) [count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerOpaqueAligned(
    comptime child: type,
    any: *const anyopaque,
    comptime alignment: u64,
) *const child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) const child, @ptrCast(any));
}
pub fn copy(dst: u64, src: u64, bytes: u64, comptime high_alignment: u64) void {
    const unit_type: type = @Type(.{ .Int = .{
        .bits = 8 *% high_alignment,
        .signedness = .unsigned,
    } });
    var index: u64 = 0;
    @setRuntimeSafety(false);
    while (index != bytes / high_alignment) : (index +%= 1) {
        @as([*]unit_type, @ptrFromInt(dst))[index] = @as([*]const unit_type, @ptrFromInt(src))[index];
    }
}
pub const Specification0 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
};
pub const Specification1 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification2 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
};
pub const Specification3 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification4 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
};
pub const Specification5 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification6 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
};
pub const Specification7 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification8 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification9 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification10 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification11 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification12 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification13 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification14 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification15 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification16 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification17 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification18 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification19 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification20 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification21 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification22 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification23 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification24 = struct {
    low_alignment: u64,
};
pub const Specification25 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification26 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification27 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification28 = struct {
    low_alignment: u64,
};
pub const Specification29 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification30 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification31 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification32 = struct {
    low_alignment: u64,
};
pub const Specification33 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification34 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification35 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification36 = struct {
    low_alignment: u64,
};
pub const Specification37 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification38 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification39 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification40 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification41 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification42 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification43 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification44 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification45 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification46 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification47 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification48 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification49 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification50 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification51 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification52 = struct {
    child: type,
    low_alignment: u64,
};
pub const Specification53 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification54 = struct {
    child: type,
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification55 = struct {
    child: type,
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification56 = struct {
    low_alignment: u64,
};
pub const Specification57 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification58 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification59 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification60 = struct {
    low_alignment: u64,
};
pub const Specification61 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification62 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification63 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification64 = struct {
    low_alignment: u64,
};
pub const Specification65 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification66 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification67 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification68 = struct {
    low_alignment: u64,
};
pub const Specification69 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
};
pub const Specification70 = struct {
    low_alignment: u64,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification71 = struct {
    low_alignment: u64,
    sentinel: *const anyopaque,
    arena: struct {
        lb_addr: u64,
        up_addr: u64,
    },
};
pub const Specification72 = struct {
    child: type,
    low_alignment: u64,
    Allocator: type,
};
pub const Specification73 = struct {
    child: type,
    low_alignment: u64,
    Allocator: type,
    sentinel: *const anyopaque,
};
pub const Specification74 = struct {
    child: type,
    low_alignment: u64,
    Allocator: type,
};
pub const Specification75 = struct {
    child: type,
    low_alignment: u64,
    Allocator: type,
    sentinel: *const anyopaque,
};
pub const Specification76 = struct {
    low_alignment: u64,
    Allocator: type,
};
pub const Specification77 = struct {
    low_alignment: u64,
    Allocator: type,
    sentinel: *const anyopaque,
};
pub const Specification78 = struct {
    low_alignment: u64,
    Allocator: type,
};
pub const Specification79 = struct {
    low_alignment: u64,
    Allocator: type,
    sentinel: *const anyopaque,
};
const allocate0 = struct {
    s_lb_addr: u64,
    s_up_addr: u64,
};
const allocate1 = struct {
    s_lb_addr: u64,
    s_ab_addr: u64,
    s_up_addr: u64,
};
const allocate2 = struct {
    s_lb_addr: u64,
};
const allocate3 = struct {
    s_lb_addr: u64,
    s_ab_addr: u64,
};
const allocate4 = struct {
    s_ab_addr: u64,
};
const resize0 = struct {
    t_up_addr: u64,
};
const move0 = struct {
    t_lb_addr: u64,
    t_up_addr: u64,
};
const move1 = struct {
    t_lb_addr: u64,
    t_ab_addr: u64,
    t_up_addr: u64,
};
const move2 = struct {
    t_lb_addr: u64,
};
const move3 = struct {
    t_lb_addr: u64,
    t_ab_addr: u64,
};
const reallocate0 = struct {
    t_lb_addr: u64,
    t_up_addr: u64,
};
const reallocate1 = struct {
    t_lb_addr: u64,
    t_ab_addr: u64,
    t_up_addr: u64,
};
const reallocate2 = struct {
    t_lb_addr: u64,
};
const reallocate3 = struct {
    t_lb_addr: u64,
    t_ab_addr: u64,
};
const deallocate0 = struct {};
pub fn AutomaticStructuredReadWrite(comptime impl_spec: Specification0) type {
    return (struct {
        auto: [impl_spec.count]impl_spec.child,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
    });
}
pub fn AutomaticStructuredReadWriteSentinel(comptime impl_spec: Specification1) type {
    return (struct {
        auto: [impl_spec.count:impl_spec.sentinel]impl_spec.child,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
    });
}
pub fn AutomaticStructuredReadWriteStream(comptime impl_spec: Specification2) type {
    return (struct {
        auto: [impl_spec.count]impl_spec.child,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
    });
}
pub fn AutomaticStructuredReadWriteStreamSentinel(comptime impl_spec: Specification3) type {
    return (struct {
        auto: [impl_spec.count:impl_spec.sentinel]impl_spec.child,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
    });
}
pub fn AutomaticStructuredReadWriteResize(comptime impl_spec: Specification4) type {
    return (struct {
        auto: [impl_spec.count]impl_spec.child,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
    });
}
pub fn AutomaticStructuredReadWriteResizeSentinel(comptime impl_spec: Specification5) type {
    return (struct {
        auto: [impl_spec.count:impl_spec.sentinel]impl_spec.child,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
    });
}
pub fn AutomaticStructuredReadWriteStreamResize(comptime impl_spec: Specification6) type {
    return (struct {
        auto: [impl_spec.count]impl_spec.child,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
    });
}
pub fn AutomaticStructuredReadWriteStreamResizeSentinel(comptime impl_spec: Specification7) type {
    return (struct {
        auto: [impl_spec.count:impl_spec.sentinel]impl_spec.child,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(@intFromPtr(impl), @offsetOf(Implementation, "auto"));
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
    });
}
pub fn DynamicStructuredReadWriteLazyAlignment(comptime impl_spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteUnitAlignment(comptime impl_spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteDisjunctAlignment(comptime impl_spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteSentinelLazyAlignment(comptime impl_spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteSentinelUnitAlignment(comptime impl_spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteSentinelDisjunctAlignment(comptime impl_spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaLazyAlignment(comptime impl_spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaUnitAlignment(comptime impl_spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaDisjunctAlignment(comptime impl_spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaSentinelLazyAlignment(comptime impl_spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaSentinelUnitAlignment(comptime impl_spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteArenaSentinelDisjunctAlignment(comptime impl_spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamLazyAlignment(comptime impl_spec: Specification12) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamUnitAlignment(comptime impl_spec: Specification12) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamDisjunctAlignment(comptime impl_spec: Specification12) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamSentinelLazyAlignment(comptime impl_spec: Specification13) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamSentinelUnitAlignment(comptime impl_spec: Specification13) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamSentinelDisjunctAlignment(comptime impl_spec: Specification13) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaLazyAlignment(comptime impl_spec: Specification14) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaUnitAlignment(comptime impl_spec: Specification14) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaDisjunctAlignment(comptime impl_spec: Specification14) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaSentinelLazyAlignment(comptime impl_spec: Specification15) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaSentinelUnitAlignment(comptime impl_spec: Specification15) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamArenaSentinelDisjunctAlignment(comptime impl_spec: Specification15) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification16) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification16) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeDisjunctAlignment(comptime impl_spec: Specification16) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification17) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification17) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeSentinelDisjunctAlignment(comptime impl_spec: Specification17) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaLazyAlignment(comptime impl_spec: Specification18) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaUnitAlignment(comptime impl_spec: Specification18) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaDisjunctAlignment(comptime impl_spec: Specification18) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification19) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification19) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification19) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification20) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification20) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeDisjunctAlignment(comptime impl_spec: Specification20) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification21) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification21) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeSentinelDisjunctAlignment(comptime impl_spec: Specification21) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaLazyAlignment(comptime impl_spec: Specification22) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaUnitAlignment(comptime impl_spec: Specification22) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaDisjunctAlignment(comptime impl_spec: Specification22) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification23) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification23) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification23) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteLazyAlignment(comptime impl_spec: Specification24) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteUnitAlignment(comptime impl_spec: Specification24) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteDisjunctAlignment(comptime impl_spec: Specification24) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteSentinelLazyAlignment(comptime impl_spec: Specification25) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteSentinelUnitAlignment(comptime impl_spec: Specification25) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteSentinelDisjunctAlignment(comptime impl_spec: Specification25) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaLazyAlignment(comptime impl_spec: Specification26) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaUnitAlignment(comptime impl_spec: Specification26) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaDisjunctAlignment(comptime impl_spec: Specification26) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaSentinelLazyAlignment(comptime impl_spec: Specification27) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaSentinelUnitAlignment(comptime impl_spec: Specification27) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn allocate(s: allocate0) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate0) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .up_word = t.up_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteArenaSentinelDisjunctAlignment(comptime impl_spec: Specification27) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamLazyAlignment(comptime impl_spec: Specification28) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamUnitAlignment(comptime impl_spec: Specification28) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamDisjunctAlignment(comptime impl_spec: Specification28) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamSentinelLazyAlignment(comptime impl_spec: Specification29) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamSentinelUnitAlignment(comptime impl_spec: Specification29) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamSentinelDisjunctAlignment(comptime impl_spec: Specification29) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaLazyAlignment(comptime impl_spec: Specification30) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaUnitAlignment(comptime impl_spec: Specification30) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaDisjunctAlignment(comptime impl_spec: Specification30) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaSentinelLazyAlignment(comptime impl_spec: Specification31) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaSentinelUnitAlignment(comptime impl_spec: Specification31) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamArenaSentinelDisjunctAlignment(comptime impl_spec: Specification31) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification32) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification32) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeDisjunctAlignment(comptime impl_spec: Specification32) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification33) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification33) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeSentinelDisjunctAlignment(comptime impl_spec: Specification33) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaLazyAlignment(comptime impl_spec: Specification34) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaUnitAlignment(comptime impl_spec: Specification34) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaDisjunctAlignment(comptime impl_spec: Specification34) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification35) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification35) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification35) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification36) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification36) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeDisjunctAlignment(comptime impl_spec: Specification36) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification37) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification37) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeSentinelDisjunctAlignment(comptime impl_spec: Specification37) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaLazyAlignment(comptime impl_spec: Specification38) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaUnitAlignment(comptime impl_spec: Specification38) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub const writable_byte_count = allocated_byte_count;
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaDisjunctAlignment(comptime impl_spec: Specification38) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification39) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification39) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(allocated_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification39) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.sub64(impl.up_word, impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_count(impl), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return math.sub64(math.sub64(allocated_byte_count(impl), impl_spec.high_alignment), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate1) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: resize0) void {
            impl.* = .{ .up_word = t.up_addr };
        }
        pub inline fn move(impl: *Implementation, t: move1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(s_impl), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteLazyAlignment(comptime impl_spec: Specification40) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteUnitAlignment(comptime impl_spec: Specification40) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteDisjunctAlignment(comptime impl_spec: Specification40) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteSentinelLazyAlignment(comptime impl_spec: Specification41) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteSentinelUnitAlignment(comptime impl_spec: Specification41) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteSentinelDisjunctAlignment(comptime impl_spec: Specification41) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaLazyAlignment(comptime impl_spec: Specification42) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaUnitAlignment(comptime impl_spec: Specification42) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaDisjunctAlignment(comptime impl_spec: Specification42) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaSentinelLazyAlignment(comptime impl_spec: Specification43) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaSentinelUnitAlignment(comptime impl_spec: Specification43) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteArenaSentinelDisjunctAlignment(comptime impl_spec: Specification43) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamLazyAlignment(comptime impl_spec: Specification44) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamUnitAlignment(comptime impl_spec: Specification44) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamDisjunctAlignment(comptime impl_spec: Specification44) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamSentinelLazyAlignment(comptime impl_spec: Specification45) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamSentinelUnitAlignment(comptime impl_spec: Specification45) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamSentinelDisjunctAlignment(comptime impl_spec: Specification45) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaLazyAlignment(comptime impl_spec: Specification46) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaUnitAlignment(comptime impl_spec: Specification46) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaDisjunctAlignment(comptime impl_spec: Specification46) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaSentinelLazyAlignment(comptime impl_spec: Specification47) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaSentinelUnitAlignment(comptime impl_spec: Specification47) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamArenaSentinelDisjunctAlignment(comptime impl_spec: Specification47) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification48) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification48) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeDisjunctAlignment(comptime impl_spec: Specification48) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification49) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification49) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeSentinelDisjunctAlignment(comptime impl_spec: Specification49) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaLazyAlignment(comptime impl_spec: Specification50) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaUnitAlignment(comptime impl_spec: Specification50) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaDisjunctAlignment(comptime impl_spec: Specification50) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification51) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification51) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification51) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification52) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification52) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeDisjunctAlignment(comptime impl_spec: Specification52) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification53) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification53) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeSentinelDisjunctAlignment(comptime impl_spec: Specification53) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaLazyAlignment(comptime impl_spec: Specification54) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaUnitAlignment(comptime impl_spec: Specification54) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaDisjunctAlignment(comptime impl_spec: Specification54) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification55) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification55) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticStructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification55) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteLazyAlignment(comptime impl_spec: Specification56) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteUnitAlignment(comptime impl_spec: Specification56) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteDisjunctAlignment(comptime impl_spec: Specification56) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteSentinelLazyAlignment(comptime impl_spec: Specification57) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteSentinelUnitAlignment(comptime impl_spec: Specification57) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteSentinelDisjunctAlignment(comptime impl_spec: Specification57) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaLazyAlignment(comptime impl_spec: Specification58) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaUnitAlignment(comptime impl_spec: Specification58) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaDisjunctAlignment(comptime impl_spec: Specification58) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaSentinelLazyAlignment(comptime impl_spec: Specification59) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaSentinelUnitAlignment(comptime impl_spec: Specification59) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn allocate(s: allocate2) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn move(impl: *Implementation, t: move2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteArenaSentinelDisjunctAlignment(comptime impl_spec: Specification59) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr) };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr) };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamLazyAlignment(comptime impl_spec: Specification60) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamUnitAlignment(comptime impl_spec: Specification60) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamDisjunctAlignment(comptime impl_spec: Specification60) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamSentinelLazyAlignment(comptime impl_spec: Specification61) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamSentinelUnitAlignment(comptime impl_spec: Specification61) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamSentinelDisjunctAlignment(comptime impl_spec: Specification61) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaLazyAlignment(comptime impl_spec: Specification62) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaUnitAlignment(comptime impl_spec: Specification62) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaDisjunctAlignment(comptime impl_spec: Specification62) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaSentinelLazyAlignment(comptime impl_spec: Specification63) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaSentinelUnitAlignment(comptime impl_spec: Specification63) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ss_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ss_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamArenaSentinelDisjunctAlignment(comptime impl_spec: Specification63) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification64) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification64) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeDisjunctAlignment(comptime impl_spec: Specification64) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification65) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification65) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeSentinelDisjunctAlignment(comptime impl_spec: Specification65) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaLazyAlignment(comptime impl_spec: Specification66) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaUnitAlignment(comptime impl_spec: Specification66) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaDisjunctAlignment(comptime impl_spec: Specification66) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification67) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification67) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr, .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification67) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification68) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification68) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeDisjunctAlignment(comptime impl_spec: Specification68) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification69) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification69) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeSentinelDisjunctAlignment(comptime impl_spec: Specification69) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaLazyAlignment(comptime impl_spec: Specification70) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaUnitAlignment(comptime impl_spec: Specification70) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaDisjunctAlignment(comptime impl_spec: Specification70) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaSentinelLazyAlignment(comptime impl_spec: Specification71) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.alignA64(allocated_byte_address(impl), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaSentinelUnitAlignment(comptime impl_spec: Specification71) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(comptime impl_spec: Specification71) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: Static = writable_byte_count,
        comptime aligned_byte_count: Static = aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return bits.andn64(impl.lb_word, math.sub64(impl_spec.low_alignment, 1));
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return math.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return math.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count = writable_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return math.add64(aligned_byte_count(), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return math.mul64(impl_spec.count, @sizeOf(impl_spec.child));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return math.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate3) Implementation {
            return .{
                .lb_word = math.subOr64(s.ab_addr, s.lb_addr, s.ab_addr),
                .ss_word = s.ab_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn move(impl: *Implementation, t: move3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
        pub inline fn reallocate(impl: *Implementation, t: reallocate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = math.subOr64(t.ab_addr, t.lb_addr, t.ab_addr),
                .ss_word = t.ab_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(aligned_byte_address(s_impl), aligned_byte_count(), aligned_byte_address(impl), impl_spec.high_alignment);
        }
    });
}
pub fn ParametricStructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification72) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification72) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification73) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification73) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification74) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification74) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification75) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricStructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification75) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteResizeLazyAlignment(comptime impl_spec: Specification76) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteResizeUnitAlignment(comptime impl_spec: Specification76) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteResizeSentinelLazyAlignment(comptime impl_spec: Specification77) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteResizeSentinelUnitAlignment(comptime impl_spec: Specification77) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteStreamResizeLazyAlignment(comptime impl_spec: Specification78) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteStreamResizeUnitAlignment(comptime impl_spec: Specification78) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const aligned_byte_count = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteStreamResizeSentinelLazyAlignment(comptime impl_spec: Specification79) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return bits.alignA64(allocator.unallocated_byte_address(), impl_spec.low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
pub fn ParametricUnstructuredReadWriteStreamResizeSentinelUnitAlignment(comptime impl_spec: Specification79) type {
    return (struct {
        comptime allocated_byte_address: Slave = allocated_byte_address,
        comptime aligned_byte_address: Slave = aligned_byte_address,
        comptime unallocated_byte_address: Slave = unallocated_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unwritable_byte_address: Slave = unwritable_byte_address,
        comptime allocated_byte_count: Slave = allocated_byte_count,
        comptime writable_byte_count: Slave = writable_byte_count,
        comptime aligned_byte_count: Slave = aligned_byte_count,
        const Implementation = @This();
        const Slave = fn (*const impl_spec.Allocator) callconv(.Inline) u64;
        const unit_alignment: u64 = impl_spec.low_alignment;
        pub inline fn allocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), impl_spec.high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: *const impl_spec.Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.add64(aligned_byte_count(allocator), impl_spec.high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return math.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: *const impl_spec.Allocator) u64 {
            return math.sub64(undefined_byte_address(impl), allocated_byte_address(allocator));
        }
        pub inline fn define(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn undefine(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ub_word, x_bytes);
            pointerOne(impl_spec.child, undefined_byte_address(impl)).* = pointerOpaque(impl_spec.child, impl_spec.sentinel).*;
        }
        pub inline fn seek(impl: *Implementation, x_bytes: u64) void {
            math.addEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn tell(impl: *Implementation, x_bytes: u64) void {
            math.subEqu64(&impl.ss_word, x_bytes);
        }
        pub inline fn allocate(s: allocate4) Implementation {
            return .{ .ss_word = s.ab_addr, .ub_word = s.ab_addr };
        }
    });
}
