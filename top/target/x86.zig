pub const target = @import("../target.zig");
pub const feat = @import("./feat.zig");
pub const Feature = enum(u8) {
    @"16bit_mode" = 0,
    @"32bit_mode" = 1,
    @"3dnow" = 2,
    @"3dnowa" = 3,
    @"64bit" = 4,
    adx = 5,
    aes = 6,
    allow_light_256_bit = 7,
    amx_bf16 = 8,
    amx_fp16 = 9,
    amx_int8 = 10,
    amx_tile = 11,
    avx = 12,
    avx2 = 13,
    avx512bf16 = 14,
    avx512bitalg = 15,
    avx512bw = 16,
    avx512cd = 17,
    avx512dq = 18,
    avx512er = 19,
    avx512f = 20,
    avx512fp16 = 21,
    avx512ifma = 22,
    avx512pf = 23,
    avx512vbmi = 24,
    avx512vbmi2 = 25,
    avx512vl = 26,
    avx512vnni = 27,
    avx512vp2intersect = 28,
    avx512vpopcntdq = 29,
    avxifma = 30,
    avxneconvert = 31,
    avxvnni = 32,
    avxvnniint8 = 33,
    bmi = 34,
    bmi2 = 35,
    branchfusion = 36,
    cldemote = 37,
    clflushopt = 38,
    clwb = 39,
    clzero = 40,
    cmov = 41,
    cmpccxadd = 42,
    crc32 = 43,
    cx16 = 44,
    cx8 = 45,
    enqcmd = 46,
    ermsb = 47,
    f16c = 48,
    false_deps_getmant = 49,
    false_deps_lzcnt_tzcnt = 50,
    false_deps_mulc = 51,
    false_deps_mullq = 52,
    false_deps_perm = 53,
    false_deps_popcnt = 54,
    false_deps_range = 55,
    fast_11bytenop = 56,
    fast_15bytenop = 57,
    fast_7bytenop = 58,
    fast_bextr = 59,
    fast_gather = 60,
    fast_hops = 61,
    fast_lzcnt = 62,
    fast_movbe = 63,
    fast_scalar_fsqrt = 64,
    fast_scalar_shift_masks = 65,
    fast_shld_rotate = 66,
    fast_variable_crosslane_shuffle = 67,
    fast_variable_perlane_shuffle = 68,
    fast_vector_fsqrt = 69,
    fast_vector_shift_masks = 70,
    fma = 71,
    fma4 = 72,
    fsgsbase = 73,
    fsrm = 74,
    fxsr = 75,
    gfni = 76,
    harden_sls_ijmp = 77,
    harden_sls_ret = 78,
    hreset = 79,
    idivl_to_divb = 80,
    idivq_to_divl = 81,
    invpcid = 82,
    kl = 83,
    lea_sp = 84,
    lea_uses_ag = 85,
    lvi_cfi = 86,
    lvi_load_hardening = 87,
    lwp = 88,
    lzcnt = 89,
    macrofusion = 90,
    mmx = 91,
    movbe = 92,
    movdir64b = 93,
    movdiri = 94,
    mwaitx = 95,
    nopl = 96,
    pad_short_functions = 97,
    pclmul = 98,
    pconfig = 99,
    pku = 100,
    popcnt = 101,
    prefer_128_bit = 102,
    prefer_256_bit = 103,
    prefer_mask_registers = 104,
    prefetchi = 105,
    prefetchwt1 = 106,
    prfchw = 107,
    ptwrite = 108,
    raoint = 109,
    rdpid = 110,
    rdpru = 111,
    rdrnd = 112,
    rdseed = 113,
    retpoline = 114,
    retpoline_external_thunk = 115,
    retpoline_indirect_branches = 116,
    retpoline_indirect_calls = 117,
    rtm = 118,
    sahf = 119,
    sbb_dep_breaking = 120,
    serialize = 121,
    seses = 122,
    sgx = 123,
    sha = 124,
    shstk = 125,
    slow_3ops_lea = 126,
    slow_incdec = 127,
    slow_lea = 128,
    slow_pmaddwd = 129,
    slow_pmulld = 130,
    slow_shld = 131,
    slow_two_mem_ops = 132,
    slow_unaligned_mem_16 = 133,
    slow_unaligned_mem_32 = 134,
    soft_float = 135,
    sse = 136,
    sse2 = 137,
    sse3 = 138,
    sse4_1 = 139,
    sse4_2 = 140,
    sse4a = 141,
    sse_unaligned_mem = 142,
    ssse3 = 143,
    tagged_globals = 144,
    tbm = 145,
    tsxldtrk = 146,
    uintr = 147,
    use_glm_div_sqrt_costs = 148,
    use_slm_arith_costs = 149,
    vaes = 150,
    vpclmulqdq = 151,
    vzeroupper = 152,
    waitpkg = 153,
    wbnoinvd = 154,
    widekl = 155,
    x87 = 156,
    xop = 157,
    xsave = 158,
    xsavec = 159,
    xsaveopt = 160,
    xsaves = 161,
};
pub const all_features: []const target.Target.Feature = &.{
    .{ .name = "16bit_mode", .llvm_name = "16bit-mode", .description = "16-bit mode (i8086)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 1, .name = "32bit_mode", .llvm_name = "32bit-mode", .description = "32-bit mode (80386)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 2, .name = "3dnow", .llvm_name = "3dnow", .description = "Enable 3DNow! instructions", .dependencies = .{ .ints = .{ 0, 134217728, 0, 0, 0 } } },
    .{ .index = 3, .name = "3dnowa", .llvm_name = "3dnowa", .description = "Enable 3DNow! Athlon instructions", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
    .{ .index = 4, .name = "64bit", .llvm_name = "64bit", .description = "Support 64-bit instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 5, .name = "adx", .llvm_name = "adx", .description = "Support ADX instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 6, .name = "aes", .llvm_name = "aes", .description = "Enable AES instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 7, .name = "allow_light_256_bit", .llvm_name = "allow-light-256-bit", .description = "Enable generation of 256-bit load/stores even if we prefer 128-bit", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 8, .name = "amx_bf16", .llvm_name = "amx-bf16", .description = "Support AMX-BF16 instructions", .dependencies = .{ .ints = .{ 2048, 0, 0, 0, 0 } } },
    .{ .index = 9, .name = "amx_fp16", .llvm_name = "amx-fp16", .description = "Support AMX amx-fp16 instructions", .dependencies = .{ .ints = .{ 2048, 0, 0, 0, 0 } } },
    .{ .index = 10, .name = "amx_int8", .llvm_name = "amx-int8", .description = "Support AMX-INT8 instructions", .dependencies = .{ .ints = .{ 2048, 0, 0, 0, 0 } } },
    .{ .index = 11, .name = "amx_tile", .llvm_name = "amx-tile", .description = "Support AMX-TILE instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 12, .name = "avx", .llvm_name = "avx", .description = "Enable AVX instructions", .dependencies = .{ .ints = .{ 0, 0, 4096, 0, 0 } } },
    .{ .index = 13, .name = "avx2", .llvm_name = "avx2", .description = "Enable AVX2 instructions", .dependencies = .{ .ints = .{ 4096, 0, 0, 0, 0 } } },
    .{ .index = 14, .name = "avx512bf16", .llvm_name = "avx512bf16", .description = "Support bfloat16 floating point", .dependencies = .{ .ints = .{ 65536, 0, 0, 0, 0 } } },
    .{ .index = 15, .name = "avx512bitalg", .llvm_name = "avx512bitalg", .description = "Enable AVX-512 Bit Algorithms", .dependencies = .{ .ints = .{ 65536, 0, 0, 0, 0 } } },
    .{ .index = 16, .name = "avx512bw", .llvm_name = "avx512bw", .description = "Enable AVX-512 Byte and Word Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 17, .name = "avx512cd", .llvm_name = "avx512cd", .description = "Enable AVX-512 Conflict Detection Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 18, .name = "avx512dq", .llvm_name = "avx512dq", .description = "Enable AVX-512 Doubleword and Quadword Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 19, .name = "avx512er", .llvm_name = "avx512er", .description = "Enable AVX-512 Exponential and Reciprocal Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 20, .name = "avx512f", .llvm_name = "avx512f", .description = "Enable AVX-512 instructions", .dependencies = .{ .ints = .{ 281474976718848, 128, 0, 0, 0 } } },
    .{ .index = 21, .name = "avx512fp16", .llvm_name = "avx512fp16", .description = "Support 16-bit floating point", .dependencies = .{ .ints = .{ 67436544, 0, 0, 0, 0 } } },
    .{ .index = 22, .name = "avx512ifma", .llvm_name = "avx512ifma", .description = "Enable AVX-512 Integer Fused Multiply-Add", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 23, .name = "avx512pf", .llvm_name = "avx512pf", .description = "Enable AVX-512 PreFetch Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 24, .name = "avx512vbmi", .llvm_name = "avx512vbmi", .description = "Enable AVX-512 Vector Byte Manipulation Instructions", .dependencies = .{ .ints = .{ 65536, 0, 0, 0, 0 } } },
    .{ .index = 25, .name = "avx512vbmi2", .llvm_name = "avx512vbmi2", .description = "Enable AVX-512 further Vector Byte Manipulation Instructions", .dependencies = .{ .ints = .{ 65536, 0, 0, 0, 0 } } },
    .{ .index = 26, .name = "avx512vl", .llvm_name = "avx512vl", .description = "Enable AVX-512 Vector Length eXtensions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 27, .name = "avx512vnni", .llvm_name = "avx512vnni", .description = "Enable AVX-512 Vector Neural Network Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 28, .name = "avx512vp2intersect", .llvm_name = "avx512vp2intersect", .description = "Enable AVX-512 vp2intersect", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 29, .name = "avx512vpopcntdq", .llvm_name = "avx512vpopcntdq", .description = "Enable AVX-512 Population Count Instructions", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
    .{ .index = 30, .name = "avxifma", .llvm_name = "avxifma", .description = "Enable AVX-IFMA", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
    .{ .index = 31, .name = "avxneconvert", .llvm_name = "avxneconvert", .description = "Support AVX-NE-CONVERT instructions", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
    .{ .index = 32, .name = "avxvnni", .llvm_name = "avxvnni", .description = "Support AVX_VNNI encoding", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
    .{ .index = 33, .name = "avxvnniint8", .llvm_name = "avxvnniint8", .description = "Enable AVX-VNNI-INT8", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
    .{ .index = 34, .name = "bmi", .llvm_name = "bmi", .description = "Support BMI instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 35, .name = "bmi2", .llvm_name = "bmi2", .description = "Support BMI2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 36, .name = "branchfusion", .llvm_name = "branchfusion", .description = "CMP/TEST can be fused with conditional branches", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 37, .name = "cldemote", .llvm_name = "cldemote", .description = "Enable Cache Line Demote", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 38, .name = "clflushopt", .llvm_name = "clflushopt", .description = "Flush A Cache Line Optimized", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 39, .name = "clwb", .llvm_name = "clwb", .description = "Cache Line Write Back", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 40, .name = "clzero", .llvm_name = "clzero", .description = "Enable Cache Line Zero", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 41, .name = "cmov", .llvm_name = "cmov", .description = "Enable conditional move instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 42, .name = "cmpccxadd", .llvm_name = "cmpccxadd", .description = "Support CMPCCXADD instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 43, .name = "crc32", .llvm_name = "crc32", .description = "Enable SSE 4.2 CRC32 instruction (used when SSE4.2 is supported but function is GPR only)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 44, .name = "cx16", .llvm_name = "cx16", .description = "64-bit with cmpxchg16b (this is true for most x86-64 chips, but not the first AMD chips)", .dependencies = .{ .ints = .{ 35184372088832, 0, 0, 0, 0 } } },
    .{ .index = 45, .name = "cx8", .llvm_name = "cx8", .description = "Support CMPXCHG8B instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 46, .name = "enqcmd", .llvm_name = "enqcmd", .description = "Has ENQCMD instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 47, .name = "ermsb", .llvm_name = "ermsb", .description = "REP MOVS/STOS are fast", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 48, .name = "f16c", .llvm_name = "f16c", .description = "Support 16-bit floating point conversion instructions", .dependencies = .{ .ints = .{ 4096, 0, 0, 0, 0 } } },
    .{ .index = 49, .name = "false_deps_getmant", .llvm_name = "false-deps-getmant", .description = "VGETMANTSS/SD/SH and VGETMANDPS/PD(memory version) has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 50, .name = "false_deps_lzcnt_tzcnt", .llvm_name = "false-deps-lzcnt-tzcnt", .description = "LZCNT/TZCNT have a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 51, .name = "false_deps_mulc", .llvm_name = "false-deps-mulc", .description = "VF[C]MULCPH/SH has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 52, .name = "false_deps_mullq", .llvm_name = "false-deps-mullq", .description = "VPMULLQ has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 53, .name = "false_deps_perm", .llvm_name = "false-deps-perm", .description = "VPERMD/Q/PS/PD has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 54, .name = "false_deps_popcnt", .llvm_name = "false-deps-popcnt", .description = "POPCNT has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 55, .name = "false_deps_range", .llvm_name = "false-deps-range", .description = "VRANGEPD/PS/SD/SS has a false dependency on dest register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 56, .name = "fast_11bytenop", .llvm_name = "fast-11bytenop", .description = "Target can quickly decode up to 11 byte NOPs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 57, .name = "fast_15bytenop", .llvm_name = "fast-15bytenop", .description = "Target can quickly decode up to 15 byte NOPs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 58, .name = "fast_7bytenop", .llvm_name = "fast-7bytenop", .description = "Target can quickly decode up to 7 byte NOPs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 59, .name = "fast_bextr", .llvm_name = "fast-bextr", .description = "Indicates that the BEXTR instruction is implemented as a single uop with good throughput", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 60, .name = "fast_gather", .llvm_name = "fast-gather", .description = "Indicates if gather is reasonably fast (this is true for Skylake client and all AVX-512 CPUs)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 61, .name = "fast_hops", .llvm_name = "fast-hops", .description = "Prefer horizontal vector math instructions (haddp, phsub, etc.) over normal vector instructions with shuffles", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 62, .name = "fast_lzcnt", .llvm_name = "fast-lzcnt", .description = "LZCNT instructions are as fast as most simple integer ops", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 63, .name = "fast_movbe", .llvm_name = "fast-movbe", .description = "Prefer a movbe over a single-use load + bswap / single-use bswap + store", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 64, .name = "fast_scalar_fsqrt", .llvm_name = "fast-scalar-fsqrt", .description = "Scalar SQRT is fast (disable Newton-Raphson)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 65, .name = "fast_scalar_shift_masks", .llvm_name = "fast-scalar-shift-masks", .description = "Prefer a left/right scalar logical shift pair over a shift+and pair", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 66, .name = "fast_shld_rotate", .llvm_name = "fast-shld-rotate", .description = "SHLD can be used as a faster rotate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 67, .name = "fast_variable_crosslane_shuffle", .llvm_name = "fast-variable-crosslane-shuffle", .description = "Cross-lane shuffles with variable masks are fast", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 68, .name = "fast_variable_perlane_shuffle", .llvm_name = "fast-variable-perlane-shuffle", .description = "Per-lane shuffles with variable masks are fast", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 69, .name = "fast_vector_fsqrt", .llvm_name = "fast-vector-fsqrt", .description = "Vector SQRT is fast (disable Newton-Raphson)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 70, .name = "fast_vector_shift_masks", .llvm_name = "fast-vector-shift-masks", .description = "Prefer a left/right vector logical shift pair over a shift+and pair", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 71, .name = "fma", .llvm_name = "fma", .description = "Enable three-operand fused multiply-add", .dependencies = .{ .ints = .{ 4096, 0, 0, 0, 0 } } },
    .{ .index = 72, .name = "fma4", .llvm_name = "fma4", .description = "Enable four-operand fused multiply-add", .dependencies = .{ .ints = .{ 4096, 0, 8192, 0, 0 } } },
    .{ .index = 73, .name = "fsgsbase", .llvm_name = "fsgsbase", .description = "Support FS/GS Base instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 74, .name = "fsrm", .llvm_name = "fsrm", .description = "REP MOVSB of short lengths is faster", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 75, .name = "fxsr", .llvm_name = "fxsr", .description = "Support fxsave/fxrestore instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 76, .name = "gfni", .llvm_name = "gfni", .description = "Enable Galois Field Arithmetic Instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 77, .name = "harden_sls_ijmp", .llvm_name = "harden-sls-ijmp", .description = "Harden against straight line speculation across indirect JMP instructions.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 78, .name = "harden_sls_ret", .llvm_name = "harden-sls-ret", .description = "Harden against straight line speculation across RET instructions.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 79, .name = "hreset", .llvm_name = "hreset", .description = "Has hreset instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 80, .name = "idivl_to_divb", .llvm_name = "idivl-to-divb", .description = "Use 8-bit divide for positive values less than 256", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 81, .name = "idivq_to_divl", .llvm_name = "idivq-to-divl", .description = "Use 32-bit divide for positive values less than 2^32", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 82, .name = "invpcid", .llvm_name = "invpcid", .description = "Invalidate Process-Context Identifier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 83, .name = "kl", .llvm_name = "kl", .description = "Support Key Locker kl Instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 84, .name = "lea_sp", .llvm_name = "lea-sp", .description = "Use LEA for adjusting the stack pointer (this is an optimization for Intel Atom processors)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 85, .name = "lea_uses_ag", .llvm_name = "lea-uses-ag", .description = "LEA instruction needs inputs at AG stage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 86, .name = "lvi_cfi", .llvm_name = "lvi-cfi", .description = "Prevent indirect calls/branches from using a memory operand, and precede all indirect calls/branches from a register with an LFENCE instruction to serialize control flow. Also decompose RET instructions into a POP+LFENCE+JMP sequence.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 87, .name = "lvi_load_hardening", .llvm_name = "lvi-load-hardening", .description = "Insert LFENCE instructions to prevent data speculatively injected into loads from being used maliciously.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 88, .name = "lwp", .llvm_name = "lwp", .description = "Enable LWP instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 89, .name = "lzcnt", .llvm_name = "lzcnt", .description = "Support LZCNT instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 90, .name = "macrofusion", .llvm_name = "macrofusion", .description = "Various instructions can be fused with conditional branches", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 91, .name = "mmx", .llvm_name = "mmx", .description = "Enable MMX instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 92, .name = "movbe", .llvm_name = "movbe", .description = "Support MOVBE instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 93, .name = "movdir64b", .llvm_name = "movdir64b", .description = "Support movdir64b instruction (direct store 64 bytes)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 94, .name = "movdiri", .llvm_name = "movdiri", .description = "Support movdiri instruction (direct store integer)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 95, .name = "mwaitx", .llvm_name = "mwaitx", .description = "Enable MONITORX/MWAITX timer functionality", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 96, .name = "nopl", .llvm_name = "nopl", .description = "Enable NOPL instruction (generally pentium pro+)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 97, .name = "pad_short_functions", .llvm_name = "pad-short-functions", .description = "Pad short functions (to prevent a stall when returning too early)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 98, .name = "pclmul", .llvm_name = "pclmul", .description = "Enable packed carry-less multiplication instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 99, .name = "pconfig", .llvm_name = "pconfig", .description = "platform configuration instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 100, .name = "pku", .llvm_name = "pku", .description = "Enable protection keys", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 101, .name = "popcnt", .llvm_name = "popcnt", .description = "Support POPCNT instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 102, .name = "prefer_128_bit", .llvm_name = "prefer-128-bit", .description = "Prefer 128-bit AVX instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 103, .name = "prefer_256_bit", .llvm_name = "prefer-256-bit", .description = "Prefer 256-bit AVX instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 104, .name = "prefer_mask_registers", .llvm_name = "prefer-mask-registers", .description = "Prefer AVX512 mask registers over PTEST/MOVMSK", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 105, .name = "prefetchi", .llvm_name = "prefetchi", .description = "Prefetch instruction with T0 or T1 Hint", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 106, .name = "prefetchwt1", .llvm_name = "prefetchwt1", .description = "Prefetch with Intent to Write and T1 Hint", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 107, .name = "prfchw", .llvm_name = "prfchw", .description = "Support PRFCHW instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 108, .name = "ptwrite", .llvm_name = "ptwrite", .description = "Support ptwrite instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 109, .name = "raoint", .llvm_name = "raoint", .description = "Support RAO-INT instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 110, .name = "rdpid", .llvm_name = "rdpid", .description = "Support RDPID instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 111, .name = "rdpru", .llvm_name = "rdpru", .description = "Support RDPRU instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 112, .name = "rdrnd", .llvm_name = "rdrnd", .description = "Support RDRAND instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 113, .name = "rdseed", .llvm_name = "rdseed", .description = "Support RDSEED instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 114, .name = "retpoline", .llvm_name = "retpoline", .description = "Remove speculation of indirect branches from the generated code, either by avoiding them entirely or lowering them with a speculation blocking construct", .dependencies = .{ .ints = .{ 0, 13510798882111488, 0, 0, 0 } } },
    .{ .index = 115, .name = "retpoline_external_thunk", .llvm_name = "retpoline-external-thunk", .description = "When lowering an indirect call or branch using a `retpoline`, rely on the specified user provided thunk rather than emitting one ourselves. Only has effect when combined with some other retpoline feature", .dependencies = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } },
    .{ .index = 116, .name = "retpoline_indirect_branches", .llvm_name = "retpoline-indirect-branches", .description = "Remove speculation of indirect branches from the generated code", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 117, .name = "retpoline_indirect_calls", .llvm_name = "retpoline-indirect-calls", .description = "Remove speculation of indirect calls from the generated code", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 118, .name = "rtm", .llvm_name = "rtm", .description = "Support RTM instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 119, .name = "sahf", .llvm_name = "sahf", .description = "Support LAHF and SAHF instructions in 64-bit mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 120, .name = "sbb_dep_breaking", .llvm_name = "sbb-dep-breaking", .description = "SBB with same register has no source dependency", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 121, .name = "serialize", .llvm_name = "serialize", .description = "Has serialize instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 122, .name = "seses", .llvm_name = "seses", .description = "Prevent speculative execution side channel timing attacks by inserting a speculation barrier before memory reads, memory writes, and conditional branches. Implies LVI Control Flow integrity.", .dependencies = .{ .ints = .{ 0, 4194304, 0, 0, 0 } } },
    .{ .index = 123, .name = "sgx", .llvm_name = "sgx", .description = "Enable Software Guard Extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 124, .name = "sha", .llvm_name = "sha", .description = "Enable SHA instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 125, .name = "shstk", .llvm_name = "shstk", .description = "Support CET Shadow-Stack instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 126, .name = "slow_3ops_lea", .llvm_name = "slow-3ops-lea", .description = "LEA instruction with 3 ops or certain registers is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 127, .name = "slow_incdec", .llvm_name = "slow-incdec", .description = "INC and DEC instructions are slower than ADD and SUB", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 128, .name = "slow_lea", .llvm_name = "slow-lea", .description = "LEA instruction with certain arguments is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 129, .name = "slow_pmaddwd", .llvm_name = "slow-pmaddwd", .description = "PMADDWD is slower than PMULLD", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 130, .name = "slow_pmulld", .llvm_name = "slow-pmulld", .description = "PMULLD instruction is slow (compared to PMULLW/PMULHW and PMULUDQ)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 131, .name = "slow_shld", .llvm_name = "slow-shld", .description = "SHLD instruction is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 132, .name = "slow_two_mem_ops", .llvm_name = "slow-two-mem-ops", .description = "Two memory operand instructions are slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 133, .name = "slow_unaligned_mem_16", .llvm_name = "slow-unaligned-mem-16", .description = "Slow unaligned 16-byte memory access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 134, .name = "slow_unaligned_mem_32", .llvm_name = "slow-unaligned-mem-32", .description = "Slow unaligned 32-byte memory access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 135, .name = "soft_float", .llvm_name = "soft-float", .description = "Use software floating point features", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 136, .name = "sse", .llvm_name = "sse", .description = "Enable SSE instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 137, .name = "sse2", .llvm_name = "sse2", .description = "Enable SSE2 instructions", .dependencies = .{ .ints = .{ 0, 0, 256, 0, 0 } } },
    .{ .index = 138, .name = "sse3", .llvm_name = "sse3", .description = "Enable SSE3 instructions", .dependencies = .{ .ints = .{ 0, 0, 512, 0, 0 } } },
    .{ .index = 139, .name = "sse4_1", .llvm_name = "sse4.1", .description = "Enable SSE 4.1 instructions", .dependencies = .{ .ints = .{ 0, 0, 32768, 0, 0 } } },
    .{ .index = 140, .name = "sse4_2", .llvm_name = "sse4.2", .description = "Enable SSE 4.2 instructions", .dependencies = .{ .ints = .{ 0, 0, 2048, 0, 0 } } },
    .{ .index = 141, .name = "sse4a", .llvm_name = "sse4a", .description = "Support SSE 4a instructions", .dependencies = .{ .ints = .{ 0, 0, 1024, 0, 0 } } },
    .{ .index = 142, .name = "sse_unaligned_mem", .llvm_name = "sse-unaligned-mem", .description = "Allow unaligned memory operands with SSE instructions (this may require setting a configuration bit in the processor)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 143, .name = "ssse3", .llvm_name = "ssse3", .description = "Enable SSSE3 instructions", .dependencies = .{ .ints = .{ 0, 0, 1024, 0, 0 } } },
    .{ .index = 144, .name = "tagged_globals", .llvm_name = "tagged-globals", .description = "Use an instruction sequence for taking the address of a global that allows a memory tag in the upper address bits.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 145, .name = "tbm", .llvm_name = "tbm", .description = "Enable TBM instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 146, .name = "tsxldtrk", .llvm_name = "tsxldtrk", .description = "Support TSXLDTRK instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 147, .name = "uintr", .llvm_name = "uintr", .description = "Has UINTR Instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 148, .name = "use_glm_div_sqrt_costs", .llvm_name = "use-glm-div-sqrt-costs", .description = "Use Goldmont specific floating point div/sqrt costs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 149, .name = "use_slm_arith_costs", .llvm_name = "use-slm-arith-costs", .description = "Use Silvermont specific arithmetic costs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 150, .name = "vaes", .llvm_name = "vaes", .description = "Promote selected AES instructions to AVX512/AVX registers", .dependencies = .{ .ints = .{ 4160, 0, 0, 0, 0 } } },
    .{ .index = 151, .name = "vpclmulqdq", .llvm_name = "vpclmulqdq", .description = "Enable vpclmulqdq instructions", .dependencies = .{ .ints = .{ 4096, 17179869184, 0, 0, 0 } } },
    .{ .index = 152, .name = "vzeroupper", .llvm_name = "vzeroupper", .description = "Should insert vzeroupper instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 153, .name = "waitpkg", .llvm_name = "waitpkg", .description = "Wait and pause enhancements", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 154, .name = "wbnoinvd", .llvm_name = "wbnoinvd", .description = "Write Back No Invalidate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 155, .name = "widekl", .llvm_name = "widekl", .description = "Support Key Locker wide Instructions", .dependencies = .{ .ints = .{ 0, 524288, 0, 0, 0 } } },
    .{ .index = 156, .name = "x87", .llvm_name = "x87", .description = "Enable X87 float instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 157, .name = "xop", .llvm_name = "xop", .description = "Enable XOP instructions", .dependencies = .{ .ints = .{ 0, 256, 0, 0, 0 } } },
    .{ .index = 158, .name = "xsave", .llvm_name = "xsave", .description = "Support xsave instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
    .{ .index = 159, .name = "xsavec", .llvm_name = "xsavec", .description = "Support xsavec instructions", .dependencies = .{ .ints = .{ 0, 0, 1073741824, 0, 0 } } },
    .{ .index = 160, .name = "xsaveopt", .llvm_name = "xsaveopt", .description = "Support xsaveopt instructions", .dependencies = .{ .ints = .{ 0, 0, 1073741824, 0, 0 } } },
    .{ .index = 161, .name = "xsaves", .llvm_name = "xsaves", .description = "Support xsaves instructions", .dependencies = .{ .ints = .{ 0, 0, 1073741824, 0, 0 } } },
};
pub const cpu = struct {
    pub const alderlake: target.Target.Cpu.Model = .{ .name = "alderlake", .llvm_name = "alderlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
    pub const amdfam10: target.Target.Cpu.Model = .{ .name = "amdfam10", .llvm_name = "amdfam10", .features = .{ .ints = .{ 19791209299992, 108095328917391362, 285220872, 0, 0 } } };
    pub const athlon: target.Target.Cpu.Model = .{ .name = "athlon", .llvm_name = "athlon", .features = .{ .ints = .{ 37383395344392, 4294967296, 285212712, 0, 0 } } };
    pub const athlon64: target.Target.Cpu.Model = .{ .name = "athlon64", .llvm_name = "athlon64", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
    pub const athlon64_sse3: target.Target.Cpu.Model = .{ .name = "athlon64_sse3", .llvm_name = "athlon64-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
    pub const athlon_4: target.Target.Cpu.Model = .{ .name = "athlon_4", .llvm_name = "athlon-4", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
    pub const athlon_fx: target.Target.Cpu.Model = .{ .name = "athlon_fx", .llvm_name = "athlon-fx", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
    pub const athlon_mp: target.Target.Cpu.Model = .{ .name = "athlon_mp", .llvm_name = "athlon-mp", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
    pub const athlon_tbird: target.Target.Cpu.Model = .{ .name = "athlon_tbird", .llvm_name = "athlon-tbird", .features = .{ .ints = .{ 37383395344392, 4294967296, 285212712, 0, 0 } } };
    pub const athlon_xp: target.Target.Cpu.Model = .{ .name = "athlon_xp", .llvm_name = "athlon-xp", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
    pub const atom: target.Target.Cpu.Model = .{ .name = "atom", .llvm_name = "atom", .features = .{ .ints = .{ 19791209299984, 36028810309863424, 285245488, 0, 0 } } };
    pub const barcelona: target.Target.Cpu.Model = .{ .name = "barcelona", .llvm_name = "barcelona", .features = .{ .ints = .{ 19791209299992, 108095328917391362, 285220872, 0, 0 } } };
    pub const bdver1: target.Target.Cpu.Model = .{ .name = "bdver1", .llvm_name = "bdver1", .features = .{ .ints = .{ 72086250059726928, 108095346248255490, 1895825416, 0, 0 } } };
    pub const bdver2: target.Target.Cpu.Model = .{ .name = "bdver2", .llvm_name = "bdver2", .features = .{ .ints = .{ 9872200531374506064, 108095346248255618, 1895956488, 0, 0 } } };
    pub const bdver3: target.Target.Cpu.Model = .{ .name = "bdver3", .llvm_name = "bdver3", .features = .{ .ints = .{ 9872200531374506064, 108095346248256130, 5117181960, 0, 0 } } };
    pub const bdver4: target.Target.Cpu.Model = .{ .name = "bdver4", .llvm_name = "bdver4", .features = .{ .ints = .{ 9872200565734252624, 108376823640885890, 5117181960, 0, 0 } } };
    pub const bonnell: target.Target.Cpu.Model = .{ .name = "bonnell", .llvm_name = "bonnell", .features = .{ .ints = .{ 19791209299984, 36028810309863424, 285245488, 0, 0 } } };
    pub const broadwell: target.Target.Cpu.Model = .{ .name = "broadwell", .llvm_name = "broadwell", .features = .{ .ints = .{ 163706337799184560, 4648568195887008413, 4580179968, 0, 0 } } };
    pub const btver1: target.Target.Cpu.Model = .{ .name = "btver1", .llvm_name = "btver1", .features = .{ .ints = .{ 144134979285155856, 108095329051609154, 285253640, 0, 0 } } };
    pub const btver2: target.Target.Cpu.Model = .{ .name = "btver2", .llvm_name = "btver2", .features = .{ .ints = .{ 16861787084334039120, 108095346499913794, 4563410952, 0, 0 } } };
    pub const c3: target.Target.Cpu.Model = .{ .name = "c3", .llvm_name = "c3", .features = .{ .ints = .{ 4, 0, 285212704, 0, 0 } } };
    pub const c3_2: target.Target.Cpu.Model = .{ .name = "c3_2", .llvm_name = "c3-2", .features = .{ .ints = .{ 37383395344384, 134219776, 285212960, 0, 0 } } };
    pub const cannonlake: target.Target.Cpu.Model = .{ .name = "cannonlake", .llvm_name = "cannonlake", .features = .{ .ints = .{ 1297206343979368688, 5801490318969145917, 15317598208, 0, 0 } } };
    pub const cascadelake: target.Target.Cpu.Model = .{ .name = "cascadelake", .llvm_name = "cascadelake", .features = .{ .ints = .{ 1315221292357976304, 4648568814362298941, 15317598208, 0, 0 } } };
    pub const cooperlake: target.Target.Cpu.Model = .{ .name = "cooperlake", .llvm_name = "cooperlake", .features = .{ .ints = .{ 1315221292357927152, 4648568814362298941, 15317598208, 0, 0 } } };
    pub const core2: target.Target.Cpu.Model = .{ .name = "core2", .llvm_name = "core2", .features = .{ .ints = .{ 19791209299984, 36028801515259904, 285245472, 0, 0 } } };
    pub const core_avx2: target.Target.Cpu.Model = .{ .name = "core_avx2", .llvm_name = "core-avx2", .features = .{ .ints = .{ 163706337799184528, 4647996449840564893, 4580179968, 0, 0 } } };
    pub const core_avx_i: target.Target.Cpu.Model = .{ .name = "core_avx_i", .llvm_name = "core-avx-i", .features = .{ .ints = .{ 162439648864370704, 4647996449538312709, 4580180032, 0, 0 } } };
    pub const corei7: target.Target.Cpu.Model = .{ .name = "corei7", .llvm_name = "corei7", .features = .{ .ints = .{ 28587302322192, 36028938954213376, 285216768, 0, 0 } } };
    pub const corei7_avx: target.Target.Cpu.Model = .{ .name = "corei7_avx", .llvm_name = "corei7-avx", .features = .{ .ints = .{ 162158173887664144, 4647714974561601541, 4580180032, 0, 0 } } };
    pub const emeraldrapids: target.Target.Cpu.Model = .{ .name = "emeraldrapids", .llvm_name = "emeraldrapids", .features = .{ .ints = .{ 1349631750520882608, 3639850477552016957, 15431630848, 0, 0 } } };
    pub const generic: target.Target.Cpu.Model = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 144150372447944720, 4611686018494627841, 285212672, 0, 0 } } };
    pub const geode: target.Target.Cpu.Model = .{ .name = "geode", .llvm_name = "geode", .features = .{ .ints = .{ 35184372088840, 0, 285212704, 0, 0 } } };
    pub const goldmont: target.Target.Cpu.Model = .{ .name = "goldmont", .llvm_name = "goldmont", .features = .{ .ints = .{ 9241415297544486992, 10413175718820186624, 15318650897, 0, 0 } } };
    pub const goldmont_plus: target.Target.Cpu.Model = .{ .name = "goldmont_plus", .llvm_name = "goldmont-plus", .features = .{ .ints = .{ 9223400899035005008, 10413263679750408704, 15318650897, 0, 0 } } };
    pub const grandridge: target.Target.Cpu.Model = .{ .name = "grandridge", .llvm_name = "grandridge", .features = .{ .ints = .{ 9223687526898729008, 12863257148955859584, 15499001873, 0, 0 } } };
    pub const graniterapids: target.Target.Cpu.Model = .{ .name = "graniterapids", .llvm_name = "graniterapids", .features = .{ .ints = .{ 1349631750520883120, 3639852676575272509, 15431630848, 0, 0 } } };
    pub const haswell: target.Target.Cpu.Model = .{ .name = "haswell", .llvm_name = "haswell", .features = .{ .ints = .{ 163706337799184528, 4647996449840564893, 4580179968, 0, 0 } } };
    pub const @"i386": target.Target.Cpu.Model = .{ .name = "i386", .llvm_name = "i386", .features = .{ .ints = .{ 0, 0, 285212704, 0, 0 } } };
    pub const @"i486": target.Target.Cpu.Model = .{ .name = "i486", .llvm_name = "i486", .features = .{ .ints = .{ 0, 0, 285212704, 0, 0 } } };
    pub const @"i586": target.Target.Cpu.Model = .{ .name = "i586", .llvm_name = "i586", .features = .{ .ints = .{ 35184372088832, 0, 285212704, 0, 0 } } };
    pub const @"i686": target.Target.Cpu.Model = .{ .name = "i686", .llvm_name = "i686", .features = .{ .ints = .{ 37383395344384, 0, 285212704, 0, 0 } } };
    pub const icelake_client: target.Target.Cpu.Model = .{ .name = "icelake_client", .llvm_name = "icelake-client", .features = .{ .ints = .{ 1297206344684044464, 1189874652106071613, 15330181120, 0, 0 } } };
    pub const icelake_server: target.Target.Cpu.Model = .{ .name = "icelake_server", .llvm_name = "icelake-server", .features = .{ .ints = .{ 1297206894439858352, 1189874686465809981, 15397289984, 0, 0 } } };
    pub const ivybridge: target.Target.Cpu.Model = .{ .name = "ivybridge", .llvm_name = "ivybridge", .features = .{ .ints = .{ 162439648864370704, 4647996449538312709, 4580180032, 0, 0 } } };
    pub const k6: target.Target.Cpu.Model = .{ .name = "k6", .llvm_name = "k6", .features = .{ .ints = .{ 35184372088832, 134217728, 285212704, 0, 0 } } };
    pub const k6_2: target.Target.Cpu.Model = .{ .name = "k6_2", .llvm_name = "k6-2", .features = .{ .ints = .{ 35184372088836, 0, 285212704, 0, 0 } } };
    pub const k6_3: target.Target.Cpu.Model = .{ .name = "k6_3", .llvm_name = "k6-3", .features = .{ .ints = .{ 35184372088836, 0, 285212704, 0, 0 } } };
    pub const k8: target.Target.Cpu.Model = .{ .name = "k8", .llvm_name = "k8", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
    pub const k8_sse3: target.Target.Cpu.Model = .{ .name = "k8_sse3", .llvm_name = "k8-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
    pub const knl: target.Target.Cpu.Model = .{ .name = "knl", .llvm_name = "knl", .features = .{ .ints = .{ 10376322180312596592, 13871945730232551936, 4563402770, 0, 0 } } };
    pub const knm: target.Target.Cpu.Model = .{ .name = "knm", .llvm_name = "knm", .features = .{ .ints = .{ 10376322180849467504, 13871945730232551936, 4563402770, 0, 0 } } };
    pub const lakemont: target.Target.Cpu.Model = .{ .name = "lakemont", .llvm_name = "lakemont", .features = .{ .ints = .{ 35184372088832, 0, 16777376, 0, 0 } } };
    pub const meteorlake: target.Target.Cpu.Model = .{ .name = "meteorlake", .llvm_name = "meteorlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
    pub const nehalem: target.Target.Cpu.Model = .{ .name = "nehalem", .llvm_name = "nehalem", .features = .{ .ints = .{ 28587302322192, 36028938954213376, 285216768, 0, 0 } } };
    pub const nocona: target.Target.Cpu.Model = .{ .name = "nocona", .llvm_name = "nocona", .features = .{ .ints = .{ 19791209299984, 4429187072, 285213728, 0, 0 } } };
    pub const opteron: target.Target.Cpu.Model = .{ .name = "opteron", .llvm_name = "opteron", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
    pub const opteron_sse3: target.Target.Cpu.Model = .{ .name = "opteron_sse3", .llvm_name = "opteron-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
    pub const penryn: target.Target.Cpu.Model = .{ .name = "penryn", .llvm_name = "penryn", .features = .{ .ints = .{ 19791209299984, 36028801515259904, 285214752, 0, 0 } } };
    pub const pentium: target.Target.Cpu.Model = .{ .name = "pentium", .llvm_name = "pentium", .features = .{ .ints = .{ 35184372088832, 0, 285212704, 0, 0 } } };
    pub const pentium2: target.Target.Cpu.Model = .{ .name = "pentium2", .llvm_name = "pentium2", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212704, 0, 0 } } };
    pub const pentium3: target.Target.Cpu.Model = .{ .name = "pentium3", .llvm_name = "pentium3", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212960, 0, 0 } } };
    pub const pentium3m: target.Target.Cpu.Model = .{ .name = "pentium3m", .llvm_name = "pentium3m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212960, 0, 0 } } };
    pub const pentium4: target.Target.Cpu.Model = .{ .name = "pentium4", .llvm_name = "pentium4", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
    pub const pentium4m: target.Target.Cpu.Model = .{ .name = "pentium4m", .llvm_name = "pentium4m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
    pub const pentium_m: target.Target.Cpu.Model = .{ .name = "pentium_m", .llvm_name = "pentium-m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
    pub const pentium_mmx: target.Target.Cpu.Model = .{ .name = "pentium_mmx", .llvm_name = "pentium-mmx", .features = .{ .ints = .{ 35184372088832, 134217728, 285212704, 0, 0 } } };
    pub const pentiumpro: target.Target.Cpu.Model = .{ .name = "pentiumpro", .llvm_name = "pentiumpro", .features = .{ .ints = .{ 37383395344384, 4294967296, 285212704, 0, 0 } } };
    pub const prescott: target.Target.Cpu.Model = .{ .name = "prescott", .llvm_name = "prescott", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213728, 0, 0 } } };
    pub const raptorlake: target.Target.Cpu.Model = .{ .name = "raptorlake", .llvm_name = "raptorlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
    pub const rocketlake: target.Target.Cpu.Model = .{ .name = "rocketlake", .llvm_name = "rocketlake", .features = .{ .ints = .{ 1297206344684044464, 1189874652106071613, 15330181120, 0, 0 } } };
    pub const sandybridge: target.Target.Cpu.Model = .{ .name = "sandybridge", .llvm_name = "sandybridge", .features = .{ .ints = .{ 162158173887664144, 4647714974561601541, 4580180032, 0, 0 } } };
    pub const sapphirerapids: target.Target.Cpu.Model = .{ .name = "sapphirerapids", .llvm_name = "sapphirerapids", .features = .{ .ints = .{ 1349631750520882608, 3639850477552016957, 15431630848, 0, 0 } } };
    pub const sierraforest: target.Target.Cpu.Model = .{ .name = "sierraforest", .llvm_name = "sierraforest", .features = .{ .ints = .{ 9223687526898729008, 12863221964583770752, 15499001873, 0, 0 } } };
    pub const silvermont: target.Target.Cpu.Model = .{ .name = "silvermont", .llvm_name = "silvermont", .features = .{ .ints = .{ 9529645398818291728, 9259691264260048896, 287313941, 0, 0 } } };
    pub const skx: target.Target.Cpu.Model = .{ .name = "skx", .llvm_name = "skx", .features = .{ .ints = .{ 1315221292223758576, 4648568814362298941, 15317598208, 0, 0 } } };
    pub const skylake: target.Target.Cpu.Model = .{ .name = "skylake", .llvm_name = "skylake", .features = .{ .ints = .{ 1315502217377095920, 4648568195887008445, 15317598208, 0, 0 } } };
    pub const skylake_avx512: target.Target.Cpu.Model = .{ .name = "skylake_avx512", .llvm_name = "skylake-avx512", .features = .{ .ints = .{ 1315221292223758576, 4648568814362298941, 15317598208, 0, 0 } } };
    pub const slm: target.Target.Cpu.Model = .{ .name = "slm", .llvm_name = "slm", .features = .{ .ints = .{ 9529645398818291728, 9259691264260048896, 287313941, 0, 0 } } };
    pub const tigerlake: target.Target.Cpu.Model = .{ .name = "tigerlake", .llvm_name = "tigerlake", .features = .{ .ints = .{ 1297206894708293808, 3495717662930378301, 15330181120, 0, 0 } } };
    pub const tremont: target.Target.Cpu.Model = .{ .name = "tremont", .llvm_name = "tremont", .features = .{ .ints = .{ 9223401448790818896, 10413263679750412800, 15318650897, 0, 0 } } };
    pub const westmere: target.Target.Cpu.Model = .{ .name = "westmere", .llvm_name = "westmere", .features = .{ .ints = .{ 28587302322192, 36028956134082560, 285216768, 0, 0 } } };
    pub const winchip2: target.Target.Cpu.Model = .{ .name = "winchip2", .llvm_name = "winchip2", .features = .{ .ints = .{ 4, 0, 285212704, 0, 0 } } };
    pub const winchip_c6: target.Target.Cpu.Model = .{ .name = "winchip_c6", .llvm_name = "winchip-c6", .features = .{ .ints = .{ 0, 134217728, 285212704, 0, 0 } } };
    pub const x86_64: target.Target.Cpu.Model = .{ .name = "x86_64", .llvm_name = "x86-64", .features = .{ .ints = .{ 37383395344400, 13835058059778590720, 285213184, 0, 0 } } };
    pub const x86_64_v2: target.Target.Cpu.Model = .{ .name = "x86_64_v2", .llvm_name = "x86-64-v2", .features = .{ .ints = .{ 162158173887660048, 4647714957381732357, 285216832, 0, 0 } } };
    pub const x86_64_v3: target.Target.Cpu.Model = .{ .name = "x86_64_v3", .llvm_name = "x86-64-v3", .features = .{ .ints = .{ 163565600310829200, 4647714957683722397, 1358954496, 0, 0 } } };
    pub const x86_64_v4: target.Target.Cpu.Model = .{ .name = "x86_64_v4", .llvm_name = "x86-64-v4", .features = .{ .ints = .{ 1315079730101682320, 4647715507439536189, 1358954496, 0, 0 } } };
    pub const yonah: target.Target.Cpu.Model = .{ .name = "yonah", .llvm_name = "yonah", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213728, 0, 0 } } };
    pub const znver1: target.Target.Cpu.Model = .{ .name = "znver1", .llvm_name = "znver1", .features = .{ .ints = .{ 14555945552589103344, 1261861278184377011, 15317606408, 0, 0 } } };
    pub const znver2: target.Target.Cpu.Model = .{ .name = "znver2", .llvm_name = "znver2", .features = .{ .ints = .{ 14555946102344917232, 1262072384416910003, 15384715272, 0, 0 } } };
    pub const znver3: target.Target.Cpu.Model = .{ .name = "znver3", .llvm_name = "znver3", .features = .{ .ints = .{ 14555946102344917168, 1262072436023889587, 15397298184, 0, 0 } } };
    pub const znver4: target.Target.Cpu.Model = .{ .name = "znver4", .llvm_name = "znver4", .features = .{ .ints = .{ 14555664628161364144, 3567915445237587507, 15397298184, 0, 0 } } };
};
pub usingnamespace feat.GenericFeatureSet(Feature);
