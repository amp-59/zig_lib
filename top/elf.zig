const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
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
pub const PT = meta.EnumBitField(enum(u32) {
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
    GNU_RELRO = 1685382482,
    GNU_UNKNOWN = 1685382483,
    LOSUNW = 1879048186,
    HISUNW = 1879048191,
    GNU_STACK = 1685382481,
    LOPROC = 1879048192,
    HIPROC = 2147483647,
});
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
pub const STT = meta.EnumBitField(enum(u8) {
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
    st_info: STT,
    st_other: STV,
    st_shndx: u16,
};
pub const Elf64_Sym = extern struct {
    st_name: u32,
    st_info: STT,
    st_other: STV,
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
        return @as(u24, @truncate(self.r_info >> 8));
    }
    pub inline fn r_type(self: @This()) u8 {
        return @as(u8, @truncate(self.r_info & 0xff));
    }
};
pub const Elf64_Rel = extern struct {
    r_offset: u64,
    r_info: u64,
    pub inline fn r_sym(self: @This()) u32 {
        return @as(u32, @truncate(self.r_info >> 32));
    }
    pub inline fn r_type(self: @This()) u32 {
        return @as(u32, @truncate(self.r_info & 0xffffffff));
    }
};
pub const Elf32_Rela = extern struct {
    r_offset: u32,
    r_info: u32,
    r_addend: i32,
    pub inline fn r_sym(self: @This()) u24 {
        return @as(u24, @truncate(self.r_info >> 8));
    }
    pub inline fn r_type(self: @This()) u8 {
        return @as(u8, @truncate(self.r_info & 0xff));
    }
};
pub const Elf64_Rela = extern struct {
    r_offset: u64,
    r_info: u64,
    r_addend: i64,
    pub inline fn r_sym(self: @This()) u32 {
        return @as(u32, @truncate(self.r_info >> 32));
    }
    pub inline fn r_type(self: @This()) u32 {
        return @as(u32, @truncate(self.r_info & 0xffffffff));
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
    X = 1,
    W = 2,
    R = 4,
    MASKOS = 0x0ff00000,
    MASKPROC = 0xf0000000,
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
pub const LoaderSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    const Options = struct {
        lb_info_addr: usize = 0x800000000,
        lb_sect_addr: usize = 0x1000000000,
        show_defined: bool = false,
        show_sections: bool = false,
        extra_sections: []const []const u8 = &.{},
    };
    pub const Logging = packed struct {
        open: debug.Logging.AcquireError = .{},
        seek: debug.Logging.SuccessError = .{},
        read: debug.Logging.SuccessError = .{},
        map: debug.Logging.AcquireError = .{},
        unmap: debug.Logging.ReleaseError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    pub const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        seek: sys.ErrorPolicy = .{ .throw = sys.seek_errors },
        read: sys.ErrorPolicy = .{ .throw = sys.read_errors },
        map: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
        unmap: sys.ErrorPolicy = .{ .abort = sys.munmap_errors },
        close: sys.ErrorPolicy = .{ .abort = sys.close_errors },
    };
};
pub fn GenericDynamicLoader(comptime loader_spec: LoaderSpec) type {
    const T = struct {
        ub_info_addr: usize = lb_info_addr,
        ub_sect_addr: usize = lb_sect_addr,

        const DynamicLoader = @This();
        pub const Info = extern struct {
            ehdr: Elf64_Ehdr,

            meta_next: usize,
            meta_finish: usize,

            prog_addr: usize,
            prog_len: usize,

            links: [links_len]?*Elf64_Shdr,
            impl: extern struct {
                shdr: [*]Elf64_Shdr,
                shstr: [*]u8,

                dynsym: [*]Elf64_Sym,
                symtab: [*]Elf64_Sym,
                dynstr: [*]u8,
                strtab: [*]u8,
            },
            pub fn getSectionHeader(info: *Info, tag: Tag) ?*Elf64_Shdr {
                @setRuntimeSafety(builtin.is_safe);
                return info.links[@intFromEnum(tag)];
            }
            fn allocateMeta(info: *Info, size_of: usize, align_of: usize) usize {
                @setRuntimeSafety(builtin.is_safe);
                const aligned: usize = mach.alignA64(info.meta_next, align_of);
                const next: usize = aligned +% size_of;
                if (next > info.meta_finish) {
                    const finish: usize = mach.alignA4096(next);
                    mem.map(map(), .{}, .{}, info.meta_finish, finish -% info.meta_finish);
                    info.meta_finish = finish;
                }
                info.meta_next = next;
                return aligned;
            }
            fn mapSection(info: *Info, prot: file.Map.Protection, fd: usize, shdr: *Elf64_Shdr) sys.ErrorUnion(loader_spec.errors.map, void) {
                @setRuntimeSafety(builtin.is_safe);
                const addr: usize = mach.alignB4096(shdr.sh_addr);
                const len: usize = mach.alignA4096(shdr.sh_addr +% shdr.sh_size) -% addr;
                const off: usize = mach.alignB4096(shdr.sh_offset);
                try meta.wrap(file.map(map(), prot, .{ .fixed_noreplace = true }, fd, info.prog_addr +% addr, len, off));
            }
            fn symbolGeneric(shdr: *Elf64_Shdr, symtab: [*]Elf64_Sym, strtab: [*]u8, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                const max_idx: usize = @divExact(shdr.sh_size, shdr.sh_entsize);
                var dyn_idx: usize = 1;
                while (dyn_idx != max_idx) : (dyn_idx +%= 1) {
                    var idx: usize = 0;
                    const sym: [*]Elf64_Sym = symtab + dyn_idx;
                    const str: [*]u8 = strtab + sym[0].st_name;
                    while (str[idx] != 0) : (idx +%= 1) {
                        if (sym_name[idx] != str[idx]) break;
                    } else {
                        return @ptrCast(sym);
                    }
                }
                return null;
            }
            pub inline fn dynamicSymbol(info: *const Info, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                return symbolGeneric(
                    info.links[dynsym_idx].?,
                    info.impl.dynsym,
                    info.impl.dynstr,
                    sym_name,
                );
            }
            pub inline fn symbol(info: *const Info, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                return symbolGeneric(
                    info.links[symtab_idx].?,
                    info.impl.symtab,
                    info.impl.strtab,
                    sym_name,
                );
            }
            pub fn loadPointers(info: *const Info, comptime Pointers: type, ptrs: *Pointers) void {
                @setRuntimeSafety(builtin.is_safe);
                const words: [*]usize = @ptrCast(ptrs);
                for (meta.fieldNames(Pointers), 0..) |field_name, fields_idx| {
                    if (info.dynamicSymbol(field_name)) |ret| {
                        words[fields_idx] = info.prog_addr +% ret.st_value;
                    }
                    if (loader_spec.options.show_defined) {
                        about.aboutDefined(field_name, words[fields_idx]);
                    }
                }
            }
            fn readSections(info: *Info) void {
                @setRuntimeSafety(builtin.is_safe);
                var shdr_idx: usize = 0;
                while (shdr_idx != info.ehdr.e_shnum) : (shdr_idx +%= 1) {
                    for (&info.links, 0..) |*link, tags_idx| {
                        if (@intFromPtr(link.*) != 0) {
                            continue;
                        }
                        const shdr: *Elf64_Shdr = &info.impl.shdr[shdr_idx];
                        var str: [*]u8 = info.impl.shstr + shdr.sh_name;
                        var idx: usize = 1;
                        while (str[idx] != 0) : (idx +%= 1) {
                            if (sections[tags_idx][idx] != str[idx]) break;
                        } else {
                            link.* = shdr;
                            info.prog_len = @max(info.prog_len, shdr.sh_addr +% shdr.sh_size);
                            break;
                        }
                    }
                }
                if (loader_spec.options.show_sections) {
                    about.readSectionNotice(info);
                }
            }
            fn readInfo(info: *Info, fd: usize) void {
                @setRuntimeSafety(builtin.is_safe);
                const dynsym_shdr: *Elf64_Shdr = info.links[dynsym_idx].?;
                const dynstr_shdr: *Elf64_Shdr = info.links[dynstr_idx].?;
                const dynsym_buf: [*]u8 = @ptrFromInt(info.allocateMeta(dynsym_shdr.sh_size, 8));
                try meta.wrap(readAt(fd, dynsym_shdr.sh_offset, dynsym_buf, dynsym_shdr.sh_size));
                if (@hasField(Tag, ".symtab")) {
                    if (info.links[symtab_idx]) |symtab_shdr| {
                        info.impl.symtab = @ptrFromInt(info.allocateMeta(symtab_shdr.sh_size, 8));
                        try meta.wrap(readAt(fd, symtab_shdr.sh_offset, @ptrCast(info.impl.symtab), symtab_shdr.sh_size));
                    }
                }
                info.impl.dynstr = @ptrFromInt(info.allocateMeta(dynstr_shdr.sh_size, 1));
                try meta.wrap(readAt(fd, dynstr_shdr.sh_offset, info.impl.dynstr, dynstr_shdr.sh_size));
                if (@hasField(Tag, ".strtab")) {
                    if (info.links[strtab_idx]) |strtab_shdr| {
                        info.impl.strtab = @ptrFromInt(info.allocateMeta(strtab_shdr.sh_size, 1));
                        try meta.wrap(readAt(fd, strtab_shdr.sh_offset, @ptrCast(info.impl.strtab), strtab_shdr.sh_size));
                    }
                }
                info.impl.dynsym = @ptrCast(@alignCast(dynsym_buf));
            }
        };
        pub const lb_info_addr: comptime_int = loader_spec.options.lb_info_addr;
        pub const lb_sect_addr: comptime_int = loader_spec.options.lb_sect_addr;
        pub const links_len: comptime_int = @typeInfo(Tag).Enum.fields.len;
        const sections = [_][]const u8{
            ".dynsym",
            ".dynstr",
            ".rodata",
            ".data.rel.ro",
            ".text",
            ".strtab",
            ".dynamic",
            ".symtab",
        };
        const Tag = meta.TagFromList(sections ++ loader_spec.options.extra_sections);
        const ep0 = .{
            .throw = loader_spec.errors.open.throw ++ loader_spec.errors.seek.throw ++
                loader_spec.errors.read.throw ++ loader_spec.errors.map.throw ++
                loader_spec.errors.unmap.throw ++ loader_spec.errors.close.throw,
            .abort = loader_spec.errors.open.abort ++ loader_spec.errors.seek.abort ++
                loader_spec.errors.read.abort ++ loader_spec.errors.map.abort ++
                loader_spec.errors.unmap.abort ++ loader_spec.errors.close.abort,
        };
        const ep1 = .{
            .throw = loader_spec.errors.read.throw ++ loader_spec.errors.seek.throw,
            .abort = loader_spec.errors.read.abort ++ loader_spec.errors.seek.abort,
        };
        const dynsym_idx: comptime_int = 0;
        const dynstr_idx: comptime_int = 1;
        const rodata_idx: comptime_int = 2;
        const data_rel_ro_idx: comptime_int = 3;
        const text_idx: comptime_int = 4;
        const strtab_idx: comptime_int = 5;
        const dynamic_idx: comptime_int = 6;
        const symtab_idx: comptime_int = 7;

        fn allocateInfo(loader: *DynamicLoader, fd: usize) sys.ErrorUnion(loader_spec.errors.map, *Info) {
            @setRuntimeSafety(builtin.is_safe);
            const len: usize = mach.alignA4096(try meta.wrap(file.seek(seek(), fd, 0, .end)));
            const addr: usize = mach.alignA4096(@atomicRmw(usize, &loader.ub_info_addr, .Add, len, .SeqCst));
            mem.map(map(), .{}, .{}, addr, 4096);
            const info: *Info = @ptrFromInt(addr);
            info.meta_next = addr +% @sizeOf(Info);
            info.meta_finish = addr +% 4096;
            try meta.wrap(readAt(fd, 0, @ptrCast(info), @sizeOf(Elf64_Ehdr)));
            const shdr_len: usize = info.ehdr.e_shnum *% info.ehdr.e_shentsize;
            info.impl.shdr = @ptrFromInt(info.allocateMeta(shdr_len, 8));
            try meta.wrap(readAt(fd, info.ehdr.e_shoff, @ptrCast(info.impl.shdr), shdr_len));
            const shstr_len: usize = info.impl.shdr[info.ehdr.e_shstrndx].sh_size;
            info.impl.shstr = @ptrFromInt(info.allocateMeta(shstr_len, 1));
            try meta.wrap(readAt(fd, info.impl.shdr[info.ehdr.e_shstrndx].sh_offset, info.impl.shstr, shstr_len));
            return info;
        }
        fn mapSections(loader: *DynamicLoader, fd: usize, info: *Info) sys.ErrorUnion(loader_spec.errors.map, void) {
            @setRuntimeSafety(builtin.is_safe);
            info.prog_addr = mach.alignA4096(@atomicRmw(usize, &loader.ub_sect_addr, .Add, info.prog_len, .SeqCst));
            if (info.links[rodata_idx]) |rodata| {
                try meta.wrap(info.mapSection(.{ .read = true }, fd, rodata));
            }
            if (info.links[text_idx]) |text| {
                try meta.wrap(info.mapSection(.{ .exec = true }, fd, text));
            }
            if (info.links[data_rel_ro_idx]) |data_rel_ro| {
                try meta.wrap(info.mapSection(.{ .exec = true }, fd, data_rel_ro));
            }
        }
        pub fn load(loader: *DynamicLoader, pathname: [:0]const u8) sys.ErrorUnion(ep0, *Info) {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = try meta.wrap(file.open(open(), pathname));
            const info: *Info = try meta.wrap(loader.allocateInfo(fd));
            try meta.wrap(info.readSections());
            try meta.wrap(loader.mapSections(fd, info));
            try meta.wrap(info.readInfo(fd));
            try meta.wrap(file.close(close(), fd));
            return info;
        }
        // Consider making function in `file`.
        fn readAt(fd: usize, offset: usize, buf: [*]u8, len: usize) sys.ErrorUnion(ep1, void) {
            @setRuntimeSafety(builtin.is_safe);
            _ = try meta.wrap(file.seek(seek(), fd, offset, .set));
            try meta.wrap(file.read(read(), fd, buf[0..len]));
        }
        fn seek() file.SeekSpec {
            return .{
                .return_type = usize,
                .logging = loader_spec.logging.seek,
                .errors = loader_spec.errors.seek,
            };
        }
        fn read() file.ReadSpec {
            return .{
                .return_type = void,
                .logging = loader_spec.logging.read,
                .errors = loader_spec.errors.read,
            };
        }
        fn close() file.CloseSpec {
            return .{
                .logging = loader_spec.logging.close,
                .errors = loader_spec.errors.close,
            };
        }
        fn open() file.OpenSpec {
            return .{
                .logging = loader_spec.logging.open,
                .errors = loader_spec.errors.open,
            };
        }
        fn map() mem.MapSpec {
            return .{
                .logging = loader_spec.logging.map,
                .errors = loader_spec.errors.map,
            };
        }
        pub const about = struct {
            const load_s: fmt.AboutSrc = fmt.about("load");
            const undef_s: fmt.AboutSrc = fmt.about("undef");
            const dynsym_s: fmt.AboutSrc = fmt.about("dynsym");
            const symtab_s: fmt.AboutSrc = fmt.about("symtab");
            const rodata_s: fmt.AboutSrc = fmt.about("rodata");
            const section_s: fmt.AboutSrc = fmt.about("section");
            pub fn aboutDefined(name: []const u8, addr: usize) void {
                @setRuntimeSafety(builtin.is_safe);
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                var ux64: fmt.Type.Ux64 = .{ .value = addr };
                ptr[0..load_s.len].* = load_s.*;
                ptr += load_s.len;
                @memcpy(ptr, name);
                ptr += name.len;
                if (addr == 8) {
                    ptr[0..8].* = " = null\n".*;
                    ptr += 8;
                } else {
                    ptr[0..15].* = " = @ptrFromInt(".*;
                    ptr += 15;
                    ptr += ux64.formatWriteBuf(ptr);
                    ptr[0..2].* = ")\n".*;
                    ptr += 2;
                }
                debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
            }
            pub fn readSectionNotice(info: *const Info) void {
                @setRuntimeSafety(builtin.is_safe);
                var ux64: fmt.Type.Ux64 = undefined;
                var ud64: fmt.Type.Ud64 = undefined;
                for (info.links, 0..) |link, tags_idx| {
                    if (link) |shdr| {
                        var buf: [4096]u8 = undefined;
                        var ptr: [*]u8 = &buf;
                        if (@intFromPtr(shdr) == 0) {
                            continue;
                        }
                        ptr[0..section_s.len].* = section_s.*;
                        ptr += section_s.len;
                        @memcpy(ptr, sections[tags_idx]);
                        ptr += sections[tags_idx].len;
                        ptr[0..2].* = ": ".*;
                        ptr += 2;
                        if (shdr.sh_addr != 0) {
                            ptr[0..5].* = "addr=".*;
                            ptr += 5;
                            ux64.value = info.prog_addr +% shdr.sh_addr;
                            ptr += ux64.formatWriteBuf(ptr);
                            ptr[0..2].* = ", ".*;
                            ptr += 2;
                        }
                        ptr[0..7].* = "offset=".*;
                        ptr += 7;
                        ud64.value = shdr.sh_offset;
                        ptr += ud64.formatWriteBuf(ptr);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                        ud64.value = shdr.sh_size;
                        ptr += ud64.formatWriteBuf(ptr);
                        ptr[0..6].* = " bytes".*;
                        ptr += 6;
                        ptr[0] = '\n';
                        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
                        if (tags_idx == dynsym_idx and
                            @intFromPtr(info.impl.dynsym) != 0)
                        {
                            writeDynSym(info);
                        }
                    }
                }
            }
            fn writeDynSym(info: *const Info) void {
                @setRuntimeSafety(builtin.is_safe);
                if (@intFromPtr(info.impl.dynsym) == 0) {
                    return;
                }
                const dynsym_shdr: *Elf64_Shdr = info.links[dynsym_idx].?;
                var dyn_idx: usize = 1;
                var buf: [4096]u8 = undefined;
                var ud64: fmt.Type.Ud64 = undefined;
                var ux64: fmt.Type.Ux64 = undefined;
                while (dyn_idx < @divExact(dynsym_shdr.sh_size, dynsym_shdr.sh_entsize)) : (dyn_idx +%= 1) {
                    const sym: Elf64_Sym = info.impl.dynsym[dyn_idx];
                    var name: [:0]u8 = mem.terminate(info.impl.dynstr + sym.st_name, 0);
                    var ptr: [*]u8 = &buf;
                    ptr[0..dynsym_s.len].* = dynsym_s.*;
                    ptr += dynsym_s.len;
                    ptr[0..5].* = "name=".*;
                    ptr += 5;
                    @memcpy(ptr, name);
                    ptr += name.len;
                    ptr[0..8].* = ", vaddr=".*;
                    ux64.value = sym.st_value;
                    ptr += 8;
                    ptr += ux64.formatWriteBuf(ptr);
                    ptr[0..7].* = ", size=".*;
                    ptr += 7;
                    ud64.value = sym.st_size;
                    ptr += ud64.formatWriteBuf(ptr);
                    ptr[0..10].* = ", section=".*;
                    ptr += 10;
                    ud64.value = sym.st_shndx;
                    ptr += ud64.formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                    name = symbolSectionName(info, sym);
                    @memcpy(ptr, name);
                    ptr += name.len;
                    ptr[0] = '\n';
                    ptr += 1;
                    debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
                }
            }
            fn symbolSectionName(info: *const Info, sym: Elf64_Sym) [:0]u8 {
                return mem.terminate(info.impl.shstr + info.impl.shdr[sym.st_shndx].sh_name, 0);
            }
        };
    };
    return T;
}
