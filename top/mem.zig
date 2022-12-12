const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

const _reference = @import("./reference.zig");
const _container = @import("./container.zig");

const mem = @This();

pub usingnamespace _reference;
pub usingnamespace _container;

pub const ArenaError = error{ UnderSupply, OverSupply };

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
pub const PartSpec = struct {
    options: Options = .{},
    errors: ?type = ArenaError,
    logging: bool = true,
    const Options = struct {
        thread_safe: bool = true,
    };
};
pub const MapSpec = struct {
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.mmap_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct {
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
        var flags_bitfield: Map = .{ .tag = .fixed_no_replace };
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
        var prot_bitfield: Prot = .{ .val = 0 };
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
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const MoveSpec = struct {
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.mremap_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct { no_unmap: bool = false };
    pub fn flags(comptime spec: Specification) Remap {
        var flags_bitfield: Remap = .{ .val = 0 };
        if (spec.options.no_unmap) {
            flags_bitfield.set(.no_unmap);
        }
        flags_bitfield.set(.fixed);
        flags_bitfield.set(.may_move);
        return flags_bitfield;
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const RemapSpec = struct {
    errors: ?[]const sys.ErrorCode = sys.mremap_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const UnmapSpec = struct {
    errors: ?[]const sys.ErrorCode = sys.munmap_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const AdviseSpec = struct {
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.madvise_errors,
    return_type: type = void,
    logging: bool = builtin.is_verbose,
    const Options = struct {
        usage: ?Usage = null,
        action: ?Action = null,
        property: ?Property = null,
    };
    const Usage = enum { normal, random, sequential, immediate, deferred };
    const Action = enum { reclaim, free, remove, pageout, poison };
    const Property = union(enum) { mergeable: bool, hugepage: bool, dump: bool, fork: bool, wipe_on_fork: bool };
    pub fn advice(comptime spec: AdviseSpec) Advice {
        var flags: Advice = .{ .val = 0 };
        if (spec.options.usage) |usage| {
            switch (usage) {
                .normal => {
                    flags.set(.normal);
                },
                .random => {
                    flags.set(.random);
                },
                .sequential => {
                    flags.set(.sequential);
                },
                .immediate => {
                    flags.set(.immediate);
                },
                .deferred => {
                    flags.set(.deferred);
                },
            }
        }
        if (spec.options.action) |action| {
            switch (action) {
                .remove => {
                    flags.set(.remove);
                },
                .free => {
                    flags.set(.free);
                },
                .reclaim => {
                    flags.set(.reclaim);
                },
                .pageout => {
                    flags.set(.pageout);
                },
                .poison => {
                    flags.set(.poison);
                },
            }
        }
        if (spec.options.property) |property| {
            switch (property) {
                .mergeable => |mergeable| {
                    if (mergeable) {
                        flags.set(.mergeable);
                    } else {
                        flags.set(.unmergeable);
                    }
                },
                .hugepage => |hugepage| {
                    if (hugepage) {
                        flags.set(.hugepage);
                    } else {
                        flags.set(.no_hugepage);
                    }
                },
                .dump => |dump| {
                    if (dump) {
                        flags.set(.dump);
                    } else {
                        flags.set(.no_dump);
                    }
                },
                .fork => |fork| {
                    if (fork) {
                        flags.set(.fork);
                    } else {
                        flags.set(.no_fork);
                    }
                },
                .wipe_on_fork => |wipe_on_fork| {
                    if (wipe_on_fork) {
                        flags.set(.wipe_on_fork);
                    } else {
                        flags.set(.keep_on_fork);
                    }
                },
            }
        }
        if (flags.val == 0) {
            flags.set(.normal);
        }
        return flags;
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
    pub usingnamespace sys.FunctionInterfaceSpec(AdviseSpec);
};
pub const Amount = union(enum) { bytes: u64, count: u64 };
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
pub fn pointerMany(comptime child: type, s_lb_addr: u64, n: u64) []child {
    return builtin.intToPtr([*]child, s_lb_addr)[0..n];
}
pub fn pointerManyWithSentinel(comptime child: type, s_lb_addr: u64, n: u64, comptime sentinel: child) [:sentinel]child {
    return builtin.intToPtr([*]child, s_lb_addr)[0..n :sentinel];
}
pub fn pointerCount(comptime child: type, s_lb_addr: u64, comptime n: u64) *[n]child {
    return builtin.intToPtr(*[n]child, s_lb_addr)[0..n];
}
pub fn pointerCountWithSentinel(comptime child: type, s_lb_addr: u64, comptime n: u64, comptime sentinel: child) *[n:sentinel]child {
    return builtin.intToPtr(*[n]child, s_lb_addr)[0..n :sentinel];
}
pub fn pointerOneWithSentinel(comptime child: type, s_lb_addr: u64, comptime sentinel: child) [*:sentinel]child {
    return builtin.intToPtr([*:sentinel]child, s_lb_addr);
}
pub fn map(comptime spec: MapSpec, addr: u64, len: u64) spec.Unwrapped(.mmap) {
    const mmap_prot: Prot = spec.prot();
    const mmap_flags: Map = spec.flags();
    if (spec.call(.mmap, .{ addr, len, mmap_prot.val, mmap_flags.val, ~@as(u64, 0), 0 })) {
        if (spec.logging) {
            debug.mapNotice(addr, len);
        }
    } else |map_error| {
        if (spec.logging or builtin.is_correct) {
            debug.mapError(map_error, addr, len);
        }
        return map_error;
    }
}
pub fn move(comptime spec: MoveSpec, old_addr: u64, old_len: u64, new_addr: u64) spec.Unwrapped(.mremap) {
    const mremap_flags: Remap = spec.flags();
    if (spec.call(.mremap, .{ old_addr, old_len, old_len, mremap_flags.val, new_addr })) {
        if (spec.logging) {
            debug.remapNotice(old_addr, old_len, new_addr, null);
        }
    } else |mremap_error| {
        if (spec.logging or builtin.is_correct) {
            debug.remapError(mremap_error, old_addr, old_len, new_addr, null);
        }
        return mremap_error;
    }
}
pub fn resize(comptime spec: RemapSpec, old_addr: u64, old_len: u64, new_len: u64) spec.Unwrapped(.mremap) {
    if (spec.call(.mremap, .{ old_addr, old_len, new_len, 0, 0 })) {
        if (spec.logging) {
            debug.remapNotice(old_addr, old_len, null, new_len);
        }
    } else |mremap_error| {
        if (spec.logging or builtin.is_correct) {
            debug.remapError(mremap_error, old_addr, old_len, null, new_len);
        }
        return mremap_error;
    }
}
pub fn unmap(comptime spec: UnmapSpec, addr: u64, len: u64) spec.Unwrapped(.munmap) {
    if (spec.call(.munmap, .{ addr, len })) {
        if (spec.logging) {
            debug.unmapNotice(addr, len);
        }
    } else |unmap_error| {
        if (spec.logging or builtin.is_correct) {
            debug.unmapError(unmap_error, addr, len);
        }
        return unmap_error;
    }
}
pub fn advise(comptime spec: AdviseSpec, addr: u64, len: u64) spec.Unwrapped(.madvise) {
    const advice: Advice = spec.advice();
    if (spec.call(.madvise, .{ addr, len, advice.val })) {
        if (spec.logging) {
            debug.adviseNotice(addr, len, spec.describe());
        }
    } else |madvise_error| {
        if (spec.logging or builtin.is_correct) {
            debug.adviseError(madvise_error, addr, len, spec.describe());
        }
        return madvise_error;
    }
}
pub const debug = opaque {
    const about_map_0_s: []const u8 = "map:            ";
    const about_map_1_s: []const u8 = "map-error:      ";
    const about_brk_1_s: []const u8 = "brk-error:      ";
    const about_unmap_0_s: []const u8 = "unmap:          ";
    const about_unmap_1_s: []const u8 = "unmap-error:    ";
    const about_remap_0_s: []const u8 = "remap:          ";
    const about_remap_1_s: []const u8 = "remap-error:    ";
    const about_resize_0_s: []const u8 = "resize:         ";
    const about_resize_1_s: []const u8 = "resize-error:   ";
    const about_advice_0_s: []const u8 = "advice:         ";
    const about_advice_1_s: []const u8 = "advice-error:   ";
    fn print(buf: []u8, ss: []const []const u8) void {
        var len: u64 = 0;
        for (ss) |s| {
            for (s) |c, i| buf[len +% i] = c;
            len +%= s.len;
        }
        sys.noexcept.write(2, @ptrToInt(buf.ptr), len);
    }
    pub fn mapNotice(addr: u64, len: u64) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_map_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",          builtin.fmt.ux64(addr +% len).readAll(),
            ", ",          builtin.fmt.ud64(len).readAll(),
            " bytes\n",
        });
    }
    pub fn mapError(map_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        var buf: [4096 +% 512]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_map_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",          builtin.fmt.ux64(addr +% len).readAll(),
            ", ",          builtin.fmt.ud64(len).readAll(),
            " bytes (",    @errorName(map_error),
            ")\n",
        });
    }
    fn unmapNotice(addr: u64, len: u64) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_unmap_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",            builtin.fmt.ux64(addr +% len).readAll(),
            ", ",            builtin.fmt.ud64(len).readAll(),
            " bytes\n",
        });
    }
    fn unmapError(unmap_error: anytype, addr: u64, len: u64) void {
        @setCold(true);
        var buf: [4096 +% 512]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_unmap_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",            builtin.fmt.ux64(addr +% len).readAll(),
            ", ",            builtin.fmt.ud64(len).readAll(),
            " bytes (",      @errorName(unmap_error),
            ")\n",
        });
    }
    fn adviseNotice(addr: u64, len: u64, description_s: []const u8) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_advice_0_s, builtin.fmt.ux64(addr).readAll(),
            "..",             builtin.fmt.ux64(addr +% len).readAll(),
            ", ",             builtin.fmt.ud64(len).readAll(),
            " bytes, ",       description_s,
            "\n",
        });
    }
    fn adviseError(madvise_error: anytype, addr: u64, len: u64, description_s: []const u8) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_advice_1_s, builtin.fmt.ux64(addr).readAll(),
            "..",             builtin.fmt.ux64(addr +% len).readAll(),
            ", ",             builtin.fmt.ud64(len).readAll(),
            " bytes, ",       description_s,
            ", (",            @errorName(madvise_error),
            ")\n",
        });
    }
    pub fn remapNotice(old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const operation_s: []const u8 = mach.cmovx(new_addr != old_addr, about_remap_0_s, about_resize_0_s);
        var buf: [4096 +% 512]u8 = undefined;
        print(&buf, &[_][]const u8{
            operation_s, builtin.fmt.ux64(old_addr).readAll(),
            "..",        builtin.fmt.ux64(old_addr +% old_len).readAll(),
            " -> ",      builtin.fmt.ux64(new_addr).readAll(),
            "..",        builtin.fmt.ux64(new_addr +% new_len).readAll(),
            notation_s,  builtin.fmt.ud64(abs_diff).readAll(),
            " bytes\n",
        });
    }
    fn remapError(mremap_err: anytype, old_addr: u64, old_len: u64, maybe_new_addr: ?u64, maybe_new_len: ?u64) void {
        const new_addr: u64 = maybe_new_addr orelse old_addr;
        const new_len: u64 = maybe_new_len orelse old_len;
        const abs_diff: u64 = builtin.max(u64, new_len, old_len) -% builtin.min(u64, new_len, old_len);
        const notation_s: []const u8 = mach.cmovx(new_len < old_len, ", -", ", +");
        const operation_s: []const u8 = mach.cmovx(new_addr != old_addr, about_remap_1_s, about_resize_1_s);
        var buf: [4096 +% 512]u8 = undefined;
        print(&buf, &[_][]const u8{
            operation_s, builtin.fmt.ux64(old_addr).readAll(),
            "..",        builtin.fmt.ux64(old_addr +% old_len).readAll(),
            " -> ",      builtin.fmt.ux64(new_addr).readAll(),
            "..",        builtin.fmt.ux64(new_addr +% new_len).readAll(),
            notation_s,  builtin.fmt.ud64(abs_diff).readAll(),
            " bytes (",  @errorName(mremap_err),
            ")\n",
        });
    }
    fn brkError(brk_error: anytype, old_addr: u64, new_addr: u64) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{
            about_brk_1_s, builtin.fmt.ux64(old_addr).readAll(),
            "..",          builtin.fmt.ux64(new_addr).readAll(),
            ", ",          builtin.fmt.ud64(new_addr -% old_addr).readAll(),
            " bytes (",    @errorName(brk_error),
            ")\n",
        });
    }
};

