const mem = @import("mem.zig");
const tab = @import("tab.zig");
const sys = @import("sys.zig");
const x86 = @import("x86.zig");
const fmt = @import("fmt.zig");
const file = @import("file.zig");
const proc = @import("proc.zig");
const algo = @import("algo.zig");
const meta = @import("meta.zig");
const bits = @import("bits.zig");
const debug = @import("debug.zig");
const testing = @import("testing.zig");
const builtin = @import("builtin.zig");
pub const DT = enum(u32) {
    NULL = 0,
    NEEDED = 1,
    PLTRELSZ = 2,
    PLTGOT = 3,
    HASH = 4,
    STRTAB = 5,
    SYMTAB = 6,
    RELA = 7,
    RELASZ = 8,
    RELAENT = 9,
    STRSZ = 10,
    SYMENT = 11,
    INIT = 12,
    FINI = 13,
    SONAME = 14,
    RPATH = 15,
    SYMBOLIC = 16,
    REL = 17,
    RELSZ = 18,
    RELENT = 19,
    PLTREL = 20,
    DEBUG = 21,
    TEXTREL = 22,
    JMPREL = 23,
    BIND_NOW = 24,
    INIT_ARRAY = 25,
    FINI_ARRAY = 26,
    INIT_ARRAYSZ = 27,
    FINI_ARRAYSZ = 28,
    RUNPATH = 29,
    FLAGS = 30,
    ENCODING = 32,
    PREINIT_ARRAYSZ = 33,
    SYMTAB_SHNDX = 34,
    NUM = 35,
    LOOS = 1610612749,
    HIOS = 1879044096,
    LOPROC = 1879048192,
    HIPROC = 2147483647,
    PROCNUM = 54,
    VALRNGLO = 1879047424,
    GNU_PRELINKED = 1879047669,
    GNU_CONFLICTSZ = 1879047670,
    GNU_LIBLISTSZ = 1879047671,
    CHECKSUM = 1879047672,
    PLTPADSZ = 1879047673,
    MOVEENT = 1879047674,
    MOVESZ = 1879047675,
    FEATURE_1 = 1879047676,
    POSFLAG_1 = 1879047677,
    SYMINSZ = 1879047678,
    SYMINENT = 1879047679,
    ADDRRNGLO = 1879047680,
    GNU_HASH = 1879047925,
    TLSDESC_PLT = 1879047926,
    TLSDESC_GOT = 1879047927,
    GNU_CONFLICT = 1879047928,
    GNU_LIBLIST = 1879047929,
    CONFIG = 1879047930,
    DEPAUDIT = 1879047931,
    AUDIT = 1879047932,
    PLTPAD = 1879047933,
    MOVETAB = 1879047934,
    SYMINFO = 1879047935,
    VERSYM = 1879048176,
    RELACOUNT = 1879048185,
    RELCOUNT = 1879048186,
    FLAGS_1 = 1879048187,
    VERDEF = 1879048188,
    VERDEFNUM = 1879048189,
    VERNEED = 1879048190,
    VERNEEDNUM = 1879048191,
    AUXILIARY = 2147483645,
    MIPS_RLD_VERSION = 1879048193,
    MIPS_TIME_STAMP = 1879048194,
    MIPS_ICHECKSUM = 1879048195,
    MIPS_IVERSION = 1879048196,
    MIPS_FLAGS = 1879048197,
    MIPS_BASE_ADDRESS = 1879048198,
    MIPS_MSYM = 1879048199,
    MIPS_CONFLICT = 1879048200,
    MIPS_LIBLIST = 1879048201,
    MIPS_LOCAL_GOTNO = 1879048202,
    MIPS_CONFLICTNO = 1879048203,
    MIPS_LIBLISTNO = 1879048208,
    MIPS_SYMTABNO = 1879048209,
    MIPS_UNREFEXTNO = 1879048210,
    MIPS_GOTSYM = 1879048211,
    MIPS_HIPAGENO = 1879048212,
    MIPS_RLD_MAP = 1879048214,
    MIPS_DELTA_CLASS = 1879048215,
    MIPS_DELTA_CLASS_NO = 1879048216,
    MIPS_DELTA_INSTANCE = 1879048217,
    MIPS_DELTA_INSTANCE_NO = 1879048218,
    MIPS_DELTA_RELOC = 1879048219,
    MIPS_DELTA_RELOC_NO = 1879048220,
    MIPS_DELTA_SYM = 1879048221,
    MIPS_DELTA_SYM_NO = 1879048222,
    MIPS_DELTA_CLASSSYM = 1879048224,
    MIPS_DELTA_CLASSSYM_NO = 1879048225,
    MIPS_CXX_FLAGS = 1879048226,
    MIPS_PIXIE_INIT = 1879048227,
    MIPS_SYMBOL_LIB = 1879048228,
    MIPS_LOCALPAGE_GOTIDX = 1879048229,
    MIPS_LOCAL_GOTIDX = 1879048230,
    MIPS_HIDDEN_GOTIDX = 1879048231,
    MIPS_PROTECTED_GOTIDX = 1879048232,
    MIPS_OPTIONS = 1879048233,
    MIPS_INTERFACE = 1879048234,
    MIPS_DYNSTR_ALIGN = 1879048235,
    MIPS_INTERFACE_SIZE = 1879048236,
    MIPS_RLD_TEXT_RESOLVE_ADDR = 1879048237,
    MIPS_PERF_SUFFIX = 1879048238,
    MIPS_COMPACT_SIZE = 1879048239,
    MIPS_GP_VALUE = 1879048240,
    MIPS_AUX_DYNAMIC = 1879048241,
    MIPS_PLTGOT = 1879048242,
    MIPS_RWPLT = 1879048244,
    MIPS_RLD_MAP_REL = 1879048245,
};
pub const PT = enum(u32) {
    NULL = 0,
    LOAD = 1,
    DYNAMIC = 2,
    INTERP = 3,
    NOTE = 4,
    SHLIB = 5,
    PHDR = 6,
    TLS = 7,
    NUM = 8,
    LOOS = 1610612736,
    GNU_EH_FRAME = 1685382480,
    GNU_STACK = 1685382481,
    GNU_RELRO = 1685382482,
    GNU_UNKNOWN = 1685382483,
    LOSUNW = 1879048186,
    HISUNW = 1879048191,
    LOPROC = 1879048192,
    HIPROC = 2147483647,
};
pub const SHT = enum(u32) {
    NULL = 0,
    PROGBITS = 1,
    SYMTAB = 2,
    STRTAB = 3,
    RELA = 4,
    HASH = 5,
    DYNAMIC = 6,
    NOTE = 7,
    NOBITS = 8,
    REL = 9,
    SHLIB = 10,
    DYNSYM = 11,
    INIT_ARRAY = 14,
    FINI_ARRAY = 15,
    PREINIT_ARRAY = 16,
    GROUP = 17,
    SYMTAB_SHNDX = 18,
    LOOS = 1610612736,
    GNU_HASH = 1879048182,
    HIOS = 1879048191,
    LOPROC = 1879048192,
    HIPROC = 2147483647,
    LOUSER = 2147483648,
    HIUSER = 4294967295,
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
pub const STT = enum(u8) {
    NOTYPE = 0,
    OBJECT = 1,
    FUNC = 2,
    SECTION = 3,
    FILE = 4,
    COMMON = 5,
    TLS = 6,
    NUM = 7,
    LOOS = 10,
    HIOS = 12,
    LOPROC = 13,
    HIPROC = 15,
    UNKNOWN = 18,
    HP_OPAQUE = 11,
};
pub const VER_FLG_BASE = 0x1;
pub const VER_FLG_WEAK = 0x2;
pub const MAGIC = "\x7fELF";
/// File types
pub const ET = enum(u16) {
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
};
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
    ident: [16]u8,
    type: ET,
    machine: EM,
    version: u32,
    entry: u32,
    phoff: u32,
    shoff: u32,
    flags: u32,
    ehsize: u16,
    phentsize: u16,
    phnum: u16,
    shentsize: u16,
    shnum: u16,
    shstrndx: u16,
};
pub const Elf64_Ehdr = extern struct {
    ident: [16]u8,
    type: ET,
    machine: EM,
    version: u32,
    entry: u64,
    phoff: u64,
    shoff: u64,
    flags: u32,
    ehsize: u16,
    phentsize: u16,
    phnum: u16,
    shentsize: u16,
    shnum: u16,
    shstrndx: u16,
    pub fn sectionHeader(ehdr: *Elf64_Ehdr, idx: usize) *Elf64_Shdr {
        @setRuntimeSafety(builtin.is_safe);
        return @ptrFromInt((@intFromPtr(ehdr) +% ehdr.shoff) +% (ehdr.shentsize *% idx));
    }
    pub fn programHeader(ehdr: *Elf64_Ehdr, idx: usize) *Elf64_Phdr {
        @setRuntimeSafety(builtin.is_safe);
        return @ptrFromInt((@intFromPtr(ehdr) +% ehdr.phoff) +% (ehdr.phentsize *% idx));
    }
    pub fn sectionName(ehdr: *Elf64_Ehdr, idx: usize) [:0]u8 {
        @setRuntimeSafety(builtin.is_safe);
        return mem.terminate(@ptrFromInt(@intFromPtr(ehdr) +%
            ehdr.sectionHeader(ehdr.shstrndx).offset +%
            ehdr.sectionHeader(idx).name), 0);
    }
    pub fn sectionBytes(ehdr: *Elf64_Ehdr, idx: usize) []u8 {
        @setRuntimeSafety(builtin.is_safe);
        @as([*]u8, @ptrFromInt(@intFromPtr(ehdr) +%
            ehdr.sectionHeader(idx).offset))[0..ehdr.sectionHeader(idx).size];
    }
};
pub const Elf32_Phdr = extern struct {
    type: PT,
    offset: u32,
    vaddr: u32,
    paddr: u32,
    filesz: u32,
    memsz: u32,
    flags: PF,
    @"align": u32,
};
pub const Elf64_Phdr = extern struct {
    type: PT,
    flags: PF,
    offset: u64,
    vaddr: u64,
    paddr: u64,
    filesz: u64,
    memsz: u64,
    @"align": u64,
};
pub const Elf32_Shdr = extern struct {
    name: u32,
    type: SHT,
    flags: SHF,
    addr: u32,
    offset: u32,
    size: u32,
    link: u32,
    info: u32,
    addralign: u32,
    entsize: u32,
};
pub const Elf64_Shdr = extern struct {
    name: u32,
    type: SHT,
    flags: SHF,
    addr: u64,
    offset: u64,
    size: u64,
    link: u32,
    info: u32,
    addralign: u64,
    entsize: u64,
};
pub const Elf32_Chdr = extern struct {
    type: u32,
    size: u32,
    addralign: u32,
};
pub const Elf64_Chdr = extern struct {
    type: u32,
    reserved: u32,
    size: u64,
    addralign: u64,
};
pub const Elf32_Sym = extern struct {
    name: u32,
    value: u32,
    size: u32,
    info: STT,
    other: STV,
    shndx: u16,
};
pub const Elf64_Sym = extern struct {
    name: u32,
    info: STT,
    other: STV,
    shndx: u16,
    value: u64,
    size: u64,
};
pub const Elf64_Sym_Idx = packed struct {
    name: u32,
    info: STT,
    other: STV,
    shndx: u16,
    value: u64,
    size: u64,
    index: u64,
};
pub const Elf32_Syminfo = extern struct {
    boundto: u16,
    flags: u16,
};
pub const Elf64_Syminfo = extern struct {
    boundto: u16,
    flags: u16,
};
pub const Elf32_Rel = extern struct {
    offset: u32,
    info: u32,
    pub inline fn r_sym(self: @This()) u24 {
        return @as(u24, @truncate(self.info >> 8));
    }
    pub inline fn r_type(self: @This()) u8 {
        return @as(u8, @truncate(self.info & 0xff));
    }
};
pub const Elf64_Rel = extern struct {
    offset: u64,
    info: packed struct(u64) {
        type: R_X86_64,
        zb32: u24,
        sym: u32,
    },
};
pub const Elf32_Rela = extern struct {
    offset: u32,
    info: u32,
    addend: i32,
};
pub const Elf64_Rela = extern struct {
    offset: u64,
    info: packed struct(u64) {
        type: R_X86_64,
        zb32: u24,
        sym: u32,
    },
    addend: i64,
};
pub const Elf32_Dyn = extern struct {
    tag: DT,
    val: u32,
};
pub const Elf64_Dyn = extern struct {
    tag: DT,
    val: u64,
};
pub const Elf32_Verdef = extern struct {
    version: u16,
    flags: u16,
    ndx: u16,
    cnt: u16,
    hash: u32,
    aux: u32,
    next: u32,
};
pub const Elf64_Verdef = extern struct {
    version: u16,
    flags: u16,
    ndx: u16,
    cnt: u16,
    hash: u32,
    aux: u32,
    next: u32,
};
pub const Elf32_Verdaux = extern struct {
    name: u32,
    next: u32,
};
pub const Elf64_Verdaux = extern struct {
    name: u32,
    next: u32,
};
pub const Elf32_Verneed = extern struct {
    version: u16,
    cnt: u16,
    file: u32,
    aux: u32,
    next: u32,
};
pub const Elf64_Verneed = extern struct {
    version: u16,
    cnt: u16,
    file: u32,
    aux: u32,
    next: u32,
};
pub const Elf32_Vernaux = extern struct {
    hash: u32,
    flags: u16,
    other: u16,
    name: u32,
    next: u32,
};
pub const Elf64_Vernaux = extern struct {
    hash: u32,
    flags: u16,
    other: u16,
    name: u32,
    next: u32,
};
pub const Elf32_auxv_t = extern struct {
    type: u32,
    un: extern union {
        a_val: u32,
    },
};
pub const Elf64_auxv_t = extern struct {
    type: u64,
    un: extern union {
        a_val: u64,
    },
};
pub const Elf32_Nhdr = extern struct {
    namesz: u32,
    descsz: u32,
    ype: u32,
};
pub const Elf64_Nhdr = extern struct {
    namesz: u32,
    descsz: u32,
    type: u32,
};
pub const Elf32_Move = extern struct {
    value: u64,
    info: u32,
    poffset: u32,
    repeat: u16,
    stride: u16,
};
pub const Elf64_Move = extern struct {
    value: u64,
    info: u64,
    poffset: u64,
    epeat: u16,
    stride: u16,
};
pub const Elf32_gptab = extern union {
    header: extern struct {
        current_g_value: u32,
        unused: u32,
    },
    _entry: extern struct {
        g_value: u32,
        gt_bytes: u32,
    },
};
pub const Elf32_RegInfo = extern struct {
    gprmask: u32,
    cprmask: [4]u32,
    gp_value: i32,
};
pub const Elf_Options = extern struct {
    kind: u8,
    size: u8,
    section: u16,
    info: u32,
};
pub const Elf_Options_Hw = extern struct {
    flags1: u32,
    flags2: u32,
};
pub const Elf32_Lib = extern struct {
    name: u32,
    time_stamp: u32,
    checksum: u32,
    version: u32,
    flags: u32,
};
pub const Elf64_Lib = extern struct {
    name: u32,
    time_stamp: u32,
    checksum: u32,
    version: u32,
    flags: u32,
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
};
pub const SHF = packed struct(usize) {
    /// Section data should be writable during execution.
    WRITE: bool = false,
    /// Section occupies memory during program execution.
    ALLOC: bool = false,
    /// Section contains executable machine instructions.
    EXECINSTR: bool = false,
    zb3: u1 = 0,
    /// The data in this section may be merged.
    MERGE: bool = false,
    /// The data in this section is null-terminated strings.
    STRINGS: bool = false,
    /// A field in this section holds a section header table index.
    INFO_LINK: bool = false,
    /// Adds special ordering requirements for link editors.
    LINK_ORDER: bool = false,
    /// This section requires special OS-specific processing to avoid incorrect
    /// behavior.
    OS_NONCONFORMING: bool = false,
    /// This section is a member of a section group.
    GROUP: bool = false,
    /// This section holds Thread-Local Storage.
    TLS: bool = false,
    /// Identifies a section containing compressed data.
    COMPRESSED: bool = false,
    zb12: u16 = 0,
    XCORE_SHF_DP_SECTION: bool = false,
    XCORE_SHF_CP_SECTION: bool = false,
    zb30: u1 = 0,
    /// This section is excluded from the final executable or shared library.
    EXCLUDE: bool = false,
    zb32: u32 = 0,
    /// All sections with the "d" flag are grouped together by the linker to form
    /// the data section and the dp register is set to the start of the section by
    /// the boot code.
    pub const XCORE_SHF_DP_SECTION = 0x10000000;
    /// All sections with the "c" flag are grouped together by the linker to form
    /// the constant pool and the cp register is set to the start of the constant
    /// pool by the boot code.
    pub const XCORE_SHF_CP_SECTION = 0x20000000;
    pub const HEX = struct {
        /// All sections with the GPREL flag are grouped into a global data area
        /// for faster accesses
        pub const HEX_GPREL = 0x10000000;
    };
    pub const ARM = struct {
        /// Make code section unreadable when in execute-only mode
        pub const ARM_PURECODE = 0x2000000;
    };
    pub const X86_64 = struct {
        /// If an object file section does not have this flag set, then it may not hold
        /// more than 2GB and can be freely referred to in objects using smaller code
        /// models. Otherwise, only objects using larger code models can refer to them.
        /// For example, a medium code model object can refer to data in a section that
        /// sets this flag besides being able to refer to data in a section that does
        /// not set it; likewise, a small code model object can refer only to code in a
        /// section that does not set this flag.
        pub const LARGE = 0x10000000;
    };
    pub const MIPS = struct {
        /// Section contains text/data which may be replicated in other sections.
        /// Linker must retain only one copy.
        pub const MIPS_NODUPES = 0x01000000;
        /// Linker must generate implicit hidden weak names.
        pub const MIPS_NAMES = 0x02000000;
        /// Section data local to process.
        pub const MIPS_LOCAL = 0x04000000;
        /// Do not strip this section.
        pub const MIPS_NOSTRIP = 0x08000000;
        /// Section must be part of global data area.
        pub const MIPS_GPREL = 0x10000000;
        /// This section should be merged.
        pub const MIPS_MERGE = 0x20000000;
        /// Address size to be inferred from section entry size.
        pub const MIPS_ADDR = 0x40000000;
        /// Section data is string data by default.
        pub const MIPS_STRING = 0x80000000;
    };
};
const PF = packed struct(u32) {
    /// Execute
    X: bool = false,
    /// Write
    W: bool = false,
    /// Read
    R: bool = false,
    zb3: u29 = 0,
    /// Bits for operating system-specific semantics.
    pub const PF_MASKOS = 0x0ff00000;
    /// Bits for processor-specific semantics.
    pub const PF_MASKPROC = 0xf0000000;
};
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
const R_X86_64 = enum(u8) {
    /// No reloc
    NONE = 0,
    /// Direct 64 bit
    @"64" = 1,
    /// PC relative 32 bit signed
    PC32 = 2,
    /// 32 bit GOT entry
    GOT32 = 3,
    /// 32 bit PLT address
    PLT32 = 4,
    /// Copy symbol at runtime
    COPY = 5,
    /// Create GOT entry
    GLOB_DAT = 6,
    /// Create PLT entry
    JUMP_SLOT = 7,
    /// Adjust by program base
    RELATIVE = 8,
    /// 32 bit signed PC relative offset to GOT
    GOTPCREL = 9,
    /// Direct 32 bit zero extended
    @"32" = 10,
    /// Direct 32 bit sign extended
    @"32S" = 11,
    /// Direct 16 bit zero extended
    @"16" = 12,
    /// 16 bit sign extended pc relative
    PC16 = 13,
    /// Direct 8 bit sign extended
    @"8" = 14,
    /// 8 bit sign extended pc relative
    PC8 = 15,
    /// ID of module containing symbol
    DTPMOD64 = 16,
    /// Offset in module's TLS block
    DTPOFF64 = 17,
    /// Offset in initial TLS block
    TPOFF64 = 18,
    /// 32 bit signed PC relative offset to two GOT entries for GD symbol
    TLSGD = 19,
    /// 32 bit signed PC relative offset to two GOT entries for LD symbol
    TLSLD = 20,
    /// Offset in TLS block
    DTPOFF32 = 21,
    /// 32 bit signed PC relative offset to GOT entry for IE symbol
    GOTTPOFF = 22,
    /// Offset in initial TLS block
    TPOFF32 = 23,
    /// PC relative 64 bit
    PC64 = 24,
    /// 64 bit offset to GOT
    GOTOFF64 = 25,
    /// 32 bit signed pc relative offset to GOT
    GOTPC32 = 26,
    /// 64 bit GOT entry offset
    GOT64 = 27,
    /// 64 bit PC relative offset to GOT entry
    GOTPCREL64 = 28,
    /// 64 bit PC relative offset to GOT
    GOTPC64 = 29,
    /// Like GOT64, says PLT entry needed
    GOTPLT64 = 30,
    /// 64-bit GOT relative offset to PLT entry
    PLTOFF64 = 31,
    /// Size of symbol plus 32-bit addend
    SIZE32 = 32,
    /// Size of symbol plus 64-bit addend
    SIZE64 = 33,
    /// GOT offset for TLS descriptor
    GOTPC32_TLSDESC = 34,
    /// Marker for call through TLS descriptor
    TLSDESC_CALL = 35,
    /// TLS descriptor
    TLSDESC = 36,
    /// Adjust indirectly by program base
    IRELATIVE = 37,
    /// 64-bit adjust by program base
    RELATIVE64 = 38,
    /// 39 Reserved was R_X86_64_PC32_BND
    /// 40 Reserved was R_X86_64_PLT32_BND
    /// Load from 32 bit signed pc relative offset to GOT entry without REX prefix, relaxable
    GOTPCRELX = 41,
    /// Load from 32 bit signed PC relative offset to GOT entry with REX prefix, relaxable
    REX_GOTPCRELX = 42,
    NUM = 43,
};
pub const STV = enum(u8) {
    DEFAULT = 0,
    INTERNAL = 1,
    HIDDEN = 2,
    PROTECTED = 3,
};
const Section = enum(u16) {
    @".dynamic" = 0,
    @".symtab" = 1,
    @".dynsym" = 2,
    @".dynstr" = 3,
    @".text" = 4,
    @".strtab" = 5,
    @".rodata" = 6,
    @".bss" = 7,
    @".tbss" = 8,
    @".rodata.data" = 9,
    @".shstrtab" = 10,
    @".eh_frame_hdr" = 11,
    @".eh_frame" = 12,
    @".data.rel.ro" = 13,
    @".data" = 14,
    @".data.rodata" = 15,
    @".hash" = 16,
    @".gnu.hash" = 17,
    @".comment" = 18,
    @".got" = 19,
    @".rela.dyn" = 20,
    @".rela.plt" = 21,
    @".rela.text" = 22,
    @".rela.data.rel.ro" = 23,
    @".debug_info" = 24,
    @".debug_abbrev" = 25,
    @".debug_str" = 26,
    @".debug_str_offsets" = 27,
    @".debug_line" = 28,
    @".debug_line_str" = 29,
    @".debug_ranges" = 30,
    @".debug_loclists" = 31,
    @".debug_rnglists" = 32,
    @".debug_addr" = 33,
    @".debug_names" = 34,
    @".debug_frame" = 35,
    @".note.gnu.property" = 36,
    @".note.gnu.build-id" = 37,
    @".note.ABI-tag" = 38,
    @".gnu.version" = 39,
    @".gnu.version_r" = 40,
    @".init_array" = 41,
    @".fini_array" = 42,
    const tag_list: [43]Section = @bitCast([43]u16{
        0,  1,  2,  3,  4,  5,  6,  7,
        8,  9,  10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
        32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42,
    });
    comptime {
        if (@typeInfo(Section).Enum.fields.len != tag_list.len) {
            @compileError("incomplete section tag list");
        }
    }
};
pub const LoaderSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    AddressSpace: type,
    pub const Options = struct {
        /// (.Devel) Commit final writes. Might disable to prefer viewing summary.
        write_symbols: bool = true,
        /// (.Devel) Debug output all matches.
        print_final_summary: bool = false,
        /// (.Devel) Debug output all matches (version 2).
        print_final_summary2: bool = false,
        /// (.Devel) Test whether formatter expected length matches actual
        /// written length.
        verify_lengths: bool = false,
        /// Determines if and how symbols should be sorted.
        sort: bool = true,
        const SortingPolicy = enum {
            /// Only sort symbol table entries if the symbol table entry size
            /// matches the symbol size. This allows sorting using a generic
            /// algorithm, and avoids operating over the entire table.
            ideal,
            /// Sort symbol table regardless of symbol table entry size.
            /// This requires a potentially slower algorithm.
            always,
            /// Never sort symbol table entries.
            never,
        };
    };
    pub const Logging = packed struct {
        show_elf_header: bool = false,
        show_relocations: bool = false,
        show_mangled_symbols: bool = true,
        show_anonymous_symbols: bool = false,
        show_unchanged_symbols: bool = false,
        show_insignificant: bool = false,
        show_insignificant_increases: bool = true,
        show_insignificant_decreases: bool = true,
        show_insignificant_additions: bool = true,
        show_insignificant_deletions: bool = true,
        open: debug.Logging.AttemptAcquireError = .{},
        seek: debug.Logging.SuccessError = .{},
        stat: debug.Logging.SuccessErrorFault = .{},
        read: debug.Logging.SuccessError = .{},
        map: debug.Logging.AcquireError = .{},
        unmap: debug.Logging.ReleaseError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    pub const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = file.spec.open.errors.all },
        stat: sys.ErrorPolicy = .{ .throw = file.spec.stat.errors.all },
        map: sys.ErrorPolicy = .{ .throw = mem.spec.mmap.errors.all },
        unmap: sys.ErrorPolicy = .{ .abort = mem.spec.munmap.errors.all },
        close: sys.ErrorPolicy = .{ .abort = file.spec.close.errors.all },
    };
};
pub fn GenericDynamicLoader(comptime loader_spec: LoaderSpec) type {
    const map = .{ .logging = loader_spec.logging.map, .errors = loader_spec.errors.map };
    const open = .{ .logging = loader_spec.logging.open, .errors = loader_spec.errors.open };
    const stat = .{ .logging = loader_spec.logging.stat, .errors = loader_spec.errors.stat };
    const close = .{ .logging = loader_spec.logging.close, .errors = loader_spec.errors.close };
    const unmap = .{ .logging = loader_spec.logging.unmap, .errors = loader_spec.errors.unmap };
    const ep1 = .{
        .throw = map.errors.throw ++ open.errors.throw ++ close.errors.throw ++ stat.errors.throw,
        .abort = map.errors.abort ++ open.errors.abort ++ close.errors.abort ++ stat.errors.abort,
    };
    const mmap_flags = .{
        .fixed = false,
        .fixed_noreplace = true,
    };
    const T = struct {
        meta: mem.Bounds = .{
            .lb_addr = lb_meta_addr,
            .up_addr = lb_meta_addr,
        },
        prog: mem.Bounds = .{
            .lb_addr = lb_prog_addr,
            .up_addr = lb_prog_addr,
        },
        const DynamicLoader = @This();
        pub const ElfInfo = extern struct {
            ehdr: *Elf64_Ehdr = @ptrFromInt(8),
            meta: mem.Vector = .{ .addr = 0, .len = 0 },
            prog: mem.Vector = .{ .addr = 0, .len = 0 },
            list: [Section.tag_list.len]u16 = .{0} ** Section.tag_list.len,
            pub fn entry(ei: *const ElfInfo) *const fn (*anyopaque) void {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(ei.prog.addr +% ei.ehdr.entry);
            }
            pub fn symbolBytes(ei: *const ElfInfo, sym: *const Elf64_Sym_Idx) []u8 {
                @setRuntimeSafety(builtin.is_safe);
                const bytes: [*]u8 = @ptrFromInt(ei.prog.addr +% sym.value);
                return bytes[0..sym.size];
            }
            pub fn bestSymbolTable(ei: *const ElfInfo) ?*Elf64_Shdr {
                @setRuntimeSafety(builtin.is_safe);
                if (ei.list[1] != 0) {
                    return ei.ehdr.sectionHeader(ei.list[1]);
                }
                if (ei.list[2] != 0) {
                    return ei.ehdr.sectionHeader(ei.list[2]);
                }
                return null;
            }
        };
        pub const lb_meta_addr: comptime_int = loader_spec.AddressSpace.arena(0).lb_addr;
        pub const lb_prog_addr: comptime_int = loader_spec.AddressSpace.arena(1).lb_addr;
        pub fn load(loader: *DynamicLoader, pathname: [:0]const u8) sys.ErrorUnion(ep1, ElfInfo) {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = try meta.wrap(file.open(open, .{}, pathname));
            var st: file.Status = .{};
            try meta.wrap(file.status(stat, fd, &st));
            st.size = bits.alignA4096(st.size);
            var ei: ElfInfo = .{};
            ei.meta.addr = @atomicRmw(usize, &loader.meta.up_addr, .Add, st.size, .SeqCst);
            const addr: usize = bits.alignA4096(ei.meta.addr);
            const end: usize = ei.meta.addr +% st.size;
            const size: usize = st.size +% bits.alignA4096(ei.meta.addr -% addr);
            try meta.wrap(file.map(map, .{}, mmap_flags, fd, addr, size, 0));
            ei.ehdr = @ptrFromInt(addr);
            var phndx: usize = 1;
            while (phndx != ei.ehdr.phnum) : (phndx +%= 1) {
                const phdr: *Elf64_Phdr = ei.ehdr.programHeader(phndx);
                if (phdr.type == .LOAD and phdr.memsz != 0) {
                    ei.prog.len +%= bits.alignA4096(phdr.vaddr +% phdr.memsz);
                }
            } else {
                phndx = 1;
            }
            ei.prog.addr = bits.alignA4096(@atomicRmw(usize, &loader.prog.up_addr, .Add, ei.prog.len, .SeqCst));
            while (phndx != ei.ehdr.phnum) : (phndx +%= 1) {
                const phdr: *Elf64_Phdr = ei.ehdr.programHeader(phndx);
                if (phdr.type == .LOAD and phdr.memsz != 0) {
                    const prot: sys.flags.FileProt = .{ .read = phdr.flags.R, .write = phdr.flags.W, .exec = phdr.flags.X };
                    const vaddr: usize = bits.alignB4096(phdr.vaddr);
                    const len: usize = bits.alignA4096(phdr.vaddr +% phdr.memsz) -% vaddr;
                    const off: usize = bits.alignB4096(phdr.offset);
                    try meta.wrap(file.map(map, prot, mmap_flags, fd, ei.prog.addr +% vaddr, len, off));
                }
            } else {
                phndx = 1;
            }
            try meta.wrap(file.close(close, fd));
            var shndx: usize = 1;
            while (shndx != ei.ehdr.shnum) : (shndx +%= 1) {
                const shdr: *Elf64_Shdr = ei.ehdr.sectionHeader(shndx);
                for (Section.tag_list) |tag| {
                    if (ei.list[@intFromEnum(tag)] == 0 and
                        mem.testEqualString(ei.ehdr.sectionName(shndx), @tagName(tag)))
                    {
                        ei.list[@intFromEnum(tag)] = @intCast(shndx);
                        break;
                    }
                }
                if (shdr.type == .DYNAMIC) {
                    var rela_addr: usize = 0;
                    var rela_entsize: usize = 0;
                    var rela_len: usize = 0;
                    const dyn_len: usize = @divExact(shdr.size, shdr.entsize);
                    const dyn: [*]Elf64_Dyn = @ptrFromInt(ei.prog.addr + shdr.addr);
                    var dyn_idx: usize = 1;
                    while (dyn_idx != dyn_len) : (dyn_idx +%= 1) {
                        switch (dyn[dyn_idx].tag) {
                            else => continue,
                            .RELA => rela_addr = dyn[dyn_idx].val,
                            .RELACOUNT => rela_len = dyn[dyn_idx].val,
                            .RELAENT => rela_entsize = dyn[dyn_idx].val,
                        }
                    }
                    if (rela_addr == 0) {
                        continue;
                    }
                    rela_addr +%= ei.prog.addr;
                    var rela_idx: usize = 0;
                    while (rela_idx != rela_len) : (rela_idx +%= 1) {
                        const rela: *Elf64_Rela = @ptrFromInt(rela_addr +% (rela_entsize *% rela_idx));
                        if (rela.info.type == .RELATIVE) {
                            const dest: *usize = @ptrFromInt(ei.prog.addr +% rela.offset);
                            const src: isize = @bitCast(ei.prog.addr);
                            dest.* = @bitCast(src +% rela.addend);
                        }
                    }
                }
            } else {
                shndx = 1;
            }
            var offset: usize = ei.ehdr.phoff +% ei.ehdr.phentsize *% ei.ehdr.phnum;
            while (shndx != ei.ehdr.shnum) : (shndx +%= 1) {
                const shdr: *Elf64_Shdr = ei.ehdr.sectionHeader(shndx);
                if (shdr.addr == 0) {
                    offset = bits.alignA64(addr +% offset, shdr.addralign) -% addr;
                    mem.addrcpy(addr + offset, addr + shdr.offset, shdr.size);
                    shdr.offset = offset;
                    offset +%= shdr.size;
                }
            }
            offset = bits.alignA64(offset, 8);
            mem.addrcpy(addr + offset, addr + ei.ehdr.shoff, ei.ehdr.shentsize *% ei.ehdr.shnum);
            ei.ehdr.shoff = offset;
            offset = offset +% ei.ehdr.shentsize *% ei.ehdr.shnum;
            const new: usize = bits.alignA4096(addr +% offset);
            if (new < end) {
                mem.unmap(unmap, new, end -% new);
                _ = @cmpxchgStrong(usize, &loader.meta.up_addr, end, new, .SeqCst, .SeqCst);
            }
            return ei;
        }
        pub fn unmapAll(loader: *DynamicLoader) void {
            mem.unmap(unmap, loader.meta.lb_addr, loader.meta.up_addr -% loader.meta.lb_addr);
            mem.unmap(unmap, loader.prog.lb_addr, loader.prog.up_addr -% loader.prog.lb_addr);
        }
        pub fn sortSymtab(allocator: *mem.SimpleAllocator, ei: *ElfInfo, st_shdr: *Elf64_Shdr) [*][]Elf64_Sym_Idx {
            @setRuntimeSafety(builtin.is_safe);
            const start: usize = @intFromPtr(ei.ehdr) +% st_shdr.offset;
            const finish: usize = start +% st_shdr.size;
            const pool: usize = allocator.allocateRaw(24 *% ei.ehdr.shnum, 8);
            mem.addrset(pool, 0, 24 *% ei.ehdr.shnum);
            const counts: [*]usize = @ptrFromInt(pool);
            const slices: [*][]Elf64_Sym_Idx = @ptrFromInt(pool +% (8 *% ei.ehdr.shnum));
            var itr: packed union { addr: usize, sym: *Elf64_Sym } = @bitCast(start +% st_shdr.entsize);
            while (itr.addr != finish) : (itr.addr +%= st_shdr.entsize) {
                if (itr.sym.shndx < ei.ehdr.shnum) {
                    counts[itr.sym.shndx] +%= 1;
                }
            }
            for (0..ei.ehdr.shnum) |shndx| {
                const syms: [*]Elf64_Sym_Idx = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(Elf64_Sym_Idx) *% counts[shndx],
                    @alignOf(Elf64_Sym_Idx),
                ));
                slices[shndx] = syms[0..counts[shndx]];
                counts[shndx] = 0;
            }
            itr.addr = start +% st_shdr.entsize;
            var sym_idx: usize = 0;
            while (itr.addr != finish) : (itr.addr +%= st_shdr.entsize) {
                sym_idx +%= 1;
                if (itr.sym.shndx < ei.ehdr.shnum and slices[itr.sym.shndx].len != 0) {
                    slices[itr.sym.shndx][counts[itr.sym.shndx]] = .{
                        .name = itr.sym.name,
                        .index = @truncate(sym_idx),
                        .info = itr.sym.info,
                        .other = itr.sym.other,
                        .value = @truncate(itr.sym.value),
                        .shndx = itr.sym.shndx,
                        .size = @truncate(itr.sym.size),
                    };
                    counts[itr.sym.shndx] +%= 1;
                }
            }
            for (1..ei.ehdr.shnum) |shndx| {
                algo.shellSort(Elf64_Sym_Idx, compare.Sort.sortSymbolSize, slices[shndx]);
            }
            return slices;
        }
        pub const compare = struct {
            pub const Cmp = struct {
                /// Match status for the before ELF
                mats1: [*]Matches,
                /// Match status for the after ELF
                mats2: [*]Matches,
                /// Sorted symbols by section and size for the before ELF
                syms1: ?[*][]Elf64_Sym_Idx = null,
                /// Sorted symbols by section and size for the after ELF
                syms2: ?[*][]Elf64_Sym_Idx = null,
                sizes: [*]SizeDiff,
                const Matches = struct {
                    /// Match (if any) against other section.
                    mat: Match = .{ .tag = .unknown },
                    /// Matches of all symbols against matched section.
                    mats: []Match = &.{},
                };
                const SizeDiff = struct {
                    /// Total
                    sizes_r1: Sizes = .{},
                    /// Ommitted
                    sizes_r2: Sizes = .{},
                };
            };
            const Sizes = extern struct {
                old: usize = 0,
                new: usize = 0,
                common: usize = 0,
                increases: usize = 0,
                decreases: usize = 0,
                additions: usize = 0,
                deletions: usize = 0,
                fn isZero(sizes: *Sizes) bool {
                    return sizes.decreases |
                        sizes.increases |
                        sizes.additions |
                        sizes.deletions == 0;
                }
            };
            const Match = struct {
                idx: u32 = no_idx,
                tag: Tag = .unknown,
                flags: Flags = .{},
                name: NameIndices = .{},
                const no_idx: u16 = ~@as(u16, 0);
                const Tag = enum(u8) {
                    unknown = 0,
                    increase = 1,
                    decrease = 2,
                    matched = 3,
                    identical = 4,
                    addition = 5,
                    deletion = 6,
                    unmatched = 7,
                };
                const Flags = struct {
                    /// Whether changes to this symbol should be ignored by
                    /// options `show_insignificant_*`.
                    is_insignificant: bool = false,
                    /// Whether the symbol will be ignored by any option.
                    is_hidden: bool = false,
                };
                pub fn isMangled(mat: Match) bool {
                    return mat.name.mangle_idx != mat.name.len;
                }
                pub fn isAnonymous(mat: Match) bool {
                    return mat.name.mangle_idx == 0;
                }
                pub fn isToplevel(mat: Match) bool {
                    return mat.name.short_idx == 0;
                }
                fn matchName(mat: *Match, strtab: [*]u8) ?[:0]u8 {
                    @setRuntimeSafety(false);
                    if (mat.name.len == 0) {
                        var idx: usize = 0;
                        while (strtab[idx] != 0) {
                            idx +%= 1;
                        }
                        const len: usize = @min(idx, ~@as(u16, 0));
                        mat.name.len = @intCast(len);
                        mat.name.mangle_idx = @intCast(len);
                        var byte: u8 = strtab[idx];
                        while (idx != 0) : (byte = strtab[idx]) {
                            idx -%= 1;
                            if (strtab[idx] == '.' and (byte < '0' or byte > '9')) {
                                mat.name.short_idx = @intCast(idx);
                                break;
                            }
                        }
                        idx = len;
                        idx -%= 1;
                        while (idx != 0) {
                            idx -%= 1;
                            if (strtab[idx] == '_' and strtab[idx +% 1] == '_') {
                                mat.name.mangle_idx = @intCast(idx);
                                break;
                            }
                        }
                    }
                    return strtab[0..mat.name.len :0];
                }
            };
            const NameIndices = packed struct(usize) {
                /// Null-terminator position.
                len: u16 = 0,
                /// Mangled name start position.
                mangle_idx: u16 = 0,
                /// Short name start position.
                short_idx: u16 = 0,
                /// Generic end position.
                cparen_idx: u16 = 0,
                fn space(name_idx: NameIndices, name: [:0]u8) []u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    return name[0..name_idx.short_idx];
                }
                fn mangler(name_idx: NameIndices, name: [:0]u8) []u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    var end: usize = name_idx.mangle_idx;
                    while (fmt.ascii.isWord(name[end])) {
                        end +%= 1;
                    }
                    return name[name_idx.mangle_idx..end];
                }
                fn mangled(name_idx: NameIndices, name: [:0]u8) [:0]u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    return name[name_idx.short_idx +% @intFromBool(name_idx.short_idx != 0) ..];
                }
                fn short(name_idx: NameIndices, name: [:0]u8) []u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    if (name_idx.mangle_idx > name_idx.short_idx) {
                        return name[name_idx.short_idx +% @intFromBool(name_idx.short_idx != 0) .. name_idx.mangle_idx];
                    } else {
                        return name[name_idx.short_idx +% @intFromBool(name_idx.short_idx != 0) ..];
                    }
                }
            };
            const Sort = struct {
                fn sortSymbolShIndex(sym1: Elf64_Sym, sym2: Elf64_Sym) bool {
                    return sym1.shndx > sym2.shndx;
                }
                fn sortSymbolSize(sym1: Elf64_Sym_Idx, sym2: Elf64_Sym_Idx) bool {
                    return sym1.size < sym2.size;
                }
                fn sortSymbolAddr(sym1: Elf64_Sym, sym2: Elf64_Sym) bool {
                    return sym1.value < sym2.value;
                }
                fn inPlace(st_shdr: *Elf64_Shdr, start: usize, finish: usize, cmp: *const fn (Elf64_Sym, Elf64_Sym) bool) void {
                    @setRuntimeSafety(builtin.is_safe);
                    if (loader_spec.options.sort) {
                        if (st_shdr.entsize == @sizeOf(Elf64_Sym)) {
                            const symtab: [*]Elf64_Sym = @ptrFromInt(st_shdr.addr);
                            algo.shellSort(Elf64_Sym, cmp, symtab[start..finish]);
                        }
                    }
                }
            };
            fn filterSymbolsHalf(
                sym: *const Elf64_Sym_Idx,
                mat: Match,
                sizes: *Sizes,
            ) bool {
                if (mat.flags.is_insignificant) {
                    if (!loader_spec.logging.show_insignificant and
                        mat.tag == .identical)
                    {
                        sizes.common +%= sym.size;
                        return true;
                    }
                    if (!loader_spec.logging.show_insignificant_additions and
                        mat.tag == .addition)
                    {
                        sizes.additions +%= sym.size;
                        return true;
                    }
                    if (!loader_spec.logging.show_insignificant_deletions and
                        mat.tag == .deletion)
                    {
                        sizes.deletions +%= sym.size;
                        return true;
                    }
                }
                if (!loader_spec.logging.show_mangled_symbols and
                    mat.isMangled())
                {
                    sizes.common +%= sym.size;
                    return true;
                }
                if (!loader_spec.logging.show_anonymous_symbols and
                    mat.isAnonymous())
                {
                    sizes.common +%= sym.size;
                    return true;
                }
                return false;
            }
            fn filterSymbolsFull(
                sym1: *const Elf64_Sym_Idx,
                mat1: Match,
                sym2: *const Elf64_Sym_Idx,
                mat2: Match,
                sizes: *Sizes,
            ) bool {
                if (!loader_spec.logging.show_unchanged_symbols and
                    mat2.tag == .identical)
                {
                    sizes.common +%= builtin.diff(usize, sym1.size, sym2.size);
                    return true;
                }
                if (mat2.flags.is_insignificant and
                    mat1.flags.is_insignificant)
                {
                    if (!loader_spec.logging.show_insignificant_additions and
                        mat2.tag == .addition)
                    {
                        sizes.additions +%= builtin.diff(usize, sym1.size, sym2.size);
                        return true;
                    }
                    if (!loader_spec.logging.show_insignificant_deletions and
                        mat2.tag == .deletion)
                    {
                        sizes.deletions +%= builtin.diff(usize, sym1.size, sym2.size);
                        return true;
                    }
                    if (!loader_spec.logging.show_insignificant_increases and
                        mat2.tag == .increase)
                    {
                        sizes.increases +%= builtin.diff(usize, sym1.size, sym2.size);
                        return true;
                    }
                    if (!loader_spec.logging.show_insignificant_decreases and
                        mat2.tag == .decrease)
                    {
                        sizes.decreases +%= builtin.diff(usize, sym1.size, sym2.size);
                        return true;
                    }
                }
                if (!loader_spec.logging.show_mangled_symbols and
                    mat2.isMangled())
                {
                    sizes.common +%= builtin.diff(usize, sym1.size, sym2.size);
                    return true;
                }
                if (!loader_spec.logging.show_anonymous_symbols and
                    mat2.isAnonymous())
                {
                    sizes.common +%= builtin.diff(usize, sym1.size, sym2.size);
                    return true;
                }
                return false;
            }
            fn symbolName(
                ei: *const ElfInfo,
                shdr: *const Elf64_Shdr,
                sym: *const Elf64_Sym_Idx,
                mat: *Match,
            ) ?[:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (shdr.link != 0) {
                    return mat.matchName(@ptrFromInt(@intFromPtr(ei.ehdr) +% ei.ehdr.sectionHeader(shdr.link).offset +% sym.name));
                }
                return null;
            }
            fn compareSizes(sym1: *Elf64_Sym_Idx, sym2: *Elf64_Sym_Idx, min_size_diff: *usize) bool {
                @setRuntimeSafety(builtin.is_safe);
                const size_diff: usize =
                    @max(sym1.size, sym2.size) -%
                    @min(sym1.size, sym2.size);
                const ret: bool = size_diff < min_size_diff.*;
                if (ret) {
                    min_size_diff.* = size_diff;
                }
                return ret;
            }
            pub fn compareElfInfo(
                cmp: *Cmp,
                allocator: *mem.SimpleAllocator,
                ei1: *ElfInfo,
                ei2: *ElfInfo,
                width1: usize,
            ) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (ei1.bestSymbolTable()) |st_shdr1| {
                    cmp.syms1 = sortSymtab(allocator, ei1, st_shdr1);
                }
                if (ei2.bestSymbolTable()) |st_shdr2| {
                    cmp.syms2 = sortSymtab(allocator, ei2, st_shdr2);
                }
                cmp.mats1 = @ptrFromInt(allocator.allocateRaw(ei1.ehdr.shnum * @sizeOf(Cmp.Matches), @alignOf(Cmp.Matches)));
                @memset(cmp.mats1[0..ei1.ehdr.shnum], .{});
                cmp.mats2 = @ptrFromInt(allocator.allocateRaw(ei2.ehdr.shnum * @sizeOf(Cmp.Matches), @alignOf(Cmp.Matches)));
                @memset(cmp.mats2[0..ei2.ehdr.shnum], .{});
                cmp.sizes = @ptrFromInt(allocator.allocateRaw(@max(ei1.ehdr.shnum, ei2.ehdr.shnum) * @sizeOf(Cmp.SizeDiff), @alignOf(Cmp.SizeDiff)));
                @memset(cmp.sizes[0..@max(ei1.ehdr.shnum, ei2.ehdr.shnum)], .{});
                if (cmp.syms1) |symtab1| {
                    for (cmp.mats1[1..ei1.ehdr.shnum], 1..) |*sect_mat1, shndx1| {
                        const mats1: [*]Match = @ptrFromInt(allocator.allocateRaw(symtab1[shndx1].len * @sizeOf(Match), @alignOf(Match)));
                        sect_mat1.mats = mats1[0..symtab1[shndx1].len];
                        @memset(sect_mat1.mats, .{});
                    }
                }
                if (cmp.syms2) |symtab2| {
                    for (cmp.mats2[1..ei2.ehdr.shnum], 1..) |*sect_mat2, shndx2| {
                        const mats2: [*]Match = @ptrFromInt(allocator.allocateRaw(symtab2[shndx2].len * @sizeOf(Match), @alignOf(Match)));
                        sect_mat2.mats = mats2[0..symtab2[shndx2].len];
                        @memset(sect_mat2.mats, .{});
                    }
                }
                var len: usize = 0;
                for (cmp.mats2[1..ei2.ehdr.shnum], 1..) |*sect_mat2, shndx2| {
                    const shdr2: *Elf64_Shdr = ei2.ehdr.sectionHeader(shndx2);
                    const sh_name2: [:0]const u8 = ei2.ehdr.sectionName(shndx2);
                    const width2: usize = sh_name2.len;
                    var shndx1: usize = 1;
                    while (shndx1 != ei1.ehdr.shnum) : (shndx1 +%= 1) {
                        if (mem.testEqualString(sh_name2, ei1.ehdr.sectionName(shndx1))) {
                            break;
                        }
                    } else {
                        len +%= about.lengthSection2(ei2, shdr2.addr, shdr2.offset, 0, shdr2.size, shndx2, width1);
                        continue;
                    }
                    const sect_mat1: *Match = &cmp.mats1[shndx1].mat;
                    sect_mat1.idx = @intCast(shndx2);
                    sect_mat1.tag = .matched;
                    sect_mat2.mat.idx = @intCast(shndx1);
                    sect_mat2.mat.tag = .matched;
                    const shdr1: *Elf64_Shdr = ei1.ehdr.sectionHeader(shndx1);
                    len +%= about.lengthSection2(ei2, shdr2.addr, shdr2.offset, shdr1.size, shdr2.size, shndx2, width1);
                    if (ei1.bestSymbolTable()) |symtab_shdr1| {
                        if (ei2.bestSymbolTable()) |symtab_shdr2| {
                            lo: for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2], 0..) |*mat2, *sym2, sym_idx2| {
                                cmp.sizes[shndx2].sizes_r1.new +%= sym2.size;
                                const name2: [:0]u8 = symbolName(ei2, symtab_shdr2, sym2, mat2) orelse {
                                    continue;
                                };
                                if (mat2.isMangled() or mat2.isAnonymous()) {
                                    mat2.tag = .unmatched;
                                    continue;
                                }
                                for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1], 0..) |*mat1, *sym1, sym_idx1| {
                                    if (mat1.idx != Match.no_idx) {
                                        continue;
                                    }
                                    const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1) orelse {
                                        continue;
                                    };
                                    if (mem.testEqualString(name1, name2)) {
                                        mat2.tag = .matched;
                                        mat2.idx = @intCast(sym_idx1);
                                        mat1.tag = .matched;
                                        mat1.idx = @intCast(sym_idx2);
                                        continue :lo;
                                    }
                                }
                                mat2.tag = .addition;
                            }
                            for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1], 0..) |*mat1, *sym1, sym_idx1| {
                                cmp.sizes[shndx2].sizes_r1.old +%= sym1.size;
                                if (mat1.idx != Match.no_idx) {
                                    continue;
                                }
                                const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1) orelse {
                                    continue;
                                };
                                if (!loader_spec.logging.show_anonymous_symbols and
                                    mat1.isAnonymous())
                                {
                                    continue;
                                }
                                var diff: usize = ~@as(usize, 0);
                                if (mat1.isMangled()) {
                                    for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2], 0..) |*mat2, *sym2, sym_idx2| {
                                        if (mat2.idx != Match.no_idx) {
                                            continue;
                                        }
                                        const name2: [:0]u8 = symbolName(ei2, symtab_shdr2, sym2, mat2) orelse {
                                            continue;
                                        };
                                        if (mem.testEqualString(mat1.name.short(name1), mat2.name.short(name2)) and
                                            mem.testEqualString(mat1.name.space(name1), mat2.name.space(name2)))
                                        {
                                            if (mem.testEqualString(ei1.symbolBytes(sym1), ei2.symbolBytes(sym2))) {
                                                mat1.tag = .matched;
                                                mat1.idx = @intCast(sym_idx2);
                                                mat2.tag = .matched;
                                                mat2.idx = @intCast(sym_idx1);
                                                break;
                                            }
                                            if (compareSizes(sym1, sym2, &diff)) {
                                                mat1.tag = .matched;
                                                mat1.idx = @intCast(sym_idx2);
                                            }
                                        }
                                    }
                                }
                                if (mat1.tag == .matched) {
                                    cmp.mats2[shndx2].mats[mat1.idx].tag = .matched;
                                    cmp.mats2[shndx2].mats[mat1.idx].idx = @intCast(sym_idx1);
                                } else {
                                    mat1.idx = Match.no_idx;
                                    mat1.tag = .deletion;
                                }
                            }
                            for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2]) |*mat2, *sym2| {
                                if (mat2.idx == Match.no_idx) {
                                    if (mat2.tag == .unmatched and mat2.isMangled()) {
                                        mat2.tag = .addition;
                                    }
                                    if (!loader_spec.logging.show_anonymous_symbols and
                                        mat2.isAnonymous())
                                    {
                                        continue;
                                    }
                                    cmp.sizes[shndx2].sizes_r1.additions +%= sym2.size;
                                } else {
                                    const sym1: *Elf64_Sym_Idx = &cmp.syms1.?[shndx1][mat2.idx];
                                    if (sym2.size < sym1.size) {
                                        cmp.sizes[shndx2].sizes_r1.decreases +%= sym1.size -% sym2.size;
                                        mat2.tag = .decrease;
                                    } else if (sym2.size > sym1.size) {
                                        cmp.sizes[shndx2].sizes_r1.increases +%= sym2.size -% sym1.size;
                                        mat2.tag = .increase;
                                    } else {
                                        mat2.tag = .identical;
                                    }
                                    cmp.mats1[shndx1].mats[mat2.idx].tag = mat2.tag;
                                }
                            }
                            for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1]) |*mat1, *sym1| {
                                if (mat1.tag == .deletion) {
                                    cmp.sizes[shndx2].sizes_r1.deletions +%= sym1.size;
                                }
                            }
                            for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1]) |*mat1, *sym1| {
                                mat1.flags.is_insignificant = switch (mat1.tag) {
                                    else => sym1.size *% 100 < cmp.sizes[shndx2].sizes_r1.new,
                                    .increase => (sym1.size -% cmp.syms2.?[shndx2][mat1.idx].size) *% 100 < cmp.sizes[shndx2].sizes_r1.increases,
                                    .decrease => (cmp.syms2.?[shndx2][mat1.idx].size -% sym1.size) *% 100 < cmp.sizes[shndx2].sizes_r1.decreases,
                                    .deletion => (sym1.size *% 100) < cmp.sizes[shndx2].sizes_r1.deletions,
                                };
                            }
                            for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2]) |*mat2, *sym2| {
                                mat2.flags.is_insignificant = switch (mat2.tag) {
                                    else => sym2.size *% 100 < cmp.sizes[shndx2].sizes_r1.new,
                                    .increase => (sym2.size -% cmp.syms1.?[shndx1][mat2.idx].size) *% 100 < cmp.sizes[shndx2].sizes_r1.increases,
                                    .decrease => (cmp.syms1.?[shndx1][mat2.idx].size -% sym2.size) *% 100 < cmp.sizes[shndx2].sizes_r1.decreases,
                                    .addition => (sym2.size *% 100) < cmp.sizes[shndx2].sizes_r1.deletions,
                                };
                            }
                            for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2]) |*mat2, *sym2| {
                                const name2: [:0]u8 = symbolName(ei2, symtab_shdr2, sym2, mat2).?;
                                if (mat2.idx == Match.no_idx) {
                                    if (filterSymbolsHalf(sym2, mat2.*, &cmp.sizes[shndx2].sizes_r2)) {
                                        mat2.flags.is_hidden = true;
                                        continue;
                                    }
                                    if (loader_spec.options.write_symbols) {
                                        len +%= about.lengthSymbolIntro(sym2.index, mat2.tag, width2);
                                        len +%= about.lengthSymbol(sym2, mat2.*, name2, &cmp.sizes[shndx2].sizes_r1);
                                    }
                                } else {
                                    const mat1: *Match = &cmp.mats1[shndx1].mats[mat2.idx];
                                    const sym1: *Elf64_Sym_Idx = &cmp.syms1.?[shndx1][mat2.idx];
                                    if (filterSymbolsFull(sym1, mat1.*, sym2, mat2.*, &cmp.sizes[shndx2].sizes_r2)) {
                                        mat1.flags.is_hidden = true;
                                        continue;
                                    }
                                    const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1).?;
                                    if (loader_spec.options.write_symbols) {
                                        len +%= about.lengthSymbolIntro(sym2.index, mat2.tag, width2);
                                        len +%= about.lengthSymbolDifference(sym1, mat1.*, name1, &cmp.sizes[shndx2].sizes_r1, sym2, mat2.*, name2);
                                    }
                                }
                            }
                            for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1]) |*mat1, *sym1| {
                                if (mat1.idx != Match.no_idx) {
                                    continue;
                                }
                                if (filterSymbolsHalf(sym1, mat1.*, &cmp.sizes[shndx2].sizes_r2)) {
                                    mat1.flags.is_hidden = true;
                                    continue;
                                }
                                const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1).?;
                                if (loader_spec.options.write_symbols) {
                                    len +%= about.lengthSymbolIntro(sym1.index, mat1.tag, width2);
                                    len +%= about.lengthSymbol(sym1, mat1.*, name1, &cmp.sizes[shndx2].sizes_r1);
                                }
                            }
                            if (!cmp.sizes[shndx2].sizes_r2.isZero()) {
                                len +%= about.lengthExcluded(width2, &cmp.sizes[shndx2].sizes_r2);
                            }
                        }
                    }
                }
                for (cmp.mats1[1..ei1.ehdr.shnum], 1..) |*mat1, shndx1| {
                    const shdr1: *Elf64_Shdr = ei1.ehdr.sectionHeader(shndx1);
                    if (mat1.mat.tag == .unknown) {
                        mat1.mat.tag = .deletion;
                        len +%= about.lengthSection2(ei1, shdr1.addr, shdr1.offset, shdr1.size, 0, shndx1, width1);
                    }
                }
                return len;
            }
            pub fn lengthElf(
                cmp: *Cmp,
                allocator: *mem.SimpleAllocator,
                ei: *ElfInfo,
                width1: usize,
            ) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (ei.bestSymbolTable()) |st_shdr| {
                    cmp.syms2 = sortSymtab(allocator, ei, st_shdr);
                }
                cmp.mats2 = @ptrFromInt(allocator.allocateRaw(ei.ehdr.shnum * @sizeOf(Cmp.Matches), @alignOf(Cmp.Matches)));
                @memset(cmp.mats2[0..ei.ehdr.shnum], .{ .mat = .{ .tag = .identical } });
                cmp.sizes = @ptrFromInt(allocator.allocateRaw(ei.ehdr.shnum * @sizeOf(Cmp.SizeDiff), @alignOf(Cmp.SizeDiff)));
                @memset(cmp.sizes[0..ei.ehdr.shnum], .{});
                if (cmp.syms2) |symtab2| {
                    for (cmp.mats2[1..ei.ehdr.shnum], 1..) |*sect_mat2, shndx2| {
                        const mats2: [*]Match = @ptrFromInt(allocator.allocateRaw(symtab2[shndx2].len * @sizeOf(Match), @alignOf(Match)));
                        sect_mat2.mats = mats2[0..symtab2[shndx2].len];
                        @memset(sect_mat2.mats, .{ .tag = .identical });
                    }
                }
                var len: usize = 0;
                for (1..ei.ehdr.shnum) |shndx| {
                    const shdr: *Elf64_Shdr = ei.ehdr.sectionHeader(shndx);
                    const width2: usize = ei.ehdr.sectionName(shndx).len;
                    len +%= about.lengthSection(ei, shdr.addr, shdr.offset, shdr.size, shndx, width1);
                    if (ei.bestSymbolTable()) |symtab_shdr2| {
                        if (cmp.syms2.?[shndx].len == 0) {
                            continue;
                        }
                        for (cmp.syms2.?[shndx]) |*sym2| {
                            cmp.sizes[shndx].sizes_r1.new +%= sym2.size;
                        }
                        for (cmp.mats2[shndx].mats, cmp.syms2.?[shndx]) |*mat2, *sym2| {
                            mat2.flags.is_insignificant = sym2.size *% 100 < cmp.sizes[shndx].sizes_r1.new;
                        }
                        for (cmp.mats2[shndx].mats, cmp.syms2.?[shndx]) |*mat2, *sym2| {
                            const name2: [:0]u8 = symbolName(ei, symtab_shdr2, sym2, mat2).?;
                            if (!loader_spec.logging.show_anonymous_symbols and
                                mat2.isAnonymous())
                            {
                                mat2.flags.is_hidden = true;
                                continue;
                            }
                            if (filterSymbolsHalf(sym2, mat2.*, &cmp.sizes[shndx].sizes_r2)) {
                                mat2.flags.is_hidden = true;
                                continue;
                            }
                            if (loader_spec.options.write_symbols) {
                                len +%= about.lengthSymbolIntro(sym2.index, mat2.tag, width2);
                                len +%= about.lengthSymbol(sym2, mat2.*, name2, &cmp.sizes[shndx].sizes_r1);
                            }
                        }
                        len +%= about.lengthExcluded(width2, &cmp.sizes[shndx].sizes_r2);
                    }
                }
                return len;
            }
            pub fn writeElf(
                cmp: *const Cmp,
                buf: [*]u8,
                ei: *const ElfInfo,
                width1: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                for (1..ei.ehdr.shnum) |shndx| {
                    const shdr: *Elf64_Shdr = ei.ehdr.sectionHeader(shndx);
                    const width2: usize = ei.ehdr.sectionName(shndx).len;
                    ptr = about.writeSection2(ptr, ei, shdr, shndx, width1);
                    if (ei.bestSymbolTable()) |symtab_shdr| {
                        if (cmp.syms2.?[shndx].len == 0) {
                            continue;
                        }
                        for (cmp.mats2[shndx].mats, cmp.syms2.?[shndx]) |*mat, *sym| {
                            const name: [:0]u8 = symbolName(ei, symtab_shdr, sym, mat).?;
                            if (mat.flags.is_hidden) {
                                continue;
                            }
                            if (loader_spec.options.write_symbols) {
                                ptr = about.writeSymbolIntro(ptr, sym.index, mat.tag, width1, width2);
                                ptr = about.writeSymbol(ptr, sym, mat.*, name, &cmp.sizes[shndx].sizes_r1);
                            }
                        }
                        ptr = about.writeExcluded(ptr, width1, width2, &cmp.sizes[shndx].sizes_r2);
                    }
                }
                return ptr;
            }
            pub fn writeElfDifferences(
                cmp: *const Cmp,
                buf: [*]u8,
                ei1: *const ElfInfo,
                ei2: *const ElfInfo,
                width1: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                for (cmp.mats2[1..ei2.ehdr.shnum], 1..) |*sect_mat2, shndx2| {
                    const shdr2: *Elf64_Shdr = ei2.ehdr.sectionHeader(shndx2);
                    const shndx1: usize = sect_mat2.mat.idx;
                    const width2: usize = ei2.ehdr.sectionName(shndx2).len;
                    if (shndx1 == Match.no_idx) {
                        ptr = about.writeSectionAdded(ptr, ei2, shdr2, shndx2, width1);
                        continue;
                    }
                    const shdr1: *Elf64_Shdr = ei1.ehdr.sectionHeader(shndx1);
                    ptr = about.writeSectionDifference2(ptr, ei2, shdr1, shdr2, shndx2, width1);
                    if (ei1.bestSymbolTable()) |symtab_shdr1| {
                        if (ei2.bestSymbolTable()) |symtab_shdr2| {
                            for (cmp.mats2[shndx2].mats, cmp.syms2.?[shndx2]) |*mat2, *sym2| {
                                const name2: [:0]u8 = symbolName(ei2, symtab_shdr2, sym2, mat2).?;
                                if (mat2.idx == Match.no_idx) {
                                    if (mat2.flags.is_hidden) {
                                        continue;
                                    }
                                    if (loader_spec.options.write_symbols) {
                                        ptr = about.writeSymbolIntro(ptr, sym2.index, mat2.tag, width1, width2);
                                        ptr = about.writeSymbol(ptr, sym2, mat2.*, name2, &cmp.sizes[shndx2].sizes_r1);
                                    }
                                    if (loader_spec.options.print_final_summary2) {
                                        if (mat2.isMangled()) {
                                            testing.printBufN(4096, .{
                                                .tag = mat2.tag,
                                                .flags = mat2.flags,
                                                .space = mat2.name.space(name2),
                                                .short = mat2.name.short(name2),
                                                .mangler = mat2.name.mangler(name2),
                                            });
                                        } else {
                                            testing.printBufN(4096, .{
                                                .tag = mat2.tag,
                                                .flags = mat2.flags,
                                                .space = mat2.name.space(name2),
                                                .short = mat2.name.short(name2),
                                            });
                                        }
                                    }
                                } else {
                                    const mat1: *Match = &cmp.mats1[shndx1].mats[mat2.idx];
                                    const sym1: *const Elf64_Sym_Idx = &cmp.syms1.?[shndx1][mat2.idx];
                                    if (mat1.flags.is_hidden) {
                                        continue;
                                    }
                                    const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1).?;
                                    if (loader_spec.options.write_symbols) {
                                        ptr = about.writeSymbolIntro(ptr, sym2.index, mat2.tag, width1, width2);
                                        ptr = about.writeSymbolDifference(ptr, sym1, mat1.*, name1, &cmp.sizes[shndx2].sizes_r1, sym2, mat2.*, name2);
                                    }
                                    if (loader_spec.options.print_final_summary2) {
                                        if (mat2.isMangled()) {
                                            testing.printBufN(4096, .{
                                                .tag1 = mat1.tag,
                                                .flags1 = mat1.flags,
                                                .space1 = mat1.name.space(name1),
                                                .short1 = mat1.name.short(name1),
                                                .mangler1 = mat1.name.mangler(name1),
                                                .tag2 = mat2.tag,
                                                .flags2 = mat2.flags,
                                                .space2 = mat2.name.space(name2),
                                                .short2 = mat2.name.short(name2),
                                                .mangler2 = mat2.name.mangler(name2),
                                            });
                                        } else {
                                            testing.printBufN(4096, .{
                                                .tag1 = mat1.tag,
                                                .flags1 = mat1.flags,
                                                .space1 = mat1.name.space(name1),
                                                .short1 = mat1.name.short(name1),
                                                .tag2 = mat2.tag,
                                                .flags2 = mat2.flags,
                                                .space2 = mat2.name.space(name2),
                                                .short2 = mat2.name.short(name2),
                                            });
                                        }
                                    }
                                }
                            }
                            for (cmp.mats1[shndx1].mats, cmp.syms1.?[shndx1]) |*mat1, *sym1| {
                                if (mat1.flags.is_hidden) {
                                    continue;
                                }
                                if (mat1.idx != Match.no_idx) {
                                    continue;
                                }
                                const name1: [:0]u8 = symbolName(ei1, symtab_shdr1, sym1, mat1).?;
                                if (loader_spec.options.write_symbols) {
                                    ptr = about.writeSymbolIntro(ptr, sym1.index, mat1.tag, width1, width2);
                                    ptr = about.writeSymbol(ptr, sym1, mat1.*, name1, &cmp.sizes[shndx2].sizes_r1);
                                }
                                if (loader_spec.options.print_final_summary2) {
                                    if (mat1.isMangled()) {
                                        testing.printBufN(4096, .{
                                            .tag = mat1.tag,
                                            .flags = mat1.flags,
                                            .space = mat1.name.space(name1),
                                            .short = mat1.name.short(name1),
                                            .mangler = mat1.name.mangler(name1),
                                        });
                                    } else {
                                        testing.printBufN(4096, .{
                                            .tag = mat1.tag,
                                            .flags = mat1.flags,
                                            .space = mat1.name.space(name1),
                                            .short = mat1.name.short(name1),
                                        });
                                    }
                                }
                            }
                            if (!cmp.sizes[shndx2].sizes_r2.isZero()) {
                                ptr = about.writeExcluded(ptr, width1, width2, &cmp.sizes[shndx2].sizes_r2);
                            }
                        }
                    }
                }
                for (cmp.mats1[1..ei1.ehdr.shnum], 1..) |*mat1, shndx1| {
                    const shdr1: *Elf64_Shdr = ei1.ehdr.sectionHeader(shndx1);
                    if (mat1.mat.tag == .unmatched) {
                        ptr = about.writeSectionRemoved(ptr, ei1, shdr1, shndx1, width1);
                    }
                }
                return ptr;
            }
        };
        pub const about = struct {
            fn aboutReadMetadataSection(name: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..about.meta_s.len].* = about.meta_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[24..], name);
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
            }
            fn unknownSectionFault(name: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..24].* = "unknown section header: ".*;
                proc.exitFault(buf[0 .. @intFromPtr(fmt.strcpyEqu(buf[24..], name)) -% @intFromPtr(&buf)], 2);
            }
            fn unsupportedRelocationFault(tag_name: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..24].* = "unsupported relocation: ".*;
                proc.exitFault(buf[0 .. @intFromPtr(fmt.strcpyEqu(buf[24..], tag_name)) -% @intFromPtr(&buf)], 2);
            }
            fn aboutRelocation(rela: *Elf64_Rela) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..reloc_s.len].* = reloc_s.*;
                var ptr: [*]u8 = buf[reloc_s.len..];
                ptr[0..7].* = "offset=".*;
                ptr = fmt.Ud64.write(ptr + 7, rela.r_offset);
                ptr[0..7].* = ", type=".*;
                ptr = fmt.strcpyEqu(ptr + 7, @tagName(rela.info.type));
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (rela.info.sym != 0) {
                    ptr[0..4].* = "sym=".*;
                    ptr = fmt.Ud64.write(ptr + 4, rela.info.sym);
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                    ptr[0..5].* = "name=".*;
                    ptr += 5;
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                }
                ptr[0..7].* = "addend=".*;
                ptr = fmt.writeId64(ptr + 7, rela.r_addend);
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
            }
            const load_s = fmt.about("load");
            const reloc_s = fmt.about("reloc");
            fn aboutLoad(info: *const ElfInfo, pathname: [:0]const u8) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                buf[0..load_s.len].* = load_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[load_s.len..], "ELF-");
                ptr = fmt.strcpyEqu(ptr, @tagName(info.ehdr.type));
                ptr[0..2].* = ", ".*;
                ptr = fmt.strcpyEqu(ptr + 2, @tagName(info.ehdr.machine));
                ptr[0..11].* = ", sections=".*;
                ptr = fmt.Ud64.write(ptr + 11, info.ehdr.shnum);
                ptr[0..11].* = ", segments=".*;
                ptr = fmt.Ud64.write(ptr + 11, info.ehdr.phnum);
                if (info.ehdr.type == .DYN) {
                    ptr[0..7].* = ", addr=".*;
                    ptr = fmt.Ux64.write(ptr + 7, info.prog.addr);
                }
                var pos: usize = 0;
                for (pathname, 0..) |byte, idx| {
                    if (byte == '/') pos = idx;
                }
                ptr[0..7].* = ", name=".*;
                ptr = fmt.strcpyEqu(ptr + 7, pathname[pos +% 1 ..]);
                ptr[0] = '\n';
                debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
            }
            fn lengthPercentage(sym: *const Elf64_Sym_Idx, mat: compare.Match, sizes: *const compare.Sizes) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = 0;
                if (sym.size * 200 < (sizes.new +% sizes.old) or
                    mat.flags.is_insignificant)
                {
                    return len;
                }
                const result: usize = (sym.size *% 100000) / switch (mat.tag) {
                    .deletion, .decrease => @max(sizes.old, 1),
                    .addition, .increase => @max(sizes.new, 1),
                    else => @max(sizes.new, 1),
                };
                len += fmt.Ud64.length(((result / 1000) *% 1000) / 1000) +% 7;
                return len;
            }
            fn writePercentage(buf: [*]u8, sym: *const Elf64_Sym_Idx, mat: compare.Match, sizes: *const compare.Sizes) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (sym.size * 200 < (sizes.new +% sizes.old) or
                    mat.flags.is_insignificant)
                {
                    return buf;
                }
                const result: usize = (sym.size *% 100000) / switch (mat.tag) {
                    .deletion, .decrease => @max(sizes.old, 1),
                    .addition, .increase => @max(sizes.new, 1),
                    else => @max(sizes.new, 1),
                };
                const sig: usize = (result / 1000) *% 1000;
                const exp: usize = result - sig;
                var ptr: [*]u8 = fmt.Ud64.write(buf, sig / 1000);
                ptr[0..4].* = ".000".*;
                ptr += 1;
                const figs: usize = fmt.sigFigLen(usize, exp, 10);
                ptr += 3 -% figs;
                _ = fmt.Ud64.write(ptr, exp);
                ptr += (figs -% 3);
                ptr += 3;
                ptr[0..3].* = "%, ".*;
                ptr += 3;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthPercentage, .{ sym, mat, sizes });
                }
                return ptr;
            }
            fn writeSection2(
                buf: [*]u8,
                ei: *const ElfInfo,
                shdr: *Elf64_Shdr,
                shndx: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarIndexFormat.write(buf, width, shndx);
                ptr = fmt.strcpyEqu(ptr, ei.ehdr.sectionName(shndx));
                ptr[0..2].* = ": ".*;
                ptr = writeAddressOrOffset(ptr + 2, shdr.addr, shdr.offset);
                ptr[0..5].* = "size=".*;
                ptr = fmt.Bytes.write(ptr + 5, shdr.size);
                ptr[0] = '\n';
                ptr += 1;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthSection, .{ ei, shdr.addr, shdr.size, shndx, width });
                }
                return ptr;
            }
            fn lengthSection(
                ei: *const ElfInfo,
                addr: usize,
                offset: usize,
                size: usize,
                shndx: usize,
                width: usize,
            ) usize {
                return fmt.SideBarIndexFormat.length(width, shndx) +%
                    ei.ehdr.sectionName(shndx).len +% lengthAddressOrOffset(addr, offset) +% fmt.Bytes.length(size) +% 8;
            }
            fn lengthSection2(
                ei: *const ElfInfo,
                addr: usize,
                offset: usize,
                old_size: usize,
                new_size: usize,
                shndx: usize,
                width: usize,
            ) usize {
                return fmt.SideBarIndexFormat.length(width, shndx) +%
                    ei.ehdr.sectionName(shndx).len +%
                    lengthAddressOrOffset(addr, offset) +%
                    lengthSizeCmp(old_size, new_size) +% 3;
            }
            fn writeSectionAdded(
                buf: [*]u8,
                ei2: *const ElfInfo,
                shdr2: *Elf64_Shdr,
                shndx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarIndexFormat.write(buf, width, shndx2);
                ptr = fmt.strcpyEqu(ptr, ei2.ehdr.sectionName(shndx2));
                ptr[0..2].* = ": ".*;
                ptr = writeAddressOrOffset(ptr + 2, shdr2.addr, shdr2.offset);
                ptr = writeSizeCmp(ptr, 0, shdr2.size);
                ptr[0] = '\n';
                if (loader_spec.options.verify_lengths) {
                    verify(ptr + 1, buf, lengthSection2, .{ ei2, shdr2.addr, 0, shdr2.size, shndx2, width });
                }
                return ptr + 1;
            }
            fn writeSectionRemoved(
                buf: [*]u8,
                ei1: *const ElfInfo,
                shdr1: *const Elf64_Shdr,
                shndx1: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarIndexFormat.write(buf, width, shndx1);
                ptr = fmt.strcpyEqu(ptr, ei1.ehdr.sectionName(shndx1));
                ptr[0..2].* = ": ".*;
                ptr = writeAddressOrOffset(ptr + 2, shdr1.addr, shdr1.offset);
                ptr = writeSizeCmp(ptr, shdr1.size, 0);
                ptr[0] = '\n';
                if (loader_spec.options.verify_lengths) {
                    verify(ptr + 1, buf, lengthSection2, .{ ei1, shdr1.addr, shdr1.size, 0, shndx1, width });
                }
                return ptr + 1;
            }
            fn writeSectionDifference2(
                buf: [*]u8,
                ei2: *const ElfInfo,
                shdr1: *const Elf64_Shdr,
                shdr2: *const Elf64_Shdr,
                shndx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.SideBarIndexFormat.write(buf, width, shndx2);
                ptr = fmt.strcpyEqu(ptr, ei2.ehdr.sectionName(shndx2));
                ptr[0..2].* = ": ".*;
                ptr = writeAddressOrOffset(ptr + 2, shdr2.addr, shdr2.offset);
                ptr = writeSizeCmp(ptr, shdr1.size, shdr2.size);
                ptr[0] = '\n';
                if (loader_spec.options.verify_lengths) {
                    verify(ptr + 1, buf, lengthSection2, .{ ei2, shdr2.addr, shdr1.size, shdr2.size, shndx2, width });
                }
                return ptr + 1;
            }
            fn lengthAddressOrOffset(addr: usize, offset: usize) usize {
                if (addr == 0) {
                    return 9 +% fmt.Ux64.length(offset);
                } else {
                    return 7 +% fmt.Ux64.length(addr);
                }
            }
            fn writeAddressOrOffset(buf: [*]u8, addr: usize, offset: usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (addr == 0) {
                    ptr[0..7].* = "offset=".*;
                    ptr = fmt.Ux64.write(buf + 7, offset);
                } else {
                    ptr[0..5].* = "addr=".*;
                    ptr = fmt.Ux64.write(buf + 5, addr);
                }
                ptr[0..2].* = ", ".*;
                return ptr + 2;
            }
            fn lengthSizeCmp(old_size: usize, new_size: usize) usize {
                return 5 +% fmt.BloatDiff.length(old_size, new_size);
            }
            fn writeSizeCmp(buf: [*]u8, old_size: usize, new_size: usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                buf[0..5].* = "size=".*;
                return fmt.BloatDiff.write(buf + 5, old_size, new_size);
            }
            fn lengthSymbolGeneric(style_s: []const u8, width2: usize) usize {
                return style_s.len +% builtin.message_indent +% width2 +% 2 +% tab.fx.none.len;
            }
            fn writeSymbolGeneric(
                buf: [*]u8,
                style_s: []const u8,
                style_b: u8,
                width1: usize,
                width2: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.strsetEqu(buf, ' ', width1);
                ptr = fmt.strcpyEqu(ptr, style_s);
                ptr[0] = style_b;
                ptr[1..5].* = tab.fx.none;
                ptr = fmt.strsetEqu(ptr + 5, ' ', (builtin.message_indent +% (width2 -% width1)));
                ptr[0] = ' ';
                ptr += 1;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthSymbolGeneric, .{ style_s, width2 });
                }
                return ptr;
            }
            fn eventString(event: compare.Match.Tag) []const u8 {
                @setRuntimeSafety(builtin.is_safe);
                switch (event) {
                    .unknown => return "!",
                    .unmatched => return "?",
                    .increase => return tab.fx.color.fg.red ++ "+" ++ tab.fx.none,
                    .addition => return tab.fx.color.fg.red ++ "a" ++ tab.fx.none,
                    .decrease => return tab.fx.color.fg.green ++ "-" ++ tab.fx.none,
                    .deletion => return tab.fx.color.fg.green ++ "d" ++ tab.fx.none,
                    .matched => return tab.fx.color.fg.yellow ++ "~" ++ tab.fx.none,
                    .identical => return "=",
                }
            }
            fn lengthSymbolIntro(
                value: usize,
                event: compare.Match.Tag,
                width2: usize,
            ) usize {
                return eventString(event).len +% (builtin.message_indent +% width2) -%
                    (fmt.sigFigLen(usize, value, 10) +% 1) +%
                    tab.fx.style.faint.len +% fmt.Ud64.length(value) +%
                    tab.fx.none.len +% 2;
            }
            fn writeSymbolIntro(
                buf: [*]u8,
                value: usize,
                event: compare.Match.Tag,
                width1: usize,
                width2: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                @memset(buf[0..width1], ' ');
                var ptr: [*]u8 = fmt.strcpyEqu(buf + width1, eventString(event));
                @memset(ptr[0 .. builtin.message_indent +% width2], ' ');
                ptr += builtin.message_indent +% width2;
                ptr -= width1 +% fmt.sigFigLen(usize, value, 10) +% 1;
                ptr[0..4].* = tab.fx.style.faint;
                ptr = fmt.Ud64.write(ptr + 4, value);
                ptr[0..4].* = tab.fx.none;
                ptr[4..6].* = ": ".*;
                ptr += 6;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthSymbolIntro, .{ value, event, width2 });
                }
                return ptr;
            }
            fn lengthExcludedElement(styles_s: []const u8, bytes: usize, total: *usize) usize {
                var len: usize = 0;
                if (bytes != 0) {
                    if (total.* != 0) {
                        len +%= 2;
                    }
                    len +%= styles_s.len;
                    len +%= fmt.Bytes.length(bytes);
                    total.* +%= bytes;
                }
                return len;
            }
            fn writeExcludedElement(buf: [*]u8, styles_s: []const u8, bytes: usize, total: *usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (bytes != 0) {
                    if (total.* != 0) {
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                    }
                    ptr = fmt.strcpyEqu(ptr, styles_s);
                    ptr = fmt.Bytes.write(ptr, bytes);
                    total.* +%= bytes;
                }
                return ptr;
            }
            fn lengthExcluded(width2: usize, sizes_r2: *const compare.Sizes) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = lengthSymbolGeneric(&tab.fx.color.fg.magenta, width2);
                len +%= tab.fx.style.faint.len;
                var total: usize = 0;
                len +%= lengthExcludedElement(eventString(.addition), sizes_r2.additions, &total);
                len +%= lengthExcludedElement(eventString(.increase), sizes_r2.increases, &total);
                len +%= lengthExcludedElement(eventString(.deletion), sizes_r2.deletions, &total);
                len +%= lengthExcludedElement(eventString(.decrease), sizes_r2.decreases, &total);
                if (total == 0) {
                    return 0;
                }
                len +%= tab.fx.none.len +% 1;
                return len;
            }
            fn writeExcluded(buf: [*]u8, width1: usize, width2: usize, sizes_r2: *const compare.Sizes) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolGeneric(buf, &tab.fx.color.fg.magenta, '?', width1, width2);
                ptr[0..4].* = tab.fx.style.faint;
                var total: usize = 0;
                ptr = writeExcludedElement(ptr, eventString(.addition), sizes_r2.additions, &total);
                ptr = writeExcludedElement(ptr, eventString(.increase), sizes_r2.increases, &total);
                ptr = writeExcludedElement(ptr, eventString(.deletion), sizes_r2.deletions, &total);
                ptr = writeExcludedElement(ptr, eventString(.decrease), sizes_r2.decreases, &total);
                if (total == 0) {
                    return buf;
                }
                ptr[0..4].* = tab.fx.none;
                ptr += 4;
                ptr[0] = '\n';
                ptr += 1;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthExcluded, .{ width2, sizes_r2 });
                }
                return ptr;
            }
            fn lengthSymbol(sym: *const Elf64_Sym_Idx, mat: compare.Match, name: [:0]u8, sizes_r1: *const compare.Sizes) usize {
                return lengthAddressOrOffset(sym.value, 0) +% 13 +%
                    switch (mat.tag) {
                    .addition => fmt.BloatDiff.length(0, sym.size),
                    .deletion => fmt.BloatDiff.length(sym.size, 0),
                    else => fmt.Bytes.length(sym.size),
                } +% lengthPercentage(sym, mat, sizes_r1) +% lengthCompoundNameHalf(mat, name);
            }
            fn writeSymbol(buf: [*]u8, sym: *const Elf64_Sym_Idx, mat: compare.Match, name: [:0]u8, sizes_r1: *const compare.Sizes) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeAddressOrOffset(buf, sym.value, 0);
                ptr[0..5].* = "size=".*;
                ptr = switch (mat.tag) {
                    .addition => fmt.BloatDiff.write(ptr + 5, 0, sym.size),
                    .deletion => fmt.BloatDiff.write(ptr + 5, sym.size, 0),
                    else => fmt.Bytes.write(ptr + 5, sym.size),
                };
                ptr[0..2].* = ", ".*;
                ptr = writePercentage(ptr + 2, sym, mat, sizes_r1);
                ptr[0..5].* = "name=".*;
                ptr = writeCompoundNameHalf(ptr + 5, mat, name);
                ptr[0] = '\n';
                ptr += 1;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthSymbol, .{ sym, mat, name, sizes_r1 });
                }
                return ptr;
            }
            fn writeSymbolValue() [*]u8 {}
            fn lengthSymbolValue() usize {}
            fn writeSymbolValueDifference() void {}
            fn lengthChangedSymbolValueDifference() void {}
            fn lengthSymbolDifference(
                sym1: *const Elf64_Sym_Idx,
                mat1: compare.Match,
                name1: [:0]u8,
                sizes: *const compare.Sizes,
                sym2: *const Elf64_Sym_Idx,
                mat2: compare.Match,
                name2: [:0]u8,
            ) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = lengthAddressOrOffset(sym2.value, 0);
                len +%= 8 +% fmt.BloatDiff.length(sym1.size, sym2.size);
                len +%= lengthPercentage(sym2, mat2, sizes);
                len +%= lengthCompoundName(mat1, name1, mat2, name2);
                return len;
            }
            fn writeSymbolDifference(
                buf: [*]u8,
                sym1: *const Elf64_Sym_Idx,
                mat1: compare.Match,
                name1: [:0]u8,
                sizes: *const compare.Sizes,
                sym2: *const Elf64_Sym_Idx,
                mat2: compare.Match,
                name2: [:0]u8,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeAddressOrOffset(buf, sym2.value, 0);
                ptr[0..5].* = "size=".*;
                ptr = fmt.BloatDiff.write(ptr + 5, sym1.size, sym2.size);
                ptr[0..2].* = ", ".*;
                ptr = writePercentage(ptr + 2, sym2, mat2, sizes);
                ptr[0..5].* = "name=".*;
                ptr = writeCompoundName(ptr + 5, mat1, name1, mat2, name2);
                ptr[0] = '\n';
                ptr += 1;
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthSymbolDifference, .{ sym1, mat1, name1, sizes, sym2, mat2, name2 });
                }
                return ptr;
            }
            fn lengthName(style: []const u8, name: []const u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                const pos: usize = mem.indexOfLastEqualOne(u8, '.', name) orelse 0;
                const to: usize = nameFromPosition(name, pos);
                var len: usize = style.len +% to;
                if (to != pos and name[to] == '(' and name[pos -% 1] == ')') {
                    len +%= 5;
                }
                len +%= name[pos..].len;
                if (style.len != 0) {
                    len +%= tab.fx.none.len;
                }
                return len;
            }
            fn nameFromPosition(name: []const u8, pos: usize) usize {
                var to: usize = pos;
                if (to > 80) {
                    if (mem.indexOfFirstEqualOne(u8, '(', name[0..pos])) |end| {
                        to = end;
                    }
                    while (to > 80) {
                        to = mem.indexOfLastEqualOne(u8, '.', name[0..to]) orelse break;
                    }
                }
                return to;
            }
            fn writeName(buf: [*]u8, style: []const u8, name: []const u8) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const pos: usize = mem.indexOfLastEqualOne(u8, '.', name) orelse 0;
                const to: usize = nameFromPosition(name, pos);
                var ptr: [*]u8 = fmt.strcpyEqu(buf, style);
                ptr = fmt.strcpyEqu(ptr, name[0..to]);
                if (to != pos and name[to] == '(' and name[pos -% 1] == ')') {
                    ptr[0..5].* = "(...)".*;
                    ptr += 5;
                }
                ptr = fmt.strcpyEqu(ptr, name[pos..]);
                if (style.len != 0) {
                    ptr[0..4].* = tab.fx.none;
                    ptr += 4;
                }
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthName, .{ style, name });
                }
                return ptr;
            }
            fn lengthCompoundNameHalf(mat: compare.Match, name: [:0]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                if (mat.isToplevel()) {
                    return lengthName(&.{}, name);
                }
                var len: usize = lengthName(&tab.fx.style.faint, mat.name.space(name)) +% 1 +% lengthName(&.{}, mat.name.short(name));
                if (mat.isMangled() and mat.name.mangle_idx > mat.name.short_idx) {
                    len +%= lengthName(&tab.fx.color.fg.bracket, mat.name.mangler(name));
                }
                return len;
            }
            fn writeCompoundNameHalf(buf: [*]u8, mat: compare.Match, name: [:0]u8) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (mat.isToplevel()) {
                    return writeName(buf, &.{}, name);
                }
                var ptr: [*]u8 = writeName(buf, &tab.fx.style.faint, mat.name.space(name));
                ptr[0] = '.';
                ptr = writeName(ptr + 1, &.{}, mat.name.short(name));
                if (mat.isMangled() and mat.name.mangle_idx > mat.name.short_idx) {
                    ptr = writeName(ptr, &tab.fx.color.fg.bracket, mat.name.mangler(name));
                }
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthCompoundNameHalf, .{ mat, name });
                }
                return ptr;
            }
            fn lengthNameSegment(
                style: []const u8,
                style1: []const u8,
                name1: []const u8,
                style2: []const u8,
                name2: []const u8,
            ) usize {
                var len: usize = 0;
                if (mem.testEqualString(name1, name2)) {
                    len +%= lengthName(style, name2);
                } else {
                    len +%= 1 +% lengthName(style1, name1) +% 2 +% lengthName(style2, name2) +% 1;
                }
                return len;
            }
            fn writeNameSegment(
                buf: [*]u8,
                style: []const u8,
                style1: []const u8,
                name1: []const u8,
                style2: []const u8,
                name2: []const u8,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (mem.testEqualString(name1, name2)) {
                    ptr = writeName(ptr, style, name2);
                } else {
                    ptr[0] = '[';
                    ptr = writeName(ptr + 1, style1, name1);
                    ptr[0..2].* = "=>".*;
                    ptr = writeName(ptr + 2, style2, name2);
                    ptr[0] = ']';
                    ptr += 1;
                }
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthNameSegment, .{ style, style1, name1, style2, name2 });
                }
                return ptr;
            }
            fn lengthCompoundName(
                mat1: compare.Match,
                name1: [:0]u8,
                mat2: compare.Match,
                name2: [:0]u8,
            ) usize {
                if (mat1.isToplevel() and mat2.isToplevel()) {
                    return lengthName(&tab.fx.none, name2);
                }
                if (mem.testEqualString(name1, name2)) {
                    return lengthCompoundNameHalf(mat2, name2);
                } else {
                    var len: usize = 0;
                    len +%= lengthNameSegment(
                        &tab.fx.style.faint,
                        &tab.fx.color.fg.hi_yellow,
                        mat1.name.space(name1),
                        &tab.fx.color.fg.hi_blue,
                        mat2.name.space(name2),
                    );
                    len +%= 1;
                    len +%= lengthNameSegment(
                        &tab.fx.none,
                        &tab.fx.color.fg.hi_yellow,
                        mat1.name.short(name1),
                        &tab.fx.color.fg.hi_blue,
                        mat2.name.short(name2),
                    );
                    if (mat1.isMangled() and
                        mat2.isMangled())
                    {
                        len +%= lengthNameSegment(
                            &tab.fx.style.faint,
                            &tab.fx.color.fg.hi_yellow,
                            mat1.name.mangler(name1),
                            &tab.fx.color.fg.hi_blue,
                            mat2.name.mangler(name2),
                        );
                    }
                    return len;
                }
            }
            fn writeCompoundName(
                buf: [*]u8,
                mat1: compare.Match,
                name1: [:0]u8,
                mat2: compare.Match,
                name2: [:0]u8,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf;
                if (mat1.isToplevel() and mat2.isToplevel()) {
                    return writeName(ptr, &tab.fx.none, name2);
                }
                if (mem.testEqualString(name1, name2)) {
                    return writeCompoundNameHalf(buf, mat2, name2);
                } else {
                    ptr = writeNameSegment(
                        ptr,
                        &tab.fx.style.faint,
                        &tab.fx.color.fg.hi_yellow,
                        mat1.name.space(name1),
                        &tab.fx.color.fg.hi_blue,
                        mat2.name.space(name2),
                    );
                    ptr[0] = '.';
                    ptr += 1;
                    ptr = writeNameSegment(
                        ptr,
                        &tab.fx.none,
                        &tab.fx.color.fg.hi_yellow,
                        mat1.name.short(name1),
                        &tab.fx.color.fg.hi_blue,
                        mat2.name.short(name2),
                    );
                    if (mat1.isMangled() and
                        mat2.isMangled())
                    {
                        ptr = writeNameSegment(
                            ptr,
                            &tab.fx.style.faint,
                            &tab.fx.color.fg.hi_yellow,
                            mat1.name.mangler(name1),
                            &tab.fx.color.fg.hi_blue,
                            mat2.name.mangler(name2),
                        );
                    }
                }
                if (loader_spec.options.verify_lengths) {
                    verify(ptr, buf, lengthCompoundName, .{ mat1, name1, mat2, name2 });
                }
                return ptr;
            }
            inline fn verify(ptr: [*]u8, buf: [*]u8, lengthFn: anytype, args: anytype) void {
                const expected: usize = @call(.auto, lengthFn, args);
                const found: usize = fmt.strlen(ptr, buf);
                if (found != expected) {
                    testing.printBufN(4096, .{ .fn_name = fmt.cx(lengthFn), .expected = expected, .found = found });
                }
            }
        };
    };
    return T;
}
pub const spec = struct {
    pub const loader = struct {
        pub const logging = struct {
            pub const verbose = builtin.all(LoaderSpec.Logging);
            pub const silent = builtin.zero(LoaderSpec.Logging);
        };
        pub const errors = struct {
            pub const noexcept = .{
                .open = .{},
                .map = .{},
                .unmap = .{},
                .close = .{},
            };
        };
    };
};
