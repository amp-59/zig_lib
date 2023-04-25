const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

const DT = enum(u32) {
    NULL = NULL,
    NEEDED = NEEDED,
    PLTRELSZ = PLTRELSZ,
    PLTGOT = PLTGOT,
    HASH = HASH,
    STRTAB = STRTAB,
    SYMTAB = SYMTAB,
    RELA = RELA,
    RELASZ = RELASZ,
    RELAENT = RELAENT,
    STRSZ = STRSZ,
    SYMENT = SYMENT,
    INIT = INIT,
    FINI = FINI,
    SONAME = SONAME,
    RPATH = RPATH,
    SYMBOLIC = SYMBOLIC,
    REL = REL,
    RELSZ = RELSZ,
    RELENT = RELENT,
    PLTREL = PLTREL,
    DEBUG = DEBUG,
    TEXTREL = TEXTREL,
    JMPREL = JMPREL,
    BIND_NOW = BIND_NOW,
    INIT_ARRAY = INIT_ARRAY,
    FINI_ARRAY = FINI_ARRAY,
    INIT_ARRAYSZ = INIT_ARRAYSZ,
    FINI_ARRAYSZ = FINI_ARRAYSZ,
    RUNPATH = RUNPATH,
    FLAGS = FLAGS,
    ENCODING = ENCODING,
    // PREINIT_ARRAY = PREINIT_ARRAY,
    PREINIT_ARRAYSZ = PREINIT_ARRAYSZ,
    SYMTAB_SHNDX = SYMTAB_SHNDX,
    NUM = NUM,
    LOOS = LOOS,
    HIOS = HIOS,
    LOPROC = LOPROC,
    HIPROC = HIPROC,
    PROCNUM = PROCNUM,
    VALRNGLO = VALRNGLO,
    GNU_PRELINKED = GNU_PRELINKED,
    GNU_CONFLICTSZ = GNU_CONFLICTSZ,
    GNU_LIBLISTSZ = GNU_LIBLISTSZ,
    CHECKSUM = CHECKSUM,
    PLTPADSZ = PLTPADSZ,
    MOVEENT = MOVEENT,
    MOVESZ = MOVESZ,
    FEATURE_1 = FEATURE_1,
    POSFLAG_1 = POSFLAG_1,
    SYMINSZ = SYMINSZ,
    SYMINENT = SYMINENT,
    // VALRNGHI = VALRNGHI,
    // VALNUM = VALNUM,
    ADDRRNGLO = ADDRRNGLO,
    GNU_HASH = GNU_HASH,
    TLSDESC_PLT = TLSDESC_PLT,
    TLSDESC_GOT = TLSDESC_GOT,
    GNU_CONFLICT = GNU_CONFLICT,
    GNU_LIBLIST = GNU_LIBLIST,
    CONFIG = CONFIG,
    DEPAUDIT = DEPAUDIT,
    AUDIT = AUDIT,
    PLTPAD = PLTPAD,
    MOVETAB = MOVETAB,
    SYMINFO = SYMINFO,
    // ADDRRNGHI = ADDRRNGHI,
    // ADDRNUM = ADDRNUM,
    VERSYM = VERSYM,
    RELACOUNT = RELACOUNT,
    RELCOUNT = RELCOUNT,
    FLAGS_1 = FLAGS_1,
    VERDEF = VERDEF,
    VERDEFNUM = VERDEFNUM,
    VERNEED = VERNEED,
    VERNEEDNUM = VERNEEDNUM,
    // VERSIONTAGNUM = VERSIONTAGNUM,
    AUXILIARY = AUXILIARY,
    // FILTER = FILTER,
    // EXTRANUM = EXTRANUM,
    // SPARC_REGISTER = SPARC_REGISTER,
    // SPARC_NUM = SPARC_NUM,
    MIPS_RLD_VERSION = MIPS_RLD_VERSION,
    MIPS_TIME_STAMP = MIPS_TIME_STAMP,
    MIPS_ICHECKSUM = MIPS_ICHECKSUM,
    MIPS_IVERSION = MIPS_IVERSION,
    MIPS_FLAGS = MIPS_FLAGS,
    MIPS_BASE_ADDRESS = MIPS_BASE_ADDRESS,
    MIPS_MSYM = MIPS_MSYM,
    MIPS_CONFLICT = MIPS_CONFLICT,
    MIPS_LIBLIST = MIPS_LIBLIST,
    MIPS_LOCAL_GOTNO = MIPS_LOCAL_GOTNO,
    MIPS_CONFLICTNO = MIPS_CONFLICTNO,
    MIPS_LIBLISTNO = MIPS_LIBLISTNO,
    MIPS_SYMTABNO = MIPS_SYMTABNO,
    MIPS_UNREFEXTNO = MIPS_UNREFEXTNO,
    MIPS_GOTSYM = MIPS_GOTSYM,
    MIPS_HIPAGENO = MIPS_HIPAGENO,
    MIPS_RLD_MAP = MIPS_RLD_MAP,
    MIPS_DELTA_CLASS = MIPS_DELTA_CLASS,
    MIPS_DELTA_CLASS_NO = MIPS_DELTA_CLASS_NO,
    MIPS_DELTA_INSTANCE = MIPS_DELTA_INSTANCE,
    MIPS_DELTA_INSTANCE_NO = MIPS_DELTA_INSTANCE_NO,
    MIPS_DELTA_RELOC = MIPS_DELTA_RELOC,
    MIPS_DELTA_RELOC_NO = MIPS_DELTA_RELOC_NO,
    MIPS_DELTA_SYM = MIPS_DELTA_SYM,
    MIPS_DELTA_SYM_NO = MIPS_DELTA_SYM_NO,
    MIPS_DELTA_CLASSSYM = MIPS_DELTA_CLASSSYM,
    MIPS_DELTA_CLASSSYM_NO = MIPS_DELTA_CLASSSYM_NO,
    MIPS_CXX_FLAGS = MIPS_CXX_FLAGS,
    MIPS_PIXIE_INIT = MIPS_PIXIE_INIT,
    MIPS_SYMBOL_LIB = MIPS_SYMBOL_LIB,
    MIPS_LOCALPAGE_GOTIDX = MIPS_LOCALPAGE_GOTIDX,
    MIPS_LOCAL_GOTIDX = MIPS_LOCAL_GOTIDX,
    MIPS_HIDDEN_GOTIDX = MIPS_HIDDEN_GOTIDX,
    MIPS_PROTECTED_GOTIDX = MIPS_PROTECTED_GOTIDX,
    MIPS_OPTIONS = MIPS_OPTIONS,
    MIPS_INTERFACE = MIPS_INTERFACE,
    MIPS_DYNSTR_ALIGN = MIPS_DYNSTR_ALIGN,
    MIPS_INTERFACE_SIZE = MIPS_INTERFACE_SIZE,
    MIPS_RLD_TEXT_RESOLVE_ADDR = MIPS_RLD_TEXT_RESOLVE_ADDR,
    MIPS_PERF_SUFFIX = MIPS_PERF_SUFFIX,
    MIPS_COMPACT_SIZE = MIPS_COMPACT_SIZE,
    MIPS_GP_VALUE = MIPS_GP_VALUE,
    MIPS_AUX_DYNAMIC = MIPS_AUX_DYNAMIC,
    MIPS_PLTGOT = MIPS_PLTGOT,
    MIPS_RWPLT = MIPS_RWPLT,
    MIPS_RLD_MAP_REL = MIPS_RLD_MAP_REL,
    // MIPS_NUM = MIPS_NUM,
    // ALPHA_PLTRO = ALPHA_PLTRO,
    // ALPHA_NUM = ALPHA_NUM,
    // PPC_GOT = PPC_GOT,
    // PPC_OPT = PPC_OPT,
    // PPC_NUM = PPC_NUM,
    // PPC64_GLINK = PPC64_GLINK,
    // PPC64_OPD = PPC64_OPD,
    // PPC64_OPDSZ = PPC64_OPDSZ,
    // PPC64_OPT = PPC64_OPT,
    // PPC64_NUM = PPC64_NUM,
    // IA_64_PLT_RESERVE = IA_64_PLT_RESERVE,
    // IA_64_NUM = IA_64_NUM,
    // NIOS2_GP = NIOS2_GP,
    pub const NULL = 0;
    pub const NEEDED = 1;
    pub const PLTRELSZ = 2;
    pub const PLTGOT = 3;
    pub const HASH = 4;
    pub const STRTAB = 5;
    pub const SYMTAB = 6;
    pub const RELA = 7;
    pub const RELASZ = 8;
    pub const RELAENT = 9;
    pub const STRSZ = 10;
    pub const SYMENT = 11;
    pub const INIT = 12;
    pub const FINI = 13;
    pub const SONAME = 14;
    pub const RPATH = 15;
    pub const SYMBOLIC = 16;
    pub const REL = 17;
    pub const RELSZ = 18;
    pub const RELENT = 19;
    pub const PLTREL = 20;
    pub const DEBUG = 21;
    pub const TEXTREL = 22;
    pub const JMPREL = 23;
    pub const BIND_NOW = 24;
    pub const INIT_ARRAY = 25;
    pub const FINI_ARRAY = 26;
    pub const INIT_ARRAYSZ = 27;
    pub const FINI_ARRAYSZ = 28;
    pub const RUNPATH = 29;
    pub const FLAGS = 30;
    pub const ENCODING = 32;
    pub const PREINIT_ARRAY = 32;
    pub const PREINIT_ARRAYSZ = 33;
    pub const SYMTAB_SHNDX = 34;
    pub const NUM = 35;
    pub const LOOS = 0x6000000d;
    pub const HIOS = 0x6ffff000;
    pub const LOPROC = 0x70000000;
    pub const HIPROC = 0x7fffffff;
    pub const PROCNUM = MIPS_NUM;
    pub const VALRNGLO = 0x6ffffd00;
    pub const GNU_PRELINKED = 0x6ffffdf5;
    pub const GNU_CONFLICTSZ = 0x6ffffdf6;
    pub const GNU_LIBLISTSZ = 0x6ffffdf7;
    pub const CHECKSUM = 0x6ffffdf8;
    pub const PLTPADSZ = 0x6ffffdf9;
    pub const MOVEENT = 0x6ffffdfa;
    pub const MOVESZ = 0x6ffffdfb;
    pub const FEATURE_1 = 0x6ffffdfc;
    pub const POSFLAG_1 = 0x6ffffdfd;
    pub const SYMINSZ = 0x6ffffdfe;
    pub const SYMINENT = 0x6ffffdff;
    pub const VALRNGHI = 0x6ffffdff;
    pub const VALNUM = 12;
    pub const ADDRRNGLO = 0x6ffffe00;
    pub const GNU_HASH = 0x6ffffef5;
    pub const TLSDESC_PLT = 0x6ffffef6;
    pub const TLSDESC_GOT = 0x6ffffef7;
    pub const GNU_CONFLICT = 0x6ffffef8;
    pub const GNU_LIBLIST = 0x6ffffef9;
    pub const CONFIG = 0x6ffffefa;
    pub const DEPAUDIT = 0x6ffffefb;
    pub const AUDIT = 0x6ffffefc;
    pub const PLTPAD = 0x6ffffefd;
    pub const MOVETAB = 0x6ffffefe;
    pub const SYMINFO = 0x6ffffeff;
    pub const ADDRRNGHI = 0x6ffffeff;
    pub const ADDRNUM = 11;
    pub const VERSYM = 0x6ffffff0;
    pub const RELACOUNT = 0x6ffffff9;
    pub const RELCOUNT = 0x6ffffffa;
    pub const FLAGS_1 = 0x6ffffffb;
    pub const VERDEF = 0x6ffffffc;
    pub const VERDEFNUM = 0x6ffffffd;
    pub const VERNEED = 0x6ffffffe;
    pub const VERNEEDNUM = 0x6fffffff;
    pub const VERSIONTAGNUM = 16;
    pub const AUXILIARY = 0x7ffffffd;
    pub const FILTER = 0x7fffffff;
    pub const EXTRANUM = 3;
    pub const SPARC_REGISTER = 0x70000001;
    pub const SPARC_NUM = 2;
    pub const MIPS_RLD_VERSION = 0x70000001;
    pub const MIPS_TIME_STAMP = 0x70000002;
    pub const MIPS_ICHECKSUM = 0x70000003;
    pub const MIPS_IVERSION = 0x70000004;
    pub const MIPS_FLAGS = 0x70000005;
    pub const MIPS_BASE_ADDRESS = 0x70000006;
    pub const MIPS_MSYM = 0x70000007;
    pub const MIPS_CONFLICT = 0x70000008;
    pub const MIPS_LIBLIST = 0x70000009;
    pub const MIPS_LOCAL_GOTNO = 0x7000000a;
    pub const MIPS_CONFLICTNO = 0x7000000b;
    pub const MIPS_LIBLISTNO = 0x70000010;
    pub const MIPS_SYMTABNO = 0x70000011;
    pub const MIPS_UNREFEXTNO = 0x70000012;
    pub const MIPS_GOTSYM = 0x70000013;
    pub const MIPS_HIPAGENO = 0x70000014;
    pub const MIPS_RLD_MAP = 0x70000016;
    pub const MIPS_DELTA_CLASS = 0x70000017;
    pub const MIPS_DELTA_CLASS_NO = 0x70000018;
    pub const MIPS_DELTA_INSTANCE = 0x70000019;
    pub const MIPS_DELTA_INSTANCE_NO = 0x7000001a;
    pub const MIPS_DELTA_RELOC = 0x7000001b;
    pub const MIPS_DELTA_RELOC_NO = 0x7000001c;
    pub const MIPS_DELTA_SYM = 0x7000001d;
    pub const MIPS_DELTA_SYM_NO = 0x7000001e;
    pub const MIPS_DELTA_CLASSSYM = 0x70000020;
    pub const MIPS_DELTA_CLASSSYM_NO = 0x70000021;
    pub const MIPS_CXX_FLAGS = 0x70000022;
    pub const MIPS_PIXIE_INIT = 0x70000023;
    pub const MIPS_SYMBOL_LIB = 0x70000024;
    pub const MIPS_LOCALPAGE_GOTIDX = 0x70000025;
    pub const MIPS_LOCAL_GOTIDX = 0x70000026;
    pub const MIPS_HIDDEN_GOTIDX = 0x70000027;
    pub const MIPS_PROTECTED_GOTIDX = 0x70000028;
    pub const MIPS_OPTIONS = 0x70000029;
    pub const MIPS_INTERFACE = 0x7000002a;
    pub const MIPS_DYNSTR_ALIGN = 0x7000002b;
    pub const MIPS_INTERFACE_SIZE = 0x7000002c;
    pub const MIPS_RLD_TEXT_RESOLVE_ADDR = 0x7000002d;
    pub const MIPS_PERF_SUFFIX = 0x7000002e;
    pub const MIPS_COMPACT_SIZE = 0x7000002f;
    pub const MIPS_GP_VALUE = 0x70000030;
    pub const MIPS_AUX_DYNAMIC = 0x70000031;
    pub const MIPS_PLTGOT = 0x70000032;
    pub const MIPS_RWPLT = 0x70000034;
    pub const MIPS_RLD_MAP_REL = 0x70000035;
    pub const MIPS_NUM = 0x36;
    pub const ALPHA_PLTRO = (LOPROC + 0);
    pub const ALPHA_NUM = 1;
    pub const PPC_GOT = (LOPROC + 0);
    pub const PPC_OPT = (LOPROC + 1);
    pub const PPC_NUM = 2;
    pub const PPC64_GLINK = (LOPROC + 0);
    pub const PPC64_OPD = (LOPROC + 1);
    pub const PPC64_OPDSZ = (LOPROC + 2);
    pub const PPC64_OPT = (LOPROC + 3);
    pub const PPC64_NUM = 4;
    pub const IA_64_PLT_RESERVE = (LOPROC + 0);
    pub const IA_64_NUM = 1;
    pub const NIOS2_GP = 0x70000002;
};
const PT = meta.EnumBitField(enum(u32) {
    NULL = NULL,
    LOAD = LOAD,
    DYNAMIC = DYNAMIC,
    INTERP = INTERP,
    NOTE = NOTE,
    SHLIB = SHLIB,
    PHDR = PHDR,
    TLS = TLS,
    NUM = NUM,
    LOOS = LOOS,
    GNU_EH_FRAME = GNU_EH_FRAME,
    GNU_RELRO = GNU_RELRO,
    GNU_UNKNOWN = GNU_UNKNOWN,
    LOSUNW = LOSUNW,
    HISUNW = HISUNW,
    GNU_STACK = GNU_STACK,
    LOPROC = LOPROC,
    HIPROC = HIPROC,

    pub const NULL = 0;
    pub const LOAD = 1;
    pub const DYNAMIC = 2;
    pub const INTERP = 3;
    pub const NOTE = 4;
    pub const SHLIB = 5;
    pub const PHDR = 6;
    pub const TLS = 7;
    pub const NUM = 8;
    pub const LOOS = 0x60000000;
    pub const GNU_EH_FRAME = 0x6474e550;
    pub const GNU_STACK = 0x6474e551;
    pub const GNU_RELRO = 0x6474e552;
    pub const GNU_UNKNOWN = 0x6474e553;
    pub const LOSUNW = 0x6ffffffa;
    pub const SUNWBSS = 0x6ffffffa;
    pub const SUNWSTACK = 0x6ffffffb;
    pub const HISUNW = 0x6fffffff;
    pub const HIOS = 0x6fffffff;
    pub const LOPROC = 0x70000000;
    pub const HIPROC = 0x7fffffff;
});
const SHT = enum(u32) {
    NULL = NULL,
    PROGBITS = PROGBITS,
    SYMTAB = SYMTAB,
    STRTAB = STRTAB,
    RELA = RELA,
    HASH = HASH,
    DYNAMIC = DYNAMIC,
    NOTE = NOTE,
    NOBITS = NOBITS,
    REL = REL,
    SHLIB = SHLIB,
    DYNSYM = DYNSYM,
    INIT_ARRAY = INIT_ARRAY,
    FINI_ARRAY = FINI_ARRAY,
    PREINIT_ARRAY = PREINIT_ARRAY,
    GROUP = GROUP,
    SYMTAB_SHNDX = SYMTAB_SHNDX,
    LOOS = LOOS,
    GNU_HASH = GNU_HASH,
    HIOS = HIOS,
    LOPROC = LOPROC,
    HIPROC = HIPROC,
    LOUSER = LOUSER,
    HIUSER = HIUSER,
    pub const NULL = 0;
    pub const PROGBITS = 1;
    pub const SYMTAB = 2;
    pub const STRTAB = 3;
    pub const RELA = 4;
    pub const HASH = 5;
    pub const DYNAMIC = 6;
    pub const NOTE = 7;
    pub const NOBITS = 8;
    pub const REL = 9;
    pub const SHLIB = 10;
    pub const DYNSYM = 11;
    pub const INIT_ARRAY = 14;
    pub const FINI_ARRAY = 15;
    pub const PREINIT_ARRAY = 16;
    pub const GROUP = 17;
    pub const SYMTAB_SHNDX = 18;
    pub const LOOS = 0x60000000;
    pub const GNU_HASH = 0x6ffffff6;
    pub const HIOS = 0x6fffffff;
    pub const LOPROC = 0x70000000;
    pub const HIPROC = 0x7fffffff;
    pub const LOUSER = 0x80000000;
    pub const HIUSER = 0xffffffff;
};
pub const STB_LOCAL = 0;
pub const STB_GLOBAL = 1;
pub const STB_WEAK = 2;
pub const STB_NUM = 3;
pub const STB_LOOS = 10;
pub const STB_GNU_UNIQUE = 10;
pub const STB_HIOS = 12;
pub const STB_LOPROC = 13;
pub const STB_HIPROC = 15;
pub const STB_MIPS_SPLIT_COMMON = 13;
pub const STT = meta.EnumBitField(enum(u8) {
    NOTYPE = NOTYPE,
    OBJECT = OBJECT,
    FUNC = FUNC,
    SECTION = SECTION,
    FILE = FILE,
    COMMON = COMMON,
    TLS = TLS,
    NUM = NUM,
    LOOS = LOOS,
    // GNU_IFUNC = GNU_IFUNC,
    HIOS = HIOS,
    LOPROC = LOPROC,
    HIPROC = HIPROC,
    UNKNOWN = UNKNOWN,
    // SPARC_REGISTER = SPARC_REGISTER,
    // PARISC_MILLICODE = PARISC_MILLICODE,
    HP_OPAQUE = HP_OPAQUE,
    // HP_STUB = HP_STUB,
    pub const NOTYPE = 0;
    pub const OBJECT = 1;
    pub const FUNC = 2;
    pub const SECTION = 3;
    pub const FILE = 4;
    pub const COMMON = 5;
    pub const TLS = 6;
    pub const NUM = 7;
    pub const LOOS = 10;
    pub const GNU_IFUNC = 10;
    pub const HIOS = 12;
    pub const LOPROC = 13;
    pub const HIPROC = 15;
    pub const UNKNOWN = 18;
    pub const SPARC_REGISTER = 13;
    pub const PARISC_MILLICODE = 13;
    pub const HP_OPAQUE = (LOOS + 0x1);
    pub const HP_STUB = (LOOS + 0x2);
    pub const ARM_TFUNC = LOPROC;
    pub const ARM_16BIT = HIPROC;
});
pub const VER_FLG_BASE = 0x1;
pub const VER_FLG_WEAK = 0x2;
pub const MAGIC = "\x7fELF";
/// File types
pub const ET = meta.EnumBitField(enum(u16) {
    /// No file type
    NONE = 0,
    /// Relocatable file
    REL = 1,
    /// Executable file
    EXEC = 2,
    /// Shared object file
    DYN = 3,
    /// Core file
    CORE = 4,
    /// Beginning of processor-specific codes
    pub const LOPROC = 0xff00;
    /// Processor-specific
    pub const HIPROC = 0xffff;
});
/// All integers are native endian.
pub const Header = struct {
    endian: builtin.Endian,
    machine: EM,
    is_64: bool,
    entry: u64,
    phoff: u64,
    shoff: u64,
    phentsize: u16,
    phnum: u16,
    shentsize: u16,
    shnum: u16,
    shstrndx: u16,
    pub fn parse(array: anytype) !Header {
        const hdr64: *Elf64_Ehdr = array.referOneAt(Elf64_Ehdr, .{ .bytes = 0 });
        const hdr32: *Elf32_Ehdr = array.referOneAt(Elf32_Ehdr, .{ .bytes = 0 });
        if (!mem.testEqualMany(u8, hdr32.e_ident[0..4], MAGIC)) {
            return error.InvalidElfMagic;
        }
        if (hdr32.e_ident[EI.VERSION] != 1) {
            if (builtin.logging_general.Error) {
                debug.badVersionError(hdr32);
            }
            return error.InvalidElfVersion;
        }
        const endian: builtin.Endian = switch (hdr32.e_ident[EI.DATA]) {
            ELFDATA2LSB => .Little,
            ELFDATA2MSB => .Big,
            else => {
                if (builtin.logging_general.Error) {
                    debug.badEndianError(hdr32);
                }
                return error.InvalidElfEndian;
            },
        };
        const need_bswap: bool = endian != builtin.native_endian;
        const is_64: bool = switch (hdr32.e_ident[EI.CLASS]) {
            ELFCLASS32 => false,
            ELFCLASS64 => true,
            else => return error.InvalidElfClass,
        };
        const machine = if (need_bswap) blk: {
            const value = @enumToInt(hdr32.e_machine);
            break :blk @intToEnum(EM, @byteSwap(value));
        } else hdr32.e_machine;
        return @as(Header, .{
            .endian = endian,
            .machine = machine,
            .is_64 = is_64,
            .entry = int(is_64, need_bswap, hdr32.e_entry, hdr64.e_entry),
            .phoff = int(is_64, need_bswap, hdr32.e_phoff, hdr64.e_phoff),
            .shoff = int(is_64, need_bswap, hdr32.e_shoff, hdr64.e_shoff),
            .phentsize = int(is_64, need_bswap, hdr32.e_phentsize, hdr64.e_phentsize),
            .phnum = int(is_64, need_bswap, hdr32.e_phnum, hdr64.e_phnum),
            .shentsize = int(is_64, need_bswap, hdr32.e_shentsize, hdr64.e_shentsize),
            .shnum = int(is_64, need_bswap, hdr32.e_shnum, hdr64.e_shnum),
            .shstrndx = int(is_64, need_bswap, hdr32.e_shstrndx, hdr64.e_shstrndx),
        });
    }
};
pub fn ProgramHeaderIterator(comptime Memory: type) type {
    return struct {
        elf_header: Header,
        array: *Memory,
        index: usize = 0,
        const Iterator = @This();
        const phdr_size: u64 = @sizeOf(Elf64_Phdr);
        pub fn init(elf_header: Header, array: *Memory) Iterator {
            array.unstreamAll();
            array.stream(u8, .{ .bytes = elf_header.phoff });
            return .{ .elf_header = elf_header, .array = array };
        }
        pub fn next(itr: *Iterator) ?Elf64_Phdr {
            if (itr.index == itr.elf_header.phnum) {
                return null;
            }
            itr.index += 1;
            itr.array.stream(Elf64_Phdr, .{ .count = 1 });
            return itr.array.readOneBehind(Elf64_Phdr);
        }
    };
}
pub fn SectionHeaderIterator(comptime Memory: type) type {
    return struct {
        elf_header: Header,
        array: *Memory,
        index: usize = 0,
        const Iterator = @This();
        const shdr_size: u64 = @sizeOf(Elf64_Shdr);

        pub fn init(elf_header: Header, array: *Memory) Iterator {
            array.unstreamAll();
            array.stream(u8, .{ .bytes = elf_header.shoff });
            return .{ .elf_header = elf_header, .array = array };
        }
        pub fn next(itr: *Iterator) ?Elf64_Shdr {
            if (itr.index == itr.elf_header.shnum) {
                return null;
            }
            itr.index += 1;
            itr.array.stream(Elf64_Shdr, .{ .count = 1 });
            return itr.array.readOneBehind(Elf64_Shdr);
        }
    };
}
pub fn int(is_64: bool, need_bswap: bool, int_32: anytype, int_64: anytype) @TypeOf(int_64) {
    if (is_64) {
        if (need_bswap) {
            return @byteSwap(int_64);
        } else {
            return int_64;
        }
    } else {
        return int32(need_bswap, int_32, @TypeOf(int_64));
    }
}
pub fn int32(need_bswap: bool, int_32: anytype, comptime Int64: anytype) Int64 {
    if (need_bswap) {
        return @byteSwap(int_32);
    } else {
        return int_32;
    }
}
pub const EI = opaque {
    pub const CLASS = 4;
    pub const DATA = 5;
    pub const VERSION = 6;
    pub const NIDENT = 16;
};
pub const ELFCLASSNONE = 0;
pub const ELFCLASS32 = 1;
pub const ELFCLASS64 = 2;
pub const ELFCLASSNUM = 3;
pub const ELFDATANONE = 0;
pub const ELFDATA2LSB = 1;
pub const ELFDATA2MSB = 2;
pub const ELFDATANUM = 3;