pub fn StaticArray(comptime child: type, comptime count: u64) type {
    return mem.StructuredAutomaticVector(.{
        .child = child,
        .count = count,
        .low_alignment = @alignOf(child),
    });
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
    automatic_storage: union(enum) {
        read_write_auto: union(enum) {
            structured: AutoAlignment(struct {
                child: type,
                sentinel: in_out(*const anyopaque) = null,
                count: u64,
                low_alignment: in(u64) = null,
            }),
        },
        offset_byte_address: union(enum) {
            read_write_stream_auto: union(enum) {
                structured: AutoAlignment(struct {
                    child: type,
                    sentinel: in_out(*const anyopaque) = null,
                    count: u64,
                    low_alignment: in(u64) = null,
                }),
            },
            undefined_byte_address: union(enum) {
                read_write_stream_push_pop_auto: union(enum) {
                    structured: AutoAlignment(struct {
                        child: type,
                        sentinel: in_out(*const anyopaque) = null,
                        count: u64,
                        low_alignment: in(u64) = null,
                    }),
                },
            },
        },
        undefined_byte_address: union(enum) {
            read_write_push_pop_auto: union(enum) {
                structured: AutoAlignment(struct {
                    child: type,
                    sentinel: in_out(*const anyopaque) = null,
                    count: u64,
                    low_alignment: in(u64) = null,
                }),
            },
        },
    },
    pub const Mode = enum {
        read_write,
        read_write_push_pop,
        read_write_auto,
        read_write_push_pop_auto,
        read_write_stream,
        read_write_stream_push_pop,
        read_write_stream_auto,
        read_write_stream_push_pop_auto,
    };
    // For structures below named 'mutex', iterate through the structure until
    // finding an enum literal, then concatenate direct parent field names to
    // yield the name of one of the category fields. In contexts where multiple
    // names from the same substructure present, these should form a union or
    // enumeration instead of individual boolean options.
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
    fn getMutuallyExclusivePivot(comptime any: anytype) []const []const u8 {
        switch (@typeInfo(@TypeOf(any))) {
            .Struct => |struct_info| {
                var names: []const []const u8 = meta.empty;
                for (struct_info.fields) |field| {
                    for (getMutuallyExclusivePivot(@field(any, field.name))) |name| {
                        if (struct_info.is_tuple) {
                            names = meta.parcel(@as([]const u8, name));
                        } else {
                            names = meta.parcel(@as([]const u8, name ++ "_" ++ field.name));
                        }
                    }
                }
                return names;
            },
            .EnumLiteral => {
                return meta.parcel(@as([]const u8, @tagName(any)));
            },
            else => @compileError(@typeName(@TypeOf(any))),
        }
    }
    comptime {
        for (getMutuallyExclusivePivot(Technique.mutex)) |name| {
            if (!@hasField(Technique, name)) {
                @compileError(name);
            }
        }
        for (getMutuallyExclusivePivot(Fields.mutex)) |name| {
            if (!@hasField(Fields, name)) {
                @compileError(name);
            }
        }
    }

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
        return union(enum) {
            unit_alignment: S,
            lazy_alignment: S,
            disjunct_alignment: S,
        };
    }
    fn AutoAlignment(comptime S: type) type {
        return union(enum) {
            auto_alignment: S,
        };
    }
    fn NoPackedAlignment(comptime S: type) type {
        return union(enum) {
            unit_alignment: S,
            lazy_alignment: S,
        };
    }
    fn StrictAlignment(comptime S: type) type {
        return union(enum) {
            unit_alignment: S,
            disjunct_alignment: S,
        };
    }
    fn AnyAlignment(comptime S: type) type {
        return union(enum) {
            unit_alignment: S,
            lazy_alignment: S,
            super_alignment: S,
            disjunct_alignment: S,
        };
    }
};
