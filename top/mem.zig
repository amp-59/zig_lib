const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const math = @import("./math.zig");
const proc = @import("./proc.zig");
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
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();
};
pub const SyncSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.msync_errors },
    return_type: type = void,
    logging: builtin.Logging.AcquireError = .{},
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
    logging: builtin.Logging.SuccessError = .{},
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
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
};
pub const UnmapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.munmap_errors },
    return_type: type = void,
    logging: builtin.Logging.ReleaseError = .{},
    const Specification = @This();
};
pub const ProtectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.mprotect_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
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
    logging: builtin.Logging.SuccessError = .{},
};
pub const FdSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.memfd_create_errors },
    return_type: type = u64,
    logging: builtin.Logging.AcquireError = .{},
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
    count: u64,
    unit: Unit,
    pub const Unit = enum(u64) {
        EiB = 1 << 60,
        PiB = 1 << 50,
        TiB = 1 << 40,
        GiB = 1 << 30,
        MiB = 1 << 20,
        KiB = 1 << 10,
        B = 1,
        fn mask(u: Unit) u64 {
            const bits: u64 = 0b1111111111;
            return switch (u) {
                .EiB => bits << 60,
                .PiB => bits << 50,
                .TiB => bits << 40,
                .GiB => bits << 30,
                .MiB => bits << 20,
                .KiB => bits << 10,
                else => bits,
            };
        }
        pub fn to(count: u64, unit: Unit) Bytes {
            const amt: u8 = builtin.tzcnt(u64, unit.mask());
            return .{
                .count = mach.shrx64(count & unit.mask(), amt),
                .unit = unit,
            };
        }
    };
    pub fn bytes(amt: Bytes) u64 {
        return amt.count * @intFromEnum(amt.unit);
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
        return map(AddressSpace.map_spec, spec.addressable_byte_address(), spec.addressable_byte_count());
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
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireSet(AddressSpace, address_space, index)) {
        if (spec.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_acq_0_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_acq_1_s, @errorName(spec.errors.acquire.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        builtin.proc.exitFault(debug.about_acq_2_s, 2);
    }
}
pub fn acquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireStaticSet(AddressSpace, address_space, index)) {
        if (logging.Acquire) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_acq_0_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_acq_1_s, @errorName(spec.errors.acquire.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        builtin.proc.exitFault(debug.about_acq_2_s, 2);
    }
}
pub fn acquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_void {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = address_space.low();
    const up_addr: u64 = address_space.high();
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireElementarySet(AddressSpace, address_space)) {
        if (logging.Acquire) {
            debug.arenaAcquireNotice(null, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_acq_1_s, @errorName(spec.errors.acquire.throw), null, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        builtin.proc.exitFault(debug.about_acq_2_s, 2);
    }
}
pub fn release(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_void {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: builtin.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    if (releaseUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_rel_0_s, index, lb_addr, up_addr, spec.label);
        }
        if (spec.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_rel_1_s, @errorName(spec.errors.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        builtin.proc.exitFault(debug.about_rel_2_s, 2);
    }
}
pub fn releaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: builtin.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    if (releaseStaticUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_rel_0_s, index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_rel_1_s, @errorName(spec.errors.throw), index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        builtin.proc.exitFault(debug.about_rel_2_s, 2);
    }
}
pub fn releaseElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.release_void {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = address_space.low();
    const up_addr: u64 = address_space.high();
    if (releaseElementaryUnset(AddressSpace, address_space)) {
        if (spec.logging.release.Release) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_rel_0_s, null, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (spec.logging.release.Error) {
            debug.aboutIndexLbAddrUpAddrLabelError(debug.about_rel_1_s, @errorName(spec.errors.throw), null, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        builtin.proc.exitFault(debug.about_rel_2_s, 2);
    }
}
pub fn testAcquire(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.acquire_bool {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireSet(AddressSpace, address_space, index);
    if (ret) {
        if (spec.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_acq_0_s, index, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testAcquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_bool(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime AddressSpace.low(index);
    const up_addr: u64 = comptime AddressSpace.high(index);
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireStaticSet(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Acquire) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_acq_0_s, index, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testAcquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_bool {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = comptime address_space.low();
    const up_addr: u64 = comptime address_space.high();
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    const ret: bool = acquireElementarySet(AddressSpace, address_space);
    if (ret) {
        if (logging.Acquire) {
            debug.aboutIndexLbAddrUpAddrLabelNotice(debug.about_acq_0_s, null, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn testRelease(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_bool {
    const spec: mem.RegularAddressSpaceSpec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: builtin.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    const ret: bool = releaseUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            debug.arenaReleaseNotice(index, lb_addr, up_addr, spec.label);
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
    const logging: builtin.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    const ret: bool = releaseStaticUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            debug.arenaReleaseNotice(index, lb_addr, up_addr, spec.label);
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
            debug.arenaReleaseNotice(null, lb_addr, up_addr, spec.label);
        }
    }
    return ret;
}
pub fn map(comptime spec: MapSpec, flags: Map.Flags, prot: Map.Protection, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mmap, spec.errors, spec.return_type, .{
        addr, len, @as(usize, @bitCast(prot)), @as(usize, @bitCast(flags)), ~@as(u64, 0), 0,
    }))) |ret| {
        if (logging.Acquire) {
            debug.mapNotice(addr, len);
        }
        if (spec.return_type != void) {
            return ret;
        }
    } else |map_error| {
        if (logging.Error) {
            debug.mapError(map_error, addr, len);
        }
        return map_error;
    }
}
pub fn sync(comptime sync_spec: SyncSpec, addr: u64, len: u64) sys.ErrorUnion(sync_spec.errors, sync_spec.return_type) {
    const msync_flags: Sync.Options = comptime sync_spec.flags();
    const logging: builtin.Logging.AcquireError = comptime sync_spec.logging.override();
    if (meta.wrap(sys.call(.sync, sync_spec.errors, sync_spec.return_type, .{ addr, len, msync_flags.val }))) |ret| {
        if (logging.Acquire) {
            debug.syncNotice(addr, len);
        }
        if (sync_spec.return_type != void) {
            return ret;
        }
    } else |sync_error| {
        if (logging.Error) {
            debug.syncError(sync_error, addr, len);
        }
        return sync_error;
    }
}
pub fn move(comptime spec: MoveSpec, old_addr: u64, old_len: u64, new_addr: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const mremap_flags: Remap.Options = comptime spec.flags();
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mremap, spec.errors, spec.return_type, .{ old_addr, old_len, old_len, mremap_flags.val, new_addr }))) {
        if (logging.Success) {
            debug.aboutRemapNotice(debug.about_remap_0_s, old_addr, old_len, new_addr, null);
        }
    } else |mremap_error| {
        if (logging.Error) {
            debug.remapError(mremap_error, old_addr, old_len, new_addr, null);
        }
        return mremap_error;
    }
}
pub fn resize(comptime spec: RemapSpec, old_addr: u64, old_len: u64, new_len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mremap, spec.errors, spec.return_type, .{ old_addr, old_len, new_len, 0, 0 }))) {
        if (logging.Success) {
            debug.aboutRemapNotice(debug.about_resize_0_s, old_addr, old_len, null, new_len);
        }
    } else |mremap_error| {
        if (logging.Error) {
            debug.remapError(mremap_error, old_addr, old_len, null, new_len);
        }
        return mremap_error;
    }
}
pub fn unmap(comptime spec: UnmapSpec, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.ReleaseError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.munmap, spec.errors, spec.return_type, .{ addr, len }))) {
        if (logging.Release) {
            debug.unmapNotice(addr, len);
        }
    } else |unmap_error| {
        if (logging.Error) {
            debug.unmapError(unmap_error, addr, len);
        }
        return unmap_error;
    }
}
pub fn protect(comptime spec: ProtectSpec, prot: ProtectSpec.Protection, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mprotect, spec.errors, spec.return_type, .{ addr, len, @as(usize, @bitCast(prot)) }))) {
        if (logging.Success) {
            debug.protectNotice(addr, len, "<description>");
        }
    } else |protect_error| {
        if (logging.Error) {
            debug.protectError(protect_error, addr, len, "<description>");
        }
        return protect_error;
    }
}
pub fn advise(comptime spec: AdviseSpec, advice: Advice, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.madvise, spec.errors, spec.return_type, .{ addr, len, @intFromEnum(advice) }))) {
        if (logging.Success) {
            debug.adviseNotice(addr, len, advice.describe());
        }
    } else |madvise_error| {
        if (logging.Error) {
            debug.adviseError(madvise_error, addr, len, advice.describe());
        }
        return madvise_error;
    }
}
pub fn fd(comptime spec: FdSpec, name: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @intFromPtr(name.ptr);
    const flags: mem.Fd.Options = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.memfd_create, spec.errors, spec.return_type, .{ name_buf_addr, flags.val }))) |mem_fd| {
        if (logging.Acquire) {
            mem.debug.memFdNotice(name, mem_fd);
        }
        return mem_fd;
    } else |memfd_create_error| {
        if (logging.Error) {
            mem.debug.memFdError(memfd_create_error, name);
        }
        return memfd_create_error;
    }
}
pub const debug = opaque {
    const about_map_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("map");
    const about_acq_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("acq");
    const about_acq_1_s: builtin.fmt.AboutSrc = builtin.fmt.about("acq-error");
    const about_rel_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("rel");
    const about_rel_1_s: builtin.fmt.AboutSrc = builtin.fmt.about("rel-error");
    const about_acq_2_s: builtin.fmt.AboutSrc = builtin.fmt.about("acq-fault\n");
    const about_rel_2_s: builtin.fmt.AboutSrc = builtin.fmt.about("rel-fault\n");
    const about_unmap_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("unmap");
    const about_remap_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("remap");
    const about_memfd_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("memfd");
    const about_resize_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("resize");
    const about_advice_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("advice");
    const about_protect_0_s: builtin.fmt.AboutSrc = builtin.fmt.about("protect");
    pub fn mapNotice(addr: u64, len: u64) void {
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_map_0_s, start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    pub fn unmapNotice(addr: u64, len: u64) void {
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_unmap_0_s, start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    fn protectNotice(addr: u64, len: u64, description_s: []const u8) void {
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_protect_0_s, start_s, "..", finish_s, ", ", len_s, " bytes, ", description_s, "\n" });
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_advice_0_s, start_s, "..", finish_s, ", ", len_s, " bytes, ", description_s, "\n" });
    }
    pub fn aboutRemapNotice(about_s: builtin.fmt.AboutSrc, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const old_start_s: []const u8 = builtin.fmt.ux64(old_addr).readAll();
        const old_finish_s: []const u8 = builtin.fmt.ux64(old_addr +% old_len).readAll();
        const new_start_s: []const u8 = builtin.fmt.ux64(new_addr).readAll();
        const new_finish_s: []const u8 = builtin.fmt.ux64(new_addr +% new_len).readAll();
        const diff_s: []const u8 = builtin.fmt.ud64(abs_diff).readAll();
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_s, old_start_s, "..", old_finish_s, " -> ", new_start_s, "..", new_finish_s, notation_s, diff_s, " bytes\n" });
    }
    fn aboutIndexLbAddrUpAddrLabelNotice(about_s: builtin.fmt.AboutSrc, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        const index_s: []const u8 = builtin.fmt.ud64(index orelse 0).readAll();
        const start_s: []const u8 = builtin.fmt.ux64(lb_addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(up_addr).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(up_addr -% lb_addr).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_s, label orelse "arena", "-", index_s, ", ", start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    fn aboutIndexLbAddrUpAddrLabelError(about_s: builtin.fmt.AboutSrc, error_name: [:0]const u8, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        @setCold(true);
        const index_s: []const u8 = builtin.fmt.ud64(index orelse 0).readAll();
        const start_s: []const u8 = builtin.fmt.ux64(lb_addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(up_addr).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(up_addr -% lb_addr).readAll();
        var buf: [4096 + 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_s, builtin.debug.about_error_s, error_name, ", ", label orelse "arena", "-", index_s, ", ", start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    fn memFdNotice(name: [:0]const u8, mem_fd: u64) void {
        var buf: [4096 + 32]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_memfd_0_s, "fd=", builtin.fmt.ud64(mem_fd).readAll(), ", ", name, "\n" });
    }
    pub fn mapError(map_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_map_0_s, builtin.debug.about_error_s, @errorName(map_error), ", ", start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    pub fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_unmap_0_s, builtin.debug.about_error_s, @errorName(unmap_error), ", ", start_s, "..", finish_s, ", ", len_s, " bytes\n" });
    }
    fn protectError(protect_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        @setCold(true);
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_protect_0_s, builtin.debug.about_error_s, @errorName(protect_error), ", ", start_s, "..", finish_s, ", ", len_s, " bytes, ", description_s, "\n" });
    }
    fn adviseError(advise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        @setCold(true);
        const start_s: []const u8 = builtin.fmt.ux64(addr).readAll();
        const finish_s: []const u8 = builtin.fmt.ux64(addr +% len).readAll();
        const len_s: []const u8 = builtin.fmt.ud64(len).readAll();
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_advice_0_s, builtin.debug.about_error_s, @errorName(advise_error), ", ", start_s, "..", finish_s, ", ", len_s, " bytes, ", description_s, "\n" });
    }
    fn remapError(mremap_err: anytype, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setCold(true);
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const operation_s: []const u8 = mach.cmovx(new_addr != old_addr, about_remap_0_s, about_resize_0_s);
        const old_start_s: []const u8 = builtin.fmt.ux64(old_addr).readAll();
        const old_finish_s: []const u8 = builtin.fmt.ux64(old_addr +% old_len).readAll();
        const new_start_s: []const u8 = builtin.fmt.ux64(new_addr).readAll();
        const new_finish_s: []const u8 = builtin.fmt.ux64(new_addr +% new_len).readAll();
        const diff_s: []const u8 = builtin.fmt.ud64(abs_diff).readAll();
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ operation_s, builtin.debug.about_error_s, @errorName(mremap_err), ", ", old_start_s, "..", old_finish_s, " -> ", new_start_s, "..", new_finish_s, notation_s, diff_s, " bytes\n" });
    }
    fn memFdError(memfd_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_memfd_0_s, builtin.debug.about_error_s, @errorName(memfd_error), ", ", pathname, "\n" });
    }
    pub fn sampleAllReports() void {
        const about_s: builtin.fmt.AboutSrc = comptime builtin.fmt.about("about");
        const name1: [:0]const u8 = "name";
        const pathname1: [:0]const u8 = "/path/to/file1";
        const fd1: u32 = 8;
        const addr1: u64 = 4096;
        const len1: u64 = 4096;
        const addr2: u64 = 8192;
        const len2: u64 = 8192;
        mapNotice(addr1, len1);
        unmapNotice(addr1, len1);
        protectNotice(addr1, len1, "<missing>");
        adviseNotice(addr1, len1, "<missing>");
        aboutRemapNotice(about_s, addr1, len1, addr2, len2);
        memFdNotice(name1, fd1);
        mapError(error.MapError, addr1, len1);
        unmapError(error.UnmapError, addr1, len1);
        protectError(error.ProtectError, addr1, len1, "<missing>");
        adviseError(error.AdviseError, addr1, len1, "<missing>");
        remapError(error.RemapError, addr1, len1, addr2, len2);
        memFdError(error.MemFdError, pathname1);
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
// These should be in builtin.zig, but cannot adhere to the test-error-fault
// standard yet--that is, their assert* and expect* counterparts cannot be added
// to builtin--so they are here temporarily as utility functions.
//
// TODO: Move the following functions to builtin, and create aliases with common
// names. e.g. `startsWith` instead of `testEqualManyFront`.
pub fn testEqualMany(comptime T: type, l_values: []const T, r_values: []const T) bool {
    if (l_values.len != r_values.len) {
        return false;
    }
    if (l_values.ptr == r_values.ptr) {
        return true;
    }
    var idx: u64 = 0;
    while (idx != l_values.len) {
        if (!builtin.testEqual(T, l_values[idx], r_values[idx])) return false;
        idx +%= 1;
    }
    return true;
}
pub fn testEqualOneFront(comptime T: type, value: T, values: []const T) bool {
    if (values.len != 0) {
        return values[0] == value;
    }
    return false;
}
pub fn testEqualOneBack(comptime T: type, value: T, values: []const T) bool {
    if (values.len != 0) {
        return values[values.len -% 1] == value;
    }
    return false;
}
pub fn testEqualManyFront(comptime T: type, prefix_values: []const T, values: []const T) bool {
    if (prefix_values.len == 0 or prefix_values.len > values.len) {
        return false;
    }
    return testEqualMany(T, prefix_values, values[0..prefix_values.len]);
}
pub fn testEqualManyBack(comptime T: type, suffix_values: []const T, values: []const T) bool {
    if (suffix_values.len == 0 or suffix_values.len > values.len) {
        return false;
    }
    return testEqualMany(T, suffix_values, values[values.len -% suffix_values.len ..]);
}
pub fn testEqualManyIn(comptime T: type, find_values: []const T, values: []const T) bool {
    return indexOfFirstEqualMany(T, find_values, values) != null;
}
pub fn indexOfFirstEqualOne(comptime T: type, value: T, values: []const T) ?u64 {
    var idx: u64 = 0;
    while (idx != values.len) {
        if (values[idx] == value) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfLastEqualOne(comptime T: type, value: T, values: []const T) ?u64 {
    var idx: u64 = values.len;
    while (idx != 0) {
        idx -%= 1;
        if (values[idx] == value) {
            return idx;
        }
    }
    return null;
}
pub fn indexOfFirstEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    if (sub_values.len > values.len) {
        return null;
    }
    const max_idx: u64 = (values.len -% sub_values.len) +% 1;
    var idx: u64 = 0;
    while (idx != max_idx) {
        if (testEqualManyFront(T, sub_values, values[idx..])) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfFirstEqualAny(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    if (sub_values.len > values.len) {
        return null;
    }
    var idx: u64 = 0;
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
    if (sub_values.len > values.len) {
        return null;
    }
    const max_idx: u64 = (values.len -% sub_values.len) +% 1;
    var idx: u64 = max_idx;
    while (idx != 0) {
        idx -%= 1;
        if (testEqualManyFront(T, sub_values, values[idx..])) {
            return idx;
        }
    }
    return null;
}
pub fn indexOfLastEqualAny(comptime T: type, sub_values: []const T, values: []const T) ?u64 {
    if (sub_values.len > values.len) {
        return null;
    }
    var idx: u64 = values.len;
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
    if (indexOfFirstEqualMany(T, sub_values, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterFirstEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    if (indexOfFirstEqualMany(T, sub_values, values)) |index| {
        return values[index +% sub_values.len ..];
    }
    return null;
}
pub fn readBeforeLastEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    if (indexOfLastEqualMany(T, sub_values, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterLastEqualMany(comptime T: type, sub_values: []const T, values: []const T) ?[]const T {
    if (indexOfLastEqualMany(T, sub_values, values)) |index| {
        return values[sub_values.len +% index ..];
    }
    return null;
}
pub fn readBeforeFirstEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    if (indexOfFirstEqualOne(T, value, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterFirstEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    if (indexOfFirstEqualOne(T, value, values)) |index| {
        return values[index +% 1 ..];
    }
    return null;
}
pub fn readBeforeLastEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
    if (indexOfLastEqualOne(T, value, values)) |index| {
        return values[0..index];
    }
    return null;
}
pub fn readAfterLastEqualOne(comptime T: type, value: T, values: []const T) ?[]const T {
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
    const max_idx: u64 = @min(l_values.len, r_values.len);
    var idx: u64 = 0;
    while (idx != max_idx) : (idx += 1) {
        const o: math.Order = math.order(l_values[idx], r_values[idx]);
        if (o != .eq) {
            return o;
        }
    }
    return math.order(l_values.len, r_values.len);
}
pub fn orderedMatches(comptime T: type, l_values: []const T, r_values: []const T) u64 {
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
pub fn indexOfNearestEqualMany(comptime T: type, arg1: []const T, arg2: []const T, index: u64) ?u64 {
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
    mach.memset(@as([*]u8, @ptrCast(ptr)), 0, @sizeOf(T));
}
pub const SimpleAllocator = struct {
    start: u64 = 0x40000000,
    next: u64 = 0x40000000,
    finish: u64 = 0x40000000,
    const Allocator = @This();
    pub const Save = struct { u64 };
    pub const min_align_of: u64 = if (@hasDecl(builtin.root, "min_align_of")) builtin.root.min_align_of else 8;
    pub inline fn create(allocator: *Allocator, comptime T: type) *T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T), @max(min_align_of, @alignOf(T)));
        return @as(*T, @ptrFromInt(ret_addr));
    }
    pub inline fn allocate(allocator: *Allocator, comptime T: type, count: u64) []T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T) *% count, @max(min_align_of, @alignOf(T)));
        return @as([*]T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: u64) []T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.reallocateInternal(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), @max(min_align_of, @alignOf(T)));
        return @as([*]T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn createAligned(allocator: *Allocator, comptime T: type, comptime align_of: u64) *align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T), align_of);
        return @as(*align(align_of) T, @ptrFromInt(ret_addr));
    }
    pub inline fn allocateAligned(allocator: *Allocator, comptime T: type, count: u64, comptime align_of: u64) []align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T) *% count, align_of);
        return @as([*]align(align_of) T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn reallocateAligned(allocator: *Allocator, comptime T: type, buf: []T, count: u64, comptime align_of: u64) []align(align_of) T {
        @setRuntimeSafety(false);
        const ret_addr: u64 = allocator.reallocateInternal(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), align_of);
        return @as([*]align(align_of) T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn destroy(allocator: *Allocator, comptime T: type, ptr: *T) void {
        allocator.deallocateInternal(@intFromPtr(ptr), @sizeOf(T));
    }
    pub inline fn deallocate(allocator: *Allocator, comptime T: type, buf: []T) void {
        allocator.deallocateInternal(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T));
    }
    pub inline fn save(allocator: *const Allocator) Save {
        return .{allocator.next};
    }
    pub inline fn restore(allocator: *Allocator, state: Save) void {
        allocator.next = state[0];
    }
    pub inline fn discard(allocator: *Allocator) void {
        allocator.next = allocator.start;
    }
    pub inline fn utility(allocator: *Allocator) u64 {
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
    pub fn unmap(allocator: *Allocator) void {
        mem.unmap(unmap_spec, allocator.start, allocator.finish - allocator.start);
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
    pub inline fn alignAbove(allocator: *Allocator, alignment: u64) u64 {
        const mask: u64 = alignment -% 1;
        return (allocator.next +% mask) & ~mask;
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
    pub const allocateRaw = allocateInternal;
    pub const reallocateRaw = reallocateInternal;
    pub const deallocateRaw = deallocateInternal;
    fn allocateInternal(
        allocator: *Allocator,
        size_of: u64,
        align_of: u64,
    ) u64 {
        const aligned: u64 = mach.alignA64(allocator.next, align_of);
        const next: u64 = aligned +% size_of;
        if (next > allocator.finish) {
            const len: u64 = allocator.finish -% allocator.start;
            const finish: u64 = mach.alignA64(next, @max(4096, len));
            map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
            allocator.finish = finish;
        }
        allocator.next = next;
        return aligned;
    }
    fn reallocateInternal(
        allocator: *Allocator,
        old_aligned: u64,
        old_size_of: u64,
        new_size_of: u64,
        align_of: u64,
    ) u64 {
        const old_next: u64 = old_aligned +% old_size_of;
        const new_next: u64 = old_aligned +% new_size_of;
        if (allocator.next == old_next) {
            if (new_next > allocator.finish) {
                const len: u64 = allocator.finish -% allocator.start;
                const finish: u64 = mach.alignA64(new_next, @max(4096, len));
                map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
                allocator.finish = finish;
            }
            allocator.next = new_next;
            return old_aligned;
        }
        const new_aligned: u64 = allocator.allocateInternal(new_size_of, align_of);
        mach.addrcpy(new_aligned, old_aligned, old_size_of);
        return new_aligned;
    }
    fn deallocateInternal(
        allocator: *Allocator,
        old_aligned: u64,
        old_size_of: u64,
    ) void {
        const old_next: u64 = old_aligned +% old_size_of;
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
                if (builtin.testEqualMemory(Key, pair.key, key)) {
                    return pair.val;
                }
            }
            return null;
        }
        pub fn refer(array: *const Array, key: Key) ?*Value {
            for (array.pairs) |pair| {
                if (builtin.testEqualMemory(Key, pair.key, key)) {
                    return &pair.val;
                }
            }
            return null;
        }
        pub fn remove(array: *Array, key: Key) void {
            const end: *Pair = array.pairs[array.pairs_len -% 1];
            for (array.pairs) |*pair| {
                if (builtin.testEqualMemory(Key, pair.*.key, key)) {
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
    builtin.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
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
    builtin.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
    if (@typeInfo(T).Int.bits == 0) {
        return @memset(dest, 0);
    } else if (@typeInfo(T).Int.bits == 8) {
        @memset(dest, 0);
        dest[dest.len - 1] = @as(u8, @bitCast(value));
        return;
    }
    const Int = @Type(.{ .Int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(T),
    } });
    var bits: Int = @as(Int, @bitCast(value));
    var index: u64 = dest.len;
    while (index != 0) {
        index -= 1;
        dest[index] = @as(u8, @truncate(bits));
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
    builtin.assert(bytes.len >= n);
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