pub const Elf32_Ehdr = extern struct {
    e_ident: [16]u8,
    e_type: ET,
    e_machine: EM,
    e_version: u32,
    e_entry: u32,
    e_phoff: u32,
    e_shoff: u32,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
};
pub const Elf64_Ehdr = extern struct {
    e_ident: [16]u8,
    e_type: ET,
    e_machine: EM,
    e_version: u32,
    e_entry: u64,
    e_phoff: u64,
    e_shoff: u64,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
};
pub const Elf32_Phdr = extern struct {
    p_type: PT,
    p_offset: u32,
    p_vaddr: u32,
    p_paddr: u32,
    p_filesz: u32,
    p_memsz: u32,
    p_flags: PF,
    p_align: u32,
};
pub const Elf64_Phdr = extern struct {
    p_type: PT,
    p_flags: PF,
    p_offset: u64,
    p_vaddr: u64,
    p_paddr: u64,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,
};
pub const Elf32_Shdr = extern struct {
    sh_name: u32,
    sh_type: SHT,
    sh_flags: u32,
    sh_addr: u32,
    sh_offset: u32,
    sh_size: u32,
    sh_link: u32,
    sh_info: u32,
    sh_addralign: u32,
    sh_entsize: u32,
};
pub const Elf64_Shdr = extern struct {
    sh_name: u32,
    sh_type: SHT,
    sh_flags: u64,
    sh_addr: u64,
    sh_offset: u64,
    sh_size: u64,
    sh_link: u32,
    sh_info: u32,
    sh_addralign: u64,
    sh_entsize: u64,
};
pub const Elf32_Chdr = extern struct {
    ch_type: u32,
    ch_size: u32,
    ch_addralign: u32,
};
pub const Elf64_Chdr = extern struct {
    ch_type: u32,
    ch_reserved: u32,
    ch_size: u64,
    ch_addralign: u64,
};
pub const Elf32_Sym = extern struct {
    st_name: u32,
    st_value: u32,
    st_size: u32,
    st_info: u8,
    st_other: u8,
    st_shndx: u16,
};
pub const Elf64_Sym = extern struct {
    st_name: u32,
    st_info: u8,
    st_other: u8,
    st_shndx: u16,
    st_value: u64,
    st_size: u64,
};
pub const Elf32_Syminfo = extern struct {
    si_boundto: u16,
    si_flags: u16,
};
pub const Elf64_Syminfo = extern struct {
    si_boundto: u16,
    si_flags: u16,
};
pub const Elf32_Rel = extern struct {
    r_offset: u32,
    r_info: u32,
    pub inline fn r_sym(self: @This()) u24 {
        return @truncate(u24, self.r_info >> 8);
    }
    pub inline fn r_type(self: @This()) u8 {
        return @truncate(u8, self.r_info & 0xff);
    }
};
pub const Elf64_Rel = extern struct {
    r_offset: u64,
    r_info: u64,
    pub inline fn r_sym(self: @This()) u32 {
        return @truncate(u32, self.r_info >> 32);
    }
    pub inline fn r_type(self: @This()) u32 {
        return @truncate(u32, self.r_info & 0xffffffff);
    }
};
pub const Elf32_Rela = extern struct {
    r_offset: u32,
    r_info: u32,
    r_addend: i32,
    pub inline fn r_sym(self: @This()) u24 {
        return @truncate(u24, self.r_info >> 8);
    }
    pub inline fn r_type(self: @This()) u8 {
        return @truncate(u8, self.r_info & 0xff);
    }
};
pub const Elf64_Rela = extern struct {
    r_offset: u64,
    r_info: u64,
    r_addend: i64,
    pub inline fn r_sym(self: @This()) u32 {
        return @truncate(u32, self.r_info >> 32);
    }
    pub inline fn r_type(self: @This()) u32 {
        return @truncate(u32, self.r_info & 0xffffffff);
    }
};
pub const Elf32_Dyn = extern struct {
    d_tag: DT,
    d_val: u32,
};
pub const Elf64_Dyn = extern struct {
    d_tag: DT,
    d_val: u64,
};
pub const Elf32_Verdef = extern struct {
    vd_version: u16,
    vd_flags: u16,
    vd_ndx: u16,
    vd_cnt: u16,
    vd_hash: u32,
    vd_aux: u32,
    vd_next: u32,
};
pub const Elf64_Verdef = extern struct {
    vd_version: u16,
    vd_flags: u16,
    vd_ndx: u16,
    vd_cnt: u16,
    vd_hash: u32,
    vd_aux: u32,
    vd_next: u32,
};
pub const Elf32_Verdaux = extern struct {
    vda_name: u32,
    vda_next: u32,
};
pub const Elf64_Verdaux = extern struct {
    vda_name: u32,
    vda_next: u32,
};
pub const Elf32_Verneed = extern struct {
    vn_version: u16,
    vn_cnt: u16,
    vn_file: u32,
    vn_aux: u32,
    vn_next: u32,
};
pub const Elf64_Verneed = extern struct {
    vn_version: u16,
    vn_cnt: u16,
    vn_file: u32,
    vn_aux: u32,
    vn_next: u32,
};
pub const Elf32_Vernaux = extern struct {
    vna_hash: u32,
    vna_flags: u16,
    vna_other: u16,
    vna_name: u32,
    vna_next: u32,
};
pub const Elf64_Vernaux = extern struct {
    vna_hash: u32,
    vna_flags: u16,
    vna_other: u16,
    vna_name: u32,
    vna_next: u32,
};
pub const Elf32_auxv_t = extern struct {
    a_type: u32,
    a_un: extern union {
        a_val: u32,
    },
};
pub const Elf64_auxv_t = extern struct {
    a_type: u64,
    a_un: extern union {
        a_val: u64,
    },
};
pub const Elf32_Nhdr = extern struct {
    n_namesz: u32,
    n_descsz: u32,
    n_type: u32,
};
pub const Elf64_Nhdr = extern struct {
    n_namesz: u32,
    n_descsz: u32,
    n_type: u32,
};
pub const Elf32_Move = extern struct {
    m_value: u64,
    m_info: u32,
    m_poffset: u32,
    m_repeat: u16,
    m_stride: u16,
};
pub const Elf64_Move = extern struct {
    m_value: u64,
    m_info: u64,
    m_poffset: u64,
    m_repeat: u16,
    m_stride: u16,
};
pub const Elf32_gptab = extern union {
    gt_header: extern struct {
        gt_current_g_value: u32,
        gt_unused: u32,
    },
    gt_entry: extern struct {
        gt_g_value: u32,
        gt_bytes: u32,
    },
};
pub const Elf32_RegInfo = extern struct {
    ri_gprmask: u32,
    ri_cprmask: [4]u32,
    ri_gp_value: i32,
};
pub const Elf_Options = extern struct {
    kind: u8,
    size: u8,
    section: u16,
    info: u32,
};
pub const Elf_Options_Hw = extern struct {
    hwp_flags1: u32,
    hwp_flags2: u32,
};
pub const Elf32_Lib = extern struct {
    l_name: u32,
    l_time_stamp: u32,
    l_checksum: u32,
    l_version: u32,
    l_flags: u32,
};
pub const Elf64_Lib = extern struct {
    l_name: u32,
    l_time_stamp: u32,
    l_checksum: u32,
    l_version: u32,
    l_flags: u32,
};
pub const Elf32_Conflict = u32;
pub const Elf_MIPS_ABIFlags_v0 = extern struct {
    version: u16,
    isa_level: u8,
    isa_rev: u8,
    gpr_size: u8,
    cpr1_size: u8,
    cpr2_size: u8,
    fp_abi: u8,
    isa_ext: u32,
    ases: u32,
    flags1: u32,
    flags2: u32,
};
comptime {
    builtin.static.assert(@sizeOf(Elf32_Ehdr) == 52);
    builtin.static.assert(@sizeOf(Elf64_Ehdr) == 64);
    builtin.static.assert(@sizeOf(Elf32_Phdr) == 32);
    builtin.static.assert(@sizeOf(Elf64_Phdr) == 56);
    builtin.static.assert(@sizeOf(Elf32_Shdr) == 40);
    builtin.static.assert(@sizeOf(Elf64_Shdr) == 64);
}
pub const Auxv = switch (@sizeOf(usize)) {
    4 => Elf32_auxv_t,
    8 => Elf64_auxv_t,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Ehdr = switch (@sizeOf(usize)) {
    4 => Elf32_Ehdr,
    8 => Elf64_Ehdr,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Phdr = switch (@sizeOf(usize)) {
    4 => Elf32_Phdr,
    8 => Elf64_Phdr,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Dyn = switch (@sizeOf(usize)) {
    4 => Elf32_Dyn,
    8 => Elf64_Dyn,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Rel = switch (@sizeOf(usize)) {
    4 => Elf32_Rel,
    8 => Elf64_Rel,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Rela = switch (@sizeOf(usize)) {
    4 => Elf32_Rela,
    8 => Elf64_Rela,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Shdr = switch (@sizeOf(usize)) {
    4 => Elf32_Shdr,
    8 => Elf64_Shdr,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Sym = switch (@sizeOf(usize)) {
    4 => Elf32_Sym,
    8 => Elf64_Sym,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Verdef = switch (@sizeOf(usize)) {
    4 => Elf32_Verdef,
    8 => Elf64_Verdef,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Verdaux = switch (@sizeOf(usize)) {
    4 => Elf32_Verdaux,
    8 => Elf64_Verdaux,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Addr = switch (@sizeOf(usize)) {
    4 => u32,
    8 => u64,
    else => @compileError("expected pointer size of 32 or 64"),
};
pub const Half = switch (@sizeOf(usize)) {
    4 => u16,
    8 => u16,
    else => @compileError("expected pointer size of 32 or 64"),
};
/// Machine architectures.
///
/// See current registered ELF machine architectures at:
/// http://www.sco.com/developers/gabi/latest/ch4.eheader.html
pub const EM = enum(u16) {
    /// No machine
    NONE = 0,
    /// AT&T WE 32100
    M32 = 1,
    /// SPARC
    SPARC = 2,
    /// Intel 386
    @"386" = 3,
    /// Motorola 68000
    @"68K" = 4,
    /// Motorola 88000
    @"88K" = 5,
    /// Intel MCU
    IAMCU = 6,
    /// Intel 80860
    @"860" = 7,
    /// MIPS R3000
    MIPS = 8,
    /// IBM System/370
    S370 = 9,
    /// MIPS RS3000 Little-endian
    MIPS_RS3_LE = 10,
    /// SPU Mark II
    SPU_2 = 13,
    /// Hewlett-Packard PA-RISC
    PARISC = 15,
    /// Fujitsu VPP500
    VPP500 = 17,
    /// Enhanced instruction set SPARC
    SPARC32PLUS = 18,
    /// Intel 80960
    @"960" = 19,
    /// PowerPC
    PPC = 20,
    /// PowerPC64
    PPC64 = 21,
    /// IBM System/390
    S390 = 22,
    /// IBM SPU/SPC
    SPU = 23,
    /// NEC V800
    V800 = 36,
    /// Fujitsu FR20
    FR20 = 37,
    /// TRW RH-32
    RH32 = 38,
    /// Motorola RCE
    RCE = 39,
    /// ARM
    ARM = 40,
    /// DEC Alpha
    ALPHA = 41,
    /// Hitachi SH
    SH = 42,
    /// SPARC V9
    SPARCV9 = 43,
    /// Siemens TriCore
    TRICORE = 44,
    /// Argonaut RISC Core
    ARC = 45,
    /// Hitachi H8/300
    H8_300 = 46,
    /// Hitachi H8/300H
    H8_300H = 47,
    /// Hitachi H8S
    H8S = 48,
    /// Hitachi H8/500
    H8_500 = 49,
    /// Intel IA-64 processor architecture
    IA_64 = 50,
    /// Stanford MIPS-X
    MIPS_X = 51,
    /// Motorola ColdFire
    COLDFIRE = 52,
    /// Motorola M68HC12
    @"68HC12" = 53,
    /// Fujitsu MMA Multimedia Accelerator
    MMA = 54,
    /// Siemens PCP
    PCP = 55,
    /// Sony nCPU embedded RISC processor
    NCPU = 56,
    /// Denso NDR1 microprocessor
    NDR1 = 57,
    /// Motorola Star*Core processor
    STARCORE = 58,
    /// Toyota ME16 processor
    ME16 = 59,
    /// STMicroelectronics ST100 processor
    ST100 = 60,
    /// Advanced Logic Corp. TinyJ embedded processor family
    TINYJ = 61,
    /// AMD x86-64 architecture
    X86_64 = 62,
    /// Sony DSP Processor
    PDSP = 63,
    /// Digital Equipment Corp. PDP-10
    PDP10 = 64,
    /// Digital Equipment Corp. PDP-11
    PDP11 = 65,
    /// Siemens FX66 microcontroller
    FX66 = 66,
    /// STMicroelectronics ST9+ 8/16 bit microcontroller
    ST9PLUS = 67,
    /// STMicroelectronics ST7 8-bit microcontroller
    ST7 = 68,
    /// Motorola MC68HC16 Microcontroller
    @"68HC16" = 69,
    /// Motorola MC68HC11 Microcontroller
    @"68HC11" = 70,
    /// Motorola MC68HC08 Microcontroller
    @"68HC08" = 71,
    /// Motorola MC68HC05 Microcontroller
    @"68HC05" = 72,
    /// Silicon Graphics SVx
    SVX = 73,
    /// STMicroelectronics ST19 8-bit microcontroller
    ST19 = 74,
    /// Digital VAX
    VAX = 75,
    /// Axis Communications 32-bit embedded processor
    CRIS = 76,
    /// Infineon Technologies 32-bit embedded processor
    JAVELIN = 77,
    /// Element 14 64-bit DSP Processor
    FIREPATH = 78,
    /// LSI Logic 16-bit DSP Processor
    ZSP = 79,
    /// Donald Knuth's educational 64-bit processor
    MMIX = 80,
    /// Harvard University machine-independent object files
    HUANY = 81,
    /// SiTera Prism
    PRISM = 82,
    /// Atmel AVR 8-bit microcontroller
    AVR = 83,
    /// Fujitsu FR30
    FR30 = 84,
    /// Mitsubishi D10V
    D10V = 85,
    /// Mitsubishi D30V
    D30V = 86,
    /// NEC v850
    V850 = 87,
    /// Mitsubishi M32R
    M32R = 88,
    /// Matsushita MN10300
    MN10300 = 89,
    /// Matsushita MN10200
    MN10200 = 90,
    /// picoJava
    PJ = 91,
    /// OpenRISC 32-bit embedded processor
    OPENRISC = 92,
    /// ARC International ARCompact processor (old spelling/synonym: EM_ARC_A5)
    ARC_COMPACT = 93,
    /// Tensilica Xtensa Architecture
    XTENSA = 94,
    /// Alphamosaic VideoCore processor
    VIDEOCORE = 95,
    /// Thompson Multimedia General Purpose Processor
    TMM_GPP = 96,
    /// National Semiconductor 32000 series
    NS32K = 97,
    /// Tenor Network TPC processor
    TPC = 98,
    /// Trebia SNP 1000 processor
    SNP1K = 99,
    /// STMicroelectronics (www.st.com) ST200
    ST200 = 100,
    /// Ubicom IP2xxx microcontroller family
    IP2K = 101,
    /// MAX Processor
    MAX = 102,
    /// National Semiconductor CompactRISC microprocessor
    CR = 103,
    /// Fujitsu F2MC16
    F2MC16 = 104,
    /// Texas Instruments embedded microcontroller msp430
    MSP430 = 105,
    /// Analog Devices Blackfin (DSP) processor
    BLACKFIN = 106,
    /// S1C33 Family of Seiko Epson processors
    SE_C33 = 107,
    /// Sharp embedded microprocessor
    SEP = 108,
    /// Arca RISC Microprocessor
    ARCA = 109,
    /// Microprocessor series from PKU-Unity Ltd. and MPRC of Peking University
    UNICORE = 110,
    /// eXcess: 16/32/64-bit configurable embedded CPU
    EXCESS = 111,
    /// Icera Semiconductor Inc. Deep Execution Processor
    DXP = 112,
    /// Altera Nios II soft-core processor
    ALTERA_NIOS2 = 113,
    /// National Semiconductor CompactRISC CRX
    CRX = 114,
    /// Motorola XGATE embedded processor
    XGATE = 115,
    /// Infineon C16x/XC16x processor
    C166 = 116,
    /// Renesas M16C series microprocessors
    M16C = 117,
    /// Microchip Technology dsPIC30F Digital Signal Controller
    DSPIC30F = 118,
    /// Freescale Communication Engine RISC core
    CE = 119,
    /// Renesas M32C series microprocessors
    M32C = 120,
    /// Altium TSK3000 core
    TSK3000 = 131,
    /// Freescale RS08 embedded processor
    RS08 = 132,
    /// Analog Devices SHARC family of 32-bit DSP processors
    SHARC = 133,
    /// Cyan Technology eCOG2 microprocessor
    ECOG2 = 134,
    /// Sunplus S+core7 RISC processor
    SCORE7 = 135,
    /// New Japan Radio (NJR) 24-bit DSP Processor
    DSP24 = 136,
    /// Broadcom VideoCore III processor
    VIDEOCORE3 = 137,
    /// RISC processor for Lattice FPGA architecture
    LATTICEMICO32 = 138,
    /// Seiko Epson C17 family
    SE_C17 = 139,
    /// The Texas Instruments TMS320C6000 DSP family
    TI_C6000 = 140,
    /// The Texas Instruments TMS320C2000 DSP family
    TI_C2000 = 141,
    /// The Texas Instruments TMS320C55x DSP family
    TI_C5500 = 142,
    /// STMicroelectronics 64bit VLIW Data Signal Processor
    MMDSP_PLUS = 160,
    /// Cypress M8C microprocessor
    CYPRESS_M8C = 161,
    /// Renesas R32C series microprocessors
    R32C = 162,
    /// NXP Semiconductors TriMedia architecture family
    TRIMEDIA = 163,
    /// Qualcomm Hexagon processor
    HEXAGON = 164,
    /// Intel 8051 and variants
    @"8051" = 165,
    /// STMicroelectronics STxP7x family of configurable and extensible RISC processors
    STXP7X = 166,
    /// Andes Technology compact code size embedded RISC processor family
    NDS32 = 167,
    /// Cyan Technology eCOG1X family
    ECOG1X = 168,
    /// Dallas Semiconductor MAXQ30 Core Micro-controllers
    MAXQ30 = 169,
    /// New Japan Radio (NJR) 16-bit DSP Processor
    XIMO16 = 170,
    /// M2000 Reconfigurable RISC Microprocessor
    MANIK = 171,
    /// Cray Inc. NV2 vector architecture
    CRAYNV2 = 172,
    /// Renesas RX family
    RX = 173,
    /// Imagination Technologies META processor architecture
    METAG = 174,
    /// MCST Elbrus general purpose hardware architecture
    MCST_ELBRUS = 175,
    /// Cyan Technology eCOG16 family
    ECOG16 = 176,
    /// National Semiconductor CompactRISC CR16 16-bit microprocessor
    CR16 = 177,
    /// Freescale Extended Time Processing Unit
    ETPU = 178,
    /// Infineon Technologies SLE9X core
    SLE9X = 179,
    /// Intel L10M
    L10M = 180,
    /// Intel K10M
    K10M = 181,
    /// ARM AArch64
    AARCH64 = 183,
    /// Atmel Corporation 32-bit microprocessor family
    AVR32 = 185,
    /// STMicroeletronics STM8 8-bit microcontroller
    STM8 = 186,
    /// Tilera TILE64 multicore architecture family
    TILE64 = 187,
    /// Tilera TILEPro multicore architecture family
    TILEPRO = 188,
    /// NVIDIA CUDA architecture
    CUDA = 190,
    /// Tilera TILE-Gx multicore architecture family
    TILEGX = 191,
    /// CloudShield architecture family
    CLOUDSHIELD = 192,
    /// KIPO-KAIST Core-A 1st generation processor family
    COREA_1ST = 193,
    /// KIPO-KAIST Core-A 2nd generation processor family
    COREA_2ND = 194,
    /// Synopsys ARCompact V2
    ARC_COMPACT2 = 195,
    /// Open8 8-bit RISC soft processor core
    OPEN8 = 196,
    /// Renesas RL78 family
    RL78 = 197,
    /// Broadcom VideoCore V processor
    VIDEOCORE5 = 198,
    /// Renesas 78KOR family
    @"78KOR" = 199,
    /// Freescale 56800EX Digital Signal Controller (DSC)
    @"56800EX" = 200,
    /// Beyond BA1 CPU architecture
    BA1 = 201,
    /// Beyond BA2 CPU architecture
    BA2 = 202,
    /// XMOS xCORE processor family
    XCORE = 203,
    /// Microchip 8-bit PIC(r) family
    MCHP_PIC = 204,
    /// Reserved by Intel
    INTEL205 = 205,
    /// Reserved by Intel
    INTEL206 = 206,
    /// Reserved by Intel
    INTEL207 = 207,
    /// Reserved by Intel
    INTEL208 = 208,
    /// Reserved by Intel
    INTEL209 = 209,
    /// KM211 KM32 32-bit processor
    KM32 = 210,
    /// KM211 KMX32 32-bit processor
    KMX32 = 211,
    /// KM211 KMX16 16-bit processor
    KMX16 = 212,
    /// KM211 KMX8 8-bit processor
    KMX8 = 213,
    /// KM211 KVARC processor
    KVARC = 214,
    /// Paneve CDP architecture family
    CDP = 215,
    /// Cognitive Smart Memory Processor
    COGE = 216,
    /// iCelero CoolEngine
    COOL = 217,
    /// Nanoradio Optimized RISC
    NORC = 218,
    /// CSR Kalimba architecture family
    CSR_KALIMBA = 219,
    /// AMD GPU architecture
    AMDGPU = 224,
    /// RISC-V
    RISCV = 243,
    /// Lanai 32-bit processor
    LANAI = 244,
    /// Linux kernel bpf virtual machine
    BPF = 247,
    /// C-SKY
    CSKY = 252,
    /// Fujitsu FR-V
    FRV = 0x5441,
    _,
    pub fn toTargetCpuArch(em: EM) ?@TypeOf(@import("builtin").cpu.arch) {
        return switch (em) {
            .AVR => .avr,
            .MSP430 => .msp430,
            .ARC => .arc,
            .ARM => .arm,
            .HEXAGON => .hexagon,
            .@"68K" => .m68k,
            .MIPS => .mips,
            .MIPS_RS3_LE => .mipsel,
            .PPC => .powerpc,
            .SPARC => .sparc,
            // .@"386" => .i386,
            .XCORE => .xcore,
            .CSR_KALIMBA => .kalimba,
            .LANAI => .lanai,
            .AARCH64 => .aarch64,
            .PPC64 => .powerpc64,
            .RISCV => .riscv64,
            .X86_64 => .x86_64,
            .BPF => .bpfel,
            .SPARCV9 => .sparc64,
            .S390 => .s390x,
            .SPU_2 => .spu_2,
            // there's many cases we don't (yet) handle, or will never have a
            // zig target cpu arch equivalent (such as null).
            else => null,
        };
    }
};
/// Section data should be writable during execution.
pub const SHF_WRITE = 0x1;
/// Section occupies memory during program execution.
pub const SHF_ALLOC = 0x2;
/// Section contains executable machine instructions.
pub const SHF_EXECINSTR = 0x4;
/// The data in this section may be merged.
pub const SHF_MERGE = 0x10;
/// The data in this section is null-terminated strings.
pub const SHF_STRINGS = 0x20;
/// A field in this section holds a section header table index.
pub const SHF_INFO_LINK = 0x40;
/// Adds special ordering requirements for link editors.
pub const SHF_LINK_ORDER = 0x80;
/// This section requires special OS-specific processing to avoid incorrect
/// behavior.
pub const SHF_OS_NONCONFORMING = 0x100;
/// This section is a member of a section group.
pub const SHF_GROUP = 0x200;
/// This section holds Thread-Local Storage.
pub const SHF_TLS = 0x400;
/// Identifies a section containing compressed data.
pub const SHF_COMPRESSED = 0x800;
/// This section is excluded from the final executable or shared library.
pub const SHF_EXCLUDE = 0x80000000;
/// Start of target-specific flags.
pub const SHF_MASKOS = 0x0ff00000;
/// Bits indicating processor-specific flags.
pub const SHF_MASKPROC = 0xf0000000;
/// All sections with the "d" flag are grouped together by the linker to form
/// the data section and the dp register is set to the start of the section by
/// the boot code.
pub const XCORE_SHF_DP_SECTION = 0x10000000;
/// All sections with the "c" flag are grouped together by the linker to form
/// the constant pool and the cp register is set to the start of the constant
/// pool by the boot code.
pub const XCORE_SHF_CP_SECTION = 0x20000000;
/// If an object file section does not have this flag set, then it may not hold
/// more than 2GB and can be freely referred to in objects using smaller code
/// models. Otherwise, only objects using larger code models can refer to them.
/// For example, a medium code model object can refer to data in a section that
/// sets this flag besides being able to refer to data in a section that does
/// not set it; likewise, a small code model object can refer only to code in a
/// section that does not set this flag.
pub const SHF_X86_64_LARGE = 0x10000000;
/// All sections with the GPREL flag are grouped into a global data area
/// for faster accesses
pub const SHF_HEX_GPREL = 0x10000000;
/// Section contains text/data which may be replicated in other sections.
/// Linker must retain only one copy.
pub const SHF_MIPS_NODUPES = 0x01000000;
/// Linker must generate implicit hidden weak names.
pub const SHF_MIPS_NAMES = 0x02000000;
/// Section data local to process.
pub const SHF_MIPS_LOCAL = 0x04000000;
/// Do not strip this section.
pub const SHF_MIPS_NOSTRIP = 0x08000000;
/// Section must be part of global data area.
pub const SHF_MIPS_GPREL = 0x10000000;
/// This section should be merged.
pub const SHF_MIPS_MERGE = 0x20000000;
/// Address size to be inferred from section entry size.
pub const SHF_MIPS_ADDR = 0x40000000;
/// Section data is string data by default.
pub const SHF_MIPS_STRING = 0x80000000;
/// Make code section unreadable when in execute-only mode
pub const SHF_ARM_PURECODE = 0x2000000;
const PF_Bitfield = struct {
    X: bool,
    W: bool,
    R: bool,
};
/// Execute
pub const PF_X = 1;
/// Write
pub const PF_W = 2;
/// Read
pub const PF_R = 4;
/// Bits for operating system-specific semantics.
pub const PF_MASKOS = 0x0ff00000;
/// Bits for processor-specific semantics.
pub const PF_MASKPROC = 0xf0000000;
pub const PF = meta.EnumBitField(enum(u32) {
    X = PF_X,
    W = PF_W,
    R = PF_R,
    MASKOS = PF_MASKOS,
    MASKPROC = PF_MASKPROC,
});
// Special section indexes used in Elf{32,64}_Sym.
pub const SHN_UNDEF = 0;
pub const SHN_LORESERVE = 0xff00;
pub const SHN_LOPROC = 0xff00;
pub const SHN_HIPROC = 0xff1f;
pub const SHN_LIVEPATCH = 0xff20;
pub const SHN_ABS = 0xfff1;
pub const SHN_COMMON = 0xfff2;
pub const SHN_HIRESERVE = 0xffff;
/// AMD x86-64 relocations.
/// No reloc
pub const R_X86_64_NONE = 0;
/// Direct 64 bit
pub const R_X86_64_64 = 1;
/// PC relative 32 bit signed
pub const R_X86_64_PC32 = 2;
/// 32 bit GOT entry
pub const R_X86_64_GOT32 = 3;
/// 32 bit PLT address
pub const R_X86_64_PLT32 = 4;
/// Copy symbol at runtime
pub const R_X86_64_COPY = 5;
/// Create GOT entry
pub const R_X86_64_GLOB_DAT = 6;
/// Create PLT entry
pub const R_X86_64_JUMP_SLOT = 7;
/// Adjust by program base
pub const R_X86_64_RELATIVE = 8;
/// 32 bit signed PC relative offset to GOT
pub const R_X86_64_GOTPCREL = 9;
/// Direct 32 bit zero extended
pub const R_X86_64_32 = 10;
/// Direct 32 bit sign extended
pub const R_X86_64_32S = 11;
/// Direct 16 bit zero extended
pub const R_X86_64_16 = 12;
/// 16 bit sign extended pc relative
pub const R_X86_64_PC16 = 13;
/// Direct 8 bit sign extended
pub const R_X86_64_8 = 14;
/// 8 bit sign extended pc relative
pub const R_X86_64_PC8 = 15;
/// ID of module containing symbol
pub const R_X86_64_DTPMOD64 = 16;
/// Offset in module's TLS block
pub const R_X86_64_DTPOFF64 = 17;
/// Offset in initial TLS block
pub const R_X86_64_TPOFF64 = 18;
/// 32 bit signed PC relative offset to two GOT entries for GD symbol
pub const R_X86_64_TLSGD = 19;
/// 32 bit signed PC relative offset to two GOT entries for LD symbol
pub const R_X86_64_TLSLD = 20;
/// Offset in TLS block
pub const R_X86_64_DTPOFF32 = 21;
/// 32 bit signed PC relative offset to GOT entry for IE symbol
pub const R_X86_64_GOTTPOFF = 22;
/// Offset in initial TLS block
pub const R_X86_64_TPOFF32 = 23;
/// PC relative 64 bit
pub const R_X86_64_PC64 = 24;
/// 64 bit offset to GOT
pub const R_X86_64_GOTOFF64 = 25;
/// 32 bit signed pc relative offset to GOT
pub const R_X86_64_GOTPC32 = 26;
/// 64 bit GOT entry offset
pub const R_X86_64_GOT64 = 27;
/// 64 bit PC relative offset to GOT entry
pub const R_X86_64_GOTPCREL64 = 28;
/// 64 bit PC relative offset to GOT
pub const R_X86_64_GOTPC64 = 29;
/// Like GOT64, says PLT entry needed
pub const R_X86_64_GOTPLT64 = 30;
/// 64-bit GOT relative offset to PLT entry
pub const R_X86_64_PLTOFF64 = 31;
/// Size of symbol plus 32-bit addend
pub const R_X86_64_SIZE32 = 32;
/// Size of symbol plus 64-bit addend
pub const R_X86_64_SIZE64 = 33;
/// GOT offset for TLS descriptor
pub const R_X86_64_GOTPC32_TLSDESC = 34;
/// Marker for call through TLS descriptor
pub const R_X86_64_TLSDESC_CALL = 35;
/// TLS descriptor
pub const R_X86_64_TLSDESC = 36;
/// Adjust indirectly by program base
pub const R_X86_64_IRELATIVE = 37;
/// 64-bit adjust by program base
pub const R_X86_64_RELATIVE64 = 38;
/// 39 Reserved was R_X86_64_PC32_BND
/// 40 Reserved was R_X86_64_PLT32_BND
/// Load from 32 bit signed pc relative offset to GOT entry without REX prefix, relaxable
pub const R_X86_64_GOTPCRELX = 41;
/// Load from 32 bit signed PC relative offset to GOT entry with REX prefix, relaxable
pub const R_X86_64_REX_GOTPCRELX = 42;
pub const R_X86_64_NUM = 43;
pub const STV = enum(u2) {
    DEFAULT = 0,
    INTERNAL = 1,
    HIDDEN = 2,
    PROTECTED = 3,
};
const debug = opaque {
    const PrintArray = mem.StaticString(4096);

    const about_elf_1_s: []const u8 = "elf:           ";
    const about_elf_0_s: []const u8 = "elf-error:     offset=";

    fn badEndianError(hdr32: *Elf32_Ehdr) void {
        const offset: u64 = @ptrToInt(&hdr32.e_ident[EI.DATA]) - @ptrToInt(hdr32);
        var array: PrintArray = .{};
        array.writeMany(about_elf_1_s);
        array.writeFormat(fmt.ux64(offset));
        array.writeMany(", bad endian: ");
        array.writeFormat(fmt.ud64(hdr32.e_ident[EI.DATA]));
        array.writeMany("\n");
    }
    fn badVersionError(hdr32: *Elf32_Ehdr) void {
        const offset: u64 = @ptrToInt(&hdr32.e_ident[EI.VERSION]) - @ptrToInt(hdr32);
        var array: PrintArray = .{};
        array.writeMany(about_elf_1_s);
        array.writeFormat(fmt.ux64(offset));
        array.writeMany(", bad version: ");
        array.writeFormat(fmt.ud64(hdr32.e_ident[EI.VERSION]));
        array.writeMany("\n");
    }
};
