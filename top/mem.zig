const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
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
pub const Map = meta.EnumBitField(enum(u64) {
    anonymous = MAP.ANONYMOUS,
    file = MAP.FILE,
    shared = MAP.SHARED,
    private = MAP.PRIVATE,
    shared_validate = MAP.SHARED_VALIDATE,
    type = MAP.TYPE,
    fixed = MAP.FIXED,
    fixed_no_replace = MAP.FIXED_NOREPLACE,
    grows_down = MAP.GROWSDOWN,
    deny_write = MAP.DENYWRITE,
    executable = MAP.EXECUTABLE,
    locked = MAP.LOCKED,
    no_reserve = MAP.NORESERVE,
    populate = MAP.POPULATE,
    non_block = MAP.NONBLOCK,
    stack = MAP.STACK,
    huge_tlb = MAP.HUGETLB,
    huge_shift = MAP.HUGE_SHIFT,
    huge_mask = MAP.HUGE_MASK,
    sync = MAP.SYNC,
    const MAP = sys.MAP;
});
pub const Prot = meta.EnumBitField(enum(u64) {
    none = PROT.NONE,
    read = PROT.READ,
    write = PROT.WRITE,
    exec = PROT.EXEC,
    grows_down = PROT.GROWSDOWN,
    grows_up = PROT.GROWSUP,
    const PROT = sys.PROT;
});
pub const Remap = meta.EnumBitField(enum(u64) {
    resize = REMAP.RESIZE,
    may_move = REMAP.MAYMOVE,
    fixed = REMAP.FIXED,
    no_unmap = REMAP.DONTUNMAP,
    const REMAP = sys.REMAP;
});
pub const Advice = meta.EnumBitField(enum(u64) {
    normal = MADV.NORMAL,
    random = MADV.RANDOM,
    sequential = MADV.SEQUENTIAL,
    immediate = MADV.WILLNEED,
    deferred = MADV.DONTNEED,
    reclaim = MADV.COLD,
    free = MADV.FREE,
    remove = MADV.REMOVE,
    pageout = MADV.PAGEOUT,
    poison = MADV.HWPOISON,
    mergeable = MADV.MERGEABLE,
    unmergeable = MADV.UNMERGEABLE,
    hugepage = MADV.HUGEPAGE,
    no_hugepage = MADV.NOHUGEPAGE,
    dump = MADV.DODUMP,
    no_dump = MADV.DONTDUMP,
    fork = MADV.DOFORK,
    no_fork = MADV.DONTFORK,
    wipe_on_fork = MADV.WIPEONFORK,
    keep_on_fork = MADV.KEEPONFORK,
    const MADV = sys.MADV;
    const Tag = @This();
});
pub const Fd = meta.EnumBitField(enum(u64) {
    allow_sealing = MFD.ALLOW_SEALING,
    huge_tlb = MFD.HUGETLB,
    close_on_exec = MFD.CLOEXEC,
    const MFD = sys.MFD;
});
pub const MapSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    return_type: type = void,
    logging: builtin.Logging.AcquireError = .{},
    const Specification = @This();
    pub const Options = struct {
        anonymous: bool = true,
        visibility: Visibility = .private,
        read: bool = true,
        write: bool = true,
        exec: bool = false,
        populate: bool = false,
        grows_down: bool = false,
        sync: bool = false,
    };
    const Visibility = enum { shared, shared_validate, private };
    pub fn flags(comptime spec: Specification) Map {
        comptime var flags_bitfield: Map = .{ .val = 0 };
        flags_bitfield.set(.fixed_no_replace);
        switch (spec.options.visibility) {
            .private => flags_bitfield.set(.private),
            .shared => flags_bitfield.set(.shared),
            .shared_validate => flags_bitfield.set(.shared_validate),
        }
        if (spec.options.anonymous) {
            flags_bitfield.set(.anonymous);
        }
        if (spec.options.grows_down) {
            flags_bitfield.set(.grows_down);
            flags_bitfield.set(.stack);
        }
        if (spec.options.populate) {
            builtin.static.assert(spec.options.visibility == .private);
            flags_bitfield.set(.populate);
        }
        if (spec.options.sync) {
            builtin.static.assert(spec.options.visibility == .shared_validate);
            flags_bitfield.set(.sync);
        }
        return flags_bitfield;
    }
    pub fn prot(comptime spec: Specification) Prot {
        comptime var prot_bitfield: Prot = .{ .val = 0 };
        if (spec.options.read) {
            prot_bitfield.set(.read);
        }
        if (spec.options.write) {
            prot_bitfield.set(.write);
        }
        if (spec.options.exec) {
            prot_bitfield.set(.exec);
        }
        return prot_bitfield;
    }
};
pub const MoveSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.mremap_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
    const Options = struct { no_unmap: bool = false };
    pub fn flags(comptime spec: Specification) Remap {
        comptime var flags_bitfield: Remap = .{ .val = 0 };
        if (spec.options.no_unmap) {
            flags_bitfield.set(.no_unmap);
        }
        flags_bitfield.set(.fixed);
        flags_bitfield.set(.may_move);
        return flags_bitfield;
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
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.mprotect_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
    const Specification = @This();
    pub const Options = struct {
        none: bool = false,
        read: bool = false,
        write: bool = false,
        exec: bool = false,
        grows_up: bool = false,
        grows_down: bool = false,
    };
    pub fn prot(comptime spec: Specification) Prot {
        comptime var prot_bitfield: Prot = .{ .val = 0 };
        if (spec.options.read) {
            prot_bitfield.set(.read);
        }
        if (spec.options.write) {
            prot_bitfield.set(.write);
        }
        if (spec.options.exec) {
            prot_bitfield.set(.exec);
        }
        if (spec.options.none) {
            prot_bitfield.set(.none);
        }
        if (spec.options.grows_down) {
            prot_bitfield.set(.grows_down);
        }
        if (spec.options.grows_up) {
            prot_bitfield.set(.grows_up);
        }
        return prot_bitfield;
    }
};
pub const AdviseSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.madvise_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
    const Options = struct {
        usage: ?Usage = null,
        action: ?Action = null,
        property: ?Property = null,
    };
    const Usage = enum { normal, random, sequential, immediate, deferred };
    const Action = enum { reclaim, free, remove, pageout, poison };
    const Property = union(enum) { mergeable: bool, hugepage: bool, dump: bool, fork: bool, wipe_on_fork: bool };
    pub fn advice(comptime spec: AdviseSpec) Advice {
        comptime var advice_bitfield: Advice = .{ .val = 0 };
        if (spec.options.usage) |usage| {
            switch (usage) {
                .normal => {
                    advice_bitfield.set(.normal);
                },
                .random => {
                    advice_bitfield.set(.random);
                },
                .sequential => {
                    advice_bitfield.set(.sequential);
                },
                .immediate => {
                    advice_bitfield.set(.immediate);
                },
                .deferred => {
                    advice_bitfield.set(.deferred);
                },
            }
        }
        if (spec.options.action) |action| {
            switch (action) {
                .remove => {
                    advice_bitfield.set(.remove);
                },
                .free => {
                    advice_bitfield.set(.free);
                },
                .reclaim => {
                    advice_bitfield.set(.reclaim);
                },
                .pageout => {
                    advice_bitfield.set(.pageout);
                },
                .poison => {
                    advice_bitfield.set(.poison);
                },
            }
        }
        if (spec.options.property) |property| {
            switch (property) {
                .mergeable => |mergeable| {
                    if (mergeable) {
                        advice_bitfield.set(.mergeable);
                    } else {
                        advice_bitfield.set(.unmergeable);
                    }
                },
                .hugepage => |hugepage| {
                    if (hugepage) {
                        advice_bitfield.set(.hugepage);
                    } else {
                        advice_bitfield.set(.no_hugepage);
                    }
                },
                .dump => |dump| {
                    if (dump) {
                        advice_bitfield.set(.dump);
                    } else {
                        advice_bitfield.set(.no_dump);
                    }
                },
                .fork => |fork| {
                    if (fork) {
                        advice_bitfield.set(.fork);
                    } else {
                        advice_bitfield.set(.no_fork);
                    }
                },
                .wipe_on_fork => |wipe_on_fork| {
                    if (wipe_on_fork) {
                        advice_bitfield.set(.wipe_on_fork);
                    } else {
                        advice_bitfield.set(.keep_on_fork);
                    }
                },
            }
        }
        if (advice_bitfield.val == 0) {
            advice_bitfield.set(.normal);
        }
        return advice_bitfield;
    }
    pub fn describe(comptime spec: AdviseSpec) []const u8 {
        if (spec.options.usage) |usage| {
            switch (usage) {
                .normal => {
                    return "expect normal usage";
                },
                .random => {
                    return "expect page references in random order";
                },
                .sequential => {
                    return "expect page references in sequential order";
                },
                .immediate => {
                    return "expect access in the near future";
                },
                .deferred => {
                    return "do not expect access in the near future";
                },
            }
        }
        if (spec.options.action) |action| {
            switch (action) {
                .remove => {
                    return "swap out backing store";
                },
                .free => {
                    return "swap out pages as needed";
                },
                .pageout => {
                    return "swap out pages now";
                },
                .reclaim => {
                    return "reclaim pages";
                },
                .poison => {
                    return "illegal access";
                },
            }
        }
        if (spec.options.property) |property| {
            switch (property) {
                .mergeable => |mergeable| {
                    if (mergeable) {
                        return "merge identical pages";
                    } else {
                        return "do not merge identical pages";
                    }
                },
                .hugepage => |hugepage| {
                    if (hugepage) {
                        return "expect large contiguous mappings";
                    } else {
                        return "do not expect large contiguous mappings";
                    }
                },
                .dump => |dump| {
                    if (dump) {
                        return "include in core dump";
                    } else {
                        return "exclude from core dump";
                    }
                },
                .fork => |fork| {
                    if (fork) {
                        return "available to child processes";
                    } else {
                        return "unavailable to child processes";
                    }
                },
                .wipe_on_fork => |wipe_on_fork| {
                    if (wipe_on_fork) {
                        return "wiping on fork";
                    } else {
                        return "keeping on fork";
                    }
                },
            }
        }
        return "(unknown advise)";
    }
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
    pub fn flags(comptime spec: FdSpec) mem.Fd {
        var flags_bitfield: Fd = .{ .val = 0 };
        if (spec.options.allow_sealing) {
            flags_bitfield.set(.allow_sealing);
        }
        if (spec.options.huge_tlb) {
            flags_bitfield.set(.huge_tlb);
        }
        if (spec.options.close_on_exec) {
            flags_bitfield.set(.close_on_exec);
        }
        return flags_bitfield;
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
        return amt.count * @enumToInt(amt.unit);
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
            debug.arenaAcquireNotice(index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.arenaAcquireError(spec.errors.acquire.throw, index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.acquire.throw;
    } else if (spec.errors.acquire == .abort) {
        builtin.proc.exitFault(debug.about_acq_2_s, 2);
    }
}
pub fn acquireStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.acquire_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: builtin.Logging.AcquireErrorFault = comptime spec.logging.acquire.override();
    if (acquireStaticSet(AddressSpace, address_space, index)) {
        if (logging.Acquire) {
            debug.arenaAcquireNotice(index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.arenaAcquireError(spec.errors.acquire.throw, index, lb_addr, up_addr, spec.label);
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
    } else if (comptime spec.errors.acquire == .throw) {
        if (logging.Error) {
            debug.arenaAcquireError(spec.errors.acquire.throw, null, lb_addr, up_addr, spec.label);
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
            debug.arenaReleaseNotice(index, lb_addr, up_addr, spec.label);
        }
        if (spec.options.require_unmap) {
            try meta.wrap(releaseUnmap(AddressSpace, address_space));
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            debug.arenaReleaseError(spec.errors.throw, index, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        builtin.proc.exitFault(debug.about_rel_2_s, 2);
    }
}
pub fn releaseStatic(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) AddressSpace.release_void(index) {
    const spec = AddressSpace.addr_spec;
    const lb_addr: u64 = AddressSpace.low(index);
    const up_addr: u64 = AddressSpace.high(index);
    const logging: builtin.Logging.ReleaseErrorFault = comptime spec.logging.release.override();
    if (releaseStaticUnset(AddressSpace, address_space, index)) {
        if (logging.Release) {
            debug.arenaReleaseNotice(index, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (logging.Error) {
            debug.arenaReleaseError(spec.errors.throw, index, lb_addr, up_addr, spec.label);
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
            debug.arenaReleaseNotice(null, lb_addr, up_addr, spec.label);
        }
    } else if (spec.errors.release == .throw) {
        if (spec.logging.release.Error) {
            debug.arenaReleaseError(spec.errors.throw, null, lb_addr, up_addr, spec.label);
        }
        return spec.errors.release.throw;
    } else if (spec.errors.release == .abort) {
        builtin.proc.exitFault(debug.about_rel_2_s, 2);
    }
}
pub fn map(comptime spec: MapSpec, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const mmap_prot: Prot = comptime spec.prot();
    const mmap_flags: Map = comptime spec.flags();
    const logging: builtin.Logging.AcquireError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mmap, spec.errors, spec.return_type, .{ addr, len, mmap_prot.val, mmap_flags.val, ~@as(u64, 0), 0 }))) |ret| {
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
pub fn move(comptime spec: MoveSpec, old_addr: u64, old_len: u64, new_addr: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const mremap_flags: Remap = comptime spec.flags();
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mremap, spec.errors, spec.return_type, .{ old_addr, old_len, old_len, mremap_flags.val, new_addr }))) {
        if (logging.Success) {
            debug.remapNotice(old_addr, old_len, new_addr, null);
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
            debug.remapNotice(old_addr, old_len, null, new_len);
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
pub fn protect(comptime spec: ProtectSpec, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const prot: Prot = comptime spec.prot();
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.mprotect, spec.errors, spec.return_type, .{ addr, len, prot.val }))) {
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
pub fn advise(comptime spec: AdviseSpec, addr: u64, len: u64) sys.ErrorUnion(spec.errors, spec.return_type) {
    const advice: Advice = comptime spec.advice();
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.madvise, spec.errors, spec.return_type, .{ addr, len, advice.val }))) {
        if (logging.Success) {
            debug.adviseNotice(addr, len, spec.describe());
        }
    } else |madvise_error| {
        if (logging.Error) {
            debug.adviseError(madvise_error, addr, len, spec.describe());
        }
        return madvise_error;
    }
}
pub fn fd(comptime spec: FdSpec, name: [:0]const u8) sys.ErrorUnion(spec.errors, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const flags: mem.Fd = comptime spec.flags();
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
    const about_map_0_s: [:0]const u8 = builtin.fmt.about("map");
    const about_map_1_s: [:0]const u8 = builtin.fmt.about("map-error");
    const about_acq_0_s: [:0]const u8 = builtin.fmt.about("acq");
    const about_acq_1_s: [:0]const u8 = builtin.fmt.about("acq-error");
    const about_rel_0_s: [:0]const u8 = builtin.fmt.about("rel");
    const about_rel_1_s: [:0]const u8 = builtin.fmt.about("rel-error");
    const about_acq_2_s: [:0]const u8 = builtin.fmt.about("acq-fault\n");
    const about_rel_2_s: [:0]const u8 = builtin.fmt.about("rel-fault\n");
    const about_unmap_0_s: [:0]const u8 = builtin.fmt.about("unmap");
    const about_unmap_1_s: [:0]const u8 = builtin.fmt.about("unmap-error");
    const about_remap_0_s: [:0]const u8 = builtin.fmt.about("remap");
    const about_remap_1_s: [:0]const u8 = builtin.fmt.about("remap-error");
    const about_memfd_0_s: [:0]const u8 = builtin.fmt.about("memfd");
    const about_memfd_1_s: [:0]const u8 = builtin.fmt.about("memfd-error");
    const about_resize_0_s: [:0]const u8 = builtin.fmt.about("resize");
    const about_resize_1_s: [:0]const u8 = builtin.fmt.about("resize-error");
    const about_advice_0_s: [:0]const u8 = builtin.fmt.about("advice");
    const about_advice_1_s: [:0]const u8 = builtin.fmt.about("advice-error");
    const about_protect_0_s: [:0]const u8 = builtin.fmt.about("protect");
    const about_protect_1_s: [:0]const u8 = builtin.fmt.about("protect-error");
    pub fn mapNotice(addr: u64, len: u64) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_map_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",          builtin.fmt.ux64(addr +% len).readAll(),
            ", ",          builtin.fmt.ud64(len).readAll(),
            " bytes\n",
        });
    }
    pub fn unmapNotice(addr: u64, len: u64) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_unmap_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",            builtin.fmt.ux64(addr +% len).readAll(),
            ", ",            builtin.fmt.ud64(len).readAll(),
            " bytes\n",
        });
    }
    fn protectNotice(addr: u64, len: u64, description_s: []const u8) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_protect_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",              builtin.fmt.ux64(addr +% len).readAll(),
            ", ",              builtin.fmt.ud64(len).readAll(),
            " bytes, ",        description_s,
            "\n",
        });
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_advice_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",             builtin.fmt.ux64(addr +% len).readAll(),
            ", ",             builtin.fmt.ud64(len).readAll(),
            " bytes, ",       description_s,
            "\n",
        });
    }
    pub fn remapNotice(old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const operation_s: []const u8 = mach.cmovx(new_addr != old_addr, about_remap_0_s, about_resize_0_s);
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            operation_s, builtin.fmt.ux64(old_addr).readAll(),
            "..",        builtin.fmt.ux64(old_addr +% old_len).readAll(),
            " -> ",      builtin.fmt.ux64(new_addr).readAll(),
            "..",        builtin.fmt.ux64(new_addr +% new_len).readAll(),
            notation_s,  builtin.fmt.ud64(abs_diff).readAll(),
            " bytes\n",
        });
    }
    fn indexLbAddrUpAddrLabelAboutNotice(index: anytype, lb_addr: u64, up_addr: u64, label: ?[]const u8, about_s: [:0]const u8) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_s,    label orelse "arena",
            "-",        builtin.fmt.ud64(index).readAll(),
            ", ",       builtin.fmt.ux64(lb_addr).readAll(),
            "..",       builtin.fmt.ux64(up_addr).readAll(),
            ", ",       builtin.fmt.ud64(up_addr -% lb_addr).readAll(),
            " bytes\n",
        });
    }
    inline fn arenaAcquireNotice(index: anytype, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        indexLbAddrUpAddrLabelAboutNotice(index, lb_addr, up_addr, label, about_acq_0_s);
    }
    inline fn arenaReleaseNotice(index: anytype, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        indexLbAddrUpAddrLabelAboutNotice(index, lb_addr, up_addr, label, about_rel_0_s);
    }
    fn memFdNotice(name: [:0]const u8, mem_fd: u64) void {
        var buf: [4096 + 32]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_memfd_0_s, "fd=", builtin.fmt.ud64(mem_fd).readAll(), ", ", name, "\n" });
    }
    pub fn mapError(map_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_map_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",          builtin.fmt.ux64(addr +% len).readAll(),
            ", ",          builtin.fmt.ud64(len).readAll(),
            " bytes (",    @errorName(map_error),
            ")\n",
        });
    }
    pub fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_unmap_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",            builtin.fmt.ux64(addr +% len).readAll(),
            ", ",            builtin.fmt.ud64(len).readAll(),
            " bytes (",      @errorName(unmap_error),
            ")\n",
        });
    }
    fn protectError(protect_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        @setCold(true);
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_protect_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",              builtin.fmt.ux64(addr +% len).readAll(),
            ", ",              builtin.fmt.ud64(len).readAll(),
            " bytes, ",        description_s,
            ", (",             @errorName(protect_error),
            ")\n",
        });
    }
    fn adviseError(advise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        @setCold(true);
        var buf: [4096]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_advice_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",             builtin.fmt.ux64(addr +% len).readAll(),
            ", ",             builtin.fmt.ud64(len).readAll(),
            " bytes, ",       description_s,
            ", (",            @errorName(advise_error),
            ")\n",
        });
    }
    fn remapError(mremap_err: anytype, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        @setCold(true);
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const operation_s: []const u8 = mach.cmovx(new_addr != old_addr, about_remap_1_s, about_resize_1_s);
        var buf: [4096 +% 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            operation_s, builtin.fmt.ux64(old_addr).readAll(),
            "..",        builtin.fmt.ux64(old_addr +% old_len).readAll(),
            " -> ",      builtin.fmt.ux64(new_addr).readAll(),
            "..",        builtin.fmt.ux64(new_addr +% new_len).readAll(),
            notation_s,  builtin.fmt.ud64(abs_diff).readAll(),
            " bytes (",  @errorName(mremap_err),
            ")\n",
        });
    }
    fn arenaAcquireError(arena_error: anytype, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        @setCold(true);
        var buf: [4096 + 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_acq_1_s, label orelse "arena",
            "-",           builtin.fmt.ud64(index orelse 0).readAll(),
            ", ",          builtin.fmt.ux64(lb_addr).readAll(),
            "..",          builtin.fmt.ux64(up_addr).readAll(),
            ", ",          builtin.fmt.ud64(up_addr -% lb_addr).readAll(),
            " bytes (",    @errorName(arena_error),
            ")\n",
        });
    }
    fn arenaReleaseError(arena_error: anytype, index: ?u64, lb_addr: u64, up_addr: u64, label: ?[]const u8) void {
        @setCold(true);
        var buf: [4096 + 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_rel_1_s, label orelse "arena",
            "-",           builtin.fmt.ud64(index orelse 0).readAll(),
            ", ",          builtin.fmt.ux64(lb_addr).readAll(),
            "..",          builtin.fmt.ux64(up_addr).readAll(),
            ", ",          builtin.fmt.ud64(up_addr -% lb_addr).readAll(),
            " bytes (",    @errorName(arena_error),
            ")\n",
        });
    }
    fn memFdError(memfd_error: anytype, pathname: [:0]const u8) void {
        var buf: [16 + 4096 + 512]u8 = undefined;
        builtin.debug.logErrorAIO(&buf, &[_][]const u8{ about_memfd_1_s, pathname, " (", @errorName(memfd_error), ")\n" });
    }
};
pub fn view(comptime s: [:0]const u8) mem.StructuredAutomaticView(u8, &@as(u8, 0), s.len, null, .{}) {
    return .{ .impl = .{ .auto = @ptrCast(*const [s.len:0]u8, s.ptr).* } };
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
    const lb_addr: u64 = @ptrToInt(lu_values.ptr);
    const ab_addr: u64 = @ptrToInt(ax_values.ptr);
    const lhs_len: u64 = @divExact(ab_addr -% lb_addr, @sizeOf(T));
    return lu_values[0..lhs_len];
}
fn rhs(comptime T: type, comptime U: type, lu_values: []const T, ax_values: []const U) []const T {
    const up_addr: u64 = mach.mulAdd64(@ptrToInt(lu_values.ptr), @sizeOf(T), lu_values.len);
    const xb_addr: u64 = mach.mulAdd64(@ptrToInt(ax_values.ptr), @sizeOf(U), ax_values.len);
    const rhs_len: u64 = @divExact(up_addr -% xb_addr, @sizeOf(T));
    return lu_values[0..rhs_len];
}
fn mid(comptime T: type, comptime U: type, values: []const T) []const U {
    const lb_addr: u64 = @ptrToInt(values.ptr);
    const up_addr: u64 = mach.mulAdd64(lb_addr, @sizeOf(T), values.len);
    const ab_addr: u64 = mach.alignA64(lb_addr, @alignOf(U));
    const xb_addr: u64 = mach.alignB64(up_addr, @alignOf(U));
    const aligned_bytes: u64 = mach.sub64(xb_addr, ab_addr);
    const mid_len: u64 = mach.div64(aligned_bytes, @sizeOf(U));
    return @intToPtr([*]const U, ab_addr)[0..mid_len];
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
    if (builtin.int2v(bool, prefix_values.len == 0, prefix_values.len > values.len)) {
        return false;
    }
    return testEqualMany(T, prefix_values, values[0..prefix_values.len]);
}
pub fn testEqualManyBack(comptime T: type, suffix_values: []const T, values: []const T) bool {
    if (builtin.int2v(bool, suffix_values.len == 0, suffix_values.len > values.len)) {
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
        if (values[idx] == value) return idx;
        idx +%= 1;
    }
    return null;
}
pub fn indexOfLastEqualOne(comptime T: type, value: T, values: []const T) ?u64 {
    var idx: u64 = values.len;
    while (idx != 0) {
        idx -%= 1;
        if (values[idx] == value) return idx;
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

pub fn readIntNative(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8) T {
    return @ptrCast(*align(1) const T, bytes).*;
}
pub fn readIntForeign(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8) T {
    return @byteSwap(readIntNative(T, bytes));
}
pub const readIntLittle = switch (builtin.config.native_endian) {
    .Little => readIntNative,
    .Big => readIntForeign,
};
pub const readIntBig = switch (builtin.config.native_endian) {
    .Little => readIntForeign,
    .Big => readIntNative,
};
pub fn readInt(comptime T: type, bytes: *const [@divExact(@typeInfo(T).Int.bits, 8)]u8, endian: builtin.Endian) T {
    if (endian == builtin.config.native_endian) {
        return readIntNative(T, bytes);
    } else {
        return readIntForeign(T, bytes);
    }
}
pub fn writeIntNative(comptime T: type, buf: *[(@typeInfo(T).Int.bits + 7) / 8]u8, value: T) void {
    @ptrCast(*align(1) T, buf).* = value;
}
pub fn writeIntForeign(comptime T: type, buf: *[@divExact(@typeInfo(T).Int.bits, 8)]u8, value: T) void {
    writeIntNative(T, buf, @byteSwap(value));
}
pub const writeIntBig = switch (builtin.config.native_endian) {
    .Little => writeIntForeign,
    .Big => writeIntNative,
};
pub const writeIntLittle = switch (builtin.config.native_endian) {
    .Little => writeIntNative,
    .Big => writeIntForeign,
};
pub fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).Int.bits, 8)]u8, value: T, endian: builtin.Endian) void {
    if (endian == builtin.config.native_endian) {
        return writeIntNative(T, buffer, value);
    } else {
        return writeIntForeign(T, buffer, value);
    }
}
pub fn nativeTo(comptime T: type, x: T, desired_endianness: builtin.Endian) T {
    return switch (desired_endianness) {
        .Little => nativeToLittle(T, x),
        .Big => nativeToBig(T, x),
    };
}
pub fn littleToNative(comptime T: type, x: T) T {
    return switch (builtin.config.native_endian) {
        .Little => x,
        .Big => @byteSwap(x),
    };
}
pub fn bigToNative(comptime T: type, x: T) T {
    return switch (builtin.config.native_endian) {
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
    return switch (builtin.config.native_endian) {
        .Little => x,
        .Big => @byteSwap(x),
    };
}
pub fn nativeToBig(comptime T: type, x: T) T {
    return switch (builtin.config.native_endian) {
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
pub const readIntSliceLittle = switch (builtin.config.native_endian) {
    .Little => readIntSliceNative,
    .Big => readIntSliceForeign,
};
pub const readIntSliceBig = switch (builtin.config.native_endian) {
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

/// Given a pointer to a single item, returns a slice of the underlying bytes, preserving pointer attributes.
pub fn asBytes(ptr: anytype) AsBytesReturnType(@TypeOf(ptr)) {
    const T = AsBytesReturnType(@TypeOf(ptr));
    return @ptrCast(T, @alignCast(@typeInfo(T).Pointer.alignment, ptr));
}
pub const toBytes = meta.toBytes;

pub fn propagateSearch(comptime T: type, arg1: []const T, arg2: []const T, index: u64) ?u64 {
    const needle: []const u8 = if (arg1.len < arg2.len) arg1 else arg2;
    const haystack: []const u8 = if (arg1.len < arg2.len) arg2 else arg1;
    if (haystack.len > 127) {
        var start: u64 = index;
        while (start != haystack.len) : (start +%= 1) {
            if (testEqualManyFront(u8, needle, haystack[start..])) {
                return start;
            }
        }
        start = index -| 1;
        while (start != 0) : (start -%= 1) {
            if (testEqualManyFront(u8, needle, haystack[start..])) {
                return start;
            }
        }
    } else {
        var spread: u64 = 0;
        while (spread != haystack.len) : (spread +%= 1) {
            const below_start: u64 = index -% spread;
            const above_start: u64 = index +% spread;
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
    }
    return null;
}
pub fn orderedMatches(comptime T: type, arg1: []const T, arg2: []const T) u64 {
    const j: bool = arg1.len < arg2.len;
    const l_values: []const T = if (j) arg1 else arg2;
    const r_values: []const T = if (j) arg2 else arg1;
    var l_idx: u64 = 0;
    var mats: u64 = 0;
    while (l_idx +% mats < l_values.len) : (l_idx +%= 1) {
        var r_idx: u64 = 0;
        while (r_idx != r_values.len) : (r_idx +%= 1) {
            mats +%= builtin.int(u64, l_values[l_idx +% mats] == r_values[r_idx]);
        }
    }
    return mats;
}
pub const SimpleAllocator = struct {
    start: u64 = 0x40000000,
    next: u64 = 0x40000000,
    finish: u64 = 0x40000000,

    const Allocator = @This();
    pub const Save = struct { u64 };
    const noexcept = .{ .errors = .{} };

    pub inline fn create(allocator: *Allocator, comptime T: type) *T {
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T), @alignOf(T));
        return @intToPtr(*T, ret_addr);
    }
    pub inline fn allocate(allocator: *Allocator, comptime T: type, count: u64) []T {
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T) *% count, @alignOf(T));
        return @intToPtr([*]T, ret_addr)[0..count];
    }
    pub inline fn reallocate(allocator: *Allocator, comptime T: type, buf: []T, count: u64) []T {
        const ret_addr: u64 = allocator.reallocateInternal(@ptrToInt(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), @alignOf(T));
        return @intToPtr([*]T, ret_addr)[0..count];
    }
    pub inline fn createAligned(allocator: *Allocator, comptime T: type, comptime align_of: u64) *align(align_of) T {
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T), align_of);
        return @intToPtr(*align(align_of) T, ret_addr);
    }
    pub inline fn allocateAligned(allocator: *Allocator, comptime T: type, count: u64, comptime align_of: u64) []align(align_of) T {
        const ret_addr: u64 = allocator.allocateInternal(@sizeOf(T) *% count, align_of);
        return @intToPtr([*]align(align_of) T, ret_addr)[0..count];
    }
    pub inline fn reallocateAligned(allocator: *Allocator, comptime T: type, buf: []T, count: u64, comptime align_of: u64) []align(align_of) T {
        const ret_addr: u64 = allocator.reallocateInternal(@ptrToInt(buf.ptr), buf.len *% @sizeOf(T), count *% @sizeOf(T), align_of);
        return @intToPtr([*]align(align_of) T, ret_addr)[0..count];
    }
    pub inline fn deallocate(allocator: *Allocator, comptime T: type, buf: []T) void {
        allocator.deallocateInternal(@ptrToInt(buf.ptr), buf.len *% @sizeOf(T));
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
    pub inline fn unmap(allocator: *Allocator) void {
        sys.call(.munmap, .{}, void, .{ allocator.start, allocator.finish -% allocator.start });
        allocator.next = allocator.start;
        allocator.finish = allocator.start;
    }
    pub fn init(arena: mem.Arena) Allocator {
        if (arena.options.require_map) {
            map(noexcept, arena.lb_addr, 4096);
        }
        return .{
            .start = arena.lb_addr,
            .next = arena.lb_addr,
            .finish = if (arena.options.require_map) arena.lb_addr +% 4096 else arena.up_addr,
        };
    }
    inline fn alignAbove(value: u64, alignment: u64) u64 {
        const mask: u64 = alignment -% 1;
        return (value +% mask) & ~mask;
    }
    inline fn copy(dest: u64, src: u64, len: u64) void {
        mach.memcpy(@intToPtr([*]u8, dest), @intToPtr([*]const u8, src), len);
    }
    fn allocateInternal(
        allocator: *Allocator,
        size_of: u64,
        align_of: u64,
    ) u64 {
        const start: u64 = allocator.next;
        const aligned: u64 = alignAbove(start, align_of);
        const next: u64 = aligned +% size_of;
        if (next > allocator.finish) {
            const finish: u64 = alignAbove(next, 4096);
            map(noexcept, allocator.finish, allocator.finish -% finish);
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
                const finish: u64 = alignAbove(new_next, 4096);
                map(noexcept, allocator.finish, allocator.finish -% finish);
                allocator.finish = finish;
            }
            allocator.next = new_next;
            return old_aligned;
        }
        const new_aligned: u64 = allocator.allocateInternal(new_size_of, align_of);
        copy(new_aligned, old_aligned, old_size_of);
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
