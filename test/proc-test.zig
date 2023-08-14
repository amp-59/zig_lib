const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const sys = zl.sys;
const fmt = zl.fmt;
const elf = zl.elf;
const proc = zl.proc;
const mach = zl.mach;
const time = zl.time;
const meta = zl.meta;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;

pub const runtime_assertions: bool = true;
pub const is_safe: bool = true;
pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub const want_stack_traces: bool = true;
pub const signal_handlers: debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
const Array = mem.UnstructuredStreamView(8, 8, struct {}, .{});
const Mapping = extern struct {
    lb_addr: u64,
    up_addr: u64,
    perms: packed struct {
        read: bool,
        write: bool,
        execute: bool,
        shared: bool,
        private: bool,
    },
    offset: u32,
    device: struct {
        minor: u8,
        major: u8,
    },
    inode: u64,
    pathname: []const u8,
};
fn printHere(x: u64) void {
    var buf: [512]u8 = undefined;
    var len: u64 = fmt.ux64(x).formatWriteBuf(&buf);
    debug.write(buf[0..len]);
    debug.write("\n");
}
fn testFutexWake(futex2: *u32) void {
    proc.futexWake(.{}, futex2, 1) catch {};
}
fn testFutexWait(futex1: *u32) void {
    proc.futexWait(.{}, futex1, 0x10, &.{ .sec = 10 }) catch {};
    futex1.* +%= 16;
}
fn testFutexWakeOp(futex1: *u32, futex2: *u32) void {
    proc.futexWakeOp(.{}, futex1, futex2, 1, 1, .{ .op = .Assign, .cmp = .Equal, .to = 0x20, .from = 0x10 }) catch {};
}
fn testCloneAndFutex() !void {
    var allocator: mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(65536, 16), 65536, {}, testFutexWait, .{&futex1});
    try time.sleep(.{}, .{ .nsec = 0x10000 });
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(65536, 16), 65536, {}, testFutexWakeOp, .{ &futex1, &futex2 });
    try time.sleep(.{}, .{ .nsec = 0x20000 });
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(65536, 16), 65536, {}, testFutexWake, .{&futex2});
    try debug.expectEqual(u32, 32, futex1);
    try debug.expectEqual(u32, 32, futex2);
}

