const mem = @import("./mem.zig");
const tab = @import("./tab.zig");
const sys = @import("./sys.zig");
const x86 = @import("./x86.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const algo = @import("./algo.zig");
const meta = @import("./meta.zig");
const bits = @import("./bits.zig");
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
    sh_flags: SHF,
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
    sh_flags: SHF,
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
    r_info: packed struct(u64) {
        r_type: R_X86_64,
        zb32: u24,
        r_sym: u32,
    },
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
    r_info: packed struct(u64) {
        r_type: R_X86_64,
        zb32: u24,
        r_sym: u32,
    },
    r_addend: i64,
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
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        if (format.WRITE) {
            ptr += fmt.strcpyEqu(ptr, "WRITE");
        }
        if (format.ALLOC) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "ALLOC");
        }
        if (format.EXECINSTR) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "EXECINSTR");
        }
        if (format.MERGE) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "MERGE");
        }
        if (format.STRINGS) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "STRINGS");
        }
        if (format.INFO_LINK) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "INFO_LINK");
        }
        if (format.LINK_ORDER) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "LINK_ORDER");
        }
        if (format.OS_NONCONFORMING) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "OS_NONCONFORMING");
        }
        if (format.GROUP) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "GROUP");
        }
        if (format.TLS) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "TLS");
        }
        if (format.COMPRESSED) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "COMPRESSED");
        }
        if (format.XCORE_SHF_DP_SECTION) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "XCORE_SHF_DP_SECTION");
        }
        if (format.XCORE_SHF_CP_SECTION) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "XCORE_SHF_CP_SECTION");
        }
        if (format.EXCLUDE) {
            if (ptr != buf) {
                ptr[0] = '|';
                ptr += 1;
            }
            ptr += fmt.strcpyEqu(ptr, "EXCLUDE");
        }
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        if (format.WRITE) {
            len += 5;
        }
        if (format.ALLOC) {
            len += 5;
        }
        if (format.EXECINSTR) {
            len += 9;
        }
        if (format.MERGE) {
            len += 5;
        }
        if (format.STRINGS) {
            len += 7;
        }
        if (format.INFO_LINK) {
            len += 9;
        }
        if (format.LINK_ORDER) {
            len += 10;
        }
        if (format.OS_NONCONFORMING) {
            len += 16;
        }
        if (format.GROUP) {
            len += 5;
        }
        if (format.TLS) {
            len += 3;
        }
        if (format.COMPRESSED) {
            len += 10;
        }
        if (format.XCORE_SHF_DP_SECTION) {
            len += 20;
        }
        if (format.XCORE_SHF_CP_SECTION) {
            len += 20;
        }
        if (format.EXCLUDE) {
            len += 7;
        }
    }
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
pub const LoaderSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    AddressSpace: type,
    const Options = struct {
        extra_sections: []const []const u8 = &.{},
        try_harder_to_match: bool = true,
        exclude_size_below: usize = 128,
        exclude_terms: []const []const u8 = &[_][]const u8{
            "__anon",
            "__struct",
            "__union",
            "__enum",
        },
    };
    pub const Logging = packed struct {
        show_elf_header: bool = false,
        show_relocations: bool = false,
        show_mangled_symbols: bool = true,
        show_unchanged_sections: bool = true,
        show_unchanged_symbols: bool = true,

        open: debug.Logging.AcquireError = .{},
        seek: debug.Logging.SuccessError = .{},
        stat: debug.Logging.SuccessErrorFault = .{},
        read: debug.Logging.SuccessError = .{},
        map: debug.Logging.AcquireError = .{},
        unmap: debug.Logging.ReleaseError = .{},
        close: debug.Logging.ReleaseError = .{},
    };
    pub const Errors = struct {
        open: sys.ErrorPolicy = .{ .throw = file.spec.open.errors.all },
        seek: sys.ErrorPolicy = .{ .throw = file.spec.seek.errors.all },
        stat: sys.ErrorPolicy = .{ .throw = file.spec.stat.errors.all },
        read: sys.ErrorPolicy = .{ .throw = file.spec.read.errors.all },
        map: sys.ErrorPolicy = .{ .throw = mem.spec.mmap.errors.all },
        unmap: sys.ErrorPolicy = .{ .abort = mem.spec.munmap.errors.all },
        close: sys.ErrorPolicy = .{ .abort = file.spec.close.errors.all },
    };
};
const Section = enum(u16) {
    @".dynsym" = 0,
    @".dynstr" = 1,
    @".text" = 2,
    @".strtab" = 3,
    @".dynamic" = 4,
    @".symtab" = 5,
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
};
pub fn GenericDynamicLoader(comptime loader_spec: LoaderSpec) type {
    const T = struct {
        lb_meta_addr: usize = lb_meta_addr,
        ub_meta_addr: usize = lb_meta_addr,
        lb_prog_addr: usize = lb_prog_addr,
        ub_prog_addr: usize = lb_prog_addr,
        const DynamicLoader = @This();
        pub const Info = extern struct {
            ehdr: *Elf64_Ehdr,
            shdr: usize,
            phdr: usize,
            shstr: usize,
            meta: extern struct {
                next: usize,
                finish: usize,
            },
            prog: extern struct {
                addr: usize,
                len: usize,
            },
            fd: usize,
            impl: Sections,
            const Sections = extern struct {
                buf: [tag_list.len]Pair,
                const Pair = extern struct {
                    shdr: ?*Elf64_Shdr,
                    addr: usize,
                };
                const tag_list: [43]Section = @bitCast([43]u16{
                    0,  1,  2,  3,  4,  5,  6,  7,
                    8,  9,  10, 11, 12, 13, 14, 15,
                    16, 17, 18, 19, 20, 21, 22, 23,
                    24, 25, 26, 27, 28, 29, 30, 31,
                    32, 33, 34, 35, 36, 37, 38, 39,
                    40, 41, 42,
                });
                inline fn set(sects: *Sections, tag: Section, shdr: *Elf64_Shdr, addr: usize) void {
                    @setRuntimeSafety(false);
                    sects.buf[@intFromEnum(tag)] = .{ .shdr = shdr, .addr = addr };
                }
                inline fn header(sects: *const Sections, tag: Section) ?*Elf64_Shdr {
                    @setRuntimeSafety(false);
                    return sects.buf[@intFromEnum(tag)].shdr;
                }
                inline fn section(sects: *const Sections, tag: Section) usize {
                    @setRuntimeSafety(false);
                    return sects.buf[@intFromEnum(tag)].addr;
                }
            };
            fn allocateMeta(info: *Info, size_of: usize, align_of: usize) sys.ErrorUnion(loader_spec.errors.map, usize) {
                @setRuntimeSafety(builtin.is_safe);
                const aligned: usize = bits.alignA64(info.meta.next, align_of);
                const next: usize = aligned +% size_of;
                if (next > info.meta.finish) {
                    const finish: usize = bits.alignA4096(next);
                    try meta.wrap(mem.map(map(), .{}, .{}, info.meta.finish, finish -% info.meta.finish));
                    info.meta.finish = finish;
                }
                info.meta.next = next;
                return aligned;
            }
            pub fn loadPathname(info: *const Info) [:0]const u8 {
                const len: *usize = @ptrFromInt(@intFromPtr(info) +% @sizeOf(Info));
                const ptr: [*:0]const u8 = @ptrFromInt(@intFromPtr(len) +% 8);
                return ptr[0..len.* :0];
            }
            fn mapSegments(info: *Info) sys.ErrorUnion(loader_spec.errors.map, void) {
                @setRuntimeSafety(builtin.is_safe);
                var phdr_idx: usize = 1;
                while (phdr_idx != info.ehdr.e_phnum) : (phdr_idx +%= 1) {
                    const phdr: *Elf64_Phdr = info.programHeaderByIndex(phdr_idx);
                    if (phdr.p_type == .LOAD and phdr.p_memsz != 0) {
                        var addr: usize = bits.alignB4096(phdr.p_vaddr);
                        const len: usize = bits.alignA4096(phdr.p_vaddr +% phdr.p_memsz) -% addr;
                        const off: usize = bits.alignB4096(phdr.p_offset);
                        addr +%= info.prog.addr;
                        try meta.wrap(file.map(map(), .{ .read = phdr.p_flags.R, .write = phdr.p_flags.W, .exec = phdr.p_flags.X }, .{ .fixed = true }, info.fd, addr, len, off));
                    }
                }
            }
            fn relocateDynamic(info: *Info, shdr: *Elf64_Shdr, rela_dyn: usize) void {
                @setRuntimeSafety(builtin.is_safe);
                const max_idx: usize = @divExact(shdr.sh_size, shdr.sh_entsize);
                var rela_idx: usize = 1;
                while (rela_idx != max_idx) : (rela_idx +%= 1) {
                    const rela: *Elf64_Rela = @ptrFromInt(rela_dyn +% (rela_idx *% shdr.sh_entsize));
                    switch (rela.r_info.r_type) {
                        .RELATIVE => {
                            const loc: *usize = @ptrFromInt(info.prog.addr +% rela.r_offset);
                            if (loader_spec.logging.show_relocations) {
                                about.aboutRelocation(rela);
                            }
                            loc.* = @bitCast(rela.r_addend);
                            loc.* +%= info.prog.addr;
                        },
                        else => |tag| {
                            proc.exitErrorFault(error.UnsupportedRelocation, @tagName(tag), 2);
                        },
                    }
                }
            }
            fn symbolGeneric(shdr: *Elf64_Shdr, symtab: usize, strtab: usize, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                const max_idx: usize = @divExact(shdr.sh_size, shdr.sh_entsize);
                var sym_idx: usize = 1;
                while (sym_idx != max_idx) : (sym_idx +%= 1) {
                    const sym: *Elf64_Sym = @ptrFromInt(symtab +% (sym_idx *% shdr.sh_entsize));
                    const str: [*]u8 = @ptrFromInt(strtab +% sym.st_name);
                    var idx: usize = 0;
                    while (str[idx] != 0) : (idx +%= 1) {
                        if (sym_name[idx] != str[idx]) break;
                    } else {
                        return sym;
                    }
                }
                return null;
            }
            fn readInfo(info: *Info) sys.ErrorUnion(ep2, void) {
                @setRuntimeSafety(builtin.is_safe);
                const shdr_len: usize = info.ehdr.e_shnum *% info.ehdr.e_shentsize;
                info.shdr = try meta.wrap(info.allocateMeta(shdr_len +% (info.ehdr.e_shnum *% @sizeOf(about.Match)), 8));
                try meta.wrap(readAt(info.fd, info.ehdr.e_shoff, info.shdr, shdr_len));
                const shstr_shdr: *Elf64_Shdr = info.sectionHeaderByIndex(info.ehdr.e_shstrndx);
                info.shstr = try meta.wrap(info.allocateMeta(shstr_shdr.sh_size, 1));
                try meta.wrap(readAt(info.fd, shstr_shdr.sh_offset, info.shstr, shstr_shdr.sh_size));
                var shdr_idx: usize = 1;
                lo: while (shdr_idx != info.ehdr.e_shnum) : (shdr_idx +%= 1) {
                    const shdr: *Elf64_Shdr = info.sectionHeaderByIndex(shdr_idx);
                    if (shdr.sh_type == .PROGBITS) {
                        continue :lo;
                    }
                    var len: usize = shdr.sh_size;
                    if (shdr.sh_type == .SYMTAB or
                        shdr.sh_type == .DYNSYM)
                    {
                        len +%= @divExact(len, shdr.sh_entsize) *% @sizeOf(about.Match);
                    }
                    const tag: Section = for (Sections.tag_list) |tag| {
                        if (mem.testEqualString(info.sectionName(shdr), @tagName(tag))) {
                            shdr.sh_addr = try meta.wrap(info.allocateMeta(len, shdr.sh_addralign));
                            info.impl.set(tag, shdr, shdr.sh_addr);
                            try meta.wrap(readAt(info.fd, shdr.sh_offset, shdr.sh_addr, shdr.sh_size));
                            break tag;
                        }
                    } else {
                        proc.exitErrorFault(error.UnknownSection, info.sectionName(shdr), 2);
                    };
                    if (shdr.sh_type == .REL or
                        shdr.sh_type == .RELA)
                    {
                        try meta.wrap(info.relocateDynamic(shdr, info.impl.section(tag)));
                    }
                }
            }
            pub fn autoLoad(info: *const Info, vtable: *anyopaque) void {
                const entry: *const fn (*anyopaque) void = @ptrFromInt(info.prog.addr +% info.ehdr.e_entry);
                entry(vtable);
            }
            pub inline fn dynamicSymbol(info: *const Info, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                return symbolGeneric(
                    info.impl.header(.@".dynsym") orelse return null,
                    info.impl.section(.@".dynsym"),
                    info.impl.section(.@".dynstr"),
                    sym_name,
                );
            }
            pub inline fn symbol(info: *const Info, sym_name: []const u8) ?*Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                return symbolGeneric(
                    info.impl.header(.@".symtab") orelse return null,
                    info.impl.section(.@".symtab"),
                    info.impl.section(.@".strtab"),
                    sym_name,
                );
            }
            pub fn sectionHeaderByName(info: *const Info, name: []const u8) ?*Elf64_Shdr {
                @setRuntimeSafety(builtin.is_safe);
                var shdr_idx: usize = 1;
                while (shdr_idx != info.ehdr.e_shnum) : (shdr_idx +%= 1) {
                    const shdr: *Elf64_Shdr = @ptrFromInt(info.shdr +% (shdr_idx *% info.ehdr.e_shentsize));
                    if (mem.testEqualString(sectionName(info, shdr), name)) {
                        return shdr;
                    }
                }
                return null;
            }
            pub fn sectionName(info: *const Info, shdr: *const Elf64_Shdr) [:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                return mem.terminate(@ptrFromInt(info.shstr +% shdr.sh_name), 0);
            }
            pub fn sectionHeaderByIndex(info: *const Info, idx: usize) *Elf64_Shdr {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(info.shdr +% (info.ehdr.e_shentsize *% idx));
            }
            pub fn programHeaderByIndex(info: *const Info, idx: usize) *Elf64_Phdr {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(info.phdr +% (info.ehdr.e_phentsize *% idx));
            }
        };
        pub const lb_meta_addr: comptime_int = loader_spec.AddressSpace.arena(0).lb_addr;
        pub const lb_prog_addr: comptime_int = loader_spec.AddressSpace.arena(1).lb_addr;
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
        const ep2 = .{
            .throw = loader_spec.errors.map.throw ++ loader_spec.errors.open.throw ++ ep1.throw,
            .abort = loader_spec.errors.map.abort ++ loader_spec.errors.open.abort ++ ep1.abort,
        };
        fn allocateInfo(loader: *DynamicLoader, pathname: [:0]const u8) sys.ErrorUnion(ep2, *Info) {
            @setRuntimeSafety(builtin.is_safe);
            const fd: usize = try meta.wrap(file.open(open(), .{}, pathname));
            var st: file.Status = undefined;
            try meta.wrap(file.statusAt(stat(), .{}, file.cwd, pathname, &st));
            const len: usize = bits.alignA4096(st.size);
            const meta_start: usize = bits.alignA4096(@atomicRmw(usize, &loader.ub_meta_addr, .Add, len, .SeqCst));
            var meta_len: usize = 4096;
            var meta_finish: usize = meta_start +% meta_len;
            try meta.wrap(mem.map(map(), .{}, .{}, meta_start, 4096));
            try meta.wrap(readAt(fd, 0, meta_start, 4096));
            const ehdr: *Elf64_Ehdr = @ptrFromInt(meta_start);
            const phdr_start: usize = meta_start +% ehdr.e_phoff;
            const phdr_finish: usize = phdr_start +% (ehdr.e_phnum *% ehdr.e_phentsize);
            const meta_next: usize = phdr_finish +% (@sizeOf(Info) +% 8 +% 1 +% pathname.len);
            if (meta_next > meta_finish) {
                meta_len +%= bits.alignA4096(meta_next -% meta_finish);
                try meta.wrap(mem.map(map(), .{}, .{}, meta_start +% 4096, meta_len -% 4096));
                meta_finish = meta_start +% meta_len;
            }
            const info: *Info = @ptrFromInt(phdr_finish);
            mem.zero(Info, info);
            info.ehdr = ehdr;
            info.phdr = phdr_start;
            info.fd = fd;
            info.meta = .{ .next = meta_next, .finish = meta_finish };
            var path: [*]u8 = @ptrFromInt(phdr_finish +% @sizeOf(Info));
            path = fmt.strcpyEqu(path, &@as([8]u8, @bitCast(pathname.len)));
            fmt.strcpyEqu(path, pathname)[0] = 0;
            if (loader_spec.logging.show_elf_header) {
                about.aboutLoad(info, pathname);
            }
            return info;
        }
        fn loadSegments(loader: *DynamicLoader, info: *Info) sys.ErrorUnion(loader_spec.errors.map, void) {
            if (info.ehdr.e_phnum != 0) {
                var phdr_idx: usize = 1;
                while (phdr_idx != info.ehdr.e_phnum) : (phdr_idx +%= 1) {
                    const phdr: *Elf64_Phdr = info.programHeaderByIndex(phdr_idx);
                    if (phdr.p_type == .LOAD and phdr.p_memsz != 0) {
                        info.prog.len = @max(info.prog.len, phdr.p_vaddr +% phdr.p_memsz);
                    }
                }
                info.prog.addr = bits.alignA4096(@atomicRmw(usize, &loader.ub_prog_addr, .Add, info.prog.len, .SeqCst));
            }
            if (info.ehdr.e_type == .DYN or info.ehdr.e_type == .EXEC) {
                try meta.wrap(info.mapSegments());
            }
        }
        const LoadWhich = enum(u8) {
            Program,
            Metadata,
            All,
        };
        pub fn load(loader: *DynamicLoader, pathname: [:0]const u8) sys.ErrorUnion(ep0, *Info) {
            @setRuntimeSafety(builtin.is_safe);
            const info: *Info = try meta.wrap(loader.allocateInfo(pathname));
            try meta.wrap(loader.loadSegments(info));
            try meta.wrap(info.readInfo());
            try meta.wrap(file.close(close(), info.fd));
            return info;
        }
        // Consider making function in `file`.
        fn readAt(fd: usize, offset: usize, addr: usize, len: usize) sys.ErrorUnion(ep1, void) {
            @setRuntimeSafety(builtin.is_safe);
            try meta.wrap(file.read2(read2(), .{}, fd, &[1]mem.Vector{.{ .addr = addr, .len = len }}, offset));
        }
        fn stat() file.StatusSpec {
            return .{
                .logging = loader_spec.logging.stat,
                .errors = loader_spec.errors.stat,
            };
        }
        fn seek() file.SeekSpec {
            return .{
                .return_type = usize,
                .logging = loader_spec.logging.seek,
                .errors = loader_spec.errors.seek,
            };
        }
        fn read2() file.Read2Spec {
            return .{
                .return_type = void,
                .logging = loader_spec.logging.read,
                .errors = loader_spec.errors.read,
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
        fn unmap() mem.UnmapSpec {
            return .{
                .logging = loader_spec.logging.unmap,
                .errors = loader_spec.errors.unmap,
            };
        }
        pub const about = struct {
            const meta_s: fmt.AboutSrc = fmt.about("meta");
            const load_s: fmt.AboutSrc = fmt.about("load");
            const undef_s: fmt.AboutSrc = fmt.about("undef");
            const reloc_s: fmt.AboutSrc = fmt.about("reloc");
            const dynsym_s: fmt.AboutSrc = fmt.about("dynsym");
            const section_s: fmt.AboutSrc = fmt.about("section");
            const Match = struct {
                idx: u32 = 0,
                tag: Tag = .unknown,
                const Tag = enum(u8) {
                    unknown = 0,
                    pc_addr,
                    added,
                    removed,
                    moved,
                    matched,
                    hidden,
                    mangled,
                    /// These require considerable effort
                    renamed_mangled,
                    renamed_namespace,
                    renamed,
                };
            };
            fn nameIndices(name: [:0]u8) NameIndices {
                var idx: u32 = 0;
                var ret: NameIndices = .{};
                while (idx < name.len) : (idx +%= 1) {
                    if (name[idx] == '.') {
                        ret.spos = idx;
                    } else if (name[idx] == '_') {
                        if (name[idx +% 1] == '_') {
                            ret.mpos = idx;
                        }
                    }
                }
                return ret;
            }
            const ColumnWidth = packed struct(usize) {
                /// Character width of address column
                addr: u16 = 0,
                /// Character width of size column
                size: u16 = 0,
                /// Character width of name column
                name: u32 = 0,
            };
            const NameIndices = packed struct(usize) {
                /// Mangled name start position.
                mpos: u32 = 0,
                /// Short name start position.
                spos: u32 = 0,
                fn namespace(nidx: NameIndices, name: [:0]u8) []u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    return name[0..nidx.spos];
                }
                fn mangler(nidx: NameIndices, name: [:0]u8) [:0]u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    return name[nidx.mpos..];
                }
                fn mangled(nidx: NameIndices, name: [:0]u8) [:0]u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    return name[nidx.spos..];
                }
                fn short(nidx: NameIndices, name: [:0]u8) []u8 {
                    @setRuntimeSafety(builtin.is_safe);
                    if (nidx.mpos > nidx.spos) {
                        return name[nidx.spos..nidx.mpos];
                    } else {
                        return name[nidx.spos..];
                    }
                }
            };
            fn maybeSortInPlace(st_shdr1: *Elf64_Shdr) void {
                @setRuntimeSafety(builtin.is_safe);
                if (st_shdr1.sh_entsize == @sizeOf(Elf64_Sym)) {
                    const max_idx1: usize = st_shdr1.sh_size / st_shdr1.sh_entsize;
                    const st: [*]Elf64_Sym = @ptrFromInt(st_shdr1.sh_addr);
                    algo.shellSort(Elf64_Sym, sortSym, st[1..max_idx1]);
                }
            }
            fn symbolMatches(shdr: *const Elf64_Shdr) [*]Match {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(shdr.sh_addr +% shdr.sh_size);
            }
            fn sectionMatches(info: *const Info) [*]Match {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(info.shdr +% (info.ehdr.e_shentsize *% info.ehdr.e_shnum));
            }
            fn programMatches(info: *const Info) [*]Match {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(info.phdr +% (info.ehdr.e_phentsize *% info.ehdr.e_phnum));
            }
            fn symbolByIndex(shdr: *const Elf64_Shdr, sym_idx: usize) *Elf64_Sym {
                @setRuntimeSafety(builtin.is_safe);
                return @ptrFromInt(shdr.sh_addr +% (shdr.sh_entsize *% sym_idx));
            }
            fn symbolName(info: *const Info, shdr: *const Elf64_Shdr, sym: *Elf64_Sym) ?[:0]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (shdr.sh_link != 0) {
                    return mem.terminate(@ptrFromInt(info.sectionHeaderByIndex(shdr.sh_link).sh_addr + sym.st_name), 0);
                }
                return null;
            }
            fn bestSymbolTable(info: *const Info) ?*Elf64_Shdr {
                @setRuntimeSafety(builtin.is_safe);
                const symtab_idx: comptime_int = @intFromEnum(Section.@".symtab");
                const dynsym_idx: comptime_int = @intFromEnum(Section.@".dynsym");
                return info.impl.buf[symtab_idx].shdr orelse info.impl.buf[dynsym_idx].shdr;
            }
            fn matchSymbolNameInRange(
                info1: *const Info,
                shdr1: *const Elf64_Shdr,
                shdr_idx1: usize,
                mats1: [*]Match,
                name1: [:0]u8,
                sym_idx2_from: usize,
                sym_idx2_to: usize,
            ) usize {
                @setRuntimeSafety(builtin.is_safe);
                var sym_idx2: usize = @min(sym_idx2_from, sym_idx2_to);
                while (sym_idx2 != sym_idx2_to) : (sym_idx2 +%= 1) {
                    if (mats1[sym_idx2].tag != .unknown) {
                        continue;
                    }
                    const sym2: *Elf64_Sym = symbolByIndex(shdr1, sym_idx2);
                    if (sym2.st_shndx != shdr_idx1) {
                        continue;
                    }
                    const name2: [:0]u8 = symbolName(info1, shdr1, sym2) orelse {
                        continue;
                    };
                    if (mem.testEqualString(name1, name2)) {
                        return sym_idx2;
                    }
                }
                return 0;
            }
            fn matchSectionNameInRange(
                info2: *const Info,
                name1: [:0]const u8,
                shdr_idx2_from: usize,
                shdr_idx2_to: usize,
            ) usize {
                @setRuntimeSafety(builtin.is_safe);
                var shdr_idx2: usize = @min(shdr_idx2_from, shdr_idx2_to);
                while (shdr_idx2 != shdr_idx2_to) : (shdr_idx2 +%= 1) {
                    const shdr2: *Elf64_Shdr = info2.sectionHeaderByIndex(shdr_idx2);
                    const name2: [:0]const u8 = info2.sectionName(shdr2);
                    if (mem.testEqualString(name1, name2)) {
                        return shdr_idx2;
                    }
                }
                return 0;
            }
            fn compareSymbolBytes(info1: *const Info, sym1: *Elf64_Sym, info2: *const Info, sym2: *Elf64_Sym) bool {
                @setRuntimeSafety(builtin.is_safe);
                const bytes1: [*]u8 = @ptrFromInt(info1.prog.addr +% sym1.st_value);
                const bytes2: [*]u8 = @ptrFromInt(info2.prog.addr +% sym2.st_value);
                return mem.testEqualString(bytes1[0..sym1.st_size], bytes2[0..sym2.st_size]);
            }
            fn compareSizes(sym1: *Elf64_Sym, sym2: *Elf64_Sym, min_size_diff: *usize) bool {
                @setRuntimeSafety(builtin.is_safe);
                const size_diff: usize =
                    @max(sym1.st_size, sym2.st_size) -%
                    @min(sym1.st_size, sym2.st_size);
                const ret: bool = size_diff < min_size_diff.*;
                if (ret) {
                    min_size_diff.* = size_diff;
                }
                return ret;
            }
            pub fn writeSymtabDifference(
                buf: [*]u8,
                info1: *const Info,
                shdr1: *Elf64_Shdr,
                shndx1: usize,
                info2: *const Info,
                shdr2: *Elf64_Shdr,
                shndx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const mats1: [*]Match = symbolMatches(shdr1);
                const mats2: [*]Match = symbolMatches(shdr2);
                const max_idx1: usize = @divExact(shdr1.sh_size, shdr1.sh_entsize);
                const max_idx2: usize = @divExact(shdr2.sh_size, shdr2.sh_entsize);
                const strtab1: [*]u8 = @ptrFromInt(info1.sectionHeaderByIndex(shdr1.sh_link).sh_addr);
                const strtab2: [*]u8 = @ptrFromInt(info2.sectionHeaderByIndex(shdr2.sh_link).sh_addr);
                const sh_name1: [:0]const u8 = info1.sectionName(info1.sectionHeaderByIndex(shndx1));
                const sh_name2: [:0]const u8 = info2.sectionName(info2.sectionHeaderByIndex(shndx2));
                maybeSortInPlace(shdr1);
                maybeSortInPlace(shdr2);
                var hidden_count: usize = 0;
                var hidden_size: usize = 0;
                if (shdr1.sh_type != shdr2.sh_type) {
                    return buf;
                }
                var ptr: [*]u8 = buf;
                var sym_idx2: usize = 1;
                while (sym_idx2 != max_idx2) : (sym_idx2 +%= 1) {
                    const sym2: *Elf64_Sym = symbolByIndex(shdr2, sym_idx2);
                    if (shndx2 != sym2.st_shndx) {
                        continue;
                    }
                    const name2: [:0]u8 = symbolName(info2, shdr2, sym2) orelse {
                        continue;
                    };
                    const name_idx2: NameIndices = nameIndices(name2);
                    if (!loader_spec.logging.show_mangled_symbols and
                        name_idx2.mpos != 0 and
                        sym2.st_size < loader_spec.options.exclude_size_below)
                    {
                        hidden_count +%= 1;
                        hidden_size +%= sym2.st_size;
                        continue;
                    }
                    var sym_idx1: usize = 1;
                    sym_idx1 = blk: {
                        const min_idx1: usize = @min(max_idx1, sym_idx2);
                        sym_idx1 = min_idx1;
                        var mat_idx: usize = matchSymbolNameInRange(info1, shdr1, shndx1, mats1, name2, sym_idx1, max_idx1);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        sym_idx1 -|= 5;
                        sym_idx1 +%= 1;
                        mat_idx = matchSymbolNameInRange(info1, shdr1, shndx1, mats1, name2, sym_idx1, min_idx1);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        mat_idx = matchSymbolNameInRange(info1, shdr1, shndx1, mats1, name2, 1, sym_idx1);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        mats2[sym_idx2].tag = .added;
                        continue;
                    };
                    const sym1: *Elf64_Sym = symbolByIndex(shdr1, sym_idx1);
                    if (name_idx2.mpos != 0) {
                        if (!compareSymbolBytes(info1, sym1, info2, sym2)) {
                            mats2[sym_idx2].tag = .added;
                            continue;
                        }
                    }
                    mats1[sym_idx1] = .{
                        .tag = .matched,
                        .idx = @intCast(sym_idx2),
                    };
                    mats2[sym_idx2] = .{
                        .tag = .matched,
                        .idx = @intCast(sym_idx1),
                    };
                }
                sym_idx2 = 1;
                while (sym_idx2 != max_idx2) : (sym_idx2 +%= 1) {
                    if (mats2[sym_idx2].tag != .added) {
                        continue;
                    }
                    const sym2: *Elf64_Sym = symbolByIndex(shdr2, sym_idx2);
                    if (shndx2 != sym2.st_shndx) {
                        continue;
                    }
                    const name2: [:0]u8 = symbolName(info2, shdr2, sym2) orelse {
                        continue;
                    };
                    const name_idx2: NameIndices = nameIndices(name2);
                    var mat_size_diff: usize = 0;
                    mat_size_diff -%= 1;
                    var sym_idx1: usize = 1;
                    while (sym_idx1 != max_idx1) : (sym_idx1 +%= 1) {
                        if (mats1[sym_idx1].tag != .unknown) {
                            continue;
                        }
                        const sym1: *Elf64_Sym = symbolByIndex(shdr1, sym_idx1);
                        if (shndx1 != sym1.st_shndx) {
                            continue;
                        }
                        const name1: [:0]u8 = symbolName(info1, shdr1, sym1) orelse {
                            continue;
                        };
                        const name_idx1: NameIndices = nameIndices(name1);
                        if (compareSymbolBytes(info1, sym1, info2, sym2)) {
                            mats2[sym_idx2] = .{
                                .tag = if (name_idx2.mpos != 0) .renamed_mangled else .renamed,
                                .idx = @intCast(sym_idx1),
                            };
                            break;
                        }
                        if (name_idx2.mpos & name_idx1.mpos != 0 and
                            mem.testEqualString(name_idx2.short(name2), name_idx1.short(name1)) and
                            compareSizes(sym1, sym2, &mat_size_diff))
                        {
                            mats2[sym_idx2] = .{
                                .tag = .renamed_mangled,
                                .idx = @intCast(sym_idx1),
                            };
                        }
                        if (name_idx2.spos & name_idx1.spos != 0 and
                            mem.testEqualString(name_idx2.short(name2), name_idx1.short(name1)) and
                            compareSizes(sym1, sym2, &mat_size_diff))
                        {
                            mats2[sym_idx2] = .{
                                .tag = .renamed_namespace,
                                .idx = @intCast(sym_idx1),
                            };
                        }
                    }
                    sym_idx1 = mats2[sym_idx2].idx;
                    if (sym_idx1 != 0) {
                        mats1[sym_idx1] = .{
                            .tag = mats2[sym_idx2].tag,
                            .idx = @intCast(sym_idx2),
                        };
                    }
                }
                var sym_idx1: usize = 1;
                sym_idx2 = 1;
                while (sym_idx2 != max_idx2) : (sym_idx2 +%= 1) {
                    const sym2: *Elf64_Sym = symbolByIndex(shdr2, sym_idx2);
                    if (mats2[sym_idx2].tag == .unknown) {
                        continue;
                    }
                    if (sym2.st_shndx != shndx2) {
                        continue;
                    }
                    const name2: [:0]u8 = symbolName(info2, shdr2, sym2) orelse {
                        continue;
                    };
                    const name_idx2: NameIndices = nameIndices(name2);
                    if (!loader_spec.logging.show_mangled_symbols and
                        name_idx2.mpos != 0 and
                        sym2.st_size < loader_spec.options.exclude_size_below)
                    {
                        hidden_count +%= 1;
                        hidden_size +%= sym2.st_size;
                    } else {
                        if (mats2[sym_idx2].tag == .added) {
                            ptr = writeSymbolAdded(ptr, strtab2, sym2, sym_idx2, sh_name2.len, width);
                            continue;
                        }
                        sym_idx1 = mats2[sym_idx2].idx;
                        const sym1: *Elf64_Sym = symbolByIndex(shdr1, sym_idx1);
                        const name1: [:0]u8 = symbolName(info1, shdr1, sym1) orelse {
                            continue;
                        };
                        const name_idx1: NameIndices = nameIndices(name1);
                        ptr = @call(.auto, writeSymbolDifference, .{
                            ptr,       sym1,     mats1[sym_idx1], name1,
                            name_idx1, sym2,     mats2[sym_idx2], name2,
                            name_idx2, sym_idx2, sh_name2.len,    width,
                        });
                    }
                }
                sym_idx1 = 1;
                while (sym_idx1 != max_idx1) : (sym_idx1 +%= 1) {
                    const sym1: *Elf64_Sym = symbolByIndex(shdr1, sym_idx1);
                    if (sym1.st_shndx != shndx1) {
                        continue;
                    }
                    if (mats1[sym_idx1].tag != .unknown) {
                        continue;
                    }
                    const name1: [:0]u8 = symbolName(info1, shdr1, sym1) orelse {
                        continue;
                    };
                    const name_idx1: NameIndices = nameIndices(name1);
                    if (!loader_spec.logging.show_mangled_symbols and
                        name_idx1.mpos != 0 and
                        sym1.st_size < loader_spec.options.exclude_size_below)
                    {
                        hidden_count +%= 1;
                        hidden_size +%= sym1.st_size;
                    } else {
                        mats1[sym_idx1].tag = .removed;
                        ptr = writeSymbolRemoved(ptr, strtab1, sym1, sym_idx1, sh_name1.len, width);
                    }
                }
                return ptr;
            }
            pub fn lengthBinary(info1: *Info, _: usize) usize {
                @setRuntimeSafety(builtin.is_safe);
                var sects: ColumnWidth = .{};
                var len: usize = 0;
                len +%= info1.ehdr.e_shnum *% (builtin.message_indent +% sects.name +% sects.addr +% sects.size);
                var shdr_idx1: usize = 1;
                while (shdr_idx1 != info1.ehdr.e_shnum) : (shdr_idx1 +%= 1) {
                    const shdr1: *Elf64_Shdr = info1.sectionHeaderByIndex(shdr_idx1);
                    const name1: [:0]const u8 = info1.sectionName(shdr1);
                    sects.name = @max(sects.name, name1.len);
                }
                return len;
            }
            pub fn writeBinary(buf: [*]u8, info1: *Info, width: usize) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const symtab1: ?*Elf64_Shdr = bestSymbolTable(info1);
                var shdr_idx1: usize = 1;
                var ptr: [*]u8 = buf;
                if (symtab1) |st_shdr1| {
                    maybeSortInPlace(st_shdr1);
                }
                while (shdr_idx1 != info1.ehdr.e_shnum) : (shdr_idx1 +%= 1) {
                    const shdr1: *Elf64_Shdr = info1.sectionHeaderByIndex(shdr_idx1);
                    ptr = writeSection(ptr, info1, shdr1, shdr_idx1, width);
                    ptr = writeSymtab(ptr, info1, symtab1 orelse continue, shdr_idx1, width);
                }
                return ptr;
            }
            pub fn writeBinaryDifference(buf: [*]u8, info1: *const Info, info2: *const Info, width: usize) [*]u8 {
                @setRuntimeSafety(false);
                const symtab1: ?*Elf64_Shdr = bestSymbolTable(info1);
                const symtab2: ?*Elf64_Shdr = bestSymbolTable(info2);
                const mats1: [*]Match = sectionMatches(info1);
                const mats2: [*]Match = sectionMatches(info2);
                @memset(mats1[0..info1.ehdr.e_shnum], .{ .tag = .unknown, .idx = 0 });
                @memset(mats2[0..info2.ehdr.e_shnum], .{ .tag = .unknown, .idx = 0 });
                var ptr: [*]u8 = buf;
                var shdr_idx2: usize = 1;
                while (shdr_idx2 != info2.ehdr.e_shnum) : (shdr_idx2 +%= 1) {
                    const shdr2: *Elf64_Shdr = info2.sectionHeaderByIndex(shdr_idx2);
                    const name2: [:0]u8 = info2.sectionName(shdr2);
                    var shdr_idx1: usize = 1;
                    shdr_idx1 = blk: {
                        const min_idx1: usize = @min(info1.ehdr.e_shnum, shdr_idx2);
                        shdr_idx1 = min_idx1;
                        var mat_idx: usize = matchSectionNameInRange(info1, name2, shdr_idx1, info1.ehdr.e_shnum);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        shdr_idx1 -|= 5;
                        shdr_idx1 +%= 1;
                        mat_idx = matchSectionNameInRange(info1, name2, shdr_idx1, min_idx1);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        mat_idx = matchSectionNameInRange(info1, name2, 1, shdr_idx1);
                        if (mat_idx != 0) {
                            break :blk mat_idx;
                        }
                        mats2[shdr_idx2].tag = .added;
                        continue;
                    };
                    mats1[shdr_idx1] = .{
                        .idx = @truncate(shdr_idx2),
                        .tag = .matched,
                    };
                    mats2[shdr_idx2] = .{
                        .idx = @truncate(shdr_idx1),
                        .tag = .matched,
                    };
                    const shdr1: *Elf64_Shdr = info1.sectionHeaderByIndex(shdr_idx1);
                    ptr = writeSectionDifference(ptr, info2, shdr1, shdr2, shdr_idx2, width);
                    ptr = @call(.auto, writeSymtabDifference, .{
                        ptr,       info1, symtab1 orelse continue,
                        shdr_idx1, info2, symtab2 orelse continue,
                        shdr_idx2, width,
                    });
                }
                var shdr_idx1: usize = 1;
                while (shdr_idx1 != info1.ehdr.e_shnum) : (shdr_idx1 +%= 1) {
                    const shdr1: *Elf64_Shdr = info1.sectionHeaderByIndex(shdr_idx1);
                    if (mats1[shdr_idx1].tag == .unknown) {
                        mats1[shdr_idx1].tag = .removed;
                        ptr = writeSectionRemoved(ptr, info1, shdr1, shdr_idx1, width);
                    }
                }
                return ptr;
            }
            pub fn writeSymtab(
                buf: [*]u8,
                info1: *Info,
                st_shdr1: *const Elf64_Shdr,
                shndx1: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const strtab1: [*]u8 = @ptrFromInt(info1.sectionHeaderByIndex(st_shdr1.sh_link).sh_addr);
                const max_idx1: usize = st_shdr1.sh_size / st_shdr1.sh_entsize;
                const shdr1: *Elf64_Shdr = info1.sectionHeaderByIndex(shndx1);
                const section_name: [:0]const u8 = info1.sectionName(shdr1);
                var hidden_size: usize = 0;
                var hidden_count: usize = 0;
                var sym_idx1: usize = 1;
                var ptr: [*]u8 = buf;
                while (sym_idx1 != max_idx1) : (sym_idx1 +%= 1) {
                    const sym1: *Elf64_Sym = symbolByIndex(st_shdr1, sym_idx1);
                    if (shndx1 != sym1.st_shndx) {
                        continue;
                    }
                    const name1: [:0]u8 = symbolName(info1, st_shdr1, sym1) orelse {
                        continue;
                    };
                    const name_idx1: NameIndices = nameIndices(name1);
                    if (!loader_spec.logging.show_mangled_symbols and
                        name_idx1.mpos != 0 and
                        sym1.st_size < loader_spec.options.exclude_size_below)
                    {
                        hidden_count +%= 1;
                        hidden_size +%= sym1.st_size;
                    } else {
                        ptr = writeSymbol(ptr, strtab1, sym1, sym_idx1, section_name.len, width);
                    }
                }
                if (hidden_size != 0) {
                    ptr = writeExcluded(ptr, section_name.len, width, hidden_count, hidden_size);
                }
                return ptr;
            }
            fn sortSym(sym1: Elf64_Sym, sym2: Elf64_Sym) bool {
                return sym1.st_size < sym2.st_size;
            }
            fn aboutReadMetadataSection(name: [:0]const u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                buf[0..about.meta_s.len].* = about.meta_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[24..], name);
                ptr[0] = '\n';
                ptr += 1;
                debug.write(buf[0..fmt.strlen(ptr, &buf)]);
            }
            fn unknownSectionFault(name: [:0]const u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                buf[0..24].* = "unknown section header: ".*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[24..], name);
                proc.exitFault(buf[0..fmt.strlen(ptr, &buf)], 2);
            }
            fn unsupportedRelocationFault(tag_name: [:0]const u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                buf[0..24].* = "unsupported relocation: ".*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[24..], tag_name);
                proc.exitFault(buf[0..fmt.strlen(ptr, &buf)], 2);
            }
            fn aboutRelocation(rela: *Elf64_Rela) void {
                var buf: [4096]u8 = undefined;
                buf[0..about.reloc_s.len].* = about.reloc_s.*;
                var ptr: [*]u8 = buf[about.reloc_s.len..];
                ptr[0..7].* = "offset=".*;
                ptr += 7;
                var ud64: fmt.Type.Ux64 = .{ .value = rela.r_offset };
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "type=".*;
                ptr += 5;
                ptr = fmt.strcpyEqu(ptr, @tagName(rela.r_info.r_type));
                ptr[0..2].* = ", ".*;
                ptr += 2;
                if (rela.r_info.r_sym != 0) {
                    ptr[0..4].* = "sym=".*;
                    ptr += 4;
                    ud64.value = rela.r_info.r_sym;
                    ptr += ud64.formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                    ptr[0..5].* = "name=".*;
                    ptr += 5;
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                }
                var id64: fmt.Type.Id64 = .{ .value = rela.r_addend };
                ptr[0..7].* = "addend=".*;
                ptr += 7;
                ptr += id64.formatWriteBuf(ptr);
                ptr[0] = '\n';
                ptr += 1;
                debug.write(buf[0..fmt.strlen(ptr, &buf)]);
            }
            fn aboutLoad(info: *const Info, pathname: [:0]const u8) void {
                @setRuntimeSafety(false);
                var buf: [4096]u8 = undefined;
                buf[0..load_s.len].* = load_s.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[load_s.len..], "ELF-");
                ptr = fmt.strcpyEqu(ptr, @tagName(info.ehdr.e_type));
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr = fmt.strcpyEqu(ptr, @tagName(info.ehdr.e_machine));
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..9].* = "sections=".*;
                ptr += 9;
                var ud64: fmt.Type.Ud64 = .{ .value = info.ehdr.e_shnum };
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..9].* = "segments=".*;
                ptr += 9;
                ud64.value = info.ehdr.e_phnum;
                ptr += ud64.formatWriteBuf(ptr);
                if (info.ehdr.e_type == .DYN) {
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                    ptr[0..5].* = "addr=".*;
                    ptr += 5;
                    var ux64: fmt.Type.Ux64 = .{ .value = info.prog.addr };
                    ptr += ux64.formatWriteBuf(ptr);
                }
                var pos: usize = 0;
                for (pathname, 0..) |byte, idx| {
                    if (byte == '/') pos = idx;
                }
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                ptr = fmt.strcpyEqu(ptr, pathname[pos +% 1 ..]);
                ptr[0] = '\n';
                ptr += 1;
                debug.write(fmt.slice(ptr, &buf));
            }
            fn writeSection(
                buf: [*]u8,
                info2: *const Info,
                shdr2: *Elf64_Shdr,
                shdr_idx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf + fmt.writeSideBarIndex(buf, width, shdr_idx2);
                ptr = fmt.strcpyEqu(ptr, info2.sectionName(shdr2));
                ptr[0..2].* = ": ".*;
                ptr += 2;
                if (shdr2.sh_addr != 0) {
                    ptr[0..5].* = "addr=".*;
                    ptr += 5;
                    ptr += fmt.ux64(shdr2.sh_addr).formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                }
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bytes(shdr2.sh_size).formatWriteBuf(ptr);
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSectionAdded(
                buf: [*]u8,
                info2: *const Info,
                shdr2: *Elf64_Shdr,
                shdr_idx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf + fmt.writeSideBarIndex(buf, width, shdr_idx2);
                ptr = fmt.strcpyEqu(ptr, info2.sectionName(shdr2));
                ptr[0..2].* = ": ".*;
                ptr += 2;
                if (shdr2.sh_addr != 0) {
                    ptr[0..5].* = "addr=".*;
                    ptr += 5;
                    ptr += fmt.ux64(shdr2.sh_addr).formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                }
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(0, shdr2.sh_size).formatWriteBuf(ptr);
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSectionRemoved(
                buf: [*]u8,
                info1: *const Info,
                shdr1: *Elf64_Shdr,
                shdr_idx1: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf + fmt.writeSideBarIndex(buf, width, shdr_idx1);
                ptr = fmt.strcpyEqu(ptr, info1.sectionName(shdr1));
                ptr[0..2].* = ": ".*;
                ptr += 2;
                if (shdr1.sh_addr != 0) {
                    ptr[0..5].* = "addr=".*;
                    ptr += 5;
                    ptr += fmt.ux64(shdr1.sh_addr).formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                }
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(shdr1.sh_size, 0).formatWriteBuf(ptr);
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSectionDifference(
                buf: [*]u8,
                info2: *const Info,
                shdr1: *Elf64_Shdr,
                shdr2: *Elf64_Shdr,
                shdr_idx2: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = buf + fmt.writeSideBarIndex(buf, width, shdr_idx2);
                ptr = fmt.strcpyEqu(ptr, info2.sectionName(shdr2));
                ptr[0..2].* = ": ".*;
                ptr += 2;
                if (shdr1.sh_addr < lb_meta_addr and
                    shdr2.sh_addr < lb_meta_addr and
                    shdr1.sh_addr != shdr2.sh_addr)
                {
                    ptr[0..5].* = "addr=".*;
                    ptr += 5;
                    ptr += fmt.ux64(shdr2.sh_addr).formatWriteBuf(ptr);
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                }
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(shdr1.sh_size, shdr2.sh_size).formatWriteBuf(ptr);
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSymbolIntro(
                buf: [*]u8,
                value: usize,
                event: Match.Tag,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = fmt.strsetEqu(buf, ' ', width);
                ptr = fmt.strcpyEqu(ptr, switch (event) {
                    else => "|",
                    .hidden => tab.fx.color.fg.hi_magenta ++ "?" ++ tab.fx.none,
                    .added => tab.fx.color.fg.red ++ "+" ++ tab.fx.none,
                    .removed => tab.fx.color.fg.green ++ "-" ++ tab.fx.none,
                    .matched => tab.fx.color.fg.yellow ++ "~" ++ tab.fx.none,
                    .moved => tab.fx.color.fg.yellow ++ "*" ++ tab.fx.none,
                });
                switch (event) {
                    .hidden => {
                        ptr = fmt.strsetEqu(ptr, ' ', (builtin.message_indent +% name_len -% width));
                        ptr[0] = ' ';
                        ptr += 1;
                    },
                    .pc_addr => {
                        ptr = fmt.strsetEqu(ptr, ' ', 14 +% (builtin.message_indent -% (width +% 1)) +%
                            (name_len -% (fmt.length(usize, value, 10) +% 1)));
                        ptr[0..4].* = tab.fx.style.faint.*;
                        ptr += 4;
                        ptr += fmt.ux64(value).formatWriteBuf(ptr);
                        ptr[0..4].* = tab.fx.none.*;
                        ptr += 4;
                        ptr[0..2].* = ": ".*;
                        ptr += 2;
                    },
                    else => {
                        ptr = fmt.strsetEqu(ptr, ' ', (builtin.message_indent -% (width +% 1)) +%
                            (name_len -% (fmt.length(usize, value, 10) +% 1)));
                        ptr[0..4].* = tab.fx.style.faint.*;
                        ptr += 4;
                        ptr[0] = '#';
                        ptr += 1;
                        ptr += fmt.ud64(value).formatWriteBuf(ptr);
                        ptr[0..4].* = tab.fx.none.*;
                        ptr += 4;
                        ptr[0..2].* = ": ".*;
                        ptr += 2;
                    },
                }
                return ptr;
            }
            fn writeExcluded(
                buf: [*]u8,
                name_len: usize,
                width: usize,
                hidden_count: usize,
                hidden_size: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolIntro(buf, hidden_count, .hidden, name_len, width);
                ptr[0..4].* = tab.fx.style.faint.*;
                ptr += 4;
                ptr += fmt.ud64(hidden_count).formatWriteBuf(ptr);
                ptr[0..9].* = " hidden, ".*;
                ptr += 9;
                ptr += fmt.bytes(hidden_size).formatWriteBuf(ptr);
                ptr[0..4].* = tab.fx.none.*;
                ptr += 4;
                ptr[0] = '\n';
                return ptr + 1;
            }
            fn writeSymbol(
                buf: [*]u8,
                strtab1: [*]u8,
                sym1: *const Elf64_Sym,
                sym_idx1: usize,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolIntro(buf, sym_idx1, .matched, name_len, width);
                ptr[0..5].* = "addr=".*;
                ptr += 5;
                ptr += fmt.ux64(sym1.st_value).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bytes(sym1.st_size).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                ptr = writeBoldShortName(ptr, mem.terminate(strtab1 + sym1.st_name, 0));
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSymbolAdded(
                buf: [*]u8,
                strtab2: [*]u8,
                sym2: *const Elf64_Sym,
                sym_idx2: usize,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolIntro(buf, sym_idx2, .added, name_len, width);
                ptr[0..5].* = "addr=".*;
                ptr += 5;
                ptr += fmt.ux64(sym2.st_value).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 6;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(0, sym2.st_size).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                ptr = writeBoldShortName(ptr, mem.terminate(strtab2 + sym2.st_name, 0));
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSymbolRemoved(
                buf: [*]u8,
                strtab1: [*]u8,
                sym1: *const Elf64_Sym,
                sym_idx1: usize,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolIntro(buf, sym_idx1, .removed, name_len, width);
                ptr[0..5].* = "addr=".*;
                ptr += 5;
                ptr += fmt.ux64(sym1.st_value).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(sym1.st_size, 0).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                ptr = writeBoldShortName(ptr, mem.terminate(strtab1 + sym1.st_name, 0));
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSymbolDifference(
                buf: [*]u8,
                sym1: *const Elf64_Sym,
                mat1: Match,
                name1: [:0]u8,
                name_idx1: NameIndices,
                sym2: *const Elf64_Sym,
                mat2: Match,
                name2: [:0]u8,
                name_idx2: NameIndices,
                sym_idx2: usize,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (mat1.tag != mat2.tag) {
                    return buf;
                }
                if (!loader_spec.logging.show_unchanged_symbols and
                    sym1.st_size == sym2.st_size)
                {
                    return buf;
                }
                var ptr: [*]u8 = writeSymbolIntro(buf, sym_idx2, mat2.tag, name_len, width);
                ptr[0..5].* = "addr=".*;
                ptr += 5;
                ptr += fmt.ux64(sym2.st_value).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bloatDiff(sym1.st_size, sym2.st_size).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                if (@as(usize, @bitCast(name_idx1)) !=
                    @as(usize, @bitCast(name_idx2)))
                {
                    ptr = writeRenamedBoldShortName(ptr, name1, name_idx1, name2, name_idx2);
                } else {
                    ptr = writeBoldShortName(ptr, name2);
                }
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeSymbolMoved(
                buf: [*]u8,
                strtab1: [*]u8,
                sym1: *const Elf64_Sym,
                strtab2: [*]u8,
                sym2: *const Elf64_Sym,
                sym_idx2: usize,
                name_len: usize,
                width: usize,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var ptr: [*]u8 = writeSymbolIntro(buf, sym_idx2, .moved, name_len, width);
                ptr[0..5].* = "addr=".*;
                ptr += 5;
                ptr += fmt.ux64(sym2.st_value).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 6;
                ptr[0..5].* = "size=".*;
                ptr += 5;
                ptr += fmt.bytes(sym2.st_size).formatWriteBuf(ptr);
                ptr[0..2].* = ", ".*;
                ptr += 2;
                ptr[0..5].* = "name=".*;
                ptr += 5;
                ptr = writeRenamedBoldShortName(
                    ptr,
                    mem.terminate(strtab1 + sym1.st_name, 0),
                    mem.terminate(strtab2 + sym2.st_name, 0),
                );
                ptr[0] = '\n';
                ptr += 1;
                return ptr;
            }
            fn writeBoldShortName(buf: [*]u8, name: [:0]u8) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                const pos: usize = mem.indexOfLastEqualOne(u8, '.', name) orelse 0;
                var to: usize = pos;
                if (to > 80) {
                    if (mem.indexOfFirstEqualOne(u8, '(', name[0..pos])) |end| {
                        to = end;
                    }
                    while (to > 80) {
                        to = mem.indexOfLastEqualOne(u8, '.', name[0..to]) orelse break;
                    }
                }
                var ptr: [*]u8 = fmt.strcpyEqu(buf, name[0..to]);
                if (to != pos and
                    name[to] == '(' and name[pos -% 1] == ')')
                {
                    ptr[0..5].* = "(...)".*;
                    ptr += 5;
                }
                ptr[0..8].* = (tab.fx.none ++ tab.fx.style.bold).*;
                ptr += 8;
                ptr = fmt.strcpyEqu(ptr, name[pos..]);
                ptr[0..4].* = tab.fx.none.*;
                ptr += 4;
                return ptr;
            }
            fn writeChangedNameSegment(buf: [*]u8, name1: []const u8, name2: []const u8) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                if (mem.testEqualString(name1, name2)) {
                    return fmt.strcpyEqu(buf, name2);
                }
                buf[0..6].* = ("{" ++ tab.fx.color.fg.blue).*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf + 6, name1);
                ptr[0..11].* = (tab.fx.none ++ "=>" ++ tab.fx.color.fg.yellow).*;
                ptr += 11;
                ptr = fmt.strcpyEqu(ptr, name2);
                ptr[0..5].* = (tab.fx.none ++ "}").*;
                ptr += 5;
                return ptr;
            }
            fn writeRenamedBoldShortName(
                buf: [*]u8,
                name1: [:0]u8,
                name_idx1: NameIndices,
                name2: [:0]u8,
                name_idx2: NameIndices,
            ) [*]u8 {
                @setRuntimeSafety(builtin.is_safe);
                // For now only look at three points of renaming:
                // top.elf.writeRename__anon_1023
                // ^~~~~~~ ^~~~~~~~~~~^~~~~~~~~~~
                // |        \         |
                // Namespace |        Mangler
                //           Name
                //
                // Mangler comparison is in larger incomplete block in
                // `aboutSymtabDifference`.
                //
                // TODO: First round of rename detection should focus on symbols
                // `added` in file2 and `unknown` in file1.
                //
                var ptr: [*]u8 = writeChangedNameSegment(buf, name1[0..name_idx1.spos], name2[0..name_idx1.spos]);
                ptr[0..8].* = (tab.fx.none ++ tab.fx.style.bold).*;
                ptr += 8;
                ptr = writeChangedNameSegment(ptr, name1[name_idx1.spos..], name2[name_idx2.spos..]);
                ptr[0..4].* = tab.fx.none.*;
                ptr += 4;
                return ptr;
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
                .seek = .{},
                .read = .{},
                .map = .{},
                .unmap = .{},
                .close = .{},
            };
        };
    };
};
