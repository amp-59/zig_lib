const mem = @import("../mem.zig");
const mach = @import("../mach.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");

pub const arena_count: u64 = thread_count + 8;
pub const thread_count: u64 = 16;
pub const stack_aligned_bytes: u64 = 8 * 1024 * 1024;
pub const arena_aligned_bytes: u64 = 8 * 1024 * 1024;
pub const stack_lb_addr: u64 = 0x700000000000;
pub const arena_lb_addr: u64 = stack_up_addr;
pub const stack_up_addr: u64 = stack_lb_addr + (thread_count * stack_aligned_bytes);
pub const arena_up_addr: u64 = arena_lb_addr + (arena_count * arena_aligned_bytes);

pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .label = "arena",
    .idx_type = u8,
    .divisions = arena_count,
    .lb_addr = arena_lb_addr,
    .up_addr = arena_up_addr,
    .errors = preset.address_space.errors.noexcept,
    .logging = preset.address_space.logging.silent,
    .options = .{ .thread_safe = true, .require_map = true, .require_unmap = true },
});
pub const ThreadSpace = mem.GenericRegularAddressSpace(.{
    .label = "stack",
    .idx_type = AddressSpace.Index,
    .divisions = thread_count,
    .lb_addr = stack_lb_addr,
    .up_addr = stack_up_addr,
    .errors = preset.address_space.errors.noexcept,
    .logging = preset.address_space.logging.silent,
    .options = .{ .thread_safe = true },
});

pub const Allocator = mem.GenericRtArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.small_composed,
});
pub const Args = mem.StructuredVector(u8, &@as(u8, 0), 8, Allocator, .{});
pub const Ptrs = mem.StructuredVector([*:0]u8, builtin.anyOpaque(builtin.zero([*:0]u8)), 8, Allocator, .{});

pub const Path = struct {
    absolute: [:0]const u8,
    relative: ?[:0]const u8 = null,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.absolute);
        if (format.relative) |relative| {
            array.writeOne('/');
            array.writeMany(relative);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= format.absolute.len;
        if (format.relative) |relative| {
            len +%= 1;
            len +%= relative.len;
        }
        return len;
    }
    pub fn full(path: Path, allocator: *Allocator) [:0]u8 {
        var ret: [:0]u8 = allocator.allocateIrreversibleWithSentinel(u8, path.absolute.len +% 1 +% path.relative.len);
        const len: u64 = mach.memcpyMulti(ret, &.{ path.absolute, "/", path.relative });
        return ret[0..len :0];
    }
};
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const []const u8 = null,
    pub fn formatWrite(mod: Module, array: anytype) void {
        array.writeMany("--mod\x00");
        array.writeMany(mod.name);
        array.writeOne(':');
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                array.writeMany(dep_name);
                array.writeOne(',');
            }
            if (deps.len != 0) {
                array.undefine(1);
            }
        }
        array.writeOne(':');
        array.writeMany(mod.path);
        array.writeOne(0);
    }
    pub fn formatLength(mod: Module) u64 {
        var len: u64 = 0;
        len +%= 6;
        len +%= mod.name.len;
        len +%= 1;
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                len +%= dep_name.len;
                len +%= 1;
            }
            if (deps.len != 0) {
                len -%= 1;
            }
        }
        len +%= 1;
        len +%= mod.path.len;
        len +%= 1;
        return len;
    }
};
pub const ModuleDependency = struct {
    import: ?[]const u8 = null,
    name: []const u8,
};
pub const ModuleDependencies = struct {
    value: []const ModuleDependency,
    pub fn formatWrite(mod_deps: ModuleDependencies, array: anytype) void {
        array.writeMany("--deps\x00");
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                array.writeMany(name);
                array.writeOne('=');
            }
            array.writeMany(mod_dep.name);
            array.writeOne(',');
        }
        array.overwriteOneBack(0);
    }
    pub fn formatLength(mod_deps: ModuleDependencies) u64 {
        var len: u64 = 0;
        len +%= 7;
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import) |name| {
                len +%= name.len +% 1;
            }
            len +%= mod_dep.name.len +% 1;
        }
    }
};
pub const Macro = struct {
    name: []const u8,
    value: Value,
    const Format = @This();
    const Value = union(enum) {
        string: [:0]const u8,
        symbol: [:0]const u8,
        constant: usize,
        path: Path,
    };
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        array.writeMany("=");
        switch (format.value) {
            .constant => |constant| {
                array.writeAny(preset.reinterpret.print, constant);
            },
            .string => |string| {
                array.writeOne('"');
                array.writeMany(string);
                array.writeOne('"');
            },
            .path => |path| {
                array.writeOne('"');
                array.writeFormat(path);
                array.writeOne('"');
            },
            .symbol => |symbol| {
                array.writeMany(symbol);
            },
        }
        array.writeOne(0);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        len +%= 1;
        switch (format.value) {
            .constant => |constant| {
                len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, constant);
            },
            .string => |string| {
                len +%= 1 +% string.len +% 1;
            },
            .path => |path| {
                len +%= 1 +% path.formatLength() +% 1;
            },
            .symbol => |symbol| {
                len +%= symbol.len;
            },
        }
        len +%= 1;
        return len;
    }
};
pub const CFlags = struct {
    flags: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-cflags");
        array.writeOne(0);
        for (format.flags) |flag| {
            array.writeMany(flag);
            array.writeOne(0);
        }
        array.writeMany("--\x00");
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 8;
        for (format.flags) |flag| {
            len +%= flag.len;
            len +%= 1;
        }
        len +%= 3;
        return len;
    }
};
pub const Files = struct {
    value: []const Path,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        for (format.value) |path| {
            array.writeFormat(path);
            array.writeOne(0);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.paths) |path| {
            len +%= path.formatLength();
            len +%= 1;
        }
        return len;
    }
};
