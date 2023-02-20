const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub fn map(comptime spec: MapSpec, arena_index: u8) sys.Call(spec.errors.throw, u64) {
    const up_addr = builtin.AddressSpace.high(arena_index);
    const s_bytes: u64 = 8192;
    const st_addr: u64 = up_addr - s_bytes;
    const mmap_prot: mem.Prot = spec.prot();
    const mmap_flags: mem.Map = spec.flags();
    if (meta.wrap(sys.call(.mmap, spec.errors, void, .{ st_addr, s_bytes, mmap_prot.val, mmap_flags.val, ~@as(u64, 0), 0 }))) {
        if (spec.logging.Acquire) {
            mem.debug.mapNotice(st_addr, s_bytes);
        }
    } else |map_error| {
        if (spec.logging.Error) {
            mem.debug.mapError(map_error, st_addr, s_bytes);
        }
        return map_error;
    }
    return st_addr;
}
pub fn unmap(comptime spec: mem.UnmapSpec, arena_index: u8) sys.Call(spec.errors.throw, void) {
    const up_addr = builtin.AddressSpace.high(arena_index);
    const st_addr = mach.alignA64(up_addr - 8192, 4096);
    const len: u64 = up_addr - st_addr;
    if (meta.wrap(sys.call(.munmap, spec.errors, spec.return_type, .{ st_addr, up_addr - st_addr }))) {
        if (spec.logging.Release) {
            mem.debug.unmapNotice(st_addr, len);
        }
    } else |unmap_error| {
        if (spec.logging.Error) {
            mem.debug.unmapError(unmap_error, st_addr, len);
        }
        return unmap_error;
    }
}
pub const MapSpec = struct {
    options: Options,
    errors: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    logging: builtin.Logging.AcquireErrorFault = .{},
    const Specification = @This();
    const Visibility = enum { shared, shared_validate, private };
    const Options = struct {
        visibility: Visibility = .private,
        anonymous: bool = true,
        populate: bool = true,
        read: bool = true,
        write: bool = true,
        exec: bool = true,
        grows_down: bool = true,
        sync: bool = false,
    };
    pub fn flags(comptime spec: Specification) mem.Map {
        var flags_bitfield: mem.Map = .{ .tag = .fixed_no_replace };
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
    pub fn prot(comptime spec: Specification) mem.Prot {
        var prot_bitfield: mem.Prot = .{ .val = 0 };
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