fn testFindNameInPath(vars: [][*:0]u8) !void {
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    const open_spec: file.OpenSpec = .{
        .options = .{ .no_follow = false },
    };
    while (itr.next()) |path| {
        const dir_fd: u64 = file.path(.{}, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: u64 = file.openAt(open_spec, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = try file.status(.{}, fd);
        if (st.isExecutable(proc.getUserId(), proc.getGroupId())) {
            break itr.done();
        }
    }
    while (itr.next()) |path| {
        const dir_fd: u64 = file.path(.{}, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: u64 = file.openAt(open_spec, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = try file.status(.{}, fd);
        if (st.isExecutable(proc.getUserId(), proc.getGroupId())) {
            break itr.done();
        }
    }
}

fn testVClockGettime(aux: *const anyopaque) !void {
    const DynamicLoader = zl.elf.GenericDynamicLoader(.{ .options = .{ .show_defined = true, .show_sections = true } });
    _ = DynamicLoader;
    const vdso_addr: u64 = proc.auxiliaryValue(aux, .vdso_addr).?;

    const ElfInfo = extern struct {
        addr: usize,
        pairs: [tags.len]Pair,
        const Pair = extern struct {
            tag: Tag,
            shdr: *elf.Elf64_Shdr,
        };
        const Tag = enum(u8) {
            @".dynsym" = 0,
            @".dynstr" = 1,
            @".rodata" = 2,
            @".text" = 3,
            @".strtab" = 4,
            @".dynamic" = 5,
        };
        const dynsym_idx: comptime_int = @intFromEnum(Tag.@".dynsym");
        const dynstr_idx: comptime_int = @intFromEnum(Tag.@".dynstr");
        const rodata_idx: comptime_int = @intFromEnum(Tag.@".rodata");
        const text_idx: comptime_int = @intFromEnum(Tag.@".text");
        const strtab_idx: comptime_int = @intFromEnum(Tag.@".strtab");
        const dynamic_idx: comptime_int = @intFromEnum(Tag.@".dynamic");

        const tags = meta.tagList(Tag);
        pub fn init(elf_addr: usize) @This() {
            @setRuntimeSafety(builtin.is_safe);
            const ehdr: *elf.Elf64_Ehdr = @ptrFromInt(elf_addr);
            var shdr: *elf.Elf64_Shdr = @ptrFromInt(elf_addr +% ehdr.e_shoff +% (ehdr.e_shstrndx *% ehdr.e_shentsize));
            var pairs: [tags.len]Pair = comptime builtin.zero([tags.len]Pair);
            var strtab_addr: u64 = elf_addr +% shdr.sh_offset;
            var addr: u64 = elf_addr +% ehdr.e_shoff;
            var shdr_idx: u64 = 0;
            while (shdr_idx != ehdr.e_shnum) : ({
                shdr_idx +%= 1;
                addr +%= ehdr.e_shentsize;
                shdr = @ptrFromInt(addr);
            }) {
                var tags_idx: usize = 0;
                while (tags_idx != tags.len) : (tags_idx +%= 1) {
                    const str: [*:0]u8 = @ptrFromInt(strtab_addr +% shdr.sh_name);
                    var idx: usize = 0;
                    while (str[idx] != 0) : (idx +%= 1) {
                        if (@tagName(tags[tags_idx])[idx] != str[idx]) {
                            break;
                        }
                    } else {
                        pairs[tags_idx].shdr = shdr;
                        pairs[tags_idx].tag = tags[tags_idx];
                    }
                }
            }
            return .{ .addr = elf_addr, .pairs = pairs };
        }
        fn lookup(elf_info: *@This(), symbol: []const u8) ?elf.Elf64_Sym {
            var dyn_idx: usize = 1;
            const pairs = elf_info.pairs;
            const dynsym: [*]elf.Elf64_Sym = @ptrFromInt(elf_info.addr +% pairs[dynsym_idx].shdr.sh_offset);
            while (dyn_idx != @divExact(pairs[dynsym_idx].shdr.sh_size, @sizeOf(elf.Elf64_Sym))) : (dyn_idx +%= 1) {
                const sym: elf.Elf64_Sym = dynsym[dyn_idx];
                const str: [*]u8 = @ptrFromInt(elf_info.addr +% pairs[dynstr_idx].shdr.sh_offset +% sym.st_name);
                var idx: usize = 0;
                while (str[idx] != 0) : (idx +%= 1) {
                    if (symbol[idx] != str[idx]) break;
                } else {
                    return sym;
                }
            }
            return null;
        }
    };

    //var elf_info: DynamicLoader.Info = DynamicLoader.Info.init(vdso_addr);
    var elf_info: ElfInfo = ElfInfo.init(vdso_addr);
    if (elf_info.lookup("clock_gettime")) |symbol| {
        const clock_gettime: time.ClockGetTime = @ptrFromInt(vdso_addr +% symbol.st_value);
        const ts1: time.TimeSpec = try time.get(.{}, .realtime);
        const ts2: time.TimeSpec = try time.get(.{}, .realtime);
        var vts1: time.TimeSpec = undefined;
        var vts2: time.TimeSpec = undefined;
        _ = clock_gettime(.realtime, &vts1);
        _ = clock_gettime(.realtime, &vts2);
        const ts_diff: time.TimeSpec = time.diff(ts2, ts1);
        const vts_diff: time.TimeSpec = time.diff(vts2, vts1);
        try debug.expectEqual(u64, ts_diff.sec, 0);
        try debug.expectBelowOrEqual(u64, ts_diff.nsec, 1000);
        try debug.expectEqual(u64, vts_diff.sec, 0);
        try debug.expectBelowOrEqual(u64, vts_diff.nsec, 100);
    } else {
        return error.LookupFailed;
    }
}
fn handlerFn(_: sys.SignalCode) void {}
fn handlerSigInfoFn(_: sys.SignalCode, _: *const proc.SignalInfo, _: ?*const anyopaque) void {
    proc.exit(0);
}
fn testUpdateSignalAction() !void {
    var buf: [4096]u8 = undefined;
    recursion(&buf);
}
fn fault() void {
    var addr: u64 = 0x4000000;
    @as(*u8, @ptrFromInt(addr)).* = '0';
}
fn recursion(buf: *[4096]u8) void {
    var next: [4096]u8 = undefined;
    @memcpy(&next, buf);
    recursion(&next);
}
pub fn main(_: [][*:0]u8, vars: [][*:0]u8, aux: anytype) !void {
    _ = aux;
    try testCloneAndFutex();
    try testFindNameInPath(vars);
    //try testVClockGettime(aux);
    try testUpdateSignalAction();
    proc.about.sampleAllReports();
}
