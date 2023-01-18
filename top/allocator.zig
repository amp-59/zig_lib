const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const algo = @import("./algo.zig");
const builtin = @import("./builtin.zig");
const container = @import("./container.zig");
pub const AllocatorOptions = struct {
    /// Experimental feature:
    check_parametric: bool = builtin.is_debug,
    /// Count concurrent allocations, return to head if zero.
    count_allocations: bool = builtin.is_debug,
    /// Count each unique set of side-effects.
    count_branches: bool = builtin.is_debug,
    /// Count the number of bytes writable by clients.
    count_useful_bytes: bool = builtin.is_debug,
    /// Halt program execution if not all free on deinit.
    require_all_free_deinit: bool = builtin.is_debug,
    /// Halt program execution with error if frees are not in reverse allocation
    /// order.
    require_filo_free: bool = builtin.is_debug,
    /// Each return address must be at least this aligned.
    unit_alignment: u64 = 1,
    require_length_aligned: bool = true,
    /// Each new mapping must at least double the size of the existing
    /// mapped segment.
    require_geometric_growth: bool = builtin.is_fast,
    /// Remap as one large segment, instead of small additional segments.
    require_mremap: bool = true,
    /// Populate (prefault) mappings
    require_populate: bool = false,
    /// Size of mapping at init.
    init_commit: ?u64 = if (builtin.is_fast) 32 * 1024 else null,
    /// Halt if size of total mapping exceeds quota.
    max_commit: ?u64 = if (builtin.is_safe) 16 * 1024 * 1024 * 1024 else null,
    /// Halt if size of next mapping exceeds quota.
    max_acquire: ?u64 = if (builtin.is_safe) 2 * 1024 * 1024 * 1024 else null,
    /// Used to test metadata
    no_system_calls: bool = false,
    /// Lock on arena acquisition and release
    thread_safe: bool = builtin.is_safe,
    /// Allocations are tracked as unique entities across resizes. (This setting
    /// currently has no effect, because the client trace list has not been
    /// implemented for this allocator).
    trace_clients: bool = false,
    /// Reports rendered relative to the last report, unchanged quantities
    /// are omitted.
    trace_state: bool = false,
    /// Does nothing
    trace_saved_addresses: bool = false,
};
pub const AllocatorLogging = packed struct {
    /// Report arena acquisition and release
    arena: builtin.Logging = .{},
    /// Report updates to allocator state
    head: bool = default,
    sentinel: bool = default,
    metadata: bool = default,
    branches: bool = default,
    /// Report system calls
    map: builtin.Logging = .{},
    unmap: builtin.Logging = .{},
    remap: builtin.Logging = .{},
    advise: builtin.Logging = .{},
    /// Report when a reference is created.
    allocate: bool = default,
    /// Report when a reference is modified (move/resize).
    reallocate: bool = default,
    /// Report when a reference is converted to another kind of reference.
    reinterpret: bool = default,
    /// Report when a reference is destroyed.
    deallocate: bool = default,
    const default: bool = builtin.is_verbose;
    inline fn isSilent(comptime logging: AllocatorLogging) bool {
        comptime {
            return 0 == meta.leastBitCast(logging);
        }
    }
};
const _1: mem.Amount = .{ .count = 1 };
const default_address_space_type = builtin.configExtra(
    "AddressSpace",
    type,
    builtin.info.address_space.defaultValue,
    .{ArenaAllocatorSpec},
);
pub const AllocatorErrors = struct {
    map: ?[]const sys.ErrorCode = sys.mmap_errors,
    remap: ?[]const sys.ErrorCode = sys.mremap_errors,
    unmap: ?[]const sys.ErrorCode = null,
    acquire: ?mem.ResourceError = error.UnderSupply,
    release: ?mem.ResourceError = null,
};
pub const ArenaAllocatorSpec = struct {
    AddressSpace: type = default_address_space_type,
    arena_index: comptime_int,
    options: AllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    pub fn next(comptime spec: ArenaAllocatorSpec) ArenaAllocatorSpec {
        var ret: ArenaAllocatorSpec = spec;
        ret.arena_index += 1;
        return ret;
    }
    pub fn prev(comptime spec: ArenaAllocatorSpec) ArenaAllocatorSpec {
        var ret: ArenaAllocatorSpec = spec;
        ret.arena_index -= 1;
        return ret;
    }
};
pub const PageAllocatorSpec = struct {
    AddressSpace: type = default_address_space_type,
    arena_index: comptime_int,
    options: AllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    pub fn next(comptime spec: PageAllocatorSpec) PageAllocatorSpec {
        var ret: PageAllocatorSpec = spec;
        ret.arena_index += 1;
        return ret;
    }
    pub fn prev(comptime spec: PageAllocatorSpec) PageAllocatorSpec {
        var ret: PageAllocatorSpec = spec;
        ret.arena_index -= 1;
        return ret;
    }
};
pub const RtArenaAllocatorSpec = struct {
    AddressSpace: type = builtin.AddressSpace,
    options: AllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    pub fn next(comptime spec: RtArenaAllocatorSpec) RtArenaAllocatorSpec {
        var ret: RtArenaAllocatorSpec = spec;
        ret.arena_index += 1;
        return ret;
    }
    pub fn prev(comptime spec: RtArenaAllocatorSpec) RtArenaAllocatorSpec {
        var ret: RtArenaAllocatorSpec = spec;
        ret.arena_index -= 1;
        return ret;
    }
};
fn ReturnTypes(comptime Allocator: type) type {
    return opaque {
        const MMapError: type = Allocator.map_spec.Errors(.mmap);
        const MUnmapError: type = Allocator.map_spec.Errors(.munmap);
        const MRemapError: type = Allocator.remap_spec.Errors(.mremap);
        pub const acquire_allocator: type = blk: {
            if (Allocator.allocator_spec.errors.acquire != null) {
                if (Allocator.allocator_spec.errors.map != null and
                    Allocator.allocator_spec.options.init_commit != null or
                    Allocator.allocator_spec.options.require_mremap)
                {
                    break :blk (MMapError || mem.ResourceError)!Allocator;
                }
                break :blk mem.ResourceError!Allocator;
            } else {
                if (Allocator.allocator_spec.errors.map != null and
                    Allocator.allocator_spec.options.init_commit != null or
                    Allocator.allocator_spec.options.require_mremap)
                {
                    break :blk MMapError!Allocator;
                }
            }
        };
        pub const release_allocator: type = blk: {
            if (Allocator.allocator_spec.errors.release != null) {
                if (Allocator.allocator_spec.errors.unmap != null) {
                    break :blk (MUnmapError || mem.ResourceError)!void;
                }
                break :blk mem.ResourceError!void;
            } else {
                if (Allocator.allocator_spec.errors.unmap != null) {
                    break :blk MUnmapError!void;
                }
                break :blk void;
            }
        };
        pub fn allocate_payload(comptime s_impl_type: type) type {
            if (Allocator.allocator_spec.options.require_mremap) {
                return Allocator.resize_spec.Replaced(.mmap, s_impl_type);
            } else {
                return Allocator.resize_spec.Replaced(.mremap, s_impl_type);
            }
        }
        pub const allocate_void: type = blk: {
            if (Allocator.allocator_spec.options.require_mremap) {
                break :blk Allocator.resize_spec.Unwrapped(.mmap);
            } else {
                break :blk Allocator.resize_spec.Unwrapped(.mremap);
            }
        };
        pub const deallocate_void: type = Allocator.unmap_spec.Unwrapped(.munmap);
    };
}
fn Metadata(comptime options: AllocatorOptions) type {
    return struct {
        branches: meta.maybe(options.count_branches, Branches) = .{},
        holder: meta.maybe(options.check_parametric, u64) = 0,
        saved: meta.maybe(options.trace_saved_addresses, u64) = 0,
        count: meta.maybe(options.count_allocations, u64) = 0,
        utility: meta.maybe(options.count_useful_bytes, u64) = 0,
    };
}
fn Reference(comptime options: AllocatorOptions) type {
    return struct {
        branches: meta.maybe(options.trace_state, Branches) = .{},
        ub_addr: meta.maybe(options.trace_state, u64) = 0,
        up_addr: meta.maybe(options.trace_state, u64) = 0,
        holder: meta.maybe(options.check_parametric, u64) = 0,
        saved: meta.maybe(options.trace_saved_addresses, u64) = 0,
        count: meta.maybe(options.count_allocations, u64) = 0,
        utility: meta.maybe(options.count_useful_bytes, u64) = 0,
    };
}
pub fn GenericArenaAllocator(comptime spec: ArenaAllocatorSpec) type {
    return struct {
        comptime lb_addr: u64 = lb_addr,
        ub_addr: u64,
        up_addr: u64,
        comptime ua_addr: u64 = ua_addr,
        metadata: Metadata(spec.options) = .{},
        reference: Reference(spec.options) = .{},
        const Allocator = @This();
        const Value = fn (*const Allocator) callconv(.Inline) u64;
        const ResizeSpec = if (allocator_spec.options.require_mremap) mem.RemapSpec else mem.MapSpec;
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const allocator_spec: ArenaAllocatorSpec = spec;
        pub const arena_index: u8 = allocator_spec.arena_index;
        pub const arena: mem.Arena = allocator_spec.AddressSpace.arena(arena_index);
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        const resize_spec: ResizeSpec = if (allocator_spec.options.require_mremap) remap_spec else map_spec;
        const lb_addr: u64 = arena.low();
        const ua_addr: u64 = arena.high();
        const acq_part_spec: mem.AcquireSpec = .{
            .errors = allocator_spec.errors.acquire,
            .logging = allocator_spec.logging.arena,
        };
        const rel_part_spec: mem.ReleaseSpec = .{
            .errors = allocator_spec.errors.release,
            .logging = allocator_spec.logging.arena,
        };
        const map_spec: mem.MapSpec = .{
            .options = .{ .populate = allocator_spec.options.require_populate },
            .errors = allocator_spec.errors.map,
            .logging = allocator_spec.logging.map,
        };
        const remap_spec: mem.RemapSpec = .{
            .errors = allocator_spec.errors.remap,
            .logging = allocator_spec.logging.remap,
        };
        const unmap_spec: mem.UnmapSpec = .{
            .errors = allocator_spec.errors.unmap,
            .logging = allocator_spec.logging.unmap,
        };
        inline fn mapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.lb_addr;
        }
        inline fn unallocated_byte_address(allocator: *const Allocator) u64 {
            return allocator.ub_addr;
        }
        inline fn unmapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.up_addr;
        }
        inline fn unaddressable_byte_address(allocator: *const Allocator) u64 {
            return allocator.ua_addr;
        }
        inline fn allocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub const start: Value = mapped_byte_address;
        pub const next: Value = unallocated_byte_address;
        pub const finish: Value = unmapped_byte_address;
        pub const span: Value = allocated_byte_count;
        pub const capacity: Value = mapped_byte_count;
        pub const available: Value = unallocated_byte_count;
        fn allocate(allocator: *Allocator, s_up_addr: u64) void {
            allocator.ub_addr = s_up_addr;
        }
        fn deallocate(allocator: *Allocator, s_lb_addr: u64) void {
            if (Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = s_lb_addr;
            } else {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, s_lb_addr);
            }
        }
        pub fn reset(allocator: *Allocator) void {
            if (!Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, allocator.ub_addr);
            }
        }
        pub fn map(allocator: *Allocator, s_bytes: u64) Allocator.allocate_void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (allocator_spec.options.require_mremap) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + s_bytes));
                    allocator.up_addr += s_bytes;
                }
            } else if (s_bytes >= 4096) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.map(map_spec, allocator.finish(), t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.map(map_spec, allocator.finish(), s_bytes));
                    allocator.up_addr += s_bytes;
                }
            }
        }
        pub fn unmap(allocator: *Allocator, s_bytes: u64) Allocator.deallocate_void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (s_bytes >= 4096) {
                allocator.up_addr -= s_bytes;
                try meta.wrap(special.unmap(unmap_spec, allocator.finish(), s_bytes));
            }
        }
        pub fn unmapAbove(allocator: *Allocator, s_up_addr: u64) Allocator.deallocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const t_bytes: u64 = mach.sub64(t_ua_addr, allocator.start());
            const x_bytes: u64 = mach.sub64(allocator.capacity(), t_bytes);
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.utility, t_bytes);
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.count, t_bytes);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn mapBelow(allocator: *Allocator, s_up_addr: u64) Allocator.allocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const x_bytes: u64 = mach.sub64(t_ua_addr, allocator.finish());
            const t_bytes: u64 = mach.add64(allocator.capacity(), x_bytes);
            if (Allocator.allocator_spec.options.max_acquire) |max| {
                builtin.assertBelowOrEqual(u64, x_bytes, max);
            }
            if (Allocator.allocator_spec.options.max_commit) |max| {
                builtin.assertBelowOrEqual(u64, t_bytes, max);
            }
            return allocator.map(x_bytes);
        }
        fn reusable(allocator: *const Allocator) bool {
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                return allocator.metadata.utility == 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                return allocator.metadata.count == 0;
            }
            return false;
        }
        pub fn discard(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.check_parametric) {
                allocator.metadata.holder = 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count = 0;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility = 0;
            }
            allocator.ub_addr = lb_addr;
        }
        pub fn init(address_space: *AddressSpace) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            allocator = Allocator{ .ub_addr = lb_addr, .up_addr = lb_addr };
            try meta.wrap(special.static.acquire(acq_part_spec, AddressSpace, address_space, arena_index));
            if (allocator_spec.options.require_mremap) {
                const s_bytes: u64 = allocator_spec.options.init_commit orelse 4096;
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            } else if (allocator_spec.options.init_commit) |s_bytes| {
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            try meta.wrap(allocator.unmapAbove(allocator.start()));
            try meta.wrap(special.static.release(rel_part_spec, AddressSpace, address_space, arena_index));
        }
        pub usingnamespace ReturnTypes(Allocator);
        pub usingnamespace GenericConfiguration(Allocator);
        pub usingnamespace GenericInterface(Allocator);
        const Graphics = GenericAllocatorGraphics(Allocator);
        comptime {
            builtin.static.assertEqual(u64, 1, unit_alignment);
        }
    };
}
pub fn GenericRtArenaAllocator(comptime spec: RtArenaAllocatorSpec) type {
    return struct {
        lb_addr: u64,
        ub_addr: u64,
        up_addr: u64,
        ua_addr: u64,
        metadata: Metadata(spec.options) = .{},
        reference: Reference(spec.options) = .{},
        const Allocator = @This();
        const Value = fn (*const Allocator) callconv(.Inline) u64;
        const ResizeSpec = if (allocator_spec.options.require_mremap) mem.RemapSpec else mem.MapSpec;
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const allocator_spec: RtArenaAllocatorSpec = spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        const resize_spec: ResizeSpec = if (allocator_spec.options.require_mremap) remap_spec else map_spec;
        const acq_part_spec: mem.AcquireSpec = .{
            .errors = allocator_spec.errors.acquire,
            .logging = allocator_spec.logging.arena,
        };
        const rel_part_spec: mem.ReleaseSpec = .{
            .errors = allocator_spec.errors.release,
            .logging = allocator_spec.logging.arena,
        };
        const map_spec: mem.MapSpec = .{
            .options = .{ .populate = allocator_spec.options.require_populate },
            .errors = allocator_spec.errors.map,
            .logging = allocator_spec.logging.map,
        };
        const remap_spec: mem.RemapSpec = .{
            .errors = allocator_spec.errors.remap,
            .logging = allocator_spec.logging.remap,
        };
        const unmap_spec: mem.UnmapSpec = .{
            .errors = allocator_spec.errors.unmap,
            .logging = allocator_spec.logging.unmap,
        };
        inline fn mapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.lb_addr;
        }
        inline fn unallocated_byte_address(allocator: *const Allocator) u64 {
            return allocator.ub_addr;
        }
        inline fn unmapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.up_addr;
        }
        inline fn unaddressable_byte_address(allocator: *const Allocator) u64 {
            return allocator.ua_addr;
        }
        inline fn allocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub const start: Value = mapped_byte_address;
        pub const next: Value = unallocated_byte_address;
        pub const finish: Value = unmapped_byte_address;
        pub const span: Value = allocated_byte_count;
        pub const capacity: Value = mapped_byte_count;
        pub const available: Value = unallocated_byte_count;
        fn allocate(allocator: *Allocator, s_up_addr: u64) void {
            allocator.ub_addr = s_up_addr;
        }
        fn deallocate(allocator: *Allocator, s_lb_addr: u64) void {
            if (Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = s_lb_addr;
            } else {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, s_lb_addr);
            }
        }
        pub fn reset(allocator: *Allocator) void {
            if (!Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, allocator.ub_addr);
            }
        }
        const MMapError: type = map_spec.Errors(.mmap);
        const MUnmapError: type = map_spec.Errors(.munmap);
        const MRemapError: type = remap_spec.Errors(.mremap);
        pub fn map(allocator: *Allocator, s_bytes: u64) Allocator.allocate_void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (allocator_spec.options.require_mremap) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + s_bytes));
                    allocator.up_addr += s_bytes;
                }
            } else if (s_bytes >= 4096) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.map(map_spec, allocator.finish(), t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.map(map_spec, allocator.finish(), s_bytes));
                    allocator.up_addr += s_bytes;
                }
            }
        }
        pub fn unmap(allocator: *Allocator, s_bytes: u64) Allocator.deallocate_void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (s_bytes >= 4096) {
                allocator.up_addr -= s_bytes;
                return special.unmap(unmap_spec, unmapped_byte_address(allocator), s_bytes);
            }
        }
        pub fn unmapAbove(allocator: *Allocator, s_up_addr: u64) Allocator.deallocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const t_bytes: u64 = mach.sub64(t_ua_addr, allocator.start());
            const x_bytes: u64 = mach.sub64(allocator.capacity(), t_bytes);
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.utility, t_bytes);
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.count, t_bytes);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn mapBelow(allocator: *Allocator, s_up_addr: u64) Allocator.allocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const x_bytes: u64 = mach.sub64(t_ua_addr, allocator.finish());
            const t_bytes: u64 = mach.add64(allocator.capacity(), x_bytes);
            if (Allocator.allocator_spec.options.max_acquire) |max| {
                builtin.assertBelowOrEqual(u64, x_bytes, max);
            }
            if (Allocator.allocator_spec.options.max_commit) |max| {
                builtin.assertBelowOrEqual(u64, t_bytes, max);
            }
            return allocator.map(x_bytes);
        }
        fn reusable(allocator: *const Allocator) bool {
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                return allocator.metadata.utility == 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                return allocator.metadata.count == 0;
            }
            return false;
        }
        pub fn discard(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.check_parametric) {
                allocator.metadata.holder = 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count = 0;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility = 0;
            }
            allocator.ub_addr = allocator.lb_addr;
        }
        pub fn init(address_space: *AddressSpace, arena_index: u8) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            const lb_addr: u64 = allocator_spec.AddressSpace.low(arena_index);
            const ua_addr: u64 = allocator_spec.AddressSpace.high(arena_index);
            allocator = Allocator{ .lb_addr = lb_addr, .ub_addr = lb_addr, .up_addr = lb_addr, .ua_addr = ua_addr };
            try meta.wrap(special.acquire(acq_part_spec, AddressSpace, address_space, arena_index));
            if (allocator_spec.options.require_mremap) {
                const s_bytes: u64 = allocator_spec.options.init_commit orelse 4096;
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            } else if (allocator_spec.options.init_commit) |s_bytes| {
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            const arena_index: u8 = spec.AddressSpace.invert(allocator.lb_addr);
            try meta.wrap(allocator.unmapAbove(allocator.start()));
            try meta.wrap(special.release(rel_part_spec, AddressSpace, address_space, arena_index));
        }
        pub usingnamespace ReturnTypes(Allocator);
        pub usingnamespace GenericConfiguration(Allocator);
        pub usingnamespace GenericInterface(Allocator);
        const Graphics = GenericAllocatorGraphics(Allocator);
        comptime {
            builtin.static.assertEqual(u64, 1, unit_alignment);
        }
    };
}
pub fn GenericPageAllocator(comptime spec: PageAllocatorSpec) type {
    return struct {
        comptime lb_addr: u64 = lb_addr,
        ub_addr: u64,
        up_addr: u64,
        comptime ua_addr: u64 = ua_addr,
        metadata: Metadata(spec.options) = .{},
        reference: Reference(spec.options) = .{},
        const Allocator = @This();
        const Value = fn (*const Allocator) callconv(.Inline) u64;
        const ResizeSpec = if (allocator_spec.options.require_mremap) mem.RemapSpec else mem.MapSpec;
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const allocator_spec: PageAllocatorSpec = spec;
        pub const arena_index: u8 = allocator_spec.arena_index;
        pub const arena: mem.Arena = allocator_spec.AddressSpace.arena(arena_index);
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        const resize_spec: ResizeSpec = if (allocator_spec.options.require_mremap) remap_spec else map_spec;
        const lb_addr: u64 = arena.low();
        const ua_addr: u64 = arena.high();
        const acq_part_spec: mem.AcquireSpec = .{
            .errors = allocator_spec.errors.acquire,
            .logging = allocator_spec.logging.arena,
        };
        const rel_part_spec: mem.ReleaseSpec = .{
            .errors = allocator_spec.errors.release,
            .logging = allocator_spec.logging.arena,
        };
        const map_spec: mem.MapSpec = .{
            .options = .{ .populate = allocator_spec.options.require_populate },
            .errors = allocator_spec.errors.map,
            .logging = allocator_spec.logging.map,
        };
        const remap_spec: mem.RemapSpec = .{
            .errors = allocator_spec.errors.remap,
            .logging = allocator_spec.logging.remap,
        };
        const unmap_spec: mem.UnmapSpec = .{
            .errors = allocator_spec.errors.unmap,
            .logging = allocator_spec.logging.unmap,
        };
        inline fn mapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.lb_addr;
        }
        inline fn unallocated_byte_address(allocator: *const Allocator) u64 {
            return allocator.ub_addr;
        }
        inline fn unmapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.up_addr;
        }
        inline fn unaddressable_byte_address(allocator: *const Allocator) u64 {
            return allocator.ua_addr;
        }
        inline fn allocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub const start: Value = mapped_byte_address;
        pub const next: Value = unallocated_byte_address;
        pub const finish: Value = unmapped_byte_address;
        pub const span: Value = allocated_byte_count;
        pub const capacity: Value = mapped_byte_count;
        pub const available: Value = unallocated_byte_count;
        inline fn allocate(allocator: *Allocator, s_up_addr: u64) void {
            allocator.ub_addr = s_up_addr;
        }
        inline fn deallocate(allocator: *Allocator, s_lb_addr: u64) void {
            if (Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = s_lb_addr;
            } else {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, s_lb_addr);
            }
        }
        pub inline fn reset(allocator: *Allocator) void {
            if (!Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = mach.cmov64(allocator.reusable(), allocator.lb_addr, allocator.ub_addr);
            }
        }
        pub fn map(allocator: *Allocator, s_bytes: u64) Allocator.allocate_void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (allocator_spec.options.require_mremap) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.resize(remap_spec, allocator.start(), allocator.capacity(), allocator.capacity() + s_bytes));
                    allocator.up_addr += s_bytes;
                }
            } else if (s_bytes >= 4096) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.capacity(), s_bytes);
                    try meta.wrap(special.map(map_spec, allocator.finish(), t_bytes));
                    allocator.up_addr += t_bytes;
                } else {
                    try meta.wrap(special.map(map_spec, allocator.finish(), s_bytes));
                    allocator.up_addr += s_bytes;
                }
            }
        }
        pub fn unmap(allocator: *Allocator, s_bytes: u64) void {
            builtin.assertEqual(u64, s_bytes & 4095, 0);
            if (s_bytes >= 4096) {
                allocator.up_addr -= s_bytes;
                try meta.wrap(special.unmap(unmap_spec, allocator.finish(), s_bytes));
            }
        }
        pub fn unmapAbove(allocator: *Allocator, s_up_addr: u64) Allocator.deallocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const t_bytes: u64 = mach.sub64(t_ua_addr, allocator.start());
            const x_bytes: u64 = mach.sub64(allocator.capacity(), t_bytes);
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.utility, t_bytes);
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                builtin.assertBelowOrEqual(u64, allocator.metadata.count, t_bytes);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn mapBelow(allocator: *Allocator, s_up_addr: u64) Allocator.allocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const x_bytes: u64 = mach.sub64(t_ua_addr, allocator.finish());
            const t_bytes: u64 = mach.add64(allocator.capacity(), x_bytes);
            if (Allocator.allocator_spec.options.max_acquire) |max| {
                builtin.assertBelowOrEqual(u64, x_bytes, max);
            }
            if (Allocator.allocator_spec.options.max_commit) |max| {
                builtin.assertBelowOrEqual(u64, t_bytes, max);
            }
            return allocator.map(x_bytes);
        }
        inline fn reusable(allocator: *const Allocator) bool {
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                return allocator.metadata.utility == 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                return allocator.metadata.count == 0;
            }
            return false;
        }
        pub fn discard(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.check_parametric) {
                allocator.metadata.holder = 0;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count = 0;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility = 0;
            }
            allocator.ub_addr = lb_addr;
        }
        pub fn init(address_space: *AddressSpace) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            try meta.wrap(special.static.acquire(acq_part_spec, AddressSpace, address_space, arena_index));
            if (allocator_spec.options.require_mremap) {
                const s_bytes: u64 = allocator_spec.options.init_commit orelse 4096;
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            } else if (allocator_spec.options.init_commit) |s_bytes| {
                try meta.wrap(special.map(map_spec, unmapped_byte_address(&allocator), s_bytes));
                allocator.up_addr += s_bytes;
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            try meta.wrap(allocator.unmapAbove(allocator.start()));
            try meta.wrap(special.static.release(rel_part_spec, AddressSpace, address_space, arena_index));
        }
        pub usingnamespace ReturnTypes(Allocator);
        const Graphics = GenericAllocatorGraphics(Allocator);
        comptime {
            builtin.static.assertEqual(u64, 1, unit_alignment);
        }
    };
}
const Branches = struct {
    allocate: extern struct {
        static: extern struct {
            any_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
        } = .{},
        many: extern struct {
            any_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
        } = .{},
        holder: extern struct {
            any_aligned: u64 = 0,
            unit_aligned: u64 = 0,
        } = .{},
    } = .{},
    resize: extern struct {
        many: extern struct {
            below: extern struct {
                any_aligned: extern struct {
                    end_boundary: u64 = 0,
                    end_internal: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    end_boundary: u64 = 0,
                    end_internal: u64 = 0,
                } = .{},
            } = .{},
            above: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
        } = .{},
        holder: extern struct {
            below: extern struct {
                any_aligned: u64 = 0,
                unit_aligned: u64 = 0,
            } = .{},
            above: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
        } = .{},
    } = .{},
    move: extern struct {
        static: extern struct {
            any_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
        } = .{},
        many: extern struct {
            any_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                addressable: u64 = 0,
                unaddressable: u64 = 0,
            } = .{},
        } = .{},
    } = .{},
    reallocate: extern struct {
        many: extern struct {
            below: extern struct {
                any_aligned: extern struct {
                    end_boundary: u64 = 0,
                    end_internal: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    end_boundary: u64 = 0,
                    end_internal: u64 = 0,
                } = .{},
            } = .{},
            above: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
        } = .{},
    } = .{},
    convert: extern struct {
        any: extern struct {
            static: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
            many: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
        } = .{},
        holder: extern struct {
            static: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
            many: extern struct {
                any_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
                unit_aligned: extern struct {
                    addressable: u64 = 0,
                    unaddressable: u64 = 0,
                } = .{},
            } = .{},
            holder: extern struct {
                any_aligned: u64 = 0,
                unit_aligned: u64 = 0,
            } = .{},
        } = .{},
    } = .{},
    deallocate: extern struct {
        static: extern struct {
            any_aligned: extern struct {
                end_boundary: u64 = 0,
                end_internal: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                end_boundary: u64 = 0,
                end_internal: u64 = 0,
            } = .{},
        } = .{},
        many: extern struct {
            any_aligned: extern struct {
                end_boundary: u64 = 0,
                end_internal: u64 = 0,
            } = .{},
            unit_aligned: extern struct {
                end_boundary: u64 = 0,
                end_internal: u64 = 0,
            } = .{},
        } = .{},
        holder: extern struct {
            any_aligned: u64 = 0,
            unit_aligned: u64 = 0,
        } = .{},
    } = .{},
    fn sumBranches(branches: Branches, comptime field_name: []const u8) u64 {
        var sum: u64 = 0;
        for (@bitCast(
            [@divExact(@sizeOf(@TypeOf(@field(branches, field_name))), 8)]u64,
            @field(branches, field_name),
        )) |count| sum += count;
        return sum;
    }
    const Graphics = opaque {
        const PrintArray = mem.StaticString(8192);
        const branch_s: []const u8 = "branch:         ";
        const grand_total_s: []const u8 = "grand total:    ";
        pub fn showBranches(branches: Branches, array: *PrintArray, comptime field_name: []const u8) void {
            const Branch: type = meta.Field(Branches, field_name);
            const super_branch_name: [:0]const u8 = comptime fmt.about(field_name);
            const sum: u64 = branches.sumBranches(field_name);
            const value: Branch = @field(branches, field_name);
            showWithReferenceWriteInternal(Branch, value, value, array, "", super_branch_name);
            array.writeMany(super_branch_name);
            array.writeFormat(fmt.udh(sum));
            array.writeOne('\n');
        }
        pub fn showBranchesWithReference(
            t_branches: Branches,
            s_branches: *Branches,
            array: *PrintArray,
            comptime field_name: []const u8,
        ) void {
            const Branch: type = meta.Field(Branches, field_name);
            const super_branch_name: [:0]const u8 = comptime fmt.about(field_name);
            const s_sum: u64 = s_branches.sumBranches(field_name);
            const t_sum: u64 = t_branches.sumBranches(field_name);
            const t_value: Branch = @field(t_branches, field_name);
            const s_value: *Branch = &@field(s_branches, field_name);
            showWithReferenceWriteInternal(Branch, t_value, s_value, array, "", super_branch_name);
            array.writeMany(super_branch_name);
            array.writeFormat(fmt.udd(s_sum, t_sum));
            array.writeOne('\n');
        }
        fn showWriteInternal(
            comptime T: type,
            branch: T,
            array: *PrintArray,
            comptime branch_name: []const u8,
            super_branch_name: ?[]const u8,
        ) void {
            inline for (@typeInfo(@TypeOf(branch)).Struct.fields) |field| {
                const branch_label: [:0]const u8 = branch_name ++ field.name ++ ",";
                const value: field.type = @field(branch, field.name);
                if (@typeInfo(field.type) == .Struct) {
                    showWriteInternal(field.type, value, array, branch_label, super_branch_name);
                } else if (value != 0) {
                    if (super_branch_name) |super_branch_name_s| {
                        array.writeMany(super_branch_name_s);
                    }
                    array.writeMany(branch_s);
                    array.writeMany(branch_label);
                    array.writeOne('\t');
                    array.writeFormat(fmt.udh(value));
                    array.writeOne('\n');
                }
            }
        }
        fn showWithReferenceWriteInternal(
            comptime T: type,
            t_branch: T,
            s_branch: *T,
            array: *PrintArray,
            comptime branch_name: []const u8,
            super_branch_name: ?[]const u8,
        ) void {
            inline for (@typeInfo(@TypeOf(t_branch)).Struct.fields) |field| {
                const branch_label: [:0]const u8 = branch_name ++ field.name ++ ",";
                const t_value: field.type = @field(t_branch, field.name);
                const s_value: *field.type = &@field(s_branch, field.name);
                if (@typeInfo(field.type) == .Struct) {
                    showWithReferenceWriteInternal(field.type, t_value, s_value, array, branch_label, super_branch_name);
                    s_value.* = t_value;
                } else if (s_value.* != t_value) {
                    if (super_branch_name) |super_branch_name_s| {
                        array.writeMany(super_branch_name_s);
                    }
                    array.writeMany(branch_s);
                    array.writeMany(branch_label);
                    array.writeOne('\t');
                    array.writeFormat(fmt.udd(s_value.*, t_value));
                    array.writeOne('\n');
                }
            }
        }
        pub fn showWrite(branches: Branches, array: *PrintArray) void {
            showWriteInternal(Branches, branches, array, "", null);
        }
        pub fn showWithReferenceWrite(t_branches: Branches, s_branches: *Branches, array: *PrintArray) void {
            showWithReferenceWriteInternal(Branches, t_branches, s_branches, array, "", null);
        }
        pub fn show(branches: Branches) void {
            var array: PrintArray = .{};
            showWrite(branches, &array);
            file.noexcept.write(2, array.readAll());
        }
        pub fn showWithReference(t_branches: Branches, s_branches: *Branches) void {
            var array: PrintArray = .{};
            showWithReferenceWrite(t_branches, s_branches, &array);
            file.noexcept.write(2, array.readAll());
        }
    };
};
fn GenericConfiguration(comptime Allocator: type) type {
    return opaque {
        pub fn StructuredStaticViewWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticView(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticView(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticViewLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticView(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticView(comptime child: type, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticView(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticStreamVectorWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticStreamVector(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticStreamVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticStreamVector(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticStreamVectorLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticStreamVector(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticStreamVector(comptime child: type, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticStreamVector(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticVectorWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticVector(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticVector(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticVectorLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticVector(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticVector(comptime child: type, comptime count: u64) type {
            var options: container.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStaticVector(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn UnstructuredStaticViewHighAligned(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticView(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticViewLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticView(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticView(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticView(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVectorHighAligned(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticStreamVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVectorLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticStreamVector(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVector(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticStreamVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticVectorHighAligned(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticVectorLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticVector(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticVector(comptime bytes: u64) type {
            var options: container.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStaticVector(bytes, bytes, Allocator, options);
        }
        pub fn StructuredStreamVectorWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamVector(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamVector(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamVectorLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamVector(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamVector(comptime child: type) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamVector(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamViewWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamView(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamView(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamViewLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamView(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamView(comptime child: type) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamView(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredVectorWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredVector(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredVector(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredVectorLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredVector(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredVector(comptime child: type) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredVector(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredViewWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredView(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredView(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredViewLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredView(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredView(comptime child: type) type {
            var options: container.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredView(child, null, @alignOf(child), Allocator, options);
        }
        pub fn UnstructuredStreamVectorHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamVector(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamVectorLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamVector(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamVector(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamVector(low_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamViewHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamView(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamViewLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamView(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamView(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamView(low_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredVectorHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredVector(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredVectorLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredVector(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredVector(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredVector(low_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredViewHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredView(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredViewLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredView(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredView(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredView(low_alignment, high_alignment, Allocator, options);
        }
        pub fn StructuredStreamHolderWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamHolder(Allocator, child, &sentinel, @alignOf(child), options);
        }
        pub fn StructuredStreamHolderLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamHolder(Allocator, child, &sentinel, low_alignment, options);
        }
        pub fn StructuredStreamHolderLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamHolder(Allocator, child, null, low_alignment, options);
        }
        pub fn StructuredStreamHolder(comptime child: type) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredStreamHolder(Allocator, child, null, @alignOf(child), options);
        }
        pub fn StructuredHolderWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredHolder(Allocator, child, &sentinel, @alignOf(child), options);
        }
        pub fn StructuredHolderLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredHolder(Allocator, child, &sentinel, low_alignment, options);
        }
        pub fn StructuredHolderLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredHolder(Allocator, child, null, low_alignment, options);
        }
        pub fn StructuredHolder(comptime child: type) type {
            var options: container.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.StructuredHolder(Allocator, child, null, @alignOf(child), options);
        }
        pub fn UnstructuredStreamHolderHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamHolder(Allocator, high_alignment, high_alignment, options);
        }
        pub fn UnstructuredStreamHolderLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamHolder(Allocator, low_alignment, low_alignment, options);
        }
        pub fn UnstructuredStreamHolder(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamHolder(Allocator, low_alignment, high_alignment, options);
        }
        pub fn UnstructuredHolderHighAligned(comptime high_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredHolder(Allocator, high_alignment, high_alignment, options);
        }
        pub fn UnstructuredHolderLowAligned(comptime low_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredHolder(Allocator, low_alignment, low_alignment, options);
        }
        pub fn UnstructuredHolder(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: container.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredHolder(Allocator, low_alignment, high_alignment, options);
        }
    };
}
fn GenericInterface(comptime Allocator: type) type {
    return opaque {
        const Graphics = GenericAllocatorGraphics(Allocator);
        const Intermediate = GenericIntermediate(Allocator);
        const Implementation = GenericImplementation(Allocator);
        pub fn allocateStatic(allocator: *Allocator, comptime s_impl_type: type, o_amt: ?mem.Amount) Allocator.allocate_payload(s_impl_type) {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    if (@hasField(Construct, "ss_addr")) {
                        const s_ab_addr: u64 = s_lb_addr;
                        const s_ss_addr: u64 = s_ab_addr;
                        const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.utility();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ss_addr = s_ss_addr });
                        Graphics.showAllocateStatic(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                    const s_aligned_bytes: u64 = n_count * s_impl_type.utility();
                    const s_ab_addr: u64 = s_lb_addr;
                    const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                    try meta.wrap(Intermediate.allocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateStatic(s_impl_type, s_impl, @src());
                    return s_impl;
                }
            } else { // @1b1
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    if (@hasField(Construct, "ab_addr")) {
                        const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Construct, "ss_addr")) {
                            const s_ss_addr: u64 = s_ab_addr;
                            const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                            const s_aligned_bytes: u64 = n_count * s_impl_type.utility();
                            const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                            try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            Graphics.showAllocateStatic(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.utility();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr });
                        Graphics.showAllocateStatic(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                    const s_aligned_bytes: u64 = n_count * s_impl_type.utility();
                    const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                    const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                    try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateStatic(s_impl_type, s_impl, @src());
                    return s_impl;
                }
            }
        }
        pub fn allocateMany(allocator: *Allocator, comptime s_impl_type: type, n_amt: mem.Amount) Allocator.allocate_payload(s_impl_type) {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    if (@hasField(Construct, "up_addr")) {
                        const s_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                        const s_ab_addr: u64 = s_lb_addr;
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Construct, "ss_addr")) {
                            const s_ss_addr: u64 = s_ab_addr;
                            try meta.wrap(Intermediate.allocateManyUnitAligned(allocator, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                            Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        try meta.wrap(Intermediate.allocateManyUnitAligned(allocator, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                }
            } else { // @1b1
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    if (@hasField(Construct, "up_addr")) {
                        const s_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                        const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Construct, "ab_addr")) {
                            if (@hasField(Construct, "ss_addr")) {
                                const s_ss_addr: u64 = s_ab_addr;
                                try meta.wrap(Intermediate.allocateManyAnyAligned(allocator, s_aligned_bytes, s_up_addr));
                                const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                                Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                                return s_impl;
                            }
                            try meta.wrap(Intermediate.allocateManyAnyAligned(allocator, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr });
                            Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        if (@hasField(Construct, "ss_addr")) {
                            const s_ss_addr: u64 = s_ab_addr;
                            try meta.wrap(Intermediate.allocateManyAnyAligned(allocator, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                            Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        try meta.wrap(Intermediate.allocateManyAnyAligned(allocator, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                }
            }
        }
        pub fn allocateHolder(allocator: *Allocator, comptime s_impl_type: type) s_impl_type {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    if (@hasField(Construct, "ss_addr")) {
                        const s_ab_addr: u64 = s_lb_addr;
                        const s_ss_addr: u64 = s_ab_addr;
                        Implementation.allocateHolderUnitAligned(allocator, s_lb_addr);
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ss_addr = s_ss_addr });
                        Graphics.showAllocateHolder(allocator, s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    Implementation.allocateHolderUnitAligned(allocator, s_lb_addr);
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateHolder(allocator, s_impl_type, s_impl, @src());
                    return s_impl;
                }
            } else { // @1b1
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "ab_addr")) {
                    const s_lb_addr: u64 = allocator.next();
                    const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                    if (@hasField(Construct, "ss_addr")) {
                        const s_ss_addr: u64 = s_ab_addr;
                        Implementation.allocateHolderAnyAligned(allocator, s_lb_addr);
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                        Graphics.showAllocateHolder(allocator, s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    Implementation.allocateHolderAnyAligned(allocator, s_lb_addr);
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .ab_addr = s_ab_addr });
                    Graphics.showAllocateHolder(allocator, s_impl_type, s_impl, @src());
                    return s_impl;
                }
            }
        }
        pub fn resizeManyAbove(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.Amount) Allocator.allocate_void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                builtin.assertAbove(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveUnitAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                builtin.assertAbove(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyBelow(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.Amount) void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                builtin.assertBelow(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowUnitAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                builtin.assertBelow(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) Allocator.allocate_void {
            if (!@hasDecl(s_impl_type, "length")) {
                @compileError("cannot grow fixed-size memory: " ++ @typeName(s_impl_type));
            }
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const n_amt: mem.Amount = .{ .bytes = s_impl.length() + mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                if (t_aligned_bytes <= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveUnitAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const n_amt: mem.Amount = .{ .bytes = s_impl.length() + mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                if (t_aligned_bytes <= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyDecrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) void {
            if (!@hasDecl(s_impl_type, "length")) {
                @compileError("cannot shrink fixed-size memory: " ++ @typeName(s_impl_type));
            }
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const n_amt: mem.Amount = .{ .bytes = s_impl.length() - mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                if (t_aligned_bytes >= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowUnitAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start();
                const s_aligned_bytes: u64 = s_impl.utility();
                const n_amt: mem.Amount = .{ .bytes = s_impl.length() - mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                if (t_aligned_bytes >= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeHolderAbove(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.Amount) Allocator.allocate_void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start(allocator.*);
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start(allocator.*);
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveAnyAligned(allocator, t_up_addr));
            }
        }
        pub fn resizeHolderIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) Allocator.allocate_void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start(allocator.*);
                const n_amt: mem.Amount = .{ .bytes = s_impl.length(allocator.*) + mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.start(allocator.*);
                const n_amt: mem.Amount = .{ .bytes = s_impl.length(allocator.*) + mem.amountToBytesOfLength(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountToBytesReserved(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveAnyAligned(allocator, t_up_addr));
            }
        }
        pub fn moveStatic(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type) Allocator.allocate_void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = mach.cmov64(allocator.metadata.count == 1, allocator.start(), allocator.next());
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = t_lb_addr;
                        const t_ss_addr: u64 = t_ab_addr + s_impl.behind();
                        const s_aligned_bytes: u64 = s_impl.utility();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveStaticUnitAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr });
                    }
                    const s_aligned_bytes: u64 = s_impl.utility();
                    const t_aligned_bytes: u64 = s_aligned_bytes;
                    const t_ab_addr: u64 = t_lb_addr;
                    const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                    try meta.wrap(Intermediate.moveStaticUnitAligned(allocator, t_up_addr));
                    return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr });
                }
            } else { // @1b1
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = mach.cmov64(allocator.metadata.count == 1, allocator.start(), allocator.next());
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Translate, "ss_addr")) {
                            const t_ss_addr: u64 = t_ab_addr + s_impl.behind();
                            const s_aligned_bytes: u64 = s_impl.utility();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .ss_addr = t_ss_addr });
                        }
                        const s_aligned_bytes: u64 = s_impl.utility();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr });
                    }
                    const s_aligned_bytes: u64 = s_impl.utility();
                    const t_aligned_bytes: u64 = s_aligned_bytes;
                    const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                    const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                    try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                    return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr });
                }
            }
        }
        pub fn moveMany(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type) Allocator.allocate_void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = mach.cmov64(allocator.metadata.count == 1, allocator.start(), allocator.next());
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = t_lb_addr;
                        const t_ss_addr: u64 = t_ab_addr + s_impl.behind();
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.utility();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyUnitAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "up_addr")) {
                        const s_aligned_bytes: u64 = s_impl.utility();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_ab_addr: u64 = t_lb_addr;
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveManyUnitAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .up_addr = t_up_addr });
                    }
                }
            } else { // @1b1
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = mach.cmov64(allocator.metadata.count == 1, allocator.start(), allocator.next());
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Translate, "ss_addr")) {
                            const t_ss_addr: u64 = t_ab_addr + s_impl.behind();
                            if (@hasField(Translate, "up_addr")) {
                                const s_aligned_bytes: u64 = s_impl.utility();
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                                return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                            }
                        }
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.utility();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        const t_ss_addr: u64 = t_ab_addr + s_impl.behind();
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.utility();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "up_addr")) {
                        const s_aligned_bytes: u64 = s_impl.utility();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .up_addr = t_up_addr });
                    }
                }
            }
        }
        pub fn deallocateStatic(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type, o_amt: ?mem.Amount) void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const n_count: u64 = if (o_amt) |n_amt| mem.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
                const n_aligned_bytes: u64 = s_impl_type.utility();
                const s_aligned_bytes: u64 = n_aligned_bytes * n_count;
                const s_lb_addr: u64 = s_impl.low();
                const s_ab_addr: u64 = s_impl.start();
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.deallocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            } else { // @1b1
                const n_count: u64 = if (o_amt) |n_amt| mem.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
                const n_aligned_bytes: u64 = s_impl_type.utility();
                const s_aligned_bytes: u64 = n_aligned_bytes * n_count;
                const s_lb_addr: u64 = s_impl.low();
                const s_ab_addr: u64 = s_impl.start();
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.deallocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            }
        }
        pub fn deallocateMany(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type) void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_ab_addr: u64 = s_impl.start();
                const s_up_addr: u64 = s_impl.high();
                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                const s_lb_addr: u64 = s_impl.low();
                Intermediate.deallocateManyUnitAligned(allocator, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            } else { // @1b1
                const s_ab_addr: u64 = s_impl.start();
                const s_up_addr: u64 = s_impl.high();
                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                const s_lb_addr: u64 = s_impl.low();
                Intermediate.deallocateManyAnyAligned(allocator, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            }
        }
        pub fn deallocateHolder(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type) void {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                Implementation.deallocateHolderUnitAligned(allocator);
                Graphics.showDeallocateHolder(allocator, s_impl_type, s_impl, @src());
            } else { // @1b1
                Implementation.deallocateHolderAnyAligned(allocator);
                Graphics.showDeallocateHolder(allocator, s_impl_type, s_impl, @src());
            }
        }
        pub fn convertHolderMany(allocator: *Allocator, comptime s_impl_type: type, comptime t_impl_type: type, s_impl: s_impl_type) Allocator.allocate_payload(t_impl_type) {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low(allocator.*);
                    if (@hasField(Convert, "up_addr")) {
                        const s_ab_addr: u64 = s_impl.start(allocator.*);
                        const s_aligned_bytes: u64 = s_impl.length(allocator.*);
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start(allocator.*);
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertHolderManyUnitAligned(allocator, t_aligned_bytes, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertHolderManyUnitAligned(allocator, t_aligned_bytes, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertHolderManyUnitAligned(allocator, t_aligned_bytes, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertHolderManyUnitAligned(allocator, t_aligned_bytes, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            } else { // @1b1
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low(allocator.*);
                    if (@hasField(Convert, "up_addr")) {
                        const s_ab_addr: u64 = s_impl.start(allocator.*);
                        const s_aligned_bytes: u64 = s_impl.length(allocator.*);
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Convert, "ab_addr")) {
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.start(allocator.*);
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.next();
                                    const t_aligned_bytes: u64 = s_aligned_bytes;
                                    const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                    try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                                    return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                                }
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            }
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ub_addr = s_ub_addr });
                            }
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr });
                        }
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start(allocator.*);
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertHolderManyAnyAligned(allocator, t_aligned_bytes, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            }
        }
        pub fn convertManyMany(allocator: *Allocator, comptime s_impl_type: type, comptime t_impl_type: type, s_impl: s_impl_type) Allocator.allocate_payload(t_impl_type) {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.high();
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_ab_addr: u64 = s_impl.start();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.start();
                        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            } else { // @1b1
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.high();
                        if (@hasField(Convert, "ab_addr")) {
                            const s_ab_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.start();
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.next();
                                    const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                    const t_aligned_bytes: u64 = s_aligned_bytes;
                                    const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                    try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                    return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                                }
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            }
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ub_addr = s_ub_addr });
                            }
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr });
                        }
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_ab_addr: u64 = s_impl.start();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.start();
                        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            }
        }
        pub fn convertStaticMany(allocator: *Allocator, comptime s_impl_type: type, comptime t_impl_type: type, s_impl: s_impl_type) Allocator.allocate_payload(t_impl_type) {
            if (comptime @hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.high();
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_ab_addr: u64 = s_impl.start();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.start();
                        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            } else { // @1b1
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.low();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.high();
                        if (@hasField(Convert, "ab_addr")) {
                            const s_ab_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.start();
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.next();
                                    const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                    const t_aligned_bytes: u64 = s_aligned_bytes;
                                    const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                    try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                    return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                                }
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            }
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr, .ub_addr = s_ub_addr });
                            }
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ab_addr = s_ab_addr });
                        }
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.start();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.next();
                                const s_ab_addr: u64 = s_impl.start();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.next();
                            const s_ab_addr: u64 = s_impl.start();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.start();
                        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                        return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr });
                    }
                }
            }
        }
    };
}
fn GenericIntermediate(comptime Allocator: type) type {
    return opaque {
        const Graphics = GenericAllocatorGraphics(Allocator);
        const Implementation = GenericImplementation(Allocator);
        fn allocateStaticUnitAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.allocateStaticUnitAlignedUnaddressable(allocator, n_count, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateStaticUnitAlignedAddressable(allocator, n_count, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateStaticAnyAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.allocateStaticAnyAlignedUnaddressable(allocator, n_count, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateStaticAnyAlignedAddressable(allocator, n_count, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateManyUnitAligned(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.allocateManyUnitAlignedUnaddressable(allocator, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateManyUnitAlignedAddressable(allocator, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateManyAnyAligned(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.allocateManyAnyAlignedUnaddressable(allocator, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateManyAnyAlignedAddressable(allocator, s_aligned_bytes, s_up_addr);
            }
        }
        fn resizeManyAboveUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.next()) {
                if (t_up_addr > allocator.finish()) {
                    try meta.wrap(Implementation.resizeManyAboveUnitAlignedUnaddressable(allocator, s_up_addr, t_up_addr));
                } else {
                    Implementation.resizeManyAboveUnitAlignedAddressable(allocator, s_up_addr, t_up_addr);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else {
                @breakpoint();
            }
        }
        fn resizeManyAboveAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.next()) {
                if (t_up_addr > allocator.finish()) {
                    try meta.wrap(Implementation.resizeManyAboveAnyAlignedUnaddressable(allocator, s_up_addr, t_up_addr));
                } else {
                    Implementation.resizeManyAboveAnyAlignedAddressable(allocator, s_up_addr, t_up_addr);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else {
                @breakpoint();
            }
        }
        fn resizeManyBelowUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.resizeManyBelowUnitAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloResizeViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.resizeManyBelowUnitAlignedEndInternal(allocator, s_up_addr, t_up_addr);
            }
        }
        fn resizeManyBelowAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.resizeManyBelowAnyAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloResizeViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.resizeManyBelowAnyAlignedEndInternal(allocator, s_up_addr, t_up_addr);
            }
        }
        fn resizeHolderAboveUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.resizeHolderAboveUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.resizeHolderAboveUnitAlignedAddressable(allocator);
            }
        }
        fn resizeHolderAboveAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.resizeHolderAboveAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.resizeHolderAboveAnyAlignedAddressable(allocator);
            }
        }
        fn moveStaticUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.moveStaticUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveStaticUnitAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveStaticAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.moveStaticAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveStaticAnyAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveManyUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.moveManyUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveManyUnitAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveManyAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.moveManyAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveManyAnyAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn deallocateStaticUnitAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.deallocateStaticUnitAlignedEndBoundary(allocator, n_count, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticUnitAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateStaticAnyAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.deallocateStaticAnyAlignedEndBoundary(allocator, n_count, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticAnyAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateManyUnitAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.deallocateManyUnitAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateManyUnitAlignedEndInternal(allocator, s_aligned_bytes);
            }
        }
        fn deallocateManyAnyAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.next()) {
                Implementation.deallocateManyAnyAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateManyAnyAlignedEndInternal(allocator, s_aligned_bytes);
            }
        }
        fn convertHolderManyUnitAligned(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.convertHolderManyUnitAlignedUnaddressable(allocator, t_aligned_bytes, t_up_addr));
            } else {
                Implementation.convertHolderManyUnitAlignedAddressable(allocator, t_aligned_bytes, t_up_addr);
            }
        }
        fn convertHolderManyAnyAligned(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.finish()) {
                try meta.wrap(Implementation.convertHolderManyAnyAlignedUnaddressable(allocator, t_aligned_bytes, t_up_addr));
            } else {
                Implementation.convertHolderManyAnyAlignedAddressable(allocator, t_aligned_bytes, t_up_addr);
            }
        }
        fn convertAnyManyUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.next()) {
                if (t_up_addr > allocator.finish()) {
                    Implementation.convertAnyManyUnitAlignedUnaddressable(allocator);
                } else {
                    Implementation.convertAnyManyUnitAlignedAddressable(allocator);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else {
                @breakpoint();
            }
        }
        fn convertAnyManyAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.next()) {
                if (t_up_addr > allocator.finish()) {
                    Implementation.convertAnyManyAnyAlignedUnaddressable(allocator);
                } else {
                    Implementation.convertAnyManyAnyAlignedAddressable(allocator);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else {
                @breakpoint();
            }
        }
    };
}
fn GenericImplementation(comptime Allocator: type) type {
    return opaque {
        const Graphics = GenericAllocatorGraphics(Allocator);
        fn allocateStaticAnyAlignedAddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.static.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
        }
        fn allocateStaticAnyAlignedUnaddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.static.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
            return allocator.mapBelow(s_up_addr);
        }
        fn allocateStaticUnitAlignedAddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.static.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
        }
        fn allocateStaticUnitAlignedUnaddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.static.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
            return allocator.mapBelow(s_up_addr);
        }
        fn allocateManyAnyAlignedAddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.many.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
        }
        fn allocateManyAnyAlignedUnaddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.many.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
            return allocator.mapBelow(s_up_addr);
        }
        fn allocateManyUnitAlignedAddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.many.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
        }
        fn allocateManyUnitAlignedUnaddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.many.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.allocate(s_up_addr);
            return allocator.mapBelow(s_up_addr);
        }
        fn allocateHolderAnyAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.holder.any_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = s_lb_addr;
            }
        }
        fn allocateHolderUnitAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.holder.unit_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = s_lb_addr;
            }
        }
        fn resizeManyBelowAnyAlignedEndBoundary(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.below.any_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr, t_up_addr);
            }
            allocator.deallocate(s_up_addr);
        }
        fn resizeManyBelowAnyAlignedEndInternal(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.below.any_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr, t_up_addr);
            }
        }
        fn resizeManyBelowUnitAlignedEndBoundary(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.below.unit_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr, t_up_addr);
            }
            allocator.deallocate(s_up_addr);
        }
        fn resizeManyBelowUnitAlignedEndInternal(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.below.unit_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr, t_up_addr);
            }
        }
        fn resizeManyAboveAnyAlignedAddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn resizeManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn resizeManyAboveUnitAlignedAddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn resizeManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn resizeHolderBelowAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.below.any_aligned += 1;
            }
        }
        fn resizeHolderBelowUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.below.unit_aligned += 1;
            }
        }
        fn resizeHolderAboveAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.any_aligned.addressable += 1;
            }
        }
        fn resizeHolderAboveAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.any_aligned.unaddressable += 1;
            }
            return allocator.mapBelow(t_up_addr);
        }
        fn resizeHolderAboveUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.unit_aligned.addressable += 1;
            }
        }
        fn resizeHolderAboveUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.unit_aligned.unaddressable += 1;
            }
            return allocator.mapBelow(t_up_addr);
        }
        fn moveStaticAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.addressable += 1;
            }
            allocator.allocate(t_up_addr);
        }
        fn moveStaticAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.unaddressable += 1;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn moveStaticUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.addressable += 1;
            }
            allocator.allocate(t_up_addr);
        }
        fn moveStaticUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.unaddressable += 1;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn moveManyAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.addressable += 1;
            }
            allocator.allocate(t_up_addr);
        }
        fn moveManyAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.unaddressable += 1;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn moveManyUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.addressable += 1;
            }
            allocator.allocate(t_up_addr);
        }
        fn moveManyUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.unaddressable += 1;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn reallocateManyBelowAnyAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyBelowAnyAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn reallocateManyAboveUnitAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
        }
        fn reallocateManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn convertAnyStaticAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.static.any_aligned.addressable += 1;
            }
        }
        fn convertAnyStaticAnyAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.static.any_aligned.unaddressable += 1;
            }
        }
        fn convertAnyStaticUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.static.unit_aligned.addressable += 1;
            }
        }
        fn convertAnyStaticUnitAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.static.unit_aligned.unaddressable += 1;
            }
        }
        fn convertAnyManyAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.many.any_aligned.addressable += 1;
            }
        }
        fn convertAnyManyAnyAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.many.any_aligned.unaddressable += 1;
            }
        }
        fn convertAnyManyUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.many.unit_aligned.addressable += 1;
            }
        }
        fn convertAnyManyUnitAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.any.many.unit_aligned.unaddressable += 1;
            }
        }
        fn convertHolderStaticAnyAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
        }
        fn convertHolderStaticAnyAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn convertHolderStaticUnitAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
        }
        fn convertHolderStaticUnitAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn convertHolderManyAnyAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
        }
        fn convertHolderManyAnyAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn convertHolderManyUnitAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
        }
        fn convertHolderManyUnitAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.allocate(t_up_addr);
            return allocator.mapBelow(t_up_addr);
        }
        fn convertHolderHolderAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.holder.any_aligned += 1;
            }
        }
        fn convertHolderHolderUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.convert.holder.holder.unit_aligned += 1;
            }
        }
        fn deallocateStaticAnyAlignedEndBoundary(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.static.any_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.deallocate(s_lb_addr);
        }
        fn deallocateStaticAnyAlignedEndInternal(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.static.any_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateStaticUnitAlignedEndBoundary(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.static.unit_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.deallocate(s_lb_addr);
        }
        fn deallocateStaticUnitAlignedEndInternal(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.static.unit_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateManyAnyAlignedEndBoundary(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.many.any_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.deallocate(s_lb_addr);
        }
        fn deallocateManyAnyAlignedEndInternal(allocator: *Allocator, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.many.any_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateManyUnitAlignedEndBoundary(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.many.unit_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.deallocate(s_lb_addr);
        }
        fn deallocateManyUnitAlignedEndInternal(allocator: *Allocator, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.many.unit_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateHolderAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.holder.any_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
        fn deallocateHolderUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.holder.unit_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                builtin.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
    };
}
const special = opaque {
    fn map(comptime spec: mem.MapSpec, addr: u64, len: u64) spec.Unwrapped(.mmap) {
        const mmap_prot: mem.Prot = spec.prot();
        const mmap_flags: mem.Map = spec.flags();
        if (spec.call(.mmap, .{ addr, len, mmap_prot.val, mmap_flags.val, ~@as(u64, 0), 0 })) {
            if (spec.logging.Acquire) {
                debug.mapNotice(addr, len);
            }
        } else |map_error| {
            if (spec.logging.Error) {
                debug.mapError(map_error, addr, len);
            }
            return map_error;
        }
    }
    fn move(comptime spec: mem.MoveSpec, old_addr: u64, old_len: u64, new_addr: u64) spec.Unwrapped(.mremap) {
        const mremap_flags: mem.Remap = spec.flags();
        if (spec.call(.mremap, .{ old_addr, old_len, old_len, mremap_flags.val, new_addr })) {
            if (spec.logging.Success) {
                debug.moveNotice(old_addr, old_len, new_addr);
            }
        } else |mremap_error| {
            if (spec.logging.Error) {
                debug.moveError(mremap_error, old_addr, old_len, new_addr);
            }
            return mremap_error;
        }
    }
    fn resize(comptime spec: mem.RemapSpec, old_addr: u64, old_len: u64, new_len: u64) spec.Unwrapped(.mremap) {
        if (spec.call(.mremap, .{ old_addr, old_len, new_len, 0, 0 })) {
            if (spec.logging.Success) {
                debug.resizeNotice(old_addr, old_len, new_len);
            }
        } else |mremap_error| {
            if (spec.logging.Error) {
                debug.resizeError(mremap_error, old_addr, old_len, new_len);
            }
            return mremap_error;
        }
    }
    fn unmap(comptime spec: mem.UnmapSpec, addr: u64, len: u64) spec.Unwrapped(.munmap) {
        if (spec.call(.munmap, .{ addr, len })) {
            if (spec.logging.Release) {
                debug.unmapNotice(addr, len);
            }
        } else |unmap_error| {
            if (spec.logging.Error) {
                debug.unmapError(unmap_error, addr, len);
            }
            return unmap_error;
        }
    }
    fn advise(comptime spec: mem.AdviseSpec, addr: u64, len: u64) spec.Unwrapped(.madvise) {
        const advice: mem.Advice = spec.advice();
        if (spec.call(.madvise, .{ addr, len, advice.val })) {
            if (spec.logging.Success) {
                debug.adviseNotice(addr, len, spec.describe());
            }
        } else |madvise_error| {
            if (spec.logging.Error) {
                debug.adviseError(madvise_error, addr, len, spec.describe());
            }
            return madvise_error;
        }
    }
    pub fn acquire(comptime spec: mem.AcquireSpec, comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) mem.AcquireSpec.Unwrapped(spec) {
        const lb_addr: u64 = AddressSpace.low(index);
        const up_addr: u64 = AddressSpace.high(index);
        if (if (AddressSpace.addr_spec.options.thread_safe)
            address_space.atomicSet(index)
        else
            address_space.set(index))
        {
            if (spec.logging.Acquire) {
                debug.arenaAcquireNotice(index, lb_addr, up_addr);
            }
        } else if (spec.errors) |arena_error| {
            if (spec.logging.Error) {
                debug.arenaAcquireError(arena_error, index, lb_addr, up_addr);
            }
            return error.UnderSupply;
        }
    }
    pub fn release(comptime spec: mem.ReleaseSpec, comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) mem.ReleaseSpec.Unwrapped(spec) {
        const lb_addr: u64 = AddressSpace.low(index);
        const up_addr: u64 = AddressSpace.high(index);
        if (if (AddressSpace.addr_spec.options.thread_safe)
            address_space.atomicUnset(index)
        else
            address_space.unset(index))
        {
            if (spec.logging.Release) {
                debug.arenaReleaseNotice(index, lb_addr, up_addr);
            }
        } else if (spec.errors) |arena_error| {
            if (spec.logging.Error) {
                return debug.arenaReleaseError(arena_error, index, lb_addr, up_addr);
            }
            return arena_error;
        }
    }
    pub const static = opaque {
        pub fn acquire(comptime spec: mem.AcquireSpec, comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) mem.AcquireSpec.Unwrapped(spec) {
            const lb_addr: u64 = AddressSpace.low(index);
            const up_addr: u64 = AddressSpace.high(index);
            if (if (comptime AddressSpace.arena(index).options.thread_safe)
                address_space.atomicSet(index)
            else
                address_space.set(index))
            {
                if (spec.logging.Acquire) {
                    debug.arenaAcquireNotice(index, lb_addr, up_addr);
                }
            } else if (spec.errors) |arena_error| {
                if (spec.logging.Error) {
                    debug.arenaAcquireError(arena_error, index, lb_addr, up_addr);
                }
                return arena_error;
            }
        }
        pub fn release(comptime spec: mem.ReleaseSpec, comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) mem.ReleaseSpec.Unwrapped(spec) {
            const lb_addr: u64 = AddressSpace.low(index);
            const up_addr: u64 = AddressSpace.high(index);
            if (if (comptime AddressSpace.arena(index).options.thread_safe)
                address_space.atomicUnset(index)
            else
                address_space.unset(index))
            {
                if (spec.logging.Release) {
                    debug.arenaReleaseNotice(index, lb_addr, up_addr);
                }
            } else if (spec.errors) |arena_error| {
                if (spec.logging.Error) {
                    return debug.arenaReleaseError(arena_error, index);
                }
                return arena_error;
            }
        }
    };
};
const debug = opaque {
    const PrintArray = mem.StaticString(8192);
    const ArenaRange = fmt.AddressRangeFormat;
    const ChangedArenaRange = fmt.ChangedAddressRangeFormat;
    const ChangedBytes = fmt.ChangedBytesFormat(.{});
    const about_next_s: []const u8 = "next:           ";
    const about_count_s: []const u8 = "count:          ";
    const about_map_0_s: []const u8 = "map:            ";
    const about_map_1_s: []const u8 = "map-error:      ";
    const about_acq_0_s: []const u8 = "acq:            arena-";
    const about_acq_1_s: []const u8 = "acq-error:      arena-";
    const about_rel_0_s: []const u8 = "rel:            arena-";
    const about_rel_1_s: []const u8 = "rel-error:      arena-";
    const about_brk_1_s: []const u8 = "brk-error:      ";
    const about_no_op_s: []const u8 = "no-op:          ";
    const about_move_0_s: []const u8 = "move:           ";
    const about_move_1_s: []const u8 = "move-error:     ";
    const about_finish_s: []const u8 = "finish:         ";
    const about_holder_s: []const u8 = "holder:         ";
    const about_unmap_0_s: []const u8 = "unmap:          ";
    const about_unmap_1_s: []const u8 = "unmap-error:    ";
    const about_remap_0_s: []const u8 = "remap:          ";
    const about_remap_1_s: []const u8 = "remap-error:    ";
    const about_utility_s: []const u8 = "utility:        ";
    const about_capacity_s: []const u8 = "capacity:       ";
    const about_resize_0_s: []const u8 = "resize:         ";
    const about_resize_1_s: []const u8 = "resize-error:   ";
    const about_advice_0_s: []const u8 = "advice:         ";
    const about_advice_1_s: []const u8 = "advice-error:   ";
    const about_remapped_s: []const u8 = "remapped:       ";
    const about_allocated_s: []const u8 = "allocated:      ";
    const about_filo_error_s: []const u8 = "filo-error:     ";
    const about_deallocated_s: []const u8 = "deallocated:    ";
    const about_reallocated_s: []const u8 = "reallocated:    ";
    fn errorName(array: *PrintArray, error_name: []const u8) void {
        array.writeMany("(");
        array.writeMany(error_name);
        array.writeMany(")");
    }
    fn addressRange(array: *PrintArray, begin: u64, end: u64) void {
        array.writeFormat(fmt.ux64(begin));
        array.writeMany("..");
        array.writeFormat(fmt.ux64(end));
    }
    fn bytes(array: *PrintArray, begin: u64, end: u64) void {
        array.writeFormat(fmt.ud64(end - begin));
        array.writeMany(" bytes");
    }
    fn addressRangeBytes(array: *PrintArray, begin: u64, end: u64) void {
        addressRange(array, begin, end);
        array.writeMany(", ");
        bytes(array, begin, end);
    }
    fn changedAddressRange(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        addressRange(array, old_begin, old_end);
        array.writeMany(" -> ");
        addressRange(array, new_begin, new_end);
    }
    fn changedBytes(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        const old_len: u64 = old_end - old_begin;
        const new_len: u64 = new_end - new_begin;
        array.writeFormat(fmt.ud64(old_len));
        if (old_len != new_len) {
            array.writeMany(" -> ");
            array.writeFormat(fmt.ud64(new_len));
        }
        array.writeMany(" bytes");
    }
    fn changedAddressRangeBytes(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        changedAddressRange(array, old_begin, old_end, new_begin, new_end);
        array.writeMany(", ");
        changedBytes(array, old_begin, old_end, new_begin, new_end);
    }
    fn writeAddressSpaceA(array: *PrintArray, s_ab_addr: u64, s_uw_addr: u64) void {
        array.writeFormat(ArenaRange.init(s_ab_addr, s_uw_addr));
        array.writeMany(", ");
    }
    fn writeAddressSpaceB(array: *PrintArray, s_ab_addr: u64, s_uw_addr: u64, t_ab_addr: u64, t_uw_addr: u64) void {
        array.writeFormat(ChangedArenaRange.init(s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr));
        array.writeMany(", ");
    }
    fn writeAlignedBytesA(array: *PrintArray, s_aligned_bytes: u64) void {
        array.writeFormat(fmt.bytes(s_aligned_bytes));
        array.writeMany(", ");
    }
    fn writeAlignedBytesB(array: *PrintArray, s_aligned_bytes: u64, t_aligned_bytes: u64) void {
        array.writeFormat(ChangedBytes.init(s_aligned_bytes, t_aligned_bytes));
        array.writeMany(", ");
    }
    fn writeModifyOperation(array: *PrintArray, s_ab_addr: u64, s_aligned_bytes: u64, t_ab_addr: u64, t_aligned_bytes: u64) void {
        if (s_aligned_bytes != t_aligned_bytes and s_ab_addr == t_ab_addr) {
            return array.writeMany(about_resize_0_s);
        }
        if (s_aligned_bytes == t_aligned_bytes and s_ab_addr != t_ab_addr) {
            return array.writeMany(about_move_0_s);
        }
        if (s_ab_addr != t_ab_addr) {
            return array.writeMany(about_reallocated_s);
        }
        array.writeMany(about_no_op_s);
    }
    fn writeManyArrayNotation(array: *PrintArray, comptime child: type, count: u64, comptime sentinel: ?*const child) void {
        array.writeOne('[');
        array.writeFormat(fmt.ud64(count));
        if (sentinel) |sentinel_ptr| {
            array.writeOne(':');
            array.writeFormat(fmt.any(sentinel_ptr.*));
            array.writeOne(']');
        } else {
            array.writeOne(']');
        }
        array.writeMany(@typeName(child));
    }
    fn writeHolderArrayNotation(array: *PrintArray, comptime child: type, count: u64, comptime sentinel: ?*const child) void {
        array.writeOne('[');
        array.writeFormat(fmt.ud64(count));
        array.writeMany("..*");
        if (sentinel) |sentinel_ptr| {
            array.writeOne(':');
            array.writeFormat(fmt.any(sentinel_ptr.*));
            array.writeOne(']');
        } else {
            array.writeOne(']');
        }
        array.writeMany(@typeName(child));
    }
    fn writeChangedManyArrayNotation(array: *PrintArray, comptime child: type, s_count: u64, t_count: u64, comptime sentinel: ?*const child) void {
        array.writeOne('[');
        array.writeFormat(fmt.udd(s_count, t_count));
        if (sentinel) |sentinel_ptr| {
            array.writeOne(':');
            array.writeFormat(fmt.any(sentinel_ptr.*));
            array.writeOne(']');
        } else {
            array.writeOne(']');
        }
        array.writeMany(@typeName(child));
    }
    fn writeChangedHolderArrayNotation(array: *PrintArray, comptime child: type, s_count: u64, t_count: u64, comptime sentinel: ?*const child) void {
        array.writeOne('[');
        array.writeFormat(fmt.udd(s_count, t_count));
        array.writeMany("..*");
        if (sentinel) |sentinel_ptr| {
            array.writeOne(':');
            array.writeFormat(fmt.any(sentinel_ptr.*));
            array.writeOne(']');
        } else {
            array.writeOne(']');
        }
        array.writeMany(@typeName(child));
    }
    fn writeManyArrayNotationA(
        array: *PrintArray,
        comptime s_child: type,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes - @sizeOf(s_child) * @boolToInt(s_sentinel != null)) / @sizeOf(s_child);
        writeManyArrayNotation(array, s_child, s_count, s_sentinel);
        array.writeMany(", ");
    }
    fn writeManyArrayNotationB(
        array: *PrintArray,
        comptime s_child: type,
        comptime t_child: type,
        s_aligned_bytes: u64,
        t_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes - @sizeOf(s_child) * @boolToInt(s_sentinel != null)) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes - @sizeOf(t_child) * @boolToInt(t_sentinel != null)) / @sizeOf(t_child);
        if (s_child == t_child and s_sentinel == t_sentinel) {
            if (s_count != t_count) {
                writeChangedManyArrayNotation(array, s_child, s_count, t_count, s_sentinel);
            } else {
                writeManyArrayNotation(array, s_child, s_count, s_sentinel);
            }
        } else {
            writeManyArrayNotation(array, s_child, s_count, s_sentinel);
            if (s_count != t_count) {
                array.writeMany(" -> ");
                writeManyArrayNotation(array, t_child, t_count, t_sentinel);
            }
        }
        array.writeMany(", ");
    }
    fn writeHolderArrayNotationA(
        array: *PrintArray,
        comptime s_child: type,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes - @sizeOf(s_child) * @boolToInt(s_sentinel != null)) / @sizeOf(s_child);
        writeHolderArrayNotation(array, s_child, s_count, s_sentinel);
        array.writeMany(", ");
    }
    fn writeHolderArrayNotationB(
        array: *PrintArray,
        comptime s_child: type,
        comptime t_child: type,
        s_aligned_bytes: u64,
        t_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes - @sizeOf(s_child) * @boolToInt(s_sentinel != null)) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes - @sizeOf(t_child) * @boolToInt(t_sentinel != null)) / @sizeOf(t_child);
        if (s_child == t_child and s_sentinel == t_sentinel) {
            if (s_count != t_count) {
                writeChangedHolderArrayNotation(array, s_child, s_count, t_count, s_sentinel);
            } else {
                writeHolderArrayNotation(array, s_child, s_count, s_sentinel);
            }
        } else {
            writeHolderArrayNotation(array, s_child, s_count, s_sentinel);
            if (s_count != t_count) {
                array.writeMany(" -> ");
                writeHolderArrayNotation(array, t_child, t_count, t_sentinel);
            }
        }
        array.writeMany(", ");
    }
    fn mapNotice(addr: u64, len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_map_0_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn mapError(map_error: anytype, addr: u64, len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_map_1_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany(" ");
        errorName(&array, @errorName(map_error));
        file.noexcept.write(2, array.readAll());
    }
    fn unmapNotice(addr: u64, len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_unmap_0_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_unmap_1_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany(" ");
        errorName(&array, @errorName(unmap_error));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn arenaAcquireNotice(index: u8, lb_addr: u64, up_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_acq_0_s);
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        addressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn arenaAcquireError(arena_error: anytype, index: u8, lb_addr: u64, up_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_acq_1_s);
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        addressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany(" ");
        errorName(&array, @errorName(arena_error));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn arenaReleaseNotice(index: u8, lb_addr: u64, up_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_rel_0_s);
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        addressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn arenaReleaseError(arena_error: anytype, index: u8, lb_addr: u64, up_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_rel_1_s);
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        addressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany(" ");
        errorName(&array, @errorName(arena_error));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        var array: PrintArray = .{};
        array.writeMany(about_advice_0_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany(", ");
        array.writeMany(description_s);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn adviseError(madvise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        var array: PrintArray = .{};
        array.writeMany(about_advice_1_s);
        addressRangeBytes(&array, addr, addr + len);
        array.writeMany(", ");
        array.writeMany(description_s);
        array.writeMany(", ");
        errorName(&array, @errorName(madvise_error));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn resizeNotice(old_addr: u64, old_len: u64, new_len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_remap_0_s);
        changedAddressRangeBytes(&array, old_addr, old_addr + old_len, old_addr, old_addr + new_len);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn resizeError(mremap_err: anytype, old_addr: u64, old_len: u64, new_len: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_remap_1_s);
        changedAddressRangeBytes(&array, old_addr, old_addr + old_len, old_addr, old_addr + new_len);
        array.writeMany(" ");
        errorName(&array, @errorName(mremap_err));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn moveNotice(old_addr: u64, old_len: u64, new_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_move_0_s);
        changedAddressRangeBytes(&array, old_addr, old_addr + old_len, new_addr, new_addr + old_len);
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn moveError(mremap_err: anytype, old_addr: u64, old_len: u64, new_addr: u64) void {
        var array: PrintArray = .{};
        array.writeMany(about_move_1_s);
        changedAddressRangeBytes(&array, old_addr, old_addr + old_len, new_addr, new_addr + old_len);
        array.writeMany(" ");
        errorName(&array, @errorName(mremap_err));
        array.writeMany("\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showAllocateManyStructured(comptime s_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, comptime s_sentinel: ?*const s_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr + s_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        writeManyArrayNotationA(&array, s_child, s_aligned_bytes, s_sentinel);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    pub fn showAllocateHolderStructured(comptime s_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, comptime sentinel: ?*const s_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr + s_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        writeHolderArrayNotationA(&array, s_child, s_aligned_bytes, sentinel);
        array.writeMany("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showReallocateManyStructured(comptime s_child: type, comptime t_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, _: u64, t_ab_addr: u64, t_up_addr: u64, comptime s_sentinel: ?*const s_child, comptime t_sentinel: ?*const t_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr - t_ab_addr;
        const s_uw_addr: u64 = s_ab_addr + s_aligned_bytes;
        const t_uw_addr: u64 = t_ab_addr + t_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        writeManyArrayNotationB(&array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showReallocateHolderStructured(comptime s_child: type, comptime t_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, _: u64, t_ab_addr: u64, t_up_addr: u64, comptime s_sentinel: ?*const s_child, comptime t_sentinel: ?*const t_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr - t_ab_addr;
        const s_uw_addr: u64 = s_ab_addr + s_aligned_bytes;
        const t_uw_addr: u64 = t_ab_addr + t_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        writeHolderArrayNotationB(&array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showDeallocateManyStructured(comptime s_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, comptime s_sentinel: ?*const s_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const uw_offset: u64 = @sizeOf(s_child) * @boolToInt(s_sentinel != null);
        const s_uw_addr: u64 = s_up_addr - uw_offset;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        writeManyArrayNotationA(&array, s_child, s_aligned_bytes, s_sentinel);
        array.writeMany("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showDeallocateHolderStructured(comptime s_child: type, _: u64, s_ab_addr: u64, s_up_addr: u64, comptime s_sentinel: ?*const s_child, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const uw_offset: u64 = @sizeOf(s_child) * @boolToInt(s_sentinel != null);
        const s_uw_addr: u64 = s_up_addr - uw_offset;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        writeHolderArrayNotationA(&array, s_child, s_aligned_bytes, s_sentinel);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    pub fn verboseAllocateStaticUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr + s_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showAllocateManyUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr + s_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showReallocateManyUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, _: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr - t_ab_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showReallocateHolderUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, _: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr - t_ab_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showAllocateHolderUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr + s_aligned_bytes;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showDeallocateManyUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showDeallocateHolderUnstructured(_: u64, s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        file.noexcept.write(2, array.readAll());
    }
    fn showFiloDeallocateViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (builtin.is_perf) @panic(about_filo_error_s ++ "bad deallocate");
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
        const s_ua_addr: u64 = allocator.next();
        const d_aligned_bytes: u64 = s_ua_addr - s_up_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_filo_error_s ++ "attempted deallocation ");
        array.writeFormat(fmt.bytes(d_aligned_bytes));
        array.writeMany(" below segment maximum\n\n");
        file.noexcept.write(2, array.readAll());
        sys.exit(1);
    }
    fn showFiloResizeViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (builtin.is_perf) @panic(about_filo_error_s ++ "bad resize");
        const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
        const s_ua_addr: u64 = allocator.next();
        const d_aligned_bytes: u64 = s_ua_addr - s_up_addr;
        var array: PrintArray = .{};
        array.writeFormat(src_fmt);
        array.writeMany(about_filo_error_s ++ "attempted resize ");
        array.writeFormat(fmt.bytes(d_aligned_bytes));
        array.writeMany(" below segment maximum\n\n");
        file.noexcept.write(2, array.readAll());
        sys.exit(1);
    }
};
fn GenericAllocatorGraphics(comptime Allocator: type) type {
    return opaque {
        pub fn show(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.isSilent()) return;
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: debug.PrintArray = .{};
            array.writeFormat(src_fmt);
            if (Allocator.allocator_spec.logging.head) {
                array.writeMany(debug.about_next_s);
                array.writeFormat(fmt.ux64(allocator.next()));
                array.writeOne('\n');
            }
            if (Allocator.allocator_spec.logging.sentinel) {
                array.writeMany(debug.about_finish_s);
                array.writeFormat(fmt.ux64(allocator.finish()));
                array.writeOne('\n');
            }
            if (Allocator.allocator_spec.logging.metadata) {
                if (Allocator.allocator_spec.options.count_allocations) {
                    array.writeMany(debug.about_count_s);
                    array.writeFormat(fmt.ud64(allocator.metadata.count));
                    array.writeOne('\n');
                }
                if (Allocator.allocator_spec.options.count_useful_bytes) {
                    array.writeMany(debug.about_utility_s);
                    array.writeFormat(fmt.ud64(allocator.metadata.utility));
                    array.writeOne('/');
                    array.writeFormat(fmt.ud64(allocator.span()));
                    array.writeOne('\n');
                }
                if (Allocator.allocator_spec.options.check_parametric) {
                    array.writeMany(debug.about_holder_s);
                    array.writeFormat(fmt.ux64(allocator.metadata.holder));
                    array.writeOne('\n');
                }
            }
            if (Allocator.allocator_spec.logging.branches and
                Allocator.allocator_spec.options.count_branches)
            {
                Branches.Graphics.showWrite(allocator.metadata.branches, &array);
            }
            if (array.len() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        pub fn showWithReference(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.isSilent()) return;
            if (Allocator.allocator_spec.options.trace_state) {
                const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
                var array: debug.PrintArray = .{};
                array.writeFormat(src_fmt);
                if (Allocator.allocator_spec.logging.head and
                    allocator.reference.ub_addr != allocator.ub_addr)
                {
                    array.writeMany(debug.about_next_s);
                    array.writeFormat(fmt.uxd(allocator.reference.ub_addr, allocator.ub_addr));
                    array.writeOne('\n');
                    allocator.reference.ub_addr = allocator.ub_addr;
                }
                if (Allocator.allocator_spec.logging.sentinel and
                    allocator.reference.up_addr != allocator.up_addr)
                {
                    array.writeMany(debug.about_finish_s);
                    array.writeFormat(fmt.uxd(allocator.reference.up_addr, allocator.up_addr));
                    array.writeOne('\n');
                    allocator.reference.up_addr = allocator.up_addr;
                }
                if (Allocator.allocator_spec.logging.metadata) {
                    if (Allocator.allocator_spec.options.count_allocations and
                        allocator.reference.count != allocator.metadata.count)
                    {
                        array.writeMany(debug.about_count_s);
                        array.writeFormat(fmt.udd(allocator.reference.count, allocator.metadata.count));
                        array.writeOne('\n');
                        allocator.reference.count = allocator.metadata.count;
                    }
                    if (Allocator.allocator_spec.options.count_useful_bytes and
                        allocator.reference.utility != allocator.metadata.utility)
                    {
                        array.writeMany(debug.about_utility_s);
                        array.writeFormat(fmt.udd(allocator.reference.utility, allocator.metadata.utility));
                        array.writeOne('/');
                        array.writeFormat(fmt.ud(allocator.span()));
                        array.writeOne('\n');
                        allocator.reference.utility = allocator.metadata.utility;
                    }
                    if (Allocator.allocator_spec.options.check_parametric and
                        allocator.reference.holder != allocator.metadata.holder)
                    {
                        array.writeMany(debug.about_holder_s);
                        array.writeFormat(fmt.uxd(allocator.reference.holder, allocator.metadata.holder));
                        array.writeOne('\n');
                        allocator.reference.holder = allocator.metadata.holder;
                    }
                }
                if (Allocator.allocator_spec.logging.branches and
                    Allocator.allocator_spec.options.count_branches)
                {
                    Branches.Graphics.showWithReferenceWrite(allocator.metadata.branches, &allocator.reference.branches, &array);
                }
                if (array.len() != src_fmt.formatLength()) {
                    array.writeOne('\n');
                    file.noexcept.write(2, array.readAll());
                }
            } else {
                return show(allocator, src);
            }
        }
        fn showAllocateMany(comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.allocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showAllocateManyStructured, .{
                        impl_type.child, impl.low(), impl.start(),     impl.high(),
                        sentinel_ptr,    src,        @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showAllocateManyUnstructured, .{
                        impl.low(), impl.start(),     impl.high(),
                        src,        @returnAddress(),
                    });
                }
            }
        }
        const showAllocateStatic = showAllocateMany;
        fn showAllocateHolder(allocator: *const Allocator, comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.allocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showAllocateHolderStructured, .{
                        impl_type.child, impl.low(allocator.*), impl.start(allocator.*), impl.high(allocator.*),
                        sentinel_ptr,    src,                   @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showAllocateHolderUnstructured, .{
                        impl.low(allocator.*), impl.start(allocator.*), impl.high(allocator.*),
                        src,                   @returnAddress(),
                    });
                }
            }
        }
        fn showReallocateMany(comptime impl_type: type, s_impl: impl_type, t_impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.reallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showReallocateManyStructured, .{
                        impl_type.child, impl_type.child, s_impl.low(),
                        s_impl.start(),  s_impl.high(),   t_impl.low(),
                        t_impl.start(),  t_impl.high(),   sentinel_ptr,
                        sentinel_ptr,    src,             @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showReallocateManyUnstructured, .{
                        s_impl.low(), s_impl.start(),   s_impl.high(),
                        t_impl.low(), t_impl.start(),   t_impl.high(),
                        src,          @returnAddress(),
                    });
                }
            }
        }
        const showReallocateStatic = showReallocateMany;
        fn showReallocateHolder(allocator: *const Allocator, comptime impl_type: type, s_impl: impl_type, t_impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.reallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showReallocateHolderStructured, .{
                        impl_type.child,           impl_type.child,          s_impl.low(allocator.*),
                        s_impl.start(allocator.*), s_impl.high(allocator.*), t_impl.low(allocator.*),
                        t_impl.start(allocator.*), t_impl.high(allocator.*), sentinel_ptr,
                        sentinel_ptr,              src,                      @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showReallocateHolderUnstructured, .{
                        s_impl.low(allocator.*), s_impl.start(allocator.*), s_impl.high(allocator.*),
                        t_impl.low(allocator.*), t_impl.start(allocator.*), t_impl.high(allocator.*),
                        src,                     @returnAddress(),
                    });
                }
            }
        }
        const showResizeMany = showReallocateMany;
        const showResizeStatic = showReallocateStatic;
        const showResizeHolder = showReallocateHolder;
        fn showDeallocateMany(comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.deallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showDeallocateManyStructured, .{
                        impl_type.child, impl.low(), impl.start(),     impl.high(),
                        sentinel_ptr,    src,        @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showDeallocateManyUnstructured, .{
                        impl.low(), impl.start(),     impl.high(),
                        src,        @returnAddress(),
                    });
                }
            }
        }
        const showDeallocateStatic = showDeallocateMany;
        fn showDeallocateHolder(allocator: *const Allocator, comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.allocator_spec.logging.deallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.never_inline, debug.showDeallocateHolderStructured, .{
                        impl_type.child, impl.low(allocator.*), impl.start(allocator.*), impl.high(allocator.*),
                        sentinel_ptr,    src,                   @returnAddress(),
                    });
                } else {
                    @call(.never_inline, debug.showDeallocateHolderUnstructured, .{
                        impl.low(allocator.*), impl.start(allocator.*), impl.high(allocator.*),
                        src,                   @returnAddress(),
                    });
                }
            }
        }
    };
}
