const top = @import("../zig_lib.zig");
const mem = top.mem;
const fmt = top.fmt;
const exe = top.exe;
const proc = top.proc;
const time = top.time;
const meta = top.meta;
const file = top.file;
const spec = top.spec;
const build = top.build2;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace proc.start;

pub const runtime_assertions: bool = false;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const shdr_size: u64 = @sizeOf(exe.Elf64_Shdr);
const phdr_size: u64 = @sizeOf(exe.Elf64_Phdr);

const Array = mem.UnstructuredStreamView(8, 8, struct {}, .{});

fn programOffset(ehdr_addr: u64) ?u64 {
    const ehdr: *exe.Elf64_Ehdr = @intToPtr(*exe.Elf64_Ehdr, ehdr_addr);
    var addr: u64 = ehdr_addr +% ehdr.e_phoff;
    var idx: u64 = 0;
    while (idx != ehdr.e_phnum) : ({
        idx +%= 1;
        addr +%= phdr_size;
    }) {
        const phdr: *exe.Elf64_Phdr = @intToPtr(*exe.Elf64_Phdr, addr);
        if (phdr.p_flags.check(.X)) {
            return phdr.p_offset -% phdr.p_paddr;
        }
    }
    return null;
}
fn sectionAddress(ehdr_addr: u64, symbol: [:0]const u8) ?u64 {
    const ehdr: *exe.Elf64_Ehdr = @intToPtr(*exe.Elf64_Ehdr, ehdr_addr);
    var symtab_addr: u64 = 0;
    var strtab_addr: u64 = 0;
    var symtab_ents: u64 = 0;
    var dynsym_size: u64 = 0;
    var addr: u64 = ehdr_addr +% ehdr.e_shoff;
    var idx: u64 = 0;
    while (idx != ehdr.e_shnum) : ({
        idx +%= 1;
        addr = addr +% shdr_size;
    }) {
        const shdr: *exe.Elf64_Shdr = @intToPtr(*exe.Elf64_Shdr, addr);
        if (shdr.sh_type == .DYNSYM) {
            dynsym_size = shdr.sh_size;
        }
        if (shdr.sh_type == .DYNAMIC) {
            const dyn: [*]exe.Elf64_Dyn = @intToPtr([*]exe.Elf64_Dyn, ehdr_addr +% shdr.sh_offset);
            var dyn_idx: u64 = 0;
            while (true) : (dyn_idx +%= 1) {
                if (dyn[dyn_idx].d_tag == .SYMTAB) {
                    symtab_addr = ehdr_addr +% dyn[dyn_idx].d_val;
                    dyn_idx +%= 1;
                }
                if (dyn[dyn_idx].d_tag == .SYMENT) {
                    symtab_ents = dyn[dyn_idx].d_val;
                    dyn_idx +%= 1;
                }
                if (dyn[dyn_idx].d_tag == .STRTAB) {
                    strtab_addr = ehdr_addr +% dyn[dyn_idx].d_val;
                }
                if (symtab_addr != 0 and
                    symtab_ents != 0 and
                    strtab_addr != 0)
                {
                    const strtab: [*:0]u8 = @intToPtr([*:0]u8, strtab_addr);
                    const symtab: [*]exe.Elf64_Sym = @intToPtr([*]exe.Elf64_Sym, symtab_addr);
                    var st_idx: u64 = 1;
                    lo: while (st_idx *% symtab_ents != dynsym_size) : (st_idx +%= 1) {
                        for (symbol, strtab + symtab[st_idx].st_name) |x, y| {
                            if (x != y) {
                                continue :lo;
                            }
                        }
                        return ehdr_addr +% symtab[st_idx].st_value;
                    }
                    break;
                }
            }
        }
    }
    return null;
}

var vdso_clock_gettime: ?*fn (time.Kind, *time.TimeSpec) void = null;

pub fn main(args: [][*:0]u8, _: [][*:0]u8, aux: *const anyopaque) !void {
    const vdso_addr: u64 = proc.auxiliaryValue(aux, .vdso_addr).?;
    for (args[1..]) |arg| {
        if (sectionAddress(vdso_addr, meta.manyToSlice(arg))) |addr| {
            if (programOffset(vdso_addr)) |offset| {
                vdso_clock_gettime = @intToPtr(*fn (time.Kind, *time.TimeSpec) void, addr +% offset);
            }
        }
        if (vdso_clock_gettime) |clock_gettime| {
            var ts: time.TimeSpec = undefined;
            clock_gettime(.realtime, &ts);
        }
    }
}
