const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const bits = @import("./bits.zig");
const math = @import("./math.zig");
const meta = @import("./meta.zig");
const algo = @import("./algo.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const ArenaAllocatorOptions = struct {
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
    /// Each new mapping must at least double the size of the existing
    /// mapped segment.
    require_geometric_growth: bool = builtin.is_fast,
    /// Allocator is required to reserve memory before allocation.
    require_map: bool = true,
    /// Allocator is required to unreserve memory on deinit.
    require_unmap: bool = true,
    /// Abort the program if an allocation can not be resized and can not return
    /// an error.
    require_resize: bool = true,
    /// Use mremap instead of mmap where possible.
    prefer_remap: bool = true,
    /// Populate (prefault) mappings
    require_populate: bool = false,
    /// Size of mapping at init.
    init_commit: ?u64 = if (builtin.is_fast) 32 * 1024 else null,
    /// Halt if size of total mapping exceeds quota.
    max_commit: ?u64 = if (builtin.is_safe) 16 * 1024 * 1024 * 1024 else null,
    /// Halt if size of next mapping exceeds quota.
    max_acquire: ?u64 = if (builtin.is_safe) 2 * 1024 * 1024 * 1024 else null,
    /// Lock on arena acquisition and release
    thread_safe: bool = builtin.is_safe,
    /// Every next address must be at least this aligned
    unit_alignment: u64 = 1,
    /// Every allocation length must be exactly divisible by this
    length_alignment: u64 = 1,
    /// Allocations are tracked as unique entities across resizes. (This setting
    /// currently has no effect, because the client trace list has not been
    /// implemented for this allocator).
    trace_clients: bool = false,
    /// Reports rendered relative to the last report, unchanged quantities
    /// are omitted.
    trace_state: bool = false,
};
pub const PageAllocatorOptions = struct {
    /// Lowest mappable number of bytes
    page_size: u64 = 4096,
    /// Count concurrent mappings, return to head if zero.
    count_segments: bool = builtin.is_debug,
    /// Count number of pages reserved.
    count_pages: bool = builtin.is_debug,
    /// Count each unique set of side-effects.
    count_branches: bool = builtin.is_debug,
    /// Halt program execution if not all free on deinit.
    require_all_free_deinit: bool = builtin.is_debug,
    /// Populate (prefault) mappings
    require_populate: bool = false,
    /// Halt if size of total mapping exceeds quota.
    max_commit: ?u64 = if (builtin.is_safe) 16 * 1024 * 1024 * 1024 else null,
    /// Halt if size of next mapping exceeds quota.
    max_acquire: ?u64 = if (builtin.is_safe) 2 * 1024 * 1024 * 1024 else null,
    /// Lock on arena acquisition and release
    thread_safe: bool = builtin.is_safe,
    /// Max number of concurrent threads
    thread_count: comptime_int = 16,
    /// Stack size afforded to each thread
    thread_stack_size: u64 = 1024 * 1024 * 16,
    /// Reports rendered relative to the last report, unchanged quantities
    /// are omitted.
    trace_state: bool = false,
};
pub const AllocatorLogging = packed struct {
    /// Report updates to allocator state
    head: bool = debug.logging_general.Success,
    sentinel: bool = debug.logging_general.Success,
    metadata: bool = debug.logging_general.Success,
    branches: bool = debug.logging_general.Success,
    illegal: bool = debug.logging_general.Fault,
    /// Report `mmap` Acquire and Release.
    map: debug.Logging.Field(mem.MapSpec) = .{},
    /// Report `munmap` Release and Error.
    unmap: debug.Logging.Field(mem.UnmapSpec) = .{},
    /// Report `mremap` Success and Error.
    remap: debug.Logging.Field(mem.RemapSpec) = .{},
    /// Report `madvise` Success and Error.
    advise: debug.Logging.Field(mem.AdviseSpec) = .{},
    /// Report when a reference is created.
    allocate: bool = debug.logging_general.Acquire,
    /// Report when a reference is modified (move/resize).
    reallocate: bool = debug.logging_general.Success,
    /// Report when a reference is converted to another kind of reference.
    reinterpret: bool = debug.logging_general.Success,
    /// Report when a reference is destroyed.
    deallocate: bool = debug.logging_general.Release,
};
const _1: mem.array.Amount = .{ .count = 1 };
pub const AllocatorErrors = struct {
    map: sys.ErrorPolicy = .{ .throw = mem.spec.mmap.errors.all },
    remap: sys.ErrorPolicy = .{ .throw = mem.spec.mremap.errors.all },
    unmap: sys.ErrorPolicy = .{ .abort = mem.spec.munmap.errors.all },
    madvise: sys.ErrorPolicy = .{ .throw = mem.spec.madvise.errors.all },
};
pub const ArenaAllocatorSpec = struct {
    AddressSpace: type,
    arena_index: comptime_int = undefined,
    options: ArenaAllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    fn arena(comptime allocator_spec: ArenaAllocatorSpec) mem.Arena {
        if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec or
            @TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec)
        {
            return allocator_spec.AddressSpace.arena(allocator_spec.arena_index);
        }
        if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec) {
            return allocator_spec.AddressSpace.arena();
        }
        @compileError("invalid address space for this allocator");
    }
    // If true, the allocator is responsible for reserving memory and the
    // address space is not.
    fn isMapper(comptime allocator_spec: ArenaAllocatorSpec) bool {
        const allocator_is_mapper: bool = allocator_spec.options.require_map;
        const address_space_is_mapper: bool = blk: {
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec or
                @TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk allocator_spec.AddressSpace.specification.options.require_map;
            }
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec) {
                break :blk allocator_spec.AddressSpace.specification.options(allocator_spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_mapper and address_space_is_mapper) {
            @compileError("both allocator and address space are mappers");
        }
        return allocator_spec.options.require_map;
    }
    // If true, the allocator is responsible for unreserving memory and the
    // address space is not.
    fn isUnmapper(comptime allocator_spec: ArenaAllocatorSpec) bool {
        const allocator_is_unmapper: bool = allocator_spec.options.require_unmap;
        const address_space_is_unmapper: bool = blk: {
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec or
                @TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk allocator_spec.AddressSpace.specification.options.require_map;
            }
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec) {
                break :blk allocator_spec.AddressSpace.specification.options(allocator_spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_unmapper and address_space_is_unmapper) {
            @compileError("both allocator and address space are unmappers");
        }
        return allocator_spec.options.require_unmap;
    }
};
pub const RtArenaAllocatorSpec = struct {
    AddressSpace: type,
    options: ArenaAllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    // If true, the allocator is responsible for reserving memory and the
    // address space is not.
    fn isMapper(comptime allocator_spec: RtArenaAllocatorSpec) bool {
        const allocator_is_mapper: bool = allocator_spec.options.require_map;
        const address_space_is_mapper: bool = allocator_spec.AddressSpace.specification.options.require_map;
        if (allocator_is_mapper and address_space_is_mapper) {
            @compileError("both allocator and address space are mappers");
        }
        return allocator_spec.options.require_map;
    }
    // If true, the allocator is responsible for unreserving memory and the
    // address space is not.
    fn isUnmapper(comptime allocator_spec: RtArenaAllocatorSpec) bool {
        const allocator_is_unmapper: bool = allocator_spec.options.require_unmap;
        const address_space_is_unmapper: bool = allocator_spec.AddressSpace.specification.options.require_unmap;
        if (allocator_is_unmapper and address_space_is_unmapper) {
            @compileError("both allocator and address space are unmappers");
        }
        return allocator_spec.options.require_unmap;
    }
};
pub const LinkedAllocatorOptions = struct {
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
    /// Each new mapping must at least double the size of the existing
    /// mapped segment.
    require_geometric_growth: bool = builtin.is_fast,
    /// Allocator is required to reserve memory before allocation.
    require_map: bool = true,
    /// Allocator is required to unreserve memory on deinit.
    require_unmap: bool = true,
    /// Abort the program if an allocation can not be resized and can not return
    /// an error.
    require_resize: bool = true,
    /// Use mremap instead of mmap where possible.
    prefer_remap: bool = true,
    /// Populate (prefault) mappings
    require_populate: bool = false,
    /// Size of mapping at init.
    init_commit: ?u64 = if (builtin.is_fast) 32 * 1024 else null,
    /// Halt if size of total mapping exceeds quota.
    max_commit: ?u64 = if (builtin.is_safe) 16 * 1024 * 1024 * 1024 else null,
    /// Halt if size of next mapping exceeds quota.
    max_acquire: ?u64 = if (builtin.is_safe) 2 * 1024 * 1024 * 1024 else null,
    /// Lock on arena acquisition and release
    thread_safe: bool = builtin.is_safe,
    /// Every next address must be at least this aligned
    unit_alignmentment: u64 = 1,
    /// Every allocation length must be exactly divisible by this
    length_alignment: u64 = 1,
    /// Allocations are tracked as unique entities across resizes. (This setting
    /// currently has no effect, because the client trace list has not been
    /// implemented for this allocator).
    trace_clients: bool = false,
    /// Reports rendered relative to the last report, unchanged quantities
    /// are omitted.
    trace_state: bool = false,
};
pub const LinkedAllocatorSpec = struct {
    AddressSpace: type,
    options: LinkedAllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    fn arena(comptime allocator_spec: LinkedAllocatorSpec) mem.Arena {
        if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec or
            @TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec)
        {
            return allocator_spec.AddressSpace.arena(allocator_spec.arena_index);
        }
        if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec) {
            return allocator_spec.AddressSpace.arena();
        }
        @compileError("invalid address space for this allocator");
    }
    // If true, the allocator is responsible for reserving memory and the
    // address space is not.
    fn isMapper(comptime allocator_spec: LinkedAllocatorSpec) bool {
        const allocator_is_mapper: bool = allocator_spec.options.require_map;
        const address_space_is_mapper: bool = blk: {
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec or
                @TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk allocator_spec.AddressSpace.specification.options.require_map;
            }
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec) {
                break :blk allocator_spec.AddressSpace.specification.options(allocator_spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_mapper and address_space_is_mapper) {
            @compileError("both allocator and address space are mappers");
        }
        return allocator_spec.options.require_map;
    }
    // If true, the allocator is responsible for unreserving memory and the
    // address space is not.
    fn isUnmapper(comptime allocator_spec: LinkedAllocatorSpec) bool {
        const allocator_is_unmapper: bool = allocator_spec.options.require_unmap;
        const address_space_is_unmapper: bool = blk: {
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.RegularAddressSpaceSpec or
                @TypeOf(allocator_spec.AddressSpace.specification) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk allocator_spec.AddressSpace.specification.options.require_map;
            }
            if (@TypeOf(allocator_spec.AddressSpace.specification) == mem.DiscreteAddressSpaceSpec) {
                break :blk allocator_spec.AddressSpace.specification.options(allocator_spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_unmapper and address_space_is_unmapper) {
            @compileError("both allocator and address space are unmappers");
        }
        return allocator_spec.options.require_unmap;
    }
};
fn GenericAllocatorInterface(comptime Allocator: type) type {
    const Graphics = GenericArenaAllocatorGraphics(Allocator);
    const T = struct {
        pub inline fn mapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.lb_addr;
        }
        pub inline fn unallocated_byte_address(allocator: *const Allocator) u64 {
            return allocator.ub_addr;
        }
        pub inline fn unmapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.up_addr;
        }
        pub inline fn unaddressable_byte_address(allocator: *const Allocator) u64 {
            return allocator.ua_addr;
        }
        pub inline fn allocated_byte_count(allocator: *const Allocator) u64 {
            return math.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return math.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        pub inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return math.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return math.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub inline fn alignAbove(allocator: *Allocator, alignment: u64) u64 {
            allocator.ub_addr = bits.alignA64(allocator.ub_addr, alignment);
            return allocator.ub_addr;
        }
        pub fn increment(allocator: *Allocator, s_up_addr: u64) void {
            allocator.ub_addr = s_up_addr;
        }
        pub fn decrement(allocator: *Allocator, s_lb_addr: u64) void {
            if (Allocator.specification.options.require_filo_free) {
                allocator.ub_addr = s_lb_addr;
            } else {
                allocator.ub_addr = bits.cmov64(reusable(allocator), allocator.lb_addr, s_lb_addr);
            }
        }
        pub fn reset(allocator: *Allocator) void {
            if (!Allocator.specification.options.require_filo_free) {
                allocator.ub_addr = bits.cmov64(reusable(allocator), allocator.lb_addr, allocator.ub_addr);
            }
        }
        pub fn map(allocator: *Allocator, s_bytes: u64) Allocator.allocate_void {
            debug.assertEqual(u64, s_bytes & 4095, 0);
            if (Allocator.specification.options.prefer_remap) {
                if (Allocator.specification.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.mapped_byte_count(), s_bytes);
                    try meta.wrap(mem.resize(
                        Allocator.remap_spec,
                        mapped_byte_address(allocator),
                        mapped_byte_count(allocator),
                        mapped_byte_count(allocator) +% t_bytes,
                    ));
                    allocator.up_addr +%= t_bytes;
                } else {
                    try meta.wrap(mem.resize(
                        Allocator.remap_spec,
                        mapped_byte_address(allocator),
                        mapped_byte_count(allocator),
                        mapped_byte_count(allocator) +% s_bytes,
                    ));
                    allocator.up_addr +%= s_bytes;
                }
            } else if (s_bytes >= 4096) {
                if (Allocator.specification.options.require_geometric_growth) {
                    const t_bytes: u64 = builtin.max(u64, allocator.mapped_byte_count(), s_bytes);
                    try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), t_bytes));
                    allocator.up_addr +%= t_bytes;
                } else {
                    try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), s_bytes));
                    allocator.up_addr +%= s_bytes;
                }
            }
        }
        pub fn unmap(allocator: *Allocator, s_bytes: u64) Allocator.deallocate_void {
            debug.assertEqual(u64, s_bytes & 4095, 0);
            if (s_bytes >= 4096) {
                allocator.up_addr -%= s_bytes;
                return mem.unmap(Allocator.unmap_spec, unmapped_byte_address(allocator), s_bytes);
            }
        }
        fn mapInit(allocator: *Allocator) sys.ErrorUnion(Allocator.map_spec.errors, void) {
            if (Allocator.specification.options.prefer_remap) {
                const s_bytes: u64 = Allocator.specification.options.init_commit orelse 4096;
                try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), s_bytes));
                allocator.up_addr +%= s_bytes;
            } else if (Allocator.specification.options.init_commit) |s_bytes| {
                try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), s_bytes));
                allocator.up_addr +%= s_bytes;
            }
        }
        pub fn unmapAll(allocator: *Allocator) Allocator.deallocate_void {
            const x_bytes: u64 = allocator.mapped_byte_count();
            if (Allocator.specification.options.count_useful_bytes) {
                debug.assertBelowOrEqual(u64, allocator.metadata.utility, 0);
            }
            if (Allocator.specification.options.count_allocations) {
                debug.assertBelowOrEqual(u64, allocator.metadata.count, 0);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn unmapAbove(allocator: *Allocator, s_up_addr: u64) Allocator.deallocate_void {
            const t_ua_addr: u64 = bits.alignA64(s_up_addr, 4096);
            const t_bytes: u64 = math.sub64(t_ua_addr, mapped_byte_address(allocator));
            const x_bytes: u64 = math.sub64(mapped_byte_count(allocator), t_bytes);
            if (Allocator.specification.options.count_useful_bytes) {
                debug.assertBelowOrEqual(u64, allocator.metadata.utility, t_bytes);
            }
            if (Allocator.specification.options.count_allocations) {
                debug.assertBelowOrEqual(u64, allocator.metadata.count, t_bytes);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn mapBelow(allocator: *Allocator, s_up_addr: u64) Allocator.allocate_void {
            const t_ua_addr: u64 = bits.alignA64(s_up_addr, 4096);
            const x_bytes: u64 = math.sub64(t_ua_addr, allocator.unmapped_byte_address());
            const t_bytes: u64 = math.add64(allocator.mapped_byte_count(), x_bytes);
            if (Allocator.specification.options.max_acquire) |max| {
                debug.assertBelowOrEqual(u64, x_bytes, max);
            }
            if (Allocator.specification.options.max_commit) |max| {
                debug.assertBelowOrEqual(u64, t_bytes, max);
            }
            if (Allocator.specification.options.require_map) {
                return allocator.map(x_bytes);
            }
        }
        fn reusable(allocator: *const Allocator) bool {
            if (Allocator.specification.options.count_useful_bytes) {
                return allocator.metadata.utility == 0;
            }
            if (Allocator.specification.options.count_allocations) {
                return allocator.metadata.count == 0;
            }
            return false;
        }
        pub fn discard(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.check_parametric) {
                allocator.metadata.holder = 0;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count = 0;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility = 0;
            }
            allocator.ub_addr = allocator.lb_addr;
        }
    };
    return T;
}
fn Types(comptime Allocator: type) type {
    return struct {
        /// This policy is applied to `init` return types.
        pub const map_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.specification.isMapper()) {
                break :blk Allocator.specification.errors.map;
            } else {
                break :blk Allocator.AddressSpace.specification.errors.map;
            }
        };
        /// This policy is applied to `deinit` return types.
        pub const unmap_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.specification.isMapper()) {
                break :blk Allocator.specification.errors.unmap;
            } else {
                break :blk Allocator.AddressSpace.specification.errors.unmap;
            }
            break :blk .{};
        };
        /// This policy is applied to any operation which may result in an
        /// increase to the amount of memory reserved by the allocator.
        pub const resize_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.specification.isMapper()) {
                if (Allocator.specification.options.prefer_remap) {
                    break :blk Allocator.specification.errors.remap;
                } else {
                    break :blk Allocator.specification.errors.map;
                }
            }
            break :blk .{};
        };
        pub const acquire_allocator: type = blk: {
            if (map_error_policy.throw.len != 0) {
                const MMapError = sys.Error(map_error_policy.throw);
                if (Allocator.AddressSpace.specification.errors.acquire == .throw) {
                    break :blk (MMapError || mem.ResourceError)!Allocator;
                }
                break :blk MMapError!Allocator;
            }
            if (Allocator.AddressSpace.specification.errors.acquire == .throw) {
                break :blk mem.ResourceError!Allocator;
            }
            break :blk Allocator;
        };
        pub const release_allocator: type = blk: {
            if (unmap_error_policy.throw.len != 0) {
                const MUnmapError = sys.Error(unmap_error_policy.throw);
                if (Allocator.AddressSpace.specification.errors.release == .throw) {
                    break :blk (MUnmapError || mem.ResourceError)!void;
                }
                break :blk MUnmapError!void;
            }
            if (Allocator.AddressSpace.specification.errors.release == .throw) {
                break :blk mem.ResourceError!void;
            }
            break :blk void;
        };
        /// For allocation operations which return a value
        pub fn allocate_payload(comptime s_impl_type: type) type {
            return sys.ErrorUnion(resize_error_policy, s_impl_type);
        }
        pub const init_void: type = sys.ErrorUnion(map_error_policy, void);
        /// For allocation operations which do not return a value
        pub const allocate_void: type = sys.ErrorUnion(resize_error_policy, void);
        pub const deallocate_void: type = sys.ErrorUnion(unmap_error_policy, void);
    };
}
fn Specs(comptime Allocator: type) type {
    return struct {
        const map_spec: mem.MapSpec = .{
            .errors = Allocator.specification.errors.map,
            .logging = Allocator.specification.logging.map,
        };
        const remap_spec: mem.RemapSpec = .{
            .errors = Allocator.specification.errors.remap,
            .logging = Allocator.specification.logging.remap,
        };
        const unmap_spec: mem.UnmapSpec = .{
            .errors = Allocator.specification.errors.unmap,
            .logging = Allocator.specification.logging.unmap,
        };
    };
}
inline fn ArenaAllocatorMetadata(comptime allocator_spec: anytype) type {
    const T = struct {
        branches: meta.maybe(allocator_spec.options.count_branches, Branches) = .{},
        holder: meta.maybe(allocator_spec.options.check_parametric, u64) = 0,
        count: meta.maybe(allocator_spec.options.count_allocations, u64) = 0,
        utility: meta.maybe(allocator_spec.options.count_useful_bytes, u64) = 0,
    };
    return T;
}
inline fn ArenaAllocatorReference(comptime allocator_spec: anytype) type {
    const T = struct {
        branches: meta.maybe(allocator_spec.options.trace_state, Branches) = .{},
        ub_addr: meta.maybe(allocator_spec.options.trace_state, u64) = 0,
        up_addr: meta.maybe(allocator_spec.options.trace_state, u64) = 0,
        holder: meta.maybe(allocator_spec.options.check_parametric, u64) = 0,
        count: meta.maybe(allocator_spec.options.count_allocations, u64) = 0,
        utility: meta.maybe(allocator_spec.options.count_useful_bytes, u64) = 0,
    };
    return T;
}
pub fn GenericArenaAllocator(comptime allocator_spec: ArenaAllocatorSpec) type {
    const T = struct {
        comptime lb_addr: u64 = lb_addr,
        ub_addr: u64,
        up_addr: u64,
        comptime ua_addr: u64 = ua_addr,
        metadata: ArenaAllocatorMetadata(allocator_spec) = .{},
        reference: ArenaAllocatorReference(allocator_spec) = .{},
        const Allocator = @This();
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const specification: ArenaAllocatorSpec = allocator_spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        pub const arena_index: u64 = allocator_spec.arena_index;
        const arena: mem.Arena = specification.arena();
        const lb_addr: u64 = arena.lb_addr;
        const ua_addr: u64 = arena.up_addr;
        pub fn init(address_space: *AddressSpace) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            allocator = .{
                .ub_addr = lb_addr,
                .up_addr = lb_addr,
            };
            switch (@TypeOf(AddressSpace.specification)) {
                mem.RegularAddressSpaceSpec => {
                    try meta.wrap(mem.acquire(AddressSpace, address_space, allocator_spec.arena_index));
                },
                mem.DiscreteAddressSpaceSpec => {
                    try meta.wrap(mem.acquireStatic(AddressSpace, address_space, allocator_spec.arena_index));
                },
                mem.ElementaryAddressSpaceSpec => {
                    try meta.wrap(mem.acquireElementary(AddressSpace, address_space));
                },
                else => @compileError("invalid address space for this allocator"),
            }
            if (Allocator.specification.options.require_map) {
                try meta.wrap(Allocator.mapInit(&allocator));
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.require_unmap) {
                try meta.wrap(allocator.unmapAll());
            }
            switch (@TypeOf(AddressSpace.specification)) {
                mem.RegularAddressSpaceSpec => {
                    try meta.wrap(mem.release(AddressSpace, address_space, allocator_spec.arena_index));
                },
                mem.DiscreteAddressSpaceSpec => {
                    try meta.wrap(mem.releaseStatic(AddressSpace, address_space, allocator_spec.arena_index));
                },
                mem.ElementaryAddressSpaceSpec => {
                    try meta.wrap(mem.releaseElementary(AddressSpace, address_space));
                },
                else => @compileError("invalid address space for this allocator"),
            }
        }
        pub usingnamespace Types(Allocator);
        pub usingnamespace Specs(Allocator);
        pub usingnamespace GenericAllocatorInterface(Allocator);
        pub usingnamespace GenericIrreversibleInterface(Allocator);
        pub usingnamespace GenericConfiguration(Allocator);
        pub usingnamespace GenericInterface(Allocator);
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        comptime {
            debug.assertEqual(u64, 1, unit_alignment);
        }
    };
    return T;
}
pub fn GenericRtArenaAllocator(comptime allocator_spec: RtArenaAllocatorSpec) type {
    return (struct {
        lb_addr: u64,
        ub_addr: u64,
        up_addr: u64,
        ua_addr: u64,
        metadata: ArenaAllocatorMetadata(allocator_spec) = .{},
        reference: ArenaAllocatorReference(allocator_spec) = .{},
        const Allocator = @This();
        const Value = fn (*const Allocator) callconv(.Inline) u64;
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const specification: RtArenaAllocatorSpec = allocator_spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        pub fn fromArena(arena: mem.Arena) Allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            allocator = .{
                .lb_addr = arena.lb_addr,
                .ub_addr = arena.lb_addr,
                .up_addr = arena.lb_addr,
                .ua_addr = arena.up_addr,
            };
            if (Allocator.specification.options.require_map) {
                try meta.wrap(Allocator.mapInit(&allocator));
            }
            return allocator;
        }
        pub fn init(address_space: *AddressSpace, arena_index: AddressSpace.Index) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            const lb_addr: u64 = allocator_spec.AddressSpace.low(arena_index);
            const ua_addr: u64 = allocator_spec.AddressSpace.high(arena_index);
            allocator = .{
                .lb_addr = lb_addr,
                .ub_addr = lb_addr,
                .up_addr = lb_addr,
                .ua_addr = ua_addr,
            };
            try meta.wrap(mem.acquire(AddressSpace, address_space, arena_index));
            if (Allocator.specification.options.require_map) {
                try meta.wrap(Allocator.mapInit(&allocator));
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace, arena_index: AddressSpace.Index) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.require_unmap) {
                try meta.wrap(Allocator.unmapAll(allocator));
            }
            try meta.wrap(mem.release(AddressSpace, address_space, arena_index));
        }
        pub usingnamespace Types(Allocator);
        pub usingnamespace Specs(Allocator);
        pub usingnamespace GenericAllocatorInterface(Allocator);
        pub usingnamespace GenericIrreversibleInterface(Allocator);
        pub usingnamespace GenericConfiguration(Allocator);
        pub usingnamespace GenericInterface(Allocator);
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        comptime {
            debug.assertEqual(u64, 1, unit_alignment);
        }
    });
}
pub fn GenericLinkedAllocator(comptime allocator_spec: LinkedAllocatorSpec) type {
    const T = struct {
        lb_addr: u64,
        ub_addr: u64,
        up_addr: u64,
        ua_addr: u64,
        const Allocator = @This();
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const specification: LinkedAllocatorSpec = allocator_spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        pub inline fn mapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.lb_addr;
        }
        pub inline fn unallocated_byte_address(allocator: *const Allocator) u64 {
            return allocator.ub_addr;
        }
        pub inline fn unmapped_byte_address(allocator: *const Allocator) u64 {
            return allocator.up_addr;
        }
        pub inline fn unaddressable_byte_address(allocator: *const Allocator) u64 {
            return allocator.ua_addr;
        }
        pub inline fn allocated_byte_count(allocator: *const Allocator) u64 {
            return bits.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return bits.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        pub inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return bits.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return bits.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub inline fn create(allocator: *Allocator, comptime s_child: type) Allocator.allocate_payload(*s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.allocateRaw(@sizeOf(s_child), @alignOf(s_child)),
            );
            const ret: *s_child = @ptrFromInt(s_ab_addr);
            if (Allocator.specification.logging.allocate) {
                showCreate(s_child, ret);
            }
            return ret;
        }
        pub inline fn allocate(allocator: *Allocator, comptime s_child: type, count: usize) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.allocateRaw(@sizeOf(s_child) *% count, @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            if (Allocator.specification.logging.allocate) {
                showAllocate(s_child, ret, null);
            }
            return ret;
        }
        pub inline fn reallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child, count: usize) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.reallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child), count *% @sizeOf(s_child), @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            if (Allocator.specification.logging.reallocate) {
                showReallocate(s_child, buf, ret, null);
            }
            return ret;
        }
        pub inline fn createAligned(
            allocator: *Allocator,
            comptime s_child: type,
            comptime s_alignment: usize,
        ) *align(s_alignment) Allocator.allocate_payload(s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(allocator.allocateRaw(@sizeOf(s_child), s_alignment));
            const ptr: *align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            if (Allocator.specification.logging.allocate) {
                showCreate(s_child, ptr);
            }
            return ptr;
        }
        pub inline fn allocateAligned(
            allocator: *Allocator,
            comptime s_child: type,
            count: usize,
            comptime s_alignment: usize,
        ) []align(s_alignment) Allocator.allocate_payload(s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(allocator.allocateRaw(@sizeOf(s_child) *% count, s_alignment));
            const ptr: [*]align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            const ret: []align(s_alignment) s_child = ptr[0..count];
            if (Allocator.specification.logging.allocate) {
                showAllocate(s_child, ret, null);
            }
            return ret;
        }
        pub inline fn deallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child) void {
            allocator.deallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child));
        }
        pub inline fn save(allocator: *const Allocator) usize {
            return allocator.ub_addr;
        }
        pub inline fn restore(allocator: *Allocator, state: usize) void {
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            allocator.ub_addr = state;
        }
        inline fn alignAbove(value: usize, alignment: usize) usize {
            const mask: usize = alignment -% 1;
            return (value +% mask) & ~mask;
        }
        pub fn fromArena(arena: mem.Arena) Allocator {
            @setRuntimeSafety(builtin.is_safe);
            const t_len: u64 = 4096;
            const t_s_node_addr: u64 = arena.lb_addr;
            try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, t_s_node_addr, t_len));
            const t_end: u64 = t_s_node_addr +% t_len;
            const t_u_node_addr: u64 = t_end -% Node4.size;
            const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
            Node4.create(t_s_node_addr, t_u_node_addr, t_f_node_addr);
            return .{ .lb_addr = t_s_node_addr, .ub_addr = t_f_node_addr, .up_addr = t_end, .ua_addr = arena.up_addr };
        }
        pub fn fromBuffer(buf: anytype) Allocator {
            return .{
                .start = @intFromPtr(buf.ptr),
                .next = @intFromPtr(buf.ptr),
                .finish = @intFromPtr(buf.ptr + @sizeOf(meta.Child(@TypeOf(buf)))),
            };
        }
        pub fn init(address_space: *AddressSpace, arena_index: AddressSpace.Index) !Allocator {
            try meta.wrap(mem.acquire(AddressSpace, address_space, arena_index));
            return fromArena(AddressSpace.arena(arena_index));
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace, arena_index: AddressSpace.Index) void {
            try meta.wrap(allocator.unmapAll());
            try meta.wrap(mem.release(AddressSpace, address_space, arena_index));
        }
        pub fn allocateRaw(
            allocator: *Allocator,
            s_aligned_bytes: usize,
            s_alignment: usize,
        ) Allocator.allocate_payload(usize) {
            @setRuntimeSafety(builtin.is_safe);
            var s_lb_addr: usize = allocator.ub_addr;
            var s_ul_addr: usize = Node4.link(s_lb_addr);
            var s_ab_addr: usize = bits.alignA64(s_lb_addr +% Node4.size, s_alignment);
            var s_up_addr: usize = bits.alignA64(s_ab_addr +% s_aligned_bytes, Node4.size);
            var r_np_addr: usize = s_ab_addr -% Node4.size;
            if (s_up_addr <= s_ul_addr) {
                Node4.allocate(s_up_addr, s_ul_addr, s_lb_addr, r_np_addr);
                allocator.ub_addr = s_up_addr;
                return s_ab_addr;
            }
            const s_bytes: usize = bits.alignA4096(3 *% Node4.size +% s_alignment +% s_aligned_bytes);
            try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, allocator.up_addr, s_bytes));
            allocator.ub_addr = allocator.addAny(allocator.up_addr, allocator.up_addr +% s_bytes);
            s_lb_addr = allocator.ub_addr;
            s_ul_addr = Node4.link(s_lb_addr);
            s_ab_addr = bits.alignA64(s_lb_addr +% Node4.size, s_alignment);
            s_up_addr = bits.alignA64(s_ab_addr +% s_aligned_bytes, Node4.size);
            r_np_addr = s_ab_addr -% Node4.size;
            Node4.allocate(s_up_addr, s_ul_addr, s_lb_addr, r_np_addr);
            allocator.ub_addr = s_up_addr;
            return s_ab_addr;
        }
        pub fn reallocateRaw(
            allocator: *Allocator,
            s_ab_addr: usize,
            s_aligned_bytes: usize,
            t_aligned_bytes: usize,
            t_alignment: usize,
        ) Allocator.allocate_payload(usize) {
            @setRuntimeSafety(builtin.is_safe);
            var s_lb_addr: usize = allocator.ub_addr;
            var s_al_addr: usize = s_ab_addr -% Node4.size;
            var l_np_addr: usize = freeConsolidate(s_lb_addr, s_al_addr);
            var t_ab_addr: usize = bits.alignA64(l_np_addr +% Node4.size, t_alignment);
            var t_np_addr: usize = t_ab_addr -% Node4.size;
            var t_up_addr: usize = bits.alignA64(t_ab_addr +% t_aligned_bytes, Node4.size);
            var r_np_addr: usize = Node4.link(l_np_addr);
            if (t_up_addr <= r_np_addr) {
                mem.addrcpy(t_ab_addr, s_ab_addr, s_aligned_bytes);
                Node4.reallocate(l_np_addr, t_np_addr, t_up_addr, r_np_addr);
                allocator.ub_addr = t_up_addr;
                return t_ab_addr;
            }
            const t_bytes: usize = bits.alignA4096(3 *% Node4.size +% t_alignment +% s_aligned_bytes);
            try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, allocator.up_addr, t_bytes));
            allocator.ub_addr = allocator.addAny(allocator.up_addr, allocator.up_addr +% t_bytes);
            s_lb_addr = allocator.ub_addr;
            s_al_addr = s_ab_addr -% Node4.size;
            l_np_addr = freeConsolidate(s_lb_addr, s_al_addr);
            t_ab_addr = bits.alignA64(l_np_addr +% Node4.size, t_alignment);
            t_np_addr = t_ab_addr -% Node4.size;
            t_up_addr = bits.alignA64(t_ab_addr +% t_aligned_bytes, Node4.size);
            r_np_addr = Node4.link(l_np_addr);
            mem.addrcpy(t_ab_addr, s_ab_addr, s_aligned_bytes);
            Node4.reallocate(l_np_addr, t_np_addr, t_up_addr, r_np_addr);
            allocator.ub_addr = t_up_addr;
            return t_ab_addr;
        }
        pub fn deallocateRaw(
            allocator: *Allocator,
            s_ab_addr: usize,
            _: usize,
        ) void {
            @setRuntimeSafety(builtin.is_safe);
            const s_np_addr: usize = s_ab_addr -% Node4.size;
            const r_np_addr: usize = Node4.link(s_np_addr);
            if (r_np_addr == allocator.ub_addr) {
                Node4.refer(s_np_addr).* = Node4.read(allocator.ub_addr);
                Node4.clear(allocator.ub_addr);
                allocator.ub_addr = s_np_addr;
            } else {
                Node4.write(s_np_addr, Node4.F | r_np_addr);
            }
        }
        pub fn addGeneric(allocator: *Allocator, size: usize, init_len: usize, ptr: *usize, max_len: *usize, len: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            const new_max_len: usize = len +% 2;
            if (max_len.* == 0) {
                ptr.* = allocateRaw(allocator, size *% init_len, 8);
                max_len.* = init_len;
            } else if (len == max_len.*) {
                ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, 8);
                max_len.* = new_max_len;
            }
            return ptr.* +% (size *% len);
        }
        pub fn addGenericSize(allocator: *Allocator, comptime Size: type, size: usize, init_len: Size, ptr: *usize, max_len: *Size, len: Size) usize {
            @setRuntimeSafety(builtin.is_safe);
            const new_max_len: Size = len +% 2;
            if (max_len.* == 0) {
                ptr.* = allocateRaw(allocator, size *% init_len, 8);
                max_len.* = init_len;
            } else if (len == max_len.*) {
                ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, 8);
                max_len.* = new_max_len;
            }
            return ptr.* +% (size *% len);
        }
        pub fn unmapAll(allocator: *Allocator) void {
            mem.unmap(Allocator.unmap_spec, allocator.lb_addr, allocator.up_addr -% allocator.lb_addr);
        }
        pub fn deallocateAll(allocator: *Allocator) void {
            @setRuntimeSafety(builtin.is_safe);
            var l_node_addr: u64 = allocator.lb_addr;
            while (true) {
                switch (Node4.kind(l_node_addr)) {
                    Node4.U => {
                        const r_node_addr: u64 = Node4.link(l_node_addr);
                        if (r_node_addr < l_node_addr) {
                            break;
                        }
                        l_node_addr = r_node_addr;
                    },
                    Node4.H => l_node_addr +%= Node4.size,
                    Node4.A => {
                        const r_node_addr: u64 = Node4.link(l_node_addr);
                        Node4.toggle(l_node_addr);
                        l_node_addr = r_node_addr;
                    },
                    Node4.F => l_node_addr = Node4.link(l_node_addr),
                    else => unreachable,
                }
            }
            allocator.consolidate();
        }
        pub fn consolidate(allocator: *Allocator) void {
            @setRuntimeSafety(builtin.is_safe);
            var r_capacity: u64 = 0;
            var l_node_addr: u64 = allocator.lb_addr +% Node4.size;
            while (true) {
                switch (Node4.kind(l_node_addr)) {
                    Node4.U => {
                        const r_node_addr: u64 = Node4.link(l_node_addr);
                        if (r_node_addr < l_node_addr) {
                            break;
                        }
                        l_node_addr = r_node_addr;
                    },
                    Node4.H => l_node_addr +%= Node4.size,
                    Node4.A => l_node_addr = Node4.link(l_node_addr),
                    Node4.F => {
                        const l_cell_addr: u64 = l_node_addr +% Node4.size;
                        const r_node_addr: u64 = fastConsolidate(l_node_addr);
                        const l_capacity: u64 = r_node_addr -% l_cell_addr;
                        if (r_capacity < l_capacity) {
                            r_capacity = l_capacity;
                            allocator.ub_addr = l_node_addr;
                        }
                        l_node_addr = r_node_addr;
                    },
                    else => unreachable,
                }
            }
        }
        fn fastConsolidate(t_node_addr: u64) u64 {
            @setRuntimeSafety(builtin.is_safe);
            var t_next_addr: u64 = Node4.link(t_node_addr);
            if (Node4.kind(t_next_addr) != Node4.F) {
                return t_next_addr;
            }
            while (true) {
                const r_next_addr: u64 = Node4.link(t_next_addr);
                if (Node4.kind(r_next_addr) == Node4.F) {
                    t_next_addr = r_next_addr;
                } else {
                    Node4.refer(t_node_addr).* = Node4.read(t_next_addr);
                    return r_next_addr;
                }
            }
            unreachable;
        }
        fn freeConsolidate(s_next_addr: u64, s_allocation_addr: u64) u64 {
            @setRuntimeSafety(builtin.is_safe);
            const t_next_addr: u64 = Node4.link(s_allocation_addr);
            if (t_next_addr == s_next_addr) {
                Node4.move(s_allocation_addr, s_next_addr);
                return s_allocation_addr;
            } else {
                const s_next: u64 = Node4.read(s_next_addr);
                Node4.write(s_allocation_addr, Node4.F | t_next_addr);
                Node4.write(s_next_addr, s_next);
                return s_next_addr;
            }
        }
        fn addBelow(allocator: *Allocator, t_s_node_addr: u64) u64 {
            @setRuntimeSafety(builtin.is_safe);
            const l_s_node_addr: u64 = allocator.lb_addr;
            const r_end: u64 = allocator.up_addr;
            allocator.lb_addr = t_s_node_addr;
            return Node4.prependFlush(t_s_node_addr, l_s_node_addr, r_end);
        }
        fn addAbove(allocator: *Allocator, t_end: u64) u64 {
            @setRuntimeSafety(builtin.is_safe);
            const r_end: u64 = allocator.up_addr;
            allocator.up_addr = t_end;
            return Node4.appendFlush(r_end, t_end);
        }
        fn addAny(allocator: *Allocator, t_s_node_addr: u64, t_end: u64) u64 {
            @setRuntimeSafety(builtin.is_safe);
            const r_end: u64 = allocator.up_addr;
            var l_s_node_addr: u64 = allocator.lb_addr;
            if (t_s_node_addr == r_end) {
                allocator.up_addr = t_end;
                return Node4.appendFlush(r_end, t_end);
            }
            if (t_end < l_s_node_addr) {
                allocator.lb_addr = t_s_node_addr;
                return Node4.prependBridged(t_s_node_addr, t_end, l_s_node_addr);
            }
            if (t_end == l_s_node_addr) {
                allocator.lb_addr = t_s_node_addr;
                return Node4.prependFlush(t_s_node_addr, l_s_node_addr, r_end);
            }
            if (t_s_node_addr > r_end) {
                allocator.up_addr = t_end;
                return Node4.appendBridged(r_end, t_s_node_addr, t_end);
            }
            var l_u_node_addr: u64 = Node4.link(l_s_node_addr);
            while (true) {
                const l_end: u64 = l_u_node_addr +% Node4.size;
                switch (Node4.kind(l_u_node_addr)) {
                    Node4.H => {
                        l_s_node_addr = l_u_node_addr;
                        l_u_node_addr = Node4.link(l_u_node_addr);
                    },
                    else => {
                        const r_s_node_addr: u64 = Node4.link(l_u_node_addr);
                        if (l_end < t_s_node_addr) {
                            if (t_end == r_s_node_addr) {
                                return Node4.insertBridgedFlush(l_u_node_addr, t_s_node_addr, r_s_node_addr, r_end);
                            }
                            if (t_end < r_s_node_addr) {
                                return Node4.insertBridgedBridged(l_u_node_addr, t_s_node_addr, t_end, r_s_node_addr);
                            }
                        }
                        if (l_end == t_s_node_addr) {
                            if (t_end == r_s_node_addr) {
                                return Node4.insertFlushFlush(l_s_node_addr, l_u_node_addr, r_s_node_addr, r_end);
                            }
                            if (t_end < r_s_node_addr) {
                                return Node4.insertFlushBridged(l_s_node_addr, l_u_node_addr, t_end, r_s_node_addr);
                            }
                        }
                        l_s_node_addr = l_u_node_addr;
                        l_u_node_addr = r_s_node_addr;
                    },
                }
                if (l_end == r_end) {
                    break;
                }
            }
            unreachable;
        }
        pub usingnamespace Types(Allocator);
        pub usingnamespace Specs(Allocator);
        pub const Graphics = GenericLinkedAllocatorGraphics(Allocator);
    };
    return T;
}

