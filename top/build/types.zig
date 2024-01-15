const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
pub const Path = file.CompoundPath;
pub const Allocator = mem.SimpleAllocator;
const OtherAllocator = mem.dynamic.GenericRtArenaAllocator(.{
    .AddressSpace = builtin.root.Builder.AddressSpace,
    .errors = mem.dynamic.spec.errors.noexcept,
});
pub const File = packed struct {
    /// What this file represents to the node.
    key: Key,
    /// File descriptor.
    fd: u16,
    /// The index of the path this file corresponds to in the node
    /// `paths` list.
    path_idx: u32,
    /// Status for this file.
    st: *file.Status,
    pub const Key = packed union { tag: Tag, flags: Flags, id: u16 };
    pub const Flags = packed struct(u16) {
        idx: u12 = 0,
        is_cached: bool = false,
        is_output: bool = false,
        is_input: bool = false,
        is_source: bool = false,
    };
    pub const Tag = enum(u16) {
        // zig fmt: off
        /// All names relative to this absolute path.
        /// Root group nodes store a path and file handle to this directory.
        build_root = 1,
        /// Temporary state files here.
        /// Root group nodes store a path and file handle to this directory.
        cache_root = 2,
        /// Not our business (yet).
        /// Root group nodes store a path and file handle to this directory.
        global_cache_root = 3,

        /// Root group nodes store a file handle to this directory.
        output_root = 4,

        /// Executables and objects link here.
        /// Root group nodes store a file handle to this directory.
        config_root = 5,

        /// Executables and objects link here.
        /// Root group nodes store a file handle to this directory.
        bin_output_root = 6,
        /// Libraries and archives link here.
        /// Root group nodes store a file handle to this directory.
        lib_output_root = 7,
        /// All sources (assembly, IR, and high level code) link here.
        /// Root group nodes store a file handle to this directory.
        aux_output_root = 8,

        zig_compiler_exe = 9,
        llc_compiler_exe = 10,
        c_compiler_exe = 11,
        cxx_compiler_exe = 12,

        cached_generic      = @bitCast(Flags{ .idx = 0, .is_cached = true }),
        cached_exe          = @bitCast(Flags{ .idx = 1, .is_cached = true }),
        cached_lib          = @bitCast(Flags{ .idx = 2, .is_cached = true }),
        cached_obj          = @bitCast(Flags{ .idx = 3, .is_cached = true }),

        output_generic      = @bitCast(Flags{ .idx = 0, .is_output = true }),
        output_exe          = @bitCast(Flags{ .idx = 1, .is_output = true }),
        output_lib          = @bitCast(Flags{ .idx = 2, .is_output = true }),
        output_obj          = @bitCast(Flags{ .idx = 3, .is_output = true }),
        output_ar           = @bitCast(Flags{ .idx = 4, .is_output = true }),

        output_asm          = @bitCast(Flags{ .idx = 1, .is_output = true, .is_source = true }),
        output_c            = @bitCast(Flags{ .idx = 2, .is_output = true, .is_source = true }),
        output_zir          = @bitCast(Flags{ .idx = 3, .is_output = true, .is_source = true }),
        output_llvm_ir      = @bitCast(Flags{ .idx = 4, .is_output = true, .is_source = true }),
        output_llvm_bc      = @bitCast(Flags{ .idx = 5, .is_output = true, .is_source = true }),
        output_h            = @bitCast(Flags{ .idx = 6, .is_output = true, .is_source = true }),

        input_generic       = @bitCast(Flags{ .idx = 0, .is_input = true }),
        input_exe           = @bitCast(Flags{ .idx = 1, .is_input = true }),
        input_lib           = @bitCast(Flags{ .idx = 2, .is_input = true }),
        input_obj           = @bitCast(Flags{ .idx = 3, .is_input = true }),
        input_ar            = @bitCast(Flags{ .idx = 4, .is_input = true }),

        input_zig           = @bitCast(Flags{ .idx = 1, .is_input = true, .is_source = true }),
        input_asm           = @bitCast(Flags{ .idx = 2, .is_input = true, .is_source = true }),
        input_c             = @bitCast(Flags{ .idx = 3, .is_input = true, .is_source = true }),
        input_h             = @bitCast(Flags{ .idx = 4, .is_input = true, .is_source = true }),
        input_cc            = @bitCast(Flags{ .idx = 5, .is_input = true, .is_source = true }),
        input_hh            = @bitCast(Flags{ .idx = 6, .is_input = true, .is_source = true }),
        input_zig_ir        = @bitCast(Flags{ .idx = 7, .is_input = true, .is_source = true }),
        input_llvm_ir       = @bitCast(Flags{ .idx = 8, .is_input = true, .is_source = true }),
        input_llvm_bc       = @bitCast(Flags{ .idx = 9, .is_input = true, .is_source = true }),
        _,
        // zig fmt: on
        pub fn toggle(tag: *Tag, flags: Flags) bool {
            @setRuntimeSafety(builtin.is_safe);
            const new_tag: File.Tag = @enumFromInt(@intFromEnum(tag.*) ^ @as(u16, @bitCast(flags)));
            const ret: bool = @bitCast(@intFromBool(@popCount(@intFromEnum(new_tag)) ==
                @popCount(@intFromEnum(tag.*))) & @intFromBool(new_tag != tag.*));
            if (ret) tag.* = new_tag;
            return ret;
        }
    };
};
pub const BinaryOutput = enum(u16) {
    exe = @intFromEnum(File.Tag.output_exe),
    lib = @intFromEnum(File.Tag.output_lib),
    obj = @intFromEnum(File.Tag.output_obj),
};
pub const Lists = extern struct {
    buf: [len]List,
    pub const Key = extern union { tag: Tag, info: Info, id: u32 };
    const Info = extern struct {
        idx: u8,
        size_of: u8,
        align_of: u8,
        init_len: u8,
    };
    pub const Tag = enum(u32) {
        /// For groups, lists elements. For workers, lists dependencies.
        /// The zeroth element of this list is always the node's parent node.
        nodes = @bitCast(Info{ .idx = 0, .size_of = @sizeOf(usize), .init_len = 1, .align_of = @alignOf(usize) }),
        depns = @bitCast(Info{ .idx = 1, .size_of = @sizeOf(usize), .init_len = 1, .align_of = @alignOf(usize) }),
        confs = @bitCast(Info{ .idx = 2, .size_of = @sizeOf(usize), .init_len = 1, .align_of = @alignOf(usize) }),
        /// Key:
        /// build
        ///     [0] <build_root> / <output_dir/(bin|lib)> / <(lib)long_name>
        ///     [1] <build_root> / <path/to/source>
        ///     [2] <config_root> / <long_name> (want_build_config=true)
        ///     ...
        /// archive
        ///     [0] <build_root> / <output_dir/lib> / lib<long_name>
        ///     ...
        /// format
        ///     [0] <build_root> / <path/to/target>
        paths = @bitCast(Info{ .idx = 3, .size_of = @sizeOf(Path), .init_len = 1, .align_of = @alignOf(Path) }),
        files = @bitCast(Info{ .idx = 4, .size_of = @sizeOf(File), .init_len = 1, .align_of = @alignOf(File) }),
        /// Used by raw commands and groups to distribute command arguments.
        cmd_args = @bitCast(Info{ .idx = 5, .size_of = @sizeOf([*:0]u8), .init_len = 4, .align_of = @alignOf([*:0]u8) }),
        run_args = @bitCast(Info{ .idx = 6, .size_of = @sizeOf([*:0]u8), .init_len = 4, .align_of = @alignOf([*:0]u8) }),
    };
    pub const List = extern struct {
        addr: *const anyopaque,
        len: usize,
        max_len: usize,
        pub fn add(res: *List, allocator: *Allocator, key: Key) usize {
            defer res.len +%= 1;
            return @call(.auto, Allocator.addGeneric, .{
                allocator,                        key.info.size_of, key.info.align_of, key.info.init_len,
                @as(*usize, @ptrCast(&res.addr)), &res.max_len,     res.len,
            });
        }
    };
    pub fn set(lists: *Lists, comptime T: type, tag: Tag, val: []const T) void {
        @setRuntimeSafety(false);
        lists.buf[@intFromEnum(tag) & 0xff] = .{
            .addr = @ptrCast(val.ptr),
            .len = val.len,
            .max_len = val.len,
        };
    }
    pub fn list(lists: *Lists, tag: Tag) *List {
        @setRuntimeSafety(false);
        return &lists.buf[@intFromEnum(tag) & 0xf];
    }
    pub fn add(lists: *Lists, allocator: *Allocator, tag: Tag) usize {
        @setRuntimeSafety(false);
        return lists.buf[@intFromEnum(tag) & 0xf].add(allocator, @bitCast(@intFromEnum(tag)));
    }
    pub fn get(lists: *const Lists, tag: Tag) *align(8) anyopaque {
        @setRuntimeSafety(false);
        return @constCast(@ptrCast(&lists.buf[@intFromEnum(tag) & 0xf]));
    }
    const len: usize = @typeInfo(Tag).Enum.fields.len;
    comptime {
        @compileError("deprecated");
    }
};

