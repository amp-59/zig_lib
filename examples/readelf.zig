const srg = @import("zig_lib");
const sys = srg.sys;
const mem = srg.mem;
const exe = srg.exe;
const fmt = srg.fmt;
const file = srg.file;
const time = srg.time;
const meta = srg.meta;
const mach = srg.mach;
const proc = srg.proc;
const spec = srg.spec;
const build = srg.build;
const builtin = srg.builtin;

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

pub const logging_default: builtin.Logging.Default = .{
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
pub const AddressSpace = spec.address_space.regular_128;

const PrimaryAllocator = mem.GenericArenaAllocator(.{ .arena_index = 24 });
const SecondaryAllocator = mem.GenericArenaAllocator(.{ .arena_index = 32 });

const Random = file.DeviceRandomBytes(4096);
const PrintArray = mem.StaticString(4096);
const StaticPath = mem.StructuredAutomaticVector(u8, &@as(u8, 0), 4096, 1, .{});

const Mapping = SecondaryAllocator.UnstructuredStreamVector(64, 64);
const MappingI = @typeInfo(Mapping).Struct.fields[0].type;
const Holder64 = SecondaryAllocator.StructuredHolder(u64);
const Holder64I = @typeInfo(Holder64).Struct.fields[0].type;
const Many8 = SecondaryAllocator.StructuredVector(u8);
const Many8I = @typeInfo(Many8).Struct.fields[0].type;
const Many64 = SecondaryAllocator.StructuredVector(u64);
const Many64I = @typeInfo(Many64).Struct.fields[0].type;

const build_dynamic: bool = false;
const is_verbose: bool = true;

var random: Random = .{};

const unlink_spec: file.UnlinkSpec = .{
    .errors = null,
    .logging = .{ .Success = true },
};
const so_open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null },
    .logging = .{},
};
const so_map_spec: file.MapSpec = .{
    .options = spec.mmap.options.object,
    .logging = .{},
};
const close_spec: file.CloseSpec = .{
    .errors = null,
    .logging = .{},
};
fn showHeader(elf_header: exe.Header) void {
    var array: PrintArray = .{};
    array.writeFormat(fmt.any(elf_header));
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn showDynamicSymbolEntry(defined_name: [:0]const u8, st_entry: exe.Elf64_Sym) void {
    var array: PrintArray = .{};
    array.writeMany("lookup: \"");
    array.writeMany(defined_name);
    array.writeMany("\", ");
    array.writeFormat(fmt.any(st_entry));
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn showProgramHeader(header_index: u64, p_header: exe.Elf64_Phdr) void {
    var array: PrintArray = .{};
    array.writeFormat(fmt.ux64(header_index));
    array.writeMany(":\t");
    array.writeFormat(fmt.any(p_header));
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn showSectionHeader(header_index: u64, s_header: exe.Elf64_Shdr) void {
    var array: PrintArray = .{};
    array.writeFormat(fmt.ux64(header_index));
    array.writeMany(":\t");
    array.writeFormat(fmt.any(s_header));
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn showDynamicSectionEntry(d_header: exe.Elf64_Dyn) void {
    var array: PrintArray = .{};
    array.writeFormat(fmt.any(d_header));
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn showLibraryUpToDate(src_path: [:0]const u8, so_path: [:0]const u8, src_stat: file.Stat, so_stat: file.Stat) void {
    const src_dt: time.DateTime = time.DateTime.init(src_stat.ctime.sec);
    const so_dt: time.DateTime = time.DateTime.init(so_stat.ctime.sec);
    var array: PrintArray = .{};
    array.writeMany(so_path);
    array.writeMany(" @ ");
    array.writeFormat(fmt.dt(so_dt));
    array.writeMany(" newer than ");
    array.writeMany(src_path);
    array.writeMany(" @ ");
    array.writeFormat(fmt.dt(src_dt));
    array.writeMany("\n");
    builtin.debug.write(array.readAll());
}
fn read(ref: *Many8I, fd: u64) !u64 {
    return sys.read(fd, ref.next(), ref.available());
}
fn appendIO(allocator_1: *SecondaryAllocator, ref: *Many8I, fd: u64) !void {
    var read_amt: u64 = try read(ref, fd);
    while (read_amt != 0) : (read_amt = try read(ref, fd)) {
        if (read_amt == ref.available()) {
            try allocator_1.resizeManyIncrement(Many8I, ref, .{ .bytes = 64 });
        }
        ref.define(read_amt);
    }
}
fn getLineOffsets(allocator_1: *SecondaryAllocator, many_8: Many8) !Many64 {
    var holder_64: Holder64 = Holder64.init(allocator_1);
    for (many_8.readAll(), 0..) |c, i| {
        if (c == '\n') {
            try holder_64.appendOne(allocator_1, i);
        }
    }
    return .{ .impl = try allocator_1.convertHolderMany(Holder64I, Many64I, holder_64.impl) };
}
fn compile(vars: [][*:0]u8, src_path: [:0]const u8, so_path: [:0]const u8) !void {
    var exe_order: build.BuildCmd = .{
        .root = src_path,
        .emit_bin = .{ .yes = so_path },
        .cmd = .lib,
        .O = .ReleaseSmall,
        .dynamic = true,
        .pic = true,
    };
    const src_stat: file.Stat = file.stat(.{ .errors = null }, src_path);
    if (file.stat(.{}, so_path)) |so_stat| {
        if (so_stat.mtime.sec < src_stat.mtime.sec) {
            _ = try exe_order.compile(vars);
        } else if (is_verbose) {
            showLibraryUpToDate(src_path, so_path, src_stat, so_stat);
        }
    } else |stat_err| {
        switch (stat_err) {
            error.NoSuchFileOrDirectory => {
                _ = try exe_order.compile(vars);
            },
            else => {
                return stat_err;
            },
        }
    }
}
fn getProgramOffset(header_array: anytype, elf_header: exe.Header) !u64 {
    const T: type = @TypeOf(header_array.*);
    const PhdrIterator = exe.ProgramHeaderIterator(T);
    defer header_array.unstreamAll();
    var phdr_itr: PhdrIterator = PhdrIterator.init(elf_header, header_array);
    while (phdr_itr.next()) |phdr| {
        if (is_verbose) {
            showProgramHeader(phdr_itr.index, phdr);
        }
        if (phdr.p_flags.check(.X)) {
            return phdr.p_offset -% phdr.p_paddr;
        }
    }
    return error.MissingExecutableProgram;
}
fn getSectionAddress(header_array: anytype, fn_name: [:0]const u8, elf_header: exe.Header) !u64 {
    const T: type = @TypeOf(header_array.*);
    defer header_array.unstreamAll();
    const ShdrIterator = exe.SectionHeaderIterator(T);
    var shdr_itr: ShdrIterator = ShdrIterator.init(elf_header, header_array);
    var header_index: u64 = 0;
    var dynsym_size: u64 = 0;
    while (shdr_itr.next()) |shdr| {
        if (is_verbose) {
            showSectionHeader(header_index, shdr);
        }
        if (shdr.sh_type == .DYNSYM) {
            dynsym_size = shdr.sh_size;
        }
        if (shdr.sh_type == .DYNAMIC) {
            const dynamic: []const exe.Elf64_Dyn =
                header_array.readManyAt(exe.Elf64_Dyn, .{ .bytes = shdr.sh_offset });
            var dynamic_index: u64 = 0;
            var symtab_addr: u64 = 0;
            var symtab_ents: u64 = 0;
            var strtab_addr: u64 = 0;
            while (dynamic_index != dynamic.len) : (dynamic_index += 1) {
                var d_entry: exe.Elf64_Dyn = dynamic[dynamic_index];
                if (is_verbose) {
                    showDynamicSectionEntry(d_entry);
                }
                if (d_entry.d_tag == .SYMTAB) {
                    symtab_addr = d_entry.d_val;
                    const b0: bool = (dynamic[dynamic_index + 1].d_tag == .SYMENT);
                    const b1: bool = (dynamic[dynamic_index + 2].d_tag == .STRTAB);
                    if (builtin.int2a(bool, b0, b1)) {
                        symtab_ents = dynamic[dynamic_index + 1].d_val;
                        strtab_addr = dynamic[dynamic_index + 2].d_val;
                        break;
                    }
                }
                if (d_entry.d_tag == .SYMENT) {
                    symtab_ents = d_entry.d_val;
                }
                if (d_entry.d_tag == .STRTAB) {
                    strtab_addr = d_entry.d_val;
                }
                if (d_entry.d_tag == .NULL) {
                    const b0: bool = symtab_addr != 0;
                    const b1: bool = symtab_ents != 0;
                    const b2: bool = strtab_addr != 0;
                    if (builtin.int3a(bool, b0, b1, b2)) {
                        break;
                    }
                    return error.MissingSymbolTable;
                }
            }
            const symtab: []const exe.Elf64_Sym =
                header_array.readManyAt(exe.Elf64_Sym, .{ .bytes = symtab_addr });
            const strtab: [:0]const u8 =
                header_array.readManyWithSentinelAt(u8, .{ .bytes = strtab_addr }, 0);
            var st_index: u64 = 1;
            while (st_index * symtab_ents != dynsym_size) {
                const st_entry: exe.Elf64_Sym = symtab[st_index];
                const defined_name: [:0]const u8 = meta.manyToSlice(strtab[st_entry.st_name..].ptr);
                const undefined_name: [:0]const u8 = meta.manyToSlice(fn_name);
                if (mem.testEqualMany(u8, undefined_name, defined_name)) {
                    return st_entry.st_value;
                }
                st_index += 1;
            } else {
                st_index = 1;
                while (st_index * symtab_ents != dynsym_size) : (st_index += 1) {
                    const st_entry: exe.Elf64_Sym = symtab[st_index];
                    const defined_name: [:0]const u8 = meta.manyToSlice(strtab[st_entry.st_name..].ptr);
                    showDynamicSymbolEntry(defined_name, st_entry);
                }
                return error.UndefinedSymbol;
            }
        }
        header_index += 1;
    }
    return error.MissingDynamicSection;
}
fn mload(header_array: anytype, fn_name: [:0]const u8, comptime T: type) !T {
    const elf_header: exe.Header = try exe.Header.parse(header_array);
    if (is_verbose) {
        showHeader(elf_header);
    }
    const offset: u64 = try getProgramOffset(header_array, elf_header);
    const vaddr: u64 = try getSectionAddress(header_array, fn_name, elf_header);
    return @intToPtr(T, header_array.impl.start() +% vaddr +% offset);
}

fn fload(fd: u64, fn_name: [:0]const u8, comptime T: type) !T {
    const arena: mem.Arena = builtin.AddressSpace.arena(1);
    const s_lb_addr: u64 = arena.low();
    const s_ub_addr: u64 = try file.map(so_map_spec, s_lb_addr, fd);
    const s_ab_addr: u64 = mach.alignA64(s_lb_addr, 8);
    const s_up_addr: u64 = mach.alignA64(s_ub_addr, 4096);
    var header_array: Mapping = .{ .impl = MappingI.construct(.{
        .lb_addr = s_lb_addr,
        .ab_addr = s_ab_addr,
        .ss_addr = s_ab_addr,
        .up_addr = s_up_addr,
    }) };
    header_array.impl.define(s_ub_addr - s_lb_addr);
    return mload(&header_array, fn_name, T);
}
fn load(so_path: [:0]const u8, fn_name: [:0]const u8, comptime T: type) !T {
    return fload(try file.open(so_open_spec, so_path), fn_name, T);
}

const Options = struct {
    jit_mode: bool = false,
    direct_lookup: bool = false,
    env_src: ?[:0]const u8 = null,

    pub const Map = proc.GenericOptions(Options);
};

const opt_map: []const Options.Map = meta.slice(Options.Map, .{ // zig fmt: off
    .{ .field_name = "env_src",        .short = "-f",  .long = "--file",   .assign = .{ .argument = "pathname" } },
    .{ .field_name = "direct_lookup",  .short = "-l",                      .assign = .{ .boolean = false } },
    .{ .field_name = "jit_mode",       .long = "--no-fixed",               .assign = .{ .boolean = false } },
}); // zig fmt: on

pub fn threadMain(address_space: *AddressSpace, args_in: [][*:0]u8, vars: [][*:0]u8) anyerror!void {
    if (return) {}
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opt_map);
    var result_array: PrintArray = .{};
    if (args.len == 0) {
        return;
    }
    var allocator: PrimaryAllocator = try PrimaryAllocator.init(address_space);
    defer allocator.deinit(address_space);
    var tmp_dir_path: StaticPath = .{};
    tmp_dir_path.writeMany("/run/user/1000/elf_test");
    file.makeDir(.{ .logging = .{} }, tmp_dir_path.readAllWithSentinel(0)) catch |mkdir_error| {
        if (mkdir_error != error.FileExists) {
            return mkdir_error;
        }
    };
    var so_path: StaticPath = tmp_dir_path;
    so_path.writeAny(spec.reinterpret.fmt, .{ "/elf", fmt.ux16(random.readOne(u16)), ".so" });

    if (options.direct_lookup) {
        if (args.len > 2) {
            _ = try load(meta.manyToSlice(args[1]), meta.manyToSlice(args[2]), *const fn () void);
        }
    } else if (options.jit_mode) {
        var src_path: StaticPath = tmp_dir_path;
        src_path.writeAny(spec.reinterpret.fmt, .{ "/src", fmt.ux16(random.readOne(u16)), ".zig" });
        const fd: u64 = try file.create(.{ .options = .{ .exclusive = true }, .logging = .{} }, src_path.readAllWithSentinel(0));
        defer {
            file.close(close_spec, fd);
            file.unlink(unlink_spec, src_path.readAllWithSentinel(0));
        }
        const fn_defn: [:0]const u8 = meta.manyToSlice(args[1]);
        const fn_name: [:0]const u8 = meta.manyToSlice(args[2]);
        var array: PrintArray = .{};
        array.writeMany(fn_defn);
        array.writeMany("\n");
        array.writeMany("export fn __call() callconv(.C) @typeInfo(@TypeOf(");
        array.writeMany(fn_name);
        array.writeMany(")).Fn.return_type.? {");
        array.writeMany("    return ");
        array.writeMany(fn_name);
        array.writeMany("(");
        for (args[3..]) |arg| {
            array.writeMany(meta.manyToSlice(arg));
            array.writeMany(",");
        }
        array.writeMany(");\n");
        array.writeMany("}");
        try file.write(fd, array.readAll());
        try compile(vars, src_path.readAllWithSentinel(0), so_path.readAllWithSentinel(0));
        const dlfn: *fn () callconv(.C) u64 = try load(so_path.readAllWithSentinel(0), "__call", *fn () callconv(.C) u64);
        const result: u64 = @call(.auto, dlfn, .{});
        result_array.writeAny(spec.reinterpret.fmt, .{ '\n', fn_name, ": ", fmt.ud64(result), "\n\n" });
    } else {
        switch (args.len) {
            1 => {
                var src_path: StaticPath = .{};
                src_path.writeMany(builtin.build_root.? ++ "/test/readelf/exe-test.zig");
                try compile(vars, src_path.readAllWithSentinel(0), so_path.readAllWithSentinel(0));
                defer {
                    file.unlink(unlink_spec, so_path.readAllWithSentinel(0));
                }
                const dlfn: *fn () callconv(.C) u64 = try load(so_path.readAllWithSentinel(0), "relativeJumpA", *fn () callconv(.C) u64);
                const result: u64 = dlfn();
                result_array.writeAny(spec.reinterpret.fmt, .{ fmt.ud64(result), '\n' });
            },
            2 => {
                try file.write(2, "test command usage: <zig_source_with_exports> <name_of_exported_function> [function args ... ]\n");
            },
            3 => {
                const src_root: [:0]const u8 = meta.manyToSlice(args[1]);
                const fn_name: [:0]const u8 = meta.manyToSlice(args[2]);
                var src_path: StaticPath = .{};
                src_path.writeMany(src_root);
                try compile(vars, src_path.readAllWithSentinel(0), so_path.readAllWithSentinel(0));
                defer {
                    file.unlink(unlink_spec, so_path.readAllWithSentinel(0));
                }
                const dlfn: *fn () callconv(.C) u64 =
                    try load(so_path.readAllWithSentinel(0), fn_name, *fn () callconv(.C) u64);
                result_array.writeAny(spec.reinterpret.fmt, .{ fmt.ud64(dlfn()), '\n' });
            },
            4 => {
                const src_root: [:0]const u8 = meta.manyToSlice(args[1]);
                const fn_name: [:0]const u8 = meta.manyToSlice(args[2]);
                const arg0_s: [:0]const u8 = meta.manyToSlice(args[3]);
                const arg0: u64 = try builtin.parse.any(u64, arg0_s);
                var src_path: StaticPath = .{};
                src_path.writeMany(src_root);
                try compile(vars, src_path.readAllWithSentinel(0), so_path.readAllWithSentinel(0));
                defer {
                    file.unlink(unlink_spec, so_path.readAllWithSentinel(0));
                }
                const dlfn: *fn (u64) callconv(.C) u64 =
                    try load(so_path.readAllWithSentinel(0), fn_name, *fn (u64) callconv(.C) u64);
                const result: u64 = dlfn(arg0);
                result_array.writeAny(spec.reinterpret.fmt, .{ fmt.ud64(result), '\n' });
            },
            5 => {
                const src_root: [:0]const u8 = meta.manyToSlice(args[1]);
                const fn_name: [:0]const u8 = meta.manyToSlice(args[2]);
                const arg0_s: [:0]const u8 = meta.manyToSlice(args[3]);
                const arg1_s: [:0]const u8 = meta.manyToSlice(args[4]);
                const arg0: u64 = try builtin.parse.any(u64, arg0_s);
                const arg1: u64 = try builtin.parse.any(u64, arg1_s);
                var src_path: StaticPath = .{};
                src_path.writeMany(src_root);
                try compile(vars, src_path.readAllWithSentinel(0), so_path.readAllWithSentinel(0));
                defer {
                    file.unlink(unlink_spec, so_path.readAllWithSentinel(0));
                }
                const dlfn: *fn (u64, u64) callconv(.C) u64 =
                    try load(so_path.readAllWithSentinel(0), fn_name, *fn (u64, u64) callconv(.C) u64);
                const result: u64 = dlfn(arg0, arg1);
                result_array.writeAny(spec.reinterpret.fmt, .{ fmt.ud64(result), '\n' });
            },
            else => {},
        }
    }
    builtin.debug.write(result_array.readAll());
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) anyerror!void {
    var address_space: AddressSpace = .{};
    try threadMain(&address_space, args, vars);
}