fn GenericIrreversibleInterface(comptime Allocator: type) type {
    const T = struct {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        pub inline fn create(allocator: *Allocator, comptime s_child: type) Allocator.allocate_payload(*s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.allocateRaw(@sizeOf(s_child), @alignOf(s_child)),
            );
            const ret: *s_child = @ptrFromInt(s_ab_addr);
            if (Allocator.specification.logging.allocate) {
                showCreate(s_child, ret);
            }
            return ret;
        }
        pub inline fn allocate(allocator: *Allocator, comptime s_child: type, count: usize) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.allocateRaw(@sizeOf(s_child) *% count, @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            if (Allocator.specification.logging.allocate) {
                showAllocate(s_child, ret, null);
            }
            return ret;
        }
        pub inline fn reallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child, count: usize) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = try meta.wrap(
                allocator.reallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child), count *% @sizeOf(s_child), @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            if (Allocator.specification.logging.reallocate) {
                showReallocate(s_child, buf, ret, null);
            }
            return ret;
        }
        pub inline fn createAligned(
            allocator: *Allocator,
            comptime s_child: type,
            comptime s_alignment: usize,
        ) *align(s_alignment) Allocator.allocate_payload(s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = allocator.allocateRaw(@sizeOf(s_child), s_alignment);
            const ptr: *align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            if (Allocator.specification.logging.allocate) {
                showCreate(s_child, ptr);
            }
            return ptr;
        }
        pub inline fn allocateAligned(
            allocator: *Allocator,
            comptime s_child: type,
            count: usize,
            comptime s_alignment: usize,
        ) []align(s_alignment) Allocator.allocate_payload(s_child) {
            @setRuntimeSafety(false);
            defer if (Allocator.specification.options.trace_state) {
                Graphics.showWithReference(allocator, @src());
            };
            const s_ab_addr: usize = allocator.allocateRaw(@sizeOf(s_child) *% count, s_alignment);
            const ptr: [*]align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            const ret: []align(s_alignment) s_child = ptr[0..count];
            if (Allocator.specification.logging.allocate) {
                showAllocate(s_child, ret, null);
            }
            return ret;
        }
        pub inline fn deallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child) void {
            allocator.deallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child));
        }
        pub inline fn save(allocator: *const Allocator) usize {
            return allocator.ub_addr;
        }
        pub inline fn restore(allocator: *Allocator, state: usize) void {
            defer Graphics.showWithReference(allocator, @src());
            allocator.ub_addr = state;
        }
        inline fn alignAbove(value: usize, alignment: usize) usize {
            const mask: usize = alignment -% 1;
            return (value +% mask) & ~mask;
        }
        pub fn allocateRaw(
            allocator: *Allocator,
            s_aligned_bytes: usize,
            s_alignment: usize,
        ) Allocator.allocate_payload(usize) {
            const s_ab_addr: usize = alignAbove(allocator.unallocated_byte_address(), s_alignment);
            const s_up_addr: usize = s_ab_addr +% s_aligned_bytes;
            if (Allocator.specification.options.require_map and s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(allocator.mapBelow(s_up_addr));
            }
            allocator.ub_addr = s_up_addr;
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count +%= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility +%= s_aligned_bytes;
            }
            return s_ab_addr;
        }
        pub fn reallocateRaw(
            allocator: *Allocator,
            s_ab_addr: usize,
            s_aligned_bytes: usize,
            t_aligned_bytes: usize,
            align_of: usize,
        ) Allocator.allocate_payload(usize) {
            const s_up_addr: usize = s_ab_addr +% s_aligned_bytes;
            const t_up_addr: usize = s_ab_addr +% t_aligned_bytes;
            if (allocator.unallocated_byte_address() == s_up_addr) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    try meta.wrap(allocator.mapBelow(t_up_addr));
                }
                allocator.increment(t_up_addr);
                return s_ab_addr;
            }
            const t_ab_addr: usize = try meta.wrap(allocator.allocateRaw(t_aligned_bytes, align_of));
            mem.addrcpy(t_ab_addr, s_ab_addr, s_aligned_bytes);
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count +%= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility +%= t_aligned_bytes -% s_aligned_bytes;
            }
            return t_ab_addr;
        }
        pub fn deallocateRaw(
            allocator: *Allocator,
            s_aligned: usize,
            s_aligned_bytes: usize,
        ) void {
            const s_next: usize = s_aligned +% s_aligned_bytes;
            if (allocator.unallocated_byte_address() == s_next) {
                allocator.ub_addr = s_next;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -%= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.count -%= s_aligned_bytes;
            }
        }
        pub fn addGeneric(allocator: *Allocator, size: usize, init_len: usize, ptr: *usize, max_len: *usize, len: usize) usize {
            const new_max_len: usize = len +% 2;
            if (max_len.* == 0) {
                ptr.* = allocateRaw(allocator, size *% init_len, 8);
                max_len.* = init_len;
            } else if (len == max_len.*) {
                ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, 8);
                max_len.* = new_max_len;
            }
            return ptr.* +% (size *% len);
        }
        pub fn addGenericSize(allocator: *Allocator, comptime Size: type, size: usize, init_len: Size, ptr: *usize, max_len: *Size, len: Size) usize {
            const new_max_len: Size = len +% 2;
            if (max_len.* == 0) {
                ptr.* = allocateRaw(allocator, size *% init_len, 8);
                max_len.* = init_len;
            } else if (len == max_len.*) {
                ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, 8);
                max_len.* = new_max_len;
            }
            return ptr.* +% (size *% len);
        }
        pub inline fn duplicate(allocator: *Allocator, comptime T: type, value: T) Allocator.allocate_payload(*T) {
            const ret: *T = try meta.wrap(allocator.create(T));
            ret.* = value;
            return ret;
        }
    };
    return T;
}
const Journal = struct {
    lists: struct {
        mem.GenericLinkedList(.{
            .child = Allocation,
            .Allocator = JournalAllocator,
            .low_alignment = 8,
        }),
        mem.GenericLinkedList(.{
            .child = Deallocation,
            .Allocator = JournalAllocator,
            .low_alignment = 8,
        }),
    },
    const JournalAllocator = struct {};
    pub const Allocation = struct {
        pc_addr: usize,
        lb_addr: usize,
        ab_addr: usize,
        up_addr: usize,
        alignment: usize,
    };
    pub const Deallocation = struct {
        pc_addr: usize,
        ab_addr: usize,
        up_addr: usize,
    };
    pub fn allocate(
        journal: *Journal,
        allocator: *mem.SimpleAllocator,
        pc_addr: usize,
        lb_addr: usize,
        ab_addr: u64,
        up_addr: u64,
        alignment: usize,
    ) void {
        return journal.lists[0].append(allocator, .{
            .pc_addr = pc_addr,
            .lb_addr = lb_addr,
            .ab_addr = ab_addr,
            .up_addr = up_addr,
            .alignment = alignment,
        });
    }
    pub fn deallocate(
        journal: *Journal,
        allocator: *mem.SimpleAllocator,
        pc_addr: usize,
        ab_addr: usize,
        up_addr: usize,
    ) void {
        var idx: usize = 0;
        while (journal.lists[0].at(idx)) |*allocation| : (idx +%= 1) {
            if (allocation.ab_addr == ab_addr) {
                return journal.lists[1].append(allocator, .{
                    .pc_addr = pc_addr,
                    .ab_addr = ab_addr,
                    .up_addr = up_addr,
                });
            }
        }
    }
};
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
        for (@as(
            [@divExact(@sizeOf(@TypeOf(@field(branches, field_name))), 8)]u64,
            @bitCast(@field(branches, field_name)),
        )) |count| sum +%= count;
        return sum;
    }
    const Graphics = opaque {
        const PrintArray = mem.array.StaticString(8192);
        const branch_s: []const u8 = "branch:         ";
        const grand_total_s: []const u8 = "grand total:    ";
        pub fn showBranches(branches: Branches, print_array: *PrintArray, comptime field_name: []const u8) void {
            const Branch: type = meta.Field(Branches, field_name);
            const super_branch_name: [:0]const u8 = comptime fmt.about(field_name);
            const sum: u64 = branches.sumBranches(field_name);
            const value: Branch = @field(branches, field_name);
            showWithReferenceWriteInternal(Branch, value, value, print_array, "", super_branch_name);
            print_array.writeMany(super_branch_name);
            print_array.writeFormat(fmt.udh(sum));
            print_array.writeOne('\n');
        }
        pub fn showBranchesWithReference(
            t_branches: Branches,
            s_branches: *Branches,
            print_array: *PrintArray,
            comptime field_name: []const u8,
        ) void {
            const Branch: type = meta.Field(Branches, field_name);
            const super_branch_name: [:0]const u8 = comptime fmt.about(field_name);
            const s_sum: u64 = s_branches.sumBranches(field_name);
            const t_sum: u64 = t_branches.sumBranches(field_name);
            const t_value: Branch = @field(t_branches, field_name);
            const s_value: *Branch = &@field(s_branches, field_name);
            showWithReferenceWriteInternal(Branch, t_value, s_value, print_array, "", super_branch_name);
            print_array.writeMany(super_branch_name);
            print_array.writeFormat(fmt.udd(s_sum, t_sum));
            print_array.writeOne('\n');
        }
        inline fn showWriteInternal(
            comptime T: type,
            branch: T,
            print_array: *PrintArray,
            comptime branch_name: []const u8,
            super_branch_name: ?[]const u8,
        ) void {
            inline for (@typeInfo(@TypeOf(branch)).Struct.fields) |field| {
                const branch_label: [:0]const u8 = branch_name ++ field.name ++ ",";
                const value: field.type = @field(branch, field.name);
                if (@typeInfo(field.type) == .Struct) {
                    showWriteInternal(field.type, value, print_array, branch_label, super_branch_name);
                } else if (value != 0) {
                    if (super_branch_name) |super_branch_name_s| {
                        print_array.writeMany(super_branch_name_s);
                    }
                    writeBranch(print_array, branch_label, value);
                }
            }
        }
        fn writeBranch(print_array: *PrintArray, branch_label: []const u8, value: usize) void {
            print_array.writeMany(branch_s);
            print_array.writeMany(branch_label);
            print_array.writeOne('\t');
            print_array.writeFormat(fmt.udh(value));
            print_array.writeOne('\n');
        }
        fn writeBranchChanged(print_array: *PrintArray, branch_label: []const u8, s_value: *usize, t_value: usize) void {
            print_array.writeMany(branch_s);
            print_array.writeMany(branch_label);
            print_array.writeOne('\t');
            print_array.writeFormat(fmt.udd(s_value.*, t_value));
            print_array.writeOne('\n');
        }
        inline fn showWithReferenceWriteInternal(
            comptime T: type,
            t_branch: T,
            s_branch: *T,
            print_array: *PrintArray,
            comptime branch_name: []const u8,
            super_branch_name: ?[]const u8,
        ) void {
            inline for (@typeInfo(@TypeOf(t_branch)).Struct.fields) |field| {
                const branch_label: [:0]const u8 = branch_name ++ field.name ++ ",";
                const t_value: field.type = @field(t_branch, field.name);
                const s_value: *field.type = &@field(s_branch, field.name);
                if (@typeInfo(field.type) == .Struct) {
                    showWithReferenceWriteInternal(field.type, t_value, s_value, print_array, branch_label, super_branch_name);
                    s_value.* = t_value;
                } else if (s_value.* != t_value) {
                    if (super_branch_name) |super_branch_name_s| {
                        print_array.writeMany(super_branch_name_s);
                    }
                    writeBranchChanged(print_array, branch_label, s_value, t_value);
                }
            }
        }
        pub fn showWrite(branches: Branches, print_array: *PrintArray) void {
            showWriteInternal(Branches, branches, print_array, "", null);
        }
        pub fn showWithReferenceWrite(t_branches: Branches, s_branches: *Branches, print_array: *PrintArray) void {
            showWithReferenceWriteInternal(Branches, t_branches, s_branches, print_array, "", null);
        }
        pub fn show(branches: Branches) void {
            var print_array: PrintArray = undefined;
            print_array.undefineAll();
            showWrite(branches, &print_array);
            debug.write(print_array.readAll());
        }
        pub fn showWithReference(t_branches: Branches, s_branches: *Branches) void {
            var print_array: PrintArray = undefined;
            print_array.undefineAll();
            showWithReferenceWrite(t_branches, s_branches, &print_array);
            debug.write(print_array.readAll());
        }
    };
};
fn GenericConfiguration(comptime Allocator: type) type {
    return opaque {
        pub fn StructuredStaticViewWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticView(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticView(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticViewLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticView(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticView(comptime child: type, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticView(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticStreamVectorWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticStreamVector(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticStreamVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticStreamVector(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticStreamVectorLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticStreamVector(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticStreamVector(comptime child: type, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticStreamVector(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticVectorWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticVector(child, &sentinel, count, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStaticVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticVector(child, &sentinel, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticVectorLowAligned(comptime child: type, comptime count: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticVector(child, null, count, low_alignment, Allocator, options);
        }
        pub fn StructuredStaticVector(comptime child: type, comptime count: u64) type {
            var options: mem.array.Parameters1.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStaticVector(child, null, count, @alignOf(child), Allocator, options);
        }
        pub fn UnstructuredStaticViewHighAligned(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticView(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticViewLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticView(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticView(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticView(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVectorHighAligned(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticStreamVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVectorLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticStreamVector(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticStreamVector(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticStreamVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticVectorHighAligned(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticVector(bytes, bytes, Allocator, options);
        }
        pub fn UnstructuredStaticVectorLowAligned(comptime bytes: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticVector(bytes, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStaticVector(comptime bytes: u64) type {
            var options: mem.array.Parameters2.Options = .{};
            options.unit_alignment = bytes == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStaticVector(bytes, bytes, Allocator, options);
        }
        pub fn StructuredStreamVectorWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamVector(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamVector(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamVectorLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamVector(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamVector(comptime child: type) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamVector(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamViewWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamView(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredStreamViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamView(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamViewLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamView(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamView(comptime child: type) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamView(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredVectorWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredVector(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredVectorLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredVector(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredVectorLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredVector(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredVector(comptime child: type) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredVector(child, null, @alignOf(child), Allocator, options);
        }
        pub fn StructuredViewWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredView(child, &sentinel, @alignOf(child), Allocator, options);
        }
        pub fn StructuredViewLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredView(child, &sentinel, low_alignment, Allocator, options);
        }
        pub fn StructuredViewLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredView(child, null, low_alignment, Allocator, options);
        }
        pub fn StructuredView(comptime child: type) type {
            var options: mem.array.Parameters3.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredView(child, null, @alignOf(child), Allocator, options);
        }
        pub fn UnstructuredStreamVectorHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamVector(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamVectorLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamVector(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamVector(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamVector(high_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamViewHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamView(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamViewLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamView(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredStreamView(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamView(high_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredVectorHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredVector(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredVectorLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredVector(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredVector(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredVector(high_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredViewHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredView(high_alignment, high_alignment, Allocator, options);
        }
        pub fn UnstructuredViewLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredView(low_alignment, low_alignment, Allocator, options);
        }
        pub fn UnstructuredView(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters4.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredView(high_alignment, low_alignment, Allocator, options);
        }
        pub fn StructuredStreamHolderWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamHolder(Allocator, child, &sentinel, @alignOf(child), options);
        }
        pub fn StructuredStreamHolderLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamHolder(Allocator, child, &sentinel, low_alignment, options);
        }
        pub fn StructuredStreamHolderLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamHolder(Allocator, child, null, low_alignment, options);
        }
        pub fn StructuredStreamHolder(comptime child: type) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredStreamHolder(Allocator, child, null, @alignOf(child), options);
        }
        pub fn StructuredHolderWithSentinel(comptime child: type, comptime sentinel: child) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredHolder(Allocator, child, &sentinel, @alignOf(child), options);
        }
        pub fn StructuredHolderLowAlignedWithSentinel(comptime child: type, comptime sentinel: child, comptime low_alignment: u64) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredHolder(Allocator, child, &sentinel, low_alignment, options);
        }
        pub fn StructuredHolderLowAligned(comptime child: type, comptime low_alignment: u64) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredHolder(Allocator, child, null, low_alignment, options);
        }
        pub fn StructuredHolder(comptime child: type) type {
            var options: mem.array.Parameters5.Options = .{};
            options.unit_alignment = @alignOf(child) == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.StructuredHolder(Allocator, child, null, @alignOf(child), options);
        }
        pub fn UnstructuredStreamHolderHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamHolder(Allocator, high_alignment, high_alignment, options);
        }
        pub fn UnstructuredStreamHolderLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamHolder(Allocator, low_alignment, low_alignment, options);
        }
        pub fn UnstructuredStreamHolder(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredStreamHolder(Allocator, high_alignment, low_alignment, options);
        }
        pub fn UnstructuredHolderHighAligned(comptime high_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = high_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredHolder(Allocator, high_alignment, high_alignment, options);
        }
        pub fn UnstructuredHolderLowAligned(comptime low_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredHolder(Allocator, low_alignment, low_alignment, options);
        }
        pub fn UnstructuredHolder(comptime high_alignment: u64, comptime low_alignment: u64) type {
            var options: mem.array.Parameters6.Options = .{};
            options.unit_alignment = low_alignment == Allocator.specification.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return mem.array.UnstructuredHolder(Allocator, high_alignment, low_alignment, options);
        }
    };
}
fn GenericInterface(comptime Allocator: type) type {
    const T = struct {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        const Intermediate = GenericArenaAllocatorIntermediate(Allocator);
        const Implementation = GenericArenaAllocatorImplementation(Allocator);
        pub fn allocateStatic(allocator: *Allocator, comptime s_impl_type: type, o_amt: ?mem.array.Amount) Allocator.allocate_payload(s_impl_type) {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    if (@hasField(Construct, "ss_addr")) {
                        const s_ab_addr: u64 = s_lb_addr;
                        const s_ss_addr: u64 = s_ab_addr;
                        const n_count: u64 = mem.array.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ss_addr = s_ss_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.array.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                    const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                    const s_ab_addr: u64 = s_lb_addr;
                    const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                    try meta.wrap(Intermediate.allocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                    return s_impl;
                }
            } else { // @1b1
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    if (@hasField(Construct, "ab_addr")) {
                        const s_ab_addr: u64 = bits.alignA64(s_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Construct, "ss_addr")) {
                            const s_ss_addr: u64 = s_ab_addr;
                            const n_count: u64 = mem.array.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                            const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                            const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                            try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        const n_count: u64 = mem.array.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.array.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                    const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                    const s_ab_addr: u64 = bits.alignA64(s_lb_addr, s_impl_type.low_alignment);
                    const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                    try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                    return s_impl;
                }
            }
        }
        pub fn allocateMany(allocator: *Allocator, comptime s_impl_type: type, n_amt: mem.array.Amount) Allocator.allocate_payload(s_impl_type) {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    if (@hasField(Construct, "up_addr")) {
                        const s_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
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
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    if (@hasField(Construct, "up_addr")) {
                        const s_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                        const s_ab_addr: u64 = bits.alignA64(s_lb_addr, s_impl_type.low_alignment);
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
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
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
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    const s_ab_addr: u64 = bits.alignA64(s_lb_addr, s_impl_type.low_alignment);
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
        pub fn resizeManyAbove(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.array.Amount) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertAbove(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveUnitAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertAbove(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyBelow(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.array.Amount) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertBelow(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowUnitAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertBelow(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.array.Amount) Allocator.allocate_void {
            if (!@hasDecl(s_impl_type, "defined_byte_count")) {
                @compileError("cannot grow fixed-size memory: " ++ @typeName(s_impl_type));
            }
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count() +
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes <= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveUnitAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count() +
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes <= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyDecrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.array.Amount) void {
            if (!@hasDecl(s_impl_type, "defined_byte_count")) {
                @compileError("cannot shrink fixed-size memory: " ++ @typeName(s_impl_type));
            }
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count() -
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes >= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowUnitAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count() -
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes >= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeHolderAbove(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.array.Amount) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveAnyAligned(allocator, t_up_addr));
            }
        }
        pub fn resizeHolderIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.array.Amount) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count(allocator.*) +
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const n_amt: mem.array.Amount = .{ .bytes = s_impl.defined_byte_count(allocator.*) +
                    mem.array.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.array.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveAnyAligned(allocator, t_up_addr));
            }
        }
        pub fn moveStatic(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = bits.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = t_lb_addr;
                        const t_ss_addr: u64 = t_ab_addr + s_impl.streamed_byte_count();
                        const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveStaticUnitAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr });
                    }
                    const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
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
                    const t_lb_addr: u64 = bits.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = bits.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Translate, "ss_addr")) {
                            const t_ss_addr: u64 = t_ab_addr + s_impl.streamed_byte_count();
                            const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .ss_addr = t_ss_addr });
                        }
                        const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr });
                    }
                    const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                    const t_aligned_bytes: u64 = s_aligned_bytes;
                    const t_ab_addr: u64 = bits.alignA64(t_lb_addr, s_impl_type.low_alignment);
                    const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                    try meta.wrap(Intermediate.moveStaticAnyAligned(allocator, t_up_addr));
                    return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr });
                }
            }
        }
        pub fn moveMany(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Translate: type = meta.FnParam1(s_impl_type.translate);
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                if (@hasField(Translate, "lb_addr")) {
                    const t_lb_addr: u64 = bits.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = t_lb_addr;
                        const t_ss_addr: u64 = t_ab_addr + s_impl.streamed_byte_count();
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyUnitAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "up_addr")) {
                        const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
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
                    const t_lb_addr: u64 = bits.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = bits.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Translate, "ss_addr")) {
                            const t_ss_addr: u64 = t_ab_addr + s_impl.streamed_byte_count();
                            if (@hasField(Translate, "up_addr")) {
                                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                                return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                            }
                        }
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ab_addr = t_ab_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "ss_addr")) {
                        const t_ab_addr: u64 = bits.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        const t_ss_addr: u64 = t_ab_addr + s_impl.streamed_byte_count();
                        if (@hasField(Translate, "up_addr")) {
                            const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                            return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .ss_addr = t_ss_addr, .up_addr = t_up_addr });
                        }
                    }
                    if (@hasField(Translate, "up_addr")) {
                        const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                        const t_aligned_bytes: u64 = s_aligned_bytes;
                        const t_ab_addr: u64 = bits.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .up_addr = t_up_addr });
                    }
                }
            }
        }
        pub fn deallocateStatic(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type, o_amt: ?mem.array.Amount) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const n_count: u64 = if (o_amt) |n_amt| mem.array.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
                const n_aligned_bytes: u64 = s_impl_type.aligned_byte_count();
                const s_aligned_bytes: u64 = n_aligned_bytes * n_count;
                const s_lb_addr: u64 = s_impl.allocated_byte_address();
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.deallocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            } else { // @1b1
                const n_count: u64 = if (o_amt) |n_amt| mem.array.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
                const n_aligned_bytes: u64 = s_impl_type.aligned_byte_count();
                const s_aligned_bytes: u64 = n_aligned_bytes * n_count;
                const s_lb_addr: u64 = s_impl.allocated_byte_address();
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.deallocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            }
        }
        pub fn deallocateMany(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_up_addr: u64 = s_impl.unallocated_byte_address();
                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                const s_lb_addr: u64 = s_impl.allocated_byte_address();
                Intermediate.deallocateManyUnitAligned(allocator, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            } else { // @1b1
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_up_addr: u64 = s_impl.unallocated_byte_address();
                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                const s_lb_addr: u64 = s_impl.allocated_byte_address();
                Intermediate.deallocateManyAnyAligned(allocator, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            }
        }
        pub fn deallocateHolder(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
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
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.allocated_byte_address(allocator.*);
                    if (@hasField(Convert, "up_addr")) {
                        const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                        const s_aligned_bytes: u64 = s_impl.defined_byte_count(allocator.*);
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                    const s_lb_addr: u64 = s_impl.allocated_byte_address(allocator.*);
                    if (@hasField(Convert, "up_addr")) {
                        const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                        const s_aligned_bytes: u64 = s_impl.defined_byte_count(allocator.*);
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        if (@hasField(Convert, "ab_addr")) {
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                            const s_ss_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.allocated_byte_address();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.unallocated_byte_address();
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
                                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.aligned_byte_address();
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
                    const s_lb_addr: u64 = s_impl.allocated_byte_address();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.unallocated_byte_address();
                        if (@hasField(Convert, "ab_addr")) {
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.aligned_byte_address();
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                            const s_ss_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
                                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.aligned_byte_address();
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
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Convert: type = meta.FnParam0(t_impl_type.convert);
                if (@hasField(Convert, "lb_addr")) {
                    const s_lb_addr: u64 = s_impl.allocated_byte_address();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.unallocated_byte_address();
                        if (@hasField(Convert, "ss_addr")) {
                            const s_ss_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
                                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyUnitAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.aligned_byte_address();
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
                    const s_lb_addr: u64 = s_impl.allocated_byte_address();
                    if (@hasField(Convert, "up_addr")) {
                        const s_up_addr: u64 = s_impl.unallocated_byte_address();
                        if (@hasField(Convert, "ab_addr")) {
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ss_addr")) {
                                const s_ss_addr: u64 = s_impl.aligned_byte_address();
                                if (@hasField(Convert, "ub_addr")) {
                                    const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
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
                            const s_ss_addr: u64 = s_impl.aligned_byte_address();
                            if (@hasField(Convert, "ub_addr")) {
                                const s_ub_addr: u64 = s_impl.undefined_byte_address();
                                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                                const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                                const t_aligned_bytes: u64 = s_aligned_bytes;
                                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                                try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                                return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr, .ub_addr = s_ub_addr });
                            }
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ss_addr = s_ss_addr });
                        }
                        if (@hasField(Convert, "ub_addr")) {
                            const s_ub_addr: u64 = s_impl.undefined_byte_address();
                            const s_ab_addr: u64 = s_impl.aligned_byte_address();
                            const s_aligned_bytes: u64 = s_up_addr - s_ab_addr;
                            const t_aligned_bytes: u64 = s_aligned_bytes;
                            const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                            try meta.wrap(Intermediate.convertAnyManyAnyAligned(allocator, s_up_addr, t_up_addr));
                            return t_impl_type.convert(.{ .lb_addr = s_lb_addr, .up_addr = s_up_addr, .ub_addr = s_ub_addr });
                        }
                        const s_ab_addr: u64 = s_impl.aligned_byte_address();
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
    return T;
}
fn GenericArenaAllocatorIntermediate(comptime Allocator: type) type {
    const T = struct {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        const Implementation = GenericArenaAllocatorImplementation(Allocator);
        fn allocateStaticUnitAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.allocateStaticUnitAlignedUnaddressable(allocator, n_count, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateStaticUnitAlignedAddressable(allocator, n_count, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateStaticAnyAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.allocateStaticAnyAlignedUnaddressable(allocator, n_count, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateStaticAnyAlignedAddressable(allocator, n_count, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateManyUnitAligned(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.allocateManyUnitAlignedUnaddressable(allocator, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateManyUnitAlignedAddressable(allocator, s_aligned_bytes, s_up_addr);
            }
        }
        fn allocateManyAnyAligned(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.allocateManyAnyAlignedUnaddressable(allocator, s_aligned_bytes, s_up_addr));
            } else {
                Implementation.allocateManyAnyAlignedAddressable(allocator, s_aligned_bytes, s_up_addr);
            }
        }
        fn resizeManyAboveUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    try meta.wrap(Implementation.resizeManyAboveUnitAlignedUnaddressable(allocator, s_up_addr, t_up_addr));
                } else {
                    Implementation.resizeManyAboveUnitAlignedAddressable(allocator, s_up_addr, t_up_addr);
                }
            } else if (Allocator.allocate_void != void) {
                return error.CannotAllocateMemory;
            } else if (Allocator.specification.options.require_resize) {
                @trap();
            }
        }
        fn resizeManyAboveAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    try meta.wrap(Implementation.resizeManyAboveAnyAlignedUnaddressable(allocator, s_up_addr, t_up_addr));
                } else {
                    Implementation.resizeManyAboveAnyAlignedAddressable(allocator, s_up_addr, t_up_addr);
                }
            } else if (Allocator.allocate_void != void) {
                return error.CannotAllocateMemory;
            } else if (Allocator.specification.options.require_resize) {
                @trap();
            }
        }
        fn resizeManyBelowUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.resizeManyBelowUnitAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloResizeViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.resizeManyBelowUnitAlignedEndInternal(allocator, s_up_addr, t_up_addr);
            }
        }
        fn resizeManyBelowAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.resizeManyBelowAnyAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloResizeViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.resizeManyBelowAnyAlignedEndInternal(allocator, s_up_addr, t_up_addr);
            }
        }
        fn resizeHolderAboveUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.resizeHolderAboveUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.resizeHolderAboveUnitAlignedAddressable(allocator);
            }
        }
        fn resizeHolderAboveAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.resizeHolderAboveAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.resizeHolderAboveAnyAlignedAddressable(allocator);
            }
        }
        fn moveStaticUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.moveStaticUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveStaticUnitAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveStaticAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.moveStaticAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveStaticAnyAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveManyUnitAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.moveManyUnitAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveManyUnitAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn moveManyAnyAligned(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.moveManyAnyAlignedUnaddressable(allocator, t_up_addr));
            } else {
                Implementation.moveManyAnyAlignedAddressable(allocator, t_up_addr);
            }
        }
        fn deallocateStaticUnitAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateStaticUnitAlignedEndBoundary(allocator, n_count, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticUnitAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateStaticAnyAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateStaticAnyAlignedEndBoundary(allocator, n_count, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticAnyAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateManyUnitAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateManyUnitAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateManyUnitAlignedEndInternal(allocator, s_aligned_bytes);
            }
        }
        fn deallocateManyAnyAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateManyAnyAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.specification.options.require_filo_free) {
                about.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateManyAnyAlignedEndInternal(allocator, s_aligned_bytes);
            }
        }
        fn convertHolderManyUnitAligned(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.convertHolderManyUnitAlignedUnaddressable(allocator, t_aligned_bytes, t_up_addr));
            } else {
                Implementation.convertHolderManyUnitAlignedAddressable(allocator, t_aligned_bytes, t_up_addr);
            }
        }
        fn convertHolderManyAnyAligned(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            if (t_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(Implementation.convertHolderManyAnyAlignedUnaddressable(allocator, t_aligned_bytes, t_up_addr));
            } else {
                Implementation.convertHolderManyAnyAlignedAddressable(allocator, t_aligned_bytes, t_up_addr);
            }
        }
        fn convertAnyManyUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    Implementation.convertAnyManyUnitAlignedUnaddressable(allocator);
                } else {
                    Implementation.convertAnyManyUnitAlignedAddressable(allocator);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else if (Allocator.specification.options.require_resize) {
                @trap();
            }
        }
        fn convertAnyManyAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    Implementation.convertAnyManyAnyAlignedUnaddressable(allocator);
                } else {
                    Implementation.convertAnyManyAnyAlignedAddressable(allocator);
                }
            } else if (Allocator.allocate_void != void) {
                return error.OpaqueSystemError;
            } else if (Allocator.specification.options.require_resize) {
                @trap();
            }
        }
    };
    return T;
}
fn GenericArenaAllocatorImplementation(comptime Allocator: type) type {
    const T = struct {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        fn allocateStaticAnyAlignedAddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.static.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
        }
        fn allocateStaticAnyAlignedUnaddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.static.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
        }
        fn allocateStaticUnitAlignedAddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.static.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
        }
        fn allocateStaticUnitAlignedUnaddressable(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.static.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
        }
        fn allocateManyAnyAlignedAddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.many.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
        }
        fn allocateManyAnyAlignedUnaddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.many.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
        }
        fn allocateManyUnitAlignedAddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.many.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
        }
        fn allocateManyUnitAlignedUnaddressable(allocator: *Allocator, s_aligned_bytes: u64, s_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.many.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += s_aligned_bytes;
            }
            allocator.increment(s_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
        }
        fn allocateHolderAnyAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.holder.any_aligned += 1;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = s_lb_addr;
            }
        }
        fn allocateHolderUnitAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.allocate.holder.unit_aligned += 1;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = s_lb_addr;
            }
        }
        fn resizeManyBelowAnyAlignedEndBoundary(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.below.any_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr, t_up_addr);
            }
            allocator.decrement(s_up_addr);
        }
        fn resizeManyBelowAnyAlignedEndInternal(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.below.any_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr, t_up_addr);
            }
        }
        fn resizeManyBelowUnitAlignedEndBoundary(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.below.unit_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr, t_up_addr);
            }
            allocator.decrement(s_up_addr);
        }
        fn resizeManyBelowUnitAlignedEndInternal(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.below.unit_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr, t_up_addr);
            }
        }
        fn resizeManyAboveAnyAlignedAddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.above.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn resizeManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn resizeManyAboveUnitAlignedAddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn resizeManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn resizeHolderBelowAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.below.any_aligned += 1;
            }
        }
        fn resizeHolderBelowUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.below.unit_aligned += 1;
            }
        }
        fn resizeHolderAboveAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.any_aligned.addressable += 1;
            }
        }
        fn resizeHolderAboveAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn resizeHolderAboveUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.unit_aligned.addressable += 1;
            }
        }
        fn resizeHolderAboveUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.resize.holder.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveStaticAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveStaticAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveStaticUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveStaticUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveManyAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveManyAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveManyUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveManyUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn reallocateManyBelowAnyAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowAnyAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn reallocateManyAboveUnitAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += math.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn convertAnyStaticAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.static.any_aligned.addressable += 1;
            }
        }
        fn convertAnyStaticAnyAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.static.any_aligned.unaddressable += 1;
            }
        }
        fn convertAnyStaticUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.static.unit_aligned.addressable += 1;
            }
        }
        fn convertAnyStaticUnitAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.static.unit_aligned.unaddressable += 1;
            }
        }
        fn convertAnyManyAnyAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.many.any_aligned.addressable += 1;
            }
        }
        fn convertAnyManyAnyAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.many.any_aligned.unaddressable += 1;
            }
        }
        fn convertAnyManyUnitAlignedAddressable(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.many.unit_aligned.addressable += 1;
            }
        }
        fn convertAnyManyUnitAlignedUnaddressable(allocator: *Allocator) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.any.many.unit_aligned.unaddressable += 1;
            }
        }
        fn convertHolderStaticAnyAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
        }
        fn convertHolderStaticAnyAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn convertHolderStaticUnitAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
        }
        fn convertHolderStaticUnitAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.static.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn convertHolderManyAnyAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.any_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
        }
        fn convertHolderManyAnyAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.any_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn convertHolderManyUnitAlignedAddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.unit_aligned.addressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
        }
        fn convertHolderManyUnitAlignedUnaddressable(allocator: *Allocator, t_aligned_bytes: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.many.unit_aligned.unaddressable += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count += 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility += t_aligned_bytes;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.specification.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn convertHolderHolderAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.holder.any_aligned += 1;
            }
        }
        fn convertHolderHolderUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.convert.holder.holder.unit_aligned += 1;
            }
        }
        fn deallocateStaticAnyAlignedEndBoundary(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.static.any_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.decrement(s_lb_addr);
        }
        fn deallocateStaticAnyAlignedEndInternal(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.static.any_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateStaticUnitAlignedEndBoundary(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.static.unit_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.decrement(s_lb_addr);
        }
        fn deallocateStaticUnitAlignedEndInternal(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.static.unit_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= n_count;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateManyAnyAlignedEndBoundary(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.many.any_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.decrement(s_lb_addr);
        }
        fn deallocateManyAnyAlignedEndInternal(allocator: *Allocator, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.many.any_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateManyUnitAlignedEndBoundary(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.many.unit_aligned.end_boundary += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.decrement(s_lb_addr);
        }
        fn deallocateManyUnitAlignedEndInternal(allocator: *Allocator, s_aligned_bytes: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.many.unit_aligned.end_internal += 1;
            }
            if (Allocator.specification.options.count_allocations) {
                allocator.metadata.count -= 1;
            }
            if (Allocator.specification.options.count_useful_bytes) {
                allocator.metadata.utility -= s_aligned_bytes;
            }
            allocator.reset();
        }
        fn deallocateHolderAnyAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.holder.any_aligned += 1;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
        fn deallocateHolderUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.specification.options.count_branches) {
                allocator.metadata.branches.deallocate.holder.unit_aligned += 1;
            }
            if (Allocator.specification.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
    };
    return T;
}
const about = opaque {
    const PrintArray = mem.array.StaticString(8192);
    const ArenaRange = fmt.AddressRangeFormat;
    const ChangedArenaRange = fmt.ChangedAddressRangeFormat;
    const ChangedBytes = fmt.GenericChangedBytesFormat(.{});
    const next_s: []const u8 = fmt.about("next");
    const count_s: []const u8 = fmt.about("count");
    const map_s: []const u8 = fmt.about("map");
    const map_1_s: []const u8 = fmt.about("map-error");
    const acq_s: []const u8 = fmt.about("acq");
    const acq_1_s: []const u8 = fmt.about("acq-error");
    const rel_s: []const u8 = fmt.about("rel");
    const rel_1_s: []const u8 = fmt.about("rel-error");
    const acq_2_s: []const u8 = fmt.about("acq-fault\n");
    const rel_2_s: []const u8 = fmt.about("rel-fault\n");
    const brk_1_s: []const u8 = fmt.about("brk-error");
    const no_op_s: []const u8 = fmt.about("no-op");
    const move_s: []const u8 = fmt.about("move");
    const move_1_s: []const u8 = fmt.about("move-error");
    const finish_s: []const u8 = fmt.about("finish");
    const holder_s: []const u8 = fmt.about("holder");
    const unmap_s: []const u8 = fmt.about("unmap");
    const unmap_1_s: []const u8 = fmt.about("unmap-error");
    const remap_s: []const u8 = fmt.about("remap");
    const remap_1_s: []const u8 = fmt.about("remap-error");
    const utility_s: []const u8 = fmt.about("utility");
    const capacity_s: []const u8 = fmt.about("capacity");
    const resize_s: []const u8 = fmt.about("resize");
    const resize_1_s: []const u8 = fmt.about("resize-error");
    const advice_s: []const u8 = fmt.about("advice");
    const advice_1_s: []const u8 = fmt.about("advice-error");
    const remapped_s: []const u8 = fmt.about("remapped");
    const allocated_s: []const u8 = fmt.about("allocated");
    const filo_error_s: []const u8 = fmt.about("filo-error");
    const deallocated_s: []const u8 = fmt.about("deallocated");
    const reallocated_s: []const u8 = fmt.about("reallocated");
    const pretty_bytes: bool = true;
    fn writeErrorName(print_array: *PrintArray, error_name: []const u8) void {
        print_array.writeMany("(");
        print_array.writeMany(error_name);
        print_array.writeMany(")");
    }
    fn writeAddressRange(print_array: *PrintArray, begin: u64, end: u64) void {
        print_array.writeFormat(fmt.ux64(begin));
        print_array.writeMany("..");
        print_array.writeFormat(fmt.ux64(end));
    }
    fn writeBytes(print_array: *PrintArray, begin: u64, end: u64) void {
        if (pretty_bytes) {
            print_array.writeFormat(fmt.bytes(end -% begin));
        } else {
            print_array.writeFormat(fmt.ud64(end -% begin));
            print_array.writeMany(" bytes");
        }
    }
    fn writeAddressRangeBytes(print_array: *PrintArray, begin: u64, end: u64) void {
        writeAddressRange(print_array, begin, end);
        print_array.writeMany(", ");
        writeBytes(print_array, begin, end);
    }
    fn writeChangedAddressRange(print_array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        writeAddressRange(print_array, old_begin, old_end);
        print_array.writeMany(" -> ");
        writeAddressRange(print_array, new_begin, new_end);
    }
    fn writeChangedBytes(print_array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        const old_len: u64 = old_end -% old_begin;
        const new_len: u64 = new_end -% new_begin;
        print_array.writeFormat(fmt.ud64(old_len));
        if (old_len != new_len) {
            print_array.writeMany(" -> ");
            print_array.writeFormat(fmt.ud64(new_len));
        }
        print_array.writeMany(" bytes");
    }
    fn writeChangedAddressRangeBytes(print_array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        writeChangedAddressRange(print_array, old_begin, old_end, new_begin, new_end);
        print_array.writeMany(", ");
        writeChangedBytes(print_array, old_begin, old_end, new_begin, new_end);
    }
    fn writeAddressSpaceA(print_array: *PrintArray, s_ab_addr: u64, s_uw_addr: u64) void {
        print_array.writeFormat(ArenaRange.init(s_ab_addr, s_uw_addr));
        print_array.writeMany(", ");
    }
    fn writeAddressSpaceB(print_array: *PrintArray, s_ab_addr: u64, s_uw_addr: u64, t_ab_addr: u64, t_uw_addr: u64) void {
        print_array.writeFormat(ChangedArenaRange.init(s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr));
        print_array.writeMany(", ");
    }
    fn writeAlignedBytesA(print_array: *PrintArray, s_aligned_bytes: u64) void {
        print_array.writeFormat(fmt.bytes(s_aligned_bytes));
        print_array.writeMany(", ");
    }
    fn writeAlignedBytesB(print_array: *PrintArray, s_aligned_bytes: u64, t_aligned_bytes: u64) void {
        print_array.writeFormat(ChangedBytes.init(s_aligned_bytes, t_aligned_bytes));
        print_array.writeMany(", ");
    }
    fn writeModifyOperation(print_array: *PrintArray, s_ab_addr: u64, s_aligned_bytes: u64, t_ab_addr: u64, t_aligned_bytes: u64) void {
        if (s_aligned_bytes != t_aligned_bytes and s_ab_addr == t_ab_addr) {
            return print_array.writeMany(resize_s);
        }
        if (s_aligned_bytes == t_aligned_bytes and s_ab_addr != t_ab_addr) {
            return print_array.writeMany(move_s);
        }
        if (s_ab_addr != t_ab_addr) {
            return print_array.writeMany(reallocated_s);
        }
        print_array.writeMany(no_op_s);
    }
    fn writeManyArrayNotation(print_array: *PrintArray, comptime child: type, count: u64, comptime sentinel: ?*const child) void {
        print_array.writeOne('[');
        print_array.writeFormat(fmt.ud64(count));
        if (sentinel) |sentinel_ptr| {
            print_array.writeOne(':');
            print_array.writeFormat(fmt.any(sentinel_ptr.*));
            print_array.writeOne(']');
        } else {
            print_array.writeOne(']');
        }
        print_array.writeMany(@typeName(child));
    }
    fn writeHolderArrayNotation(print_array: *PrintArray, comptime child: type, count: u64, comptime sentinel: ?*const child) void {
        print_array.writeOne('[');
        print_array.writeFormat(fmt.ud64(count));
        print_array.writeMany("..*");
        if (sentinel) |sentinel_ptr| {
            print_array.writeOne(':');
            print_array.writeFormat(fmt.any(sentinel_ptr.*));
            print_array.writeOne(']');
        } else {
            print_array.writeOne(']');
        }
        print_array.writeMany(@typeName(child));
    }
    fn writeChangedManyArrayNotation(print_array: *PrintArray, comptime child: type, s_count: u64, t_count: u64, comptime sentinel: ?*const child) void {
        print_array.writeOne('[');
        print_array.writeFormat(fmt.udd(s_count, t_count));
        if (sentinel) |sentinel_ptr| {
            print_array.writeOne(':');
            print_array.writeFormat(fmt.any(sentinel_ptr.*));
            print_array.writeOne(']');
        } else {
            print_array.writeOne(']');
        }
        print_array.writeMany(@typeName(child));
    }
    fn writeChangedHolderArrayNotation(print_array: *PrintArray, comptime child: type, s_count: u64, t_count: u64, comptime sentinel: ?*const child) void {
        print_array.writeOne('[');
        print_array.writeFormat(fmt.udd(s_count, t_count));
        print_array.writeMany("..*");
        if (sentinel) |sentinel_ptr| {
            print_array.writeOne(':');
            print_array.writeFormat(fmt.any(sentinel_ptr.*));
            print_array.writeOne(']');
        } else {
            print_array.writeOne(']');
        }
        print_array.writeMany(@typeName(child));
    }
    fn writeOneType(print_array: *PrintArray, comptime s_child: type) void {
        print_array.writeMany(@typeName(s_child));
        print_array.writeMany(", ");
    }
    fn writeManyArrayNotationA(
        print_array: *PrintArray,
        comptime s_child: type,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        writeManyArrayNotation(print_array, s_child, s_count, s_sentinel);
        print_array.writeMany(", ");
    }
    fn writeManyArrayNotationB(
        print_array: *PrintArray,
        comptime s_child: type,
        comptime t_child: type,
        s_aligned_bytes: u64,
        t_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes -% @sizeOf(t_child) *% @as(u64, @intFromBool(t_sentinel != null))) / @sizeOf(t_child);
        if (s_child == t_child and s_sentinel == t_sentinel) {
            if (s_count != t_count) {
                writeChangedManyArrayNotation(print_array, s_child, s_count, t_count, s_sentinel);
            } else {
                writeManyArrayNotation(print_array, s_child, s_count, s_sentinel);
            }
        } else {
            writeManyArrayNotation(print_array, s_child, s_count, s_sentinel);
            if (s_count != t_count) {
                print_array.writeMany(" -> ");
                writeManyArrayNotation(print_array, t_child, t_count, t_sentinel);
            }
        }
        print_array.writeMany(", ");
    }
    fn writeHolderArrayNotationA(
        print_array: *PrintArray,
        comptime s_child: type,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        writeHolderArrayNotation(print_array, s_child, s_count, s_sentinel);
        print_array.writeMany(", ");
    }
    fn writeHolderArrayNotationB(
        print_array: *PrintArray,
        comptime s_child: type,
        comptime t_child: type,
        s_aligned_bytes: u64,
        t_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes -% @sizeOf(t_child) *% @as(u64, @intFromBool(t_sentinel != null))) / @sizeOf(t_child);
        if (s_child == t_child and s_sentinel == t_sentinel) {
            if (s_count != t_count) {
                writeChangedHolderArrayNotation(print_array, s_child, s_count, t_count, s_sentinel);
            } else {
                writeHolderArrayNotation(print_array, s_child, s_count, s_sentinel);
            }
        } else {
            writeHolderArrayNotation(print_array, s_child, s_count, s_sentinel);
            if (s_count != t_count) {
                print_array.writeMany(" -> ");
                writeHolderArrayNotation(print_array, t_child, t_count, t_sentinel);
            }
        }
        print_array.writeMany(", ");
    }
    fn writeAboutOneAllocation(
        print_array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_uw_addr: u64,
        s_aligned_bytes: u64,
    ) void {
        writeAddressSpaceA(print_array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(print_array, s_aligned_bytes);
        writeOneType(print_array, s_child);
        print_array.overwriteManyBack("\n\n");
    }
    fn writeAboutManyAllocation(
        print_array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_uw_addr: u64,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        writeAddressSpaceA(print_array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(print_array, s_aligned_bytes);
        writeManyArrayNotationA(print_array, s_child, s_aligned_bytes, s_sentinel);
        print_array.overwriteManyBack("\n\n");
    }
    fn writeAboutHolderAllocation(
        print_array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_ua_addr: u64,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        writeAddressSpaceA(print_array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(print_array, s_aligned_bytes);
        writeHolderArrayNotationA(print_array, s_child, s_aligned_bytes, s_sentinel);
        print_array.writeMany("\n\n");
    }
    fn writeAboutUnstructuredAllocation(
        print_array: *PrintArray,
        s_ab_addr: u64,
        s_ua_addr: u64,
        s_aligned_bytes: u64,
    ) void {
        writeAddressSpaceA(print_array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(print_array, s_aligned_bytes);
        print_array.writeMany("\n\n");
    }
    fn mapNotice(addr: u64, len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(map_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn unmapNotice(addr: u64, len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(unmap_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn arenaAcquireNotice(index_opt: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(acq_s);
        print_array.writeMany(label orelse "arena");
        print_array.writeMany("-");
        if (index_opt) |index| {
            print_array.writeFormat(fmt.ud64(index));
        }
        print_array.writeMany(", ");
        writeAddressRangeBytes(&print_array, lb_addr, up_addr);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn arenaReleaseNotice(index_opt: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(rel_s);
        print_array.writeMany(label orelse "arena");
        print_array.writeMany("-");
        if (index_opt) |index| {
            print_array.writeFormat(fmt.ud64(index));
        }
        print_array.writeMany(", ");
        writeAddressRangeBytes(&print_array, lb_addr, up_addr);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(advice_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany(", ");
        print_array.writeMany(description_s);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn resizeNotice(old_addr: u64, old_len: u64, new_len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(remap_s);
        writeChangedAddressRangeBytes(&print_array, old_addr, old_addr +% old_len, old_addr, old_addr +% new_len);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn moveNotice(old_addr: u64, old_len: u64, new_addr: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(move_s);
        writeChangedAddressRangeBytes(&print_array, old_addr, old_addr +% old_len, new_addr, new_addr +% old_len);
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn mapError(map_error: anytype, addr: u64, len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(map_1_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(map_error));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(unmap_1_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(unmap_error));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn arenaAcquireError(arena_error: anytype, index: u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(acq_1_s);
        print_array.writeMany(label orelse "arena");
        print_array.writeMany("-");
        print_array.writeFormat(fmt.ud64(index));
        print_array.writeMany(", ");
        writeAddressRangeBytes(&print_array, lb_addr, up_addr);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(arena_error));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn arenaReleaseError(arena_error: anytype, index: u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(rel_1_s);
        print_array.writeMany(label orelse "arena");
        print_array.writeMany("-");
        print_array.writeFormat(fmt.ud64(index));
        print_array.writeMany(", ");
        writeAddressRangeBytes(&print_array, lb_addr, up_addr);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(arena_error));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn adviseError(madvise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(advice_1_s);
        writeAddressRangeBytes(&print_array, addr, addr +% len);
        print_array.writeMany(", ");
        print_array.writeMany(description_s);
        print_array.writeMany(", ");
        writeErrorName(&print_array, @errorName(madvise_error));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn resizeError(mremap_err: anytype, old_addr: u64, old_len: u64, new_len: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(remap_1_s);
        writeChangedAddressRangeBytes(&print_array, old_addr, old_addr +% old_len, old_addr, old_addr +% new_len);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(mremap_err));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn moveError(mremap_err: anytype, old_addr: u64, old_len: u64, new_addr: u64) void {
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeMany(move_1_s);
        writeChangedAddressRangeBytes(&print_array, old_addr, old_addr +% old_len, new_addr, new_addr +% old_len);
        print_array.writeMany(" ");
        writeErrorName(&print_array, @errorName(mremap_err));
        print_array.writeMany("\n");
        debug.write(print_array.readAll());
    }
    fn showAllocateOneStructured(comptime s_child: type, s_ab_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = @sizeOf(s_child);
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(allocated_s);
        writeAboutOneAllocation(&print_array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(print_array.readAll());
    }
    fn showAllocateManyStructured(
        comptime s_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(allocated_s);
        writeAboutManyAllocation(&print_array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes, s_sentinel);
        debug.write(print_array.readAll());
    }
    pub fn showAllocateHolderStructured(
        comptime s_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(allocated_s);
        writeAboutHolderAllocation(&print_array, s_child, s_ab_addr, s_ua_addr, s_aligned_bytes, s_sentinel);
        debug.write(print_array.readAll());
    }
    fn showReallocateManyStructured(
        comptime s_child: type,
        comptime t_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        t_ab_addr: u64,
        t_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        const t_uw_addr: u64 = t_ab_addr +% t_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        writeModifyOperation(&print_array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&print_array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&print_array, s_aligned_bytes, t_aligned_bytes);
        writeManyArrayNotationB(&print_array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showReallocateHolderStructured(
        comptime s_child: type,
        comptime t_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        t_ab_addr: u64,
        t_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        comptime t_sentinel: ?*const t_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        const t_uw_addr: u64 = t_ab_addr +% t_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        writeModifyOperation(&print_array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&print_array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&print_array, s_aligned_bytes, t_aligned_bytes);
        writeHolderArrayNotationB(&print_array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showDeallocateOneStructured(comptime s_child: type, s_ab_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = @sizeOf(s_child);
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(deallocated_s);
        writeAboutOneAllocation(&print_array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(print_array.readAll());
    }
    fn showDeallocateManyStructured(
        comptime s_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const uw_offset: u64 = @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null));
        const s_uw_addr: u64 = s_up_addr -% uw_offset;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(deallocated_s);
        writeAboutManyAllocation(&print_array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes, s_sentinel);
        debug.write(print_array.readAll());
    }
    fn showDeallocateHolderStructured(
        comptime s_child: type,
        s_ab_addr: u64,
        s_up_addr: u64,
        comptime s_sentinel: ?*const s_child,
        src: builtin.SourceLocation,
        ret_addr: u64,
    ) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(deallocated_s);
        writeAboutHolderAllocation(&print_array, s_child, s_ab_addr, s_ua_addr, s_aligned_bytes, s_sentinel);
        debug.write(print_array.readAll());
    }
    fn showAllocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(allocated_s);
        writeAboutUnstructuredAllocation(&print_array, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(print_array.readAll());
    }
    fn showReallocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        writeModifyOperation(&print_array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&print_array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&print_array, s_aligned_bytes, t_aligned_bytes);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showReallocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        writeModifyOperation(&print_array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&print_array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&print_array, s_aligned_bytes, t_aligned_bytes);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showAllocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(allocated_s);
        writeAddressSpaceA(&print_array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(&print_array, s_aligned_bytes);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showDeallocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(deallocated_s);
        writeAddressSpaceA(&print_array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&print_array, s_aligned_bytes);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showDeallocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        var print_array: PrintArray = undefined;
        print_array.undefineAll();
        print_array.writeFormat(src_fmt);
        print_array.writeMany(deallocated_s);
        writeAddressSpaceA(&print_array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&print_array, s_aligned_bytes);
        print_array.overwriteManyBack("\n\n");
        debug.write(print_array.readAll());
    }
    fn showFiloDeallocateViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (comptime @TypeOf(allocator.*).specification.logging.illegal) {
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            const s_ua_addr: u64 = allocator.unallocated_byte_address();
            const d_aligned_bytes: u64 = s_ua_addr -% s_up_addr;
            var print_array: PrintArray = undefined;
            print_array.undefineAll();
            print_array.writeFormat(src_fmt);
            print_array.writeMany(filo_error_s ++ "attempted deallocation ");
            print_array.writeFormat(fmt.bytes(d_aligned_bytes));
            print_array.writeMany(" below segment maximum\n\n");
            debug.write(print_array.readAll());
        }
        proc.exit(2);
    }
    fn showFiloResizeViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (comptime @TypeOf(allocator.*).specification.logging.illegal) {
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            const s_ua_addr: u64 = allocator.unallocated_byte_address();
            const d_aligned_bytes: u64 = s_ua_addr -% s_up_addr;
            var print_array: PrintArray = undefined;
            print_array.undefineAll();
            print_array.writeFormat(src_fmt);
            print_array.writeMany(filo_error_s ++ "attempted resize ");
            print_array.writeFormat(fmt.bytes(d_aligned_bytes));
            print_array.writeMany(" below segment maximum\n\n");
            debug.write(print_array.readAll());
        }
        proc.exit(2);
    }
};
fn GenericArenaAllocatorGraphics(comptime Allocator: type) type {
    const T = struct {
        const is_silent: bool = meta.leastBitCast(Allocator.specification.logging) == 0;
        pub fn show(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (is_silent) return;
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            var print_array: about.PrintArray = undefined;
            print_array.undefineAll();
            print_array.writeFormat(src_fmt);
            if (Allocator.specification.logging.head) {
                print_array.writeMany(about.next_s);
                print_array.writeFormat(fmt.ux64(allocator.unallocated_byte_address()));
                print_array.writeOne('\n');
            }
            if (Allocator.specification.logging.sentinel) {
                print_array.writeMany(about.finish_s);
                print_array.writeFormat(fmt.ux64(allocator.unmapped_byte_address()));
                print_array.writeOne('\n');
            }
            if (Allocator.specification.logging.metadata) {
                if (Allocator.specification.options.count_allocations) {
                    print_array.writeMany(about.count_s);
                    print_array.writeFormat(fmt.ud64(allocator.metadata.count));
                    print_array.writeOne('\n');
                }
                if (Allocator.specification.options.count_useful_bytes) {
                    print_array.writeMany(about.utility_s);
                    print_array.writeFormat(fmt.ud64(allocator.metadata.utility));
                    print_array.writeOne('/');
                    print_array.writeFormat(fmt.ud64(allocator.allocated_byte_count()));
                    print_array.writeOne('\n');
                }
                if (Allocator.specification.options.check_parametric) {
                    print_array.writeMany(about.holder_s);
                    print_array.writeFormat(fmt.ux64(allocator.metadata.holder));
                    print_array.writeOne('\n');
                }
            }
            if (Allocator.specification.logging.branches and
                Allocator.specification.options.count_branches)
            {
                Branches.Graphics.showWrite(allocator.metadata.branches, &print_array);
            }
            if (print_array.len() != src_fmt.formatLength()) {
                print_array.writeOne('\n');
                debug.write(print_array.readAll());
            }
        }
        pub fn showWithReference(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (is_silent) return;
            if (Allocator.specification.options.trace_state) {
                const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
                var print_array: about.PrintArray = undefined;
                print_array.undefineAll();
                print_array.writeFormat(src_fmt);
                if (Allocator.specification.logging.head and
                    allocator.reference.ub_addr != allocator.ub_addr)
                {
                    print_array.writeMany(about.next_s);
                    print_array.writeFormat(fmt.uxd(allocator.reference.ub_addr, allocator.ub_addr));
                    print_array.writeOne('\n');
                    allocator.reference.ub_addr = allocator.ub_addr;
                }
                if (Allocator.specification.logging.sentinel and
                    allocator.reference.up_addr != allocator.up_addr)
                {
                    print_array.writeMany(about.finish_s);
                    print_array.writeFormat(fmt.uxd(allocator.reference.up_addr, allocator.up_addr));
                    print_array.writeOne('\n');
                    allocator.reference.up_addr = allocator.up_addr;
                }
                if (Allocator.specification.logging.metadata) {
                    if (Allocator.specification.options.count_allocations and
                        allocator.reference.count != allocator.metadata.count)
                    {
                        print_array.writeMany(about.count_s);
                        print_array.writeFormat(fmt.udd(allocator.reference.count, allocator.metadata.count));
                        print_array.writeOne('\n');
                        allocator.reference.count = allocator.metadata.count;
                    }
                    if (Allocator.specification.options.count_useful_bytes and
                        allocator.reference.utility != allocator.metadata.utility)
                    {
                        print_array.writeMany(about.utility_s);
                        print_array.writeFormat(fmt.udd(allocator.reference.utility, allocator.metadata.utility));
                        print_array.writeOne('/');
                        print_array.writeFormat(fmt.ud(allocator.allocated_byte_count()));
                        print_array.writeOne('\n');
                        allocator.reference.utility = allocator.metadata.utility;
                    }
                    if (Allocator.specification.options.check_parametric and
                        allocator.reference.holder != allocator.metadata.holder)
                    {
                        print_array.writeMany(about.holder_s);
                        print_array.writeFormat(fmt.uxd(allocator.reference.holder, allocator.metadata.holder));
                        print_array.writeOne('\n');
                        allocator.reference.holder = allocator.metadata.holder;
                    }
                }
                if (Allocator.specification.logging.branches and
                    Allocator.specification.options.count_branches)
                {
                    Branches.Graphics.showWithReferenceWrite(allocator.metadata.branches, &allocator.reference.branches, &print_array);
                }
                if (print_array.len() != src_fmt.formatLength()) {
                    print_array.writeOne('\n');
                    debug.write(print_array.readAll());
                }
            } else {
                return show(allocator, src);
            }
        }
        fn showAllocateMany(comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.allocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showAllocateManyStructured, .{
                        impl_type.child,                 impl.aligned_byte_address(),
                        impl.unallocated_byte_address(), sentinel_ptr,
                        src,                             @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showAllocateManyUnstructured, .{
                        impl.aligned_byte_address(), impl.unallocated_byte_address(),
                        src,                         @returnAddress(),
                    });
                }
            }
        }
        fn showAllocateHolder(allocator: *const Allocator, comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.allocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showAllocateHolderStructured, .{
                        impl_type.child,                            impl.aligned_byte_address(allocator.*),
                        impl.unallocated_byte_address(allocator.*), sentinel_ptr,
                        src,                                        @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showAllocateHolderUnstructured, .{
                        impl.aligned_byte_address(allocator.*), impl.unallocated_byte_address(allocator.*),
                        src,                                    @returnAddress(),
                    });
                }
            }
        }
        fn showReallocateMany(comptime impl_type: type, s_impl: impl_type, t_impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.reallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showReallocateManyStructured, .{
                        impl_type.child,               impl_type.child,
                        s_impl.aligned_byte_address(), s_impl.unallocated_byte_address(),
                        t_impl.aligned_byte_address(), t_impl.unallocated_byte_address(),
                        sentinel_ptr,                  sentinel_ptr,
                        src,                           @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showReallocateManyUnstructured, .{
                        s_impl.aligned_byte_address(), s_impl.unallocated_byte_address(),
                        t_impl.aligned_byte_address(), t_impl.unallocated_byte_address(),
                        src,                           @returnAddress(),
                    });
                }
            }
        }
        fn showReallocateHolder(allocator: *const Allocator, comptime impl_type: type, s_impl: impl_type, t_impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.reallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showReallocateHolderStructured, .{
                        impl_type.child,                          impl_type.child,
                        s_impl.aligned_byte_address(allocator.*), s_impl.unallocated_byte_address(allocator.*),
                        t_impl.aligned_byte_address(allocator.*), t_impl.unallocated_byte_address(allocator.*),
                        sentinel_ptr,                             sentinel_ptr,
                        src,                                      @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showReallocateHolderUnstructured, .{
                        s_impl.aligned_byte_address(allocator.*), s_impl.unallocated_byte_address(allocator.*),
                        t_impl.aligned_byte_address(allocator.*), t_impl.unallocated_byte_address(allocator.*),
                        src,                                      @returnAddress(),
                    });
                }
            }
        }
        fn showDeallocateMany(comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.deallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showDeallocateManyStructured, .{
                        impl_type.child,                 impl.aligned_byte_address(),
                        impl.unallocated_byte_address(), sentinel_ptr,
                        src,                             @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showDeallocateManyUnstructured, .{
                        impl.aligned_byte_address(), impl.unallocated_byte_address(),
                        src,                         @returnAddress(),
                    });
                }
            }
        }
        fn showDeallocateHolder(allocator: *const Allocator, comptime impl_type: type, impl: impl_type, src: builtin.SourceLocation) void {
            if (Allocator.specification.logging.deallocate) {
                if (@hasDecl(impl_type, "child")) {
                    const sentinel_ptr: ?*const impl_type.child =
                        if (@hasDecl(impl_type, "sentinel")) impl_type.sentinel else null;
                    @call(.auto, about.showDeallocateHolderStructured, .{
                        impl_type.child,
                        impl.aligned_byte_address(allocator.*),
                        impl.unallocated_byte_address(allocator.*),
                        sentinel_ptr,
                        src,
                        @returnAddress(),
                    });
                } else {
                    @call(.auto, about.showDeallocateHolderUnstructured, .{
                        impl.aligned_byte_address(allocator.*),
                        impl.unallocated_byte_address(allocator.*),
                        src,
                        @returnAddress(),
                    });
                }
            }
        }
    };
    return T;
}
fn GenericLinkedAllocatorGraphics(comptime Allocator: type) type {
    const T = struct {
        const PrintArray = mem.array.StaticArray(u8, 8096);
        const tab = .{
            .segment_s = "|S",
            .allocation_s = "|A--\x1b[94;1m",
            .free_s = "|F--\x1b[91;1m",
            .hint_s = "|H--\x1b[92;1m",
            .unaddressable_s = "|U--",
            .div_s = "\x1b[0m--",
            .end_s = "|\n\n",
        };
        pub fn graphPartitions(allocator: Allocator) void {
            var print_array: PrintArray = undefined;
            print_array.undefineAll();
            if (allocator.lb_addr == 0) {
                const len: u64 = tab.unaddressable_s.len +% 3 +% tab.div_s.len +% tab.end_s.len;
                if (print_array.avail() < len) {
                    debug.write(print_array.readAll());
                    print_array.undefineAll();
                }
                print_array.writeMany(tab.unaddressable_s);
                print_array.writeFormat(fmt.bytes(~@as(u48, 0)));
                print_array.writeMany(tab.div_s);
                print_array.writeMany(tab.end_s);
            } else {
                var l_node_addr: u64 = allocator.lb_addr;
                while (true) {
                    const l_node_kind: u64 = Node4.kind(l_node_addr);
                    switch (l_node_kind) {
                        Node4.H => {
                            if (print_array.avail() < tab.segment_s.len) {
                                debug.write(print_array.readAll());
                                print_array.undefineAll();
                            }
                            print_array.writeMany(tab.segment_s);
                            l_node_addr +%= Node4.size;
                        },
                        Node4.F => {
                            const r_node_addr: u64 = Node4.link(l_node_addr);
                            const l_cell_addr: u64 = l_node_addr +% Node4.size;
                            const l_capacity: u64 = r_node_addr -% l_cell_addr;
                            if (allocator.ub_addr == l_node_addr) {
                                const len: u64 = tab.hint_s.len +% fmt.bytes(l_capacity).formatLength() +% tab.div_s.len;
                                if (print_array.avail() < len) {
                                    debug.write(print_array.readAll());
                                    print_array.undefineAll();
                                }
                                print_array.writeMany(tab.hint_s);
                                print_array.writeFormat(fmt.bytes(l_capacity));
                                print_array.writeMany(tab.div_s);
                            } else {
                                const len: u64 = tab.free_s.len +% fmt.bytes(l_capacity).formatLength() +% tab.div_s.len;
                                if (print_array.avail() < len) {
                                    debug.write(print_array.readAll());
                                    print_array.undefineAll();
                                }
                                print_array.writeMany(tab.free_s);
                                print_array.writeFormat(fmt.bytes(l_capacity));
                                print_array.writeMany(tab.div_s);
                            }
                            l_node_addr = r_node_addr;
                        },
                        Node4.A => {
                            const r_node_addr: u64 = Node4.link(l_node_addr);
                            const l_cell_addr: u64 = l_node_addr +% Node4.size;
                            const l_capacity: u64 = r_node_addr -% l_cell_addr;
                            const len: u64 = tab.allocation_s.len +% fmt.bytes(l_capacity).formatLength() +% tab.div_s.len;
                            if (print_array.avail() < len) {
                                debug.write(print_array.readAll());
                                print_array.undefineAll();
                            }
                            print_array.writeMany(tab.allocation_s);
                            print_array.writeFormat(fmt.bytes(l_capacity));
                            print_array.writeMany(tab.div_s);
                            l_node_addr = r_node_addr;
                        },
                        Node4.U => {
                            const r_node_addr: u64 = Node4.link(l_node_addr);
                            const l_cell_addr: u64 = l_node_addr +% Node4.size;
                            if (r_node_addr < l_cell_addr) {
                                if (print_array.avail() < tab.end_s.len) {
                                    debug.write(print_array.readAll());
                                    print_array.undefineAll();
                                }
                                print_array.writeMany(tab.end_s);
                                break;
                            }
                            const l_capacity: u64 = r_node_addr -% l_cell_addr;
                            const len: u64 = tab.unaddressable_s.len +% fmt.bytes(l_capacity).formatLength() +% tab.div_s.len;
                            if (print_array.avail() < len) {
                                debug.write(print_array.readAll());
                                print_array.undefineAll();
                            }
                            print_array.writeMany(tab.unaddressable_s);
                            print_array.writeFormat(fmt.bytes(l_capacity));
                            print_array.writeMany(tab.div_s);
                            l_node_addr = r_node_addr;
                        },
                        else => unreachable,
                    }
                }
            }
            debug.write(print_array.readAll());
        }
    };
    return T;
}
noinline fn showCreate(comptime child: type, ptr: *child) void {
    about.showAllocateOneStructured(
        child,
        @intFromPtr(ptr),
        @src(),
        @returnAddress(),
    );
}
noinline fn showAllocate(comptime child: type, buf: []child, comptime sentinel: ?*const child) void {
    about.showAllocateManyStructured(
        child,
        @intFromPtr(buf.ptr),
        @intFromPtr(buf.ptr) +% @sizeOf(child) *% (buf.len +% @intFromBool(sentinel != null)),
        sentinel,
        @src(),
        @returnAddress(),
    );
}
noinline fn showReallocate(comptime child: type, s_buf: []child, t_buf: []child, comptime sentinel: ?*const child) void {
    about.showReallocateManyStructured(
        child,
        child,
        @intFromPtr(s_buf.ptr),
        @intFromPtr(s_buf.ptr) +% @sizeOf(child) *% (s_buf.len +% @intFromBool(sentinel != null)),
        @intFromPtr(t_buf.ptr),
        @intFromPtr(t_buf.ptr) +% @sizeOf(child) *% (t_buf.len +% @intFromBool(sentinel != null)),
        sentinel,
        sentinel,
        @src(),
        @returnAddress(),
    );
}
noinline fn showDeallocate(comptime child: type, buf: []child, comptime sentinel: ?*const child) void {
    about.showDeallocateManyStructured(
        child,
        @intFromPtr(buf.ptr),
        @intFromPtr(buf.ptr) +% @sizeOf(child) *% (buf.len +% @intFromBool(sentinel != null)),
        sentinel,
        @src(),
        @returnAddress(),
    );
}
pub const spec = struct {
    pub const options = struct {
        pub const small: ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
        };
        // TODO: Describe conditions where this is better.
        pub const fast: ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
        };
        pub const debug: ArenaAllocatorOptions = .{
            .count_branches = true,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = true,
            .trace_state = true,
            .trace_clients = true,
        };
        pub const small_composed: ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric = false,
            .prefer_remap = false,
            .require_map = false,
            .require_unmap = false,
        };
        pub const fast_composed: ArenaAllocatorOptions = .{
            .count_branches = false,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = false,
            .require_geometric_growth = true,
            .require_map = false,
            .require_unmap = false,
        };
        pub const debug_composed: ArenaAllocatorOptions = .{
            .count_branches = true,
            .count_allocations = true,
            .count_useful_bytes = true,
            .check_parametric = true,
            .trace_state = true,
            .trace_clients = true,
            .require_map = false,
            .require_unmap = false,
        };
    };
    pub const logging = struct {
        pub const verbose: AllocatorLogging = .{
            .head = true,
            .sentinel = true,
            .metadata = true,
            .branches = true,
            .illegal = true,
            .map = debug.spec.logging.acquire_error.verbose,
            .unmap = debug.spec.logging.release_error.verbose,
            .remap = debug.spec.logging.success_error.verbose,
            .advise = debug.spec.logging.success_error.verbose,
            .allocate = true,
            .reallocate = true,
            .reinterpret = true,
            .deallocate = true,
        };
        pub const silent: AllocatorLogging = .{
            .head = false,
            .sentinel = false,
            .metadata = false,
            .branches = false,
            .illegal = false,
            .map = debug.spec.logging.acquire_error.silent,
            .unmap = debug.spec.logging.release_error.silent,
            .remap = debug.spec.logging.success_error.silent,
            .advise = debug.spec.logging.success_error.silent,
            .allocate = false,
            .reallocate = false,
            .reinterpret = false,
            .deallocate = false,
        };
    };
    pub const errors = struct {
        pub const zen: AllocatorErrors = .{
            .map = .{ .throw = mem.spec.mmap.errors.mem },
            .remap = .{ .throw = mem.spec.mremap.errors.all },
            .unmap = .{ .abort = mem.spec.munmap.errors.all },
        };
        pub const noexcept: AllocatorErrors = .{
            .map = .{},
            .remap = .{},
            .unmap = .{},
        };
        pub const critical: AllocatorErrors = .{
            .map = .{ .throw = mem.spec.mmap.errors.mem },
            .remap = .{ .throw = mem.spec.mremap.errors.all },
            .unmap = .{ .throw = mem.spec.munmap.errors.all },
        };
    };
};
pub const Node4 = opaque {
    pub const U = 0;
    pub const H = 3 << 48;
    pub const A = 2 << 48;
    pub const F = 1 << 48;
    pub const size: u64 = 8;
    pub const kind_mask: u64 = 0b11111111_11111111_000000000000000000000000000000000000000000000000;
    pub const link_mask: u64 = 0b00000000_00000000_111111111111111111111111111111111111111111111111;
    pub fn refer(node_addr: u64) *u64 {
        return builtin.ptrFromInt(*u64, node_addr);
    }
    pub fn write(node_addr: u64, word: u64) void {
        refer(node_addr).* = word;
    }
    pub fn toggle(node_addr: u64) void {
        refer(node_addr).* ^= Node4.H;
    }
    pub fn clear(node_addr: u64) void {
        refer(node_addr).* = 0;
    }
    pub fn kind(node_addr: u64) u64 {
        return refer(node_addr).* & Node4.kind_mask;
    }
    pub fn link(node_addr: u64) u64 {
        return refer(node_addr).* & Node4.link_mask;
    }
    pub fn read(node_addr: u64) u64 {
        return refer(node_addr).*;
    }
    pub fn move(s_node_addr: u64, t_node_addr: u64) void {
        refer(s_node_addr).* = read(t_node_addr);
        clear(t_node_addr);
    }
    pub fn create(t_s_node_addr: u64, t_u_node_addr: u64, t_f_node_addr: u64) void {
        @setRuntimeSafety(false);
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | t_s_node_addr;
    }
    pub fn allocate(t_next_addr: u64, s_next_next_addr: u64, s_next_addr: u64, r_node_addr: u64) void {
        @setRuntimeSafety(false);
        @as(*u64, @ptrFromInt(t_next_addr)).* = Node4.F | s_next_next_addr;
        if (s_next_addr == r_node_addr) {
            @as(*u64, @ptrFromInt(s_next_addr)).* = Node4.A | t_next_addr;
        } else {
            @as(*u64, @ptrFromInt(s_next_addr)).* = Node4.F | r_node_addr;
            @as(*u64, @ptrFromInt(r_node_addr)).* = Node4.A | t_next_addr;
        }
    }
    pub fn reallocate(l_node_addr: u64, t_node_addr: u64, t_next_addr: u64, r_next_addr: u64) void {
        @setRuntimeSafety(false);
        if (l_node_addr == t_node_addr) {
            @as(*u64, @ptrFromInt(l_node_addr)).* = Node4.A | t_next_addr;
        } else {
            @as(*u64, @ptrFromInt(l_node_addr)).* = Node4.F | t_node_addr;
            @as(*u64, @ptrFromInt(t_node_addr)).* = Node4.A | t_next_addr;
        }
        @as(*u64, @ptrFromInt(t_next_addr)).* = Node4.F | r_next_addr;
    }
    pub fn appendFlush(r_end: u64, t_end: u64) u64 {
        @setRuntimeSafety(false);
        const l_u_node_addr: u64 = r_end -% Node4.size;
        const t_u_node_addr: u64 = t_end -% Node4.size;
        const l_s_node_addr: u64 = @as(*u64, @ptrFromInt(l_u_node_addr)).* & Node4.link_mask;
        const t_f_node_addr: u64 = l_u_node_addr;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | l_s_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | t_u_node_addr;
        @as(*u64, @ptrFromInt(l_s_node_addr)).* = Node4.H | t_u_node_addr;
        return t_f_node_addr;
    }
    pub fn appendBridged(r_end: u64, t_s_node_addr: u64, t_end: u64) u64 {
        @setRuntimeSafety(false);
        const l_u_node_addr: u64 = r_end -% Node4.size;
        const t_u_node_addr: u64 = t_end -% Node4.size;
        const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | t_s_node_addr;
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(l_u_node_addr)).* = Node4.U | t_s_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | t_u_node_addr;
        return t_f_node_addr;
    }
    pub fn prependBridged(t_s_node_addr: u64, t_end: u64, r_s_node_addr: u64) u64 {
        @setRuntimeSafety(false);
        const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
        const t_u_node_addr: u64 = t_end -% Node4.size;
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | r_s_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | t_u_node_addr;
        return t_f_node_addr;
    }
    pub fn insertFlushBridged(l_s_node_addr: u64, l_u_node_addr: u64, t_end: u64, r_s_node_addr: u64) u64 {
        @setRuntimeSafety(false);
        const t_u_node_addr: u64 = t_end -% Node4.size;
        @as(*u64, @ptrFromInt(l_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(l_u_node_addr)).* = Node4.F | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | r_s_node_addr;
        return l_u_node_addr;
    }
    pub fn insertBridgedBridged(l_u_node_addr: u64, t_s_node_addr: u64, t_end: u64, r_s_node_addr: u64) u64 {
        @setRuntimeSafety(false);
        const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
        const t_u_node_addr: u64 = t_end -% Node4.size;
        @as(*u64, @ptrFromInt(l_u_node_addr)).* = Node4.U | t_s_node_addr;
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | r_s_node_addr;
        return t_f_node_addr;
    }
    pub fn flushConsolidate(r_node_addr: u64) u64 {
        return if (Node4.kind(r_node_addr) == Node4.F) Node4.link(r_node_addr) else r_node_addr;
    }
    pub fn prependFlush(t_s_node_addr: u64, r_s_node_addr: u64, r_end: u64) u64 {
        @setRuntimeSafety(false);
        const r_u_node_addr: u64 = r_end -% Node4.size;
        const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
        const t_u_node_addr: u64 = @as(*u64, @ptrFromInt(r_s_node_addr)).* & Node4.link_mask;
        const r_f_node_addr: u64 = flushConsolidate(r_s_node_addr +% Node4.size);
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | r_f_node_addr;
        @as(*u64, @ptrFromInt(r_s_node_addr)).* = 0;
        if (t_u_node_addr == r_u_node_addr)
            @as(*u64, @ptrFromInt(t_u_node_addr)).* = Node4.U | t_s_node_addr;
        return t_f_node_addr;
    }
    pub fn insertBridgedFlush(l_u_node_addr: u64, t_s_node_addr: u64, r_s_node_addr: u64, r_end: u64) u64 {
        @setRuntimeSafety(false);
        const t_f_node_addr: u64 = t_s_node_addr +% Node4.size;
        const t_u_node_addr: u64 = @as(*u64, @ptrFromInt(r_s_node_addr)).* & Node4.link_mask;
        const r_u_node_addr: u64 = r_end -% Node4.size;
        const r_node_addr: u64 = r_s_node_addr +% Node4.size;
        const r_f_node_addr: u64 = flushConsolidate(r_node_addr);
        @as(*u64, @ptrFromInt(l_u_node_addr)).* = Node4.U | t_s_node_addr;
        @as(*u64, @ptrFromInt(t_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(t_f_node_addr)).* = Node4.F | r_f_node_addr;
        @as(*u64, @ptrFromInt(r_s_node_addr)).* = 0;
        if (t_u_node_addr == r_u_node_addr)
            @as(*u64, @ptrFromInt(r_u_node_addr)).* = Node4.U | t_s_node_addr;
        return t_f_node_addr;
    }
    pub fn insertFlushFlush(l_s_node_addr: u64, l_u_node_addr: u64, r_s_node_addr: u64, r_end: u64) u64 {
        @setRuntimeSafety(false);
        const r_u_node_addr: u64 = r_end -% Node4.size;
        const t_u_node_addr: u64 = @as(*u64, @ptrFromInt(r_s_node_addr)).* & Node4.link_mask;
        const r_f_node_addr: u64 = flushConsolidate(r_s_node_addr +% Node4.size);
        @as(*u64, @ptrFromInt(l_u_node_addr)).* = Node4.F | r_f_node_addr;
        @as(*u64, @ptrFromInt(l_s_node_addr)).* = Node4.H | t_u_node_addr;
        @as(*u64, @ptrFromInt(r_s_node_addr)).* = 0;
        if (t_u_node_addr == r_u_node_addr)
            @as(*u64, @ptrFromInt(r_u_node_addr)).* = Node4.U | l_s_node_addr;
        return l_u_node_addr;
    }
};
