const sys = @import("sys.zig");
const fmt = @import("fmt.zig");
const meta = @import("meta.zig");
const bits = @import("bits.zig");
const math = @import("math.zig");
const proc = @import("proc.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
pub const namespace = @This();
pub const list = @import("list.zig");
pub const array = @import("array.zig");
pub const pointer = @import("pointer.zig");
pub const dynamic = @import("dynamic.zig");
pub const word_bit_size: comptime_int = @bitSizeOf(usize);
pub const @"undefined": usize = 12297829382473034410;
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
pub const MapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mmap.errors.all },
    return_type: type = void,
    logging: debug.Logging.AcquireErrorFault = .{},
};
pub const SyncSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.msync.errors.all },
    return_type: type = void,
    logging: debug.Logging.AcquireError = .{},
};
pub const MoveSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mremap.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const RemapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mremap.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const UnmapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.munmap.errors.all },
    return_type: type = void,
    logging: debug.Logging.ReleaseError = .{},
};
pub const ProtectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mprotect.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const AdviseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.madvise.errors.all },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
};
pub const FdSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.memfd_create.errors.all },
    return_type: type = u64,
    logging: debug.Logging.AcquireError = .{},
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
fn acquireMap(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.map_void {
    if (address_space.set(AddressSpace.specification.divisions)) {
        return map(AddressSpace.map_spec, .{}, .{}, AddressSpace.specification.addressable_byte_address(), AddressSpace.specification.addressable_byte_count());
    }
}
fn releaseUnmap(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.unmap_void {
    if (address_space.count() == 0 and
        address_space.unset(AddressSpace.specification.divisions))
    {
        return unmap(AddressSpace.unmap_spec, AddressSpace.specification.addressable_byte_address(), AddressSpace.specification.addressable_byte_count());
    }
}
fn acquireSet(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) bool {
    if (AddressSpace.specification.options.thread_safe) {
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
    if (comptime AddressSpace.specification.options.thread_safe) {
        return address_space.atomicSet();
    } else {
        return address_space.set();
    }
}
fn releaseUnset(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) bool {
    if (AddressSpace.specification.options.thread_safe) {
        return address_space.atomicUnset(index);
    } else {
        return address_space.unset(index);
    }
}
inline fn releaseStaticUnset(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) bool {
    if (comptime AddressSpace.arena(index).options.thread_safe) {
        return address_space.atomicUnset(index);
    } else {
        return address_space.unset(index);
    }
}
fn releaseElementaryUnset(comptime AddressSpace: type, address_space: *AddressSpace) bool {
    if (comptime AddressSpace.specification.options.thread_safe) {
        return address_space.atomicUnset();
    } else {
        return address_space.unset();
    }
}
pub fn acquire(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.acquire_void {
    const lb_addr: usize = AddressSpace.low(index);
    const up_addr: usize = AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    if (acquireSet(AddressSpace, address_space, index)) {
        if (AddressSpace.specification.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    } else if (AddressSpace.specification.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(AddressSpace.specification.errors.acquire.throw), index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.acquire.throw;
    } else if (AddressSpace.specification.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn acquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_void(index) {
    const lb_addr: usize = comptime AddressSpace.low(index);
    const up_addr: usize = comptime AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    if (acquireStaticSet(AddressSpace, address_space, index)) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    } else if (AddressSpace.specification.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(AddressSpace.specification.errors.acquire.throw), index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.acquire.throw;
    } else if (AddressSpace.specification.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn acquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_void {
    const lb_addr: usize = address_space.low();
    const up_addr: usize = address_space.high();
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    if (acquireElementarySet(AddressSpace, address_space)) {
        if (logging.Acquire) {
            about.arenaAcquireNotice(null, lb_addr, up_addr, AddressSpace.specification.label);
        }
    } else if (AddressSpace.specification.errors.acquire == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.acq_s, @errorName(AddressSpace.specification.errors.acquire.throw), null, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.acquire.throw;
    } else if (AddressSpace.specification.errors.acquire == .abort) {
        proc.exitFault(about.acq_2_s, 2);
    }
}
pub fn release(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_void {
    const lb_addr: usize = AddressSpace.low(index);
    const up_addr: usize = AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime AddressSpace.specification.logging.release.override();
    if (releaseUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        if (AddressSpace.specification.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    } else if (AddressSpace.specification.errors.release == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(AddressSpace.specification.errors.throw), index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.release.throw;
    } else if (AddressSpace.specification.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn releaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_void(index) {
    const lb_addr: usize = comptime AddressSpace.low(index);
    const up_addr: usize = comptime AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime AddressSpace.specification.logging.release.override();
    if (releaseStaticUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    } else if (AddressSpace.specification.errors.release == .throw) {
        if (logging.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(AddressSpace.specification.errors.throw), index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.release.throw;
    } else if (AddressSpace.specification.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn releaseElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.release_void {
    const lb_addr: usize = address_space.low();
    const up_addr: usize = address_space.high();
    if (releaseElementaryUnset(AddressSpace, address_space)) {
        if (AddressSpace.specification.logging.release.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, null, lb_addr, up_addr, AddressSpace.specification.label);
        }
    } else if (AddressSpace.specification.errors.release == .throw) {
        if (AddressSpace.specification.logging.release.Error) {
            about.aboutIndexLbAddrUpAddrLabelError(about.rel_1_s, @errorName(AddressSpace.specification.errors.throw), null, lb_addr, up_addr, AddressSpace.specification.label);
        }
        return AddressSpace.specification.errors.release.throw;
    } else if (AddressSpace.specification.errors.release == .abort) {
        proc.exitFault(about.rel_2_s, 2);
    }
}
pub fn testAcquire(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.acquire_bool {
    const lb_addr: usize = AddressSpace.low(index);
    const up_addr: usize = AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    const ret: bool = acquireSet(AddressSpace, address_space, index);
    if (ret) {
        if (AddressSpace.specification.options.require_map) {
            try meta.wrap(acquireMap(AddressSpace, address_space));
        }
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    }
    return ret;
}
pub fn testAcquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_bool(index) {
    const lb_addr: usize = comptime AddressSpace.low(index);
    const up_addr: usize = comptime AddressSpace.high(index);
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    const ret: bool = acquireStaticSet(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    }
    return ret;
}
pub fn testAcquireElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.acquire_bool {
    const lb_addr: usize = comptime address_space.low();
    const up_addr: usize = comptime address_space.high();
    const logging: debug.Logging.AcquireErrorFault = comptime AddressSpace.specification.logging.acquire.override();
    const ret: bool = acquireElementarySet(AddressSpace, address_space);
    if (ret) {
        if (logging.Acquire) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.acq_s, null, lb_addr, up_addr, AddressSpace.specification.label);
        }
    }
    return ret;
}
pub fn testRelease(comptime AddressSpace: type, address_space: *AddressSpace, index: AddressSpace.Index) AddressSpace.release_bool {
    const lb_addr: usize = AddressSpace.low(index);
    const up_addr: usize = AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime AddressSpace.specification.logging.release.override();
    const ret: bool = releaseUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
        if (AddressSpace.specification.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    }
    return ret;
}
pub fn tryReleaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_bool(index) {
    const lb_addr: usize = comptime AddressSpace.low(index);
    const up_addr: usize = comptime AddressSpace.high(index);
    const logging: debug.Logging.ReleaseErrorFault = comptime AddressSpace.specification.logging.release.override();
    const ret: bool = releaseStaticUnset(AddressSpace, address_space, index);
    if (ret) {
        if (logging.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, index, lb_addr, up_addr, AddressSpace.specification.label);
        }
    }
    return ret;
}
pub fn testReleaseElementary(comptime AddressSpace: type, address_space: *AddressSpace) AddressSpace.release_bool {
    const lb_addr: usize = comptime address_space.low();
    const up_addr: usize = comptime address_space.high();
    const ret: bool = releaseElementaryUnset(AddressSpace, address_space);
    if (ret) {
        if (AddressSpace.specification.logging.release.Release) {
            about.aboutIndexLbAddrUpAddrLabelNotice(about.rel_s, null, lb_addr, up_addr, AddressSpace.specification.label);
        }
    }
    return ret;
}
pub fn map(
    comptime map_spec: MapSpec,
    prot: sys.flags.MemProt,
    flags: sys.flags.MemMap,
    addr: usize,
    len: usize,
) sys.ErrorUnion(map_spec.errors, map_spec.return_type) {
    const logging: debug.Logging.AcquireErrorFault = comptime map_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #mmap
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.mmap)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (prot),
          [_] "{r10}" (flags),
          [_] "{r8}" (18446744073709551615),
          [_] "{r9}" (0),
        : "memory", "rcx", "r11"
    );
    if (map_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.throw, ret) catch |map_error| {
            if (logging.Error) {
                about.aboutAddrLenFlagsError(about.map_s, @errorName(map_error), addr, len, flags);
            }
            return map_error;
        };
    }
    if (map_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.abort, ret) catch |map_error| {
            if (logging.Fault) {
                about.aboutAddrLenFlagsError(about.map_s, @errorName(map_error), addr, len, flags);
            }
            proc.exitError(map_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutAddrLenFlagsNotice(about.map_s, addr, len, flags);
    }
    if (map_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub fn sync(comptime sync_spec: SyncSpec, flags: sys.flags.MemSync, addr: usize, len: usize) sys.ErrorUnion(sync_spec.errors, sync_spec.return_type) {
    const logging: debug.Logging.AcquireError = comptime sync_spec.logging.override();
    if (meta.wrap(sys.call(.sync, sync_spec.errors, sync_spec.return_type, .{ addr, len, @bitCast(flags) }))) |ret| {
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
pub fn move(comptime move_spec: MoveSpec, flags: sys.flags.Remap, old_addr: usize, old_len: usize, new_addr: usize) sys.ErrorUnion(move_spec.errors, move_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime move_spec.logging.override();
    if (meta.wrap(sys.call(.mremap, move_spec.errors, move_spec.return_type, .{ old_addr, old_len, old_len, @bitCast(flags), new_addr }))) {
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
pub fn resize(comptime resize_spec: RemapSpec, old_addr: usize, old_len: usize, new_len: usize) sys.ErrorUnion(resize_spec.errors, resize_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime resize_spec.logging.override();
    if (meta.wrap(sys.call(.mremap, resize_spec.errors, resize_spec.return_type, .{ old_addr, old_len, new_len, 0, 0 }))) {
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
pub fn unmap(comptime unmap_spec: UnmapSpec, addr: usize, len: usize) sys.ErrorUnion(unmap_spec.errors, unmap_spec.return_type) {
    @setRuntimeSafety(builtin.is_safe);
    const logging: debug.Logging.ReleaseError = comptime unmap_spec.logging.override();
    const ret: isize = asm volatile ("syscall # munmap"
        : [ret] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.munmap)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
        : "rcx", "r11", "memory"
    );
    if (unmap_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, unmap_spec.errors.throw, ret) catch |munmap_error| {
            if (logging.Error) {
                about.aboutAddrLenError(about.unmap_s, @errorName(munmap_error), addr, len);
            }
            return munmap_error;
        };
    }
    if (unmap_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, unmap_spec.errors.abort, ret) catch |munmap_error| {
            if (logging.Error) {
                about.aboutAddrLenError(about.unmap_s, @errorName(munmap_error), addr, len);
            }
            proc.exitError(munmap_error, 2);
        };
    }
    if (logging.Release) {
        about.aboutAddrLenNotice(about.unmap_s, addr, len);
    }
    if (unmap_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub fn protect(comptime protect_spec: ProtectSpec, prot: sys.flags.MemProt, addr: usize, len: usize) sys.ErrorUnion(protect_spec.errors, protect_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime protect_spec.logging.override();
    if (meta.wrap(sys.call(.mprotect, protect_spec.errors, protect_spec.return_type, .{ addr, len, @as(usize, @bitCast(prot)) }))) {
        if (logging.Success) {
            about.aboutAddrLenMemProtNotice(about.protect_s, addr, len, prot);
        }
    } else |protect_error| {
        if (logging.Error) {
            about.aboutAddrLenMemProtError(about.protect_s, @errorName(protect_error), addr, len, prot);
        }
        return protect_error;
    }
}
pub fn advise(comptime advise_spec: AdviseSpec, advice: Advice, addr: usize, len: usize) sys.ErrorUnion(advise_spec.errors, advise_spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime advise_spec.logging.override();
    if (meta.wrap(sys.call(.madvise, advise_spec.errors, advise_spec.return_type, .{ addr, len, @intFromEnum(advice) }))) {
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
pub fn fd(comptime fd_spec: FdSpec, flags: sys.flags.MemFd, name: [:0]const u8) sys.ErrorUnion(fd_spec.errors, fd_spec.return_type) {
    const name_buf_addr: usize = @intFromPtr(name.ptr);
    const logging: debug.Logging.AcquireError = comptime fd_spec.logging.override();
    if (meta.wrap(sys.call(.memfd_create, fd_spec.errors, fd_spec.return_type, .{ name_buf_addr, @bitCast(flags) }))) |mem_fd| {
        if (logging.Acquire) {
            about.aboutMemFdPathnameNotice(about.memfd_s, mem_fd, name);
        }
        return mem_fd;
    } else |memfd_create_error| {
        if (logging.Error) {
            about.aboutPathnameError(about.memfd_s, @errorName(memfd_create_error), name);
        }
        return memfd_create_error;
    }
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
    const lb_addr: usize = @intFromPtr(lu_values.ptr);
    const ab_addr: usize = @intFromPtr(ax_values.ptr);
    const lhs_len: usize = @divExact(ab_addr -% lb_addr, @sizeOf(T));
    return lu_values[0..lhs_len];
}
fn rhs(comptime T: type, comptime U: type, lu_values: []const T, ax_values: []const U) []const T {
    const up_addr: usize = math.mulAdd64(@intFromPtr(lu_values.ptr), @sizeOf(T), lu_values.len);
    const xb_addr: usize = math.mulAdd64(@intFromPtr(ax_values.ptr), @sizeOf(U), ax_values.len);
    const rhs_len: usize = @divExact(up_addr -% xb_addr, @sizeOf(T));
    return lu_values[0..rhs_len];
}
fn mid(comptime T: type, comptime U: type, values: []const T) []const U {
    const lb_addr: usize = @intFromPtr(values.ptr);
    const up_addr: usize = math.mulAdd64(lb_addr, @sizeOf(T), values.len);
    const ab_addr: usize = bits.alignA64(lb_addr, @alignOf(U));
    const xb_addr: usize = bits.alignB64(up_addr, @alignOf(U));
    const aligned_bytes: usize = math.sub64(xb_addr, ab_addr);
    const mid_len: usize = math.div64(aligned_bytes, @sizeOf(U));
    return @as([*]const U, @ptrFromInt(ab_addr))[0..mid_len];
}
inline fn testEqualArray(comptime T: type, comptime array_info: builtin.Type.Array, arg1: T, arg2: T) bool {
    if (builtin.requireComptime(T)) comptime {
        var idx: usize = 0;
        while (idx != array_info.len) : (idx +%= 1) {
            if (!testEqual(array_info.child, arg1[idx], arg2[idx])) {
                return false;
            }
        }
    } else {
        var idx: usize = 0;
        while (idx != array_info.len) : (idx +%= 1) {
            if (!testEqual(array_info.child, arg1[idx], arg2[idx])) {
                return false;
            }
        }
    }
    return true;
}
inline fn testEqualSlice(comptime T: type, comptime pointer_info: builtin.Type.Pointer, arg1: T, arg2: T) bool {
    if (arg1.len != arg2.len) {
        return false;
    }
    if (arg1.ptr == arg2.ptr) {
        return true;
    }
    if (builtin.requireComptime(T)) comptime {
        var idx: usize = 0;
        while (idx != arg1.len) : (idx +%= 1) {
            if (!testEqual(pointer_info.child, arg1[idx], arg2[idx])) {
                return false;
            }
        }
    } else {
        var idx: usize = 0;
        while (idx != arg1.len) : (idx +%= 1) {
            if (!testEqual(pointer_info.child, arg1[idx], arg2[idx])) {
                return false;
            }
        }
    }
    return true;
}
inline fn testEqualPointer(comptime T: type, comptime pointer_info: builtin.Type.Pointer, arg1: T, arg2: T) bool {
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
inline fn testEqualStruct(comptime T: type, comptime struct_info: builtin.Type.Struct, arg1: T, arg2: T) bool {
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
            testEqualString(
            @as(*const [@sizeOf(T)]u8, @ptrCast(&arg1)),
            @as(*const [@sizeOf(T)]u8, @ptrCast(&arg2)),
        );
    }
}
inline fn testEqualUnion(comptime T: type, comptime union_info: builtin.Type.Union, arg1: T, arg2: T) bool {
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
inline fn testEqualOptional(comptime T: type, comptime optional_info: builtin.Type.Optional, arg1: T, arg2: T) bool {
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
        if (!testEqual(T, l_values[idx], r_values[idx])) {
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
            if (@typeInfo(pointer_info.child) == .Fn) {
                return arg1 == arg2;
            }
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
pub fn sequentialDifference(values1: []const u8, values2: []const u8) usize {
    return @max(values1.len, values2.len) -% sequentialMatches(values1, values2);
}
pub fn sequentialMatches(values1: []const u8, values2: []const u8) usize {
    @setRuntimeSafety(builtin.is_safe);
    var idx1: usize = 0;
    var idx2: usize = 0;
    var mats: usize = 0;
    while (true) {
        if (@intFromBool(idx1 == values1.len) &
            @intFromBool(idx2 == values2.len) != 0)
        {
            return mats;
        }
        if (values1[idx1] == values2[idx2]) {
            idx1 +%= 1;
            idx2 +%= 1;
            mats +%= 1;
        } else if ((values1.len -% idx1) > (values2.len -% idx2)) {
            idx1 +%= 1;
        } else if ((values2.len -% idx2) > (values1.len -% idx1)) {
            idx2 +%= 1;
        } else {
            idx1 +%= 1;
            idx2 +%= 1;
        }
    }
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
pub const addrcpy = builtin.addrcpy;
pub const addrset = builtin.addrset;
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
    pub inline fn create(allocator: *Allocator, comptime T: type) *T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T), @alignOf(T));
        return @ptrFromInt(ret_addr);
    }
    pub inline fn allocate(allocator: *Allocator, comptime T: type, count: usize) []T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.allocateRaw(@sizeOf(T) *% count, @alignOf(T));
        return @as([*]T, @ptrFromInt(ret_addr))[0..count];
    }
    pub inline fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: usize) []T {
        @setRuntimeSafety(false);
        const ret_addr: usize = allocator.reallocateRaw(@intFromPtr(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), @alignOf(T));
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
    pub inline fn add(allocator: *Allocator, comptime T: type, buf: *[*]T, buf_max_len: *usize, buf_len: usize) *T {
        @setRuntimeSafety(false);
        return @ptrFromInt(allocator.addGeneric(@sizeOf(T), @alignOf(T), 1, @ptrCast(buf), buf_max_len, buf_len));
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
        unmap(unmap_spec, allocator.start, allocator.finish -% allocator.start);
        allocator.next = allocator.start;
        allocator.finish = allocator.start;
    }
    pub fn fromArena(arena: Arena) Allocator {
        map(map_spec, .{}, .{}, arena.lb_addr, 4096);
        return .{
            .start = arena.lb_addr,
            .next = arena.lb_addr,
            .finish = arena.lb_addr +% 4096,
        };
    }
    pub fn fromBuffer(buf: anytype) Allocator {
        return .{
            .start = @intFromPtr(buf.ptr),
            .next = @intFromPtr(buf.ptr),
            .finish = @intFromPtr(buf.ptr + @sizeOf(meta.Child(@TypeOf(buf)))),
        };
    }
    pub fn addGeneric(allocator: *Allocator, size: usize, alignment: usize, init_len: usize, ptr: *usize, max_len: *usize, len: usize) usize {
        @setRuntimeSafety(builtin.is_safe);
        const new_max_len: usize = len +% 2;
        if (max_len.* == 0) {
            ptr.* = allocateRaw(allocator, size *% init_len, alignment);
            max_len.* = init_len;
        } else if (len == max_len.*) {
            ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, alignment);
            max_len.* = new_max_len;
        }
        return ptr.* +% (size *% len);
    }
    pub fn addGenericSize(allocator: *Allocator, comptime Size: type, size: usize, alignment: usize, init_len: Size, ptr: *usize, max_len: *Size, len: Size) usize {
        @setRuntimeSafety(builtin.is_safe);
        const new_max_len: Size = len +% 2;
        if (max_len.* == 0) {
            ptr.* = allocateRaw(allocator, size *% init_len, alignment);
            max_len.* = init_len;
        } else if (len == max_len.*) {
            ptr.* = reallocateRaw(allocator, ptr.*, size *% max_len.*, size *% new_max_len, alignment);
            max_len.* = new_max_len;
        }
        return ptr.* +% (size *% len);
    }
    pub fn allocateAtomic(
        allocator: *Allocator,
        size_of: usize,
        align_of: usize,
    ) usize {
        @setRuntimeSafety(builtin.is_safe);
        const ret: usize = @atomicRmw(usize, &allocator.next, .Add, size_of +% align_of, .SeqCst);
        if (allocator.next > allocator.finish) {
            const len: usize = allocator.finish -% allocator.start;
            const finish: usize = bits.alignA64(allocator.next, @max(4096, len));
            map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
            allocator.finish = finish;
        }
        return bits.alignA64(ret, align_of);
    }
    pub fn allocateRaw(
        allocator: *Allocator,
        size_of: usize,
        align_of: usize,
    ) usize {
        @setRuntimeSafety(builtin.is_safe);
        const aligned: usize = bits.alignA64(allocator.next, align_of);
        const next: usize = aligned +% size_of;
        if (next > allocator.finish) {
            const len: usize = allocator.finish -% allocator.start;
            const finish: usize = bits.alignA64(next, @max(4096, len));
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
                debug.panic_extra.panicAddressAboveUpperBound(old_aligned, allocator.finish);
            }
            if (old_aligned < allocator.start) {
                debug.panic_extra.panicAddressBelowLowerBound(old_aligned, allocator.start);
            }
        }
        const old_next: usize = old_aligned +% old_size_of;
        const new_next: usize = old_aligned +% new_size_of;
        if (allocator.next == old_next) {
            if (new_next > allocator.finish) {
                const len: usize = allocator.finish -% allocator.start;
                const finish: usize = bits.alignA64(new_next, @max(4096, len));
                map(map_spec, .{}, .{}, allocator.finish, finish -% allocator.finish);
                allocator.finish = finish;
            }
            allocator.next = new_next;
            return old_aligned;
        }
        const new_aligned: usize = allocator.allocateRaw(new_size_of, align_of);
        addrcpy(new_aligned, old_aligned, old_size_of);
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
pub fn GenericOptionalArrays(comptime Allocator: type, comptime Int: type, comptime TaggedUnion: type) type {
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
            pub fn len(res: *Elem) Size {
                return res.tag_len & bit_mask;
            }
            pub fn add(res: *Elem, allocator: *Allocator, size_of: usize) usize {
                return allocator.addGenericSize(Size, size_of, 8, 2, &res.addr, &res.max_len, res.tag_len & bit_mask);
            }
            pub fn at(res: *Elem, comptime tag: ImTag, index: usize) *Child(tag) {
                return @ptrFromInt(res.addr +% (index *% @sizeOf(Child(tag))));
            }
            pub fn cast(res: *Elem, comptime tag: ImTag) [*]Child(tag) {
                return @as([*]Child(tag), @ptrFromInt(res.addr));
            }
        };
        const bit_size_of: comptime_int = @bitSizeOf(@typeInfo(ImTag).Enum.tag_type);
        const shift_amt: comptime_int = @bitSizeOf(Int) - bit_size_of;
        const bit_mask: comptime_int = ~@as(Int, 0) >> bit_size_of;
        const Size = @Type(.{ .Int = .{ .bits = @max(meta.alignRealBitSizeAbove(bit_size_of), @bitSizeOf(Int)), .signedness = .unsigned } });
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
        pub fn create(im: *Im, allocator: *Allocator, tag: ImTag) *Elem {
            @setRuntimeSafety(builtin.is_safe);
            const ret: *Elem = @ptrFromInt(allocator.addGenericSize(Size, @sizeOf(Elem), 8, 1, @ptrCast(&im.buf), &im.buf_max_len, im.buf_len));
            im.buf_len +%= 1;
            ret.tag_len = @intFromEnum(tag);
            ret.tag_len = @shlExact(ret.tag_len, shift_amt);
            return ret;
        }
        pub fn set(im: *Im, allocator: *Allocator, comptime tag: ImTag, val: []Child(tag)) void {
            @setRuntimeSafety(builtin.is_safe);
            const res: *Elem = im.create(allocator, tag);
            res.addr = @intFromPtr(val.ptr);
            res.max_len = @intCast(val.len);
            res.tag_len = res.max_len | (@as(Size, @intFromEnum(tag)) << shift_amt);
        }
        pub fn elem(im: *Im, allocator: *Allocator, tag: ImTag) *Elem {
            return im.getInternal(tag) orelse im.create(allocator, tag);
        }
        pub fn get(im: *const Im, comptime tag: ImTag) []Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            if (im.getInternal(tag)) |res| {
                return @as([*]Child(tag), @ptrFromInt(res.addr))[0 .. res.tag_len & bit_mask];
            }
            return @constCast(&.{});
        }
        pub fn add(im: *Im, allocator: *Allocator, comptime tag: ImTag) *Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            const res: *Elem = im.elem(allocator, tag);
            const ret: usize = res.add(allocator, sizeOf(tag));
            res.tag_len +%= 1;
            return @ptrFromInt(ret);
        }
    };
    return U;
}
pub fn GenericOptionals(comptime Allocator: type, comptime TaggedUnion: type) type {
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
        fn getInternal(im: *const Im, tag: ImTag) usize {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx != im.buf_len) : (idx +%= 1) {
                if (im.buf[idx] >> shift_amt == @intFromEnum(tag)) {
                    return im.buf[idx] & bit_mask;
                }
            }
            return 0;
        }
        fn createInternal(im: *Im, allocator: *Allocator, tag: ImTag, size_of: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            const ret: usize = allocator.allocateRaw(size_of, 8);
            const addr: *usize = @ptrFromInt(allocator.addGeneric(8, @alignOf(TaggedUnion), 1, @ptrCast(&im.buf), &im.buf_max_len, im.buf_len));
            addr.* = ret | (@as(usize, @intFromEnum(tag)) << shift_amt);
            im.buf_len +%= 1;
            return ret;
        }
        pub fn set(im: *Im, allocator: *Allocator, comptime tag: ImTag, val: Child(tag)) void {
            @setRuntimeSafety(builtin.is_safe);
            const addr: usize = im.getInternal(tag);
            const ptr: *Child(tag) = if (addr != 0) @ptrFromInt(addr) else im.add(allocator, tag);
            ptr.* = val;
        }
        pub fn get(im: *const Im, comptime tag: ImTag) *Child(tag) {
            @setRuntimeSafety(builtin.is_safe);
            return @ptrFromInt(im.getInternal(tag));
        }
        pub fn add(im: *Im, allocator: *Allocator, comptime tag: ImTag) *Child(tag) {
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
pub fn readIntVar(comptime T: type, buf: []const u8, len: usize) T {
    @setRuntimeSafety(builtin.is_safe);
    var ret: [@sizeOf(T)]u8 = .{0} ** @sizeOf(T);
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
    .little => readIntNative,
    .big => readIntForeign,
};
pub const readIntBig = switch (builtin.native_endian) {
    .little => readIntForeign,
    .big => readIntNative,
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
    .little => writeIntForeign,
    .big => writeIntNative,
};
pub const writeIntLittle = switch (builtin.native_endian) {
    .little => writeIntNative,
    .big => writeIntForeign,
};
pub fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).Int.bits, 8)]u8, value: T, endian: builtin.Endian) void {
    if (endian == builtin.native_endian) {
        return writeIntNative(T, buffer, value);
    } else {
        return writeIntForeign(T, buffer, value);
    }
}
pub fn writeIntSliceLittle(comptime T: type, dest: []u8, value: T) void {
    if (builtin.runtime_assertions) {
        debug.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
    }
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
    var bit_count: Int = @as(Int, @bitCast(value));
    for (dest) |*b| {
        b.* = @as(u8, @truncate(bit_count));
        bit_count >>= 8;
    }
}
pub fn writeIntSliceBig(comptime T: type, dest: []u8, value: T) void {
    if (builtin.runtime_assertions) {
        debug.assert(dest.len >= @divExact(@typeInfo(T).Int.bits, 8));
    }
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
    var bit_count: Int = @as(Int, @bitCast(value));
    var idx: usize = dest.len;
    while (idx != 0) {
        idx -%= 1;
        dest[idx] = @as(u8, @truncate(bits));
        bit_count >>= 8;
    }
}
pub const writeIntSliceNative = switch (builtin.native_endian) {
    .little => writeIntSliceLittle,
    .big => writeIntSliceBig,
};
pub const writeIntSliceForeign = switch (builtin.native_endian) {
    .little => writeIntSliceBig,
    .big => writeIntSliceLittle,
};
pub fn nativeTo(comptime T: type, x: T, desired_endianness: builtin.Endian) T {
    return switch (desired_endianness) {
        .little => nativeToLittle(T, x),
        .big => nativeToBig(T, x),
    };
}
pub fn littleToNative(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .little => x,
        .big => @byteSwap(x),
    };
}
pub fn bigToNative(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .little => @byteSwap(x),
        .big => x,
    };
}
pub fn toNative(comptime T: type, x: T, endianness_of_x: builtin.Endian) T {
    return switch (endianness_of_x) {
        .little => littleToNative(T, x),
        .big => bigToNative(T, x),
    };
}
pub fn nativeToLittle(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .little => x,
        .big => @byteSwap(x),
    };
}
pub fn nativeToBig(comptime T: type, x: T) T {
    return switch (builtin.native_endian) {
        .little => @byteSwap(x),
        .big => x,
    };
}
pub fn readIntSliceNative(comptime T: type, bytes: []const u8) T {
    const n = @divExact(@typeInfo(T).Int.bits, 8);
    if (builtin.runtime_assertions) {
        debug.assert(bytes.len >= n);
    }
    return readIntNative(T, bytes[0..n]);
}
pub fn readIntSliceForeign(comptime T: type, bytes: []const u8) T {
    return @byteSwap(readIntSliceNative(T, bytes));
}
pub const readIntSliceLittle = switch (builtin.native_endian) {
    .little => readIntSliceNative,
    .big => readIntSliceForeign,
};
pub const readIntSliceBig = switch (builtin.native_endian) {
    .little => readIntSliceForeign,
    .big => readIntSliceNative,
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
pub const ResourceError = error{ UnderSupply, OverSupply };
pub const ResourceErrorPolicy = builtin.InternalError(ResourceError);
pub const RegularAddressSpaceSpec = RegularMultiArena;
pub const DiscreteAddressSpaceSpec = DiscreteMultiArena;
pub fn DiscreteBitSet(comptime elements: u16, comptime value_type: type, comptime index_type: type) type {
    const val_bit_size_of: u16 = @bitSizeOf(value_type);
    if (val_bit_size_of != 1) {
        @compileError("not yet implemented");
    }
    const bit_size_of: u16 = elements * val_bit_size_of;
    const data_type: type = meta.UniformData(bit_size_of);
    const data_info: builtin.Type = @typeInfo(data_type);
    const idx_info: builtin.Type = @typeInfo(index_type);
    if (data_info == .Array and idx_info != .Enum) {
        return extern struct {
            bits: data_type = [1]u64{0} ** data_info.Array.len,
            pub const BitSet: type = @This();
            const Word: type = data_info.Array.child;
            const Shift: type = builtin.ShiftAmount(Word);
            pub fn get(bit_set: *const BitSet, index: index_type) value_type {
                @setRuntimeSafety(builtin.is_safe);
                return bit_set.bits[index / word_bit_size] & (@as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size))) != 0;
            }
            pub fn set(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits[index / word_bit_size] |= @as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size));
            }
            pub fn unset(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits[index / word_bit_size] &= ~(@as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size)));
            }
        };
    } else if (data_info == .Int and idx_info != .Enum) {
        return extern struct {
            bits: data_type = 0,
            pub const BitSet: type = @This();
            const Word: type = data_type;
            const Shift: type = builtin.ShiftAmount(Word);
            pub fn get(bit_set: *const BitSet, index: index_type) value_type {
                @setRuntimeSafety(builtin.is_safe);
                return bit_set.bits & (@as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% index)) != 0;
            }
            pub fn set(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits |= @as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% index);
            }
            pub fn unset(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits &= ~(@as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% index));
            }
        };
    } else if (data_info == .Array and idx_info == .Enum) {
        return extern struct {
            bits: data_type = [1]u64{0} ** data_info.Array.len,
            pub const BitSet: type = @This();
            const Word: type = data_info.Array.child;
            const Shift: type = builtin.ShiftAmount(Word);
            pub fn get(bit_set: *const BitSet, index: index_type) value_type {
                @setRuntimeSafety(builtin.is_safe);
                return bit_set.bits[index / word_bit_size] & (@as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size))) != 0;
            }
            pub fn set(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits[index / word_bit_size] |= @as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size));
            }
            pub fn unset(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits[index / word_bit_size] &= ~(@as(Word, 1) << @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size)));
            }
        };
    } else if (data_info == .Int and idx_info == .Enum) {
        return extern struct {
            bits: data_type = 0,
            pub const BitSet: type = @This();
            const Word: type = data_type;
            const Shift: type = builtin.ShiftAmount(Word);
            pub fn get(bit_set: *const BitSet, index: index_type) value_type {
                @setRuntimeSafety(builtin.is_safe);
                return bit_set.bits & (@as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% @intFromEnum(index))) != 0;
            }
            pub fn set(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits |= @as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% @intFromEnum(index));
            }
            pub fn unset(bit_set: *BitSet, index: index_type) void {
                @setRuntimeSafety(builtin.is_safe);
                bit_set.bits &= ~(@as(Word, 1) << @intCast((data_info.Int.bits -% 1) -% @intFromEnum(index)));
            }
        };
    }
}
fn ThreadSafeSetBoolInt(comptime elements: u16, comptime index_type: type) type {
    return extern struct {
        bytes: [elements]u8 align(8) = builtin.zero([elements]u8),
        pub const SafeSet: type = @This();
        const Int = @Type(.{ .Int = .{ .bits = 8 *% elements, .signedness = .unsigned } });
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *const SafeSet, index: index_type) bool {
            @setRuntimeSafety(false);
            return safe_set.bytes[index] != 0;
        }
        pub fn set(safe_set: *SafeSet, index: index_type) void {
            @setRuntimeSafety(false);
            safe_set.bytes[index] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: index_type) void {
            @setRuntimeSafety(false);
            safe_set.bytes[index] = 0;
        }
        pub inline fn atomicSet(safe_set: *SafeSet, index: index_type) bool {
            @setRuntimeSafety(false);
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 0, 255, .SeqCst, .SeqCst) == null;
        }
        pub inline fn atomicUnset(safe_set: *SafeSet, index: index_type) bool {
            @setRuntimeSafety(false);
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 255, 0, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: index_type) *u32 {
            @setRuntimeSafety(false);
            return @as(*u32, @ptrFromInt(bits.alignB64(@intFromPtr(&safe_set.bytes[index]), 4)));
        }
        pub fn int(safe_set: *const SafeSet) *const Int {
            @setRuntimeSafety(false);
            return @ptrCast(safe_set);
        }
    };
}
fn ThreadSafeSetBoolEnum(comptime elements: u16, comptime index_type: type) type {
    return extern struct {
        bytes: [elements]u8 align(8) = builtin.zero([elements]u8),
        pub const SafeSet: type = @This();
        const Int = @Type(.{ .Int = .{ .bits = 8 *% elements, .signedness = .unsigned } });
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *const SafeSet, index: index_type) bool {
            return safe_set.bytes[@intFromEnum(index)] != 0;
        }
        pub fn set(safe_set: *SafeSet, index: index_type) void {
            safe_set.bytes[@intFromEnum(index)] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: index_type) void {
            safe_set.bytes[@intFromEnum(index)] = 0;
        }
        pub fn atomicSet(safe_set: *SafeSet, index: index_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 0, 255, .SeqCst, .SeqCst) == null;
        }
        pub fn atomicUnset(safe_set: *SafeSet, index: index_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 255, 0, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: index_type) *u32 {
            return @as(*u32, @ptrFromInt(bits.alignB64(@intFromPtr(&safe_set.bytes[@intFromEnum(index)]), 4)));
        }
        pub fn int(safe_set: *const SafeSet) *const Int {
            return @ptrCast(safe_set);
        }
    };
}
fn ThreadSafeSetEnumInt(comptime elements: u16, comptime value_type: type, comptime index_type: type) type {
    return extern struct {
        bytes: [elements]value_type align(8) = builtin.zero([elements]value_type),
        pub const SafeSet: type = @This();
        const Int = @Type(.{ .Int = .{ .bits = 8 *% elements, .signedness = .unsigned } });
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *const SafeSet, index: index_type) value_type {
            return safe_set.bytes[index];
        }
        pub fn set(safe_set: *SafeSet, index: index_type, to: value_type) void {
            safe_set.bytes[index] = to;
        }
        pub fn atomicExchange(safe_set: *SafeSet, index: index_type, if_state: value_type, to_state: value_type) bool {
            return @cmpxchgStrong(value_type, &safe_set.bytes[index], if_state, to_state, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: index_type) *u32 {
            return @as(*u32, @ptrFromInt(bits.alignB64(@intFromPtr(&safe_set.bytes[index]), 4)));
        }
        pub fn int(safe_set: *const SafeSet) *const Int {
            return @ptrCast(safe_set);
        }
    };
}
fn ThreadSafeSetEnumEnum(comptime elements: u16, comptime value_type: type, comptime index_type: type) type {
    return extern struct {
        bytes: [elements]value_type align(8) = builtin.zero([elements]value_type),
        pub const SafeSet: type = @This();
        const Int = @Type(.{ .Int = .{ .bits = 8 *% elements, .signedness = .unsigned } });
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *const SafeSet, index: index_type) value_type {
            @setRuntimeSafety(false);
            return safe_set.bytes[@intFromEnum(index)];
        }
        pub fn set(safe_set: *SafeSet, index: index_type, to: value_type) void {
            @setRuntimeSafety(false);
            safe_set.bytes[@intFromEnum(index)] = to;
        }
        pub fn exchange(safe_set: *SafeSet, index: index_type, if_state: value_type, to_state: value_type) bool {
            const ret: bool = safe_set.get(index) == if_state;
            if (ret) safe_set.bytes[@intFromEnum(index)] = to_state;
            return ret;
        }
        pub fn atomicExchange(safe_set: *SafeSet, index: index_type, if_state: value_type, to_state: value_type) callconv(.C) bool {
            @setRuntimeSafety(false);
            return @cmpxchgStrong(value_type, &safe_set.bytes[@intFromEnum(index)], if_state, to_state, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: index_type) *u32 {
            @setRuntimeSafety(false);
            return @as(*u32, @ptrFromInt(bits.alignB64(@intFromPtr(&safe_set.bytes[@intFromEnum(index)]), 4)));
        }
        pub fn int(safe_set: *const SafeSet) *const Int {
            @setRuntimeSafety(false);
            return @ptrCast(safe_set);
        }
    };
}
pub fn ThreadSafeSet(comptime elements: u16, comptime value_type: type, comptime index_type: type) type {
    const idx_info: builtin.Type = @typeInfo(index_type);
    if (value_type == bool and idx_info != .Enum) {
        return ThreadSafeSetBoolInt(elements, index_type);
    } else if (value_type == bool and idx_info == .Enum) {
        return ThreadSafeSetBoolEnum(elements, index_type);
    } else if (value_type != bool and idx_info != .Enum) {
        return ThreadSafeSetEnumInt(elements, value_type, index_type);
    } else if (value_type != bool and idx_info == .Enum) {
        return ThreadSafeSetEnumEnum(elements, value_type, index_type);
    }
}
fn GenericMultiSet(
    comptime addr_spec: DiscreteAddressSpaceSpec,
    comptime directory: anytype,
    comptime Fields: type,
) type {
    const T = struct {
        fields: Fields = .{},
        pub const MultiSet: type = @This();
        inline fn arenaIndex(comptime index: addr_spec.index_type) addr_spec.index_type {
            if (@typeInfo(addr_spec.index_type) == .Enum) {
                comptime return @as(addr_spec.index_type, @enumFromInt(directory[@intFromEnum(index)].arena_index));
            } else {
                comptime return directory[index].arena_index;
            }
        }
        inline fn fieldName(comptime index: addr_spec.index_type) []const u8 {
            if (@typeInfo(addr_spec.index_type) == .Enum) {
                comptime return directory[@intFromEnum(index)].field_name;
            } else {
                comptime return directory[index].field_name;
            }
        }
        pub inline fn get(multi_set: *const MultiSet, comptime index: addr_spec.index_type) addr_spec.value_type {
            return @field(multi_set.fields, fieldName(index)).get(arenaIndex(index));
        }
        pub inline fn set(multi_set: *MultiSet, comptime index: addr_spec.index_type) void {
            @field(multi_set.fields, fieldName(index)).set(arenaIndex(index));
        }
        pub fn exchange(
            multi_set: *MultiSet,
            comptime index: addr_spec.index_type,
            if_state: addr_spec.value_type,
            to_state: addr_spec.value_type,
        ) bool {
            return @field(multi_set.fields, fieldName(index)).exchange(arenaIndex(index), if_state, to_state);
        }
        pub fn unset(multi_set: *MultiSet, comptime index: addr_spec.index_type) void {
            @field(multi_set.fields, fieldName(index)).unset(arenaIndex(index));
        }
        pub inline fn atomicSet(multi_set: *MultiSet, comptime index: addr_spec.index_type) bool {
            return @field(multi_set.fields, fieldName(index)).atomicSet(arenaIndex(index));
        }
        pub inline fn atomicUnset(multi_set: *MultiSet, comptime index: addr_spec.index_type) bool {
            return @field(multi_set.fields, fieldName(index)).atomicUnset(arenaIndex(index));
        }
        pub fn atomicExchange(
            multi_set: *MultiSet,
            comptime index: addr_spec.index_type,
            if_state: addr_spec.value_type,
            to_state: addr_spec.value_type,
        ) bool {
            return @field(multi_set.fields, fieldName(index)).atomicExchange(arenaIndex(index), if_state, to_state);
        }
    };
    return T;
}
pub fn Intersection(comptime A: type) type {
    return extern struct { l: A, x: A, h: A };
}
pub fn bounds(any: anytype) Bounds {
    return .{
        .lb_addr = @intFromPtr(any.ptr),
        .up_addr = @intFromPtr(any.ptr) +% any.len,
    };
}
pub fn intersection2(comptime A: type, s_arena: A, t_arena: A) ?Intersection(A) {
    @setRuntimeSafety(false);
    if (intersection(A, s_arena, t_arena)) |x_arena| {
        return .{
            .l = if (@hasField(A, "options")) .{
                .lb_addr = @min(t_arena.lb_addr, s_arena.lb_addr),
                .up_addr = x_arena.lb_addr,
                .options = if (s_arena.lb_addr < t_arena.lb_addr)
                    s_arena.options
                else
                    t_arena.options,
            } else .{
                .lb_addr = @min(t_arena.lb_addr, s_arena.lb_addr),
                .up_addr = x_arena.lb_addr,
            },
            .x = x_arena,
            .h = if (@hasField(A, "options")) .{
                .lb_addr = x_arena.up_addr,
                .up_addr = @max(s_arena.up_addr, t_arena.up_addr),
                .options = if (t_arena.up_addr > s_arena.up_addr)
                    t_arena.options
                else
                    s_arena.options,
            } else .{
                .lb_addr = x_arena.up_addr,
                .up_addr = @max(s_arena.up_addr, t_arena.up_addr),
            },
        };
    }
    return null;
}
pub fn intersection(comptime A: type, s_arena: Arena, t_arena: Arena) ?A {
    @setRuntimeSafety(false);
    if (@intFromBool(t_arena.up_addr -% 1 < s_arena.lb_addr) |
        @intFromBool(s_arena.up_addr -% 1 < t_arena.lb_addr) != 0)
    {
        return null;
    }
    return if (@hasField(A, "options")) .{
        .lb_addr = @max(s_arena.lb_addr, t_arena.lb_addr),
        .up_addr = @min(s_arena.up_addr, t_arena.up_addr),
        .options = .{
            .thread_safe = builtin.int2v(
                bool,
                s_arena.options.thread_safe,
                t_arena.options.thread_safe,
            ),
        },
    } else .{
        .lb_addr = @max(s_arena.lb_addr, t_arena.lb_addr),
        .up_addr = @min(s_arena.up_addr, t_arena.up_addr),
    };
}
pub const Bounds = extern struct {
    lb_addr: usize,
    up_addr: usize,
};
pub const Vector = extern struct {
    addr: usize,
    len: usize,
    pub inline fn any(ptr: *const anyopaque) Vector {
        const Pointer = @TypeOf(ptr);
        return .{
            .addr = @intFromPtr(ptr),
            .len = @sizeOf(@typeInfo(Pointer).child),
        };
    }
    pub inline fn slice(ptr: anytype) Vector {
        const Pointer = @TypeOf(ptr);
        return .{
            .addr = @intFromPtr(ptr.ptr),
            .len = ptr.len *% @sizeOf(@typeInfo(Pointer).child),
        };
    }
};
pub const Arena = extern struct {
    lb_addr: usize,
    up_addr: usize,
    options: Flags = .{},
    pub const Flags = packed struct(u8) {
        thread_safe: bool = false,
        require_map: bool = false,
        require_unmap: bool = false,
        zb3: u5 = 0,
    };
};
pub const AddressSpaceLogging = packed struct {
    acquire: debug.Logging.AcquireErrorFault = .{},
    release: debug.Logging.ReleaseErrorFault = .{},
    map: debug.Logging.AcquireError = .{},
    unmap: debug.Logging.ReleaseError = .{},
};
pub const AddressSpaceErrors = struct {
    acquire: ResourceErrorPolicy = .{ .throw = error.UnderSupply },
    release: ResourceErrorPolicy = .abort,
    map: sys.ErrorPolicy = .{ .throw = spec.mmap.errors.all },
    unmap: sys.ErrorPolicy = .{ .abort = spec.munmap.errors.all },
};
pub const ArenaReference = struct {
    index: comptime_int,
    options: ?Arena.Flags = null,
    fn arena(comptime arena_ref: ArenaReference, comptime AddressSpace: type) Arena {
        return AddressSpace.arena(arena_ref.index);
    }
};
pub const DiscreteMultiArena = struct {
    label: ?[]const u8 = null,
    list: []const Arena,
    subspace: ?[]const meta.Generic = null,
    value_type: type = bool,
    index_type: type = u16,
    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},
    pub const MultiArena: type = @This();
    fn Directory(comptime multi_arena: MultiArena) type {
        return [multi_arena.list.len]struct {
            field_name: []const u8,
            arena_index: comptime_int,
        };
    }
    pub fn Implementation(comptime multi_arena: MultiArena) type {
        if (builtin.comptime_assertions) {
            debug.assertNotEqual(u64, multi_arena.list.len, 0);
        }
        const empty_fields: []const builtin.Type.StructField = @typeInfo(@TypeOf(.{{}} ** multi_arena.list.len)).Struct.fields;
        var directory: Directory(multi_arena) = undefined;
        var fields: []const builtin.Type.StructField = meta.empty;
        var thread_safe_state: bool = multi_arena.list[0].options.thread_safe;
        var arena_index: comptime_int = 0;
        for (multi_arena.list, 0..) |super_arena, index| {
            if (thread_safe_state and !super_arena.options.thread_safe) {
                const T: type = ThreadSafeSet(arena_index +% 1, multi_arena.value_type, multi_arena.index_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, empty_fields[fields.len].name, .{})};
                directory[index] = .{ .arena_index = 0, .field_name = empty_fields[fields.len].name };
                arena_index = 1;
            } else if (!thread_safe_state and super_arena.options.thread_safe) {
                const T: type = DiscreteBitSet(arena_index +% 1, multi_arena.value_type, multi_arena.index_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, empty_fields[fields.len].name, .{})};
                directory[index] = .{ .arena_index = 0, .field_name = empty_fields[fields.len].name };
                arena_index = 1;
            } else {
                directory[index] = .{ .arena_index = arena_index, .field_name = empty_fields[fields.len].name };
                arena_index +%= 1;
            }
            thread_safe_state = super_arena.options.thread_safe;
        }
        const GenericSet = if (thread_safe_state) ThreadSafeSet else DiscreteBitSet;
        const T: type = GenericSet(arena_index +% 1, multi_arena.value_type, multi_arena.index_type);
        fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, empty_fields[fields.len].name, .{})};
        if (fields.len == 1) {
            return fields[0].type;
        }
        return GenericMultiSet(multi_arena, directory, @Type(meta.structInfo(.Extern, fields)));
    }
    fn referSubRegular(comptime multi_arena: MultiArena, comptime sub_arena: Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var s_index: multi_arena.index_type = 0;
        while (s_index <= multi_arena.list.len) : (s_index +%= 1) {
            const super_arena: Arena = multi_arena.list[s_index];
            if (super_arena.lb_addr > sub_arena.up_addr) {
                break;
            }
            if (super_arena.intersection(sub_arena) != null) {
                map_list = map_list ++ [1]ArenaReference{.{
                    .index = s_index,
                    .options = multi_arena.list[s_index].options,
                }};
            }
        }
        return map_list;
    }
    fn referSubDiscrete(comptime multi_arena: MultiArena, comptime sub_list: []const Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var t_index: multi_arena.index_type = 0;
        while (t_index != sub_list.len) : (t_index +%= 1) {
            var s_index: multi_arena.index_type = 0;
            while (s_index != multi_arena.list.len) : (s_index +%= 1) {
                const s_arena: Arena = multi_arena.list[s_index];
                const t_arena: Arena = sub_list[t_index];
                if (s_arena.intersection(t_arena) != null) {
                    map_list = map_list ++ [1]ArenaReference{.{
                        .index = s_index,
                        .options = multi_arena.list[s_index].options,
                    }};
                }
            }
        }
        return map_list;
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: usize) ?multi_arena.index_type {
        @setRuntimeSafety(builtin.is_safe);
        var index: multi_arena.index_type = 0;
        while (index != multi_arena.list.len) : (index +%= 1) {
            if (addr >= multi_arena.list[index].lb_addr and
                addr < multi_arena.list[index].up_addr)
            {
                return index;
            }
        }
        return null;
    }
    pub fn capacityAll(comptime multi_arena: MultiArena) comptime_int {
        return builtin.sub(u64, multi_arena.up_addr, multi_arena.lb_addr);
    }
    pub fn capacityAny(comptime multi_arena: MultiArena, comptime index: multi_arena.index_type) comptime_int {
        return multi_arena.list[index].up_addr -% multi_arena.list[index].up_addr;
    }
    pub fn arena(comptime multi_arena: MultiArena, index: multi_arena.index_type) Arena {
        return multi_arena.list[index];
    }
    pub fn count(comptime multi_arena: MultiArena) comptime_int {
        return multi_arena.list.len;
    }
    pub fn low(comptime multi_arena: MultiArena, comptime index: multi_arena.index_type) comptime_int {
        return multi_arena.list[index].lb_addr;
    }
    pub fn high(comptime multi_arena: MultiArena, comptime index: multi_arena.index_type) comptime_int {
        return multi_arena.list[index].up_addr;
    }
    pub fn instantiate(comptime multi_arena: MultiArena) type {
        return GenericDiscreteAddressSpace(multi_arena);
    }
    pub fn options(comptime multi_arena: MultiArena, comptime index: multi_arena.index_type) Arena.Flags {
        return multi_arena.list[index].options;
    }
};
pub const RegularMultiArena = struct {
    /// This will show up in logging.
    label: ?[]const u8 = null,
    /// Lower bound of address space. This is used when computing division
    /// length.
    lb_addr: usize = 0,
    /// Upper bound of address space. This is used when computing division
    /// length.
    up_addr: usize = 1 << 47,
    /// The first arena starts at this offset in the first division.
    /// This is an option to allow the largest alignment possible per division
    /// while avoiding the binary mapping in the first division.
    lb_offset: u64 = 0,
    /// The last arena ends at this offset below the end of the last division.
    up_offset: u64 = 0,
    divisions: u64 = 64,
    alignment: u64 = 4096,
    subspace: ?[]const meta.Generic = null,
    value_type: type = bool,
    index_type: type = u16,
    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},
    options: Arena.Flags = .{},
    pub const MultiArena = @This();
    fn Index(comptime multi_arena: MultiArena) type {
        return multi_arena.index_type;
    }
    fn Implementation(comptime multi_arena: MultiArena) type {
        if (multi_arena.options.thread_safe or
            @bitSizeOf(multi_arena.value_type) == 8)
        {
            return ThreadSafeSet(
                multi_arena.divisions +% @intFromBool(multi_arena.options.require_map),
                multi_arena.value_type,
                multi_arena.index_type,
            );
        } else {
            return DiscreteBitSet(
                multi_arena.divisions +% @intFromBool(multi_arena.options.require_map),
                multi_arena.value_type,
                multi_arena.index_type,
            );
        }
    }
    pub fn addressable_byte_address(comptime multi_arena: MultiArena) comptime_int {
        return math.add64(multi_arena.lb_addr, multi_arena.lb_offset);
    }
    pub fn allocated_byte_address(comptime multi_arena: MultiArena) comptime_int {
        return multi_arena.lb_addr;
    }
    pub fn unallocated_byte_address(comptime multi_arena: MultiArena) comptime_int {
        return math.sub64(multi_arena.up_addr, multi_arena.up_offset);
    }
    pub fn unaddressable_byte_address(comptime multi_arena: MultiArena) comptime_int {
        return multi_arena.up_addr;
    }
    pub fn allocated_byte_count(comptime multi_arena: MultiArena) comptime_int {
        return math.sub64(unallocated_byte_address(multi_arena), allocated_byte_address(multi_arena));
    }
    pub fn addressable_byte_count(comptime multi_arena: MultiArena) comptime_int {
        return math.sub64(unaddressable_byte_address(multi_arena), addressable_byte_address(multi_arena));
    }
    fn referSubRegular(comptime multi_arena: MultiArena, comptime sub_arena: Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        const max_index: Index(multi_arena) = multi_arena.invert(sub_arena.up_addr);
        const min_index: Index(multi_arena) = multi_arena.invert(sub_arena.lb_addr);
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index +%= 1) {
            map_list = meta.concat(ArenaReference, map_list, .{
                .index = s_index,
                .options = multi_arena.options,
            });
        }
        if (isRegular(multi_arena, map_list)) {
            return map_list;
        } else {
            @compileError("invalid sub address space spec");
        }
    }
    fn referSubDiscrete(comptime multi_arena: MultiArena, comptime sub_list: []const Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        const max_index: Index(multi_arena) = multi_arena.invert(sub_list[sub_list.len -% 1].up_addr);
        const min_index: Index(multi_arena) = multi_arena.invert(sub_list[0].lb_addr);
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index +%= 1) {
            map_list = meta.concat(ArenaReference, map_list, .{
                .index = s_index,
                .options = multi_arena.options,
            });
        }
        if (isRegular(multi_arena, map_list)) {
            return map_list;
        } else {
            @compileError("invalid sub address space spec");
        }
    }
    pub inline fn count(comptime multi_arena: MultiArena) Index(multi_arena) {
        comptime return multi_arena.divisions;
    }
    pub fn capacityAll(comptime multi_arena: MultiArena) u64 {
        return bits.alignA64(multi_arena.up_addr -% multi_arena.lb_addr, multi_arena.alignment);
    }
    pub inline fn capacityEach(comptime multi_arena: MultiArena) u64 {
        return @divExact(capacityAll(multi_arena), multi_arena.divisions);
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: usize) Index(multi_arena) {
        return @as(Index(multi_arena), @intCast((addr -% multi_arena.lb_addr) / capacityEach(multi_arena)));
    }
    pub fn low(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        @setRuntimeSafety(false);
        return @max(multi_arena.lb_addr +% multi_arena.lb_offset, multi_arena.lb_addr +% (index *% comptime capacityEach(multi_arena)));
    }
    pub fn high(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        @setRuntimeSafety(false);
        return @min(multi_arena.up_addr -% multi_arena.up_offset, multi_arena.lb_addr +% ((index +% 1) *% comptime capacityEach(multi_arena)));
    }
    pub fn instantiate(comptime multi_arena: MultiArena) type {
        return GenericRegularAddressSpace(multi_arena);
    }
    pub fn super(comptime multi_arena: MultiArena) Arena {
        return .{
            .lb_addr = multi_arena.lb_addr,
            .up_addr = multi_arena.up_addr,
            .options = multi_arena.options,
        };
    }
    pub fn arena(comptime multi_arena: MultiArena, index: Index(multi_arena)) Arena {
        return .{
            .lb_addr = multi_arena.low(index),
            .up_addr = multi_arena.high(index),
            .options = multi_arena.options,
        };
    }
};
pub fn isRegular(comptime multi_arena: anytype, comptime map_list: []const ArenaReference) bool {
    var safety: ?bool = null;
    var addr: ?u64 = null;
    for (map_list) |item| {
        if (safety) |prev| {
            if (item.options) |options| {
                if (options.thread_safe != prev) {
                    return false;
                }
            }
        } else {
            if (item.options) |options| {
                safety = options.thread_safe;
            }
        }
        if (addr) |prev| {
            if (multi_arena.low(item.index) == prev) {
                addr = multi_arena.high(item.index);
            } else {
                return false;
            }
        } else {
            addr = multi_arena.high(item.index);
        }
    }
    return true;
}
fn RegularTypes(comptime AddressSpace: type) type {
    return struct {
        pub const acquire_void: type = blk: {
            if (AddressSpace.specification.options.require_map and
                AddressSpace.specification.errors.map.throw.len != 0)
            {
                const MMapError = sys.Error(AddressSpace.specification.errors.map.throw);
                if (AddressSpace.specification.errors.acquire == .throw) {
                    break :blk (MMapError || ResourceError)!void;
                }
                break :blk MMapError!void;
            }
            if (AddressSpace.specification.errors.acquire == .throw) {
                break :blk ResourceError!void;
            }
            break :blk void;
        };
        pub const acquire_bool: type = blk: {
            if (AddressSpace.specification.options.require_map and
                AddressSpace.specification.errors.map.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.specification.errors.map.throw)!bool;
            }
            break :blk bool;
        };
        pub const release_void: type = blk: {
            if (AddressSpace.specification.options.require_unmap and
                AddressSpace.specification.errors.unmap.throw.len != 0)
            {
                const MUnmapError = sys.Error(AddressSpace.specification.errors.unmap.throw);
                if (AddressSpace.specification.errors.release == .throw) {
                    break :blk (MUnmapError || ResourceError)!void;
                }
                break :blk MUnmapError!void;
            }
            if (AddressSpace.specification.errors.release == .throw) {
                break :blk ResourceError!void;
            }
            break :blk void;
        };
        pub const release_bool: type = blk: {
            if (AddressSpace.specification.options.require_unmap and
                AddressSpace.specification.errors.unmap.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.specification.errors.unmap.throw)!bool;
            }
            break :blk bool;
        };
        pub const map_void: type = blk: {
            if (AddressSpace.specification.options.require_map and
                AddressSpace.specification.errors.map.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.specification.errors.map.throw)!void;
            }
            break :blk void;
        };
        pub const unmap_void: type = blk: {
            if (AddressSpace.specification.options.require_unmap and
                AddressSpace.specification.errors.unmap.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.specification.errors.unmap.throw)!void;
            }
            break :blk void;
        };
    };
}
fn DiscreteTypes(comptime AddressSpace: type) type {
    return struct {
        pub fn acquire_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.specification.options(index).require_map and
                AddressSpace.specification.errors.map.throw.len != 0)
            {
                const MMapError = sys.Error(AddressSpace.specification.errors.map.throw);
                if (AddressSpace.specification.errors.acquire == .throw) {
                    return (MMapError || ResourceError)!void;
                }
                return MMapError!void;
            }
            if (AddressSpace.specification.errors.acquire == .throw) {
                return ResourceError!void;
            }
            return void;
        }
        pub fn release_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.specification.options(index).require_unmap and
                AddressSpace.specification.errors.unmap.throw.len != 0)
            {
                const MUnmapError = sys.Error(AddressSpace.specification.errors.unmap.throw);
                if (AddressSpace.specification.errors.release == .throw) {
                    return (MUnmapError || ResourceError)!void;
                }
                return MUnmapError!void;
            }
            if (AddressSpace.specification.errors.release == .throw) {
                return ResourceError!void;
            }
            return void;
        }
        pub fn map_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.specification.options(index).require_map and
                AddressSpace.specification.errors.map.throw.len != 0)
            {
                return sys.Error(AddressSpace.specification.errors.map.throw)!void;
            }
            return void;
        }
        pub fn unmap_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.specification.options(index).require_unmap and
                AddressSpace.specification.errors.unmap.throw.len != 0)
            {
                return sys.Error(AddressSpace.specification.errors.unmap.throw)!void;
            }
            return void;
        }
    };
}
fn Specs(comptime AddressSpace: type) type {
    return struct {
        pub const map_spec = .{
            .errors = AddressSpace.specification.errors.map,
            .logging = AddressSpace.specification.logging.map,
        };
        pub const unmap_spec = .{
            .errors = AddressSpace.specification.errors.unmap,
            .logging = AddressSpace.specification.logging.unmap,
        };
    };
}
/// Regular:
/// Good:
///     * Good locality associated with computing the begin and end addresses
///       using the arena index alone.
///     * Thread safety is all-or-nothing, therefore requesting atomic
///       operations from a thread-unsafe address space yields a compile error.
/// Bad:
///     * Poor flexibility.
///     * Results must be tightly constrained or checked.
///     * Arenas can not be independently configured.
///     * Thread safety is all-or-nothing, which increases the metadata size
///       required by each arena from 1 to 8 bits.
pub fn GenericRegularAddressSpace(comptime addr_spec: RegularAddressSpaceSpec) type {
    const T = extern struct {
        impl: RegularAddressSpaceSpec.Implementation(addr_spec) align(8) = defaultValue(addr_spec),
        pub const RegularAddressSpace = @This();
        pub const Index: type = addr_spec.index_type;
        pub const Value: type = addr_spec.value_type;
        pub const specification: RegularAddressSpaceSpec = addr_spec;
        pub inline fn get(address_space: *const RegularAddressSpace, index: Index) Value {
            return address_space.impl.get(index);
        }
        pub inline fn unset(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub inline fn set(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (!ret) address_space.impl.set(index);
            return !ret;
        }
        pub inline fn exchange(
            address_space: *RegularAddressSpace,
            index: Index,
            if_state: Value,
            to_state: Value,
        ) bool {
            const ret: Value = address_space.impl.get(index);
            if (ret == if_state) address_space.impl.set(index, to_state);
            return !ret;
        }
        pub inline fn atomicUnset(address_space: *RegularAddressSpace, index: Index) bool {
            return addr_spec.options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub inline fn atomicSet(address_space: *RegularAddressSpace, index: Index) bool {
            return addr_spec.options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub inline fn atomicExchange(
            address_space: *RegularAddressSpace,
            index: Index,
            comptime if_state: addr_spec.value_type,
            comptime to_state: addr_spec.value_type,
        ) bool {
            return addr_spec.options.thread_safe and
                address_space.impl.atomicExchange(index, if_state, to_state);
        }
        pub fn low(index: Index) u64 {
            return addr_spec.low(index);
        }
        pub fn high(index: Index) u64 {
            return addr_spec.high(index);
        }
        pub fn arena(index: Index) Arena {
            return addr_spec.arena(index);
        }
        pub fn count(address_space: *RegularAddressSpace) u64 {
            var index: Index = 0;
            var ret: u64 = 0;
            while (index != addr_spec.divisions) : (index +%= 1) {
                ret +%= builtin.int(u64, address_space.impl.get(index));
            }
            return ret;
        }
        pub usingnamespace Specs(RegularAddressSpace);
        pub usingnamespace RegularTypes(RegularAddressSpace);
        pub usingnamespace GenericAddressSpace(RegularAddressSpace);
    };
    return T;
}
/// Discrete:
/// Good:
///     * Arbitrary ranges.
///     * Maps directly to an arena.
/// Bad:
///     * Arena index must be known at compile time.
///     * Inversion is expensive.
///     * Constructing the bit set fields can be expensive at compile time.
pub fn GenericDiscreteAddressSpace(comptime addr_spec: DiscreteAddressSpaceSpec) type {
    const T = struct {
        impl: DiscreteAddressSpaceSpec.Implementation(addr_spec) = defaultValue(addr_spec),
        pub const DiscreteAddressSpace = @This();
        pub const Index: type = addr_spec.index_type;
        pub const Value: type = addr_spec.value_type;
        pub const specification: DiscreteAddressSpaceSpec = addr_spec;
        pub inline fn get(address_space: *const DiscreteAddressSpace, comptime index: Index) bool {
            return address_space.impl.get(index);
        }
        pub inline fn unset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: addr_spec.value_type = address_space.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub inline fn set(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: addr_spec.value_type = !address_space.get(index);
            if (ret) address_space.impl.set(index);
            return ret;
        }
        pub inline fn transform(address_space: *DiscreteAddressSpace, comptime index: Index, if_state: Value, to_state: Value) bool {
            const ret: Value = address_space.get(index);
            if (ret == if_state) address_space.impl.transform(index, if_state, to_state);
            return !ret;
        }
        pub inline fn atomicUnset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return addr_spec.list[index].options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub inline fn atomicSet(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return addr_spec.list[index].options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub inline fn atomicExchange(
            address_space: *DiscreteAddressSpace,
            comptime index: Index,
            comptime if_state: addr_spec.value_type,
            comptime to_state: addr_spec.value_type,
        ) bool {
            return addr_spec.list[index].options.thread_safe and
                address_space.impl.atomicExchange(index, if_state, to_state);
        }
        pub inline fn low(comptime index: Index) u64 {
            return addr_spec.low(index);
        }
        pub inline fn high(comptime index: Index) u64 {
            return addr_spec.high(index);
        }
        pub inline fn arena(comptime index: Index) Arena {
            return addr_spec.arena(index);
        }
        pub fn count(address_space: *DiscreteAddressSpace) u64 {
            comptime var index: Index = 0;
            var ret: u64 = 0;
            inline while (index != addr_spec.list.len) : (index +%= 1) {
                ret +%= builtin.int(u64, address_space.impl.get(index));
            }
            return ret;
        }
        pub usingnamespace Specs(DiscreteAddressSpace);
        pub usingnamespace DiscreteTypes(DiscreteAddressSpace);
        pub usingnamespace GenericAddressSpace(DiscreteAddressSpace);
    };
    return T;
}
pub const ElementaryAddressSpaceSpec = struct {
    label: ?[]const u8 = null,
    lb_addr: usize = 0x40000000,
    up_addr: usize = 0x800000000000,
    errors: AddressSpaceErrors,
    logging: AddressSpaceLogging,
    options: Arena.Flags,
};
/// Elementary:
pub fn GenericElementaryAddressSpace(comptime addr_spec: ElementaryAddressSpaceSpec) type {
    const T = struct {
        impl: bool = false,
        comptime high: fn () u64 = high,
        comptime low: fn () u64 = low,
        pub const ElementaryAddressSpace = @This();
        pub const specification: ElementaryAddressSpaceSpec = addr_spec;
        pub fn get(address_space: *const ElementaryAddressSpace) bool {
            return address_space.impl;
        }
        pub fn unset(address_space: *ElementaryAddressSpace) bool {
            const ret: bool = address_space.impl;
            if (ret) {
                address_space.impl = false;
            }
            return ret;
        }
        pub fn set(address_space: *ElementaryAddressSpace) bool {
            const ret: bool = address_space.impl;
            if (!ret) {
                address_space.impl = true;
            }
            return !ret;
        }
        pub fn atomicSet(address_space: *ElementaryAddressSpace) bool {
            return @cmpxchgStrong(u8, &address_space.impl, 0, 255, .SeqCst, .SeqCst);
        }
        pub fn atomicUnset(address_space: *ElementaryAddressSpace) bool {
            return @cmpxchgStrong(u8, &address_space.impl, 255, 0, .SeqCst, .SeqCst);
        }
        fn low() u64 {
            return addr_spec.lb_addr;
        }
        fn high() u64 {
            return addr_spec.up_addr;
        }
        pub fn arena() Arena {
            return .{
                .lb_addr = addr_spec.lb_addr,
                .up_addr = addr_spec.up_addr,
                .options = addr_spec.options,
            };
        }
        pub fn count(address_space: *const ElementaryAddressSpace) u8 {
            return builtin.int(u8, address_space.impl);
        }
        pub usingnamespace Specs(ElementaryAddressSpace);
        pub usingnamespace RegularTypes(ElementaryAddressSpace);
        pub usingnamespace GenericAddressSpace(ElementaryAddressSpace);
    };
    return T;
}
fn GenericAddressSpace(comptime AddressSpace: type) type {
    const T = extern struct {
        pub fn SubSpace(comptime label_or_index: anytype) type {
            return GenericSubSpace(AddressSpace.specification.subspace.?, label_or_index);
        }
    };
    return T;
}
pub fn generic(comptime any: anytype) meta.Generic {
    const T: type = if (@hasField(@TypeOf(any), "list"))
        DiscreteMultiArena
    else
        RegularMultiArena;
    return meta.genericCast(T, any);
}
pub fn genericSlice(comptime any: anytype) []const meta.Generic {
    return meta.genericSlice(generic, any);
}
fn GenericSubSpace(comptime ss: []const meta.Generic, comptime any: anytype) type {
    switch (@typeInfo(@TypeOf(any))) {
        .Int, .ComptimeInt => {
            return ss[any].cast().instantiate();
        },
        else => for (ss) |s| {
            if (s.cast().label) |label| {
                if (label.len != any.len) {
                    continue;
                }
                for (label, 0..) |c, i| {
                    if (c != any[i]) continue;
                }
                return s.cast().instantiate();
            }
        },
    }
}
fn defaultValue(comptime multi_arena: anytype) multi_arena.Implementation() {
    var tmp: multi_arena.Implementation() = .{};
    for (multi_arena.subspace orelse
        return tmp) |subspace|
    {
        for (blk: {
            if (subspace.type == RegularMultiArena) {
                break :blk multi_arena.referSubRegular(subspace.cast().super());
            }
            if (subspace.type == DiscreteMultiArena) {
                break :blk multi_arena.referSubDiscrete(subspace.cast().list);
            }
        }) |ref| {
            tmp.set(ref.index);
        }
    }
    return tmp;
}
pub const about = struct {
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

    pub fn aboutAddrLenNotice(about_s: fmt.AboutSrc, addr: usize, len: usize) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.Uxsize.write(buf[about_s.len..], addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenFlagsNotice(about_s: fmt.AboutSrc, addr: usize, len: usize, flags: sys.flags.MemMap) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.Uxsize.write(buf[about_s.len..], addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, len);
        ptr[0..2].* = ", ".*;
        ptr = sys.flags.MemMap.write(ptr + 2, flags);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAddrLenDescrNotice(about_s: fmt.AboutSrc, addr: usize, len: usize, description_s: []const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.Uxsize.write(buf[about_s.len..], addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, description_s);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAddrLenMemProtNotice(about_s: fmt.AboutSrc, addr: usize, len: usize, prot: sys.flags.MemProt) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = fmt.Uxsize.write(buf[about_s.len..], addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = sys.flags.MemProt.write(ptr + 2, prot);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutRemapNotice(about_s: fmt.AboutSrc, old_addr: usize, old_len: usize, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        const new_addr: usize = maybe_new_addr orelse old_addr;
        const new_len: usize = maybe_new_len orelse old_len;
        const abs_diff: u64 = @max(new_len, old_len) -% @min(new_len, old_len);
        const notation_s: *const [3]u8 = bits.cmovx(new_len < old_len, ", -", ", +");
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = fmt.Uxsize.write(ptr, old_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, old_addr +% old_len);
        ptr[0..4].* = " -> ".*;
        ptr += 4;
        ptr = fmt.Uxsize.write(ptr, new_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, new_addr +% new_len);
        ptr[0..3].* = notation_s.*;
        ptr += 3;
        ptr = fmt.Bytes.write(ptr, abs_diff);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutIndexLbAddrUpAddrLabelNotice(about_s: fmt.AboutSrc, index: ?u64, lb_addr: usize, up_addr: usize, label: ?[]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = fmt.strcpyEqu(ptr, label orelse "arena");
        ptr[0] = '-';
        ptr += 1;
        ptr = fmt.Udsize.write(ptr, index orelse 0);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, lb_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, up_addr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, up_addr -% lb_addr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutMemFdPathnameNotice(about_s: fmt.AboutSrc, mem_fd: usize, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr = fmt.strcpyEqu(ptr, pathname);
        ptr[0..9].* = ", mem_fd=".*;
        ptr = fmt.Udsize.write(ptr + 9, mem_fd);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenError(about_s: fmt.AboutSrc, error_name: []const u8, addr: usize, len: usize) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) - @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenFlagsError(about_s: fmt.AboutSrc, error_name: []const u8, addr: usize, len: usize, flags: sys.flags.MemMap) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr = fmt.Uxsize.write(ptr + 2, addr);
        ptr[0..2].* = "..".*;
        ptr = fmt.Uxsize.write(ptr + 2, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr = fmt.Bytes.write(ptr + 2, len);
        ptr[0..2].* = ", ".*;
        ptr = sys.flags.MemMap.write(ptr + 2, flags);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) - @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenDescrError(about_s: fmt.AboutSrc, error_name: []const u8, addr: usize, len: usize, description_s: []const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Udsize.write(ptr, len);
        ptr[0..8].* = " bytes, ".*;
        ptr += 8;
        @memcpy(ptr, description_s);
        ptr += description_s.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    pub fn aboutAddrLenMemProtError(about_s: fmt.AboutSrc, error_name: []const u8, addr: usize, len: usize, prot: sys.flags.MemProt) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, addr +% len);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Udsize.write(ptr, len);
        ptr[0..8].* = " bytes, ".*;
        ptr += 8;
        ptr = sys.flags.MemProt.write(ptr, prot);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutRemapError(about_s: fmt.AboutSrc, error_name: []const u8, old_addr: usize, old_len: usize, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        const new_addr: usize = maybe_new_addr orelse old_addr;
        const new_len: usize = maybe_new_len orelse old_len;
        const abs_diff: u64 = @max(new_len, old_len) -% @min(new_len, old_len);
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, old_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, old_addr +% old_len);
        ptr[0..4].* = " -> ".*;
        ptr += 4;
        ptr = fmt.Uxsize.write(ptr, new_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, new_addr +% new_len);
        ptr[0..3].* = if (new_len < old_len) ", -".* else ", +".*;
        ptr += 3;
        ptr = fmt.Bytes.write(ptr, abs_diff);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutIndexLbAddrUpAddrLabelError(about_s: fmt.AboutSrc, error_name: [:0]const u8, index: ?usize, lb_addr: usize, up_addr: usize, label: ?[]const u8) void {
        @setRuntimeSafety(false);
        const label_s: []const u8 = label orelse "arena";
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, label_s);
        ptr[0] = '-';
        ptr += 1;
        ptr = fmt.Udsize.write(ptr, index orelse 0);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, lb_addr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ptr = fmt.Uxsize.write(ptr, up_addr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.Bytes.write(ptr, up_addr -% lb_addr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameError(about_s: fmt.AboutSrc, error_name: []const u8, pathname: [:0]const u8) void {
        @setRuntimeSafety(false);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, pathname);
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
pub const spec = struct {
    pub const msync = struct {
        pub const errors = struct {
            pub const all = &.{ .BUSY, .INVAL, .NOMEM };
        };
    };
    pub const memfd_create = struct {
        pub const errors = struct {
            pub const all = &.{ .FAULT, .INVAL, .MFILE, .NFILE, .NOMEM, .PERM };
        };
    };
    pub const mprotect = struct {
        pub const errors = struct {
            pub const all = &.{ .ACCES, .INVAL, .NOMEM };
        };
    };
    pub const mmap = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .AGAIN, .BADF,     .EXIST, .INVAL,  .NFILE,
                .NODEV, .NOMEM, .OVERFLOW, .PERM,  .TXTBSY,
            };
            pub const mem = &.{
                .EXIST, .INVAL, .NOMEM,
            };
            pub const file = &.{
                .EXIST, .INVAL, .NOMEM, .NFILE, .NODEV, .TXTBSY,
            };
        };
    };
    pub const madvise = struct {
        pub const errors = struct {
            pub const all = &.{
                .ACCES, .AGAIN, .BADF, .INVAL, .IO, .NOMEM, .PERM,
            };
        };
    };
    pub const mremap = struct {
        pub const errors = struct {
            pub const all = &.{
                .AGAIN, .FAULT, .INVAL, .NOMEM,
            };
        };
    };
    pub const munmap = struct {
        pub const errors = struct {
            pub const all = &.{.INVAL};
        };
    };
    pub const brk = struct {
        pub const errors = struct {
            pub const all = &.{.NOMEM};
        };
    };
    pub const address_space = struct {
        pub const regular_128 = GenericRegularAddressSpace(.{
            .lb_addr = 0,
            .lb_offset = 0x40000000,
            .divisions = 128,
        });
        pub const exact_8 = GenericDiscreteAddressSpace(.{
            .list = &[_]Arena{
                .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
                .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
                .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
                .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
                .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
                .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
                .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
                .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
            },
        });
        pub const logging = struct {
            pub const verbose: AddressSpaceLogging = .{
                .acquire = debug.spec.logging.acquire_error_fault.verbose,
                .release = debug.spec.logging.release_error_fault.verbose,
                .map = debug.spec.logging.acquire_error.verbose,
                .unmap = debug.spec.logging.release_error.verbose,
            };
            pub const silent: AddressSpaceLogging = builtin.zero(AddressSpaceLogging);
        };
        pub const errors = struct {
            pub const noexcept: AddressSpaceErrors = .{
                .release = .ignore,
                .acquire = .ignore,
                .map = .{},
                .unmap = .{},
            };
            pub const zen: AddressSpaceErrors = .{
                .acquire = .{ .throw = error.UnderSupply },
                .release = .abort,
                .map = .{ .throw = mmap.errors.all },
                .unmap = .{ .abort = munmap.errors.all },
            };
        };
    };
};
pub fn cpy(comptime T: type, dest: [*]T, src: []const T) void {
    @setRuntimeSafety(false);
    @memcpy(dest, src);
}
pub fn set(comptime T: type, dest: [*]T, value: T, len: usize) void {
    @setRuntimeSafety(false);
    @memset(dest[0..len], value);
}
pub fn cpyLen(comptime T: type, dest: [*]T, src: []const T) usize {
    @setRuntimeSafety(false);
    @memcpy(dest, src);
    return src.len;
}
pub fn setLen(comptime T: type, dest: [*]T, value: T, len: usize) usize {
    @setRuntimeSafety(false);
    @memset(dest[0..len], value);
    return len;
}
pub fn cpyEqu(comptime T: type, dest: [*]T, src: []const T) [*]T {
    @setRuntimeSafety(false);
    @memcpy(dest, src);
    return dest + src.len;
}
pub fn setEqu(comptime T: type, dest: [*]T, value: T, len: usize) [*]T {
    @setRuntimeSafety(false);
    @memset(dest[0..len], value);
    return dest + len;
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
pub inline fn pointerCount(
    comptime child: type,
    addr: u64,
    comptime count: u64,
) *[count]child {
    @setRuntimeSafety(false);
    return @ptrFromInt(addr);
}
pub inline fn pointerCountWithSentinel(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
) *[count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*[count:sentinel]child, @ptrFromInt(addr));
}
pub inline fn pointerOpaque(comptime child: type, any: *const anyopaque) *const child {
    @setRuntimeSafety(false);
    return @as(*align(@max(1, @alignOf(child))) const child, @ptrCast(@alignCast(any)));
}
pub inline fn pointerOneAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) *align(alignment) child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) child, @ptrFromInt(addr));
}
pub inline fn pointerManyAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) [*]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr));
}
pub inline fn pointerManyWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [*:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*:sentinel]align(alignment) child, @ptrFromInt(addr));
}
pub inline fn pointerSliceAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime alignment: u64,
) []align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count];
}
pub inline fn pointerSliceWithSentinelAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count :sentinel];
}
pub inline fn pointerCountAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime alignment: u64,
) *align(alignment) [count]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count]child, @ptrFromInt(addr));
}
pub inline fn pointerCountWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) *align(alignment) [count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count:sentinel]child, @ptrFromInt(addr));
}
pub inline fn pointerOpaqueAligned(
    comptime child: type,
    any: *const anyopaque,
    comptime alignment: u64,
) *const child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) const child, @ptrCast(any));
}
extern fn sse42_strcmp(arg1: *const anyopaque, arg2: *const anyopaque, len: usize, off: usize) bool;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\sse42_strcmp:
        \\  mov         rax, rdx
        \\  movdqu      xmm0, xmmword ptr [rdi + rcx]
        \\  movdqu      xmm1, xmmword ptr [rsi + rcx]
        \\  pcmpestri   xmm0, xmm1, 24
        \\  setae       al
        \\  ret
    );
}
pub fn testEqualManySSE(comptime T: type, arg1: []const T, arg2: []const T) bool {
    @setRuntimeSafety(false);
    if (arg1.len != arg2.len) {
        return false;
    }
    if (arg1.len == 0) {
        return true;
    }
    if (@as(*const u8, @ptrCast(arg1.ptr)).* !=
        @as(*const u8, @ptrCast(arg2.ptr)).*)
    {
        return false;
    }
    const rem: usize = arg1.len *% @sizeOf(T) & 0xf;
    const len: usize = arg1.len *% @sizeOf(T) -% rem;
    var off: usize = 0;
    while (off != len) : (off +%= 16) {
        if (!sse42_strcmp(arg1.ptr, arg2.ptr, 16, off)) {
            return false;
        }
    }
    if (rem == 0) {
        return true;
    }
    const rem1: []const T = arg1[off / @sizeOf(T) ..];
    const rem2: []const T = arg1[off / @sizeOf(T) ..];
    var idx: usize = 0;
    while (idx != rem1.len) {
        if (!testEqual(T, rem1[idx], rem2[idx])) {
            return false;
        }
        idx +%= 1;
    }
    return true;
}
