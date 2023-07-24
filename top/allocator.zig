const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const list = @import("./list.zig");
const meta = @import("./meta.zig");
const algo = @import("./algo.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const container = @import("./container.zig");
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
const _1: mem.Amount = .{ .count = 1 };
const default_address_space_type = builtin.configExtra(
    "AddressSpace",
    type,
    builtin.info.address_space.defaultValue,
    .{ArenaAllocatorSpec},
);
pub const AllocatorErrors = struct {
    map: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    remap: sys.ErrorPolicy = .{ .throw = sys.mremap_errors },
    unmap: sys.ErrorPolicy = .{ .abort = sys.munmap_errors },
    madvise: sys.ErrorPolicy = .{ .throw = sys.madvise_errors },
};
pub const ArenaAllocatorSpec = struct {
    AddressSpace: type,
    arena_index: comptime_int = undefined,
    options: ArenaAllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    fn arena(comptime spec: ArenaAllocatorSpec) mem.Arena {
        if (@TypeOf(spec.AddressSpace.addr_spec) == mem.DiscreteAddressSpaceSpec or
            @TypeOf(spec.AddressSpace.addr_spec) == mem.RegularAddressSpaceSpec)
        {
            return spec.AddressSpace.arena(spec.arena_index);
        }
        if (@TypeOf(spec.AddressSpace.addr_spec) == mem.ElementaryAddressSpaceSpec) {
            return spec.AddressSpace.arena();
        }
        @compileError("invalid address space for this allocator");
    }
    // If true, the allocator is responsible for reserving memory and the
    // address space is not.
    fn isMapper(comptime spec: ArenaAllocatorSpec) bool {
        const allocator_is_mapper: bool = spec.options.require_map;
        const address_space_is_mapper: bool = blk: {
            if (@TypeOf(spec.AddressSpace.addr_spec) == mem.RegularAddressSpaceSpec or
                @TypeOf(spec.AddressSpace.addr_spec) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk spec.AddressSpace.addr_spec.options.require_map;
            }
            if (@TypeOf(spec.AddressSpace.addr_spec) == mem.DiscreteAddressSpaceSpec) {
                break :blk spec.AddressSpace.addr_spec.options(spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_mapper and address_space_is_mapper) {
            @compileError("both allocator and address space are mappers");
        }
        return spec.options.require_map;
    }
    // If true, the allocator is responsible for unreserving memory and the
    // address space is not.
    fn isUnmapper(comptime spec: ArenaAllocatorSpec) bool {
        const allocator_is_unmapper: bool = spec.options.require_unmap;
        const address_space_is_unmapper: bool = blk: {
            if (@TypeOf(spec.AddressSpace.addr_spec) == mem.RegularAddressSpaceSpec or
                @TypeOf(spec.AddressSpace.addr_spec) == mem.ElementaryAddressSpaceSpec)
            {
                break :blk spec.AddressSpace.addr_spec.options.require_map;
            }
            if (@TypeOf(spec.AddressSpace.addr_spec) == mem.DiscreteAddressSpaceSpec) {
                break :blk spec.AddressSpace.addr_spec.options(spec.arena_index).require_map;
            }
            @compileError("invalid address space for this allocator");
        };
        if (allocator_is_unmapper and address_space_is_unmapper) {
            @compileError("both allocator and address space are unmappers");
        }
        return spec.options.require_unmap;
    }
};
pub const RtArenaAllocatorSpec = struct {
    AddressSpace: type,
    options: ArenaAllocatorOptions = .{},
    errors: AllocatorErrors = .{},
    logging: AllocatorLogging = .{},
    // If true, the allocator is responsible for reserving memory and the
    // address space is not.
    fn isMapper(comptime spec: RtArenaAllocatorSpec) bool {
        const allocator_is_mapper: bool = spec.options.require_map;
        const address_space_is_mapper: bool = spec.AddressSpace.addr_spec.options.require_map;
        if (allocator_is_mapper and address_space_is_mapper) {
            @compileError("both allocator and address space are mappers");
        }
        return spec.options.require_map;
    }
    // If true, the allocator is responsible for unreserving memory and the
    // address space is not.
    fn isUnmapper(comptime spec: RtArenaAllocatorSpec) bool {
        const allocator_is_unmapper: bool = spec.options.require_unmap;
        const address_space_is_unmapper: bool = spec.AddressSpace.addr_spec.options.require_unmap;
        if (allocator_is_unmapper and address_space_is_unmapper) {
            @compileError("both allocator and address space are unmappers");
        }
        return spec.options.require_unmap;
    }
};
fn GenericAllocatorInterface(comptime Allocator: type) type {
    const Graphics = GenericArenaAllocatorGraphics(Allocator);
    return (struct {
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
            return mach.sub64(unallocated_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unallocated_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), unallocated_byte_address(allocator));
        }
        pub inline fn mapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unmapped_byte_address(allocator), mapped_byte_address(allocator));
        }
        pub inline fn unmapped_byte_count(allocator: *const Allocator) u64 {
            return mach.sub64(unaddressable_byte_address(allocator), unmapped_byte_address(allocator));
        }
        pub inline fn alignAbove(allocator: *Allocator, alignment: u64) u64 {
            allocator.ub_addr = mach.alignA64(allocator.ub_addr, alignment);
            return allocator.ub_addr;
        }
        pub fn increment(allocator: *Allocator, s_up_addr: u64) void {
            allocator.ub_addr = s_up_addr;
        }
        pub fn decrement(allocator: *Allocator, s_lb_addr: u64) void {
            if (Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = s_lb_addr;
            } else {
                allocator.ub_addr = mach.cmov64(reusable(allocator), allocator.lb_addr, s_lb_addr);
            }
        }
        pub fn reset(allocator: *Allocator) void {
            if (!Allocator.allocator_spec.options.require_filo_free) {
                allocator.ub_addr = mach.cmov64(reusable(allocator), allocator.lb_addr, allocator.ub_addr);
            }
        }
        pub fn map(allocator: *Allocator, s_bytes: u64) Allocator.allocate_void {
            debug.assertEqual(u64, s_bytes & 4095, 0);
            if (Allocator.allocator_spec.options.prefer_remap) {
                if (Allocator.allocator_spec.options.require_geometric_growth) {
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
                if (Allocator.allocator_spec.options.require_geometric_growth) {
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
            if (Allocator.allocator_spec.options.prefer_remap) {
                const s_bytes: u64 = Allocator.allocator_spec.options.init_commit orelse 4096;
                try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), s_bytes));
                allocator.up_addr +%= s_bytes;
            } else if (Allocator.allocator_spec.options.init_commit) |s_bytes| {
                try meta.wrap(mem.map(Allocator.map_spec, .{}, .{}, unmapped_byte_address(allocator), s_bytes));
                allocator.up_addr +%= s_bytes;
            }
        }
        fn unmapAll(allocator: *Allocator) Allocator.deallocate_void {
            const x_bytes: u64 = allocator.mapped_byte_count();
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                debug.assertBelowOrEqual(u64, allocator.metadata.utility, 0);
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                debug.assertBelowOrEqual(u64, allocator.metadata.count, 0);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn unmapAbove(allocator: *Allocator, s_up_addr: u64) Allocator.deallocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const t_bytes: u64 = mach.sub64(t_ua_addr, mapped_byte_address(allocator));
            const x_bytes: u64 = mach.sub64(mapped_byte_count(allocator), t_bytes);
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                debug.assertBelowOrEqual(u64, allocator.metadata.utility, t_bytes);
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                debug.assertBelowOrEqual(u64, allocator.metadata.count, t_bytes);
            }
            return allocator.unmap(x_bytes);
        }
        pub fn mapBelow(allocator: *Allocator, s_up_addr: u64) Allocator.allocate_void {
            const t_ua_addr: u64 = mach.alignA64(s_up_addr, 4096);
            const x_bytes: u64 = mach.sub64(t_ua_addr, allocator.unmapped_byte_address());
            const t_bytes: u64 = mach.add64(allocator.mapped_byte_count(), x_bytes);
            if (Allocator.allocator_spec.options.max_acquire) |max| {
                debug.assertBelowOrEqual(u64, x_bytes, max);
            }
            if (Allocator.allocator_spec.options.max_commit) |max| {
                debug.assertBelowOrEqual(u64, t_bytes, max);
            }
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.map(x_bytes);
            }
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
    });
}
fn Types(comptime Allocator: type) type {
    return struct {
        /// This policy is applied to `init` return types.
        pub const map_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.allocator_spec.isMapper()) {
                break :blk Allocator.allocator_spec.errors.map;
            } else {
                break :blk Allocator.AddressSpace.addr_spec.errors.map;
            }
        };
        /// This policy is applied to `deinit` return types.
        pub const unmap_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.allocator_spec.isMapper()) {
                break :blk Allocator.allocator_spec.errors.unmap;
            } else {
                break :blk Allocator.AddressSpace.addr_spec.errors.unmap;
            }
            break :blk .{};
        };
        /// This policy is applied to any operation which may result in an
        /// increase to the amount of memory reserved by the allocator.
        pub const resize_error_policy: sys.ErrorPolicy = blk: {
            if (Allocator.allocator_spec.isMapper()) {
                if (Allocator.allocator_spec.options.prefer_remap) {
                    break :blk Allocator.allocator_spec.errors.remap;
                } else {
                    break :blk Allocator.allocator_spec.errors.map;
                }
            }
            break :blk .{};
        };
        pub const acquire_allocator: type = blk: {
            if (map_error_policy.throw.len != 0) {
                const MMapError = sys.Error(map_error_policy.throw);
                if (Allocator.AddressSpace.addr_spec.errors.acquire == .throw) {
                    break :blk (MMapError || mem.ResourceError)!Allocator;
                }
                break :blk MMapError!Allocator;
            }
            if (Allocator.AddressSpace.addr_spec.errors.acquire == .throw) {
                break :blk mem.ResourceError!Allocator;
            }
            break :blk Allocator;
        };
        pub const release_allocator: type = blk: {
            if (unmap_error_policy.throw.len != 0) {
                const MUnmapError = sys.Error(unmap_error_policy.throw);
                if (Allocator.AddressSpace.addr_spec.errors.release == .throw) {
                    break :blk (MUnmapError || mem.ResourceError)!void;
                }
                break :blk MUnmapError!void;
            }
            if (Allocator.AddressSpace.addr_spec.errors.release == .throw) {
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
            .errors = Allocator.allocator_spec.errors.map,
            .logging = Allocator.allocator_spec.logging.map,
        };
        const remap_spec: mem.RemapSpec = .{
            .errors = Allocator.allocator_spec.errors.remap,
            .logging = Allocator.allocator_spec.logging.remap,
        };
        const unmap_spec: mem.UnmapSpec = .{
            .errors = Allocator.allocator_spec.errors.unmap,
            .logging = Allocator.allocator_spec.logging.unmap,
        };
    };
}
inline fn ArenaAllocatorMetadata(comptime spec: anytype) type {
    return (struct {
        branches: meta.maybe(spec.options.count_branches, Branches) = .{},
        holder: meta.maybe(spec.options.check_parametric, u64) = 0,
        count: meta.maybe(spec.options.count_allocations, u64) = 0,
        utility: meta.maybe(spec.options.count_useful_bytes, u64) = 0,
    });
}
inline fn ArenaAllocatorReference(comptime spec: anytype) type {
    return (struct {
        branches: meta.maybe(spec.options.trace_state, Branches) = .{},
        ub_addr: meta.maybe(spec.options.trace_state, u64) = 0,
        up_addr: meta.maybe(spec.options.trace_state, u64) = 0,
        holder: meta.maybe(spec.options.check_parametric, u64) = 0,
        count: meta.maybe(spec.options.count_allocations, u64) = 0,
        utility: meta.maybe(spec.options.count_useful_bytes, u64) = 0,
    });
}
pub fn GenericArenaAllocator(comptime spec: ArenaAllocatorSpec) type {
    return (struct {
        comptime lb_addr: u64 = lb_addr,
        ub_addr: u64,
        up_addr: u64,
        comptime ua_addr: u64 = ua_addr,
        metadata: ArenaAllocatorMetadata(spec) = .{},
        reference: ArenaAllocatorReference(spec) = .{},
        const Allocator = @This();
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const allocator_spec: ArenaAllocatorSpec = spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
        pub const arena_index: u64 = allocator_spec.arena_index;
        const arena: mem.Arena = spec.arena();
        const lb_addr: u64 = arena.lb_addr;
        const ua_addr: u64 = arena.up_addr;
        pub fn init(address_space: *AddressSpace) Allocator.acquire_allocator {
            var allocator: Allocator = undefined;
            defer Graphics.showWithReference(&allocator, @src());
            allocator = .{
                .ub_addr = lb_addr,
                .up_addr = lb_addr,
            };
            switch (@TypeOf(AddressSpace.addr_spec)) {
                mem.RegularAddressSpaceSpec => {
                    try meta.wrap(mem.acquire(AddressSpace, address_space, spec.arena_index));
                },
                mem.DiscreteAddressSpaceSpec => {
                    try meta.wrap(mem.acquireStatic(AddressSpace, address_space, spec.arena_index));
                },
                mem.ElementaryAddressSpaceSpec => {
                    try meta.wrap(mem.acquireElementary(AddressSpace, address_space));
                },
                else => @compileError("invalid address space for this allocator"),
            }
            if (Allocator.allocator_spec.options.require_map) {
                try meta.wrap(Allocator.mapInit(&allocator));
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.require_unmap) {
                try meta.wrap(allocator.unmapAll());
            }
            switch (@TypeOf(AddressSpace.addr_spec)) {
                mem.RegularAddressSpaceSpec => {
                    try meta.wrap(mem.release(AddressSpace, address_space, spec.arena_index));
                },
                mem.DiscreteAddressSpaceSpec => {
                    try meta.wrap(mem.releaseStatic(AddressSpace, address_space, spec.arena_index));
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
    });
}
pub fn GenericRtArenaAllocator(comptime spec: RtArenaAllocatorSpec) type {
    return (struct {
        lb_addr: u64,
        ub_addr: u64,
        up_addr: u64,
        ua_addr: u64,
        metadata: ArenaAllocatorMetadata(spec) = .{},
        reference: ArenaAllocatorReference(spec) = .{},
        const Allocator = @This();
        const Value = fn (*const Allocator) callconv(.Inline) u64;
        pub const AddressSpace = allocator_spec.AddressSpace;
        pub const allocator_spec: RtArenaAllocatorSpec = spec;
        pub const unit_alignment: u64 = allocator_spec.options.unit_alignment;
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
            if (Allocator.allocator_spec.options.require_map) {
                try meta.wrap(Allocator.mapInit(&allocator));
            }
            return allocator;
        }
        pub fn deinit(allocator: *Allocator, address_space: *AddressSpace, arena_index: AddressSpace.Index) Allocator.release_allocator {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.require_unmap) {
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
fn GenericIrreversibleInterface(comptime Allocator: type) type {
    return struct {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        pub const Save = struct { u64 };
        pub inline fn create(allocator: *Allocator, comptime s_child: type) Allocator.allocate_payload(*s_child) {
            @setRuntimeSafety(false);
            defer Graphics.showWithReference(allocator, @src());
            const s_ab_addr: u64 = try meta.wrap(
                allocator.allocateInternal(@sizeOf(s_child), @alignOf(s_child)),
            );
            const ret: *s_child = @ptrFromInt(s_ab_addr);
            showCreate(s_child, ret);
            return ret;
        }
        pub inline fn allocate(allocator: *Allocator, comptime s_child: type, count: u64) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer Graphics.showWithReference(allocator, @src());
            const s_ab_addr: u64 = try meta.wrap(
                allocator.allocateInternal(@sizeOf(s_child) *% count, @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            showAllocate(s_child, ret, null);
            return ret;
        }
        pub inline fn reallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child, count: u64) Allocator.allocate_payload([]s_child) {
            @setRuntimeSafety(false);
            defer Graphics.showWithReference(allocator, @src());
            const s_ab_addr: u64 = try meta.wrap(
                allocator.reallocateInternal(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child), count *% @sizeOf(s_child), @alignOf(s_child)),
            );
            const ptr: [*]s_child = @ptrFromInt(s_ab_addr);
            const ret: []s_child = ptr[0..count];
            showReallocate(s_child, buf, ret, null);
            return ret;
        }
        pub inline fn createAligned(allocator: *Allocator, comptime s_child: type, comptime s_alignment: u64) *align(s_alignment) s_child {
            @setRuntimeSafety(false);
            defer Graphics.showWithReference(allocator, @src());
            const s_ab_addr: u64 = allocator.allocateInternal(@sizeOf(s_child), s_alignment);
            const ptr: *align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            showCreate(s_child, ptr);
            return ptr;
        }
        pub inline fn allocateAligned(allocator: *Allocator, comptime s_child: type, count: u64, comptime s_alignment: u64) []align(s_alignment) s_child {
            @setRuntimeSafety(false);
            defer Graphics.showWithReference(allocator, @src());
            const s_ab_addr: u64 = allocator.allocateInternal(@sizeOf(s_child) *% count, s_alignment);
            const ptr: [*]align(s_alignment) s_child = @ptrFromInt(s_ab_addr);
            const ret: []align(s_alignment) s_child = ptr[0..count];
            showAllocate(s_child, ret, null);
            return ret;
        }
        pub inline fn deallocate(allocator: *Allocator, comptime s_child: type, buf: []s_child) void {
            allocator.deallocateInternal(@intFromPtr(buf.ptr), buf.len *% @sizeOf(s_child));
        }
        pub inline fn save(allocator: *const Allocator) Save {
            return .{allocator.unallocated_byte_address()};
        }
        pub inline fn restore(allocator: *Allocator, state: Save) void {
            defer Graphics.showWithReference(allocator, @src());
            allocator.ub_addr = state[0];
        }
        inline fn alignAbove(value: u64, alignment: u64) u64 {
            const mask: u64 = alignment -% 1;
            return (value +% mask) & ~mask;
        }
        inline fn copy(dest: u64, src: u64, len: u64) void {
            mach.memcpy(@as([*]u8, @ptrFromInt(dest)), @as([*]const u8, @ptrFromInt(src)), len);
        }
        pub const allocateRaw = allocateInternal;
        pub const reallocateRaw = reallocateInternal;
        pub const deallocateRaw = deallocateInternal;
        fn allocateInternal(
            allocator: *Allocator,
            s_aligned_bytes: u64,
            s_alignment: u64,
        ) Allocator.allocate_payload(u64) {
            const s_ab_addr: u64 = alignAbove(allocator.unallocated_byte_address(), s_alignment);
            const s_up_addr: u64 = s_ab_addr +% s_aligned_bytes;
            if (Allocator.allocator_spec.options.require_map and s_up_addr > allocator.unmapped_byte_address()) {
                try meta.wrap(allocator.mapBelow(s_up_addr));
            }
            allocator.ub_addr = s_up_addr;
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count +%= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility +%= s_aligned_bytes;
            }
            return s_ab_addr;
        }
        fn reallocateInternal(
            allocator: *Allocator,
            s_ab_addr: u64,
            s_aligned_bytes: u64,
            t_aligned_bytes: u64,
            align_of: u64,
        ) Allocator.allocate_payload(u64) {
            const s_up_addr: u64 = s_ab_addr +% s_aligned_bytes;
            const t_up_addr: u64 = s_ab_addr +% t_aligned_bytes;
            if (allocator.unallocated_byte_address() == s_up_addr) {
                if (t_up_addr > allocator.unmapped_byte_address()) {
                    try meta.wrap(allocator.mapBelow(t_up_addr));
                }
                allocator.increment(t_up_addr);
                return s_ab_addr;
            }
            const t_ab_addr: u64 = try meta.wrap(allocator.allocateInternal(t_aligned_bytes, align_of));
            copy(t_ab_addr, s_ab_addr, s_aligned_bytes);
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count +%= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility +%= t_aligned_bytes -% s_aligned_bytes;
            }
            return t_ab_addr;
        }
        fn deallocateInternal(
            allocator: *Allocator,
            s_aligned: u64,
            s_aligned_bytes: u64,
        ) void {
            const s_next: u64 = s_aligned +% s_aligned_bytes;
            if (allocator.unallocated_byte_address() == s_next) {
                allocator.ub_addr = s_next;
            }
            if (Allocator.allocator_spec.options.count_allocations) {
                allocator.metadata.count -%= 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.count -%= s_aligned_bytes;
            }
        }
        pub fn addGeneric(allocator: *Allocator, size: u64, init_len: u64, ptr: *u64, max_len: *u64, len: u64) u64 {
            const new_max_len: u64 = len +% 2;
            if (max_len.* == 0) {
                ptr.* = allocateInternal(allocator, size *% init_len, 8);
                max_len.* = init_len;
            } else if (len == max_len.*) {
                ptr.* = reallocateInternal(allocator, ptr.*, size *% max_len.*, size *% new_max_len, 8);
                max_len.* = new_max_len;
            }
            return ptr.* +% (size *% len);
        }
        pub inline fn duplicate(allocator: *Allocator, comptime T: type, value: T) Allocator.allocate_payload(*T) {
            const ret: *T = try meta.wrap(allocator.create(T));
            ret.* = value;
            return ret;
        }
        inline fn showCreate(comptime child: type, ptr: *child) void {
            if (Allocator.allocator_spec.logging.allocate) {
                about.showAllocateOneStructured(
                    child,
                    @intFromPtr(ptr),
                    @src(),
                    @returnAddress(),
                );
            }
        }
        inline fn showAllocate(comptime child: type, buf: []child, comptime sentinel: ?*const child) void {
            if (Allocator.allocator_spec.logging.allocate) {
                about.showAllocateManyStructured(
                    child,
                    @intFromPtr(buf.ptr),
                    @intFromPtr(buf.ptr) +% @sizeOf(child) *% (buf.len +% @as(u64, @intFromBool(sentinel != null))),
                    sentinel,
                    @src(),
                    @returnAddress(),
                );
            }
        }
        inline fn showReallocate(comptime child: type, s_buf: []child, t_buf: []child, comptime sentinel: ?*const child) void {
            if (Allocator.allocator_spec.logging.reallocate) {
                about.showReallocateManyStructured(
                    child,
                    child,
                    @intFromPtr(s_buf.ptr),
                    @intFromPtr(s_buf.ptr) +% @sizeOf(child) *% (s_buf.len +% @as(u64, @intFromBool(sentinel != null))),
                    @intFromPtr(t_buf.ptr),
                    @intFromPtr(t_buf.ptr) +% @sizeOf(child) *% (t_buf.len +% @as(u64, @intFromBool(sentinel != null))),
                    sentinel,
                    sentinel,
                    @src(),
                    @returnAddress(),
                );
            }
        }
        inline fn showDeallocate(comptime child: type, buf: []child, comptime sentinel: ?*const child) void {
            if (Allocator.allocator_spec.logging.allocate) {
                about.showDeallocateManyStructured(
                    child,
                    @intFromPtr(buf.ptr),
                    @intFromPtr(buf.ptr) +% @sizeOf(child) *% (buf.len +% @as(u64, @intFromBool(sentinel != null))),
                    sentinel,
                    @src(),
                    @returnAddress(),
                );
            }
        }
    };
}
const Journal = struct {
    lists: struct {
        mem.GenericLinkedList(.{ .child = Allocation, .Allocator = JournalAllocator, .low_alignment = 8 }),
        mem.GenericLinkedList(.{ .child = Deallocation, .Allocator = JournalAllocator, .low_alignment = 8 }),
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
    pub fn allocate(journal: *Journal, allocator: *mem.SimpleAllocator, pc_addr: usize, lb_addr: usize, ab_addr: u64, up_addr: u64, alignment: usize) void {
        return journal.lists[0].append(allocator, .{
            .pc_addr = pc_addr,
            .lb_addr = lb_addr,
            .ab_addr = ab_addr,
            .up_addr = up_addr,
            .alignment = alignment,
        });
    }
    pub fn deallocate(journal: *Journal, allocator: *mem.SimpleAllocator, pc_addr: usize, ab_addr: u64, up_addr: u64) void {
        var idx: u64 = 0;
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
            var array: PrintArray = undefined;
            array.undefineAll();
            showWrite(branches, &array);
            debug.logSuccess(array.readAll());
        }
        pub fn showWithReference(t_branches: Branches, s_branches: *Branches) void {
            var array: PrintArray = undefined;
            array.undefineAll();
            showWithReferenceWrite(t_branches, s_branches, &array);
            debug.logSuccess(array.readAll());
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamVector(high_alignment, low_alignment, Allocator, options);
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamView(high_alignment, low_alignment, Allocator, options);
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredVector(high_alignment, low_alignment, Allocator, options);
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredView(high_alignment, low_alignment, Allocator, options);
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredStreamHolder(Allocator, high_alignment, low_alignment, options);
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
            options.unit_alignment = low_alignment == Allocator.allocator_spec.options.unit_alignment;
            options.lazy_alignment = !options.unit_alignment;
            return container.UnstructuredHolder(Allocator, high_alignment, low_alignment, options);
        }
    };
}
fn GenericInterface(comptime Allocator: type) type {
    return opaque {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
        const Intermediate = GenericArenaAllocatorIntermediate(Allocator);
        const Implementation = GenericArenaAllocatorImplementation(Allocator);
        pub fn allocateStatic(allocator: *Allocator, comptime s_impl_type: type, o_amt: ?mem.Amount) Allocator.allocate_payload(s_impl_type) {
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
                        const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ss_addr = s_ss_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
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
                        const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                        if (@hasField(Construct, "ss_addr")) {
                            const s_ss_addr: u64 = s_ab_addr;
                            const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                            const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                            const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                            try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                            const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr, .ss_addr = s_ss_addr });
                            Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                            return s_impl;
                        }
                        const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                        const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                        const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                        try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                        const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr, .ab_addr = s_ab_addr });
                        Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                        return s_impl;
                    }
                    const n_count: u64 = mem.amountToCountOfLength(o_amt orelse _1, s_impl_type.high_alignment);
                    const s_aligned_bytes: u64 = n_count * s_impl_type.aligned_byte_count();
                    const s_ab_addr: u64 = mach.alignA64(s_lb_addr, s_impl_type.low_alignment);
                    const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                    try meta.wrap(Intermediate.allocateStaticAnyAligned(allocator, n_count, s_aligned_bytes, s_up_addr));
                    const s_impl: s_impl_type = s_impl_type.construct(.{ .lb_addr = s_lb_addr });
                    Graphics.showAllocateMany(s_impl_type, s_impl, @src());
                    return s_impl;
                }
            }
        }
        pub fn allocateMany(allocator: *Allocator, comptime s_impl_type: type, n_amt: mem.Amount) Allocator.allocate_payload(s_impl_type) {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const Construct: type = meta.FnParam0(s_impl_type.construct);
                if (@hasField(Construct, "lb_addr")) {
                    const s_lb_addr: u64 = allocator.unallocated_byte_address();
                    if (@hasField(Construct, "up_addr")) {
                        const s_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                        const s_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertAbove(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyBelow(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.Amount) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateMany(s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_aligned_bytes: u64 = s_impl.aligned_byte_count();
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                debug.assertBelow(u64, t_aligned_bytes, s_aligned_bytes);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) Allocator.allocate_void {
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
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count() +
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count() +
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes <= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                try meta.wrap(Intermediate.resizeManyAboveAnyAligned(allocator, s_up_addr, t_up_addr));
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeManyDecrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) void {
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
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count() -
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count() -
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                if (t_aligned_bytes >= s_aligned_bytes) return;
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.resizeManyBelowAnyAligned(allocator, s_up_addr, t_up_addr);
                return s_impl_ptr.resize(.{ .up_addr = t_up_addr });
            }
        }
        pub fn resizeHolderAbove(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, n_amt: mem.Amount) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveAnyAligned(allocator, t_up_addr));
            }
        }
        pub fn resizeHolderIncrement(allocator: *Allocator, comptime s_impl_type: type, s_impl_ptr: *s_impl_type, x_amt: mem.Amount) Allocator.allocate_void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count(allocator.*) +
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
                const t_up_addr: u64 = s_ab_addr + t_aligned_bytes;
                try meta.wrap(Intermediate.resizeHolderAboveUnitAligned(allocator, t_up_addr));
            } else { // @1b1
                const s_impl: s_impl_type = s_impl_ptr.*;
                defer Graphics.showReallocateHolder(allocator, s_impl_type, s_impl, s_impl_ptr.*, @src());
                const s_ab_addr: u64 = s_impl.aligned_byte_address(allocator.*);
                const n_amt: mem.Amount = .{ .bytes = s_impl.defined_byte_count(allocator.*) +
                    mem.amountOfLengthToBytes(x_amt, s_impl_type.high_alignment) };
                const t_aligned_bytes: u64 = mem.amountReservedToBytes(n_amt, s_impl_type);
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
                    const t_lb_addr: u64 = mach.cmov64(
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
                    const t_lb_addr: u64 = mach.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
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
                    const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
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
                    const t_lb_addr: u64 = mach.cmov64(
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
                    const t_lb_addr: u64 = mach.cmov64(
                        allocator.metadata.count == 1,
                        allocator.mapped_byte_address(),
                        allocator.unallocated_byte_address(),
                    );
                    if (@hasField(Translate, "ab_addr")) {
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
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
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
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
                        const t_ab_addr: u64 = mach.alignA64(t_lb_addr, s_impl_type.low_alignment);
                        const t_up_addr: u64 = t_ab_addr + t_aligned_bytes;
                        try meta.wrap(Intermediate.moveManyAnyAligned(allocator, t_up_addr));
                        return s_impl_ptr.translate(.{ .lb_addr = t_lb_addr, .up_addr = t_up_addr });
                    }
                }
            }
        }
        pub fn deallocateStatic(allocator: *Allocator, comptime s_impl_type: type, s_impl: s_impl_type, o_amt: ?mem.Amount) void {
            if (@hasDecl(s_impl_type, "unit_alignment")) { // @1b1
                if (Allocator.unit_alignment != s_impl_type.unit_alignment) {
                    @compileError("mismatched unit alignment");
                }
                const n_count: u64 = if (o_amt) |n_amt| mem.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
                const n_aligned_bytes: u64 = s_impl_type.aligned_byte_count();
                const s_aligned_bytes: u64 = n_aligned_bytes * n_count;
                const s_lb_addr: u64 = s_impl.allocated_byte_address();
                const s_ab_addr: u64 = s_impl.aligned_byte_address();
                const s_up_addr: u64 = s_ab_addr + s_aligned_bytes;
                Intermediate.deallocateStaticUnitAligned(allocator, n_count, s_aligned_bytes, s_lb_addr, s_up_addr);
                Graphics.showDeallocateMany(s_impl_type, s_impl, @src());
            } else { // @1b1
                const n_count: u64 = if (o_amt) |n_amt| mem.amountToCountOfLength(n_amt, s_impl_type.high_alignment) else 1;
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
}
fn GenericArenaAllocatorIntermediate(comptime Allocator: type) type {
    return opaque {
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
            } else if (Allocator.allocator_spec.options.require_resize) {
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
            } else if (Allocator.allocator_spec.options.require_resize) {
                @trap();
            }
        }
        fn resizeManyBelowUnitAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.resizeManyBelowUnitAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                about.showFiloResizeViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.resizeManyBelowUnitAlignedEndInternal(allocator, s_up_addr, t_up_addr);
            }
        }
        fn resizeManyBelowAnyAligned(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.resizeManyBelowAnyAlignedEndBoundary(allocator, s_up_addr, t_up_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
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
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticUnitAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateStaticAnyAligned(allocator: *Allocator, n_count: u64, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateStaticAnyAlignedEndBoundary(allocator, n_count, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateStaticAnyAlignedEndInternal(allocator, n_count, s_aligned_bytes);
            }
        }
        fn deallocateManyUnitAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateManyUnitAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
            } else {
                Implementation.deallocateManyUnitAlignedEndInternal(allocator, s_aligned_bytes);
            }
        }
        fn deallocateManyAnyAligned(allocator: *Allocator, s_aligned_bytes: u64, s_lb_addr: u64, s_up_addr: u64) void {
            if (s_up_addr == allocator.unallocated_byte_address()) {
                Implementation.deallocateManyAnyAlignedEndBoundary(allocator, s_aligned_bytes, s_lb_addr);
            } else if (Allocator.allocator_spec.options.require_filo_free) {
                debug.showFiloDeallocateViolationAndExit(allocator, s_up_addr, @src());
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
            } else if (Allocator.allocator_spec.options.require_resize) {
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
            } else if (Allocator.allocator_spec.options.require_resize) {
                @trap();
            }
        }
    };
}
fn GenericArenaAllocatorImplementation(comptime Allocator: type) type {
    return opaque {
        const Graphics = GenericArenaAllocatorGraphics(Allocator);
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
            allocator.increment(s_up_addr);
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
            allocator.increment(s_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
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
            allocator.increment(s_up_addr);
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
            allocator.increment(s_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
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
            allocator.increment(s_up_addr);
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
            allocator.increment(s_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
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
            allocator.increment(s_up_addr);
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
            allocator.increment(s_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(s_up_addr);
            }
        }
        fn allocateHolderAnyAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.holder.any_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                debug.assertEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = s_lb_addr;
            }
        }
        fn allocateHolderUnitAligned(allocator: *Allocator, s_lb_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.allocate.holder.unit_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                debug.assertEqual(u64, allocator.metadata.holder, 0);
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
            allocator.decrement(s_up_addr);
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
            allocator.decrement(s_up_addr);
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
            allocator.increment(t_up_addr);
        }
        fn resizeManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn resizeManyAboveUnitAlignedAddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn resizeManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_up_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.resize.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(t_up_addr, s_up_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveStaticAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveStaticAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.any_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveStaticUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveStaticUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.static.unit_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveManyAnyAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveManyAnyAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.any_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn moveManyUnitAlignedAddressable(allocator: *Allocator, t_up_addr: u64) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.addressable += 1;
            }
            allocator.increment(t_up_addr);
        }
        fn moveManyUnitAlignedUnaddressable(allocator: *Allocator, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.move.many.unit_aligned.unaddressable += 1;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn reallocateManyBelowAnyAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowAnyAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.any_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndBoundary(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_boundary += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyBelowUnitAlignedEndInternal(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.below.unit_aligned.end_internal += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility -= mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveAnyAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.any_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
        }
        fn reallocateManyAboveUnitAlignedAddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.addressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
        }
        fn reallocateManyAboveUnitAlignedUnaddressable(allocator: *Allocator, s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64) Allocator.allocate_void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.reallocate.many.above.unit_aligned.unaddressable += 1;
            }
            if (Allocator.allocator_spec.options.count_useful_bytes) {
                allocator.metadata.utility += mach.sub64(s_up_addr - s_ab_addr, t_up_addr - t_ab_addr);
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
            allocator.increment(t_up_addr);
            if (Allocator.allocator_spec.options.require_map) {
                return allocator.mapBelow(t_up_addr);
            }
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
            allocator.decrement(s_lb_addr);
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
            allocator.decrement(s_lb_addr);
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
            allocator.decrement(s_lb_addr);
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
            allocator.decrement(s_lb_addr);
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
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
        fn deallocateHolderUnitAligned(allocator: *Allocator) void {
            defer Graphics.showWithReference(allocator, @src());
            if (Allocator.allocator_spec.options.count_branches) {
                allocator.metadata.branches.deallocate.holder.unit_aligned += 1;
            }
            if (Allocator.allocator_spec.options.check_parametric) {
                debug.assertNotEqual(u64, allocator.metadata.holder, 0);
                allocator.metadata.holder = 0;
            }
        }
    };
}
const about = opaque {
    const PrintArray = mem.StaticString(8192);
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
    fn writeErrorName(array: *PrintArray, error_name: []const u8) void {
        array.writeMany("(");
        array.writeMany(error_name);
        array.writeMany(")");
    }
    fn writeAddressRange(array: *PrintArray, begin: u64, end: u64) void {
        array.writeFormat(fmt.ux64(begin));
        array.writeMany("..");
        array.writeFormat(fmt.ux64(end));
    }
    fn writeBytes(array: *PrintArray, begin: u64, end: u64) void {
        if (pretty_bytes) {
            array.writeFormat(fmt.bytes(end -% begin));
        } else {
            array.writeFormat(fmt.ud64(end -% begin));
            array.writeMany(" bytes");
        }
    }
    fn writeAddressRangeBytes(array: *PrintArray, begin: u64, end: u64) void {
        writeAddressRange(array, begin, end);
        array.writeMany(", ");
        writeBytes(array, begin, end);
    }
    fn writeChangedAddressRange(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        writeAddressRange(array, old_begin, old_end);
        array.writeMany(" -> ");
        writeAddressRange(array, new_begin, new_end);
    }
    fn writeChangedBytes(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        const old_len: u64 = old_end -% old_begin;
        const new_len: u64 = new_end -% new_begin;
        array.writeFormat(fmt.ud64(old_len));
        if (old_len != new_len) {
            array.writeMany(" -> ");
            array.writeFormat(fmt.ud64(new_len));
        }
        array.writeMany(" bytes");
    }
    fn writeChangedAddressRangeBytes(array: *PrintArray, old_begin: u64, old_end: u64, new_begin: u64, new_end: u64) void {
        writeChangedAddressRange(array, old_begin, old_end, new_begin, new_end);
        array.writeMany(", ");
        writeChangedBytes(array, old_begin, old_end, new_begin, new_end);
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
            return array.writeMany(resize_s);
        }
        if (s_aligned_bytes == t_aligned_bytes and s_ab_addr != t_ab_addr) {
            return array.writeMany(move_s);
        }
        if (s_ab_addr != t_ab_addr) {
            return array.writeMany(reallocated_s);
        }
        array.writeMany(no_op_s);
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
    fn writeOneType(array: *PrintArray, comptime s_child: type) void {
        array.writeMany(@typeName(s_child));
        array.writeMany(", ");
    }
    fn writeManyArrayNotationA(
        array: *PrintArray,
        comptime s_child: type,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
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
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes -% @sizeOf(t_child) *% @as(u64, @intFromBool(t_sentinel != null))) / @sizeOf(t_child);
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
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
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
        const s_count: u64 = (s_aligned_bytes -% @sizeOf(s_child) *% @as(u64, @intFromBool(s_sentinel != null))) / @sizeOf(s_child);
        const t_count: u64 = (t_aligned_bytes -% @sizeOf(t_child) *% @as(u64, @intFromBool(t_sentinel != null))) / @sizeOf(t_child);
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
    fn writeAboutOneAllocation(
        array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_uw_addr: u64,
        s_aligned_bytes: u64,
    ) void {
        writeAddressSpaceA(array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(array, s_aligned_bytes);
        writeOneType(array, s_child);
        array.overwriteManyBack("\n\n");
    }
    fn writeAboutManyAllocation(
        array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_uw_addr: u64,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        writeAddressSpaceA(array, s_ab_addr, s_uw_addr);
        writeAlignedBytesA(array, s_aligned_bytes);
        writeManyArrayNotationA(array, s_child, s_aligned_bytes, s_sentinel);
        array.overwriteManyBack("\n\n");
    }
    fn writeAboutHolderAllocation(
        array: *PrintArray,
        comptime s_child: type,
        s_ab_addr: u64,
        s_ua_addr: u64,
        s_aligned_bytes: u64,
        comptime s_sentinel: ?*const s_child,
    ) void {
        writeAddressSpaceA(array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(array, s_aligned_bytes);
        writeHolderArrayNotationA(array, s_child, s_aligned_bytes, s_sentinel);
        array.writeMany("\n\n");
    }
    fn writeAboutUnstructuredAllocation(
        array: *PrintArray,
        s_ab_addr: u64,
        s_ua_addr: u64,
        s_aligned_bytes: u64,
    ) void {
        writeAddressSpaceA(array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(array, s_aligned_bytes);
        array.writeMany("\n\n");
    }
    fn mapNotice(addr: u64, len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(map_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn unmapNotice(addr: u64, len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(unmap_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn arenaAcquireNotice(index_opt: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(acq_s);
        array.writeMany(label orelse "arena");
        array.writeMany("-");
        if (index_opt) |index| {
            array.writeFormat(fmt.ud64(index));
        }
        array.writeMany(", ");
        writeAddressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn arenaReleaseNotice(index_opt: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(rel_s);
        array.writeMany(label orelse "arena");
        array.writeMany("-");
        if (index_opt) |index| {
            array.writeFormat(fmt.ud64(index));
        }
        array.writeMany(", ");
        writeAddressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(advice_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany(", ");
        array.writeMany(description_s);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn resizeNotice(old_addr: u64, old_len: u64, new_len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(remap_s);
        writeChangedAddressRangeBytes(&array, old_addr, old_addr +% old_len, old_addr, old_addr +% new_len);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn moveNotice(old_addr: u64, old_len: u64, new_addr: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(move_s);
        writeChangedAddressRangeBytes(&array, old_addr, old_addr +% old_len, new_addr, new_addr +% old_len);
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn mapError(map_error: anytype, addr: u64, len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(map_1_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(map_error));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(unmap_1_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(unmap_error));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn arenaAcquireError(arena_error: anytype, index: u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(acq_1_s);
        array.writeMany(label orelse "arena");
        array.writeMany("-");
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        writeAddressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(arena_error));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn arenaReleaseError(arena_error: anytype, index: u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(rel_1_s);
        array.writeMany(label orelse "arena");
        array.writeMany("-");
        array.writeFormat(fmt.ud64(index));
        array.writeMany(", ");
        writeAddressRangeBytes(&array, lb_addr, up_addr);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(arena_error));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn adviseError(madvise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(advice_1_s);
        writeAddressRangeBytes(&array, addr, addr +% len);
        array.writeMany(", ");
        array.writeMany(description_s);
        array.writeMany(", ");
        writeErrorName(&array, @errorName(madvise_error));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn resizeError(mremap_err: anytype, old_addr: u64, old_len: u64, new_len: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(remap_1_s);
        writeChangedAddressRangeBytes(&array, old_addr, old_addr +% old_len, old_addr, old_addr +% new_len);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(mremap_err));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn moveError(mremap_err: anytype, old_addr: u64, old_len: u64, new_addr: u64) void {
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeMany(move_1_s);
        writeChangedAddressRangeBytes(&array, old_addr, old_addr +% old_len, new_addr, new_addr +% old_len);
        array.writeMany(" ");
        writeErrorName(&array, @errorName(mremap_err));
        array.writeMany("\n");
        debug.write(array.readAll());
    }
    fn showAllocateOneStructured(comptime s_child: type, s_ab_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = @sizeOf(s_child);
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(allocated_s);
        writeAboutOneAllocation(&array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(allocated_s);
        writeAboutManyAllocation(&array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes, s_sentinel);
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(allocated_s);
        writeAboutHolderAllocation(&array, s_child, s_ab_addr, s_ua_addr, s_aligned_bytes, s_sentinel);
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        writeManyArrayNotationB(&array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_uw_addr, t_ab_addr, t_uw_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        writeHolderArrayNotationB(&array, s_child, t_child, s_aligned_bytes, t_aligned_bytes, s_sentinel, t_sentinel);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showDeallocateOneStructured(comptime s_child: type, s_ab_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = @sizeOf(s_child);
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(deallocated_s);
        writeAboutOneAllocation(&array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(deallocated_s);
        writeAboutManyAllocation(&array, s_child, s_ab_addr, s_uw_addr, s_aligned_bytes, s_sentinel);
        debug.write(array.readAll());
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
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(deallocated_s);
        writeAboutHolderAllocation(&array, s_child, s_ab_addr, s_ua_addr, s_aligned_bytes, s_sentinel);
        debug.write(array.readAll());
    }
    fn showAllocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_uw_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(allocated_s);
        writeAboutUnstructuredAllocation(&array, s_ab_addr, s_uw_addr, s_aligned_bytes);
        debug.write(array.readAll());
    }
    fn showReallocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showReallocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, t_ab_addr: u64, t_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const t_aligned_bytes: u64 = t_up_addr -% t_ab_addr;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        writeModifyOperation(&array, s_ab_addr, s_aligned_bytes, t_ab_addr, t_aligned_bytes);
        writeAddressSpaceB(&array, s_ab_addr, s_up_addr, t_ab_addr, t_up_addr);
        writeAlignedBytesB(&array, s_aligned_bytes, t_aligned_bytes);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showAllocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        const s_ua_addr: u64 = s_ab_addr +% s_aligned_bytes;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(allocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_ua_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showDeallocateManyUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showDeallocateHolderUnstructured(s_ab_addr: u64, s_up_addr: u64, src: builtin.SourceLocation, ret_addr: u64) void {
        const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, ret_addr);
        const s_aligned_bytes: u64 = s_up_addr -% s_ab_addr;
        var array: PrintArray = undefined;
        array.undefineAll();
        array.writeFormat(src_fmt);
        array.writeMany(deallocated_s);
        writeAddressSpaceA(&array, s_ab_addr, s_up_addr);
        writeAlignedBytesA(&array, s_aligned_bytes);
        array.overwriteManyBack("\n\n");
        debug.write(array.readAll());
    }
    fn showFiloDeallocateViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (comptime @TypeOf(allocator.*).allocator_spec.logging.illegal) {
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            const s_ua_addr: u64 = allocator.unallocated_byte_address();
            const d_aligned_bytes: u64 = s_ua_addr -% s_up_addr;
            var array: PrintArray = undefined;
            array.undefineAll();
            array.writeFormat(src_fmt);
            array.writeMany(filo_error_s ++ "attempted deallocation ");
            array.writeFormat(fmt.bytes(d_aligned_bytes));
            array.writeMany(" below segment maximum\n\n");
            debug.write(array.readAll());
        }
        proc.exit(2);
    }
    fn showFiloResizeViolationAndExit(allocator: anytype, s_up_addr: u64, src: builtin.SourceLocation) void {
        if (comptime @TypeOf(allocator.*).allocator_spec.logging.illegal) {
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            const s_ua_addr: u64 = allocator.unallocated_byte_address();
            const d_aligned_bytes: u64 = s_ua_addr -% s_up_addr;
            var array: PrintArray = undefined;
            array.undefineAll();
            array.writeFormat(src_fmt);
            array.writeMany(filo_error_s ++ "attempted resize ");
            array.writeFormat(fmt.bytes(d_aligned_bytes));
            array.writeMany(" below segment maximum\n\n");
            debug.write(array.readAll());
        }
        proc.exit(2);
    }
};
fn GenericArenaAllocatorGraphics(comptime Allocator: type) type {
    return opaque {
        const is_silent: bool = meta.leastBitCast(Allocator.allocator_spec.logging) == 0;
        pub fn show(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (is_silent) return;
            const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
            var array: about.PrintArray = undefined;
            array.undefineAll();
            array.writeFormat(src_fmt);
            if (Allocator.allocator_spec.logging.head) {
                array.writeMany(about.next_s);
                array.writeFormat(fmt.ux64(allocator.unallocated_byte_address()));
                array.writeOne('\n');
            }
            if (Allocator.allocator_spec.logging.sentinel) {
                array.writeMany(about.finish_s);
                array.writeFormat(fmt.ux64(allocator.unmapped_byte_address()));
                array.writeOne('\n');
            }
            if (Allocator.allocator_spec.logging.metadata) {
                if (Allocator.allocator_spec.options.count_allocations) {
                    array.writeMany(about.count_s);
                    array.writeFormat(fmt.ud64(allocator.metadata.count));
                    array.writeOne('\n');
                }
                if (Allocator.allocator_spec.options.count_useful_bytes) {
                    array.writeMany(about.utility_s);
                    array.writeFormat(fmt.ud64(allocator.metadata.utility));
                    array.writeOne('/');
                    array.writeFormat(fmt.ud64(allocator.allocated_byte_count()));
                    array.writeOne('\n');
                }
                if (Allocator.allocator_spec.options.check_parametric) {
                    array.writeMany(about.holder_s);
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
                debug.logSuccess(array.readAll());
            }
        }
        pub fn showWithReference(allocator: *Allocator, src: builtin.SourceLocation) void {
            if (is_silent) return;
            if (Allocator.allocator_spec.options.trace_state) {
                const src_fmt: fmt.SourceLocationFormat = fmt.sourceLocation(src, @returnAddress());
                var array: about.PrintArray = undefined;
                array.undefineAll();
                array.writeFormat(src_fmt);
                if (Allocator.allocator_spec.logging.head and
                    allocator.reference.ub_addr != allocator.ub_addr)
                {
                    array.writeMany(about.next_s);
                    array.writeFormat(fmt.uxd(allocator.reference.ub_addr, allocator.ub_addr));
                    array.writeOne('\n');
                    allocator.reference.ub_addr = allocator.ub_addr;
                }
                if (Allocator.allocator_spec.logging.sentinel and
                    allocator.reference.up_addr != allocator.up_addr)
                {
                    array.writeMany(about.finish_s);
                    array.writeFormat(fmt.uxd(allocator.reference.up_addr, allocator.up_addr));
                    array.writeOne('\n');
                    allocator.reference.up_addr = allocator.up_addr;
                }
                if (Allocator.allocator_spec.logging.metadata) {
                    if (Allocator.allocator_spec.options.count_allocations and
                        allocator.reference.count != allocator.metadata.count)
                    {
                        array.writeMany(about.count_s);
                        array.writeFormat(fmt.udd(allocator.reference.count, allocator.metadata.count));
                        array.writeOne('\n');
                        allocator.reference.count = allocator.metadata.count;
                    }
                    if (Allocator.allocator_spec.options.count_useful_bytes and
                        allocator.reference.utility != allocator.metadata.utility)
                    {
                        array.writeMany(about.utility_s);
                        array.writeFormat(fmt.udd(allocator.reference.utility, allocator.metadata.utility));
                        array.writeOne('/');
                        array.writeFormat(fmt.ud(allocator.allocated_byte_count()));
                        array.writeOne('\n');
                        allocator.reference.utility = allocator.metadata.utility;
                    }
                    if (Allocator.allocator_spec.options.check_parametric and
                        allocator.reference.holder != allocator.metadata.holder)
                    {
                        array.writeMany(about.holder_s);
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
                    debug.write(array.readAll());
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
            if (Allocator.allocator_spec.logging.allocate) {
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
            if (Allocator.allocator_spec.logging.reallocate) {
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
            if (Allocator.allocator_spec.logging.reallocate) {
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
            if (Allocator.allocator_spec.logging.deallocate) {
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
            if (Allocator.allocator_spec.logging.deallocate) {
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
}