pub const AutoOnOff = enum {
    auto,
    off,
    on,
};
pub const Listen = enum {
    none,
    @"-",
    ipv4,
};
pub const BuildId = enum(u8) {
    fast,
    uuid,
    sha1,
    md5,
    none,
    _,
};
pub const LinkFlags = enum {
    nodelete,
    notext,
    defs,
    origin,
    nocopyreloc,
    now,
    lazy,
    relro,
    norelro,
};
pub const CPU = enum(u7) {
    alderlake,
    amdfam10,
    athlon,
    athlon64,
    athlon64_sse3,
    athlon_4,
    athlon_fx,
    athlon_mp,
    athlon_tbird,
    athlon_xp,
    atom,
    atom_sse4_2_movbe,
    barcelona,
    bdver1,
    bdver2,
    bdver3,
    bdver4,
    bonnell,
    broadwell,
    btver1,
    btver2,
    c3,
    c3_2,
    cannonlake,
    cascadelake,
    cooperlake,
    core2,
    corei7,
    emeraldrapids,
    generic,
    geode,
    goldmont,
    goldmont_plus,
    grandridge,
    graniterapids,
    graniterapids_d,
    haswell,
    i386,
    i486,
    i586,
    i686,
    icelake_client,
    icelake_server,
    ivybridge,
    k6,
    k6_2,
    k6_3,
    k8,
    k8_sse3,
    knl,
    knm,
    lakemont,
    meteorlake,
    nehalem,
    nocona,
    opteron,
    opteron_sse3,
    penryn,
    pentium,
    pentium2,
    pentium3,
    pentium3m,
    pentium4,
    pentium_m,
    pentium_mmx,
    pentiumpro,
    prescott,
    raptorlake,
    rocketlake,
    sandybridge,
    sapphirerapids,
    sierraforest,
    silvermont,
    skx,
    skylake,
    skylake_avx512,
    slm,
    tigerlake,
    tremont,
    westmere,
    winchip2,
    winchip_c6,
    x86_64,
    x86_64_v2,
    x86_64_v3,
    x86_64_v4,
    yonah,
    znver1,
    znver2,
    znver3,
    znver4,
};
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: []const []const u8 = &.{},
    pub fn formatWriteBuf(mod: Module, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..6].* = "--mod\x00".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 6, mod.name);
        ptr[0] = ':';
        ptr += 1;
        for (mod.deps) |dep_name| {
            ptr = fmt.strcpyEqu(ptr, dep_name);
            ptr[0] = ',';
            ptr += 1;
        }
        if (mod.deps.len != 0) {
            ptr -= 1;
        }
        ptr[0] = ':';
        ptr = fmt.strcpyEqu(ptr + 1, mod.path);
        ptr[0] = 0;
        return @intFromPtr(ptr + 1) -% @intFromPtr(buf);
    }
    pub fn formatLength(mod: Module) u64 {
        var len: u64 = 6 +% mod.name.len +% 1;
        for (mod.deps) |dep_name| {
            len +%= dep_name.len +% 1;
        }
        if (mod.deps.len != 0) {
            len -%= 1;
        }
        return len +% 1 +% mod.path.len +% 1;
    }
    pub fn formatParseArgs(allocator: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) Module {
        @setRuntimeSafety(false);
        var idx: usize = 0;
        var len: usize = 0;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ':') {
                if (len == 0) {
                    len = idx;
                } else {
                    break;
                }
            }
        } else {
            unreachable;
        }
        if (idx +% 1 == arg.len) {
            unreachable;
        }
        const ret: Module = .{ .name = arg[0..len], .path = arg[idx +% 1 ..] };
        if (idx != len +% 1) {
            idx = len +% 1;
            len = 1;
        } else {
            return ret;
        }
        var pos: usize = idx;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ',') {
                len +%= 1;
            }
        }
        var deps: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% len, 8));
        idx = pos;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == ',') {
                deps[len] = arg[pos..idx];
                len +%= 1;
                pos = idx +% 1;
            }
        }
        return ret;
    }
};
pub const ModuleDependency = struct {
    import: []const u8 = &.{},
    name: []const u8,

    pub fn formatWriteBuf(mod_dep: ModuleDependency, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..6].* = "--dep\x00".*;
        var ptr: [*]u8 = buf + 6;
        if (mod_dep.import.len != 0) {
            ptr = fmt.strcpyEqu(ptr, mod_dep.import);
            ptr[0] = '=';
            ptr += 1;
        }
        ptr = fmt.strcpyEqu(ptr, mod_dep.name);
        ptr[0] = ',';
        ptr += 1;
        const len: usize = @intFromPtr(ptr) -% @intFromPtr(buf);
        buf[len -% 1] = 0;
        return len;
    }
    pub fn formatLength(mod_dep: ModuleDependency) u64 {
        if (mod_dep.value.len == 0) {
            return 0;
        }
        var len: u64 = 6;
        len +%= mod_dep.import.len +% @intFromBool(mod_dep.import.len != 0);
        len +%= mod_dep.name.len +% 1;
        return len;
    }
    pub fn formatParseArgs(_: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) ModuleDependency {
        return .{ .name = arg };
    }
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
    pub fn formatWriteBuf(mod_deps: ModuleDependencies, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        if (mod_deps.value.len == 0) {
            return 0;
        }
        buf[0..7].* = "--deps\x00".*;
        var ptr: [*]u8 = buf + 7;
        for (mod_deps.value) |mod_dep| {
            if (mod_dep.import.len != 0) {
                ptr = fmt.strcpyEqu(ptr, mod_dep.import);
                ptr[0] = '=';
                ptr += 1;
            }
            ptr = fmt.strcpyEqu(ptr, mod_dep.name);
            ptr[0] = ',';
            ptr += 1;
        }
        const len: usize = @intFromPtr(ptr) -% @intFromPtr(buf);
        buf[len -% 1] = 0;
        return len;
    }
    pub fn formatLength(mod_deps: ModuleDependencies) u64 {
        if (mod_deps.value.len == 0) {
            return 0;
        }
        var len: u64 = 7;
        for (mod_deps.value) |mod_dep| {
            len +%= mod_dep.import.len +% @intFromBool(mod_dep.import.len != 0);
            len +%= mod_dep.name.len +% 1;
        }
        return len;
    }
    pub fn formatParseArgs(_: anytype, _: [][*:0]u8, _: *usize, _: [:0]const u8) []const ModuleDependency {
        return undefined;
    }
};
pub const Macro = struct {
    name: []const u8,
    value: ?[]const u8 = null,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        if (format.value) |value| {
            array.writeMany("=");
            array.writeMany(value);
        }
        array.writeOne(0);
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..2].* = "-D".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 2, format.name);
        if (format.value) |value| {
            ptr[0] = '=';
            ptr += 1;
            ptr = fmt.strcpyEqu(ptr, value);
        }
        ptr[0] = 0;
        return @intFromPtr(ptr + 1) -% @intFromPtr(buf);
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 2 +% format.name.len;
        if (format.value) |value| {
            len +%= 1 +% value.len;
        }
        return len +% 1;
    }
    pub fn formatParseArgs(_: anytype, _: [][*:0]u8, _: *usize, arg: [:0]const u8) Macro {
        @setRuntimeSafety(builtin.is_safe);
        var idx: usize = 0;
        var pos: usize = 0;
        while (idx != arg.len) : (idx +%= 1) {
            if (arg[idx] == '=') {
                pos = idx +% 1;
                if (pos == arg.len) {
                    break;
                }
                return .{
                    .name = arg[0..idx],
                    .value = arg[pos..],
                };
            }
        }
        return .{ .name = arg[0..idx] };
    }
};
pub const ExtraFlags = struct {
    value: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-cflags");
        array.writeOne(0);
        for (format.value) |flag| {
            array.writeMany(flag);
            array.writeOne(0);
        }
        array.writeMany("--\x00");
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..8].* = "-cflags\x00".*;
        var ptr: [*]u8 = buf + 8;
        for (format.value) |flag| {
            ptr = fmt.strcpyEqu(ptr, flag);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr[0..3].* = "--\x00".*;
        ptr += 3;
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 0;
        len +%= 8;
        for (format.value) |flag| {
            len +%= flag.len;
            len +%= 1;
        }
        len +%= 3;
        return len;
    }
    pub fn formatParseArgs(allocator: *Allocator, args: [][*:0]u8, arg_idx: *usize, _: [:0]const u8) ?[]const []const u8 {
        @setRuntimeSafety(builtin.is_safe);
        var idx: usize = arg_idx.*;
        var end: usize = idx;
        while (end != args.len) : (end +%= 1) {
            if (mem.testEqualString("--", mem.terminate(args[end], 0))) {
                arg_idx.* = end;
                idx +%= 1;
                break;
            }
        }
        const len: usize = end -% idx;
        if (len == 0) {
            return null;
        }
        var buf: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% len, 8));
        var pos: usize = 0;
        while (idx != end) : (idx +%= 1) {
            buf[pos] = mem.terminate(args[idx], 0);
            pos +%= 1;
        }
        return buf[0..len];
    }
};
pub const Files = struct {
    value: []const Path,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        for (format.value) |path| {
            array.writeFormat(path);
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        for (format.value) |path| {
            len = len +% path.formatWriteBuf(buf + len);
        }
        return len;
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 0;
        for (format.value) |path| {
            len +%= path.formatLength();
        }
        return len;
    }
};
