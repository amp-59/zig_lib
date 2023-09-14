const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const math = @import("./math.zig");
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const _virtual = @import("./virtual.zig");
const _reference = @import("./reference.zig");
const _container = @import("./container.zig");
const _allocator = @import("./allocator.zig");
const _list = @import("./list.zig");
const mem = @This();
pub usingnamespace _virtual;
pub usingnamespace _reference;
pub usingnamespace _container;
pub usingnamespace _allocator;
pub usingnamespace _list;
pub const Sync = struct {
    pub const Options = meta.EnumBitField(enum(u64) {
        synchronous = MS.SYNC,
        asynchronous = MS.ASYNC,
        invalidate = MS.INVALIDATE,
        const MS = sys.MS;
    });
};
pub const Prot = struct {
    pub const Options = meta.EnumBitField(enum(u64) {
        none = PROT.NONE,
        read = PROT.READ,
        write = PROT.WRITE,
        exec = PROT.EXEC,
        grows_down = PROT.GROWSDOWN,
        grows_up = PROT.GROWSUP,
        const PROT = sys.PROT;
    });
};
pub const Remap = struct {
    pub const Options = meta.EnumBitField(enum(u64) {
        resize = REMAP.RESIZE,
        may_move = REMAP.MAYMOVE,
        fixed = REMAP.FIXED,
        no_unmap = REMAP.DONTUNMAP,
        const REMAP = sys.REMAP;
    });
};
pub const Advice = enum(usize) {
    normal = 0,
    random = 1,
    sequential = 2,
    will_need = 3,
    dont_need = 4,
    free = 8,
    remove = 9,
    dont_fork = 10,
    do_fork = 11,
    mergeable = 12,
    unmergeable = 13,
    hugepage = 14,
    no_hugepage = 15,
    dont_dump = 16,
    do_dump = 17,
    wipe_on_fork = 18,
    keep_on_fork = 19,
    cold = 20,
    pageout = 21,
    hw_poison = 100,
    fn describe(advice: Advice) []const u8 {
        switch (advice) {
            .normal => return "expect normal usage",
            .random => return "expect page references in random order",
            .sequential => return "expect page references in sequential order",
            .will_need => return "expect access in the near future",
            .dont_need => return "do not expect access in the near future",
            .remove => return "swap out backing store",
            .free => return "swap out pages as needed",
            .pageout => return "swap out pages now",
            .cold => return "reclaim pages",
            .hw_poison => return "illegal access",
            .mergeable => return "merge identical pages",
            .unmergeable => return "do not merge identical pages",
            .hugepage => return "expect large contiguous mappings",
            .no_hugepage => return "do not expect large contiguous mappings",
            .do_dump => return "include in core dump",
            .dont_dump => return "exclude from core dump",
            .do_fork => return "available to child processes",
            .dont_fork => return "unavailable to child processes",
            .wipe_on_fork => return "wiping on fork",
            .keep_on_fork => return "keeping on fork",
        }
        return "(unknown advise)";
    }
};
pub const Fd = struct {
    pub const Options = meta.EnumBitField(enum(u64) {
        allow_sealing = MFD.ALLOW_SEALING,
        huge_tlb = MFD.HUGETLB,
        close_on_exec = MFD.CLOEXEC,
        const MFD = sys.MFD;
    });
};
pub const Map = struct {
    pub const Flags = packed struct(usize) {
        visibility: Visibility = .private,
        zb2: u2 = 0,
        fixed: bool = false,
        anonymous: bool = true,
        @"32bit": bool = false,
        zb7: u1 = 0,
        grows_down: bool = false,
        zb9: u2 = 0,
        deny_write: bool = false,
        executable: bool = false,
        locked: bool = false,
        no_reserve: bool = false,
        populate: bool = false,
        non_block: bool = false,
        stack: bool = false,
        huge_tlb: bool = false,
        sync: bool = false,
        fixed_noreplace: bool = true,
        zb21: u43 = 0,
    };
    pub const Visibility = enum(u2) {
        shared = 1,
        private = 2,
        shared_validate = 3,
    };
    pub const Protection = packed struct(usize) {
        read: bool = true,
        write: bool = true,
        exec: bool = false,
        zb3: u21 = 0,
        grows_down: bool = false,
        grows_up: bool = false,
        zb26: u38 = 0,
    };
};
pub const MapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
};
pub const SyncSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.msync_errors },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = struct {
        non_block: bool = false,
        invalidate: bool = false,
    };
    pub fn flags(comptime spec: Specification) Sync.Options {
        var flags_bitfield: Sync.Options = .{ .val = 0 };
        if (spec.options.non_block) {
            flags_bitfield.set(.asynchronous);
        } else {
            flags_bitfield.set(.synchronous);
        }
        if (spec.options.invalidate) {
            flags_bitfield.set(.invalidate);
        }
        comptime return flags_bitfield;
    }
};
pub const MoveSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.mremap_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
    const Options = struct { no_unmap: bool = false };
    pub fn flags(comptime spec: Specification) Remap.Options {
        var flags_bitfield: Remap.Options = .{ .val = 0 };
        if (spec.options.no_unmap) {
            flags_bitfield.set(.no_unmap);
        }
        flags_bitfield.set(.fixed);
        flags_bitfield.set(.may_move);
        comptime return flags_bitfield;
    }
};
pub const RemapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mremap_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const UnmapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.munmap_errors },
    return_type: type = void,
    logging: debug.Logging.ReleaseError = .{},
    const Specification = @This();
};
pub const ProtectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mprotect_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
    const Protection = packed struct(usize) {
        read: bool = true,
        write: bool = true,
        exec: bool = false,
        zb3: u21 = 0,
        grows_down: bool = false,
        grows_up: bool = false,
        zb26: u38 = 0,
    };
};
pub const AdviseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.madvise_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const FdSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.memfd_create_errors },
    return_type: type = u64,
    logging: debug.Logging.AcquireError = .{},
    const Specification = @This();
    const Options = struct {
        allow_sealing: bool = false,
        huge_tlb: bool = false,
        close_on_exec: bool = true,
    };
    const Visibility = enum { shared, shared_validate, private };
    pub fn flags(comptime spec: FdSpec) mem.Fd.Options {
        var flags_bitfield: Fd.Options = .{ .val = 0 };
        if (spec.options.allow_sealing) {
            flags_bitfield.set(.allow_sealing);
        }
        if (spec.options.huge_tlb) {
            flags_bitfield.set(.huge_tlb);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        comptime return flags_bitfield;
    }
};
pub const Bytes = struct {
    count: usize,
    unit: Unit,

    pub const mask: usize = 0b1111111111;
    pub const Unit = enum(u6) {
        EiB = 60,
        PiB = 50,
        TiB = 40,
        GiB = 30,
        MiB = 20,
        KiB = 10,
        B = 0,
        pub fn to(count: usize, unit: Unit) Bytes {
            return .{ .count = (count & (mask << @intFromEnum(unit))) >> @intFromEnum(unit), .unit = unit };
        }
    };
    pub fn bytes(amt: Bytes) usize {
        return amt.count *% (@as(usize, 1) << @intFromEnum(amt.unit));
    }
};
pub noinline fn monitor(comptime T: type, ptr: *T) void {
    const in: T = ptr.*;
    switch (T) {
        u8, bool => asm volatile (
            \\pause
            \\0:
            \\mov %[done], %al
            \\cmpb %al, %[in]
            \\je 0b
            :
            : [done] "p" (ptr),
              [in] "r" (in),
            : "al", "memory"
        ),
        u16 => asm volatile (
            \\pause
            \\0:
            \\mov %[done], %ax
            \\cmp %ax, %[in]
            \\je 0b
            :
            : [done] "p" (ptr),
              [in] "r" (in),
            : "ax", "memory"
        ),
        u32 => asm volatile (
            \\pause
            \\0:
            \\movl %[done], %eax
            \\cmpl %eax, %[in]
            \\je 0b
            :
            : [done] "p" (ptr),
              [in] "r" (in),
            : "eax", "memory"
        ),
        u64 => asm volatile (
            \\pause
            \\0:
            \\movq %[done], %rax
            \\cmpq %rax, %[in]
            \\je 0b
            :
            : [ptr] "p" (ptr),
              [in] "r" (in),
            : "rax", "memory"
        ),
        else => @compileError("???"),
    }
}
fn acquireMap(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.map_void {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    if (address_space.set(spec.divisions)) {
        return map(AddressSpace.map_spec, .{}, .{}, spec.addressable_byte_address(), spec.addressable_byte_count());
    }
}
fn releaseUnmap(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.unmap_void {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    if (address_space.count() == 0 and
        address_space.unset(spec.divisions))
    {
        return unmap(AddressSpace.unmap_spec, spec.addressable_byte_address(), spec.addressable_byte_count());
    }
}
fn acquireSet(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) bool {
    if (AddressSpace.addr_spec.options.thread_safe) {
        return address_space.atomicSet(index);
    } else {
        return address_space.set(index);
    }
}
fn acquireStaticSet(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) bool {
    if (comptime AddressSpace.arena(index).options.thread_safe) {
        return address_space.atomicSet(index);
    } else {
        return address_space.set(index);
    }
}
fn acquireElementarySet(comptime AddressSpace: type, address_space: *AddressSpace) bool {
    if (comptime AddressSpace.addr_spec.options.thread_safe) {
        return address_space.atomicSet();
    } else {
        return address_space.set();
    }
}
fn releaseUnset(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) bool {
    if (AddressSpace.addr_spec.options.thread_safe) {
        return address_space.atomicUnset(index);
    } else {
        return address_space.unset(index);
    }
}
fn releaseStaticUnset(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) bool {
    if (comptime AddressSpace.arena(index).options.thread_safe) {
        return address_space.atomicUnset(index);
    } else {
        return address_space.unset(index);
    }
}
fn releaseElementaryUnset(comptime AddressSpace: type, address_space: *AddressSpace) bool {
    if (comptime AddressSpace.addr_spec.options.thread_safe) {
        return address_space.atomicUnset();
    } else {
        return address_space.unset();
    }
}
pub fn acquire(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.acquire_void {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireSet(AddressSpace, address_space, index)) {
        if (spec.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(spec.errors.acquire.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn acquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireStaticSet(AddressSpace, address_space, index)) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(spec.errors.acquire.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn acquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_void {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = address_space.low();
    const up_addr: u64 = address_space.high();
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireElementarySet(AddressSpace, address_space)) {
        if (logging.Acquire) {
            about.arenaAcquireNotice(null, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(spec.errors.acquire.throw), null, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn release(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_void {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    if (releaseUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, spec.label);
        }
        if (spec.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(spec.errors.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn releaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    if (releaseStaticUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(spec.errors.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn releaseElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.release_void {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = address_space.low();
    const up_addr: u64 = address_space.high();
    if (releaseElementaryUnset(AddressSpace, address_space)) {
        if (spec.logging.release.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, null, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (spec.logging.release.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(spec.errors.throw), null, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn testAcquire(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.acquire_bool {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireSet(AddressSpace, address_space, index);
    if (ret) {
        if (spec.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testAcquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_bool(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireStaticSet(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testAcquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_bool {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime address_space.low();
    const up_addr: u64 = comptime address_space.high();
    const logging: debug.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireElementarySet(AddressSpace, address_space);
    if (ret) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, null, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testRelease(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_bool {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    const ret: bool = releaseUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, spec.label);
        }
        if (spec.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    }
    return ret;
}
pub fn tryReleaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_bool(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    const ret: bool = releaseStaticUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testReleaseElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.release_bool {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime address_space.low();
    const up_addr: u64 = comptime address_space.high();
    const ret: bool = releaseElementaryUnset(AddressSpace, address_space);
    if (ret) {
        if (spec.logging.release.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, null, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn map(comptime spec: MapSpec, prot: Map.Protection, flags: Map.Flags, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mmap, spec.errors, spec.return_type, [6]usize{
        addr, len, @bitCast(prot), @bitCast(flags), 0, 0,
    }))) |ret| {
        if (logging.Acquire) {
            about.aboutAddrLenNotice(about.map_s, addr, len);
        }
        if (spec.return_type != void) {
            return ret;
        }
    } else |map_error| {
        if (logging.Error) {
            about.aboutAddrLenError(about.map_s, @errorName(map_error), addr, len);
        }
        return map_error;
    }
}
pub fn sync(comptime sync_spec: SyncSpec, addr: u64, len: u64) sys.ErrorUnion(sync_spec.errors, sync_spec.return_type) {
    const msync_flags: Sync.Options = comptime sync_spec.flags();
    const logging: debug.Logging.AcquireError = comptime sync_spec.logging.override();
    if (meta.wrap(sys.call(.sync, sync_spec.errors, sync_spec.return_type, .{ addr, len, msync_flags.val }))) |ret| {
        if (logging.Acquire) {
            about.syncNotice(addr, len);
        }
        if (sync_spec.return_type != void) {
            return ret;
        }
    } else |sync_error| {
        if (logging.Error) {
            about.syncError(sync_error, addr, len);
        }
        return sync_error;
    }
}
pub fn move(comptime spec: MoveSpec, old_addr: u64, old_len: u64, new_addr: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const mremap_flags: Remap.Options = comptime spec.flags();
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mremap, spec.errors, spec.return_type, .{ old_addr, old_len, old_len, mremap_flags.val, new_addr }))) {
        if (logging.Success) {
            about.aboutRemapNotice(about.remap_s, old_addr, old_len, new_addr, null);
        }
    } else |mremap_error| {
        if (logging.Error) {
            about.aboutRemapError(about.move_s, @errorName(mremap_error), old_addr, old_len, new_addr, null);
        }
        return mremap_error;
    }
}
pub fn resize(comptime spec: RemapSpec, old_addr: u64, old_len: u64, new_len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mremap, spec.errors, spec.return_type, .{ old_addr, old_len, new_len, 0, 0 }))) {
        if (logging.Success) {
            about.aboutRemapNotice(about.resize_s, old_addr, old_len, null, new_len);
        }
    } else |mremap_error| {
        if (logging.Error) {
            about.aboutRemapError(about.resize_s, @errorName(mremap_error), old_addr, old_len, null, new_len);
        }
        return mremap_error;
    }
}
pub fn unmap(comptime spec: UnmapSpec, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.ReleaseError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.munmap, spec.errors, spec.return_type, .{ addr, len }))) {
        if (logging.Release) {
            about.aboutAddrLenNotice(about.unmap_s, addr, len);
        }
    } else |unmap_error| {
        if (logging.Error) {
            about.aboutAddrLenError(about.unmap_s, @errorName(unmap_error), addr, len);
        }
        return unmap_error;
    }
}
pub fn protect(comptime spec: ProtectSpec, prot: ProtectSpec.Protection, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mprotect, spec.errors, spec.return_type, .{ addr, len, @as(usize, @bitCast(prot)) }))) {
        if (logging.Success) {
            about.aboutAddrLenDescrNotice(about.protect_s, addr, len, "<description>");
        }
    } else |protect_error| {
        if (logging.Error) {
            about.aboutAddrLenDescrError(about.protect_s, @errorName(protect_error), addr, len, "<description>");
        }
        return protect_error;
    }
}
pub fn advise(comptime spec: AdviseSpec, advice: Advice, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.madvise, spec.errors, spec.return_type, .{ addr, len, @intFromEnum(advice) }))) {
        if (logging.Success) {
            about.aboutAddrLenDescrNotice(about.advice_s, addr, len, advice.describe());
        }
    } else |madvise_error| {
        if (logging.Error) {
            about.aboutAddrLenDescrError(about.advice_s, @errorName(madvise_error), addr, len, advice.describe());
        }
        return madvise_error;
    }
}
pub fn fd(comptime spec: FdSpec, pathname: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(pathname.ptr);
    const flags: mem.Fd.Options = comptime spec.flags();
    const logging: debug.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.memfd_create, spec.errors, spec.return_type, .{ name_buf_addr, flags.val }))) |mem_fd| {
        if (logging.Acquire) {
            about.aboutMemFdPathnameNotice(about.memfd_s, mem_fd, pathname);
        }
        return mem_fd;
    } else |memfd_create_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.memfd_s, @errorName(memfd_create_error), pathname);
        }
        return memfd_create_error;
    }
}
pub const about = opaque {
    const map_s: fmt.AboutSrc = fmt.about("map");
    const acq_s: fmt.AboutSrc = fmt.about("acq");
    const rel_s: fmt.AboutSrc = fmt.about("rel");
    const acq_2_s: fmt.AboutSrc = fmt.about("acq-fault\n");
    const rel_2_s: fmt.AboutSrc = fmt.about("rel-fault\n");
    const move_s: fmt.AboutSrc = fmt.about("move");
    const unmap_s: fmt.AboutSrc = fmt.about("unmap");
    const remap_s: fmt.AboutSrc = fmt.about("remap");
    const memfd_s: fmt.AboutSrc = fmt.about("memfd");
    const resize_s: fmt.AboutSrc = fmt.about("resize");
    const advice_s: fmt.AboutSrc = fmt.about("advice");
    const protect_s: fmt.AboutSrc = fmt.about("protect");
    pub fn aboutAddrLenNotice(about_s: fmt.AboutSrc, addr: u64, len: u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr += fmt.ux64(addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(addr +% len).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.bytes(len).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) - @intFromPtr(&buf)]);
    }
    fn aboutAddrLenDescrNotice(about_s: fmt.AboutSrc, addr: u64, len: u64, description_s: []const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr += fmt.ux64(addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(addr +% len).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.bytes(len).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, description_s);
        ptr += description_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutRemapNotice(about_s: fmt.AboutSrc, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: *const [3]u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr += fmt.ux64(old_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(old_addr +% old_len).formatWriteBuf(ptr);
        ptr[0..4].* = " -> ".*;
        ptr += 4;
        ptr += fmt.ux64(new_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(new_addr +% new_len).formatWriteBuf(ptr);
        ptr[0..3].* = notation_s.*;
        ptr += 3;
        ptr += fmt.bytes(abs_diff).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutIndexLbAddrUpAddrLabelNotice(about_s: fmt.AboutSrc, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        const label_s: []const u8 = label orelse "arena";
        @memcpy(ptr, label_s);
        ptr += label_s.len;
        ptr[0] = '-';
        ptr += 1;
        ptr += fmt.ud64(index orelse 0).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ux64(lb_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(up_addr).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.bytes(up_addr -% lb_addr).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutMemFdPathnameNotice(about_s: fmt.AboutSrc, mem_fd: usize, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0..9].* = ", mem_fd=".*;
        ptr += 9;
        ptr += fmt.ud64(mem_fd).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenError(about_s: fmt.AboutSrc, error_name: []const u8, addr: u64, len: u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ux64(addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(addr +% len).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.bytes(len).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) - @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenDescrError(about_s: fmt.AboutSrc, error_name: []const u8, addr: u64, len: u64, description_s: []const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ux64(addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(addr +% len).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ud64(len).formatWriteBuf(ptr);
        ptr[0..8].* = " bytes, ".*;
        ptr += 8;
        @memcpy(ptr, description_s);
        ptr += description_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
    }
    fn aboutRemapError(about_s: fmt.AboutSrc, error_name: []const u8, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: *const [3]u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ux64(old_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(old_addr +% old_len).formatWriteBuf(ptr);
        ptr[0..4].* = " -> ".*;
        ptr += 4;
        ptr += fmt.ux64(new_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(new_addr +% new_len).formatWriteBuf(ptr);
        ptr[0..3].* = notation_s.*;
        ptr += 3;
        ptr += fmt.bytes(abs_diff).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutIndexLbAddrUpAddrLabelError(about_s: fmt.AboutSrc, error_name: [:0]const u8, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        const label_s: []const u8 = label orelse "arena";
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, label_s);
        ptr += label_s.len;
        ptr[0] = '-';
        ptr += 1;
        ptr += fmt.ud64(index orelse 0).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.ux64(lb_addr).formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr += fmt.ux64(up_addr).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.bytes(up_addr -% lb_addr).formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameError(about_s: fmt.AboutSrc, error_name: []const u8, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, error_name);
        ptr += error_name.len;
        ptr[0..2].* = ", ".*;
        ptr += 2;
        @memcpy(ptr, pathname);
        ptr += pathname.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
    }
    pub fn sampleAllReports() void {
        const about_s: fmt.AboutSrc = comptime fmt.about("about");
        const pathname1: [:0]const u8 = "/path/to/file1";
        const fd1: u32 = 8;
        const addr1: u64 = 4096;
        const len1: u64 = 4096;
        const addr2: u64 = 8192;
        const len2: u64 = 8192;
        aboutAddrLenNotice(about_s, addr1, len1);
        aboutAddrLenDescrNotice(about_s, addr1, len1, "<missing>");
        aboutRemapNotice(about_s, addr1, len1, addr2, len2);
        aboutRemapNotice(remap_s, addr1, len1, addr2, len2);
        aboutRemapNotice(resize_s, addr1, len1, null, len2);
        aboutRemapNotice(move_s, addr1, len1, addr2, null);
        aboutMemFdPathnameNotice(memfd_s, fd1, pathname1);
        aboutAddrLenError(about_s, "UnmapError", addr1, len1);
        aboutAddrLenDescrError(about_s, "ProtectError", addr1, len1, "<missing>");
        aboutRemapError(remap_s, "RemapError", addr1, len1, addr2, len2);
        aboutRemapError(resize_s, "ResizeError", addr1, len1, null, len2);
        aboutRemapError(move_s, "MoveError", addr1, len1, addr2, null);
        aboutPathnameError(memfd_s, "MemFdError", pathname1);
    }
};
pub fn literalView(comptime s: [:0]const u8) mem.StructuredAutomaticView(u8, &@as(u8, 0), s.len, null, .{}) {
    return .{ .impl = .{ .auto = @as(*const [s.len:0]u8, @ptrCast(s.ptr)).* } };
}
pub fn view(s: []const u8) mem.StructuredStreamView(u8, null, 1, struct {}, .{}) {
    return .{ .impl = .{
        .lb_word = @intFromPtr(s.ptr),
        .up_word = @intFromPtr(s.ptr + s.len),
        .ss_word = @intFromPtr(s.ptr),
    } };
}
pub fn StaticStream(comptime child: type, comptime count: u64) type {
    return mem.StructuredAutomaticStreamVector(child, null, count, @alignOf(child), .{});
}
pub fn StaticArray(comptime child: type, comptime count: u64) type {
    return mem.StructuredAutomaticVector(child, null, count, @alignOf(child), .{});
}
pub fn StaticView(comptime child: type, comptime count: u64) type {
    return mem.StructuredAutomaticView(child, null, count, @alignOf(child), .{});
}
pub fn StaticString(comptime count: u64) type {
    return StaticArray(u8, count);
}
/// Potential features of a referenced value in memory:
/// |->_~~~~~~_~~~~_------------------------------_--|
/// |  |      |    |                              |  |
/// |  |      |    `lowest undefined byte (UB)*   |  `lowest unallocated byte (UP)**
/// |  |      `- lowest unstreamed byte (SS)      |
/// |  `lowest aligned byte (AB)                  `-lowest sentinel byte (XB)
/// |
/// `-lowest allocated byte (LB)
///
/// *  'lowest unallocated byte' in allocator implementations
/// ** 'lowest unaddressable byte' in allocator implementations
///
/// The purpose of this union is to provide a compact overview of how memory is
/// implemented, and to restrict the nomenclature therefor. The implementation
/// is specified using four arbitrary categories:
///     `mode`          => set of available functions,
///     `fields`        => data for storing the referenced value,
///     `techniques`    => how to interpret or transform the reference data,
///     `specifiers`    => set of available configuration parameters,
pub const AbstractSpec = union(enum) {
    /// Automatic memory below
    automatic_storage: union(enum) {
        read_write_auto: Automatic,
        unstreamed_byte_address: union(enum) {
            read_write_stream_auto: Automatic,
            undefined_byte_address: union(enum) {
                read_write_stream_resize_auto: Automatic,
            },
        },
        undefined_byte_address: union(enum) {
            read_write_resize_auto: Automatic,
        },
    },
    /// Managed memory below
    allocated_byte_address: union(enum) {
        read_write: union(enum) {
            static: Static,
            // single_packed_approximate_capacity: Dynamic,
        },
        unstreamed_byte_address: union(enum) {
            undefined_byte_address: union(enum) {
                read_write_stream_resize: union(enum) {
                    // single_packed_approximate_capacity: Dynamic,
                    // double_packed_approximate_capacity: Dynamic,
                    static: Static,
                },
                unallocated_byte_address: union(enum) {
                    read_write_stream_resize: Dynamic,
                },
            },
            unallocated_byte_address: union(enum) {
                read_write_stream: Dynamic,
            },
        },
        undefined_byte_address: union(enum) {
            read_write_resize: union(enum) {
                // single_packed_approximate_capacity: Dynamic,
                // double_packed_approximate_capacity: Dynamic,
                static: Static,
            },
            unallocated_byte_address: union(enum) {
                read_write_resize: Dynamic,
            },
        },
        unallocated_byte_address: union(enum) {
            read_write: Dynamic,
        },
    },
    unstreamed_byte_address: union(enum) {
        undefined_byte_address: union(enum) {
            read_write_stream_resize: union(enum) { parametric: Parametric },
        },
    },
    undefined_byte_address: union(enum) {
        read_write_resize: union(enum) { parametric: Parametric },
    },
    const Automatic = union(enum) {
        structured: AutoAlignment(AutomaticStuctured),
    };
    const Static = union(enum) {
        structured: NoSuperAlignment(StructuredStatic),
        unstructured: NoSuperAlignment(UnstructuredStatic),
    };
    const Dynamic = union(enum) {
        structured: NoSuperAlignment(Structured),
        unstructured: NoSuperAlignment(Unstructured),
    };
    const Parametric = union(enum) {
        structured: NoPackedAlignment(StructuredParametric),
        unstructured: NoPackedAlignment(UnstructuredParametric),
    };
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
        Allocator: Allocator,
    };
    const Unstructured = struct {
        high_alignment: u64,
        low_alignment: in(u64) = null,
        Allocator: Allocator,
    };
    const StructuredStatic = struct {
        child: type,
        sentinel: in_out(*const anyopaque) = null,
        count: u64,
        low_alignment: in(u64) = null,
        Allocator: Allocator,
    };
    const UnstructuredStatic = struct {
        bytes: u64,
        low_alignment: in(u64) = null,
        Allocator: Allocator,
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
    pub const Mode = enum {
        read_write,
        read_write_resize,
        read_write_auto,
        read_write_resize_auto,
        read_write_stream,
        read_write_stream_resize,
        read_write_stream_auto,
        read_write_stream_resize_auto,
    };
    // For structures below named 'mutex', iterate through the structure until
    // finding an enum literal, then concatenate direct parent field names to
    // yield the name of one of the category fields. In contexts where multiple
    // names from the same substructure present, these should form a union or
    // enumeration instead of individual boolean options.
    comptime {
        // This probably costs next to nothing at compile time, but no reason to
        // compute it while the feature is not being updated.
        //for (getMutuallyExclusivePivot(Technique.mutex)) |name| {
        //    if (!@hasField(Technique, name)) {
        //        @compileError(name);
        //    }
        //}
        //for (getMutuallyExclusivePivot(Fields.mutex)) |name| {
        //    if (!@hasField(Fields, name)) {
        //        @compileError(name);
        //    }
        //}
    }
    pub const Field = struct {
        automatic_storage: bool = false,
        allocated_byte_address: bool = false,
        undefined_byte_address: bool = false,
        unallocated_byte_address: bool = false,
        unstreamed_byte_address: bool = false,
    };
    pub const Fields = union {
        automatic_storage: struct {
            ss_word: bool,
            ub_word: bool,
        },
        allocated_storage: struct {
            lb_word: bool,
            ss_word: bool,
            ub_word: bool,
            up_word: bool,
        },
        pub const mutex = .{
            .storage = .{
                .automatic,
                .allocated,
            },
        };
    };
    // This word 'disjunct' is used below instead of packed, because no packing
    // is ever needed to perform the technique. The unaligned bits can sit in
    // the lowest dead bits of the start address indefinitely.
    pub const Technique = struct {
        lazy_alignment: bool = true,
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
    const Allocator = AllocatorWithArenaIndex;
    /// Implementations with lb_word ignore the cause for distinction between
    /// packed_super- and packed_natural- alignment techniques, because doing so
    /// makes no (known) effective difference, saves around ~1000 lines in
    /// the output, and removes a logical branch from relevant specifications
    /// deductions. Possible solution: For all implementations where the
    /// difference is ineffective, do not specify whether natural, structural,
    /// or super-structural. This cost would be seen in the compilation time of
    /// implgen.
    ///
    /// Super alignment is a valid technique while allocated_byte_address is
    /// available. However it is likely sub-optimal for all variations.
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
};
fn lhs(comptime T: type, comptime U: type, lu_values: []const T, ax_values: []const U) []const T {
    const lb_addr: u64 = @intFromPtr(lu_values.ptr);
    const ab_addr: u64 = @intFromPtr(ax_values.ptr);
    const lhs_len: u64 = @divExact(ab_addr -% lb_addr, @sizeOf(T));
    return lu_values[0..lhs_len];
}
fn rhs(comptime T: type, comptime U: type, lu_values: []const T, ax_values: []const U) []const T {
    const up_addr: u64 = mach.mulAdd64(@intFromPtr(lu_values.ptr), @sizeOf(T), lu_values.len);
    const xb_addr: u64 = mach.mulAdd64(@intFromPtr(ax_values.ptr), @sizeOf(U), ax_values.len);
    const rhs_len: u64 = @divExact(up_addr -% xb_addr, @sizeOf(T));
    return lu_values[0..rhs_len];
}
fn mid(comptime T: type, comptime U: type, values: []const T) []const U {
    const lb_addr: u64 = @intFromPtr(values.ptr);
    const up_addr: u64 = mach.mulAdd64(lb_addr, @sizeOf(T), values.len);
    const ab_addr: u64 = mach.alignA64(lb_addr, @alignOf(U));
    const xb_addr: u64 = mach.alignB64(up_addr, @alignOf(U));
    const aligned_bytes: u64 = mach.sub64(xb_addr, ab_addr);
    const mid_len: u64 = mach.div64(aligned_bytes, @sizeOf(U));
    return @as([*]const U, @ptrFromInt(ab_addr))[0..mid_len];
}
fn testEqualArray(comptime T: type, comptime array_info: builtin.Type.Array, arg1: T, arg2: T) bool {
    var idx: usize = 0;
    while (idx != array_info.len) : (idx +%= 1) {
        if (!testEqual(array_info.child, arg1[idx], arg2[idx])) {
            return false;
        }
    }
    return true;
}
fn testEqualSlice(comptime T: type, comptime pointer_info: builtin.Type.Pointer, arg1: T, arg2: T) bool {
    if (arg1.len != arg2.len) {
        return false;
    }
    if (arg1.ptr == arg2.ptr) {
        return true;
    }
    var idx: usize = 0;
    while (idx != arg1.len) : (idx +%= 1) {
        if (!testEqual(pointer_info.child, arg1[idx], arg2[idx])) {
            return false;
        }
    }
    return true;
}
fn testEqualPointer(comptime T: type, comptime pointer_info: builtin.Type.Pointer, arg1: T, arg2: T) bool {
    if (@typeInfo(pointer_info.child) != .Fn) {
        return arg1 == arg2;
    }
    return false;
}
fn testIdenticalStruct(comptime T: type, comptime struct_info: builtin.Type.Struct, arg1: T, arg2: T) bool {
    if (struct_info.layout == .Packed) {
        return @as(struct_info.backing_integer.?, @bitCast(arg1)) == @as(struct_info.backing_integer.?, @bitCast(arg2));
    }
    return testEqualStruct(T, struct_info, arg1, arg2);
}
fn testEqualStruct(comptime T: type, comptime struct_info: builtin.Type.Struct, arg1: T, arg2: T) bool {
    inline for (struct_info.fields) |field| {
        if (!testEqual(
            field.type,
            @field(arg1, field.name),
            @field(arg2, field.name),
        )) {
            return false;
        }
    }
    return true;
}
fn testIdenticalUnion(comptime T: type, comptime union_info: builtin.Type.Union, arg1: T, arg2: T) bool {
    if (@inComptime()) {
        return false;
    } else {
        return testEqual(union_info.tag_type.?, arg1, arg2) and
            mem.testEqualString(
            @as(*const [@sizeOf(T)]u8, @ptrCast(&arg1)),
            @as(*const [@sizeOf(T)]u8, @ptrCast(&arg2)),
        );
    }
}
fn testEqualUnion(comptime T: type, comptime union_info: builtin.Type.Union, arg1: T, arg2: T) bool {
    if (union_info.tag_type) |tag_type| {
        if (@intFromEnum(arg1) != @intFromEnum(arg2)) {
            return false;
        }
        inline for (union_info.fields) |field| {
            if (@intFromEnum(arg1) == @intFromEnum(@field(tag_type, field.name))) {
                if (!testEqual(
                    field.type,
                    @field(arg1, field.name),
                    @field(arg2, field.name),
                )) {
                    return false;
                }
            }
        }
    }
    return testIdenticalUnion(T, union_info, arg1, arg2);
}
fn testEqualOptional(comptime T: type, comptime optional_info: builtin.Type.Optional, arg1: T, arg2: T) bool {
    if (@typeInfo(optional_info.child) == .Pointer and
        @typeInfo(optional_info.child).Pointer.size != .Slice and
        @typeInfo(optional_info.child).Pointer.size != .C)
    {
        return arg1 == arg2;
    }
    if (arg1) |child1| {
        if (arg2) |child2| {
            return testEqual(optional_info.child, child1, child2);
        } else {
            return false;
        }
    } else {
        return arg2 == null;
    }
}
pub fn testEqual(comptime T: type, arg1: T, arg2: T) bool {
    const type_info: builtin.Type = @typeInfo(T);
    switch (type_info) {
        .Array => |array_info| {
            return testEqualArray(T, array_info, arg1, arg2);
        },
        .Pointer => |pointer_info| if (pointer_info.size == .Slice) {
            return testEqualSlice(T, pointer_info, arg1, arg2);
        } else {
            return testEqualPointer(T, pointer_info, arg1, arg2);
        },
        .Optional => |optional_info| {
            return testEqualOptional(T, optional_info, arg1, arg2);
        },
        .Struct => |struct_info| {
            return testEqualStruct(T, struct_info, arg1, arg2);
        },
        .Union => |union_info| {
            return testEqualUnion(T, union_info, arg1, arg2);
        },
        .Type,
        .Void,
        .Bool,
        .Int,
        .Float,
        .ComptimeFloat,
        .ComptimeInt,
        .Null,
        .ErrorSet,
        .Enum,
        .Opaque,
        .AnyFrame,
        .EnumLiteral,
        => return arg1 == arg2,
        .Fn,
        .NoReturn,
        .ErrorUnion,
        .Frame,
        .Vector,
        .Undefined,
        => return false,
    }
    return false;
}
pub fn testEqualString(l_values: []const u8, r_values: []const u8) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (l_values.len != r_values.len) {
        return false;
    }
    if (l_values.ptr == r_values.ptr) {
        return true;
    }
    var idx: usize = 0;
    while (idx != l_values.len) {
        if (l_values[idx] != r_values[idx]) {
            return false;
        }
        idx +%= 1;
    }
    return true;
}
pub fn testEqualMany(comptime T: type, l_values: []const T, r_values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (l_values.len != r_values.len) {
        return false;
    }
    if (l_values.ptr == r_values.ptr) {
        return true;
    }
    var idx: usize = 0;
    while (idx != l_values.len) {
        if (!mem.testEqual(T, l_values[idx], r_values[idx])) {
            return false;
        }
        idx +%= 1;
    }
    return true;
}
pub fn testEqualOneFront(comptime T: type, value: T, values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (values.len != 0) {
        return values[0] == value;
    }
    return false;
}
pub fn testEqualOneBack(comptime T: type, value: T, values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (values.len != 0) {
        return values[values.len -% 1] == value;
    }
    return false;
}
pub fn testEqualManyFront(comptime T: type, prefix_values: []const T, values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (prefix_values.len == 0 or prefix_values.len > values.len) {
        return false;
    }
    return testEqualMany(T, prefix_values, values[0..prefix_values.len]);
}
pub fn testEqualManyBack(comptime T: type, suffix_values: []const T, values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (suffix_values.len == 0 or suffix_values.len > values.len) {
        return false;
    }
    return testEqualMany(T, suffix_values, values[values.len -% suffix_values.len ..]);
}
pub fn testEqualManyIn(comptime T: type, find_values: []const T, values: []const T) bool {
    @setRuntimeSafety(builtin.is_safe);
    return indexOfFirstEqualMany(T, find_values, values) != null;
}
pub fn testEqualMemory(comptime T: type, arg1: T, arg2: T) bool {
    @setRuntimeSafety(builtin.is_safe);
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Int, .Enum, .Bool, .Void => return arg1 == arg2,
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                comptime var field_type_info: builtin.Type = @typeInfo(field.type);
                if (field_type_info == .Pointer and
                    field_type_info.Pointer.size == .Many and
                    @hasField(T, field.name ++ "_len"))
                {
                    const len1: usize = @field(arg1, field.name ++ "_len");
                    const len2: usize = @field(arg2, field.name ++ "_len");
                    field_type_info.Pointer.size = .Slice;
                    if (!testEqualMemory(@Type(field_type_info), @field(arg1, field.name)[0..len1], @field(arg2, field.name)[0..len2])) {
                        return false;
                    }
                } else if (!testEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name))) {
                    return false;
                }
            }
            return true;
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                if (@as(tag_type, arg1) != @as(tag_type, arg2)) {
                    return false;
                }
                switch (arg1) {
                    inline else => |value, tag| {
                        return testEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                return testEqualMemory(optional_info.child, arg1.?, arg2.?);
            }
            return arg1 == null and arg2 == null;
        },
        .Array => |array_info| {
            return testEqualMemory([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = indexOfSentinel(arg1);
                    const len2: usize = indexOfSentinel(arg2);
                    if (len1 != len2) {
                        return false;
                    }
                    if (arg1 == arg2) {
                        return true;
                    }
                    for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                        if (!testEqualMemory(pointer_info.child, value1, value2)) {
                            return false;
                        }
                    }
                    return true;
                },
                .Slice => {
                    if (arg1.len != arg2.len) {
                        return false;
                    }
                    if (arg1.ptr == arg2.ptr) {
                        return true;
                    }
                    for (arg1, arg2) |value1, value2| {
                        if (!testEqualMemory(pointer_info.child, value1, value2)) {
                            return false;
                        }
                    }
                    return true;
                },
                else => return testEqualMemory(pointer_info.child, arg1.*, arg2.*),
            }
        },
    }
}
pub fn indexOfSentinel(any: anytype) usize {
    @setRuntimeSafety(builtin.is_safe);
    const T = @TypeOf(any);
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info.Pointer.sentinel == null) {
        @compileError(@typeName(T));
    }
    const sentinel: type_info.Pointer.child =
        @as(*const type_info.Pointer.child, @ptrCast(type_info.Pointer.sentinel.?)).*;
    var idx: usize = 0;
    while (any[idx] != sentinel) {
        idx +%= 1;
    }
    return idx;
}
pub fn indexOfFirstEqualOne(comptime T: type, value: T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    var idx: usize = 0;
    while (idx != values.len) {
        if (values[idx] == value) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfLastEqualOne(comptime T: type, value: T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    var idx: usize = values.len;
    while (idx != 0) {
        idx -%= 1;
        if (values[idx] == value) {
            return idx;
        }
    }
    return null;
}
pub fn indexOfFirstEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    if (sub_values.len > values.len) {
        return null;
    }
    const max_idx: u64 = (values.len -% sub_values.len) +% 1;
    var idx: usize = 0;
    while (idx != max_idx) {
        if (testEqualManyFront(T, sub_values, values[idx..])) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfFirstEqualAny(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    if (sub_values.len > values.len) {
        return null;
    }
    var idx: usize = 0;
    while (idx != values.len) {
        for (sub_values) |value| {
            if (values[idx] == value) {
                return idx;
            }
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfLastEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    if (sub_values.len > values.len) {
        return null;
    }
    const max_idx: u64 = (values.len -% sub_values.len) +% 1;
    var idx: usize = max_idx;
    while (idx != 0) {
        idx -%= 1;
        if (testEqualManyFront(T, sub_values, values[idx..])) {
            return idx;
        }
    }
    return null;
}
pub fn indexOfLastEqualAny(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    if (sub_values.len > values.len) {
        return null;
    }
    var idx: usize = values.len;
    while (idx != 0) {
        idx -%= 1;
        for (sub_values) |value| {
            if (values[idx] == value) {
                return idx;
            }
        }
    }
    return null;
}
pub fn readBeforeFirstEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualMany(T, sub_values, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterFirstEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualMany(T, sub_values, values)) |index| {
        return values[index +% sub_values.len ..];
    }
    return null;
}
pub fn readBeforeLastEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualMany(T, sub_values, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterLastEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualMany(T, sub_values, values)) |index| {
        return values[sub_values.len +% index ..];
    }
    return null;
}
pub fn readBeforeFirstEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualOne(T, value, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterFirstEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualOne(T, value, values)) |index| {
        return values[index +% 1 ..];
    }
    return null;
}
pub fn readBeforeLastEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualOne(T, value, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterLastEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualOne(T, value, values)) |index| {
        return values[index +% 1 ..];
    }
    return null;
}
pub fn readAfterFirstEqualManyWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    sub_values: []const T,
    values: [:sentinel]const T,
) ?[:sentinel]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualMany(T, sub_values, values)) |index| {
        return values[index +% sub_values.len ..];
    }
    return null;
}
pub fn readAfterLastEqualManyWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    sub_values: []const T,
    values: [:sentinel]const T,
) ?[:sentinel]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualMany(T, sub_values, values)) |index| {
        return values[sub_values.len +% index ..];
    }
    return null;
}
pub fn readAfterLastEqualOneWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    value: T,
    values: [:sentinel]const T,
) ?[:sentinel]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfLastEqualOne(T, value, values)) |index| {
        return values[index +% 1 ..];
    }
    return null;
}
pub fn readAfterFirstEqualOneWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    value: T,
    values: [:sentinel]const T,
) ?[:sentinel]const T {
    @setRuntimeSafety(builtin.is_safe);
    if (indexOfFirstEqualOne(T, value, values)) |index| {
        return values[index +% 1 ..];
    }
    return null;
}
pub fn readBeforeFirstEqualManyOrElse(comptime T: type, sub_values: []const T, values: []const T) []const T {
    return readBeforeFirstEqualMany(T, sub_values, values) orelse values;
}
pub fn readAfterFirstEqualManyOrElse(comptime T: type, sub_values: []const T, values: []const T) []const T {
    return readAfterFirstEqualMany(T, sub_values, values) orelse values;
}
pub fn readBeforeLastEqualManyOrElse(comptime T: type, sub_values: []const T, values: []const T) []const T {
    return readBeforeLastEqualMany(T, sub_values, values) orelse values;
}
pub fn readAfterLastEqualManyOrElse(comptime T: type, sub_values: []const T, values: []const T) []const T {
    return readAfterLastEqualMany(T, sub_values, values) orelse values;
}
pub fn readBeforeFirstEqualOneOrElse(comptime T: type, value: T, values: []const T) []const T {
    return readBeforeFirstEqualOne(T, value, values) orelse values;
}
pub fn readAfterFirstEqualOneOrElse(comptime T: type, value: T, values: []const T) []const T {
    return readAfterFirstEqualOne(T, value, values) orelse values;
}
pub fn readBeforeLastEqualOneOrElse(comptime T: type, value: T, values: []const T) []const T {
    return readBeforeLastEqualOne(T, value, values) orelse values;
}
pub fn readAfterLastEqualOneOrElse(comptime T: type, value: T, values: []const T) []const T {
    return readAfterLastEqualOne(T, value, values) orelse values;
}
pub fn readAfterFirstEqualManyOrElseWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    sub_values: []const T,
    values: [:sentinel]const T,
) [:sentinel]const T {
    return readAfterFirstEqualManyWithSentinel(T, sentinel, sub_values, values) orelse values;
}
pub fn readAfterLastEqualManyOrElseWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    sub_values: []const T,
    values: [:sentinel]const T,
) [:sentinel]const T {
    return readAfterLastEqualManyWithSentinel(T, sentinel, sub_values, values) orelse values;
}
pub fn readAfterFirstEqualOneOrElseWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    value: T,
    values: [:sentinel]const T,
) [:sentinel]const T {
    return readAfterFirstEqualOneWithSentinel(T, sentinel, value, values) orelse values;
}
pub fn readAfterLastEqualOneOrElseWithSentinel(
    comptime T: type,
    comptime sentinel: T,
    value: T,
    values: [:sentinel]const T,
) [:sentinel]const T {
    return readAfterLastEqualOneWithSentinel(T, sentinel, value, values) orelse values;
}
pub fn order(comptime T: type, l_values: []const T, r_values: []const T) math.Order {
    @setRuntimeSafety(builtin.is_safe);
    const max_idx: u64 = @min(l_values.len, r_values.len);
    var idx: usize = 0;
    while (idx != max_idx) : (idx +%= 1) {
        const o: math.Order = math.order(l_values[idx], r_values[idx]);
        if (o != .eq) {
            return o;
        }
    }
    return math.order(l_values.len, r_values.len);
}
pub fn orderedMatches(comptime T: type, l_values: []const T, r_values: []const T) u64 {
    @setRuntimeSafety(builtin.is_safe);
    const j: bool = l_values.len < r_values.len;
    const s_values: []const T = if (j) l_values else r_values;
    const t_values: []const T = if (j) r_values else l_values;
    var l_idx: u64 = 0;
    var mats: u64 = 0;
    while (l_idx +% mats < s_values.len) : (l_idx +%= 1) {
        var r_idx: u64 = 0;
        while (r_idx != t_values.len) : (r_idx +%= 1) {
            mats +%= @intFromBool(s_values[l_idx +% mats] == t_values[r_idx]);
        }
    }
    return mats;
}
pub fn editDistance(l_values: []const u8, r_values: []const u8) usize {
    @setRuntimeSafety(builtin.is_safe);
    if (l_values.len == 0) {
        return r_values.len;
    }
    if (r_values.len == 0) {
        return l_values.len;
    }
    const ll_values: []const u8 = l_values[0 .. l_values.len -% 1];
    const rr_values: []const u8 = r_values[0 .. r_values.len -% 1];
    var m_idx: usize = editDistance(ll_values, rr_values);
    if (l_values[ll_values.len] == r_values[rr_values.len]) {
        return m_idx;
    }
    const l_idx: usize = editDistance(l_values, rr_values);
    const r_idx: usize = editDistance(ll_values, r_values);
    if (m_idx > l_idx) {
        m_idx = l_idx;
    }
    if (m_idx > r_idx) {
        m_idx = r_idx;
    }
    return m_idx +% 1;
}
pub fn indexOfNearestEqualMany(comptime T: type, arg1: []const T, arg2: []const T, index: u64) ?u64 {
    @setRuntimeSafety(builtin.is_safe);
    const needle: []const u8 = if (arg1.len < arg2.len) arg1 else arg2;
    const haystack: []const u8 = if (arg1.len < arg2.len) arg2 else arg1;
    var off: u64 = 0;
    while (off != haystack.len) : (off +%= 1) {
        const below_start: u64 = index -% off;
        const above_start: u64 = index +% off;
        if (below_start < haystack.len) {
            if (testEqualManyFront(u8, needle, haystack[below_start..])) {
                return below_start;
            }
        }
        if (above_start < haystack.len) {
            if (testEqualManyFront(u8, needle, haystack[above_start..])) {
                return above_start;
            }
        }
    }
    return null;
}
pub inline fn zero(comptime T: type, ptr: *T) void {
    @memset(@as([*]u8, @ptrCast(ptr))[0..@sizeOf(T)], 0);
}
pub inline fn unstable(comptime T: type, val: T) T {
    return @as(*const volatile T, @ptrCast(&val)).*;
}
pub fn terminate(ptr: [*]const u8, comptime value: u8) [:value]u8 {
    @setRuntimeSafety(false);
    var idx: usize = 0;
    while (ptr[idx] != value) {
        idx +%= 1;
    }
    return @constCast(ptr[0..idx :value]);
}
pub const SimpleAllocator = struct {
    start: usize = 0x40000000,
    next: usize = 0x40000000,
    finish: usize = 0x40000000,
    const Allocator = @This();
    pub const min_align_of: usize = if (@hasDecl(builtin.root, "min_align_of")) builtin.root.min_align_of else 8;
    pub inline fn create(allocator: *Allocator, comptime T: type) *T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T), @max(min_align_of, @alignOf(T)));
        return @ptrFromInt(ret_addr);
    }
    pub inline fn allocate(allocator: *Allocator, comptime T: type, count: usize) []T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T) *% count, @max(min_align_of, @alignOf(T)));
        return @as([*]T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: usize) []T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.reallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), @max(min_align_of, @alignOf(T)));
        return @as([*]T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn createAligned(allocator: *Allocator, comptime T: type, comptime align_of: usize) *align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T), align_of);
        return @ptrFromInt(ret_addr);
    }
    pub inline fn allocateAligned(allocator: *Allocator, comptime T: type, count: usize, comptime align_of: usize) []align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T) *% count, align_of);
        return @as([*]align(align_of) T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn reallocateAligned(allocator: *Allocator, comptime T: type, buf: []T, count: usize, comptime align_of: usize) []align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.reallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), align_of);
        return @as([*]align(align_of) T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn destroy(allocator: *Allocator, comptime T: type, ptr: *T) void {
        allocator.deallocateRaw(@intFromPtr(ptr), @sizeOf(T));
    }
    pub inline fn deallocate(allocator: *Allocator, comptime T: type, buf: []T) void {
        allocator.deallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T));
    }
    pub inline fn save(allocator: *const Allocator) usize {
        return allocator.next;
    }
    pub inline fn restore(allocator: *Allocator, state: usize) void {
        allocator.next = state;
    }
    pub inline fn discard(allocator: *Allocator) void {
        allocator.next = allocator.start;
    }
    pub inline fn utility(allocator: *Allocator) usize {
        return allocator.next -% allocator.start;
    }
    const map_spec = .{
        .errors = .{},
        .logging = .{ .Acquire = false },
    };
    const unmap_spec = .{
        .errors = .{},
        .logging = .{ .Release = false },
    };
    pub fn unmapAll(allocator: *Allocator) void {
        mem.unmap(unmap_spec, allocator.start, allocator.finish -% allocator.start);
        allocator.next = allocator.start;
        allocator.finish = allocator.start;
    }
    pub fn init_arena(arena: mem.Arena) Allocator {
        mem.map(map_spec, .{}, .{}, arena.lb_addr, 4096);
        return .{
            .start = arena.lb_addr,
            .next = arena.lb_addr,
            .finish = arena.lb_addr +% 4096,
        };
    }
    pub fn init_buffer(buf: anytype) Allocator {
        return .{
            .start = @intFromPtr(buf.ptr),
            .next = @intFromPtr(buf.ptr),
            .finish = @intFromPtr(buf.ptr + buf.len),
        };
    }
    pub fn alignAbove(allocator: *Allocator, alignment: usize) usize {
        const mask: usize = alignment -% 1;
        return (allocator.next +% mask) & ~mask;
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
    pub fn allocateRaw(
        allocator: *Allocator,
        size_of: usize,
        align_of: usize,
    ) usize {
        @setRuntimeSafety(builtin.is_safe);
        const aligned: usize = mach.alignA64(allocator.next, align_of);
        const next: usize = aligned +% size_of;
        if (next > allocator.finish) {
            const len: usize = allocator.finish -% allocator.start;
            const finish: usize = mach.alignA64(next, @max(4096, len));
            map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
            allocator.finish = finish;
        }
        allocator.next = next;
        return aligned;
    }
    pub fn reallocateRaw(
        allocator: *Allocator,
        old_aligned: usize,
        old_size_of: usize,
        new_size_of: usize,
        align_of: usize,
    ) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (builtin.is_safe) {
            if (old_aligned > allocator.finish) {
                debug.panicAddressAboveUpperBound(old_aligned, allocator.finish);
            }
            if (old_aligned < allocator.start) {
                debug.panicAddressBelowLowerBound(old_aligned, allocator.start);
            }
        }
        const old_next: usize = old_aligned +% old_size_of;
        const new_next: usize = old_aligned +% new_size_of;
        if (allocator.next == old_next) {
            if (new_next > allocator.finish) {
                const len: usize = allocator.finish -% allocator.start;
                const finish: usize = mach.alignA64(new_next, @max(4096, len));
                map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
                allocator.finish = finish;
            }
            allocator.next = new_next;
            return old_aligned;
        }
        const new_aligned: usize = allocator.allocateRaw(new_size_of, align_of);
        mach.addrcpy(new_aligned, old_aligned, old_size_of);
        return new_aligned;
    }
    pub fn deallocateRaw(
        allocator: *Allocator,
        old_aligned: usize,
        old_size_of: usize,
    ) void {
        const old_next: usize = old_aligned +% old_size_of;
        if (allocator.next == old_next) {
            allocator.next = old_next;
        }
    }
};
pub fn GenericSimpleArray(comptime T: type) type {
    return struct {
        values: []T,
        values_len: u64,
        const Array = @This();
        const Allocator = builtin.define("Allocator", type, mem.SimpleAllocator);

        pub fn appendOne(array: *Array, allocator: *Allocator, value: T) void {
            if (array.values_len == array.values.len) {
                array.values = allocator.reallocate(T, array.values, array.values_len *% 2);
            }
            array.values[array.values_len] = value;
            array.values_len +%= 1;
        }
        pub fn appendSlice(array: *Array, allocator: *Allocator, values: []const T) void {
            if (array.values_len +% values.len > array.values.len) {
                array.values = allocator.reallocate(T, array.values, (array.values_len +% values.len) *% 2);
            }
            for (values) |value| {
                array.values[array.values_len] = value;
                array.values_len +%= 1;
            }
        }
        pub fn readAll(array: *const Array) []const T {
            return array.values[0..array.values_len];
        }
        pub fn referAll(array: *Array) []T {
            return array.values[0..array.values_len];
        }
        pub fn popOne(array: *Array) T {
            array.values_len -%= 1;
            return array.values[array.values_len];
        }
        pub fn init(allocator: *Allocator, count: u64) Array {
            return .{
                .values = allocator.allocate(T, count),
                .values_len = 0,
            };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            allocator.deallocate(T, array.values);
        }
    };
}
pub fn GenericSimpleMap(comptime Key: type, comptime Value: type) type {
    return struct {
        pairs: []*Pair,
        pairs_len: u64,
        const Array = @This();
        const Allocator = builtin.define("Allocator", type, mem.SimpleAllocator);
        const Pair = struct {
            key: Key,
            val: Value,
        };
        pub fn put(array: *Array, allocator: *Allocator, key: Key, val: Value) void {
            array.appendOne(allocator, .{ .key = key, .val = val });
        }
        pub fn get(array: *const Array, key: Key) ?Value {
            for (array.pairs) |pair| {
                if (testEqualMemory(Key, pair.key, key)) {
                    return pair.val;
                }
            }
            return null;
        }
        pub fn refer(array: *const Array, key: Key) ?*Value {
            for (array.pairs) |pair| {
                if (testEqualMemory(Key, pair.key, key)) {
                    return &pair.val;
                }
            }
            return null;
        }
        pub fn remove(array: *Array, key: Key) void {
            const end: *Pair = array.pairs[array.pairs_len -% 1];
            for (array.pairs) |*pair| {
                if (testEqualMemory(Key, pair.*.key, key)) {
                    pair.* = end;
                    array.pairs_len -%= 1;
                }
            }
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, pair: Pair) void {
            if (array.pairs_len == array.pairs.len) {
                array.pairs = allocator.reallocate(*Pair, array.pairs, array.pairs_len *% 2);
            }
            array.pairs[array.pairs_len] = allocator.create(Pair);
            array.pairs[array.pairs_len].* = pair;
            array.pairs_len +%= 1;
        }
        pub fn readAll(array: *const Array) []const *Pair {
            return array.pairs[0..array.pairs_len];
        }
        pub fn init(allocator: *Allocator, count: u64) Array {
            return .{
                .pairs = allocator.allocate(*Pair, count),
                .pairs_len = 0,
            };
        }
    };
}
pub fn GenericOptionalArrays(comptime Int: type, comptime TaggedUnion: type) type {
    const U = packed struct {
        buf: [*]Elem = @ptrFromInt(@alignOf(Elem)),
        buf_max_len: Size = 0,
        buf_len: Size = 0,
        const Im = @This();
        const ImTag = @typeInfo(TaggedUnion).Union.tag_type.?;
        const Elem = packed struct {
            addr: usize,
            max_len: Size,
            tag_len: Size,
            pub fn add(res: *Elem, allocator: *mem.SimpleAllocator, size_of: usize) usize {
                return allocator.addGenericSize(Size, size_of, 2, &res.addr, &res.max_len, res.tag_len & bit_mask);
            }
            pub fn len(res: *Elem) Size {
                return res.tag_len & bit_mask;
            }
            pub fn cast(res: *Elem, comptime tag: ImTag) []Child(tag) {
                const ptr: [*]Child(tag) = @ptrFromInt(res.addr);
                return ptr[0..res.len()];
            }
        };
        const bit_size_of: comptime_int = @bitSizeOf(@typeInfo(ImTag).Enum.tag_type);
        const shift_amt: comptime_int = @bitSizeOf(Int) - bit_size_of;
        const bit_mask: comptime_int = ~@as(Int, 0) >> bit_size_of;
        const Size = @Type(.{ .Int = .{ .bits = @max(meta.alignBitSizeAbove(bit_size_of), @bitSizeOf(Int)), .signedness = .unsigned } });
        fn Child(comptime tag: ImTag) type {
            return meta.Field(TaggedUnion, @tagName(tag));
        }
        fn sizeOf(comptime tag: ImTag) comptime_int {
            return @sizeOf(Child(tag));
        }
        fn getInternal(im: *const Im, tag: ImTag) ?*Elem {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx != im.buf_len) : (idx +%= 1) {
                if (im.buf[idx].tag_len >> shift_amt == @intFromEnum(tag)) {
                    return &im.buf[idx];
                }
            }
            return null;
        }
        fn create(im: *Im, allocator: *mem.SimpleAllocator, tag: ImTag) *Elem {
            @setRuntimeSafety(builtin.is_safe);
            const ret: *Elem = @ptrFromInt(allocator.addGenericSize(Size, @sizeOf(Elem), 1, @ptrCast(&im.buf), &im.buf_max_len, im.buf_len));
            im.buf_len +%= 1;
            ret.tag_len = @intFromEnum(tag);
            ret.tag_len = @shlExact(ret.tag_len, shift_amt);
            return ret;
        }
        pub fn set(im: *Im, allocator: *mem.SimpleAllocator, comptime tag: ImTag, val: []Child(tag)) void {
            @setRuntimeSafety(builtin.is_safe);
            const res: *Elem = im.create(allocator, tag);
            res.addr = @intFromPtr(val.ptr);
            res.max_len = @intCast(val.len);
            res.tag_len = res.max_len | (@as(Size, @intFromEnum(tag)) << shift_amt);
        }
        pub fn elem(im: *Im, allocator: *mem.SimpleAllocator, tag: ImTag) *Elem {
            return im.getInternal(tag) orelse im.create(allocator, tag);
        }
        pub fn get(im: *const Im, comptime tag: ImTag) []Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            if (im.getInternal(tag)) |res| {
                return @as([*]Child(tag), @ptrFromInt(res.addr))[0 .. res.tag_len & bit_mask];
            }
            return @constCast(&.{});
        }
        pub fn add(im: *Im, allocator: *mem.SimpleAllocator, comptime tag: ImTag) *Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            const res: *Elem = im.elem(allocator, tag);
            const ret: usize = res.add(allocator, sizeOf(tag));
            res.tag_len +%= 1;
            return @ptrFromInt(ret);
        }
    };
    return U;
}
pub fn GenericOptionals(comptime TaggedUnion: type) type {
    const U = struct {
        buf: [*]usize = @ptrFromInt(8),
        buf_max_len: usize = 0,
        buf_len: usize = 0,
        const Im = @This();
        const ImTag = @typeInfo(TaggedUnion).Union.tag_type.?;
        const bit_size_of: comptime_int = @bitSizeOf(@typeInfo(ImTag).Enum.tag_type);
        const bit_mask: comptime_int = ~@as(usize, 0) >> bit_size_of;
        const shift_amt: comptime_int = @bitSizeOf(usize) -% bit_size_of;
        fn Child(comptime tag: ImTag) type {
            return meta.Field(TaggedUnion, @tagName(tag));
        }
        fn sizeOf(comptime tag: ImTag) comptime_int {
            return @sizeOf(Child(tag));
        }
        fn getInternal(im: *Im, tag: ImTag) usize {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx != im.buf_len) : (idx +%= 1) {
                if (im.buf[idx] >> shift_amt == @intFromEnum(tag)) {
                    return im.buf[idx] & bit_mask;
                }
            }
            return 0;
        }
        fn createInternal(im: *Im, allocator: *mem.SimpleAllocator, tag: ImTag, size_of: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            const ret: usize = allocator.allocateInternal(size_of, 8);
            const addr: *usize = @ptrFromInt(allocator.addGeneric(8, 1, @ptrCast(&im.buf), &im.buf_max_len, im.buf_len));
            addr.* = ret | (@as(usize, @intFromEnum(tag)) << shift_amt);
            im.buf_len +%= 1;
            return ret;
        }
        pub fn set(im: *Im, allocator: *mem.SimpleAllocator, comptime tag: ImTag, val: Child(tag)) void {
            @setRuntimeSafety(builtin.is_safe);
            const addr: usize = im.getInternal(tag);
            const ptr: *Child(tag) = if (addr != 0) @ptrFromInt(addr) else im.add(allocator, tag);
            ptr.* = val;
        }
        pub fn get(im: *Im, comptime tag: ImTag) *Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            return @ptrFromInt(im.getInternal(tag));
        }
        pub fn add(im: *Im, allocator: *mem.SimpleAllocator, comptime tag: ImTag) *Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            return @ptrFromInt(im.createInternal(allocator, tag, sizeOf(tag)));
        }
        pub fn check(im: *Im, tag: ImTag) bool {
            return getInternal(im, tag) != 0;
        }
    };
    return U;
}
// Begin standard library ghetto:
pub fn readIntVar(comptime T: type, buf: []const u8, len: u64) T {
    @setRuntimeSafety(builtin.is_safe);
    var ret: [@sizeOf(T)]u8 = undefined;
    for (ret[@sizeOf(T) -% len ..], 0..) |*byte, idx| {
        byte.* = buf[idx];
    }
    return @bitCast(ret);
}
pub fn readIntNative(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8) T {
    return @as(*align(1) const T, @ptrCast(bytes)).*;
}
pub fn readIntForeign(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8) T {
    return @byteSwap(readIntNative(T, bytes));
}
pub const readIntLittle = switch (builtin.native_endian) {
    .Little => readIntNative,
    .Big => readIntForeign,
};
pub const readIntBig = switch (builtin.native_endian) {
    .Little => readIntForeign,
    .Big => readIntNative,
};
pub fn readInt(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8, endian: builtin.Endian) T {
    if (endian == builtin.native_endian) {
        return readIntNative(T, bytes);
    } else {
        return readIntForeign(T, bytes);
    }
}
pub fn writeIntNative(comptime T: type, buf: *[(@typeInfo(T).Int.bits + 7) / 8]u8, value: T) void {
    @as(*align(1) T, @ptrCast(buf)).* = value;
}
pub fn writeIntForeign(comptime T: type, buf: *[@divExact(@typeInfo(T).Int.bits, 8)]u8, value: T) void {
    writeIntNative(T, buf, @byteSwap(value));
}
pub const writeIntBig = switch (builtin.native_endian) {
    .Little => writeIntForeign,
    .Big => writeIntNative,
};
pub const writeIntLittle = switch (builtin.native_endian) {
    .Little => writeIntNative,
    .Big => writeIntForeign,
};
pub fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).Int.bits, 8)]u8, value: T, endian: builtin.Endian) void {
    if (endian == builtin.native_endian) {
        return writeIntNative(T, buffer, value);
    } else {
        return writeIntForeign(T, buffer, value);
    }
}
pub fn writeIntSliceLittle(comptime T: type, dest: []u8, value: T) void {
    debug.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
    if (@typeInfo(T).Int.bits == 0) {
        return @memset(dest, 0);
    } else if (@typeInfo(T).Int.bits == 8) {
        @memset(dest, 0);
        dest[0] = @as(u8, @bitCast(value));
        return;
    }
    const Int = @Type(.{ .Int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(T),
    } });
    var bits = @as(Int, @bitCast(value));
    for (dest) |*b| {
        b.* = @as(u8, @truncate(bits));
        bits >>= 8;
    }
}
pub fn writeIntSliceBig(comptime T: type, dest: []u8, value: T) void {
    debug.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
    if (@typeInfo(T).Int.bits == 0) {
        return @memset(dest, 0);
    } else if (@typeInfo(T).Int.bits == 8) {
        @memset(dest, 0);
        dest[dest.len -% 1] = @as(u8, @bitCast(value));
        return;
    }
    const Int = @Type(.{ .Int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(T),
    } });
    var bits: Int = @as(Int, @bitCast(value));
    var idx: usize = dest.len;
    while (idx != 0) {
        idx -%= 1;
        dest[idx] = @as(u8, @truncate(bits));
        bits >>= 8;
    }
}
pub const writeIntSliceNative = switch (builtin.native_endian) {
    .Little => writeIntSliceLittle,
    .Big => writeIntSliceBig,
};
pub const writeIntSliceForeign = switch (builtin.native_endian) {
    .Little => writeIntSliceBig,
    .Big => writeIntSliceLittle,
};
pub fn nativeTo(comptime T: type, x: T, desired_endianness: builtin.Endian) T {
    return switch (desired_endianness) {
        .Little => nativeToLittle(T, x),
        .Big => nativeToBig(T, x),
    };
}
pub fn littleToNative(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .Little => x,
        .Big => @byteSwap(x),
    };
}
pub fn bigToNative(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .Little => @byteSwap(x),
        .Big => x,
    };
}
pub fn toNative(comptime T: type, x: T, endianness_of_x: builtin.Endian) T {
    return switch (endianness_of_x) {
        .Little => littleToNative(T, x),
        .Big => bigToNative(T, x),
    };
}
pub fn nativeToLittle(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .Little => x,
        .Big => @byteSwap(x),
    };
}
pub fn nativeToBig(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .Little => @byteSwap(x),
        .Big => x,
    };
}
pub fn readIntSliceNative(comptime T: type, bytes: []const u8) T {
    const n = @divExact(@typeInfo(T).Int.bits, 8);
    debug.assert(bytes.len >= n);
    return readIntNative(T, bytes[0..n]);
}
pub fn readIntSliceForeign(comptime T: type, bytes: []const u8) T {
    return @byteSwap(readIntSliceNative(T, bytes));
}
pub const readIntSliceLittle = switch (builtin.native_endian) {
    .Little => readIntSliceNative,
    .Big => readIntSliceForeign,
};
pub const readIntSliceBig = switch (builtin.native_endian) {
    .Little => readIntSliceForeign,
    .Big => readIntSliceNative,
};
fn AsBytesReturnType(comptime P: type) type {
    const type_info: builtin.Type = @typeInfo(P);
    if (type_info.Pointer.size != .One) {
        @compileError("expected single item pointer, passed " ++ @typeName(P));
    }
    return @Type(.{
        .Pointer = .{
            .size = .One,
            .is_const = type_info.Pointer.is_const,
            .is_volatile = type_info.Pointer.is_volatile,
            .is_allowzero = type_info.Pointer.is_allowzero,
            .alignment = type_info.Pointer.alignment,
            .address_space = type_info.Pointer.address_space,
            .child = [@sizeOf(type_info.Pointer.child)]u8,
            .sentinel = null,
        },
    });
}
pub fn asBytes(ptr: anytype) AsBytesReturnType(@TypeOf(ptr)) {
    return @ptrCast(@alignCast(ptr));
}
pub const toBytes = meta.toBytes;
// TODO:
// SyncSpec
// MoveSpec
// FdSpec
